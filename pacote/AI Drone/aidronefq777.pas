unit aidronefq777;

{ TAIDroneFQ777
  -------------
  Protocolo Wi-Fi exclusivo do quadricóptero FQ777-954 (marca FQ777).
  Não serve para outros modelos: os pacotes de inicialização, as portas e o
  formato do comando são próprios deste drone.

  Rede do drone (ponto de acesso do próprio drone):
    IP 172.16.10.1, TCP 8888 (inicialização e vídeo), UDP 8895 (comando).

  Sequência de conexão (portada do aplicativo FQ777-954 para Chrome):
    1. TCP de controle -> pacote mágico CTRL (106 bytes)
    2. TCP de vídeo 1  -> pacotes mágicos VIDEO 1A e 1B
    3. TCP de vídeo 2  -> pacote mágico VIDEO 2; por esta conexão o drone
       passa a enviar o vídeo em H.264 bruto (720x576), entremeado com
       respostas de 106 bytes iniciadas por 'ITd' que são descartadas.
    4. UDP, a cada 50 ms, o pacote de comando de 8 bytes:
         [0] $CC  [1] rolagem  [2] arfagem  [3] aceleração  [4] guinada
         [5] sinalizadores  [6] XOR dos bytes 1..5  [7] $33
       Rolagem/arfagem/guinada: 0..255, centro 127 (0 = esquerda/trás).
       Aceleração: 0..255, 0 = motores parados.

  O vídeo chega pelo evento OnVideoData, na linha de rede (não acesse a
  interface dentro dele). Para ver a imagem, ligue-o a um TAIH264Decoder
  (pacote openai_video), cujo Feed é seguro entre linhas:
    procedure TForm1.DroneVideo(Sender: TObject; AData: PByte; ACount: Integer);
    begin
      Decoder.Feed(AData^, ACount);
    end;

  Controle e vídeo rodam em linhas separadas: uma queda ou reconexão do vídeo
  nunca interrompe o envio de comandos de voo. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, aibase;

const
  FQ777_DEFAULT_HOST = '172.16.10.1';
  FQ777_DEFAULT_TCP_PORT = 8888;
  FQ777_DEFAULT_UDP_PORT = 8895;
  FQ777_AXIS_CENTER = 127;
  FQ777_PACKET_SIZE = 8;
  FQ777_VIDEO_WIDTH = 720;
  FQ777_VIDEO_HEIGHT = 576;

type
  TFQ777ControlPacket = array[0..FQ777_PACKET_SIZE - 1] of Byte;

  TAIDroneVideoDataEvent = procedure(Sender: TObject; AData: PByte;
    ACount: Integer) of object;
  TAIDroneMessageEvent = procedure(Sender: TObject; const AMessage: string) of object;

  { TAIDroneFQ777 }

  TAIDroneFQ777 = class(TAIBaseComponent)
  private
    FHost: string;
    FTcpPort: Integer;
    FUdpPort: Integer;
    FSendIntervalMs: Integer;
    FConnectTimeoutMs: Integer;
    FStickTimeoutMs: Integer;
    FVideoEnabled: Boolean;
    FCutThrottleOnDisconnect: Boolean;
    FDeadZone: Double;
    FOnVideoData: TAIDroneVideoDataEvent;
    FOnStatus: TAIDroneMessageEvent;
    FOnError: TAIDroneMessageEvent;
    FOnStateChange: TNotifyEvent;

    FStickLock: TCriticalSection;
    FEventLock: TCriticalSection;
    FRoll, FPitch, FThrottle, FYaw, FFlags: Byte;
    FLastStickUpdate: QWord;
    FControlThread: TThread;
    FVideoThread: TThread;
    FControlConnected: Boolean;
    FVideoConnected: Boolean;
    FPendingStatus: TStringList;
    FPendingErrors: TStringList;
    FStateChanged: Boolean;
    FPacketsSent: Int64;
    FVideoBytes: Int64;
    FVideoChunksIgnored: Int64;
    FLastVideoTick: QWord;
    FLastPacket: TFQ777ControlPacket;

    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    procedure SetRoll(AValue: Byte);
    procedure SetPitch(AValue: Byte);
    procedure SetThrottle(AValue: Byte);
    procedure SetYaw(AValue: Byte);
    procedure SetFlags(AValue: Byte);
    function GetRoll: Byte;
    function GetPitch: Byte;
    function GetThrottle: Byte;
    function GetYaw: Byte;
    function GetLastPacket: TFQ777ControlPacket;
    procedure TouchSticks;
    procedure DeliverEvents;
  protected
    { Usados pelas linhas internas. }
    procedure PostStatus(const AMessage: string);
    procedure PostError(const AMessage: string);
    procedure SetControlConnected(AValue: Boolean);
    procedure SetVideoConnected(AValue: Boolean);
    function CurrentPacket(out ATimedOut: Boolean): TFQ777ControlPacket;
    procedure NotePacketSent(const APacket: TFQ777ControlPacket);
    procedure DoVideoData(AData: PByte; ACount: Integer);
    procedure NoteVideoIgnored;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Conecta (assíncrono): o progresso chega por OnStatus/OnStateChange.
      A aceleração é zerada e os demais eixos centralizados ao conectar. }
    procedure Connect;
    { Desconecta. Com CutThrottleOnDisconnect, envia antes alguns comandos com
      aceleração zero e eixos no centro. }
    procedure Disconnect;

    { Define os comandos com valores normalizados, já aplicando DeadZone:
        ARoll   -1 (esquerda) .. +1 (direita)
        APitch  -1 (trás)     .. +1 (frente)
        AYaw    -1 (esquerda) .. +1 (direita)
        AThrottle 0 (parado)  .. 1 (máximo) }
    procedure SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
    { Eixos no centro e aceleração zero. }
    procedure Neutral;

    { Monta o pacote UDP de comando do FQ777-954. }
    class function BuildControlPacket(ARoll, APitch, AThrottle, AYaw,
      AFlags: Byte): TFQ777ControlPacket; static;
    { Converte -1..1 em 0..255 (0 -> 127). }
    class function AxisToByte(AValue: Double): Byte; static;
    { Converte 0..1 em 0..255. }
    class function ThrottleToByte(AValue: Double): Byte; static;
    { Zona morta proporcional: |v| <= ADeadZone vira 0 e o restante é
      reescalado para continuar chegando a 1. }
    class function ApplyDeadZone(AValue, ADeadZone: Double): Double; static;
    { True se o bloco for uma resposta de 106 bytes 'ITd' do drone. }
    class function IsDroneReply(AData: PByte; ACount: Integer): Boolean; static;
    class function PacketToHex(const APacket: TFQ777ControlPacket): string; static;

    property Active: Boolean read GetActive write SetActive;
    property ControlConnected: Boolean read FControlConnected;
    property VideoConnected: Boolean read FVideoConnected;
    { True se chegou vídeo no último segundo. }
    function VideoStreaming: Boolean;
    property PacketsSent: Int64 read FPacketsSent;
    property VideoBytes: Int64 read FVideoBytes;
    property VideoChunksIgnored: Int64 read FVideoChunksIgnored;
    property LastPacket: TFQ777ControlPacket read GetLastPacket;

    property Roll: Byte read GetRoll write SetRoll;
    property Pitch: Byte read GetPitch write SetPitch;
    property Throttle: Byte read GetThrottle write SetThrottle;
    property Yaw: Byte read GetYaw write SetYaw;
    { Byte 5 do pacote. O aplicativo de referência sempre envia 0; o
      significado dos bits não é documentado para este modelo. }
    property Flags: Byte read FFlags write SetFlags;
  published
    property Host: string read FHost write FHost;
    property TcpPort: Integer read FTcpPort write FTcpPort default FQ777_DEFAULT_TCP_PORT;
    property UdpPort: Integer read FUdpPort write FUdpPort default FQ777_DEFAULT_UDP_PORT;
    property SendIntervalMs: Integer read FSendIntervalMs write FSendIntervalMs default 50;
    property ConnectTimeoutMs: Integer read FConnectTimeoutMs write FConnectTimeoutMs default 2000;
    { Se os comandos não forem atualizados neste tempo, rolagem/arfagem/guinada
      voltam ao centro (a aceleração é mantida). 0 desliga. }
    property StickTimeoutMs: Integer read FStickTimeoutMs write FStickTimeoutMs default 500;
    property VideoEnabled: Boolean read FVideoEnabled write FVideoEnabled default True;
    property CutThrottleOnDisconnect: Boolean read FCutThrottleOnDisconnect
      write FCutThrottleOnDisconnect default True;
    { Zona morta usada por SetSticks (0..0.9). }
    property DeadZone: Double read FDeadZone write FDeadZone;
    { Chamado na linha de vídeo com o H.264 bruto, já sem as respostas 'ITd'. }
    property OnVideoData: TAIDroneVideoDataEvent read FOnVideoData write FOnVideoData;
    property OnStatus: TAIDroneMessageEvent read FOnStatus write FOnStatus;
    property OnError: TAIDroneMessageEvent read FOnError write FOnError;
    { Mudança em ControlConnected ou VideoConnected (linha principal). }
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
  end;

const
  FQ777_MAGIC_CTRL: array[0..105] of Byte = (
    $49, $54, $64, $00, $00, $00, $5D, $00, $00, $00, $81, $85, $FF, $BD, $2A, $29, $5C, $AD, $67, $82, $5C, $57, $BE, $41, $03, $F8, $CA, $E2, $64, $30, $A3, $C1,
    $5E, $40, $DE, $30, $F6, $D6, $95, $E0, $30, $B7, $C2, $E5, $B7, $D6, $5D, $A8, $65, $9E, $B2, $E2, $D5, $E0, $C2, $CB, $6C, $59, $CD, $CB, $66, $1E, $7E, $1E,
    $B0, $CE, $8E, $E8, $DF, $32, $45, $6F, $A8, $42, $EE, $2E, $09, $A3, $9B, $DD, $05, $C8, $30, $A2, $81, $C8, $2A, $9E, $DA, $7F, $D5, $86, $0E, $AF, $AB, $FE,
    $FA, $3C, $7E, $54, $4F, $F2, $8A, $D2, $93, $CD
  );

  FQ777_MAGIC_VIDEO_1A: array[0..105] of Byte = (
    $49, $54, $64, $00, $00, $00, $52, $00, $00, $00, $0F, $32, $81, $95, $45, $2E, $F5, $E1, $A9, $28, $10, $86, $63, $17, $36, $C3, $CA, $E2, $64, $30, $A3, $C1,
    $5E, $40, $DE, $30, $F6, $D6, $95, $E0, $30, $B7, $C2, $E5, $B7, $D6, $5D, $A8, $65, $9E, $B2, $E2, $D5, $E0, $C2, $CB, $6C, $59, $CD, $CB, $66, $1E, $7E, $1E,
    $B0, $CE, $8E, $E8, $DF, $32, $45, $6F, $A8, $42, $B7, $33, $0F, $B7, $C9, $57, $82, $FC, $3D, $67, $E7, $C3, $A6, $67, $28, $DA, $D8, $B5, $98, $48, $C7, $67,
    $0C, $94, $B2, $9B, $54, $D2, $37, $9E, $2E, $7A
  );

  FQ777_MAGIC_VIDEO_1B: array[0..105] of Byte = (
    $49, $54, $64, $00, $00, $00, $52, $00, $00, $00, $54, $B2, $D1, $F6, $63, $48, $C7, $CD, $B6, $E0, $5B, $0D, $1D, $BC, $A8, $1B, $CA, $E2, $64, $30, $A3, $C1,
    $5E, $40, $DE, $30, $F6, $D6, $95, $E0, $30, $B7, $C2, $E5, $B7, $D6, $5D, $A8, $65, $9E, $B2, $E2, $D5, $E0, $C2, $CB, $6C, $59, $CD, $CB, $66, $1E, $7E, $1E,
    $B0, $CE, $8E, $E8, $DF, $32, $45, $6F, $A8, $42, $B7, $33, $0F, $B7, $C9, $57, $82, $FC, $3D, $67, $E7, $C3, $A6, $67, $28, $DA, $D8, $B5, $98, $48, $C7, $67,
    $0C, $94, $B2, $9B, $54, $D2, $37, $9E, $2E, $7A
  );

  FQ777_MAGIC_VIDEO_2: array[0..105] of Byte = (
    $49, $54, $64, $00, $00, $00, $58, $00, $00, $00, $80, $86, $38, $C3, $8D, $13, $50, $FD, $67, $41, $C2, $EE, $36, $89, $A0, $54, $CA, $E2, $64, $30, $A3, $C1,
    $5E, $40, $DE, $30, $F6, $D6, $95, $E0, $30, $B7, $C2, $E5, $B7, $D6, $5D, $A8, $65, $9E, $B2, $E2, $D5, $E0, $C2, $CB, $6C, $59, $CD, $CB, $66, $1E, $7E, $1E,
    $B0, $CE, $8E, $E8, $DF, $32, $45, $6F, $A8, $42, $EB, $20, $BE, $38, $3A, $AB, $05, $A8, $C2, $A7, $1F, $2C, $90, $6D, $93, $F7, $2A, $85, $E7, $35, $6E, $FF,
    $E1, $B8, $F5, $AF, $09, $7F, $91, $47, $F8, $7E
  );

procedure Register;

implementation

uses
  Math, aisockets;

const
  REPLY_SIZE = 106;

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneFQ777]);
end;

function OpenTcp(const AHost: string; APort, ATimeoutMs: Integer;
  out AError: string): TAISocketTCP;
begin
  Result := TAISocketTCP.Create(nil);
  Result.Mode := smClient;
  Result.Host := AHost;
  Result.Port := APort;
  Result.ConnectTimeoutMs := ATimeoutMs;
  if not Result.Connect then
  begin
    AError := Result.LastError;
    FreeAndNil(Result);
  end;
end;

type

  { TFQ777WorkerBase }

  TFQ777WorkerBase = class(TThread)
  protected
    FOwner: TAIDroneFQ777;
    FHost: string;
    FTcpPort: Integer;
    FUdpPort: Integer;
    FConnectTimeoutMs: Integer;
    procedure Pause(AMs: Integer);
  public
    constructor Create(AOwner: TAIDroneFQ777);
  end;

  { TFQ777ControlThread }

  TFQ777ControlThread = class(TFQ777WorkerBase)
  private
    FCtrl: TAISocketTCP;
    FUdp: TAISocketUDP;
    FIntervalMs: Integer;
    FCutOnExit: Boolean;
    FTimeoutWarned: Boolean;
    function OpenUdp: Boolean;
    procedure SendPacket(const APacket: TFQ777ControlPacket);
    procedure CloseCtrl(const AReason: string);
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIDroneFQ777);
  end;

  { TFQ777VideoThread }

  TFQ777VideoThread = class(TFQ777WorkerBase)
  private
    FVideo1: TAISocketTCP;
    FVideo2: TAISocketTCP;
    FSynced: Boolean;
    FCarry: array[0..2] of Byte;
    FCarryLen: Integer;
    procedure CloseVideo(const AReason: string);
    function OpenVideo: Boolean;
    procedure ProcessChunk(AData: PByte; ACount: Integer);
  protected
    procedure Execute; override;
  end;

{ TFQ777WorkerBase }

constructor TFQ777WorkerBase.Create(AOwner: TAIDroneFQ777);
begin
  FOwner := AOwner;
  FHost := AOwner.Host;
  FTcpPort := AOwner.TcpPort;
  FUdpPort := AOwner.UdpPort;
  FConnectTimeoutMs := Max(200, AOwner.ConnectTimeoutMs);
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TFQ777WorkerBase.Pause(AMs: Integer);
var
  T: QWord;
begin
  T := GetTickCount64 + QWord(Max(0, AMs));
  while (not Terminated) and (GetTickCount64 < T) do
    Sleep(20);
end;

{ TFQ777ControlThread }

constructor TFQ777ControlThread.Create(AOwner: TAIDroneFQ777);
begin
  FIntervalMs := EnsureRange(AOwner.SendIntervalMs, 10, 1000);
  FCutOnExit := AOwner.CutThrottleOnDisconnect;
  inherited Create(AOwner);
end;

function TFQ777ControlThread.OpenUdp: Boolean;
begin
  FUdp := TAISocketUDP.Create(nil);
  FUdp.Host := FHost;
  FUdp.Port := FUdpPort;
  FUdp.LocalPort := 0; // porta local livre, como o aplicativo original
  Result := FUdp.OpenSocket;
  if not Result then
    FOwner.PostError('Não foi possível abrir o UDP de comando: ' + FUdp.LastError);
end;

procedure TFQ777ControlThread.SendPacket(const APacket: TFQ777ControlPacket);
begin
  if Assigned(FUdp) and FUdp.SendBuffer(APacket[0], FQ777_PACKET_SIZE) then
    FOwner.NotePacketSent(APacket);
end;

procedure TFQ777ControlThread.CloseCtrl(const AReason: string);
begin
  if Assigned(FCtrl) then
  begin
    FreeAndNil(FCtrl);
    FOwner.SetControlConnected(False);
    if AReason <> '' then
      FOwner.PostStatus(AReason);
  end;
end;

procedure TFQ777ControlThread.Execute;
var
  NextSend, Now64: QWord;
  Wait, N, I: Integer;
  Buf: array[0..2047] of Byte;
  Packet: TFQ777ControlPacket;
  TimedOut, WasConnected: Boolean;
  Err: string;
begin
  WasConnected := False;
  try
    if not OpenUdp then
      Exit;
    NextSend := GetTickCount64;
    while not Terminated do
    begin
      if not Assigned(FCtrl) then
      begin
        FOwner.PostStatus(Format('Conectando ao FQ777-954 em %s:%d...', [FHost, FTcpPort]));
        FCtrl := OpenTcp(FHost, FTcpPort, FConnectTimeoutMs, Err);
        if Assigned(FCtrl) and not FCtrl.SendBuffer(FQ777_MAGIC_CTRL, SizeOf(FQ777_MAGIC_CTRL)) then
        begin
          Err := FCtrl.LastError;
          FreeAndNil(FCtrl);
        end;
        if not Assigned(FCtrl) then
        begin
          FOwner.PostStatus('Sem resposta do drone (' + Err +
            '). Nova tentativa em 1 s.');
          Pause(1000);
          Continue;
        end;
        FOwner.SetControlConnected(True);
        WasConnected := True;
        FOwner.PostStatus('Canal de controle ativo. Enviando comandos por UDP ' +
          IntToStr(FUdpPort) + '.');
        NextSend := GetTickCount64;
      end;

      Now64 := GetTickCount64;
      if NextSend > Now64 then
        Wait := Integer(NextSend - Now64)
      else
        Wait := 0;

      // Respostas do canal de controle não carregam dados úteis: descartadas.
      N := FCtrl.ReceiveBuffer(Buf, SizeOf(Buf), Wait);
      if N < 0 then
      begin
        CloseCtrl('Canal de controle fechado pelo drone. Reconectando...');
        Continue;
      end;

      Now64 := GetTickCount64;
      if Now64 >= NextSend then
      begin
        Packet := FOwner.CurrentPacket(TimedOut);
        if TimedOut and not FTimeoutWarned then
          FOwner.PostStatus('Comandos não atualizados: eixos centralizados por segurança.');
        FTimeoutWarned := TimedOut;
        SendPacket(Packet);
        Inc(NextSend, FIntervalMs);
        if NextSend + QWord(FIntervalMs) < Now64 then
          NextSend := Now64 + QWord(FIntervalMs); // não tenta "recuperar" atrasos
      end;
    end;

    if FCutOnExit and WasConnected then
    begin
      Packet := TAIDroneFQ777.BuildControlPacket(FQ777_AXIS_CENTER,
        FQ777_AXIS_CENTER, 0, FQ777_AXIS_CENTER, 0);
      for I := 1 to 5 do
      begin
        SendPacket(Packet);
        Sleep(30);
      end;
    end;
  finally
    CloseCtrl('');
    FreeAndNil(FUdp);
    FOwner.SetControlConnected(False);
  end;
end;

{ TFQ777VideoThread }

procedure TFQ777VideoThread.CloseVideo(const AReason: string);
var
  WasOpen: Boolean;
begin
  WasOpen := Assigned(FVideo1) or Assigned(FVideo2);
  FreeAndNil(FVideo2);
  FreeAndNil(FVideo1);
  FSynced := False;
  FCarryLen := 0;
  FOwner.SetVideoConnected(False);
  if WasOpen and (AReason <> '') then
    FOwner.PostStatus(AReason);
end;

function TFQ777VideoThread.OpenVideo: Boolean;
var
  Err: string;
begin
  Result := False;
  Err := '';
  FVideo1 := OpenTcp(FHost, FTcpPort, FConnectTimeoutMs, Err);
  if Assigned(FVideo1) and
    FVideo1.SendBuffer(FQ777_MAGIC_VIDEO_1A, SizeOf(FQ777_MAGIC_VIDEO_1A)) and
    FVideo1.SendBuffer(FQ777_MAGIC_VIDEO_1B, SizeOf(FQ777_MAGIC_VIDEO_1B)) then
  begin
    FVideo2 := OpenTcp(FHost, FTcpPort, FConnectTimeoutMs, Err);
    if Assigned(FVideo2) and
      FVideo2.SendBuffer(FQ777_MAGIC_VIDEO_2, SizeOf(FQ777_MAGIC_VIDEO_2)) then
    begin
      FSynced := False;
      FCarryLen := 0;
      FOwner.SetVideoConnected(True);
      FOwner.PostStatus('Canal de vídeo aberto. Aguardando imagem H.264...');
      Exit(True);
    end;
  end;
  if (Err = '') and Assigned(FVideo2) then Err := FVideo2.LastError;
  if (Err = '') and Assigned(FVideo1) then Err := FVideo1.LastError;
  FreeAndNil(FVideo2);
  FreeAndNil(FVideo1);
  FOwner.PostStatus('Vídeo indisponível (' + Err + '). Nova tentativa em 2 s.');
end;

procedure TFQ777VideoThread.ProcessChunk(AData: PByte; ACount: Integer);
var
  Tmp: array of Byte;
  I, Total: Integer;
begin
  if ACount <= 0 then
    Exit;

  if TAIDroneFQ777.IsDroneReply(AData, ACount) then
  begin
    FOwner.NoteVideoIgnored;
    Exit;
  end;

  if FSynced then
  begin
    FOwner.DoVideoData(AData, ACount);
    Exit;
  end;

  // Ainda sem sincronismo: procura o primeiro código de início 00 00 00 01,
  // inclusive se ele estiver dividido entre dois blocos.
  Total := FCarryLen + ACount;
  SetLength(Tmp, Total);
  if FCarryLen > 0 then
    Move(FCarry[0], Tmp[0], FCarryLen);
  Move(AData^, Tmp[FCarryLen], ACount);

  for I := 0 to Total - 4 do
    if (Tmp[I] = 0) and (Tmp[I + 1] = 0) and (Tmp[I + 2] = 0) and (Tmp[I + 3] = 1) then
    begin
      FSynced := True;
      FCarryLen := 0;
      FOwner.PostStatus('Vídeo sincronizado.');
      FOwner.DoVideoData(@Tmp[I], Total - I);
      Exit;
    end;

  FOwner.NoteVideoIgnored;
  FCarryLen := Min(3, Total);
  Move(Tmp[Total - FCarryLen], FCarry[0], FCarryLen);
end;

procedure TFQ777VideoThread.Execute;
var
  Buf: array of Byte;
  N: Integer;
begin
  SetLength(Buf, 65536);
  try
    while not Terminated do
    begin
      if not Assigned(FVideo2) then
      begin
        if not OpenVideo then
        begin
          Pause(2000);
          Continue;
        end;
      end;

      // Canal de vídeo 1: só precisa ser mantido aberto e esvaziado.
      if FVideo1.ReceiveBuffer(Buf[0], Length(Buf), 0) < 0 then
      begin
        CloseVideo('Canal de vídeo fechado pelo drone. Reconectando...');
        Pause(500);
        Continue;
      end;

      N := FVideo2.ReceiveBuffer(Buf[0], Length(Buf), 100);
      if N < 0 then
      begin
        CloseVideo('Fluxo de vídeo interrompido. Reconectando...');
        Pause(500);
        Continue;
      end;
      if N > 0 then
        ProcessChunk(@Buf[0], N);
    end;
  finally
    CloseVideo('');
  end;
end;

{ TAIDroneFQ777 }

constructor TAIDroneFQ777.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  Prompt := 'Component TAIDroneFQ777 controls the FQ777-954 Wi-Fi quadcopter only (host 172.16.10.1, TCP 8888 handshake, UDP 8895 commands every 50 ms). Methods: Connect, Disconnect, SetSticks(Roll, Pitch, Yaw: -1..1; Throttle: 0..1), Neutral. Properties: Roll, Pitch, Throttle, Yaw (bytes, center 127, throttle 0 = stopped), StickTimeoutMs, CutThrottleOnDisconnect, VideoEnabled. Events: OnVideoData (raw H.264, network thread; feed a TAIH264Decoder), OnStatus, OnError, OnStateChange.';
  FHost := FQ777_DEFAULT_HOST;
  FTcpPort := FQ777_DEFAULT_TCP_PORT;
  FUdpPort := FQ777_DEFAULT_UDP_PORT;
  FSendIntervalMs := 50;
  FConnectTimeoutMs := 2000;
  FStickTimeoutMs := 500;
  FVideoEnabled := True;
  FCutThrottleOnDisconnect := True;
  FDeadZone := 0.08;
  FStickLock := TCriticalSection.Create;
  FEventLock := TCriticalSection.Create;
  FPendingStatus := TStringList.Create;
  FPendingErrors := TStringList.Create;
  Neutral;
end;

destructor TAIDroneFQ777.Destroy;
begin
  Disconnect;
  TThread.RemoveQueuedEvents(@DeliverEvents);
  FPendingErrors.Free;
  FPendingStatus.Free;
  FEventLock.Free;
  FStickLock.Free;
  inherited Destroy;
end;

function TAIDroneFQ777.GetActive: Boolean;
begin
  Result := Assigned(FControlThread);
end;

procedure TAIDroneFQ777.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

procedure TAIDroneFQ777.Connect;
begin
  if Assigned(FControlThread) then
    Exit;
  ClearError;
  Neutral;
  FPacketsSent := 0;
  FVideoBytes := 0;
  FVideoChunksIgnored := 0;
  FLastVideoTick := 0;
  FControlThread := TFQ777ControlThread.Create(Self);
  if FVideoEnabled then
    FVideoThread := TFQ777VideoThread.Create(Self);
end;

procedure TAIDroneFQ777.Disconnect;
begin
  if Assigned(FVideoThread) then
  begin
    FVideoThread.Terminate;
    FVideoThread.WaitFor;
    TThread.RemoveQueuedEvents(FVideoThread);
    FreeAndNil(FVideoThread);
  end;
  if Assigned(FControlThread) then
  begin
    FControlThread.Terminate;
    FControlThread.WaitFor;
    TThread.RemoveQueuedEvents(FControlThread);
    FreeAndNil(FControlThread);
    PostStatus('Desconectado do FQ777-954.');
  end;
  FControlConnected := False;
  FVideoConnected := False;
end;

procedure TAIDroneFQ777.TouchSticks;
begin
  FLastStickUpdate := GetTickCount64;
end;

procedure TAIDroneFQ777.SetRoll(AValue: Byte);
begin
  FRoll := AValue;
  TouchSticks;
end;

procedure TAIDroneFQ777.SetPitch(AValue: Byte);
begin
  FPitch := AValue;
  TouchSticks;
end;

procedure TAIDroneFQ777.SetThrottle(AValue: Byte);
begin
  FThrottle := AValue;
  TouchSticks;
end;

procedure TAIDroneFQ777.SetYaw(AValue: Byte);
begin
  FYaw := AValue;
  TouchSticks;
end;

procedure TAIDroneFQ777.SetFlags(AValue: Byte);
begin
  FFlags := AValue;
end;

function TAIDroneFQ777.GetRoll: Byte;
begin
  Result := FRoll;
end;

function TAIDroneFQ777.GetPitch: Byte;
begin
  Result := FPitch;
end;

function TAIDroneFQ777.GetThrottle: Byte;
begin
  Result := FThrottle;
end;

function TAIDroneFQ777.GetYaw: Byte;
begin
  Result := FYaw;
end;

procedure TAIDroneFQ777.SetSticks(ARoll, APitch, AYaw, AThrottle: Double);
var
  DZ: Double;
begin
  DZ := EnsureRange(FDeadZone, 0, 0.9);
  FStickLock.Enter;
  try
    FRoll := AxisToByte(ApplyDeadZone(ARoll, DZ));
    FPitch := AxisToByte(ApplyDeadZone(APitch, DZ));
    FYaw := AxisToByte(ApplyDeadZone(AYaw, DZ));
    FThrottle := ThrottleToByte(AThrottle);
    TouchSticks;
  finally
    FStickLock.Leave;
  end;
end;

procedure TAIDroneFQ777.Neutral;
begin
  FStickLock.Enter;
  try
    FRoll := FQ777_AXIS_CENTER;
    FPitch := FQ777_AXIS_CENTER;
    FYaw := FQ777_AXIS_CENTER;
    FThrottle := 0;
    TouchSticks;
  finally
    FStickLock.Leave;
  end;
end;

function TAIDroneFQ777.CurrentPacket(out ATimedOut: Boolean): TFQ777ControlPacket;
var
  R, P, T, Y, F: Byte;
begin
  FStickLock.Enter;
  try
    R := FRoll; P := FPitch; T := FThrottle; Y := FYaw; F := FFlags;
    ATimedOut := (FStickTimeoutMs > 0) and
      (GetTickCount64 - FLastStickUpdate > QWord(FStickTimeoutMs));
  finally
    FStickLock.Leave;
  end;
  if ATimedOut then
  begin
    R := FQ777_AXIS_CENTER;
    P := FQ777_AXIS_CENTER;
    Y := FQ777_AXIS_CENTER;
  end;
  Result := BuildControlPacket(R, P, T, Y, F);
end;

procedure TAIDroneFQ777.NotePacketSent(const APacket: TFQ777ControlPacket);
begin
  FStickLock.Enter;
  try
    FLastPacket := APacket;
    Inc(FPacketsSent);
  finally
    FStickLock.Leave;
  end;
end;

function TAIDroneFQ777.GetLastPacket: TFQ777ControlPacket;
begin
  FStickLock.Enter;
  try
    Result := FLastPacket;
  finally
    FStickLock.Leave;
  end;
end;

procedure TAIDroneFQ777.DoVideoData(AData: PByte; ACount: Integer);
begin
  Inc(FVideoBytes, ACount);
  FLastVideoTick := GetTickCount64;
  if Assigned(FOnVideoData) then
    FOnVideoData(Self, AData, ACount);
end;

procedure TAIDroneFQ777.NoteVideoIgnored;
begin
  Inc(FVideoChunksIgnored);
end;

function TAIDroneFQ777.VideoStreaming: Boolean;
begin
  Result := (FLastVideoTick > 0) and (GetTickCount64 - FLastVideoTick < 1000);
end;

procedure TAIDroneFQ777.SetControlConnected(AValue: Boolean);
begin
  if FControlConnected = AValue then
    Exit;
  FControlConnected := AValue;
  FEventLock.Enter;
  try
    FStateChanged := True;
  finally
    FEventLock.Leave;
  end;
  TThread.Queue(nil, @DeliverEvents);
end;

procedure TAIDroneFQ777.SetVideoConnected(AValue: Boolean);
begin
  if FVideoConnected = AValue then
    Exit;
  FVideoConnected := AValue;
  FEventLock.Enter;
  try
    FStateChanged := True;
  finally
    FEventLock.Leave;
  end;
  TThread.Queue(nil, @DeliverEvents);
end;

procedure TAIDroneFQ777.PostStatus(const AMessage: string);
begin
  FEventLock.Enter;
  try
    FPendingStatus.Add(AMessage);
  finally
    FEventLock.Leave;
  end;
  TThread.Queue(nil, @DeliverEvents);
end;

procedure TAIDroneFQ777.PostError(const AMessage: string);
begin
  FEventLock.Enter;
  try
    FPendingErrors.Add(AMessage);
  finally
    FEventLock.Leave;
  end;
  TThread.Queue(nil, @DeliverEvents);
end;

procedure TAIDroneFQ777.DeliverEvents;
var
  Status, Errors: TStringList;
  Changed: Boolean;
  I: Integer;
begin
  Status := TStringList.Create;
  Errors := TStringList.Create;
  try
    FEventLock.Enter;
    try
      Status.Assign(FPendingStatus);
      Errors.Assign(FPendingErrors);
      FPendingStatus.Clear;
      FPendingErrors.Clear;
      Changed := FStateChanged;
      FStateChanged := False;
    finally
      FEventLock.Leave;
    end;

    for I := 0 to Errors.Count - 1 do
    begin
      SetError(Errors[I]);
      Log(llError, Errors[I]);
      if Assigned(FOnError) then
        FOnError(Self, Errors[I]);
    end;
    for I := 0 to Status.Count - 1 do
    begin
      Log(llInfo, Status[I]);
      if Assigned(FOnStatus) then
        FOnStatus(Self, Status[I]);
    end;
    if Changed and Assigned(FOnStateChange) then
      FOnStateChange(Self);
  finally
    Errors.Free;
    Status.Free;
  end;
end;

class function TAIDroneFQ777.BuildControlPacket(ARoll, APitch, AThrottle, AYaw,
  AFlags: Byte): TFQ777ControlPacket;
begin
  Result[0] := $CC;
  Result[1] := ARoll;
  Result[2] := APitch;
  Result[3] := AThrottle;
  Result[4] := AYaw;
  Result[5] := AFlags;
  Result[6] := (ARoll xor APitch xor AThrottle xor AYaw xor AFlags) and $FF;
  Result[7] := $33;
end;

class function TAIDroneFQ777.AxisToByte(AValue: Double): Byte;
begin
  if IsNan(AValue) then
    Exit(FQ777_AXIS_CENTER);
  AValue := EnsureRange(AValue, -1.0, 1.0);
  Result := Byte(EnsureRange(Trunc((AValue + 1.0) * 127.5), 0, 255));
end;

class function TAIDroneFQ777.ThrottleToByte(AValue: Double): Byte;
begin
  if IsNan(AValue) then
    Exit(0);
  AValue := EnsureRange(AValue, 0.0, 1.0);
  Result := Byte(EnsureRange(Round(AValue * 255.0), 0, 255));
end;

class function TAIDroneFQ777.ApplyDeadZone(AValue, ADeadZone: Double): Double;
begin
  if IsNan(AValue) then
    Exit(0);
  ADeadZone := EnsureRange(ADeadZone, 0.0, 0.9);
  if Abs(AValue) <= ADeadZone then
    Exit(0);
  Result := (Abs(AValue) - ADeadZone) / (1.0 - ADeadZone);
  if Result > 1 then
    Result := 1;
  if AValue < 0 then
    Result := -Result;
end;

class function TAIDroneFQ777.IsDroneReply(AData: PByte; ACount: Integer): Boolean;
begin
  Result := (ACount = REPLY_SIZE) and (AData[0] = $49) and (AData[1] = $54) and
    (AData[2] = $64) and (AData[3] = $00);
end;

class function TAIDroneFQ777.PacketToHex(const APacket: TFQ777ControlPacket): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(APacket) do
  begin
    if I > 0 then
      Result := Result + ' ';
    Result := Result + IntToHex(APacket[I], 2);
  end;
end;

end.
