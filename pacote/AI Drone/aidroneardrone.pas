unit aidroneardrone;

{ TAIDroneARDrone
  ---------------
  Parrot AR.Drone 2.0 (SDK oficial da Parrot).

  Rede do drone (ponto de acesso "ardrone2_xxxxxx"): IP 192.168.1.1.
    UDP 5556 - comandos AT em texto (AT*REF, AT*PCMD, AT*FTRIM, AT*CONFIG...)
    UDP 5554 - telemetria (navdata): estado, bateria, atitude, altura, velocidade.
               O componente escuta na porta local 5554 (o drone envia para ela).
    TCP 5555 - vídeo H.264 da câmera frontal em quadros PaVE (OnVideoData).

  Comandos:
    AT*REF   decolar (bit 9), pousar, emergência (bit 8 alterna)
    AT*PCMD  movimento: sem comando = pairar no lugar; valores -1..1 enviados
             como o inteiro de 32 bits com o mesmo padrão de bits do real.
  O drone espera comandos continuamente: sem nada por 2 s ele paira
  (watchdog). A linha de comando envia a cada 30 ms.

  Segurança:
    - manche no centro = pairar (PCMD com f=0), nunca "último comando";
    - sem SetSticks por StickTimeoutMs, o drone paira;
    - TakeOff recusa com emergência ativa ou bateria baixa;
    - ao desconectar, manda pousar antes de fechar.

  Eventos na linha principal: OnStatus, OnError, OnStateChange (telemetria
  começou/parou), OnTelemetry. OnVideoData: linha de rede (H.264 bruto). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Math, aibase, aidronebase, LResources;

const
  ARDRONE_DEFAULT_HOST = '192.168.1.1';
  ARDRONE_PORT_AT = 5556;
  ARDRONE_PORT_NAVDATA = 5554;
  ARDRONE_PORT_VIDEO = 5555;
  ARDRONE_VIDEO_WIDTH = 640;
  ARDRONE_VIDEO_HEIGHT = 360;

  ARDRONE_STATE_FLY = 1 shl 0;
  ARDRONE_STATE_COMMAND_ACK = 1 shl 6;
  ARDRONE_STATE_NAVDATA_BOOTSTRAP = 1 shl 11;
  ARDRONE_STATE_VBAT_LOW = 1 shl 15;
  ARDRONE_STATE_CUTOUT = 1 shl 22;
  ARDRONE_STATE_COM_WATCHDOG = 1 shl 30;
  ARDRONE_STATE_EMERGENCY = Cardinal(1) shl 31;

type
  TAIARDroneNavdata = record
    Valid: Boolean;
    State: Cardinal;
    Sequence: Cardinal;
    Battery: Integer;          // %
    Pitch, Roll, Heading: Double;   // graus
    Altitude: Double;          // m
    VelX, VelY, VelZ: Double;  // m/s
    ReceivedTick: QWord;
  end;

  { TAIDroneARDrone }

  TAIDroneARDrone = class(TAIDroneBase)
  private
    FHost: string;
    FVideoEnabled: Boolean;
    FSensitivity: Double;
    FStickTimeoutMs: Integer;
    FLandOnDisconnect: Boolean;
    FControlThread: TThread;
    FVideoThread: TThread;
    FLock: TCriticalSection;
    FNav: TAIARDroneNavdata;
    FRoll, FPitch, FGaz, FYaw: Single;
    FStickTick: QWord;
    FFly: Boolean;
    FEmergencyTicks: Integer;
    FTrimPending: Boolean;
    FConfigs: TStringList;
    FCommandsSent: Int64;
    FNavPackets: Int64;
    FVideoConnected: Boolean;
    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    function GetNavdata: TAIARDroneNavdata;
    function GetFlying: Boolean;
  public
    { Uso interno das linhas de rede. }
    function NextCommands(var ASeq: Cardinal; AWatchdog: Boolean): string;
    procedure ReceiveNavdata(const ABuf: array of Byte; ALen: Integer);
    procedure SetVideoConnected(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Connect;
    { Com LandOnDisconnect, manda pousar antes de fechar. }
    procedure Disconnect;

    { Rolagem/arfagem/guinada -1..1 (+ = direita/frente/direita), subida -1..1
      (+ = sobe). Multiplicados por Sensitivity (exceto a subida). Zero = pairar. }
    procedure SetSticks(ARoll, APitch, AYaw, AClimb: Double);
    procedure Hover;
    procedure TakeOff;
    procedure Land;
    { Corta os motores na hora; se já estiver em emergência, rearma. }
    procedure Emergency;
    { Calibração horizontal: só com o drone pousado numa superfície plana. }
    procedure FlatTrim;
    { Envia AT*CONFIG (um por vez, com confirmação). }
    procedure Configure(const AKey, AValue: string);

    class function FloatToAT(AValue: Single): LongInt; static;
    class function StateText(const ANav: TAIARDroneNavdata): string; static;

    property Active: Boolean read GetActive write SetActive;
    property Navdata: TAIARDroneNavdata read GetNavdata;
    property Flying: Boolean read GetFlying;
    property VideoConnected: Boolean read FVideoConnected;
    property CommandsSent: Int64 read FCommandsSent;
    property NavPackets: Int64 read FNavPackets;
  published
    property Host: string read FHost write FHost;
    property VideoEnabled: Boolean read FVideoEnabled write FVideoEnabled default True;
    { Fração do comando máximo usada por rolagem/arfagem/guinada (0.1..1). }
    property Sensitivity: Double read FSensitivity write FSensitivity;
    property StickTimeoutMs: Integer read FStickTimeoutMs write FStickTimeoutMs default 500;
    property LandOnDisconnect: Boolean read FLandOnDisconnect write FLandOnDisconnect default True;
    property OnStatus;
    property OnError;
    property OnStateChange;
    property OnTelemetry;
    property OnVideoData;
  end;

procedure Register;

implementation

uses
  aisockets;

const
  REF_BASE = $11540000;
  REF_TAKEOFF = $200;
  REF_EMERGENCY = $100;
  NAVDATA_HEADER = $55667788;
  NAV_TAG_DEMO = 0;
  NAV_TAG_CHECKSUM = $FFFF;
  PAVE_MIN_HEADER = 12;
  VIDEO_BUF_MAX = 2 * 1024 * 1024;
  ZONA_MORTA = 0.06;

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneARDrone]);
end;

function LeU16(const B: array of Byte; P: Integer): Word;
begin
  Result := Word(B[P]) or (Word(B[P + 1]) shl 8);
end;

function LeU32(const B: array of Byte; P: Integer): Cardinal;
begin
  Result := Cardinal(B[P]) or (Cardinal(B[P + 1]) shl 8) or
    (Cardinal(B[P + 2]) shl 16) or (Cardinal(B[P + 3]) shl 24);
end;

function LeF32(const B: array of Byte; P: Integer): Single;
var
  C: Cardinal;
begin
  C := LeU32(B, P);
  Move(C, Result, SizeOf(Result));
end;

type

  { TARControlThread: comandos AT e telemetria }

  TARControlThread = class(TAIDroneWorker)
  private
    FOwner: TAIDroneARDrone;
    FHost: string;
    FLand: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneARDrone);
  end;

  { TARVideoThread: vídeo PaVE/H.264 }

  TARVideoThread = class(TAIDroneWorker)
  private
    FOwner: TAIDroneARDrone;
    FHost: string;
    FBuf: TBytes;
    FLen: Integer;
    procedure ProcessaPaVE;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneARDrone);
  end;

{ TARControlThread }

constructor TARControlThread.Create(AOwner: TAIDroneARDrone);
begin
  FOwner := AOwner;
  FHost := Trim(AOwner.Host);
  if FHost = '' then
    FHost := ARDRONE_DEFAULT_HOST;
  FLand := AOwner.LandOnDisconnect;
  inherited Create;
end;

procedure TARControlThread.Execute;
const
  GATILHO: array[0..3] of Byte = ($01, $00, $00, $00);
var
  At, Nav: TAISocketUDP;
  Buf: array[0..4095] of Byte;
  Seq: Cardinal;
  Cmd, IP: string;
  N, Porta, I: Integer;
  Prox, UltimoGatilho, UltimaNav: QWord;
  Recebendo, Watchdog: Boolean;
begin
  At := TAISocketUDP.Create(nil);
  Nav := TAISocketUDP.Create(nil);
  try
    At.Host := FHost;
    At.Port := ARDRONE_PORT_AT;
    At.LocalPort := 0;
    if not At.OpenSocket then
    begin
      FOwner.PostError('Não foi possível abrir o UDP de comandos: ' + At.LastError);
      Exit;
    end;
    Nav.Host := FHost;
    Nav.Port := ARDRONE_PORT_NAVDATA;
    Nav.LocalPort := ARDRONE_PORT_NAVDATA;
    if not Nav.OpenSocket then
      FOwner.PostStatus('Telemetria indisponível (porta UDP 5554 ocupada?).');

    FOwner.PostStatus(Format('Conectando ao AR.Drone em %s...', [FHost]));
    Seq := 0;
    // Sequência 1 reinicia a numeração no drone.
    Cmd := FOwner.NextCommands(Seq, False);
    At.SendText(Cmd);
    if Nav.Active then
      Nav.SendBufferTo(GATILHO[0], SizeOf(GATILHO), FHost, ARDRONE_PORT_NAVDATA);
    UltimoGatilho := GetTickCount64;
    UltimaNav := 0;
    Recebendo := False;
    Prox := GetTickCount64;

    while not Terminated do
    begin
      if GetTickCount64 >= Prox then
      begin
        Watchdog := FOwner.Navdata.Valid and
          ((FOwner.Navdata.State and ARDRONE_STATE_COM_WATCHDOG) <> 0);
        Cmd := FOwner.NextCommands(Seq, Watchdog);
        if At.SendText(Cmd) then
          Inc(FOwner.FCommandsSent);
        Prox := GetTickCount64 + 30;
      end;

      if Nav.Active then
      begin
        N := Nav.ReceiveBuffer(Buf, SizeOf(Buf), 10, IP, Porta);
        if N > 0 then
        begin
          FOwner.ReceiveNavdata(Buf, N);
          UltimaNav := GetTickCount64;
          if not Recebendo then
          begin
            Recebendo := True;
            FOwner.PostStateChange;
          end;
        end;
        // Telemetria parada: o drone precisa de um novo gatilho.
        if (GetTickCount64 - UltimoGatilho > 1000) and
          ((UltimaNav = 0) or (GetTickCount64 - UltimaNav > 1000)) then
        begin
          Nav.SendBufferTo(GATILHO[0], SizeOf(GATILHO), FHost, ARDRONE_PORT_NAVDATA);
          UltimoGatilho := GetTickCount64;
          if Recebendo then
          begin
            Recebendo := False;
            FOwner.PostStatus('Telemetria interrompida: chamando o drone de novo.');
            FOwner.PostStateChange;
          end;
        end;
      end
      else
        Sleep(10);
    end;

    // Pouso antes de soltar o canal de comando.
    if FLand then
    begin
      FOwner.Land;
      FOwner.Hover;
      for I := 1 to 5 do
      begin
        At.SendText(FOwner.NextCommands(Seq, False));
        Sleep(30);
      end;
    end;
  finally
    Nav.Free;
    At.Free;
  end;
end;

{ TARVideoThread }

constructor TARVideoThread.Create(AOwner: TAIDroneARDrone);
begin
  FOwner := AOwner;
  FHost := Trim(AOwner.Host);
  if FHost = '' then
    FHost := ARDRONE_DEFAULT_HOST;
  SetLength(FBuf, 256 * 1024);
  inherited Create;
end;

procedure TARVideoThread.ProcessaPaVE;
var
  P, I, Cabecalho, Carga: Integer;
begin
  P := 0;
  while FLen - P >= PAVE_MIN_HEADER do
  begin
    if not ((FBuf[P] = Ord('P')) and (FBuf[P + 1] = Ord('a')) and
      (FBuf[P + 2] = Ord('V')) and (FBuf[P + 3] = Ord('E'))) then
    begin
      I := P + 1;
      while (I <= FLen - 4) and not ((FBuf[I] = Ord('P')) and (FBuf[I + 1] = Ord('a')) and
        (FBuf[I + 2] = Ord('V')) and (FBuf[I + 3] = Ord('E'))) do
        Inc(I);
      P := I;
      Continue;
    end;
    Cabecalho := LeU16(FBuf, P + 6);
    Carga := Integer(LeU32(FBuf, P + 8));
    if (Cabecalho < PAVE_MIN_HEADER) or (Carga <= 0) or (Carga > VIDEO_BUF_MAX) then
    begin
      Inc(P);
      Continue;
    end;
    if FLen - P < Cabecalho + Carga then
      Break;
    FOwner.DoVideoData(@FBuf[P + Cabecalho], Carga);
    Inc(P, Cabecalho + Carga);
  end;
  if P > 0 then
  begin
    if P < FLen then
      Move(FBuf[P], FBuf[0], FLen - P);
    Dec(FLen, P);
  end;
end;

procedure TARVideoThread.Execute;
var
  Tcp: TAISocketTCP;
  Tmp: array[0..32767] of Byte;
  N: Integer;
begin
  Tcp := nil;
  try
    while not Terminated do
    begin
      if not Assigned(Tcp) then
      begin
        Tcp := TAISocketTCP.Create(nil);
        Tcp.Mode := smClient;
        Tcp.Host := FHost;
        Tcp.Port := ARDRONE_PORT_VIDEO;
        Tcp.ConnectTimeoutMs := 2000;
        if not Tcp.Connect then
        begin
          FreeAndNil(Tcp);
          Pause(2000);
          Continue;
        end;
        FLen := 0;
        FOwner.SetVideoConnected(True);
        FOwner.PostStatus('Canal de vídeo aberto.');
      end;
      N := Tcp.ReceiveBuffer(Tmp, SizeOf(Tmp), 100);
      if N < 0 then
      begin
        FreeAndNil(Tcp);
        FOwner.SetVideoConnected(False);
        FOwner.PostStatus('Canal de vídeo fechado pelo drone. Reconectando...');
        Pause(500);
        Continue;
      end;
      if N > 0 then
      begin
        if FLen + N > Length(FBuf) then
        begin
          if FLen + N > VIDEO_BUF_MAX then
            FLen := 0; // fluxo dessincronizado: recomeça
          if FLen + N > Length(FBuf) then
            SetLength(FBuf, FLen + N);
        end;
        Move(Tmp[0], FBuf[FLen], N);
        Inc(FLen, N);
        ProcessaPaVE;
      end;
    end;
  finally
    Tcp.Free;
    FOwner.SetVideoConnected(False);
  end;
end;

{ TAIDroneARDrone }

constructor TAIDroneARDrone.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  Prompt := 'Component TAIDroneARDrone controls the Parrot AR.Drone 2.0 (official SDK: AT ' +
    'commands on UDP 5556, navdata on UDP 5554, PaVE/H.264 video on TCP 5555, host 192.168.1.1). ' +
    'Methods: Connect, Disconnect, TakeOff, Land, Emergency, FlatTrim, SetSticks(Roll, Pitch, Yaw, ' +
    'Climb: -1..1; zero = hover), Hover, Configure(Key, Value). Navdata: state, battery, attitude, ' +
    'altitude. Events: OnStatus, OnError, OnStateChange, OnTelemetry, OnVideoData (raw H.264, ' +
    'network thread; feed a TAIH264Decoder).';
  FHost := ARDRONE_DEFAULT_HOST;
  FVideoEnabled := True;
  FSensitivity := 0.5;
  FStickTimeoutMs := 500;
  FLandOnDisconnect := True;
  FLock := TCriticalSection.Create;
  FConfigs := TStringList.Create;
end;

destructor TAIDroneARDrone.Destroy;
begin
  Disconnect;
  CancelPendingEvents;
  FConfigs.Free;
  FLock.Free;
  inherited Destroy;
end;

function TAIDroneARDrone.GetActive: Boolean;
begin
  Result := Assigned(FControlThread);
end;

procedure TAIDroneARDrone.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

procedure TAIDroneARDrone.Connect;
begin
  if Assigned(FControlThread) then
    Exit;
  ClearError;
  FLock.Enter;
  try
    FillChar(FNav, SizeOf(FNav), 0);
    FRoll := 0; FPitch := 0; FGaz := 0; FYaw := 0;
    FStickTick := 0;
    FFly := False;
    FEmergencyTicks := 0;
    FTrimPending := False;
    FConfigs.Clear;
    // Pede o modo "demo" da telemetria (bateria, atitude, altura).
    FConfigs.Add('"general:navdata_demo","TRUE"');
  finally
    FLock.Leave;
  end;
  FCommandsSent := 0;
  FNavPackets := 0;
  ResetVideoCounters;
  FControlThread := TARControlThread.Create(Self);
  if FVideoEnabled then
    FVideoThread := TARVideoThread.Create(Self);
end;

procedure TAIDroneARDrone.Disconnect;
begin
  if Assigned(FVideoThread) then
  begin
    FVideoThread.Terminate;
    FVideoThread.WaitFor;
    FreeAndNil(FVideoThread);
  end;
  if Assigned(FControlThread) then
  begin
    FControlThread.Terminate;
    FControlThread.WaitFor;
    FreeAndNil(FControlThread);
    PostStatus('AR.Drone desconectado.');
    PostStateChange;
  end;
end;

procedure TAIDroneARDrone.SetSticks(ARoll, APitch, AYaw, AClimb: Double);

  function Ajusta(V: Double): Single;
  begin
    V := ClampAxis(V);
    if Abs(V) < ZONA_MORTA then
      V := 0;
    Result := V;
  end;

var
  S: Double;
begin
  S := EnsureRange(FSensitivity, 0.1, 1.0);
  FLock.Enter;
  try
    FRoll := Ajusta(ARoll) * S;
    // No AR.Drone a arfagem positiva é para TRÁS.
    FPitch := -Ajusta(APitch) * S;
    FYaw := Ajusta(AYaw) * S;
    FGaz := Ajusta(AClimb);
    FStickTick := GetTickCount64;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneARDrone.Hover;
begin
  SetSticks(0, 0, 0, 0);
end;

procedure TAIDroneARDrone.TakeOff;
var
  N: TAIARDroneNavdata;
  Motivo: string;
begin
  N := Navdata;
  Motivo := '';
  if N.Valid and ((N.State and ARDRONE_STATE_EMERGENCY) <> 0) then
    Motivo := 'Drone em emergência: use Emergency para rearmar antes de decolar.'
  else if N.Valid and ((N.State and ARDRONE_STATE_VBAT_LOW) <> 0) then
    Motivo := 'Bateria baixa: decolagem recusada.';
  if Motivo <> '' then
  begin
    PostStatus(Motivo);
    Exit;
  end;
  FLock.Enter;
  try
    FRoll := 0; FPitch := 0; FGaz := 0; FYaw := 0;
    FFly := True;
  finally
    FLock.Leave;
  end;
  PostStatus('Decolando...');
end;

procedure TAIDroneARDrone.Land;
begin
  FLock.Enter;
  try
    FFly := False;
  finally
    FLock.Leave;
  end;
  PostStatus('Pousando...');
end;

procedure TAIDroneARDrone.Emergency;
var
  JaEmergencia: Boolean;
begin
  FLock.Enter;
  try
    FFly := False;
    // O bit 8 alterna o estado: alguns comandos seguidos garantem a recepção.
    FEmergencyTicks := 8;
    JaEmergencia := FNav.Valid and ((FNav.State and ARDRONE_STATE_EMERGENCY) <> 0);
  finally
    FLock.Leave;
  end;
  if JaEmergencia then
    PostStatus('Rearmando após emergência...')
  else
    PostStatus('EMERGÊNCIA: motores cortados.');
end;

procedure TAIDroneARDrone.FlatTrim;
var
  Voando: Boolean;
begin
  FLock.Enter;
  try
    Voando := FFly or (FNav.Valid and ((FNav.State and ARDRONE_STATE_FLY) <> 0));
    if not Voando then
      FTrimPending := True;
  finally
    FLock.Leave;
  end;
  if Voando then
    PostStatus('Calibração só com o drone pousado.')
  else
    PostStatus('Calibração horizontal enviada.');
end;

procedure TAIDroneARDrone.Configure(const AKey, AValue: string);
begin
  FLock.Enter;
  try
    FConfigs.Add(Format('"%s","%s"', [AKey, AValue]));
  finally
    FLock.Leave;
  end;
end;

function TAIDroneARDrone.NextCommands(var ASeq: Cardinal; AWatchdog: Boolean): string;
var
  Ref: Cardinal;
  Mover: Boolean;
  R, P, G, Y: Single;

  function Proximo: Cardinal;
  begin
    Inc(ASeq);
    Result := ASeq;
  end;

begin
  Result := '';
  FLock.Enter;
  try
    if AWatchdog then
      Result := Result + Format('AT*COMWDG=%d'#13, [Proximo]);

    // Uma configuração por vez, seguida de AT*CTRL=5 (limpa a confirmação).
    if FConfigs.Count > 0 then
    begin
      Result := Result + Format('AT*CONFIG=%d,%s'#13'AT*CTRL=%d,5,0'#13,
        [Proximo, FConfigs[0], Proximo]);
      FConfigs.Delete(0);
    end;

    if FTrimPending then
    begin
      Result := Result + Format('AT*FTRIM=%d,'#13, [Proximo]);
      FTrimPending := False;
    end;

    Ref := REF_BASE;
    if FEmergencyTicks > 0 then
    begin
      Ref := Ref or REF_EMERGENCY;
      Dec(FEmergencyTicks);
    end
    else if FFly then
      Ref := Ref or REF_TAKEOFF;
    Result := Result + Format('AT*REF=%d,%d'#13, [Proximo, Ref]);

    R := FRoll; P := FPitch; G := FGaz; Y := FYaw;
    // Manche parado (aplicação sem atualizar): paira.
    if (FStickTimeoutMs > 0) and (GetTickCount64 - FStickTick > QWord(FStickTimeoutMs)) then
    begin
      R := 0; P := 0; G := 0; Y := 0;
    end;
    Mover := FFly and ((R <> 0) or (P <> 0) or (G <> 0) or (Y <> 0));
    if Mover then
      Result := Result + Format('AT*PCMD=%d,1,%d,%d,%d,%d'#13,
        [Proximo, FloatToAT(R), FloatToAT(P), FloatToAT(G), FloatToAT(Y)])
    else
      Result := Result + Format('AT*PCMD=%d,0,0,0,0,0'#13, [Proximo]);
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneARDrone.ReceiveNavdata(const ABuf: array of Byte; ALen: Integer);
var
  P, Etiq, TamB: Integer;
  Anterior: Cardinal;
  Primeira, Emergiu, BateriaBaixa: Boolean;
begin
  if (ALen < 16) or (LeU32(ABuf, 0) <> NAVDATA_HEADER) then
    Exit;
  FLock.Enter;
  try
    Primeira := not FNav.Valid;
    Anterior := FNav.State;
    FNav.State := LeU32(ABuf, 4);
    FNav.Sequence := LeU32(ABuf, 8);
    FNav.Valid := True;
    FNav.ReceivedTick := GetTickCount64;
    P := 16;
    while P + 4 <= ALen do
    begin
      Etiq := LeU16(ABuf, P);
      TamB := LeU16(ABuf, P + 2);
      if (TamB < 4) or (P + TamB > ALen) or (Etiq = NAV_TAG_CHECKSUM) then
        Break;
      if (Etiq = NAV_TAG_DEMO) and (TamB >= 4 + 36) then
      begin
        FNav.Battery := Integer(LeU32(ABuf, P + 8));
        FNav.Pitch := LeF32(ABuf, P + 12) / 1000;
        FNav.Roll := LeF32(ABuf, P + 16) / 1000;
        FNav.Heading := LeF32(ABuf, P + 20) / 1000;
        FNav.Altitude := LongInt(LeU32(ABuf, P + 24)) / 1000;
        FNav.VelX := LeF32(ABuf, P + 28) / 1000;
        FNav.VelY := LeF32(ABuf, P + 32) / 1000;
        FNav.VelZ := LeF32(ABuf, P + 36) / 1000;
      end;
      Inc(P, TamB);
    end;
    // Ainda em modo de inicialização: pede de novo o modo "demo".
    if ((FNav.State and ARDRONE_STATE_NAVDATA_BOOTSTRAP) <> 0) and
      (FConfigs.IndexOf('"general:navdata_demo","TRUE"') < 0) then
      FConfigs.Add('"general:navdata_demo","TRUE"');
    Emergiu := ((FNav.State and ARDRONE_STATE_EMERGENCY) <> 0) and
      ((Anterior and ARDRONE_STATE_EMERGENCY) = 0);
    if Emergiu then
      FFly := False;
    BateriaBaixa := ((FNav.State and ARDRONE_STATE_VBAT_LOW) <> 0) and
      ((Anterior and ARDRONE_STATE_VBAT_LOW) = 0);
  finally
    FLock.Leave;
  end;
  Inc(FNavPackets);
  if Primeira then
    PostStatus('Telemetria recebida.');
  if Emergiu then
    PostStatus('Drone em modo de EMERGÊNCIA (motores parados).');
  if BateriaBaixa then
    PostStatus('Bateria baixa: pouse o drone.');
  PostTelemetry;
end;

procedure TAIDroneARDrone.SetVideoConnected(AValue: Boolean);
begin
  if FVideoConnected <> AValue then
  begin
    FVideoConnected := AValue;
    PostStateChange;
  end;
end;

function TAIDroneARDrone.GetNavdata: TAIARDroneNavdata;
begin
  FLock.Enter;
  try
    Result := FNav;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneARDrone.GetFlying: Boolean;
begin
  FLock.Enter;
  try
    Result := FFly;
  finally
    FLock.Leave;
  end;
end;

class function TAIDroneARDrone.FloatToAT(AValue: Single): LongInt;
begin
  Move(AValue, Result, SizeOf(Result));
end;

class function TAIDroneARDrone.StateText(const ANav: TAIARDroneNavdata): string;
begin
  if not ANav.Valid then
    Exit('sem telemetria');
  if (ANav.State and ARDRONE_STATE_EMERGENCY) <> 0 then
    Result := 'EMERGÊNCIA'
  else if (ANav.State and ARDRONE_STATE_FLY) <> 0 then
    Result := 'voando'
  else
    Result := 'pousado';
  if (ANav.State and ARDRONE_STATE_VBAT_LOW) <> 0 then
    Result := Result + ' / BATERIA BAIXA';
  if (ANav.State and ARDRONE_STATE_CUTOUT) <> 0 then
    Result := Result + ' / motor travado';
end;

initialization
  {$I aidroneardrone_icon.lrs}

end.
