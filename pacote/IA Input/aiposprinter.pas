unit aiposprinter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, serial, sockets,
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
  TPrinterInterface = (piSerial, piEthernet);

  { TAIPOSPrinter }

  TAIPOSPrinter = class(TComponent)
  private
    FInterfaceType: TPrinterInterface;
    FDeviceName: string; // e.g., 'COM1' or '/dev/ttyUSB0' for Serial
    FHost: string;       // e.g., '192.168.1.100' for Ethernet
    FPort: Integer;      // default 9100 for raw socket
    FSerialBaud: Integer;
    FSerialHandle: TSerialHandle;
    FSocket: TSocket;
    FActive: Boolean;
    FLastError: string;
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function OpenConnection: Boolean;
    procedure CloseConnection;
    function SendRawBytes(const ABytes: array of Byte): Boolean;
    function PrintText(const AText: string): Boolean;
    function CutPaper: Boolean;
    function OpenDrawer: Boolean;
    function PrintBarcode(const ACode: string): Boolean;
  published
    property InterfaceType: TPrinterInterface read FInterfaceType write FInterfaceType default piSerial;
    property DeviceName: string read FDeviceName write FDeviceName;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9100;
    property SerialBaud: Integer read FSerialBaud write FSerialBaud default 9600;
    property Active: Boolean read FActive write SetActive default False;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Input', [TAIPOSPrinter]);
end;

{ TAIPOSPrinter }

constructor TAIPOSPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInterfaceType := piSerial;
  FDeviceName := 'COM1';
  FHost := '192.168.1.100';
  FPort := 9100;
  FSerialBaud := 9600;
  FSerialHandle := 0;
  FSocket := TSocket(-1);
  FActive := False;
  FLastError := '';
end;

destructor TAIPOSPrinter.Destroy;
begin
  CloseConnection;
  inherited Destroy;
end;

function TAIPOSPrinter.ResolveHost(const AHost: string; var AAddr): Boolean;
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

procedure TAIPOSPrinter.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    OpenConnection
  else
    CloseConnection;
end;

function TAIPOSPrinter.OpenConnection: Boolean;
var
  Addr: TInetSockAddr;
  Res: Integer;
begin
  Result := False;
  FLastError := '';
  
  if FInterfaceType = piSerial then
  begin
    FSerialHandle := SerOpen(FDeviceName);
    if FSerialHandle <> 0 then
    begin
      SerSetParams(FSerialHandle, FSerialBaud, 8, NoneParity, 1, []);
      FActive := True;
      Result := True;
    end
    else
      FLastError := 'Failed to open serial POS printer on ' + FDeviceName;
  end
  else
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
  end;
end;

procedure TAIPOSPrinter.CloseConnection;
begin
  if not FActive then Exit;
  
  if FInterfaceType = piSerial then
  begin
    if FSerialHandle <> 0 then
    begin
      SerClose(FSerialHandle);
      FSerialHandle := 0;
    end;
  end
  else
  begin
    if FSocket <> TSocket(-1) then
    begin
      sockets.CloseSocket(FSocket);
      FSocket := TSocket(-1);
    end;
  end;
  
  FActive := False;
end;

function TAIPOSPrinter.SendRawBytes(const ABytes: array of Byte): Boolean;
var
  Res: Integer;
begin
  Result := False;
  if not FActive then Exit;
  
  if FInterfaceType = piSerial then
  begin
    if FSerialHandle <> 0 then
      Result := SerWrite(FSerialHandle, ABytes[0], Length(ABytes)) = Length(ABytes);
  end
  else
  begin
    if FSocket <> TSocket(-1) then
    begin
      try
        Res := fpsend(FSocket, @ABytes[0], Length(ABytes), 0);
        Result := Res = Length(ABytes);
        if not Result then
          FLastError := 'Socket Write Error: did not write all bytes.';
      except
        on E: Exception do
          FLastError := 'Socket Write Error: ' + E.Message;
      end;
    end;
  end;
end;

function TAIPOSPrinter.PrintText(const AText: string): Boolean;
var
  Buffer: array of Byte;
  I: Integer;
begin
  Result := False;
  if Length(AText) = 0 then Exit;
  
  SetLength(Buffer, Length(AText));
  for I := 1 to Length(AText) do
    Buffer[I - 1] := Byte(AText[I]);
    
  Result := SendRawBytes(Buffer);
end;

function TAIPOSPrinter.CutPaper: Boolean;
var
  Cmd: array[0..3] of Byte;
begin
  // ESC/POS Cut paper command: GS V 66 0
  Cmd[0] := 29;
  Cmd[1] := 86;
  Cmd[2] := 66;
  Cmd[3] := 0;
  Result := SendRawBytes(Cmd);
end;

function TAIPOSPrinter.OpenDrawer: Boolean;
var
  Cmd: array[0..4] of Byte;
begin
  // ESC/POS Open cash drawer command: ESC p 0 25 250
  Cmd[0] := 27;
  Cmd[1] := 112;
  Cmd[2] := 0;
  Cmd[3] := 25;
  Cmd[4] := 250;
  Result := SendRawBytes(Cmd);
end;

function TAIPOSPrinter.PrintBarcode(const ACode: string): Boolean;
var
  Cmd: array of Byte;
  I: Integer;
begin
  if Length(ACode) = 0 then Exit(False);
  
  // ESC/POS Print Barcode command: GS k 4 (Code 39) [Length] [Data]
  SetLength(Cmd, 4 + Length(ACode) + 1);
  Cmd[0] := 29;
  Cmd[1] := 107;
  Cmd[2] := 4; // Code 39
  Cmd[3] := Length(ACode);
  
  for I := 1 to Length(ACode) do
    Cmd[3 + I] := Byte(ACode[I]);
    
  Cmd[3 + Length(ACode) + 1] := 0; // null terminator
  
  Result := SendRawBytes(Cmd);
end;

end.
