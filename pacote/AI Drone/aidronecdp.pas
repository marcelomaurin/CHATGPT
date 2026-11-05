unit aidronecdp;

{ TAIDroneCDP
  -----------
  Drone ESP32 com o firmware "Cockpit Drone" (protocolo CDP v1).
  Firmware e especificação: marcelomaurin/cockpit_drone, pasta
  firmware/esp32_drone (PROTOCOLO.md).

  Rede: ponto de acesso "CockpitDrone-XXXX", IP 192.168.4.1, UDP 4210.
  Pacote: 'C' 'D' versão tipo seq(u16) dados... CRC-16/CCITT-FALSE (u16).
    0x01 CONTROLE   (componente -> drone, a cada 30 ms; também sinal de vida)
         rolagem, arfagem, guinada: i16 -1000..1000; aceleração u16 0..1000;
         sinalizadores: bit0 = armar, bit1 = CORTE
    0x02 CALIBRAR   (só desarmado)
    0x81 TELEMETRIA (drone -> componente, 10 Hz)

  O firmware só arma com a aceleração no mínimo, desce e desarma sozinho se o
  sinal sumir por 500 ms, corta os motores se capotar e trava após um CORTE.

  Toda a comunicação roda numa linha própria; os métodos podem ser chamados da
  linha principal. Eventos na linha principal: OnStatus, OnError,
  OnStateChange (telemetria começou/parou), OnTelemetry. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Math, aibase, aidronebase, LResources;

const
  CDP_DEFAULT_HOST = '192.168.4.1';
  CDP_DEFAULT_PORT = 4210;

  CDP_STATE_DISARMED = 0;
  CDP_STATE_ARMED = 1;
  CDP_STATE_SIGNAL_LOST = 2;
  CDP_STATE_CUT = 3;
  CDP_STATE_CALIBRATING = 4;
  CDP_STATE_SENSOR_ERROR = 5;

  CDP_ALERT_LOW_BATTERY = $01;
  CDP_ALERT_SENSOR_OK = $02;
  CDP_ALERT_THROTTLE_HIGH = $04;
  CDP_ALERT_TILTED = $08;

type
  TAICdpTelemetry = record
    Valid: Boolean;
    State: Byte;
    BatteryMv: Integer;
    Roll, Pitch, Heading: Double;   // graus
    Throttle: Integer;              // 0..1000 aplicada
    Rssi: Integer;                  // dBm
    LoopHz: Integer;
    Alerts: Byte;
    ControlsPerSecond: Integer;
    ReceivedTick: QWord;
  end;

  { TAIDroneCDP }

  TAIDroneCDP = class(TAIDroneBase)
  private
    FHost: string;
    FPort: Integer;
    FSendIntervalMs: Integer;
    FStickTimeoutMs: Integer;
    FWorker: TThread;
    FLock: TCriticalSection;
    FTel: TAICdpTelemetry;
    FRoll, FPitch, FYaw: SmallInt;
    FThrottle: Word;
    FStickTick: QWord;
    FArm: Boolean;
    FCutTicks: Integer;
    FCalibrate: Boolean;
    FPacketsSent: Int64;
    FTelemetryPackets: Int64;
    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    function GetTelemetry: TAICdpTelemetry;
    function GetArmRequested: Boolean;
  public
    { Uso interno da linha de rede. }
    function BuildControl(out ACalibrate: Boolean): TBytes;
    procedure ReceiveTelemetry(const ABuf: array of Byte; ALen: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Connect;
    { Desarma e zera a aceleração antes de fechar. }
    procedure Disconnect;

    { Rolagem/arfagem/guinada -1..1 (+ = direita/frente/direita), aceleração 0..1.
      Sem atualização por StickTimeoutMs, rolagem/arfagem/guinada voltam ao
      centro (a aceleração é mantida: sem altímetro, zerá-la derrubaria o drone). }
    procedure SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
    { Pede para armar (o firmware exige aceleração no mínimo). }
    procedure Arm;
    procedure Disarm;
    { Corta os motores na hora. Para voltar: Arm de novo. }
    procedure Cut;
    { Calibra o sensor (desarmado, parado e nivelado). }
    procedure Calibrate;

    class function CRC16(const AData: array of Byte; ACount: Integer): Word; static;
    class function StateText(AState: Byte): string; static;

    property Active: Boolean read GetActive write SetActive;
    property ArmRequested: Boolean read GetArmRequested;
    property Telemetry: TAICdpTelemetry read GetTelemetry;
    property PacketsSent: Int64 read FPacketsSent;
    property TelemetryPackets: Int64 read FTelemetryPackets;
  published
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default CDP_DEFAULT_PORT;
    property SendIntervalMs: Integer read FSendIntervalMs write FSendIntervalMs default 30;
    property StickTimeoutMs: Integer read FStickTimeoutMs write FStickTimeoutMs default 500;
    property OnStatus;
    property OnError;
    property OnStateChange;
    property OnTelemetry;
  end;

procedure Register;

implementation

uses
  aisockets;

const
  CDP_MAGIC0 = $43;
  CDP_MAGIC1 = $44;
  CDP_VERSION = 1;
  CDP_CONTROL = $01;
  CDP_CALIBRATE = $02;
  CDP_TELEMETRY = $81;
  CDP_HEADER = 6;
  FLAG_ARM = $01;
  FLAG_CUT = $02;

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneCDP]);
end;

function LeS16(const B: array of Byte; P: Integer): SmallInt;
begin
  Result := SmallInt(Word(B[P]) or (Word(B[P + 1]) shl 8));
end;

function LeU16(const B: array of Byte; P: Integer): Word;
begin
  Result := Word(B[P]) or (Word(B[P + 1]) shl 8);
end;

type

  { TCdpWorker }

  TCdpWorker = class(TAIDroneWorker)
  private
    FOwner: TAIDroneCDP;
    FHost: string;
    FPort: Integer;
    FIntervalMs: Integer;
    FSeq: Word;
    function Packet(AType: Byte; const AData: array of Byte; ALen: Integer): TBytes;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneCDP);
  end;

constructor TCdpWorker.Create(AOwner: TAIDroneCDP);
begin
  FOwner := AOwner;
  FHost := Trim(AOwner.Host);
  if FHost = '' then
    FHost := CDP_DEFAULT_HOST;
  FPort := AOwner.Port;
  if FPort <= 0 then
    FPort := CDP_DEFAULT_PORT;
  FIntervalMs := EnsureRange(AOwner.SendIntervalMs, 10, 200);
  inherited Create;
end;

function TCdpWorker.Packet(AType: Byte; const AData: array of Byte; ALen: Integer): TBytes;
var
  N: Integer;
  C: Word;
begin
  Result := nil;
  N := CDP_HEADER + ALen + 2;
  SetLength(Result, N);
  Result[0] := CDP_MAGIC0;
  Result[1] := CDP_MAGIC1;
  Result[2] := CDP_VERSION;
  Result[3] := AType;
  Inc(FSeq);
  Result[4] := Lo(FSeq);
  Result[5] := Hi(FSeq);
  if ALen > 0 then
    Move(AData[0], Result[CDP_HEADER], ALen);
  C := TAIDroneCDP.CRC16(Result, N - 2);
  Result[N - 2] := Lo(C);
  Result[N - 1] := Hi(C);
end;

procedure TCdpWorker.Execute;
var
  Udp: TAISocketUDP;
  Buf: array[0..511] of Byte;
  Pkt: TBytes;
  N, Porta, I: Integer;
  IP: string;
  Prox, Agora: QWord;
  Calibrar, Recebendo: Boolean;
  UltimaTel: QWord;
  Vazio: array[0..0] of Byte;
begin
  Udp := TAISocketUDP.Create(nil);
  try
    Udp.Host := FHost;
    Udp.Port := FPort;
    Udp.LocalPort := 0;
    if not Udp.OpenSocket then
    begin
      FOwner.PostError('Não foi possível abrir o UDP: ' + Udp.LastError);
      Exit;
    end;
    FOwner.PostStatus(Format('Drone ESP32: enviando para %s:%d...', [FHost, FPort]));
    Prox := GetTickCount64;
    UltimaTel := 0;
    Recebendo := False;
    Vazio[0] := 0;

    while not Terminated do
    begin
      Agora := GetTickCount64;
      if Agora >= Prox then
      begin
        Pkt := FOwner.BuildControl(Calibrar);
        Udp.SendBuffer(Pkt[0], Length(Pkt));
        if Calibrar then
        begin
          Pkt := Packet(CDP_CALIBRATE, Vazio, 0);
          Udp.SendBuffer(Pkt[0], Length(Pkt));
        end;
        Inc(Prox, FIntervalMs);
        if Prox < Agora then
          Prox := Agora + QWord(FIntervalMs);
      end;

      N := Udp.ReceiveBuffer(Buf, SizeOf(Buf), 5, IP, Porta);
      if N > 0 then
      begin
        FOwner.ReceiveTelemetry(Buf, N);
        UltimaTel := GetTickCount64;
        if not Recebendo then
        begin
          Recebendo := True;
          FOwner.PostStateChange;
        end;
      end;
      if Recebendo and (GetTickCount64 - UltimaTel > 2000) then
      begin
        Recebendo := False;
        FOwner.PostStatus('Sem telemetria do drone há 2 s.');
        FOwner.PostStateChange;
      end;
    end;

    // Desarma e zera a aceleração antes de soltar o canal.
    FOwner.Disarm;
    FOwner.SetSticks(0, 0, 0, 0);
    for I := 1 to 5 do
    begin
      Pkt := FOwner.BuildControl(Calibrar);
      Udp.SendBuffer(Pkt[0], Length(Pkt));
      Sleep(20);
    end;
  finally
    Udp.Free;
  end;
end;

{ TAIDroneCDP }

constructor TAIDroneCDP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  Prompt := 'Component TAIDroneCDP controls the ESP32 drone with the Cockpit Drone firmware ' +
    '(CDP v1 protocol, UDP 4210, host 192.168.4.1). Methods: Connect, Disconnect, ' +
    'SetSticks(Roll, Pitch, Yaw: -1..1; Throttle: 0..1), Arm (throttle must be at minimum), ' +
    'Disarm, Cut (kills motors), Calibrate. Telemetry: state, battery, attitude, throttle, RSSI, ' +
    'alerts. Events: OnStatus, OnError, OnStateChange, OnTelemetry.';
  FHost := CDP_DEFAULT_HOST;
  FPort := CDP_DEFAULT_PORT;
  FSendIntervalMs := 30;
  FStickTimeoutMs := 500;
  FLock := TCriticalSection.Create;
end;

destructor TAIDroneCDP.Destroy;
begin
  Disconnect;
  CancelPendingEvents;
  FLock.Free;
  inherited Destroy;
end;

function TAIDroneCDP.GetActive: Boolean;
begin
  Result := Assigned(FWorker);
end;

procedure TAIDroneCDP.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

procedure TAIDroneCDP.Connect;
begin
  if Assigned(FWorker) then
    Exit;
  ClearError;
  FLock.Enter;
  try
    FillChar(FTel, SizeOf(FTel), 0);
    FRoll := 0; FPitch := 0; FYaw := 0; FThrottle := 0;
    FArm := False;
    FCutTicks := 0;
    FCalibrate := False;
    FStickTick := GetTickCount64;
  finally
    FLock.Leave;
  end;
  FPacketsSent := 0;
  FTelemetryPackets := 0;
  FWorker := TCdpWorker.Create(Self);
end;

procedure TAIDroneCDP.Disconnect;
begin
  if not Assigned(FWorker) then
    Exit;
  FWorker.Terminate;
  FWorker.WaitFor;
  FreeAndNil(FWorker);
  PostStatus('Drone ESP32 desconectado.');
  PostStateChange;
end;

procedure TAIDroneCDP.SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
begin
  if IsNan(AThrottle) then
    AThrottle := 0;
  FLock.Enter;
  try
    FRoll := Round(ClampAxis(ARoll) * 1000);
    FPitch := Round(ClampAxis(APitch) * 1000);
    FYaw := Round(ClampAxis(AYaw) * 1000);
    FThrottle := Round(EnsureRange(AThrottle, 0.0, 1.0) * 1000);
    FStickTick := GetTickCount64;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneCDP.Arm;
var
  AlertaAcel: Boolean;
begin
  FLock.Enter;
  try
    FCutTicks := 0;
    FArm := True;
    AlertaAcel := FTel.Valid and ((FTel.Alerts and CDP_ALERT_THROTTLE_HIGH) <> 0);
  finally
    FLock.Leave;
  end;
  if AlertaAcel then
    PostStatus('Para armar, leve a aceleração ao mínimo.');
  PostStatus('Pedido de armar enviado.');
end;

procedure TAIDroneCDP.Disarm;
begin
  FLock.Enter;
  try
    FArm := False;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneCDP.Cut;
begin
  FLock.Enter;
  try
    FArm := False;
    FCutTicks := 15; // ~0,5 s de corte; depois o firmware espera um novo armar
  finally
    FLock.Leave;
  end;
  PostStatus('CORTE: motores desligados.');
end;

procedure TAIDroneCDP.Calibrate;
var
  Armado: Boolean;
begin
  FLock.Enter;
  try
    Armado := FArm;
    if not Armado then
      FCalibrate := True;
  finally
    FLock.Leave;
  end;
  if Armado then
    PostStatus('Calibração só com o drone desarmado.')
  else
    PostStatus('Calibrando: mantenha o drone parado e nivelado.');
end;

function TAIDroneCDP.BuildControl(out ACalibrate: Boolean): TBytes;
var
  D: array[0..8] of Byte;
  R, P, Y: SmallInt;
  T: Word;
  Flags: Byte;
  Seq: Word;
  N: Integer;
  C: Word;
begin
  FLock.Enter;
  try
    R := FRoll; P := FPitch; Y := FYaw; T := FThrottle;
    if (FStickTimeoutMs > 0) and (GetTickCount64 - FStickTick > QWord(FStickTimeoutMs)) then
    begin
      R := 0; P := 0; Y := 0;
    end;
    Flags := 0;
    if FArm then
      Flags := Flags or FLAG_ARM;
    if FCutTicks > 0 then
    begin
      Flags := Flags or FLAG_CUT;
      Dec(FCutTicks);
    end;
    ACalibrate := FCalibrate;
    FCalibrate := False;
    Inc(FPacketsSent);
    Seq := Word(FPacketsSent);
  finally
    FLock.Leave;
  end;
  D[0] := Lo(Word(R)); D[1] := Hi(Word(R));
  D[2] := Lo(Word(P)); D[3] := Hi(Word(P));
  D[4] := Lo(Word(Y)); D[5] := Hi(Word(Y));
  D[6] := Lo(T);       D[7] := Hi(T);
  D[8] := Flags;
  N := CDP_HEADER + 9 + 2;
  Result := nil;
  SetLength(Result, N);
  Result[0] := CDP_MAGIC0;
  Result[1] := CDP_MAGIC1;
  Result[2] := CDP_VERSION;
  Result[3] := CDP_CONTROL;
  Result[4] := Lo(Seq);
  Result[5] := Hi(Seq);
  Move(D[0], Result[CDP_HEADER], 9);
  C := CRC16(Result, N - 2);
  Result[N - 2] := Lo(C);
  Result[N - 1] := Hi(C);
end;

procedure TAIDroneCDP.ReceiveTelemetry(const ABuf: array of Byte; ALen: Integer);
var
  Anterior: Byte;
  Primeira, DesarmouSozinho: Boolean;
begin
  if (ALen <> CDP_HEADER + 17 + 2) or (ABuf[0] <> CDP_MAGIC0) or (ABuf[1] <> CDP_MAGIC1) or
    (ABuf[2] <> CDP_VERSION) or (ABuf[3] <> CDP_TELEMETRY) then
    Exit;
  if CRC16(ABuf, ALen - 2) <> LeU16(ABuf, ALen - 2) then
    Exit;

  FLock.Enter;
  try
    Primeira := not FTel.Valid;
    Anterior := FTel.State;
    FTel.Valid := True;
    FTel.State := ABuf[6];
    FTel.BatteryMv := LeU16(ABuf, 7);
    FTel.Roll := LeS16(ABuf, 9) / 100;
    FTel.Pitch := LeS16(ABuf, 11) / 100;
    FTel.Heading := LeS16(ABuf, 13) / 100;
    FTel.Throttle := LeU16(ABuf, 15);
    FTel.Rssi := ShortInt(ABuf[17]);
    FTel.LoopHz := LeU16(ABuf, 18);
    FTel.Alerts := ABuf[20];
    FTel.ControlsPerSecond := LeU16(ABuf, 21);
    FTel.ReceivedTick := GetTickCount64;
    // O firmware desarmou sozinho (perda de sinal, capotou, corte): acompanha.
    DesarmouSozinho := FArm and (Anterior = CDP_STATE_ARMED) and
      (FTel.State in [CDP_STATE_DISARMED, CDP_STATE_CUT, CDP_STATE_SENSOR_ERROR]);
    if DesarmouSozinho then
      FArm := False;
  finally
    FLock.Leave;
  end;
  Inc(FTelemetryPackets);

  if Primeira then
    PostStatus('Telemetria recebida: drone ' + StateText(ABuf[6]) + '.')
  else if ABuf[6] <> Anterior then
    PostStatus('Drone: ' + StateText(ABuf[6]) + '.');
  PostTelemetry;
end;

function TAIDroneCDP.GetTelemetry: TAICdpTelemetry;
begin
  FLock.Enter;
  try
    Result := FTel;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneCDP.GetArmRequested: Boolean;
begin
  FLock.Enter;
  try
    Result := FArm;
  finally
    FLock.Leave;
  end;
end;

class function TAIDroneCDP.CRC16(const AData: array of Byte; ACount: Integer): Word;
var
  I, J: Integer;
begin
  Result := $FFFF;
  for I := 0 to ACount - 1 do
  begin
    Result := Result xor (Word(AData[I]) shl 8);
    for J := 1 to 8 do
      if (Result and $8000) <> 0 then
        Result := Word((Result shl 1) xor $1021)
      else
        Result := Word(Result shl 1);
  end;
end;

class function TAIDroneCDP.StateText(AState: Byte): string;
begin
  case AState of
    CDP_STATE_DISARMED: Result := 'desarmado';
    CDP_STATE_ARMED: Result := 'ARMADO';
    CDP_STATE_SIGNAL_LOST: Result := 'perda de sinal (descendo)';
    CDP_STATE_CUT: Result := 'CORTE';
    CDP_STATE_CALIBRATING: Result := 'calibrando';
    CDP_STATE_SENSOR_ERROR: Result := 'erro no sensor';
  else
    Result := 'desconhecido (' + IntToStr(AState) + ')';
  end;
end;

initialization
  {$I aidronecdp_icon.lrs}

end.
