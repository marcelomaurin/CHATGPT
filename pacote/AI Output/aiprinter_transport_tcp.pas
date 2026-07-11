unit aiprinter_transport_tcp;

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
  , aiprinter_transport;

type
  { TAIPrinterTcpTransport }

  TAIPrinterTcpTransport = class(TInterfacedObject, IAIPrinterTransport)
  private
    FHost: string;
    FPort: Integer;
    FTimeoutMs: Integer;
    FSocket: TSocket;
    FLastError: string;
    FIsOpen: Boolean;
    
    function ResolveHost(const AHost: string; var AAddr): Boolean;
  public
    constructor Create(const AHost: string; APort: Integer);
    destructor Destroy; override;
    
    function Open: Boolean;
    procedure Close;
    function WriteAll(const ABytes: TBytes): Boolean;
    function IsOpen: Boolean;
    function LastError: string;
    procedure SetTimeoutMs(AValue: Integer);
    function GetTimeoutMs: Integer;
  end;

implementation

{ TAIPrinterTcpTransport }

constructor TAIPrinterTcpTransport.Create(const AHost: string; APort: Integer);
begin
  inherited Create;
  FHost := AHost;
  FPort := APort;
  FTimeoutMs := 5000;
  FSocket := TSocket(-1);
  FLastError := '';
  FIsOpen := False;
end;

destructor TAIPrinterTcpTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIPrinterTcpTransport.ResolveHost(const AHost: string; var AAddr): Boolean;
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

function TAIPrinterTcpTransport.Open: Boolean;
var
  Addr: TInetSockAddr;
  Res: Integer;
begin
  Result := False;
  FLastError := '';
  Close;
  
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
  
  FIsOpen := True;
  Result := True;
end;

procedure TAIPrinterTcpTransport.Close;
begin
  if FSocket <> TSocket(-1) then
  begin
    sockets.CloseSocket(FSocket);
    FSocket := TSocket(-1);
  end;
  FIsOpen := False;
end;

function TAIPrinterTcpTransport.WriteAll(const ABytes: TBytes): Boolean;
var
  TotalSent: Integer;
  Sent: Integer;
  Len: Integer;
begin
  Result := False;
  FLastError := '';
  if not FIsOpen or (FSocket = TSocket(-1)) then
  begin
    FLastError := 'Socket not open.';
    Exit;
  end;
  
  Len := Length(ABytes);
  if Len = 0 then Exit(True);
  
  TotalSent := 0;
  while TotalSent < Len do
  begin
    try
      Sent := fpsend(FSocket, @ABytes[TotalSent], Len - TotalSent, 0);
      if Sent <= 0 then
      begin
        FLastError := 'Socket write failed or disconnected.';
        Exit;
      end;
      Inc(TotalSent, Sent);
    except
      on E: Exception do
      begin
        FLastError := 'Socket send exception: ' + E.Message;
        Exit;
      end;
    end;
  end;
  Result := True;
end;

function TAIPrinterTcpTransport.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

function TAIPrinterTcpTransport.LastError: string;
begin
  Result := FLastError;
end;

procedure TAIPrinterTcpTransport.SetTimeoutMs(AValue: Integer);
begin
  FTimeoutMs := AValue;
end;

function TAIPrinterTcpTransport.GetTimeoutMs: Integer;
begin
  Result := FTimeoutMs;
end;

end.
