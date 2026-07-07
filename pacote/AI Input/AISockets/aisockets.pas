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
    netdb
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
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Connect: Boolean;
    procedure Disconnect;
    function SendText(const AText: string): Boolean;
    function ReceiveText(out AText: string): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9000;
    property Active: Boolean read FActive write SetActive default False;
    property Mode: TSocketMode read FMode write FMode default smClient;
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
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function OpenSocket: Boolean;
    procedure CloseSocket;
    function SendText(const AText: string): Boolean;
    function ReceiveText(out AText: string; out AFromIP: string): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9001;
    property Active: Boolean read FActive write SetActive default False;
    property OnDataReceived: TSocketDataEvent read FOnDataReceived write FOnDataReceived;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

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
  FPrompt := 'Component TAISocketTCP manages standard TCP connections. Properties: Host: string (target IP/domain), Port: Integer, Mode: TSocketMode (smClient, smServer), Active: Boolean (triggers connect/disconnect), OnDataReceived: TSocketDataEvent. Methods: Connect, Disconnect, SendText(const AText: string): Boolean, ReceiveText(out AText: string): Boolean. AI Agent: Use this for persistent bidirectional stream communication.';
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
    
    Res := fpConnect(FSocket, @Addr, SizeOf(Addr));
    if Res < 0 then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
      FLastError := 'Connection to host failed.';
      Exit;
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

function TAISocketTCP.SendText(const AText: string): Boolean;
var
  Res: Integer;
begin
  Result := False;
  if not FActive or (FSocket = TSocket(-1)) then Exit;
  
  Res := fpsend(FSocket, Pointer(AText), Length(AText), 0);
  if Res > 0 then
    Result := True
  else
    FLastError := 'TCP send failed.';
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
  FPrompt := 'Component TAISocketUDP handles lightweight connectionless UDP communication. Properties: Host: string (target IP/domain), Port: Integer, Active: Boolean, OnDataReceived: TSocketDataEvent. Methods: OpenSocket, CloseSocket, SendText(const AText: string): Boolean, ReceiveText(out AText: string; out AFromIP: string): Boolean. AI Agent: Use this for quick, non-guaranteed broadcast signals or real-time telemetry.';
  FHost := '127.0.0.1';
  FPort := 9001;
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
  Addr.sin_port := htons(FPort);
  Addr.sin_addr.s_addr := htonl(INADDR_ANY);
  
  if fpBind(FSocket, @Addr, sizeof(Addr)) <> 0 then
  begin
    FLastError := 'UDP Bind failed on port ' + IntToStr(FPort);
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
  
  if fpSendTo(FSocket, Pointer(AText), Length(AText), 0, @Addr, sizeof(Addr)) = Length(AText) then
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
