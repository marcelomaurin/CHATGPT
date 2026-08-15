unit aimqtt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sockets, aibase,
  {$IFDEF WIN32}
  winsock2,
  {$ELSE}
    {$IFDEF WIN64}
    winsock2,
    {$ELSE}
    netdb,
    {$ENDIF}
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
    procedure SyncTrigger;
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
    function ResolveHost(const AHost: string; var AAddr): Boolean;
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
  while not Terminated do
  begin
    BytesRead := fprecv(FSocket, @Buffer[0], SizeOf(Buffer), 0);
    if BytesRead <= 0 then
    begin
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

      // Decode Remaining Length (variable length integer)
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
          if (RemainingLen >= 2) and (Buffer[PosIdx + 1] = 0) then
            Synchronize(@FClient.TriggerConnected);
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
              Inc(PosIdx, 2); // Skip Packet Identifier
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
            Synchronize(@SyncTrigger);
          end;
        end;
        9: // SUBACK ($90)
        begin
          // Subscription acknowledged by broker
        end;
        13: // PINGRESP ($D0)
        begin
          // Ping response from broker
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

function TAIMQTTClient.ResolveHost(const AHost: string; var AAddr): Boolean;
var
  AddrVal: Cardinal;
  {$IFDEF WIN32}
  HostEnt: PHostEnt;
  {$ELSE}
    {$IFDEF WIN64}
    HostEnt: PHostEnt;
    {$ELSE}
    HostEnt: THostEntry;
    {$ENDIF}
  {$ENDIF}
begin
  Result := False;
  AddrVal := 0;
  Move(StrToNetAddr(AHost), AddrVal, 4);
  if AddrVal <> 0 then
  begin
    Move(AddrVal, AAddr, 4);
    Exit(True);
  end;
    
  {$IFDEF WIN32}
  HostEnt := gethostbyname(PChar(AHost));
  if HostEnt <> nil then
  begin
    Move(HostEnt^.h_addr_list^^, AAddr, 4);
    Result := True;
  end;
  {$ELSE}
    {$IFDEF WIN64}
    HostEnt := gethostbyname(PChar(AHost));
    if HostEnt <> nil then
    begin
      Move(HostEnt^.h_addr_list^^, AAddr, 4);
      Result := True;
    end;
    {$ELSE}
    if netdb.ResolveHostByName(AHost, HostEnt) then
    begin
      Move(HostEnt.Addr, AAddr, SizeOf(TInAddr));
      Result := True;
    end;
    {$ENDIF}
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
  ConnectPacket: array[0..255] of Byte;
  Idx: Integer;
  I: Integer;
  Res: Integer;
begin
  Result := False;
  ClearError;
  if FActive then
  begin
    FLastResult := 'Already active';
    FLastSuccess := True;
    Exit(True);
  end;
  
  try
    FSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
    if FSocket = TSocket(-1) then
    begin
      SetError('Could not create socket.');
      Exit;
    end;
    
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(FPort);
    
    if not ResolveHost(FHost, Addr.sin_addr) then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      SetError('Host resolution failed: ' + FHost);
      Exit;
    end;
    
    Res := fpConnect(FSocket, @Addr, SizeOf(Addr));
    if Res < 0 then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      SetError('Connection to host failed.');
      Exit;
    end;
    
    // Format MQTT Connect raw binary packet
    Idx := 0;
    ConnectPacket[Idx] := $10; Inc(Idx); // CONNECT
    ConnectPacket[Idx] := 12 + Length(FClientID); Inc(Idx); // Remaining Length
    
    // Protocol Name length (2 bytes)
    ConnectPacket[Idx] := 0; Inc(Idx);
    ConnectPacket[Idx] := 4; Inc(Idx);
    // Protocol Name: MQTT
    ConnectPacket[Idx] := Ord('M'); Inc(Idx);
    ConnectPacket[Idx] := Ord('Q'); Inc(Idx);
    ConnectPacket[Idx] := Ord('T'); Inc(Idx);
    ConnectPacket[Idx] := Ord('T'); Inc(Idx);
    
    ConnectPacket[Idx] := 4; Inc(Idx); // Protocol Level (MQTT v3.1.1)
    ConnectPacket[Idx] := $02; Inc(Idx); // Connect Flags (Clean Session)
    
    // Keep Alive (2 bytes)
    ConnectPacket[Idx] := FKeepAlive shr 8; Inc(Idx);
    ConnectPacket[Idx] := FKeepAlive and $FF; Inc(Idx);
    
    // Client ID Length (2 bytes)
    ConnectPacket[Idx] := Length(FClientID) shr 8; Inc(Idx);
    ConnectPacket[Idx] := Length(FClientID) and $FF; Inc(Idx);
    
    // Client ID bytes
    for I := 1 to Length(FClientID) do
    begin
      ConnectPacket[Idx] := Ord(FClientID[I]);
      Inc(Idx);
    end;
    
    // Send CONNECT packet
    Res := fpsend(FSocket, @ConnectPacket[0], Idx, 0);
    if Res <= 0 then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      SetError('Failed to send CONNECT packet.');
      Exit;
    end;
    
    FActive := True;
    
    // Start background receiver thread
    FThread := TAIMQTTReceiverThread.Create(Self, FSocket);
    FThread.Start;
    
    if Assigned(FOnConnected) then
      FOnConnected(Self);
      
    FLastResult := 'Connected to MQTT broker successfully';
    FLastSuccess := True;
    Result := True;
  except
    on E: Exception do
      SetError('MQTT Connect Broker Exception: ' + E.Message);
  end;
end;

procedure TAIMQTTClient.DisconnectBroker;
var
  DisconnectPacket: array[0..1] of Byte;
begin
  ClearError;
  try
    if not FActive then Exit;
    
    if FThread <> nil then
    begin
      FThread.Terminate;
      FThread := nil;
    end;
    
    if FSocket >= 0 then
    begin
      // Send DISCONNECT packet
      DisconnectPacket[0] := $E0;
      DisconnectPacket[1] := $00;
      fpsend(FSocket, @DisconnectPacket[0], 2, 0);
      
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
    end;
    
    FActive := False;
    if Assigned(FOnDisconnected) then
      FOnDisconnected(Self);
      
    FLastResult := 'Disconnected from MQTT broker';
    FLastSuccess := True;
  except
    on E: Exception do
      SetError('MQTT Disconnect Broker Exception: ' + E.Message);
  end;
end;

function TAIMQTTClient.Subscribe(const ATopic: string): Boolean;
var
  SubPacket: array[0..511] of Byte;
  Idx: Integer;
  I: Integer;
  Res: Integer;
begin
  Result := False;
  ClearError;
  if not FActive or (FSocket = TSocket(-1)) then
  begin
    SetError('MQTT client is not connected.');
    Exit;
  end;
  
  try
    Idx := 0;
    SubPacket[Idx] := $82; Inc(Idx); // SUBSCRIBE
    SubPacket[Idx] := 2 + 2 + Length(ATopic) + 1; Inc(Idx); // Length
    
    // Packet Identifier (fixed to 1 for simplicity)
    SubPacket[Idx] := 0; Inc(Idx);
    SubPacket[Idx] := 1; Inc(Idx);
    
    // Topic Length
    SubPacket[Idx] := Length(ATopic) shr 8; Inc(Idx);
    SubPacket[Idx] := Length(ATopic) and $FF; Inc(Idx);
    
    // Topic Name
    for I := 1 to Length(ATopic) do
    begin
      SubPacket[Idx] := Ord(ATopic[I]);
      Inc(Idx);
    end;
    
    SubPacket[Idx] := 0; Inc(Idx); // QoS level (0)
    
    Res := fpsend(FSocket, @SubPacket[0], Idx, 0);
    if Res > 0 then
    begin
      FLastResult := 'Subscribed to topic: ' + ATopic;
      FLastSuccess := True;
      Result := True;
    end
    else
      SetError('Failed to send SUBSCRIBE packet.');
  except
    on E: Exception do
      SetError('MQTT Subscribe Exception: ' + E.Message);
  end;
end;

// MQTT Publication
function TAIMQTTClient.Publish(const ATopic, APayload: string): Boolean;
var
  PubPacket: array[0..1024] of Byte;
  Idx: Integer;
  I: Integer;
  Res: Integer;
begin
  Result := False;
  ClearError;
  if not FActive or (FSocket = TSocket(-1)) then
  begin
    SetError('MQTT client is not connected.');
    Exit;
  end;
  
  try
    Idx := 0;
    PubPacket[Idx] := $30; Inc(Idx); // PUBLISH (QoS 0)
    PubPacket[Idx] := 2 + Length(ATopic) + Length(APayload); Inc(Idx); // Remaining Length
    
    // Topic Length
    PubPacket[Idx] := Length(ATopic) shr 8; Inc(Idx);
    PubPacket[Idx] := Length(ATopic) and $FF; Inc(Idx);
    
    // Topic
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
    
    Res := fpsend(FSocket, @PubPacket[0], Idx, 0);
    if Res > 0 then
    begin
      FLastResult := 'Published message to topic: ' + ATopic;
      FLastSuccess := True;
      Result := True;
    end
    else
      SetError('Failed to send PUBLISH packet.');
  except
    on E: Exception do
      SetError('MQTT Publish Exception: ' + E.Message);
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
  if Assigned(FOnDisconnected) then
    FOnDisconnected(Self);
end;

initialization
  {$I aimqtt_icon.lrs}

end.
