unit aidronetello;

{ TAIDroneTello
  -------------
  DJI/Ryze Tello (SDK em texto da Ryze).

  Rede do drone (ponto de acesso "TELLO-xxxxxx"): IP 192.168.10.1.
    UDP 8889  - comandos em texto; o drone responde "ok" ou "error ..."
                ("command" entra no modo SDK; "takeoff", "land", "emergency",
                "streamon"; "rc a b c d" não tem resposta)
    UDP 8890  - telemetria em texto ("pitch:0;roll:0;yaw:0;...;bat:87;h:0;...")
                enviada para a porta local 8890 (o componente escuta nela)
    UDP 11111 - vídeo H.264 bruto (960x720) para a porta local 11111

  rc a b c d (-100..100): a = rolagem (+ direita), b = arfagem (+ frente),
  c = subida (+ sobe), d = guinada (+ horário). Enviado a cada SendIntervalMs.

  Segurança:
    - manche no centro = pairar; sem SetSticks por StickTimeoutMs, paira;
    - ao desconectar (LandOnDisconnect), manda pousar;
    - o próprio Tello pousa sozinho após 15 s sem comandos.

  Eventos na linha principal: OnStatus, OnError, OnStateChange (modo SDK
  confirmado / perdido), OnTelemetry. OnVideoData: linha de rede. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Math, aibase, aidronebase, LResources;

const
  TELLO_DEFAULT_HOST = '192.168.10.1';
  TELLO_PORT_COMMAND = 8889;
  TELLO_PORT_STATE = 8890;
  TELLO_PORT_VIDEO = 11111;
  TELLO_VIDEO_WIDTH = 960;
  TELLO_VIDEO_HEIGHT = 720;

type
  TAITelloState = record
    Valid: Boolean;
    Battery: Integer;          // %
    Height: Double;            // m (h, relativo à decolagem)
    TimeOfFlight: Double;      // m (tof, sensor de distância ao chão)
    Pitch, Roll, Yaw: Integer; // graus
    SpeedX, SpeedY, SpeedZ: Integer; // dm/s
    TempLow, TempHigh: Integer;
    FlightTime: Integer;       // s com motores ligados
    Raw: string;
    ReceivedTick: QWord;
  end;

  { TAIDroneTello }

  TAIDroneTello = class(TAIDroneBase)
  private
    FHost: string;
    FSendIntervalMs: Integer;
    FStickTimeoutMs: Integer;
    FVideoEnabled: Boolean;
    FLandOnDisconnect: Boolean;
    FControlThread: TThread;
    FVideoThread: TThread;
    FLock: TCriticalSection;
    FState: TAITelloState;
    FA, FB, FC, FD: Integer;
    FStickTick: QWord;
    FPending: TStringList;
    FSdkMode: Boolean;
    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    function GetState: TAITelloState;
  public
    { Uso interno das linhas de rede. }
    function TakePending: string;
    function CurrentRc: string;
    procedure ReceiveState(const AText: string);
    procedure SetSdkMode(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Connect;
    procedure Disconnect;

    { Rolagem/arfagem/guinada -1..1 (+ = direita/frente/horário), subida -1..1
      (+ = sobe). Zero = pairar. }
    procedure SetSticks(ARoll, APitch, AYaw, AClimb: Double);
    procedure Hover;
    procedure TakeOff;
    procedure Land;
    { Para os motores na hora (o drone cai). }
    procedure Emergency;
    { Envia um comando em texto do SDK (ex.: 'flip f', 'speed 50'). }
    procedure SendCommandText(const ACommand: string);

    property Active: Boolean read GetActive write SetActive;
    { True depois que o drone respondeu "ok" ao "command". }
    property SdkMode: Boolean read FSdkMode;
    property State: TAITelloState read GetState;
  published
    property Host: string read FHost write FHost;
    property SendIntervalMs: Integer read FSendIntervalMs write FSendIntervalMs default 50;
    property StickTimeoutMs: Integer read FStickTimeoutMs write FStickTimeoutMs default 500;
    property VideoEnabled: Boolean read FVideoEnabled write FVideoEnabled default True;
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

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneTello]);
end;

type

  { TTelloControlThread: comandos, rc e telemetria }

  TTelloControlThread = class(TAIDroneWorker)
  private
    FOwner: TAIDroneTello;
    FHost: string;
    FIntervalMs: Integer;
    FVideo: Boolean;
    FLand: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneTello);
  end;

  { TTelloVideoThread }

  TTelloVideoThread = class(TAIDroneWorker)
  private
    FOwner: TAIDroneTello;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneTello);
  end;

function TextoDe(const ABuf: array of Byte; N: Integer): string;
begin
  SetString(Result, PChar(@ABuf[0]), N);
  Result := Trim(Result);
end;

{ TTelloControlThread }

constructor TTelloControlThread.Create(AOwner: TAIDroneTello);
begin
  FOwner := AOwner;
  FHost := Trim(AOwner.Host);
  if FHost = '' then
    FHost := TELLO_DEFAULT_HOST;
  FIntervalMs := EnsureRange(AOwner.SendIntervalMs, 20, 500);
  FVideo := AOwner.VideoEnabled;
  FLand := AOwner.LandOnDisconnect;
  inherited Create;
end;

procedure TTelloControlThread.Execute;
var
  Cmd, Est: TAISocketUDP;
  Buf: array[0..2047] of Byte;
  N, Porta, I: Integer;
  IP, Txt, Pendente: string;
  Aguardando: TStringList;
  ProxRc, ProxCommand, UltimaResposta, UltimoEstado: QWord;
  Recebendo: Boolean;

  procedure EnviaTexto(const S: string);
  begin
    if S <> '' then
      Cmd.SendText(S);
  end;

begin
  Cmd := TAISocketUDP.Create(nil);
  Est := TAISocketUDP.Create(nil);
  Aguardando := TStringList.Create;
  try
    Cmd.Host := FHost;
    Cmd.Port := TELLO_PORT_COMMAND;
    Cmd.LocalPort := 0;
    if not Cmd.OpenSocket then
    begin
      FOwner.PostError('Não foi possível abrir o UDP de comandos: ' + Cmd.LastError);
      Exit;
    end;
    Est.Port := TELLO_PORT_STATE;
    Est.LocalPort := TELLO_PORT_STATE;
    if not Est.OpenSocket then
      FOwner.PostStatus('Telemetria indisponível (porta UDP 8890 ocupada?).');

    FOwner.PostStatus(Format('Conectando ao Tello em %s...', [FHost]));
    ProxCommand := 0;
    ProxRc := GetTickCount64;
    UltimaResposta := GetTickCount64;
    UltimoEstado := 0;
    Recebendo := False;

    while not Terminated do
    begin
      // Entra no modo SDK ("command") até o drone responder "ok".
      if (not FOwner.SdkMode) and (GetTickCount64 >= ProxCommand) then
      begin
        Aguardando.Add('command');
        EnviaTexto('command');
        ProxCommand := GetTickCount64 + 1000;
      end;

      if FOwner.SdkMode then
      begin
        Pendente := FOwner.TakePending;
        if Pendente <> '' then
        begin
          Aguardando.Add(Pendente);
          EnviaTexto(Pendente);
        end;
        if GetTickCount64 >= ProxRc then
        begin
          EnviaTexto(FOwner.CurrentRc);
          ProxRc := GetTickCount64 + QWord(FIntervalMs);
        end;
      end;

      // Respostas dos comandos
      N := Cmd.ReceiveBuffer(Buf, SizeOf(Buf), 5, IP, Porta);
      if N > 0 then
      begin
        Txt := TextoDe(Buf, N);
        UltimaResposta := GetTickCount64;
        if Aguardando.Count > 0 then
        begin
          Pendente := Aguardando[0];
          Aguardando.Delete(0);
        end
        else
          Pendente := '';
        if (Pendente = 'command') and (LowerCase(Txt) = 'ok') then
        begin
          if not FOwner.SdkMode then
          begin
            FOwner.SetSdkMode(True);
            FOwner.PostStatus('Tello em modo SDK.');
            if FVideo then
            begin
              Aguardando.Add('streamon');
              EnviaTexto('streamon');
            end;
          end;
        end
        else if Pendente <> '' then
          FOwner.PostStatus(Format('Tello: %s -> %s', [Pendente, Txt]))
        else
          FOwner.PostStatus('Tello: ' + Txt);
      end;

      // Telemetria
      if Est.Active then
      begin
        N := Est.ReceiveBuffer(Buf, SizeOf(Buf), 5, IP, Porta);
        if N > 0 then
        begin
          FOwner.ReceiveState(TextoDe(Buf, N));
          UltimoEstado := GetTickCount64;
          Recebendo := True;
        end;
      end;

      // Sem resposta nem telemetria por 3 s: volta a chamar o modo SDK.
      if FOwner.SdkMode and (GetTickCount64 - UltimaResposta > 3000) and
        ((not Recebendo) or (GetTickCount64 - UltimoEstado > 3000)) then
      begin
        FOwner.SetSdkMode(False);
        Recebendo := False;
        Aguardando.Clear;
        FOwner.PostStatus('Sem resposta do Tello: tentando de novo.');
      end;
    end;

    // Saída: para os movimentos e, se pedido, pousa.
    EnviaTexto('rc 0 0 0 0');
    if FLand and FOwner.SdkMode then
      for I := 1 to 2 do
      begin
        EnviaTexto('land');
        Sleep(50);
      end;
    if FVideo then
      EnviaTexto('streamoff');
  finally
    Aguardando.Free;
    Est.Free;
    Cmd.Free;
  end;
end;

{ TTelloVideoThread }

constructor TTelloVideoThread.Create(AOwner: TAIDroneTello);
begin
  FOwner := AOwner;
  inherited Create;
end;

procedure TTelloVideoThread.Execute;
var
  Udp: TAISocketUDP;
  Buf: array of Byte;
  N, Porta: Integer;
  IP: string;
begin
  Buf := nil;
  SetLength(Buf, 65536);
  Udp := TAISocketUDP.Create(nil);
  try
    Udp.Port := TELLO_PORT_VIDEO;
    Udp.LocalPort := TELLO_PORT_VIDEO;
    if not Udp.OpenSocket then
    begin
      FOwner.PostStatus('Vídeo indisponível (porta UDP 11111 ocupada?).');
      Exit;
    end;
    while not Terminated do
    begin
      N := Udp.ReceiveBuffer(Buf[0], Length(Buf), 100, IP, Porta);
      if N > 0 then
        FOwner.DoVideoData(@Buf[0], N);
    end;
  finally
    Udp.Free;
  end;
end;

{ TAIDroneTello }

constructor TAIDroneTello.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  Prompt := 'Component TAIDroneTello controls the DJI/Ryze Tello (text SDK: commands on UDP ' +
    '8889, state on UDP 8890, H.264 video on UDP 11111, host 192.168.10.1). Methods: Connect, ' +
    'Disconnect, TakeOff, Land, Emergency, SetSticks(Roll, Pitch, Yaw, Climb: -1..1; zero = ' +
    'hover) sent as "rc" every 50 ms, Hover, SendCommandText. State: battery, height, attitude, ' +
    'speeds. Events: OnStatus, OnError, OnStateChange, OnTelemetry, OnVideoData (raw H.264, ' +
    'network thread; feed a TAIH264Decoder).';
  FHost := TELLO_DEFAULT_HOST;
  FSendIntervalMs := 50;
  FStickTimeoutMs := 500;
  FVideoEnabled := True;
  FLandOnDisconnect := True;
  FLock := TCriticalSection.Create;
  FPending := TStringList.Create;
end;

destructor TAIDroneTello.Destroy;
begin
  Disconnect;
  CancelPendingEvents;
  FPending.Free;
  FLock.Free;
  inherited Destroy;
end;

function TAIDroneTello.GetActive: Boolean;
begin
  Result := Assigned(FControlThread);
end;

procedure TAIDroneTello.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

procedure TAIDroneTello.Connect;
begin
  if Assigned(FControlThread) then
    Exit;
  ClearError;
  FLock.Enter;
  try
    FillChar(FState, SizeOf(FState), 0);
    FA := 0; FB := 0; FC := 0; FD := 0;
    FStickTick := 0;
    FPending.Clear;
  finally
    FLock.Leave;
  end;
  FSdkMode := False;
  ResetVideoCounters;
  FControlThread := TTelloControlThread.Create(Self);
  if FVideoEnabled then
    FVideoThread := TTelloVideoThread.Create(Self);
end;

procedure TAIDroneTello.Disconnect;
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
    FSdkMode := False;
    PostStatus('Tello desconectado.');
    PostStateChange;
  end;
end;

procedure TAIDroneTello.SetSticks(ARoll, APitch, AYaw, AClimb: Double);
begin
  FLock.Enter;
  try
    FA := Round(ClampAxis(ARoll) * 100);
    FB := Round(ClampAxis(APitch) * 100);
    FC := Round(ClampAxis(AClimb) * 100);
    FD := Round(ClampAxis(AYaw) * 100);
    FStickTick := GetTickCount64;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneTello.Hover;
begin
  SetSticks(0, 0, 0, 0);
end;

procedure TAIDroneTello.SendCommandText(const ACommand: string);
begin
  if Trim(ACommand) = '' then
    Exit;
  FLock.Enter;
  try
    FPending.Add(Trim(ACommand));
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneTello.TakeOff;
var
  S: TAITelloState;
begin
  S := State;
  if S.Valid and (S.Battery > 0) and (S.Battery < 15) then
  begin
    PostStatus(Format('Bateria em %d%%: decolagem recusada.', [S.Battery]));
    Exit;
  end;
  Hover;
  SendCommandText('takeoff');
  PostStatus('Decolando...');
end;

procedure TAIDroneTello.Land;
begin
  Hover;
  SendCommandText('land');
  PostStatus('Pousando...');
end;

procedure TAIDroneTello.Emergency;
begin
  FLock.Enter;
  try
    // Na frente de tudo o que estiver pendente.
    FPending.Insert(0, 'emergency');
  finally
    FLock.Leave;
  end;
  PostStatus('EMERGÊNCIA: motores parados.');
end;

function TAIDroneTello.TakePending: string;
begin
  Result := '';
  FLock.Enter;
  try
    if FPending.Count > 0 then
    begin
      Result := FPending[0];
      FPending.Delete(0);
    end;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneTello.CurrentRc: string;
var
  A, B, C, D: Integer;
begin
  FLock.Enter;
  try
    A := FA; B := FB; C := FC; D := FD;
    if (FStickTimeoutMs > 0) and (GetTickCount64 - FStickTick > QWord(FStickTimeoutMs)) then
    begin
      A := 0; B := 0; C := 0; D := 0;
    end;
  finally
    FLock.Leave;
  end;
  Result := Format('rc %d %d %d %d', [A, B, C, D]);
end;

procedure TAIDroneTello.ReceiveState(const AText: string);
var
  Partes: TStringList;
  I, P: Integer;
  K, V: string;
  Primeira: Boolean;
  S: TAITelloState;
begin
  Partes := TStringList.Create;
  try
    Partes.Delimiter := ';';
    Partes.StrictDelimiter := True;
    Partes.DelimitedText := AText;
    FLock.Enter;
    try
      Primeira := not FState.Valid;
      S := FState;
    finally
      FLock.Leave;
    end;
    for I := 0 to Partes.Count - 1 do
    begin
      P := Pos(':', Partes[I]);
      if P = 0 then
        Continue;
      K := LowerCase(Trim(Copy(Partes[I], 1, P - 1)));
      V := Trim(Copy(Partes[I], P + 1, MaxInt));
      if K = 'bat' then S.Battery := StrToIntDef(V, S.Battery)
      else if K = 'h' then S.Height := StrToIntDef(V, 0) / 100
      else if K = 'tof' then S.TimeOfFlight := StrToIntDef(V, 0) / 100
      else if K = 'pitch' then S.Pitch := StrToIntDef(V, 0)
      else if K = 'roll' then S.Roll := StrToIntDef(V, 0)
      else if K = 'yaw' then S.Yaw := StrToIntDef(V, 0)
      else if K = 'vgx' then S.SpeedX := StrToIntDef(V, 0)
      else if K = 'vgy' then S.SpeedY := StrToIntDef(V, 0)
      else if K = 'vgz' then S.SpeedZ := StrToIntDef(V, 0)
      else if K = 'templ' then S.TempLow := StrToIntDef(V, 0)
      else if K = 'temph' then S.TempHigh := StrToIntDef(V, 0)
      else if K = 'time' then S.FlightTime := StrToIntDef(V, 0);
    end;
    S.Valid := True;
    S.Raw := AText;
    S.ReceivedTick := GetTickCount64;
    FLock.Enter;
    try
      FState := S;
    finally
      FLock.Leave;
    end;
  finally
    Partes.Free;
  end;
  if Primeira then
    PostStatus(Format('Telemetria do Tello recebida (bateria %d%%).', [S.Battery]));
  PostTelemetry;
end;

procedure TAIDroneTello.SetSdkMode(AValue: Boolean);
begin
  if FSdkMode <> AValue then
  begin
    FSdkMode := AValue;
    PostStateChange;
  end;
end;

function TAIDroneTello.GetState: TAITelloState;
begin
  FLock.Enter;
  try
    Result := FState;
  finally
    FLock.Leave;
  end;
end;

initialization
  {$I aidronetello_icon.lrs}

end.
