unit aidronemavlink;

{ TAIDroneMavlink
  ---------------
  MAVLink para multirrotores com piloto automático ArduPilot (ArduCopter) ou
  PX4: telemetria (GPS, bateria, modo), controle manual, envio de missão
  (rota por pontos) e comandos de voo.

  Rede: UDP. O componente escuta em Port (padrão 14550) e responde ao endereço
  de onde o drone falou (SITL, ponte Wi-Fi ESP8266/ESP32, rádio com ponte UDP).
  Antes de ouvir o drone, envia para Host:Port.

  Envia MAVLink 1 (aceito por ArduPilot e PX4): HEARTBEAT como estação de
  solo, MANUAL_CONTROL, COMMAND_LONG, REQUEST_DATA_STREAM, MISSION_COUNT,
  MISSION_ITEM_INT. Lê MAVLink 1 e 2: HEARTBEAT, SYS_STATUS, GPS_RAW_INT,
  GLOBAL_POSITION_INT, HOME_POSITION, MISSION_REQUEST(_INT), MISSION_ACK,
  MISSION_CURRENT, MISSION_ITEM_REACHED, COMMAND_ACK, STATUSTEXT.

  Toda a comunicação roda numa linha própria. Os métodos públicos podem ser
  chamados da linha principal; a telemetria (Telemetry) é uma cópia segura.
  Eventos na linha principal: OnStatus, OnError, OnStateChange (conexão),
  OnTelemetry (telemetria nova, no máximo ~10 vezes por segundo).

  Segurança:
    - o controle manual (SetSticks) é suspenso durante a rota e nos modos
      autônomos, e deixa de ser enviado se a aplicação parar de atualizá-lo;
    - StartMission só parte com a missão aceita pelo drone; no ArduPilot arma
      em GUIDED (AUTO não é armável) e então inicia a missão;
    - recusas do drone (comando, missão, "PreArm") viram mensagens legíveis.

  Uso:
    Drone.Port := 14550; Drone.Connect;
    M := TAIDroneMavlink.BuildMission(Pontos, 10, mfaReturnToLaunch,
      Drone.Telemetry.HomeLat, Drone.Telemetry.HomeLon,
      Drone.Telemetry.Autopilot = MAV_AUTOPILOT_ARDUPILOT);
    Drone.UploadMission(M);           // aguarde MissionState = msAccepted
    Drone.StartMission;               // arma, decola e executa }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Math, aibase, aidronebase, LResources;

const
  MAV_DEFAULT_PORT = 14550;

  MAV_AUTOPILOT_ARDUPILOT = 3;
  MAV_AUTOPILOT_PX4 = 12;

  MAV_CMD_NAV_WAYPOINT = 16;
  MAV_CMD_NAV_LOITER_UNLIM = 17;
  MAV_CMD_NAV_RETURN_TO_LAUNCH = 20;
  MAV_CMD_NAV_LAND = 21;
  MAV_CMD_NAV_TAKEOFF = 22;
  MAV_CMD_DO_SET_MODE = 176;
  MAV_CMD_DO_CHANGE_SPEED = 178;
  MAV_CMD_MISSION_START = 300;
  MAV_CMD_COMPONENT_ARM_DISARM = 400;
  MAV_CMD_GET_HOME_POSITION = 410;
  MAV_CMD_REQUEST_MESSAGE = 512;

  MAV_FRAME_GLOBAL = 0;
  MAV_FRAME_MISSION = 2;
  MAV_FRAME_GLOBAL_RELATIVE_ALT = 3;

type
  TAIMavTelemetry = record
    Connected: Boolean;
    SysId, CompId: Byte;
    Autopilot, VehicleType: Byte;
    BaseMode: Byte;
    CustomMode: Cardinal;
    Armed: Boolean;
    GpsFix: Integer;          // 0/1 sem fix, 2 = 2D, 3 = 3D, 4+ = DGPS/RTK
    Satellites: Integer;
    Hdop: Double;             // -1 = desconhecido
    PositionValid: Boolean;
    Lat, Lon: Double;
    RelativeAlt: Double;      // m acima do ponto de partida
    Heading: Double;          // graus
    GroundSpeed: Double;      // m/s
    BatteryPct: Integer;      // -1 = desconhecida
    BatteryVoltage: Double;   // 0 = desconhecida
    CurrentItem: Integer;     // item da missão em execução (-1)
    ReachedItem: Integer;     // último item alcançado (-1)
    HomeValid: Boolean;
    HomeLat, HomeLon: Double;
  end;

  TAIMavMissionItem = record
    Command: Word;
    Frame: Byte;
    P1, P2, P3, P4: Single;
    X, Y: LongInt;            // latitude/longitude * 1e7
    Z: Single;                // altitude (m)
    Waypoint: Integer;        // índice do ponto da rota (-1 = item auxiliar)
  end;
  TAIMavMission = array of TAIMavMissionItem;

  TAIMavWaypoint = record
    Lat, Lon: Double;
    Alt: Double;              // m acima do ponto de partida
    Speed: Double;            // m/s
  end;

  TAIMavFinalAction = (mfaReturnToLaunch, mfaLandAtLast, mfaHoverAtLast);
  TAIMavMissionState = (msNone, msUploading, msAccepted, msFailed);
  TAIMavStartState = (ssNone, ssGuidedMode, ssArming, ssStarting);
  { Pedidos internos da linha principal para a linha de rede. }
  TAIMavRequests = array of Integer;

  { TAIDroneMavlink }

  TAIDroneMavlink = class(TAIDroneBase)
  private
    FHost: string;
    FPort: Integer;
    FStickTimeoutMs: Integer;
    FManualControl: Boolean;
    FWorker: TThread;
    FLock: TCriticalSection;

    // Cópias publicadas pela linha de rede (sob FLock)
    FTel: TAIMavTelemetry;
    FMissionState: TAIMavMissionState;
    FMissionMessage: string;
    FMission: TAIMavMission;
    FStartState: TAIMavStartState;
    FRouteActive: Boolean;
    FSocketOk: Boolean;

    // Manche (sob FLock)
    FStickRoll, FStickPitch, FStickYaw, FStickThrottle: Double;
    FStickTick: QWord;

    // Pedidos da linha principal (sob FLock)
    FRequests: TAIMavRequests;
    FRequestMission: TAIMavMission;

    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    function GetTelemetry: TAIMavTelemetry;
    function GetMissionState: TAIMavMissionState;
    function GetMissionMessage: string;
    function GetMission: TAIMavMission;
    function GetStartState: TAIMavStartState;
    function GetRouteActive: Boolean;
    procedure AddRequest(AKind: Integer);
  public
    { Uso interno da linha de rede. }
    procedure PublishState(const ATel: TAIMavTelemetry; AMissionState: TAIMavMissionState;
      const AMissionMessage: string; const AMission: TAIMavMission;
      AStartState: TAIMavStartState; ARouteActive: Boolean);
    function TakeRequests(out AKinds: TAIMavRequests; out AMission: TAIMavMission): Boolean;
    function ReadSticks(out ARoll, APitch, AYaw, AThrottle: Double): Boolean;
    procedure SetSocketOk(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Abre a porta UDP e começa a ouvir o drone (assíncrono). }
    procedure Connect;
    procedure Disconnect;

    { Controle manual: rolagem/arfagem/guinada -1..1 (+ = direita/frente/
      direita), aceleração 0..1. Ignorado durante a rota e nos modos autônomos. }
    procedure SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
    { Para de enviar controle manual (até o próximo SetSticks). }
    procedure ReleaseSticks;

    { Rota }
    procedure UploadMission(const AItems: TAIMavMission);
    procedure StartMission;
    { Pairar no lugar (LOITER / HOLD). }
    procedure PauseMission;
    { Retoma a missão do item atual (AUTO / MISSION). }
    procedure ResumeMission;
    procedure ReturnToLaunch;
    { Pousa no local atual. }
    procedure Land;

    { Texto do modo de voo e do GPS (para exibir). }
    function ModeText: string;
    function GpsText: string;
    function IsMissionMode: Boolean;
    function IsAutonomousMode: Boolean;
    function IsMultirotor: Boolean;

    { Monta a missão: [ArduPilot: item 0 = partida], decolagem, mudanças de
      velocidade e pontos, e a ação final. Altitudes relativas à partida. }
    class function BuildMission(const AWaypoints: array of TAIMavWaypoint;
      ATakeoffAlt: Double; AFinalAction: TAIMavFinalAction; AHomeLat, AHomeLon: Double;
      AArduPilot: Boolean): TAIMavMission; static;
    { Item da missão que corresponde ao ponto AIndex (-1 se não houver). }
    class function ItemOfWaypoint(const AMission: TAIMavMission; AIndex: Integer): Integer; static;
    class function DescribeItem(const AItem: TAIMavMissionItem): string; static;
    class function MissionResultText(AType: Integer): string; static;
    class function CommandResultText(AResult: Integer): string; static;
    class function ModeTextOf(const ATel: TAIMavTelemetry): string; static;
    class function IsMissionModeOf(const ATel: TAIMavTelemetry): Boolean; static;
    class function IsAutonomousModeOf(const ATel: TAIMavTelemetry): Boolean; static;

    property Active: Boolean read GetActive write SetActive;
    { False se a porta UDP não pôde ser aberta (outro programa usando-a). }
    property SocketOk: Boolean read FSocketOk;
    property Telemetry: TAIMavTelemetry read GetTelemetry;
    property MissionState: TAIMavMissionState read GetMissionState;
    property MissionMessage: string read GetMissionMessage;
    { Cópia da última missão enviada. }
    property Mission: TAIMavMission read GetMission;
    property StartState: TAIMavStartState read GetStartState;
    { True da partida da rota até o drone pousar e desarmar. }
    property RouteActive: Boolean read GetRouteActive;
  published
    { Drone ou ponte Wi-Fi (até o drone se identificar). }
    property Host: string read FHost write FHost;
    { Porta UDP em que o componente escuta (a mesma do Mission Planner). }
    property Port: Integer read FPort write FPort default MAV_DEFAULT_PORT;
    { Sem SetSticks por este tempo, o controle manual deixa de ser enviado. }
    property StickTimeoutMs: Integer read FStickTimeoutMs write FStickTimeoutMs default 500;
    { Envia MANUAL_CONTROL com os valores de SetSticks. }
    property ManualControl: Boolean read FManualControl write FManualControl default True;
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
  GCS_SYSID = 255;
  GCS_COMPID = 190;

  ARDU_GUIDED = 4;
  ARDU_AUTO = 3;
  ARDU_LOITER = 5;
  ARDU_RTL = 6;
  ARDU_LAND = 9;
  ARDU_BRAKE = 17;
  ARDU_SMART_RTL = 21;

  PX4_AUTO = 4;
  PX4_AUTO_LOITER = 3;
  PX4_AUTO_MISSION = 4;

  MAV_TYPE_GCS = 6;
  MAV_AUTOPILOT_INVALID = 8;

  PRAZO_ITEM_MS = 2000;
  PRAZO_CMD_MS = 1200;
  RAIO_ACEITACAO = 2.0;

  RQ_UPLOAD = 1;
  RQ_START = 2;
  RQ_PAUSE = 3;
  RQ_RESUME = 4;
  RQ_RTL = 5;
  RQ_LAND = 6;
  RQ_RELEASE = 7;

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneMavlink]);
end;

{ Auxiliares }

procedure CrcAcc(var Crc: Word; B: Byte); inline;
var
  T: Byte;
begin
  T := B xor Byte(Crc and $FF);
  T := T xor Byte(T shl 4);
  Crc := (Crc shr 8) xor (Word(T) shl 8) xor (Word(T) shl 3) xor (Word(T) shr 4);
end;

function CrcExtra(AMsgId: LongWord): Integer;
begin
  case AMsgId of
    0: Result := 50;     // HEARTBEAT
    1: Result := 124;    // SYS_STATUS
    24: Result := 24;    // GPS_RAW_INT
    33: Result := 104;   // GLOBAL_POSITION_INT
    40: Result := 230;   // MISSION_REQUEST
    42: Result := 28;    // MISSION_CURRENT
    46: Result := 11;    // MISSION_ITEM_REACHED
    47: Result := 153;   // MISSION_ACK
    51: Result := 196;   // MISSION_REQUEST_INT
    77: Result := 143;   // COMMAND_ACK
    242: Result := 104;  // HOME_POSITION
    253: Result := 83;   // STATUSTEXT
  else
    Result := -1;
  end;
end;

function LeU16(const P: array of Byte; O: Integer): Word;
begin
  Result := Word(P[O]) or (Word(P[O + 1]) shl 8);
end;

function LeI16(const P: array of Byte; O: Integer): SmallInt;
begin
  Result := SmallInt(LeU16(P, O));
end;

function LeU32(const P: array of Byte; O: Integer): Cardinal;
begin
  Result := Cardinal(P[O]) or (Cardinal(P[O + 1]) shl 8) or
    (Cardinal(P[O + 2]) shl 16) or (Cardinal(P[O + 3]) shl 24);
end;

function LeI32(const P: array of Byte; O: Integer): LongInt;
begin
  Result := LongInt(LeU32(P, O));
end;

procedure PoeU16(var P: array of Byte; O: Integer; V: Word);
begin
  P[O] := Lo(V);
  P[O + 1] := Hi(V);
end;

procedure PoeU32(var P: array of Byte; O: Integer; V: Cardinal);
begin
  P[O] := V and $FF;
  P[O + 1] := (V shr 8) and $FF;
  P[O + 2] := (V shr 16) and $FF;
  P[O + 3] := (V shr 24) and $FF;
end;

procedure PoeF32(var P: array of Byte; O: Integer; V: Single);
var
  C: Cardinal;
begin
  Move(V, C, 4);
  PoeU32(P, O, C);
end;

function NomeComando(ACmd: Word): string;
begin
  case ACmd of
    MAV_CMD_NAV_RETURN_TO_LAUNCH: Result := 'Voltar ao ponto de partida';
    MAV_CMD_NAV_LAND: Result := 'Pousar';
    MAV_CMD_DO_SET_MODE: Result := 'Mudar modo';
    MAV_CMD_MISSION_START: Result := 'Iniciar missão';
    MAV_CMD_COMPONENT_ARM_DISARM: Result := 'Armar';
  else
    Result := 'Comando ' + IntToStr(ACmd);
  end;
end;

function TelemetriaVazia: TAIMavTelemetry;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.BatteryPct := -1;
  Result.Hdop := -1;
  Result.CurrentItem := -1;
  Result.ReachedItem := -1;
end;

type

  { TMavWorker: toda a comunicação MAVLink }

  TMavWorker = class(TAIDroneWorker)
  private
    FOwner: TAIDroneMavlink;
    FUdp: TAISocketUDP;
    FHost: string;
    FPort: Integer;
    FPeerIP: string;
    FPeerPort: Integer;
    FSeq: Byte;
    FTel: TAIMavTelemetry;
    FUltimoHeartbeatRx, FUltimoHeartbeatTx, FUltimaPosicao: QWord;
    FUltimoPedidoStreams, FUltimoPedidoHome, FUltimoManual, FUltimaPublicacao: QWord;
    FSujo: Boolean;

    FMissao: TAIMavMission;
    FEnvio: TAIMavMissionState;
    FEnvioMsg: string;
    FEnvioTentativas, FEnvioPedidos: Integer;
    FEnvioPrazo: QWord;

    FCmd: Word;
    FCmdP: array[0..6] of Single;
    FCmdTentativas: Integer;
    FCmdPrazo: QWord;
    FCmdAguardando: Boolean;

    FPartida: TAIMavStartState;
    FPartidaPrazo: QWord;
    FRotaAtiva: Boolean;
    FFoiArmado: Boolean;

    procedure Avisa(const AMsg: string);
    procedure Envia(AMsgId, ACrcExtra: Byte; const APayload: array of Byte; ALen: Integer);
    procedure Processa(const B: array of Byte; ALen: Integer; const AIP: string; APort: Integer);
    procedure TrataMensagem(AMsgId: LongWord; ASys, AComp: Byte; const P: array of Byte;
      const AIP: string; APort: Integer);
    procedure EnviaHeartbeat;
    procedure PedeStreams;
    procedure PedeHome;
    procedure EnviaComandoLong(ACmd: Word; const AP: array of Single; AConfirmacao: Byte);
    procedure Comando(ACmd: Word; P1: Single = 0; P2: Single = 0; P3: Single = 0;
      P4: Single = 0; P5: Single = 0; P6: Single = 0; P7: Single = 0);
    procedure DefineModo(AModoArdu: Cardinal; APx4Principal, APx4Sub: Byte);
    procedure EnviaContagemMissao;
    procedure EnviaItemMissao(ASeq: Word);
    procedure EnviaManual;
    procedure FalhaPartida(const AMotivo: string);
    procedure IniciaEnvio(const AItens: TAIMavMission);
    procedure IniciaMissao;
    procedure TrataPedidos;
    procedure Tick;
    procedure Publica(AForcar: Boolean);
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneMavlink);
  end;

{ TMavWorker }

constructor TMavWorker.Create(AOwner: TAIDroneMavlink);
begin
  FOwner := AOwner;
  FHost := Trim(AOwner.Host);
  FPort := AOwner.Port;
  if FPort <= 0 then
    FPort := MAV_DEFAULT_PORT;
  FTel := TelemetriaVazia;
  inherited Create;
end;

procedure TMavWorker.Avisa(const AMsg: string);
begin
  FOwner.PostStatus(AMsg);
end;

procedure TMavWorker.Envia(AMsgId, ACrcExtra: Byte; const APayload: array of Byte; ALen: Integer);
var
  Pkt: array[0..263] of Byte;
  I: Integer;
  Crc: Word;
begin
  Pkt[0] := $FE;
  Pkt[1] := ALen;
  Pkt[2] := FSeq;
  Pkt[3] := GCS_SYSID;
  Pkt[4] := GCS_COMPID;
  Pkt[5] := AMsgId;
  if ALen > 0 then
    Move(APayload[0], Pkt[6], ALen);
  Crc := $FFFF;
  for I := 1 to 5 + ALen do
    CrcAcc(Crc, Pkt[I]);
  CrcAcc(Crc, ACrcExtra);
  Pkt[6 + ALen] := Lo(Crc);
  Pkt[7 + ALen] := Hi(Crc);
  Inc(FSeq);
  if FPeerIP <> '' then
    FUdp.SendBufferTo(Pkt[0], ALen + 8, FPeerIP, FPeerPort)
  else if FHost <> '' then
    FUdp.SendBufferTo(Pkt[0], ALen + 8, FHost, FPort);
end;

procedure TMavWorker.EnviaHeartbeat;
var
  P: array[0..8] of Byte;
begin
  FillChar(P, SizeOf(P), 0);
  P[4] := MAV_TYPE_GCS;
  P[5] := MAV_AUTOPILOT_INVALID;
  P[7] := 4;   // ATIVO
  P[8] := 3;   // versão do MAVLink
  Envia(0, 50, P, 9);
end;

procedure TMavWorker.PedeStreams;
var
  P: array[0..5] of Byte;
begin
  PoeU16(P, 0, 4);       // 4 Hz
  P[2] := FTel.SysId;
  P[3] := FTel.CompId;
  P[4] := 0;             // todos os grupos
  P[5] := 1;             // iniciar
  Envia(66, 148, P, 6);
  FUltimoPedidoStreams := GetTickCount64;
end;

procedure TMavWorker.PedeHome;
begin
  EnviaComandoLong(MAV_CMD_REQUEST_MESSAGE, [242, 0, 0, 0, 0, 0, 0], 0);
  EnviaComandoLong(MAV_CMD_GET_HOME_POSITION, [0, 0, 0, 0, 0, 0, 0], 0);
  FUltimoPedidoHome := GetTickCount64;
end;

procedure TMavWorker.EnviaComandoLong(ACmd: Word; const AP: array of Single; AConfirmacao: Byte);
var
  P: array[0..32] of Byte;
  I: Integer;
begin
  FillChar(P, SizeOf(P), 0);
  for I := 0 to 6 do
    if I <= High(AP) then
      PoeF32(P, I * 4, AP[I]);
  PoeU16(P, 28, ACmd);
  P[30] := FTel.SysId;
  P[31] := FTel.CompId;
  P[32] := AConfirmacao;
  Envia(76, 152, P, 33);
end;

procedure TMavWorker.Comando(ACmd: Word; P1, P2, P3, P4, P5, P6, P7: Single);
begin
  FCmd := ACmd;
  FCmdP[0] := P1; FCmdP[1] := P2; FCmdP[2] := P3; FCmdP[3] := P4;
  FCmdP[4] := P5; FCmdP[5] := P6; FCmdP[6] := P7;
  FCmdTentativas := 1;
  FCmdAguardando := True;
  FCmdPrazo := GetTickCount64 + PRAZO_CMD_MS;
  EnviaComandoLong(ACmd, FCmdP, 0);
end;

procedure TMavWorker.DefineModo(AModoArdu: Cardinal; APx4Principal, APx4Sub: Byte);
begin
  if FTel.Autopilot = MAV_AUTOPILOT_PX4 then
    Comando(MAV_CMD_DO_SET_MODE, 1, APx4Principal, APx4Sub)
  else
    Comando(MAV_CMD_DO_SET_MODE, 1, AModoArdu);
end;

procedure TMavWorker.EnviaContagemMissao;
var
  P: array[0..3] of Byte;
begin
  PoeU16(P, 0, Length(FMissao));
  P[2] := FTel.SysId;
  P[3] := FTel.CompId;
  Envia(44, 221, P, 4);
end;

procedure TMavWorker.EnviaItemMissao(ASeq: Word);
var
  P: array[0..36] of Byte;
  It: TAIMavMissionItem;
begin
  It := FMissao[ASeq];
  FillChar(P, SizeOf(P), 0);
  PoeF32(P, 0, It.P1);
  PoeF32(P, 4, It.P2);
  PoeF32(P, 8, It.P3);
  PoeF32(P, 12, It.P4);
  PoeU32(P, 16, Cardinal(It.X));
  PoeU32(P, 20, Cardinal(It.Y));
  PoeF32(P, 24, It.Z);
  PoeU16(P, 28, ASeq);
  PoeU16(P, 30, It.Command);
  P[32] := FTel.SysId;
  P[33] := FTel.CompId;
  P[34] := It.Frame;
  P[35] := 0;   // current
  P[36] := 1;   // autocontinue
  Envia(73, 38, P, 37);
end;

procedure TMavWorker.EnviaManual;
var
  P: array[0..10] of Byte;
  R, PF, Y, T: Double;
  Pitch, Roll, Thr, Yaw: SmallInt;
begin
  if not FTel.Connected or not FOwner.ManualControl then
    Exit;
  // Rota ou modo autônomo: as entradas manuais não podem interferir.
  if FRotaAtiva or (FPartida <> ssNone) or TAIDroneMavlink.IsAutonomousModeOf(FTel) then
    Exit;
  if not FOwner.ReadSticks(R, PF, Y, T) then
    Exit;   // aplicação parou de atualizar: não envia

  // MANUAL_CONTROL: x = arfagem (+ frente), y = rolagem (+ direita),
  // z = aceleração 0..1000, r = guinada (+ direita).
  Pitch := EnsureRange(Round(PF * 1000), -1000, 1000);
  Roll := EnsureRange(Round(R * 1000), -1000, 1000);
  Thr := EnsureRange(Round(T * 1000), 0, 1000);
  Yaw := EnsureRange(Round(Y * 1000), -1000, 1000);
  PoeU16(P, 0, Word(Pitch));
  PoeU16(P, 2, Word(Roll));
  PoeU16(P, 4, Word(Thr));
  PoeU16(P, 6, Word(Yaw));
  PoeU16(P, 8, 0);
  P[10] := FTel.SysId;
  Envia(69, 243, P, 11);
end;

procedure TMavWorker.FalhaPartida(const AMotivo: string);
begin
  FPartida := ssNone;
  FRotaAtiva := False;
  FSujo := True;
  Avisa('Rota NÃO iniciada: ' + AMotivo + '.');
end;

procedure TMavWorker.IniciaEnvio(const AItens: TAIMavMission);
begin
  FSujo := True;
  if not FTel.Connected then
  begin
    FEnvio := msFailed;
    FEnvioMsg := 'Sem conexão com o drone.';
    Avisa(FEnvioMsg);
    Exit;
  end;
  if FRotaAtiva or FTel.Armed then
  begin
    FEnvio := msFailed;
    FEnvioMsg := 'Não é possível trocar a rota com o drone armado.';
    Avisa(FEnvioMsg);
    Exit;
  end;
  if Length(AItens) = 0 then
  begin
    FEnvio := msFailed;
    FEnvioMsg := 'Missão vazia.';
    Avisa(FEnvioMsg);
    Exit;
  end;
  FMissao := Copy(AItens);
  FEnvio := msUploading;
  FEnvioTentativas := 1;
  FEnvioPedidos := 0;
  FEnvioMsg := 'Enviando rota...';
  FEnvioPrazo := GetTickCount64 + PRAZO_ITEM_MS;
  Avisa(Format('Enviando rota ao drone (%d itens)...', [Length(FMissao)]));
  EnviaContagemMissao;
end;

procedure TMavWorker.IniciaMissao;
begin
  FSujo := True;
  if FEnvio <> msAccepted then
  begin
    Avisa('Envie a rota ao drone antes de iniciar.');
    Exit;
  end;
  FRotaAtiva := True;
  FTel.ReachedItem := -1;
  if FTel.Armed then
  begin
    FPartida := ssStarting;
    FPartidaPrazo := GetTickCount64 + 6000;
    Comando(MAV_CMD_MISSION_START, 0, 0);
  end
  else if FTel.Autopilot = MAV_AUTOPILOT_PX4 then
  begin
    FPartida := ssArming;
    FPartidaPrazo := GetTickCount64 + 6000;
    Avisa('Armando o drone...');
    Comando(MAV_CMD_COMPONENT_ARM_DISARM, 1);
  end
  else
  begin
    // ArduCopter não arma em AUTO: arma em GUIDED e depois inicia a missão.
    FPartida := ssGuidedMode;
    FPartidaPrazo := GetTickCount64 + 4000;
    Avisa('Preparando partida (modo GUIDED)...');
    DefineModo(ARDU_GUIDED, 0, 0);
  end;
end;

procedure TMavWorker.TrataPedidos;
var
  Tipos: TAIMavRequests;
  M: TAIMavMission;
  I: Integer;
begin
  if not FOwner.TakeRequests(Tipos, M) then
    Exit;
  for I := 0 to High(Tipos) do
    case Tipos[I] of
      RQ_UPLOAD: IniciaEnvio(M);
      RQ_START: IniciaMissao;
      RQ_PAUSE:
        begin
          Avisa('Pausando: o drone vai pairar no lugar.');
          DefineModo(ARDU_LOITER, PX4_AUTO, PX4_AUTO_LOITER);
        end;
      RQ_RESUME:
        begin
          FRotaAtiva := True;
          FSujo := True;
          Avisa('Retomando a rota.');
          DefineModo(ARDU_AUTO, PX4_AUTO, PX4_AUTO_MISSION);
        end;
      RQ_RTL:
        begin
          FPartida := ssNone;
          Avisa('Voltando ao ponto de partida (RTL).');
          Comando(MAV_CMD_NAV_RETURN_TO_LAUNCH);
        end;
      RQ_LAND:
        begin
          FPartida := ssNone;
          Avisa('Pousando no local atual.');
          Comando(MAV_CMD_NAV_LAND, 0, 0, 0, NaN, NaN, NaN, 0);
        end;
    end;
end;

procedure TMavWorker.Processa(const B: array of Byte; ALen: Integer; const AIP: string;
  APort: Integer);
var
  I, N, Tam, Assin, E: Integer;
  Crc: Word;
  MsgId: LongWord;
  P: array[0..255] of Byte;
begin
  I := 0;
  while I < ALen do
  begin
    if (B[I] = $FE) and (I + 8 <= ALen) then
    begin
      Tam := B[I + 1];
      if I + 8 + Tam > ALen then
        Exit;
      MsgId := B[I + 5];
      E := CrcExtra(MsgId);
      if E < 0 then
      begin
        Inc(I, 8 + Tam);
        Continue;
      end;
      Crc := $FFFF;
      for N := 1 to 5 + Tam do
        CrcAcc(Crc, B[I + N]);
      CrcAcc(Crc, E);
      if Crc <> (Word(B[I + 6 + Tam]) or (Word(B[I + 7 + Tam]) shl 8)) then
      begin
        Inc(I);
        Continue;
      end;
      FillChar(P, SizeOf(P), 0);
      if Tam > 0 then
        Move(B[I + 6], P[0], Tam);
      TrataMensagem(MsgId, B[I + 3], B[I + 4], P, AIP, APort);
      Inc(I, 8 + Tam);
    end
    else if (B[I] = $FD) and (I + 12 <= ALen) then
    begin
      Tam := B[I + 1];
      Assin := 0;
      if (B[I + 2] and 1) <> 0 then
        Assin := 13;
      if I + 12 + Tam + Assin > ALen then
        Exit;
      MsgId := LongWord(B[I + 7]) or (LongWord(B[I + 8]) shl 8) or (LongWord(B[I + 9]) shl 16);
      E := CrcExtra(MsgId);
      if E < 0 then
      begin
        Inc(I, 12 + Tam + Assin);
        Continue;
      end;
      Crc := $FFFF;
      for N := 1 to 9 + Tam do
        CrcAcc(Crc, B[I + N]);
      CrcAcc(Crc, E);
      if Crc <> (Word(B[I + 10 + Tam]) or (Word(B[I + 11 + Tam]) shl 8)) then
      begin
        Inc(I);
        Continue;
      end;
      // MAVLink 2 omite os zeros finais da carga: P começa zerado.
      FillChar(P, SizeOf(P), 0);
      if Tam > 0 then
        Move(B[I + 10], P[0], Tam);
      TrataMensagem(MsgId, B[I + 5], B[I + 6], P, AIP, APort);
      Inc(I, 12 + Tam + Assin);
    end
    else
      Inc(I);
  end;
end;

procedure TMavWorker.TrataMensagem(AMsgId: LongWord; ASys, AComp: Byte;
  const P: array of Byte; const AIP: string; APort: Integer);
var
  Tipo, Auto, Base: Byte;
  Custom, ModoAnterior: Cardinal;
  EraArmado, EraMissao: Boolean;
  V, Res, I: Integer;
  Cmd, Seq: Word;
  Txt: string;
  VX, VY: Double;
begin
  if AMsgId = 0 then
  begin
    // HEARTBEAT: só o primeiro piloto automático visto.
    Tipo := P[4];
    Auto := P[5];
    if (Tipo = MAV_TYPE_GCS) or (Auto = MAV_AUTOPILOT_INVALID) then
      Exit;
    if (FTel.SysId <> 0) and ((ASys <> FTel.SysId) or (AComp <> FTel.CompId)) then
      Exit;

    FPeerIP := AIP;
    FPeerPort := APort;
    FUltimoHeartbeatRx := GetTickCount64;
    Custom := LeU32(P, 0);
    Base := P[6];
    EraArmado := FTel.Armed;
    EraMissao := TAIDroneMavlink.IsMissionModeOf(FTel);
    ModoAnterior := FTel.CustomMode;
    FSujo := True;

    if not FTel.Connected then
    begin
      FTel.SysId := ASys;
      FTel.CompId := AComp;
      FTel.VehicleType := Tipo;
      FTel.Autopilot := Auto;
      FTel.CustomMode := Custom;
      FTel.BaseMode := Base;
      FTel.Armed := (Base and 128) <> 0;
      FTel.Connected := True;
      if Auto = MAV_AUTOPILOT_ARDUPILOT then
        Txt := 'ArduPilot'
      else if Auto = MAV_AUTOPILOT_PX4 then
        Txt := 'PX4'
      else
        Txt := 'piloto automático ' + IntToStr(Auto);
      Avisa(Format('Drone encontrado: %s, sistema %d (%s:%d). Modo %s.',
        [Txt, ASys, AIP, APort, TAIDroneMavlink.ModeTextOf(FTel)]));
      if not (Tipo in [2, 3, 4, 13, 14, 15, 29]) then
        Avisa('Atenção: este veículo não é um multirrotor; a rota é feita para multirrotores.');
      FOwner.PostStateChange;
      PedeStreams;
      PedeHome;
      Exit;
    end;

    FTel.VehicleType := Tipo;
    FTel.Autopilot := Auto;
    FTel.CustomMode := Custom;
    FTel.BaseMode := Base;
    FTel.Armed := (Base and 128) <> 0;

    if FTel.Armed and not EraArmado then
    begin
      FFoiArmado := True;
      Avisa('Drone ARMADO.');
    end
    else if EraArmado and not FTel.Armed then
    begin
      Avisa('Drone desarmado.');
      if FRotaAtiva and FFoiArmado then
      begin
        FRotaAtiva := False;
        Avisa('Rota encerrada (drone pousado e desarmado).');
      end;
      FFoiArmado := False;
    end;
    if Custom <> ModoAnterior then
      Avisa('Modo: ' + TAIDroneMavlink.ModeTextOf(FTel));
    if TAIDroneMavlink.IsMissionModeOf(FTel) and not EraMissao and (FPartida = ssStarting) then
    begin
      FPartida := ssNone;
      Avisa('Rota em execução.');
    end;
    Exit;
  end;

  if (FTel.SysId = 0) or (ASys <> FTel.SysId) then
    Exit;
  FSujo := True;

  case AMsgId of
    1: // SYS_STATUS
      begin
        V := LeU16(P, 14);
        if V <> 65535 then
          FTel.BatteryVoltage := V / 1000;
        FTel.BatteryPct := ShortInt(P[30]);
      end;
    24: // GPS_RAW_INT
      begin
        FTel.GpsFix := P[28];
        FTel.Satellites := P[29];
        V := LeU16(P, 20);
        if V <> 65535 then
          FTel.Hdop := V / 100
        else
          FTel.Hdop := -1;
      end;
    33: // GLOBAL_POSITION_INT
      begin
        FTel.Lat := LeI32(P, 4) / 1e7;
        FTel.Lon := LeI32(P, 8) / 1e7;
        FTel.RelativeAlt := LeI32(P, 16) / 1000;
        VX := LeI16(P, 20) / 100;
        VY := LeI16(P, 22) / 100;
        FTel.GroundSpeed := Sqrt(Sqr(VX) + Sqr(VY));
        V := LeU16(P, 26);
        if V <> 65535 then
          FTel.Heading := V / 100;
        FTel.PositionValid := (FTel.Lat <> 0) or (FTel.Lon <> 0);
        FUltimaPosicao := GetTickCount64;
      end;
    242: // HOME_POSITION
      begin
        FTel.HomeLat := LeI32(P, 0) / 1e7;
        FTel.HomeLon := LeI32(P, 4) / 1e7;
        if (FTel.HomeLat <> 0) or (FTel.HomeLon <> 0) then
        begin
          if not FTel.HomeValid then
            Avisa(Format('Ponto de partida do drone: %.6f, %.6f', [FTel.HomeLat, FTel.HomeLon]));
          FTel.HomeValid := True;
        end;
      end;
    42: // MISSION_CURRENT
      FTel.CurrentItem := LeU16(P, 0);
    46: // MISSION_ITEM_REACHED
      FTel.ReachedItem := LeU16(P, 0);
    40, 51: // MISSION_REQUEST / MISSION_REQUEST_INT
      if (FEnvio = msUploading) and (P[2] = GCS_SYSID) then
      begin
        Seq := LeU16(P, 0);
        if Seq < Length(FMissao) then
        begin
          EnviaItemMissao(Seq);
          Inc(FEnvioPedidos);
          FEnvioPrazo := GetTickCount64 + PRAZO_ITEM_MS;
        end;
      end;
    47: // MISSION_ACK
      if (FEnvio = msUploading) and (P[0] = GCS_SYSID) and (P[3] = 0) then
      begin
        Res := P[2];
        if Res = 0 then
        begin
          FEnvio := msAccepted;
          FEnvioMsg := Format('Rota aceita pelo drone (%d itens).', [Length(FMissao)]);
        end
        else
        begin
          FEnvio := msFailed;
          FEnvioMsg := 'O drone recusou a rota: ' + TAIDroneMavlink.MissionResultText(Res) + '.';
        end;
        Avisa(FEnvioMsg);
      end;
    77: // COMMAND_ACK
      begin
        Cmd := LeU16(P, 0);
        Res := P[2];
        if FCmdAguardando and (Cmd = FCmd) and (Res <> 5) then
        begin
          FCmdAguardando := False;
          if Res <> 0 then
            Avisa(NomeComando(Cmd) + ': ' + TAIDroneMavlink.CommandResultText(Res) + '.');
        end;
        case FPartida of
          ssGuidedMode:
            if (Cmd = MAV_CMD_DO_SET_MODE) and (Res <> 0) and (Res <> 5) then
              FalhaPartida('o drone não aceitou o modo GUIDED');
          ssArming:
            if (Cmd = MAV_CMD_COMPONENT_ARM_DISARM) and (Res <> 0) and (Res <> 5) then
              FalhaPartida('o drone não armou (veja as mensagens "PreArm")');
          ssStarting:
            if Cmd = MAV_CMD_MISSION_START then
            begin
              if Res = 0 then
              begin
                FPartida := ssNone;
                Avisa('Rota iniciada pelo drone.');
              end
              else if Res <> 5 then
                FalhaPartida('o drone recusou o início da missão');
            end;
        end;
      end;
    253: // STATUSTEXT
      begin
        Txt := '';
        for I := 1 to 50 do
        begin
          if P[I] = 0 then
            Break;
          Txt := Txt + Chr(P[I]);
        end;
        if Txt <> '' then
          Avisa('Drone: ' + Txt);
      end;
  end;
end;

procedure TMavWorker.Tick;
var
  Agora: QWord;
begin
  Agora := GetTickCount64;

  if Agora - FUltimoHeartbeatTx >= 1000 then
  begin
    EnviaHeartbeat;
    FUltimoHeartbeatTx := Agora;
  end;

  if FTel.Connected and (Agora - FUltimoHeartbeatRx > 3000) then
  begin
    FTel.Connected := False;
    FSujo := True;
    Avisa('Sem sinal do drone há 3 s.');
    FOwner.PostStateChange;
  end;

  if FTel.Connected then
  begin
    if (Agora - FUltimaPosicao > 3000) and (Agora - FUltimoPedidoStreams > 5000) then
      PedeStreams;
    if (not FTel.HomeValid) and FTel.PositionValid and (Agora - FUltimoPedidoHome > 5000) then
      PedeHome;
  end;

  if Agora - FUltimoManual >= 100 then
  begin
    FUltimoManual := Agora;
    EnviaManual;
  end;

  // Envio da missão: o drone pede item a item; sem pedido no prazo, recomeça.
  if (FEnvio = msUploading) and (Agora > FEnvioPrazo) then
  begin
    FSujo := True;
    if FEnvioTentativas >= 5 then
    begin
      FEnvio := msFailed;
      FEnvioMsg := 'O drone não respondeu ao envio da rota.';
      Avisa(FEnvioMsg);
    end
    else
    begin
      Inc(FEnvioTentativas);
      FEnvioPrazo := Agora + PRAZO_ITEM_MS;
      if FEnvioPedidos = 0 then
        EnviaContagemMissao;
    end;
  end;

  // Comando sem confirmação: reenvia até 3 vezes.
  if FCmdAguardando and (Agora > FCmdPrazo) then
  begin
    if FCmdTentativas >= 3 then
    begin
      FCmdAguardando := False;
      Avisa(NomeComando(FCmd) + ': sem resposta do drone.');
    end
    else
    begin
      EnviaComandoLong(FCmd, FCmdP, FCmdTentativas);
      Inc(FCmdTentativas);
      FCmdPrazo := Agora + PRAZO_CMD_MS;
    end;
  end;

  case FPartida of
    ssGuidedMode:
      if FTel.CustomMode = ARDU_GUIDED then
      begin
        FPartida := ssArming;
        FPartidaPrazo := Agora + 6000;
        FSujo := True;
        Avisa('Armando o drone...');
        Comando(MAV_CMD_COMPONENT_ARM_DISARM, 1);
      end
      else if Agora > FPartidaPrazo then
        FalhaPartida('o drone não entrou no modo GUIDED');
    ssArming:
      if FTel.Armed then
      begin
        FPartida := ssStarting;
        FPartidaPrazo := Agora + 6000;
        FSujo := True;
        Avisa('Iniciando a rota...');
        Comando(MAV_CMD_MISSION_START, 0, 0);
      end
      else if Agora > FPartidaPrazo then
        FalhaPartida('o drone não armou (veja as mensagens "PreArm")');
    ssStarting:
      if TAIDroneMavlink.IsMissionModeOf(FTel) then
      begin
        FPartida := ssNone;
        FSujo := True;
        Avisa('Rota em execução.');
      end
      else if Agora > FPartidaPrazo then
        FalhaPartida('o drone não entrou no modo de missão');
  end;
end;

procedure TMavWorker.Publica(AForcar: Boolean);
var
  Agora: QWord;
begin
  Agora := GetTickCount64;
  if not (AForcar or (FSujo and (Agora - FUltimaPublicacao >= 100))) then
    Exit;
  FUltimaPublicacao := Agora;
  FSujo := False;
  FOwner.PublishState(FTel, FEnvio, FEnvioMsg, FMissao, FPartida, FRotaAtiva);
  FOwner.PostTelemetry;
end;

procedure TMavWorker.Execute;
var
  Buf: array[0..4095] of Byte;
  N, Porta: Integer;
  IP: string;
begin
  FUdp := TAISocketUDP.Create(nil);
  try
    FUdp.Port := FPort;
    FUdp.LocalPort := FPort;    // escuta na porta configurada
    if not FUdp.OpenSocket then
    begin
      FOwner.SetSocketOk(False);
      FOwner.PostError(Format('Não foi possível abrir a porta UDP %d (outro programa, ' +
        'como o Mission Planner, pode estar usando-a).', [FPort]));
      FOwner.PostStateChange;
      Exit;
    end;
    FOwner.SetSocketOk(True);
    if FHost <> '' then
      Avisa(Format('MAVLink: escutando UDP %d (drone em %s)...', [FPort, FHost]))
    else
      Avisa(Format('MAVLink: escutando UDP %d...', [FPort]));
    EnviaHeartbeat;
    FUltimoHeartbeatTx := GetTickCount64;

    while not Terminated do
    begin
      N := FUdp.ReceiveBuffer(Buf, SizeOf(Buf), 20, IP, Porta);
      if N > 0 then
        Processa(Buf, N, IP, Porta);
      TrataPedidos;
      Tick;
      Publica(False);
    end;
  finally
    FTel.Connected := False;
    FRotaAtiva := False;
    FPartida := ssNone;
    if FEnvio = msUploading then
      FEnvio := msFailed;
    Publica(True);
    FUdp.Free;
  end;
end;

{ TAIDroneMavlink }

constructor TAIDroneMavlink.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  Prompt := 'Component TAIDroneMavlink talks MAVLink (UDP, default port 14550) to ArduPilot ' +
    'or PX4 multicopters: telemetry (Telemetry: GPS fix, satellites, position, battery, mode, ' +
    'home), manual control (SetSticks), missions (BuildMission, UploadMission, StartMission, ' +
    'PauseMission, ResumeMission, ReturnToLaunch, Land). MissionState shows the upload result; ' +
    'RouteActive is True from start until landing. Events on the main thread: OnStatus, OnError, ' +
    'OnStateChange, OnTelemetry.';
  FHost := '';
  FPort := MAV_DEFAULT_PORT;
  FStickTimeoutMs := 500;
  FManualControl := True;
  FLock := TCriticalSection.Create;
  FTel := TelemetriaVazia;
end;

destructor TAIDroneMavlink.Destroy;
begin
  Disconnect;
  CancelPendingEvents;
  FLock.Free;
  inherited Destroy;
end;

function TAIDroneMavlink.GetActive: Boolean;
begin
  Result := Assigned(FWorker);
end;

procedure TAIDroneMavlink.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

procedure TAIDroneMavlink.Connect;
begin
  if Assigned(FWorker) then
    Exit;
  ClearError;
  FLock.Enter;
  try
    FTel := TelemetriaVazia;
    FMissionState := msNone;
    FMissionMessage := '';
    FMission := nil;
    FStartState := ssNone;
    FRouteActive := False;
    FRequests := nil;
    FStickTick := 0;
  finally
    FLock.Leave;
  end;
  FSocketOk := True;
  FWorker := TMavWorker.Create(Self);
end;

procedure TAIDroneMavlink.Disconnect;
begin
  if not Assigned(FWorker) then
    Exit;
  FWorker.Terminate;
  FWorker.WaitFor;
  FreeAndNil(FWorker);
  PostStatus('MAVLink desconectado.');
  PostStateChange;
end;

procedure TAIDroneMavlink.PublishState(const ATel: TAIMavTelemetry;
  AMissionState: TAIMavMissionState; const AMissionMessage: string;
  const AMission: TAIMavMission; AStartState: TAIMavStartState; ARouteActive: Boolean);
var
  I: Integer;
  EnvioPendente: Boolean;
begin
  FLock.Enter;
  try
    FTel := ATel;
    // Envio pedido e ainda não tratado pela linha de rede: continua "enviando"
    // (nunca mostra como aceita a missão anterior).
    EnvioPendente := False;
    for I := 0 to High(FRequests) do
      if FRequests[I] = RQ_UPLOAD then
        EnvioPendente := True;
    if not EnvioPendente then
    begin
      FMissionState := AMissionState;
      FMissionMessage := AMissionMessage;
      FMission := Copy(AMission);
    end;
    FStartState := AStartState;
    FRouteActive := ARouteActive;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.AddRequest(AKind: Integer);
begin
  SetLength(FRequests, Length(FRequests) + 1);
  FRequests[High(FRequests)] := AKind;
end;

function TAIDroneMavlink.TakeRequests(out AKinds: TAIMavRequests; out AMission: TAIMavMission): Boolean;
begin
  FLock.Enter;
  try
    AKinds := Copy(FRequests);
    AMission := Copy(FRequestMission);
    FRequests := nil;
  finally
    FLock.Leave;
  end;
  Result := Length(AKinds) > 0;
end;

function TAIDroneMavlink.ReadSticks(out ARoll, APitch, AYaw, AThrottle: Double): Boolean;
begin
  FLock.Enter;
  try
    ARoll := FStickRoll;
    APitch := FStickPitch;
    AYaw := FStickYaw;
    AThrottle := FStickThrottle;
    Result := (FStickTick > 0) and ((FStickTimeoutMs <= 0) or
      (GetTickCount64 - FStickTick <= QWord(FStickTimeoutMs)));
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.SetSocketOk(AValue: Boolean);
begin
  FSocketOk := AValue;
end;

procedure TAIDroneMavlink.SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
begin
  FLock.Enter;
  try
    FStickRoll := ClampAxis(ARoll);
    FStickPitch := ClampAxis(APitch);
    FStickYaw := ClampAxis(AYaw);
    if IsNan(AThrottle) then
      AThrottle := 0;
    FStickThrottle := EnsureRange(AThrottle, 0.0, 1.0);
    FStickTick := GetTickCount64;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.ReleaseSticks;
begin
  FLock.Enter;
  try
    FStickTick := 0;
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.UploadMission(const AItems: TAIMavMission);
begin
  FLock.Enter;
  try
    FRequestMission := Copy(AItems);
    // Mostra "enviando" já na chamada (a linha de rede confirma em seguida).
    FMissionState := msUploading;
    FMissionMessage := 'Enviando rota...';
    AddRequest(RQ_UPLOAD);
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.StartMission;
begin
  FLock.Enter;
  try
    AddRequest(RQ_START);
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.PauseMission;
begin
  FLock.Enter;
  try
    AddRequest(RQ_PAUSE);
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.ResumeMission;
begin
  FLock.Enter;
  try
    AddRequest(RQ_RESUME);
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.ReturnToLaunch;
begin
  FLock.Enter;
  try
    AddRequest(RQ_RTL);
  finally
    FLock.Leave;
  end;
end;

procedure TAIDroneMavlink.Land;
begin
  FLock.Enter;
  try
    AddRequest(RQ_LAND);
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.GetTelemetry: TAIMavTelemetry;
begin
  FLock.Enter;
  try
    Result := FTel;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.GetMissionState: TAIMavMissionState;
begin
  FLock.Enter;
  try
    Result := FMissionState;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.GetMissionMessage: string;
begin
  FLock.Enter;
  try
    Result := FMissionMessage;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.GetMission: TAIMavMission;
begin
  FLock.Enter;
  try
    Result := Copy(FMission);
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.GetStartState: TAIMavStartState;
begin
  FLock.Enter;
  try
    Result := FStartState;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.GetRouteActive: Boolean;
begin
  FLock.Enter;
  try
    Result := FRouteActive;
  finally
    FLock.Leave;
  end;
end;

function TAIDroneMavlink.ModeText: string;
begin
  Result := ModeTextOf(Telemetry);
end;

function TAIDroneMavlink.GpsText: string;
var
  T: TAIMavTelemetry;
begin
  T := Telemetry;
  if not T.Connected then
    Exit('-');
  case T.GpsFix of
    0, 1: Result := 'sem fix';
    2: Result := 'fix 2D';
    3: Result := 'fix 3D';
    4: Result := 'DGPS';
    5: Result := 'RTK flutuante';
    6: Result := 'RTK fixo';
  else
    Result := 'fix ' + IntToStr(T.GpsFix);
  end;
  Result := Result + Format(', %d satélites', [T.Satellites]);
  if T.Hdop >= 0 then
    Result := Result + Format(', HDOP %.1f', [T.Hdop]);
end;

function TAIDroneMavlink.IsMissionMode: Boolean;
begin
  Result := IsMissionModeOf(Telemetry);
end;

function TAIDroneMavlink.IsAutonomousMode: Boolean;
begin
  Result := IsAutonomousModeOf(Telemetry);
end;

function TAIDroneMavlink.IsMultirotor: Boolean;
begin
  Result := Telemetry.VehicleType in [2, 3, 4, 13, 14, 15, 29];
end;

class function TAIDroneMavlink.IsMissionModeOf(const ATel: TAIMavTelemetry): Boolean;
begin
  if ATel.Autopilot = MAV_AUTOPILOT_PX4 then
    Result := (((ATel.CustomMode shr 16) and $FF) = PX4_AUTO) and
      (((ATel.CustomMode shr 24) and $FF) = PX4_AUTO_MISSION)
  else
    Result := ATel.CustomMode = ARDU_AUTO;
end;

class function TAIDroneMavlink.IsAutonomousModeOf(const ATel: TAIMavTelemetry): Boolean;
begin
  if ATel.Autopilot = MAV_AUTOPILOT_PX4 then
    Result := ((ATel.CustomMode shr 16) and $FF) = PX4_AUTO
  else
    case ATel.CustomMode of
      ARDU_AUTO, ARDU_GUIDED, ARDU_RTL, ARDU_LAND, ARDU_BRAKE, ARDU_SMART_RTL:
        Result := True;
    else
      Result := False;
    end;
end;

class function TAIDroneMavlink.ModeTextOf(const ATel: TAIMavTelemetry): string;
var
  Principal, Sub: Byte;
begin
  if not ATel.Connected then
    Exit('-');
  if ATel.Autopilot = MAV_AUTOPILOT_PX4 then
  begin
    Principal := (ATel.CustomMode shr 16) and $FF;
    Sub := (ATel.CustomMode shr 24) and $FF;
    case Principal of
      1: Result := 'MANUAL';
      2: Result := 'ALTITUDE';
      3: Result := 'POSIÇÃO';
      4:
        case Sub of
          1: Result := 'AUTO PRONTO';
          2: Result := 'DECOLAGEM';
          3: Result := 'PAIRANDO (HOLD)';
          4: Result := 'MISSÃO';
          5: Result := 'RETORNO (RTL)';
          6: Result := 'POUSO';
        else
          Result := 'AUTO ' + IntToStr(Sub);
        end;
      5: Result := 'ACRO';
      6: Result := 'OFFBOARD';
      7: Result := 'ESTABILIZADO';
    else
      Result := 'PX4 ' + IntToStr(Principal);
    end;
  end
  else
    case ATel.CustomMode of
      0: Result := 'STABILIZE';
      1: Result := 'ACRO';
      2: Result := 'ALT_HOLD';
      ARDU_AUTO: Result := 'AUTO (MISSÃO)';
      ARDU_GUIDED: Result := 'GUIDED';
      ARDU_LOITER: Result := 'LOITER (PAIRANDO)';
      ARDU_RTL: Result := 'RTL (RETORNO)';
      7: Result := 'CIRCLE';
      ARDU_LAND: Result := 'LAND (POUSO)';
      16: Result := 'POSHOLD';
      ARDU_BRAKE: Result := 'BRAKE';
      ARDU_SMART_RTL: Result := 'SMART_RTL';
    else
      Result := 'MODO ' + IntToStr(ATel.CustomMode);
    end;
  if ATel.Armed then
    Result := Result + ' / ARMADO'
  else
    Result := Result + ' / desarmado';
end;

class function TAIDroneMavlink.MissionResultText(AType: Integer): string;
begin
  case AType of
    0: Result := 'aceita';
    1: Result := 'erro genérico';
    2: Result := 'sistema de coordenadas não suportado';
    3: Result := 'comando não suportado';
    4: Result := 'sem espaço para a missão';
    5: Result := 'missão inválida';
    6..12: Result := 'parâmetro inválido (' + IntToStr(AType - 5) + ')';
    13: Result := 'sequência inválida';
    14: Result := 'recusada pelo drone';
    15: Result := 'operação cancelada';
  else
    Result := 'código ' + IntToStr(AType);
  end;
end;

class function TAIDroneMavlink.CommandResultText(AResult: Integer): string;
begin
  case AResult of
    0: Result := 'aceito';
    1: Result := 'recusado temporariamente';
    2: Result := 'negado';
    3: Result := 'não suportado';
    4: Result := 'falhou';
    5: Result := 'em andamento';
    6: Result := 'cancelado';
  else
    Result := 'código ' + IntToStr(AResult);
  end;
end;

{ Missão }

function Item(ACmd: Word; AFrame: Byte; P1, P2, P3, P4: Single; ALat, ALon: Double;
  AAlt: Single; AWaypoint: Integer): TAIMavMissionItem;
begin
  Result.Command := ACmd;
  Result.Frame := AFrame;
  Result.P1 := P1;
  Result.P2 := P2;
  Result.P3 := P3;
  Result.P4 := P4;
  Result.X := Round(ALat * 1e7);
  Result.Y := Round(ALon * 1e7);
  Result.Z := AAlt;
  Result.Waypoint := AWaypoint;
end;

procedure Adiciona(var M: TAIMavMission; const AItem: TAIMavMissionItem);
begin
  SetLength(M, Length(M) + 1);
  M[High(M)] := AItem;
end;

class function TAIDroneMavlink.BuildMission(const AWaypoints: array of TAIMavWaypoint;
  ATakeoffAlt: Double; AFinalAction: TAIMavFinalAction; AHomeLat, AHomeLon: Double;
  AArduPilot: Boolean): TAIMavMission;
var
  I: Integer;
  Vel: Double;
  U: TAIMavWaypoint;
begin
  Result := nil;
  if Length(AWaypoints) = 0 then
    Exit;

  if AArduPilot then
    // Item 0 do ArduPilot é o ponto de partida (o drone o substitui).
    Adiciona(Result, Item(MAV_CMD_NAV_WAYPOINT, MAV_FRAME_GLOBAL, 0, 0, 0, 0,
      AHomeLat, AHomeLon, 0, -1));

  // Decolagem vertical sobre o ponto de partida (guinada: mantém a atual).
  Adiciona(Result, Item(MAV_CMD_NAV_TAKEOFF, MAV_FRAME_GLOBAL_RELATIVE_ALT, 0, 0, 0, NaN,
    AHomeLat, AHomeLon, ATakeoffAlt, -1));

  Vel := -1;
  for I := 0 to High(AWaypoints) do
  begin
    if Abs(AWaypoints[I].Speed - Vel) > 0.01 then
    begin
      // velocidade em relação ao solo; -1 = não muda a aceleração
      Adiciona(Result, Item(MAV_CMD_DO_CHANGE_SPEED, MAV_FRAME_MISSION, 1,
        AWaypoints[I].Speed, -1, 0, 0, 0, 0, -1));
      Vel := AWaypoints[I].Speed;
    end;
    Adiciona(Result, Item(MAV_CMD_NAV_WAYPOINT, MAV_FRAME_GLOBAL_RELATIVE_ALT, 0,
      RAIO_ACEITACAO, 0, NaN, AWaypoints[I].Lat, AWaypoints[I].Lon, AWaypoints[I].Alt, I));
  end;

  U := AWaypoints[High(AWaypoints)];
  case AFinalAction of
    mfaReturnToLaunch:
      Adiciona(Result, Item(MAV_CMD_NAV_RETURN_TO_LAUNCH, MAV_FRAME_MISSION, 0, 0, 0, 0,
        0, 0, 0, -1));
    mfaLandAtLast:
      Adiciona(Result, Item(MAV_CMD_NAV_LAND, MAV_FRAME_GLOBAL_RELATIVE_ALT, 0, 0, 0, NaN,
        U.Lat, U.Lon, 0, -1));
    mfaHoverAtLast:
      Adiciona(Result, Item(MAV_CMD_NAV_LOITER_UNLIM, MAV_FRAME_GLOBAL_RELATIVE_ALT, 0, 0, 0, NaN,
        U.Lat, U.Lon, U.Alt, -1));
  end;
end;

class function TAIDroneMavlink.ItemOfWaypoint(const AMission: TAIMavMission;
  AIndex: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(AMission) do
    if AMission[I].Waypoint = AIndex then
      Exit(I);
  Result := -1;
end;

class function TAIDroneMavlink.DescribeItem(const AItem: TAIMavMissionItem): string;
begin
  case AItem.Command of
    MAV_CMD_NAV_WAYPOINT:
      if AItem.Waypoint >= 0 then
        Result := Format('Ponto %d (%.6f, %.6f) a %.1f m',
          [AItem.Waypoint + 1, AItem.X / 1e7, AItem.Y / 1e7, AItem.Z])
      else
        Result := Format('Partida (%.6f, %.6f)', [AItem.X / 1e7, AItem.Y / 1e7]);
    MAV_CMD_NAV_TAKEOFF: Result := Format('Decolar até %.1f m', [AItem.Z]);
    MAV_CMD_DO_CHANGE_SPEED: Result := Format('Velocidade %.1f m/s', [AItem.P2]);
    MAV_CMD_NAV_RETURN_TO_LAUNCH: Result := 'Voltar ao ponto de partida e pousar';
    MAV_CMD_NAV_LAND: Result := 'Pousar no último ponto';
    MAV_CMD_NAV_LOITER_UNLIM: Result := 'Pairar no último ponto';
  else
    Result := 'Comando ' + IntToStr(AItem.Command);
  end;
end;

initialization
  {$I aidronemavlink_icon.lrs}

end.
