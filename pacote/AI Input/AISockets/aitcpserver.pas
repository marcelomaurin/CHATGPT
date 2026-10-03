unit aitcpserver;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Winsock2;
type
  TAIStreamEvent = procedure(Sender: TObject; const Data: string) of object;
  { Windows TCP byte-stream server. Call Poll on the owning thread.
    One active client; bounded output queue; no LCL or firmware dependencies. }
  TAITCPServer = class(TComponent)
  private
    FListen, FClient: TSocket;
    FStarted: Boolean;
    FOutput, FLastError: string;
    FOnData: TAIStreamEvent;
    FOnConnect, FOnDisconnect: TNotifyEvent;
    procedure DropClient;
    procedure Flush;
    function GetActive: Boolean;
    function GetConnected: Boolean;
    procedure Fail(const Operation: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Start(const BindIP: string; Port: Integer): Boolean;
    procedure Stop;
    procedure Poll;
    function Send(const Data: string): Boolean;
    property Active: Boolean read GetActive;
    property Connected: Boolean read GetConnected;
    property LastError: string read FLastError;
    property OnData: TAIStreamEvent read FOnData write FOnData;
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect;
    property OnDisconnect: TNotifyEvent read FOnDisconnect write FOnDisconnect;
  end;
implementation
constructor TAITCPServer.Create(AOwner: TComponent);
var W: TWSAData;
begin
  inherited Create(AOwner);
  FListen:=INVALID_SOCKET; FClient:=INVALID_SOCKET;
  FStarted:=WSAStartup($0202,W)=0;
end;
destructor TAITCPServer.Destroy;
begin
  FOnDisconnect:=nil; Stop;
  if FStarted then WSACleanup;
  inherited Destroy;
end;
function TAITCPServer.GetActive: Boolean;
begin Result:=FListen<>INVALID_SOCKET; end;
function TAITCPServer.GetConnected: Boolean;
begin Result:=FClient<>INVALID_SOCKET; end;
procedure TAITCPServer.Fail(const Operation: string);
begin FLastError:=Operation+' (Winsock '+IntToStr(WSAGetLastError)+')'; end;
function TAITCPServer.Start(const BindIP: string; Port: Integer): Boolean;
var A: TSockAddrIn; Mode: u_long;
begin
  Stop; FLastError:=''; Result:=False;
  if not FStarted then begin FLastError:='Winsock unavailable'; Exit; end;
  if (Port<1) or (Port>65535) then begin FLastError:='Port must be 1..65535'; Exit; end;
  FillChar(A,SizeOf(A),0); A.sin_family:=AF_INET;
  A.sin_port:=htons(Port); A.sin_addr.s_addr:=inet_addr(PChar(BindIP));
  if A.sin_addr.s_addr=INADDR_NONE then begin FLastError:='Invalid IPv4 address'; Exit; end;
  FListen:=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if FListen=INVALID_SOCKET then begin Fail('socket'); Exit; end;
  Mode:=1;
  if (bind(FListen,A,SizeOf(A))=SOCKET_ERROR) or
     (listen(FListen,4)=SOCKET_ERROR) or
     (ioctlsocket(FListen,LongInt(FIONBIO),Mode)=SOCKET_ERROR) then begin
    Fail('listen'); Stop; Exit;
  end;
  Result:=True;
end;
procedure TAITCPServer.DropClient;
begin
  if Connected then begin
    closesocket(FClient); FClient:=INVALID_SOCKET; FOutput:='';
    if Assigned(FOnDisconnect) then FOnDisconnect(Self);
  end;
end;
procedure TAITCPServer.Stop;
begin
  DropClient;
  if Active then closesocket(FListen);
  FListen:=INVALID_SOCKET;
end;
procedure TAITCPServer.Flush;
var N: Integer;
begin
  if not Connected or (FOutput='') then Exit;
  N:=Winsock2.send(FClient,FOutput[1],Length(FOutput),0);
  if N>0 then Delete(FOutput,1,N)
  else if (N=0) or (WSAGetLastError<>WSAEWOULDBLOCK) then begin
    Fail('send'); DropClient;
  end;
end;
function TAITCPServer.Send(const Data: string): Boolean;
begin
  Result:=False;
  if not Connected then Exit;
  if Length(FOutput)+Length(Data)>1048576 then begin
    FLastError:='Client output queue exceeded 1 MB'; DropClient; Exit;
  end;
  FOutput:=FOutput+Data; Flush; Result:=Connected;
end;
procedure TAITCPServer.Poll;
var C: TSocket; Mode: u_long; B: array[0..4095] of Char; N,I: Integer; S: string;
begin
  if not Active then Exit;
  C:=accept(FListen,nil,nil);
  if C<>INVALID_SOCKET then begin
    if Connected then closesocket(C)
    else begin
      Mode:=1;
      if ioctlsocket(C,LongInt(FIONBIO),Mode)=SOCKET_ERROR then closesocket(C)
      else begin FClient:=C; FOutput:=''; if Assigned(FOnConnect) then FOnConnect(Self); end;
    end;
  end;
  Flush;
  for I:=1 to 8 do begin
    if not Connected then Break;
    N:=recv(FClient,B,SizeOf(B),0);
    if N>0 then begin
      SetString(S,PChar(@B[0]),N);
      if Assigned(FOnData) then FOnData(Self,S);
    end else begin
      if N=0 then DropClient
      else if WSAGetLastError<>WSAEWOULDBLOCK then begin Fail('recv'); DropClient; end;
      Break;
    end;
  end;
  Flush;
end;
end.

