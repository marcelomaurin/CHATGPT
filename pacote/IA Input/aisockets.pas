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
  ;

type
  TSocketMode = (smClient, smServer);
  TSocketDataEvent = procedure(Sender: TObject; const AData: string; const AFromIP: string) of object;

  { TAISocketTCP }

  TAISocketTCP = class(TComponent)
  private
    FHost: string;
    FPort: Integer;
    FActive: Boolean;
    FMode: TSocketMode;
    FOnDataReceived: TSocketDataEvent;
    FSocket: TSocket;
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
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9001;
    property Active: Boolean read FActive write SetActive default False;
    property OnDataReceived: TSocketDataEvent read FOnDataReceived write FOnDataReceived;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Input', [TAISocketTCP, TAISocketUDP]);
end;

{ TAISocketTCP }

constructor TAISocketTCP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHost := '127.0.0.1';
  FPort := 9000;
  FActive := False;
  FMode := smClient;
  FSocket := TSocket(-1);
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
  
  FSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
  if FSocket = TSocket(-1) then
  begin
    FLastError := 'Could not create socket.';
    Exit;
  end;
  
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(FPort);
  
  if FMode = smClient then
  begin
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
  end;
end;

procedure TAISocketTCP.Disconnect;
begin
  if FSocket <> TSocket(-1) then
  begin
    sockets.CloseSocket(FSocket);
    FSocket := TSocket(-1);
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

end.
