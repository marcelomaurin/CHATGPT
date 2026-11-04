unit aisockets;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sockets,
  {$IFDEF WIN32}
  winsock2
  {$ELSE}
    {$IFDEF WIN64}
    winsock2
    {$ELSE}
    netdb, BaseUnix
    {$ENDIF}
  {$ENDIF}
  , LResources;

type
  TSocketMode = (smClient, smServer);
  TSocketDataEvent = procedure(Sender: TObject; const AData: string; const AFromIP: string) of object;

  { TAISocketTCP }

  TAISocketTCP = class(TComponent)
  private
    FPrompt: string;
    FHost: string;
    FPort: Integer;
    FActive: Boolean;
    FMode: TSocketMode;
    FOnDataReceived: TSocketDataEvent;
    FSocket: TSocket;
    FServerThread: TThread;
    FLastError: string;
    FConnectTimeoutMs: Integer;
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
    function ConnectWithTimeout(const AAddr: TInetSockAddr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Connect: Boolean;
    procedure Disconnect;
    function SendText(const AText: string): Boolean;
    function ReceiveText(out AText: string): Boolean;
    { Dados binários (modo cliente). SendBuffer envia tudo ou retorna False. }
    function SendBuffer(const ABuffer; ACount: Integer): Boolean;
    { Espera até ATimeoutMs por dados. Retorna >0 = bytes lidos, 0 = nada
      chegou no prazo, -1 = conexão fechada ou erro (Active vira False). }
    function ReceiveBuffer(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
    { True se houver dados (ou fechamento) para ler em até ATimeoutMs. }
    function WaitForData(ATimeoutMs: Integer): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9000;
    property Active: Boolean read FActive write SetActive default False;
    property Mode: TSocketMode read FMode write FMode default smClient;
    { Tempo máximo de Connect em modo cliente (0 = sem limite, padrão). }
    property ConnectTimeoutMs: Integer read FConnectTimeoutMs write FConnectTimeoutMs default 0;
    property OnDataReceived: TSocketDataEvent read FOnDataReceived write FOnDataReceived;
    property LastError: string read FLastError;
  end;

  { TAISocketUDP }

  TAISocketUDP = class(TComponent)
  private
    FPrompt: string;
    FHost: string;
    FPort: Integer;
    FActive: Boolean;
    FOnDataReceived: TSocketDataEvent;
    FSocket: TSocket;
    FLastError: string;
    FLocalPort: Integer;
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function OpenSocket: Boolean;
    procedure CloseSocket;
    function SendText(const AText: string): Boolean;
    { Envia dados binários para Host:Port. }
    function SendBuffer(const ABuffer; ACount: Integer): Boolean;
    function ReceiveText(out AText: string; out AFromIP: string): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9001;
    { Porta local do OpenSocket: -1 (padrão) = a mesma de Port;
      0 = qualquer porta livre (para quem só envia, como clientes de drone). }
    property LocalPort: Integer read FLocalPort write FLocalPort default -1;
    property Active: Boolean read FActive write SetActive default False;
    property OnDataReceived: TSocketDataEvent read FOnDataReceived write FOnDataReceived;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

{ ---------- auxiliares de socket (Windows e Unix) ---------- }

function SocketWait(ASocket: TSocket; ATimeoutMs: Integer; AForWrite: Boolean): Boolean;
var
  FDS: TFDSet;
  TV: TTimeVal;
begin
  if ATimeoutMs < 0 then
    ATimeoutMs := 0;
  TV.tv_sec := ATimeoutMs div 1000;
  TV.tv_usec := (ATimeoutMs mod 1000) * 1000;
  {$IF DEFINED(WIN32) OR DEFINED(WIN64)}
  FD_ZERO(FDS);
  FD_SET(ASocket, FDS);
  if AForWrite then
    Result := select(0, nil, @FDS, nil, @TV) > 0
  else
    Result := select(0, @FDS, nil, nil, @TV) > 0;
  {$ELSE}
  fpFD_ZERO(FDS);
  fpFD_SET(ASocket, FDS);
  if AForWrite then
    Result := fpSelect(ASocket + 1, nil, @FDS, nil, @TV) > 0
  else
    Result := fpSelect(ASocket + 1, @FDS, nil, nil, @TV) > 0;
  {$ENDIF}
end;

procedure SocketSetBlocking(ASocket: TSocket; ABlocking: Boolean);
{$IF DEFINED(WIN32) OR DEFINED(WIN64)}
var
  Mode: u_long;
begin
  if ABlocking then Mode := 0 else Mode := 1;
  ioctlsocket(ASocket, LongInt(FIONBIO), @Mode);
end;
{$ELSE}
var
  Flags: cint;
begin
  Flags := fpfcntl(ASocket, F_GETFL);
  if ABlocking then
    fpfcntl(ASocket, F_SETFL, Flags and not O_NONBLOCK)
  else
    fpfcntl(ASocket, F_SETFL, Flags or O_NONBLOCK);
end;
{$ENDIF}

type
  { TTCPServerThread }

  TTCPServerThread = class(TThread)
  private
    FPort: Integer;
    FOnDataReceived: TSocketDataEvent;
    FOwner: TComponent;
    ReceivedData: string;
    ReceivedFrom: string;
    procedure DoDataReceived;
  protected
    procedure Execute; override;
  public
    FListenSocket: TSocket;
    constructor Create(AOwner: TComponent; APort: Integer; AEvent: TSocketDataEvent);
  end;

{ TTCPServerThread }

constructor TTCPServerThread.Create(AOwner: TComponent; APort: Integer; AEvent: TSocketDataEvent);
begin
  inherited Create(True);
  FOwner := AOwner;
  FPort := APort;
  FOnDataReceived := AEvent;
  FListenSocket := TSocket(-1);
  FreeOnTerminate := False;
end;

procedure TTCPServerThread.DoDataReceived;
begin
  if Assigned(FOnDataReceived) then
    FOnDataReceived(FOwner, ReceivedData, ReceivedFrom);
end;

procedure TTCPServerThread.Execute;
var
  ClientSocket: TSocket;
  Addr, ClientAddr: TInetSockAddr;
  AddrLen: TSockLen;
  Buffer: array[0..1023] of Char;
  BytesRead: Integer;
  OptVal: Integer;
begin
  FListenSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
  if FListenSocket = TSocket(-1) then Exit;
  
  OptVal := 1;
  fpsetsockopt(FListenSocket, SOL_SOCKET, SO_REUSEADDR, @OptVal, SizeOf(OptVal));
  
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(FPort);
  Addr.sin_addr.s_addr := INADDR_ANY;
  
  if fpBind(FListenSocket, @Addr, SizeOf(Addr)) < 0 then
  begin
    sockets.CloseSocket(FListenSocket);
    FListenSocket := TSocket(-1);
    Exit;
  end;
  
  if fpListen(FListenSocket, 5) < 0 then
  begin
    sockets.CloseSocket(FListenSocket);
    FListenSocket := TSocket(-1);
    Exit;
  end;
  
  while not Terminated do
  begin
    AddrLen := SizeOf(ClientAddr);
    ClientSocket := fpAccept(FListenSocket, @ClientAddr, @AddrLen);
    if ClientSocket <> TSocket(-1) then
    begin
      while not Terminated do
      begin
        FillChar(Buffer, SizeOf(Buffer), 0);
        BytesRead := fprecv(ClientSocket, @Buffer[0], SizeOf(Buffer) - 1, 0);
        if BytesRead > 0 then
        begin
          ReceivedData := StrPas(Buffer);
          ReceivedFrom := NetAddrToStr(ClientAddr.sin_addr);
          Synchronize(@DoDataReceived);
        end
        else
          Break;
      end;
      sockets.CloseSocket(ClientSocket);
    end;
    Sleep(10);
  end;
  
  if FListenSocket <> TSocket(-1) then
  begin
    sockets.CloseSocket(FListenSocket);
    FListenSocket := TSocket(-1);
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Communication', [TAISocketTCP, TAISocketUDP]);
end;

{ TAISocketTCP }

constructor TAISocketTCP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAISocketTCP manages standard TCP connections. Properties: Host: string (target IP/domain), Port: Integer, Mode: TSocketMode (smClient, smServer), Active: Boolean (triggers connect/disconnect), OnDataReceived: TSocketDataEvent. Methods: Connect, Disconnect, SendText(const AText: string): Boolean, ReceiveText(out AText: string): Boolean, SendBuffer(const ABuffer; ACount): Boolean, ReceiveBuffer(var ABuffer; ACount, ATimeoutMs): Integer (bytes, 0 = timeout, -1 = closed), WaitForData(ATimeoutMs): Boolean. ConnectTimeoutMs limits Connect. AI Agent: Use this for persistent bidirectional stream communication.';
  FHost := '127.0.0.1';
  FPort := 9000;
  FActive := False;
  FMode := smClient;
  FSocket := TSocket(-1);
  FServerThread := nil;
  FLastError := '';
end;

destructor TAISocketTCP.Destroy;
begin
  Disconnect;
  inherited Destroy;
end;

function TAISocketTCP.ResolveHost(const AHost: string; var AAddr): Boolean;
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

procedure TAISocketTCP.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

function TAISocketTCP.Connect: Boolean;
var
  Addr: TInetSockAddr;
  Res: Integer;
begin
  Result := False;
  FLastError := '';
  
  if FMode = smClient then
  begin
    FSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
    if FSocket = TSocket(-1) then
    begin
      FLastError := 'Could not create socket.';
      Exit;
    end;
    
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(FPort);
    if not ResolveHost(FHost, Addr.sin_addr) then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      FLastError := 'Host resolution failed: ' + FHost;
      Exit;
    end;
    
    if FConnectTimeoutMs > 0 then
    begin
      if not ConnectWithTimeout(Addr) then
      begin
        sockets.CloseSocket(FSocket);
        FSocket := TSocket(-1);
        if FLastError = '' then
          FLastError := 'Connection to host failed.';
        Exit;
      end;
    end
    else
    begin
      Res := fpConnect(FSocket, @Addr, SizeOf(Addr));
      if Res < 0 then
      begin
        sockets.CloseSocket(FSocket);
        FSocket := TSocket(-1);
        FLastError := 'Connection to host failed.';
        Exit;
      end;
    end;
    
    FActive := True;
    Result := True;
  end
  else
  begin
    if Assigned(FServerThread) then Exit(True);
    FServerThread := TTCPServerThread.Create(Self, FPort, FOnDataReceived);
    FServerThread.Start;
    FActive := True;
    Result := True;
  end;
end;

procedure TAISocketTCP.Disconnect;
begin
  if FMode = smClient then
  begin
    if FSocket <> TSocket(-1) then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
    end;
  end
  else
  begin
    if Assigned(FServerThread) then
    begin
      FServerThread.Terminate;
      if TTCPServerThread(FServerThread).FListenSocket <> TSocket(-1) then
      begin
        sockets.CloseSocket(TTCPServerThread(FServerThread).FListenSocket);
        TTCPServerThread(FServerThread).FListenSocket := TSocket(-1);
      end;
      FServerThread.Free;
      FServerThread := nil;
    end;
  end;
  FActive := False;
end;

function TAISocketTCP.ConnectWithTimeout(const AAddr: TInetSockAddr): Boolean;
var
  Err: LongInt;
  ErrLen: TSockLen;
begin
  Result := False;
  SocketSetBlocking(FSocket, False);
  try
    if fpConnect(FSocket, @AAddr, SizeOf(AAddr)) = 0 then
      Exit(True);
    if not SocketWait(FSocket, FConnectTimeoutMs, True) then
    begin
      FLastError := Format('Connection timeout (%d ms).', [FConnectTimeoutMs]);
      Exit;
    end;
    Err := 0;
    ErrLen := SizeOf(Err);
    if (fpGetSockOpt(FSocket, SOL_SOCKET, SO_ERROR, @Err, @ErrLen) <> 0) or (Err <> 0) then
    begin
      FLastError := 'Connection to host failed.';
      Exit;
    end;
    Result := True;
  finally
    SocketSetBlocking(FSocket, True);
  end;
end;

function TAISocketTCP.SendBuffer(const ABuffer; ACount: Integer): Boolean;
var
  Sent, Res: Integer;
  P: PByte;
begin
  Result := False;
  if not FActive or (FSocket = TSocket(-1)) then Exit;
  P := @ABuffer;
  Sent := 0;
  while Sent < ACount do
  begin
    Res := fpsend(FSocket, @P[Sent], ACount - Sent, 0);
    if Res <= 0 then
    begin
      FLastError := 'TCP send failed.';
      Exit;
    end;
    Inc(Sent, Res);
  end;
  Result := True;
end;

function TAISocketTCP.WaitForData(ATimeoutMs: Integer): Boolean;
begin
  Result := FActive and (FSocket <> TSocket(-1)) and SocketWait(FSocket, ATimeoutMs, False);
end;

function TAISocketTCP.ReceiveBuffer(var ABuffer; ACount, ATimeoutMs: Integer): Integer;
begin
  Result := -1;
  if not FActive or (FSocket = TSocket(-1)) or (ACount <= 0) then Exit;
  if not SocketWait(FSocket, ATimeoutMs, False) then
    Exit(0);
  Result := fprecv(FSocket, @ABuffer, ACount, 0);
  if Result <= 0 then
  begin
    FLastError := 'TCP connection closed.';
    Disconnect;
    Result := -1;
  end;
end;

function TAISocketTCP.SendText(const AText: string): Boolean;
begin
  Result := (AText <> '') and SendBuffer(AText[1], Length(AText));
end;

function TAISocketTCP.ReceiveText(out AText: string): Boolean;
var
  Buffer: array[0..1023] of Char;
  BytesRead: Integer;
begin
  Result := False;
  AText := '';
  if not FActive or (FSocket = TSocket(-1)) then Exit;
  
  FillChar(Buffer, SizeOf(Buffer), 0);
  BytesRead := fprecv(FSocket, @Buffer[0], SizeOf(Buffer) - 1, 0);
  if BytesRead > 0 then
  begin
    AText := StrPas(Buffer);
    Result := True;
    if Assigned(FOnDataReceived) then
      FOnDataReceived(Self, AText, FHost);
  end;
end;

{ TAISocketUDP }

constructor TAISocketUDP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAISocketUDP handles lightweight connectionless UDP communication. Properties: Host: string (target IP/domain), Port: Integer, Active: Boolean, OnDataReceived: TSocketDataEvent. Methods: OpenSocket, CloseSocket, SendText(const AText: string): Boolean, SendBuffer(const ABuffer; ACount): Boolean, ReceiveText(out AText: string; out AFromIP: string): Boolean. LocalPort: -1 binds to Port, 0 binds to any free port. AI Agent: Use this for quick, non-guaranteed broadcast signals or real-time telemetry.';
  FHost := '127.0.0.1';
  FPort := 9001;
  FLocalPort := -1;
  FActive := False;
  FSocket := TSocket(-1);
  FLastError := '';
end;

destructor TAISocketUDP.Destroy;
begin
  CloseSocket;
  inherited Destroy;
end;

function TAISocketUDP.ResolveHost(const AHost: string; var AAddr): Boolean;
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

procedure TAISocketUDP.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    OpenSocket
  else
    CloseSocket;
end;

function TAISocketUDP.OpenSocket: Boolean;
var
  Addr: TInetSockAddr;
begin
  Result := False;
  FLastError := '';
  
  FSocket := fpSocket(AF_INET, SOCK_DGRAM, 0);
  if FSocket = TSocket(-1) then
  begin
    FLastError := 'UDP Socket creation failed.';
    Exit;
  end;
  
  Addr.sin_family := AF_INET;
  if FLocalPort >= 0 then
    Addr.sin_port := htons(FLocalPort)
  else
    Addr.sin_port := htons(FPort);
  Addr.sin_addr.s_addr := htonl(INADDR_ANY);
  
  if fpBind(FSocket, @Addr, sizeof(Addr)) <> 0 then
  begin
    FLastError := 'UDP Bind failed on port ' + IntToStr(ntohs(Addr.sin_port));
    CloseSocket;
    Exit;
  end;
  
  FActive := True;
  Result := True;
end;

procedure TAISocketUDP.CloseSocket;
begin
  if FSocket <> TSocket(-1) then
  begin
    sockets.CloseSocket(FSocket);
    FSocket := TSocket(-1);
  end;
  FActive := False;
end;

// Removed FHost check - lets connect directly
function TAISocketUDP.SendText(const AText: string): Boolean;
begin
  Result := (AText <> '') and SendBuffer(AText[1], Length(AText));
end;

function TAISocketUDP.SendBuffer(const ABuffer; ACount: Integer): Boolean;
var
  Addr: TInetSockAddr;
begin
  Result := False;
  if not FActive or (FSocket = TSocket(-1)) then Exit;
  
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(FPort);
  if not ResolveHost(FHost, Addr.sin_addr) then
  begin
    FLastError := 'UDP Host resolution failed: ' + FHost;
    Exit;
  end;
  
  if fpSendTo(FSocket, @ABuffer, ACount, 0, @Addr, sizeof(Addr)) = ACount then
    Result := True
  else
    FLastError := 'UDP Send failed.';
end;

function TAISocketUDP.ReceiveText(out AText: string; out AFromIP: string): Boolean;
var
  Buffer: array[0..1023] of Char;
  Addr: TInetSockAddr;
  AddrLen: TSockLen;
  BytesRead: Integer;
begin
  Result := False;
  AText := '';
  AFromIP := '';
  if not FActive or (FSocket = TSocket(-1)) then Exit;
  
  AddrLen := sizeof(Addr);
  FillChar(Buffer, SizeOf(Buffer), 0);
  
  BytesRead := fpRecvFrom(FSocket, @Buffer, SizeOf(Buffer) - 1, 0, @Addr, @AddrLen);
  if BytesRead > 0 then
  begin
    AText := StrPas(Buffer);
    AFromIP := NetAddrToStr(Addr.sin_addr);
    Result := True;
    
    if Assigned(FOnDataReceived) then
      FOnDataReceived(Self, AText, AFromIP);
  end;
end;

initialization
  {$I aisockets_icon.lrs}

end.
