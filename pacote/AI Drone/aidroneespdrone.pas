unit aidroneespdrone;

{ TAIDroneESPDrone
  ----------------
  ESP-Drone (Espressif) e derivados "OpenDrone" com firmware Crazyflie:
  pacotes CRTP sobre UDP.

  Rede do drone (ponto de acesso "ESP-DRONE_xxxx"): IP 192.168.43.42.
    UDP 2390 - o drone recebe os pacotes CRTP
    UDP 2399 - o aplicativo recebe as respostas (porta local)

  Pacote: cabeçalho CRTP + dados + soma de verificação (soma simples de
  todos os bytes anteriores, módulo 256).
  Comando de voo (porta 3 "commander", canal 0, cabeçalho 0x3C):
    rolagem f32 (graus), arfagem f32 (graus, enviada com o sinal invertido,
    como faz o cflib), guinada f32 (graus/s), aceleração u16 (0..60000).

  Segurança:
    - o firmware só aceita aceleração depois de receber aceleração zero
      (trava de aceleração); o componente envia zeros ao conectar e só libera
      a aceleração depois que o manche volta ao mínimo;
    - sem SetSticks por StickTimeoutMs, a aceleração vai a zero;
    - ao desconectar, envia aceleração zero algumas vezes. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Math, aibase, aidronebase, LResources;

const
  ESPDRONE_DEFAULT_HOST = '192.168.43.42';
  ESPDRONE_PORT_DRONE = 2390;
  ESPDRONE_PORT_APP = 2399;
  ESPDRONE_MAX_THRUST = 60000;
  ESPDRONE_CRTP_COMMANDER = $3C; // porta 3, canal 0, bits de enlace

type

  { TAIDroneESPDrone }

  TAIDroneESPDrone = class(TAIDroneBase)
  private
    FHost: string;
    FPort: Integer;
    FLocalPort: Integer;
    FSendIntervalMs: Integer;
    FStickTimeoutMs: Integer;
    FMaxAngle: Double;
    FMaxYawRate: Double;
    FMaxThrust: Integer;
    FThread: TThread;
    FLock: TCriticalSection;
    FRoll, FPitch, FYaw, FThrottle: Double;
    FStickTick: QWord;
    FThrustUnlocked: Boolean;
    FLockWarned: Boolean;
    FLinkAlive: Boolean;
    FLastReplyTick: QWord;
    FPacketsSent: Int64;
    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
  public
    { Uso interno da linha de rede. }
    function CurrentPacket(out APacket: TBytes): Boolean;
    procedure NoteReply;
    procedure CheckLink;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Connect;
    procedure Disconnect;

    { Rolagem/arfagem/guinada -1..1 (+ = direita/frente/horário),
      aceleração 0..1. }
    procedure SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
    { Aceleração zero e manche no centro (também volta a travar). }
    procedure Stop;

    { Monta um pacote CRTP com a soma de verificação. }
    class function BuildPacket(AHeader: Byte; const AData: array of Byte): TBytes; static;
    class function BuildCommander(ARollDeg, APitchDeg, AYawRate: Single;
      AThrust: Word): TBytes; static;

    property Active: Boolean read GetActive write SetActive;
    { True enquanto o drone responde (respostas nos últimos 2 s). }
    property LinkAlive: Boolean read FLinkAlive;
    property ThrustUnlocked: Boolean read FThrustUnlocked;
    property PacketsSent: Int64 read FPacketsSent;
  published
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default ESPDRONE_PORT_DRONE;
    property LocalPort: Integer read FLocalPort write FLocalPort default ESPDRONE_PORT_APP;
    property SendIntervalMs: Integer read FSendIntervalMs write FSendIntervalMs default 20;
    property StickTimeoutMs: Integer read FStickTimeoutMs write FStickTimeoutMs default 500;
    { Ângulo máximo de rolagem/arfagem (graus). }
    property MaxAngle: Double read FMaxAngle write FMaxAngle;
    { Velocidade máxima de guinada (graus/s). }
    property MaxYawRate: Double read FMaxYawRate write FMaxYawRate;
    property MaxThrust: Integer read FMaxThrust write FMaxThrust default ESPDRONE_MAX_THRUST;
    property OnStatus;
    property OnError;
    property OnStateChange;
  end;

procedure Register;

implementation

uses
  aisockets;

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneESPDrone]);
end;

type

  { TESPDroneThread }

  TESPDroneThread = class(TAIDroneWorker)
  private
    FOwner: TAIDroneESPDrone;
    FHost: string;
    FPort, FLocalPort, FIntervalMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneESPDrone);
  end;

constructor TESPDroneThread.Create(AOwner: TAIDroneESPDrone);
begin
  FOwner := AOwner;
  FHost := Trim(AOwner.Host);
  if FHost = '' then
    FHost := ESPDRONE_DEFAULT_HOST;
  FPort := AOwner.Port;
  FLocalPort := AOwner.LocalPort;
  FIntervalMs := EnsureRange(AOwner.SendIntervalMs, 10, 200);
  inherited Create;
end;

procedure TESPDroneThread.Execute;
var
  Udp: TAISocketUDP;
  Buf: array[0..1023] of Byte;
  Pacote: TBytes;
  N, PortaDe, I: Integer;
  IP: string;
  Prox: QWord;
begin
  Pacote := nil;
  Udp := TAISocketUDP.Create(nil);
  try
    Udp.Host := FHost;
    Udp.Port := FPort;
    Udp.LocalPort := FLocalPort;
    if not Udp.OpenSocket then
    begin
      // Porta local ocupada: segue com uma porta qualquer.
      Udp.LocalPort := 0;
      if not Udp.OpenSocket then
      begin
        FOwner.PostError('Não foi possível abrir o UDP: ' + Udp.LastError);
        Exit;
      end;
      FOwner.PostStatus(Format('Porta local %d ocupada: usando outra.', [FLocalPort]));
    end;
    FOwner.PostStatus(Format('ESP-Drone: enviando para %s:%d.', [FHost, FPort]));
    Prox := 0;
    while not Terminated do
    begin
      if GetTickCount64 >= Prox then
      begin
        if FOwner.CurrentPacket(Pacote) then
          Udp.SendBufferTo(Pacote[0], Length(Pacote), FHost, FPort);
        Prox := GetTickCount64 + QWord(FIntervalMs);
      end;
      N := Udp.ReceiveBuffer(Buf, SizeOf(Buf), 5, IP, PortaDe);
      if N > 0 then
        FOwner.NoteReply;
      FOwner.CheckLink;
    end;
    // Saída: aceleração zero.
    Pacote := TAIDroneESPDrone.BuildCommander(0, 0, 0, 0);
    for I := 1 to 5 do
    begin
      Udp.SendBufferTo(Pacote[0], Length(Pacote), FHost, FPort);
      Sleep(20);
    end;
  finally
    Udp.Free;
  end;
end;

{ TAIDroneESPDrone }

constructor TAIDroneESPDrone.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  Prompt := 'Component TAIDroneESPDrone controls Espressif ESP-Drone / OpenDrone quadcopters ' +
    '(Crazyflie firmware) with CRTP packets over UDP: drone 192.168.43.42 port 2390, app port ' +
    '2399, commander packet header 0x3C (roll, pitch, yaw rate as float32, thrust uint16 ' +
    '0..60000) plus byte-sum checksum. Methods: Connect, Disconnect, SetSticks(Roll, Pitch, ' +
    'Yaw: -1..1; Throttle: 0..1), Stop. Thrust stays locked until throttle returns to zero. ' +
    'Events: OnStatus, OnError, OnStateChange (link up/down).';
  FHost := ESPDRONE_DEFAULT_HOST;
  FPort := ESPDRONE_PORT_DRONE;
  FLocalPort := ESPDRONE_PORT_APP;
  FSendIntervalMs := 20;
  FStickTimeoutMs := 500;
  FMaxAngle := 20;
  FMaxYawRate := 120;
  FMaxThrust := ESPDRONE_MAX_THRUST;
  FLock := TCriticalSection.Create;
end;

destructor TAIDroneESPDrone.Destroy;
begin
  Disconnect;
  CancelPendingEvents;
  FLock.Free;
  inherited Destroy;
end;

function TAIDroneESPDrone.GetActive: Boolean;
begin
  Result := Assigned(FThread);
end;

procedure TAIDroneESPDrone.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

procedure TAIDroneESPDrone.Connect;
begin
  if Assigned(FThread) then
    Exit;
  ClearError;
  FLock.Enter;
  try
    FRoll := 0; FPitch := 0; FYaw := 0; FThrottle := 0;
    FStickTick := 0;
    FThrustUnlocked := False;
    FLockWarned := False;
    FLinkAlive := False;
    FLastReplyTick := 0;
    FPacketsSent := 0;
  finally
    FLock.Leave;
  end;
  FThread := TESPDroneThread.Create(Self);
end;

procedure TAIDroneESPDrone.Disconnect;
begin
  if not Assigned(FThread) then
    Exit;
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);
  FLinkAlive := False;
  PostStatus('ESP-Drone desconectado.');
  PostStateChange;
end;

procedure TAIDroneESPDrone.SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
begin
  if IsNan(AThrottle) then
    AThrottle := 0;
  FLock.Enter;
  try
    FRoll := ClampAxis(ARoll);
    FPitch := ClampAxis(APitch);
    FYaw := ClampAxis(AYaw);
    FThrottle := EnsureRange(AThrottle, 0.0, 1.0);
    FStickTick := GetTickCount64;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneESPDrone.Stop;
begin
  FLock.Enter;
  try
    FRoll := 0; FPitch := 0; FYaw := 0; FThrottle := 0;
    FStickTick := 0; // volta a exigir o manche no mínimo
    FThrustUnlocked := False;
    FLockWarned := False;
  finally
    FLock.Leave;
  end;
end;

class function TAIDroneESPDrone.BuildPacket(AHeader: Byte; const AData: array of Byte): TBytes;
var
  I: Integer;
  Soma: Byte;
begin
  Result := nil;
  SetLength(Result, Length(AData) + 2);
  Result[0] := AHeader;
  Soma := AHeader;
  for I := 0 to High(AData) do
  begin
    Result[I + 1] := AData[I];
    Soma := Byte(Soma + AData[I]);
  end;
  Result[High(Result)] := Soma;
end;

class function TAIDroneESPDrone.BuildCommander(ARollDeg, APitchDeg, AYawRate: Single;
  AThrust: Word): TBytes;
var
  D: array[0..13] of Byte;
  P: Single;
begin
  P := -APitchDeg; // convenção do cflib
  Move(ARollDeg, D[0], 4);
  Move(P, D[4], 4);
  Move(AYawRate, D[8], 4);
  D[12] := Lo(AThrust);
  D[13] := Hi(AThrust);
  Result := BuildPacket(ESPDRONE_CRTP_COMMANDER, D);
end;

function TAIDroneESPDrone.CurrentPacket(out APacket: TBytes): Boolean;
var
  R, P, Y, T: Double;
  Avisar: Boolean;
  Thrust: Integer;
begin
  Avisar := False;
  FLock.Enter;
  try
    R := FRoll; P := FPitch; Y := FYaw; T := FThrottle;
    // Só o manche do usuário no mínimo libera a aceleração.
    if (FStickTick > 0) and (T <= 0.02) then
      FThrustUnlocked := True;
    if (FStickTimeoutMs > 0) and (GetTickCount64 - FStickTick > QWord(FStickTimeoutMs)) then
    begin
      R := 0; P := 0; Y := 0; T := 0;
    end;
    if not FThrustUnlocked then
    begin
      T := 0;
      Avisar := not FLockWarned;
      FLockWarned := True;
    end;
    Inc(FPacketsSent);
  finally
    FLock.Leave;
  end;
  if Avisar then
    PostStatus('Aceleração travada: baixe o manche ao mínimo para liberar.');
  Thrust := EnsureRange(Round(T * EnsureRange(FMaxThrust, 0, 65535)), 0, 65535);
  APacket := BuildCommander(R * FMaxAngle, P * FMaxAngle, Y * FMaxYawRate, Word(Thrust));
  Result := True;
end;

procedure TAIDroneESPDrone.NoteReply;
begin
  FLastReplyTick := GetTickCount64;
  if not FLinkAlive then
  begin
    FLinkAlive := True;
    PostStatus('ESP-Drone respondendo.');
    PostStateChange;
  end;
end;

procedure TAIDroneESPDrone.CheckLink;
begin
  if FLinkAlive and (GetTickCount64 - FLastReplyTick > 2000) then
  begin
    FLinkAlive := False;
    PostStatus('ESP-Drone sem resposta.');
    PostStateChange;
  end;
end;

initialization
  {$I aidroneespdrone_icon.lrs}

end.
