unit aimqtt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sockets, aibase,
  {$IFDEF MSWINDOWS}
  winsock2,
  {$ELSE}
  netdb,
  {$ENDIF}
  Math, LResources;

type
  TMQTTMessageEvent = procedure(Sender: TObject; const ATopic, APayload: string) of object;

  { TAIMQTTReceiverThread }

  TAIMQTTClient = class;

  TAIMQTTReceiverThread = class(TThread)
  private
    FClient: TAIMQTTClient;
    FSocket: TSocket;
    FCurrentTopic: string;
    FCurrentPayload: string;
    FLogMsg: string;
    FLogLevel: TAILogLevel;
    procedure SyncTrigger;
    procedure SyncLog;
  protected
    procedure Execute; override;
  public
    constructor Create(AClient: TAIMQTTClient; ASock: TSocket);
  end;

  { TAIMQTTClient }

  TAIMQTTClient = class(TAIBaseComponent)
  private
    FHost: string;
    FPort: Integer;
    FClientID: string;
    FKeepAlive: Integer;
    FActive: Boolean;
    FSocket: TSocket;
    FThread: TAIMQTTReceiverThread;
    FOnMessageReceived: TMQTTMessageEvent;
    FOnConnected: TNotifyEvent;
    FOnDisconnected: TNotifyEvent;
    FLastTopic: string;
    FLastPayload: string;
    
    procedure SetActive(AValue: Boolean);
    procedure TriggerMessage(const ATopic, APayload: string);
    procedure TriggerConnected;
    procedure DoDisconnect;
    function ResolveHost(const AHost: string; var AAddr: sockets.in_addr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function ConnectBroker: Boolean;
    procedure DisconnectBroker;
    function Subscribe(const ATopic: string): Boolean;
    function Publish(const ATopic, APayload: string): Boolean;
    function Ping: Boolean;
    
    property LastTopic: string read FLastTopic;
    property LastPayload: string read FLastPayload;
  published
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 1883;
    property ClientID: string read FClientID write FClientID;
    property KeepAlive: Integer read FKeepAlive write FKeepAlive default 60;
    property Active: Boolean read FActive write SetActive default False;
    
    property OnMessageReceived: TMQTTMessageEvent read FOnMessageReceived write FOnMessageReceived;
    property OnConnected: TNotifyEvent read FOnConnected write FOnConnected;
    property OnDisconnected: TNotifyEvent read FOnDisconnected write FOnDisconnected;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIMQTTClient]);
end;

{ TAIMQTTReceiverThread }

constructor TAIMQTTReceiverThread.Create(AClient: TAIMQTTClient; ASock: TSocket);
begin
  inherited Create(True);
  FClient := AClient;
  FSocket := ASock;
  FreeOnTerminate := True;
end;

procedure TAIMQTTReceiverThread.SyncTrigger;
begin
  FClient.TriggerMessage(FCurrentTopic, FCurrentPayload);
end;

procedure TAIMQTTReceiverThread.SyncLog;
begin
  if Assigned(FClient) then
    FClient.Log(FLogLevel, FLogMsg);
end;

procedure TAIMQTTReceiverThread.Execute;
var
  Buffer: array[0..8191] of Byte;
  BytesRead: Integer;
  PacketType, Flags: Byte;
  RemainingLen, Multiplier: Integer;
  TopicLen, PosIdx, PacketStart, QoS: Integer;
  Topic, Payload: string;
  I: Integer;
  Digit: Byte;
begin
  FLogMsg := 'Thread de escuta MQTT iniciada.';
  FLogLevel := llDebug;
  Synchronize(@SyncLog);

  while not Terminated do
  begin
    BytesRead := fprecv(FSocket, @Buffer[0], SizeOf(Buffer), 0);
    if BytesRead <= 0 then
    begin
      FLogMsg := 'Conexão com o broker MQTT encerrada pelo servidor (EOF / Socket fechado).';
      FLogLevel := llWarning;
      Synchronize(@SyncLog);
      Synchronize(@FClient.DoDisconnect);
      Break;
    end;

    PosIdx := 0;
    while PosIdx < BytesRead do
    begin
      PacketStart := PosIdx;
      PacketType := Buffer[PosIdx] shr 4;
      Flags := Buffer[PosIdx] and $0F;
      Inc(PosIdx);

      // Decodifica Remaining Length (inteiro de tamanho variável)
      RemainingLen := 0;
      Multiplier := 1;
      repeat
        if PosIdx >= BytesRead then Break;
        Digit := Buffer[PosIdx];
        Inc(PosIdx);
        RemainingLen := RemainingLen + (Digit and 127) * Multiplier;
        Multiplier := Multiplier * 128;
      until (Digit and 128) = 0;

      if PosIdx + RemainingLen > BytesRead then
        Break;

      case PacketType of
        2: // CONNACK ($20)
        begin
          if RemainingLen >= 2 then
          begin
            case Buffer[PosIdx + 1] of
              0: FLogMsg := '<<< [CONNACK] Conexão aceita pelo broker MQTT (Código 0: Conectado)!';
              1: FLogMsg := '<<< [CONNACK] Falha na conexão: Versão do protocolo inaceitável (Código 1).';
              2: FLogMsg := '<<< [CONNACK] Falha na conexão: Identificador de cliente rejeitado (Código 2).';
              3: FLogMsg := '<<< [CONNACK] Falha na conexão: Servidor MQTT indisponível (Código 3).';
              4: FLogMsg := '<<< [CONNACK] Falha na conexão: Usuário/Senha inválidos (Código 4).';
              5: FLogMsg := '<<< [CONNACK] Falha na conexão: Não autorizado (Código 5).';
              else FLogMsg := Format('<<< [CONNACK] Resposta do broker com código: %d', [Buffer[PosIdx + 1]]);
            end;
            FLogLevel := llInfo;
            Synchronize(@SyncLog);

            if Buffer[PosIdx + 1] = 0 then
              Synchronize(@FClient.TriggerConnected);
          end;
        end;

        3: // PUBLISH ($30..$3F)
        begin
          QoS := (Flags and $06) shr 1;
          if RemainingLen >= 2 then
          begin
            TopicLen := (Buffer[PosIdx] shl 8) + Buffer[PosIdx + 1];
            Inc(PosIdx, 2);
            SetLength(Topic, TopicLen);
            for I := 0 to TopicLen - 1 do
              Topic[I + 1] := Char(Buffer[PosIdx + I]);
            Inc(PosIdx, TopicLen);

            if (QoS > 0) and (RemainingLen >= TopicLen + 4) then
            begin
              Inc(PosIdx, 2); // Pula Packet Identifier
              SetLength(Payload, RemainingLen - TopicLen - 4);
            end
            else if RemainingLen >= TopicLen + 2 then
              SetLength(Payload, RemainingLen - TopicLen - 2)
            else
              SetLength(Payload, 0);

            if Length(Payload) > 0 then
            begin
              for I := 0 to Length(Payload) - 1 do
                Payload[I + 1] := Char(Buffer[PosIdx + I]);
              Inc(PosIdx, Length(Payload));
            end;

            FCurrentTopic := Topic;
            FCurrentPayload := Payload;
            FLogMsg := Format('<<< [PUBLISH RECEBIDO] Tópico: "%s" (%d bytes)', [Topic, Length(Payload)]);
            FLogLevel := llInfo;
            Synchronize(@SyncLog);
            Synchronize(@SyncTrigger);
          end;
        end;

        9: // SUBACK ($90)
        begin
          FLogMsg := '<<< [SUBACK] Assinatura de tópico confirmada pelo broker MQTT!';
          FLogLevel := llInfo;
          Synchronize(@SyncLog);
        end;

        13: // PINGRESP ($D0)
        begin
          FLogMsg := '<<< [PINGRESP] Resposta do broker recebida (Pong / KeepAlive OK).';
          FLogLevel := llDebug;
          Synchronize(@SyncLog);
        end;
      end;

      if PosIdx < PacketStart + 1 + RemainingLen then
        PosIdx := PacketStart + 1 + RemainingLen;
    end;

    Sleep(10);
  end;
end;

{ TAIMQTTClient }

constructor TAIMQTTClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIMQTTClient is an IoT MQTT client. Properties: Host: string (MQTT broker address), Port: Integer (default 1883), ClientID: string, KeepAlive: Integer, Active: Boolean (triggers background listener thread connection), OnMessageReceived: TMQTTMessageEvent, OnConnected/OnDisconnected: TNotifyEvent. Methods: ConnectBroker, DisconnectBroker, Subscribe(const ATopic: string): Boolean, Publish(const ATopic, APayload: string): Boolean. AI Agent: Use this to publish telemetry or receive commands via MQTT brokers in IoT setups.';
  FHost := 'broker.hivemq.com';
  FPort := 1883;
  FClientID := 'LAZ_AI_CLIENT_' + IntToStr(Random(10000));
  FKeepAlive := 60;
  FActive := False;
  FSocket := TSocket(-1);
end;

destructor TAIMQTTClient.Destroy;
begin
  DisconnectBroker;
  inherited Destroy;
end;

function TAIMQTTClient.ResolveHost(const AHost: string; var AAddr: sockets.in_addr): Boolean;
var
  CleanHost: string;
  {$IFDEF MSWINDOWS}
  WData: winsock2.TWSAData;
  HostEnt: winsock2.PHostEnt;
  AddrVal: Cardinal;
  {$ELSE}
  HostEnt: netdb.THostEntry;
  NetAddr: sockets.in_addr;
  {$ENDIF}
begin
  Result := False;
  CleanHost := Trim(AHost);
  if CleanHost = '' then
  begin
    SetError('Host não informado.');
    Log(llError, FLastError);
    Exit;
  end;

  Log(llInfo, Format('[DNS] Resolvendo endereço do broker: "%s"...', [CleanHost]));

  {$IFDEF MSWINDOWS}
  if winsock2.WSAStartup($0202, WData) <> 0 then
  begin
    SetError('Falha ao inicializar biblioteca WinSock2.');
    Log(llError, FLastError);
    Exit;
  end;

  AddrVal := winsock2.inet_addr(PChar(CleanHost));
  if (AddrVal <> winsock2.INADDR_NONE) and (AddrVal <> 0) then
  begin
    Move(AddrVal, AAddr, 4);
    Log(llInfo, Format('[DNS] Endereço IPv4 numérico reconhecido: %s', [sockets.NetAddrToStr(AAddr)]));
    Exit(True);
  end;

  HostEnt := winsock2.gethostbyname(PChar(CleanHost));
  if (HostEnt <> nil) and (HostEnt^.h_addr_list <> nil) and (HostEnt^.h_addr_list^ <> nil) then
  begin
    Move(HostEnt^.h_addr_list^^, AAddr, 4);
    Log(llInfo, Format('[DNS] Host "%s" resolvido com sucesso para o IP: %s',
      [CleanHost, sockets.NetAddrToStr(AAddr)]));
    Result := True;
  end
  else
  begin
    SetError(Format('Falha na resolução DNS de "%s" (WinSock erro: %d)',
      [CleanHost, winsock2.WSAGetLastError]));
    Log(llError, FLastError);
  end;
  {$ELSE}
  NetAddr := sockets.StrToNetAddr(CleanHost);
  if (NetAddr.s_addr <> 0) and (NetAddr.s_addr <> Cardinal($FFFFFFFF)) then
  begin
    AAddr := NetAddr;
    Log(llInfo, Format('[DNS] Endereço IPv4 numérico reconhecido: %s', [sockets.NetAddrToStr(AAddr)]));
    Exit(True);
  end;

  if netdb.ResolveHostByName(CleanHost, HostEnt) then
  begin
    Move(HostEnt.Addr, AAddr, SizeOf(in_addr));
    Log(llInfo, Format('[DNS] Host "%s" resolvido com sucesso para o IP: %s',
      [CleanHost, sockets.NetAddrToStr(AAddr)]));
    Result := True;
  end
  else
  begin
    SetError('Falha na resolução DNS de "' + CleanHost + '"');
    Log(llError, FLastError);
  end;
  {$ENDIF}
end;

procedure TAIMQTTClient.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    ConnectBroker
  else
    DisconnectBroker;
end;

function TAIMQTTClient.ConnectBroker: Boolean;
var
  Addr: TInetSockAddr;
  ConnectPacket: array[0..511] of Byte;
  Idx, I, Res: Integer;
  IPStr: string;
begin
  Result := False;
  ClearError;
  if FActive then
  begin
    Log(llWarning, 'Cliente MQTT já está conectado e ativo.');
    Exit(True);
  end;

  Log(llInfo, Format('[1/4] Preparando conexão MQTT com o broker "%s:%d"...', [FHost, FPort]));

  try
    FillChar(Addr, SizeOf(Addr), 0);
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(FPort);

    if not ResolveHost(FHost, Addr.sin_addr) then
      Exit(False);

    IPStr := sockets.NetAddrToStr(Addr.sin_addr);
    Log(llInfo, Format('[2/4] Criando socket de transporte TCP para %s:%d...', [IPStr, FPort]));

    FSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
    if FSocket = TSocket(-1) then
    begin
      SetError('Não foi possível criar o socket TCP do cliente.');
      Log(llError, FLastError);
      Exit(False);
    end;

    Log(llInfo, Format('[3/4] Estabelecendo conexão TCP com %s:%d...', [IPStr, FPort]));
    Res := fpConnect(FSocket, @Addr, SizeOf(Addr));
    if Res < 0 then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      {$IFDEF MSWINDOWS}
      SetError(Format('Falha na conexão TCP para %s:%d (WinSock erro: %d)',
        [IPStr, FPort, winsock2.WSAGetLastError]));
      {$ELSE}
      SetError(Format('Falha na conexão TCP para %s:%d (Socket erro: %d)',
        [IPStr, FPort, sockets.SocketError]));
      {$ENDIF}
      Log(llError, FLastError);
      Exit(False);
    end;

    Log(llInfo, '[4/4] Conexão TCP estabelecida! Montando pacote binário CONNECT (MQTT v3.1.1)...');

    // Monta pacote binário MQTT CONNECT v3.1.1
    Idx := 0;
    ConnectPacket[Idx] := $10; Inc(Idx); // CONNECT
    ConnectPacket[Idx] := 12 + Length(FClientID); Inc(Idx); // Remaining Length

    // Protocol Name: 0x00 0x04 'M' 'Q' 'T' 'T'
    ConnectPacket[Idx] := 0; Inc(Idx);
    ConnectPacket[Idx] := 4; Inc(Idx);
    ConnectPacket[Idx] := Ord('M'); Inc(Idx);
    ConnectPacket[Idx] := Ord('Q'); Inc(Idx);
    ConnectPacket[Idx] := Ord('T'); Inc(Idx);
    ConnectPacket[Idx] := Ord('T'); Inc(Idx);

    ConnectPacket[Idx] := 4; Inc(Idx); // Protocol Level 4 (MQTT v3.1.1)
    ConnectPacket[Idx] := $02; Inc(Idx); // Connect Flags: Clean Session

    // Keep Alive (2 bytes em big-endian)
    ConnectPacket[Idx] := FKeepAlive shr 8; Inc(Idx);
    ConnectPacket[Idx] := FKeepAlive and $FF; Inc(Idx);

    // Client ID Length (2 bytes) + string
    ConnectPacket[Idx] := Length(FClientID) shr 8; Inc(Idx);
    ConnectPacket[Idx] := Length(FClientID) and $FF; Inc(Idx);
    for I := 1 to Length(FClientID) do
    begin
      ConnectPacket[Idx] := Ord(FClientID[I]);
      Inc(Idx);
    end;

    Log(llInfo, Format('>>> [CONNECT] Transmitindo pacote CONNECT (ClientID: "%s", KeepAlive: %ds, %d bytes)...',
      [FClientID, FKeepAlive, Idx]));

    Res := fpsend(FSocket, @ConnectPacket[0], Idx, 0);
    if Res <= 0 then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      SetError('Falha ao transmitir o pacote binário CONNECT.');
      Log(llError, FLastError);
      Exit(False);
    end;

    Log(llInfo, 'Pacote CONNECT transmitido com sucesso. Aguardando CONNACK do broker...');
    FActive := True;

    // Inicia thread de escuta em background
    FThread := TAIMQTTReceiverThread.Create(Self, FSocket);
    FThread.Start;

    FLastResult := 'Conexão inicial enviada ao broker MQTT.';
    FLastSuccess := True;
    Result := True;
  except
    on E: Exception do
    begin
      SetError('Exceção ao conectar no broker: ' + E.Message);
      Log(llError, FLastError);
    end;
  end;
end;

procedure TAIMQTTClient.DisconnectBroker;
var
  DisconnectPacket: array[0..1] of Byte;
begin
  ClearError;
  try
    if not FActive then Exit;

    Log(llInfo, '>>> [DISCONNECT] Encerrando sessão MQTT e notificando broker...');

    if FThread <> nil then
    begin
      FThread.Terminate;
      FThread := nil;
    end;

    if FSocket >= 0 then
    begin
      // Pacote binário DISCONNECT ($E0, $00)
      DisconnectPacket[0] := $E0;
      DisconnectPacket[1] := $00;
      fpsend(FSocket, @DisconnectPacket[0], 2, 0);

      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
    end;

    FActive := False;
    if Assigned(FOnDisconnected) then
      FOnDisconnected(Self);

    FLastResult := 'Desconectado do broker MQTT com sucesso.';
    FLastSuccess := True;
    Log(llInfo, 'Sessão MQTT finalizada com sucesso.');
  except
    on E: Exception do
    begin
      SetError('Exceção ao desconectar do broker: ' + E.Message);
      Log(llError, FLastError);
    end;
  end;
end;

function TAIMQTTClient.Subscribe(const ATopic: string): Boolean;
var
  SubPacket: array[0..511] of Byte;
  Idx, I, Res: Integer;
begin
  Result := False;
  ClearError;
  if not FActive or (FSocket = TSocket(-1)) then
  begin
    SetError('Cliente MQTT não está conectado.');
    Log(llError, FLastError);
    Exit;
  end;

  try
    Idx := 0;
    SubPacket[Idx] := $82; Inc(Idx); // SUBSCRIBE (Packet type 8, Flags 0010)
    SubPacket[Idx] := 2 + 2 + Length(ATopic) + 1; Inc(Idx); // Remaining Length

    // Packet Identifier
    SubPacket[Idx] := 0; Inc(Idx);
    SubPacket[Idx] := 1; Inc(Idx);

    // Topic Length + Topic
    SubPacket[Idx] := Length(ATopic) shr 8; Inc(Idx);
    SubPacket[Idx] := Length(ATopic) and $FF; Inc(Idx);
    for I := 1 to Length(ATopic) do
    begin
      SubPacket[Idx] := Ord(ATopic[I]);
      Inc(Idx);
    end;

    SubPacket[Idx] := 0; Inc(Idx); // Requested QoS 0

    Log(llInfo, Format('>>> [SUBSCRIBE] Enviando solicitação de assinatura para o tópico: "%s"...', [ATopic]));
    Res := fpsend(FSocket, @SubPacket[0], Idx, 0);
    if Res > 0 then
    begin
      FLastResult := 'Assinatura enviada para o tópico: ' + ATopic;
      FLastSuccess := True;
      Result := True;
    end
    else
    begin
      SetError('Falha ao enviar pacote SUBSCRIBE.');
      Log(llError, FLastError);
    end;
  except
    on E: Exception do
    begin
      SetError('Exceção ao assinar tópico: ' + E.Message);
      Log(llError, FLastError);
    end;
  end;
end;

function TAIMQTTClient.Publish(const ATopic, APayload: string): Boolean;
var
  PubPacket: array[0..4095] of Byte;
  Idx, I, Res: Integer;
begin
  Result := False;
  ClearError;
  if not FActive or (FSocket = TSocket(-1)) then
  begin
    SetError('Cliente MQTT não está conectado.');
    Log(llError, FLastError);
    Exit;
  end;

  try
    Idx := 0;
    PubPacket[Idx] := $30; Inc(Idx); // PUBLISH (QoS 0, retain 0, dup 0)
    PubPacket[Idx] := 2 + Length(ATopic) + Length(APayload); Inc(Idx); // Remaining Length

    // Topic Length + Topic
    PubPacket[Idx] := Length(ATopic) shr 8; Inc(Idx);
    PubPacket[Idx] := Length(ATopic) and $FF; Inc(Idx);
    for I := 1 to Length(ATopic) do
    begin
      PubPacket[Idx] := Ord(ATopic[I]);
      Inc(Idx);
    end;

    // Payload
    for I := 1 to Length(APayload) do
    begin
      PubPacket[Idx] := Ord(APayload[I]);
      Inc(Idx);
    end;

    Log(llInfo, Format('>>> [PUBLISH] Publicando no tópico "%s" (%d bytes)...', [ATopic, Length(APayload)]));
    Res := fpsend(FSocket, @PubPacket[0], Idx, 0);
    if Res > 0 then
    begin
      FLastResult := 'Mensagem publicada no tópico: ' + ATopic;
      FLastSuccess := True;
      Result := True;
    end
    else
    begin
      SetError('Falha ao enviar pacote binário PUBLISH.');
      Log(llError, FLastError);
    end;
  except
    on E: Exception do
    begin
      SetError('Exceção ao publicar mensagem: ' + E.Message);
      Log(llError, FLastError);
    end;
  end;
end;

procedure TAIMQTTClient.TriggerMessage(const ATopic, APayload: string);
begin
  FLastTopic := ATopic;
  FLastPayload := APayload;
  if Assigned(FOnMessageReceived) then
    FOnMessageReceived(Self, ATopic, APayload);
end;

procedure TAIMQTTClient.TriggerConnected;
begin
  Log(llInfo, '>>> [EVENTO CONECTADO] Sessão MQTT autenticada e pronta para transmissão.');
  if Assigned(FOnConnected) then
    FOnConnected(Self);
end;

function TAIMQTTClient.Ping: Boolean;
var
  PingPacket: array[0..1] of Byte;
  Res: Integer;
begin
  Result := False;
  if not FActive or (FSocket = TSocket(-1)) then Exit;

  Log(llDebug, '>>> [PINGREQ] Enviando KeepAlive (Ping) ao broker...');
  PingPacket[0] := $C0; // PINGREQ
  PingPacket[1] := $00;
  Res := fpsend(FSocket, @PingPacket[0], 2, 0);
  Result := (Res = 2);
end;

procedure TAIMQTTClient.DoDisconnect;
begin
  FSocket := TSocket(-1);
  FActive := False;
  FThread := nil;
  Log(llInfo, '>>> [EVENTO DESCONECTADO] Conexão com o broker finalizada.');
  if Assigned(FOnDisconnected) then
    FOnDisconnected(Self);
end;

initialization
  {$I aimqtt_icon.lrs}

end.
