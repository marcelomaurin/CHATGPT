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
  , LResources, imp_generico, imp_elgini9, imp_qr203, imp_elginl42dt;

type
  TPrinterInterface = (piSerial, piEthernet);
  TPrinterModel = (pmElginI9, pmQR203, pmElginL42DT);

  { TAIPOSPrinter }

  TAIPOSPrinter = class(TComponent)
  private
    FPrompt: string;
    FInterfaceType: TPrinterInterface;
    FPrinterModel: TPrinterModel;
    FDeviceName: string; // e.g., 'COM1' or '/dev/ttyUSB0' for Serial
    FHost: string;       // e.g., '192.168.1.100' for Ethernet
    FPort: Integer;      // default 9100 for raw socket
    FSerialBaud: Integer;
    FSerialHandle: TSerialHandle;
    FSocket: TSocket;
    FActive: Boolean;
    FLastError: string;
    FDriver: TIMP_GENERICO;
    
    procedure SetActive(AValue: Boolean);
    procedure SetPrinterModel(AValue: TPrinterModel);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
    procedure InitDriver;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function OpenConnection: Boolean;
    procedure CloseConnection;
    function SendRawBytes(const ABytes: array of Byte): Boolean;
    function SendRawString(const AStr: string): Boolean;
    
    function PrintText(const AText: string): Boolean;
    function PrintTextLine(const AText: string): Boolean;
    function SetBold(const ABold: Boolean): Boolean;
    function SetNormal: Boolean;
    function SetDoubleText: Boolean;
    function SetUnderline(const AUnderline: Boolean): Boolean;
    function AlignCenter: Boolean;
    function AlignLeft: Boolean;
    function AlignRight: Boolean;
    function CutPaper: Boolean;
    function OpenDrawer: Boolean;
    function PrintBarcode(const ACode: string; H: Byte = 80; R: Byte = 3; I: Byte = 2): Boolean;
    function PrintQRCode(const ACode: string): Boolean;
    function Beep: Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property InterfaceType: TPrinterInterface read FInterfaceType write FInterfaceType default piSerial;
    property PrinterModel: TPrinterModel read FPrinterModel write SetPrinterModel default pmElginI9;
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
  RegisterComponents('AI Communication', [TAIPOSPrinter]);
end;

{ TAIPOSPrinter }

constructor TAIPOSPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIPOSPrinter handles ESC/POS receipt printers via serial or ethernet sockets.';
  FInterfaceType := piSerial;
  FPrinterModel := pmElginI9;
  FDeviceName := 'COM1';
  FHost := '192.168.1.100';
  FPort := 9100;
  FSerialBaud := 9600;
  FSerialHandle := 0;
  FSocket := TSocket(-1);
  FActive := False;
  FLastError := '';
  FDriver := nil;
  InitDriver;
end;

destructor TAIPOSPrinter.Destroy;
begin
  CloseConnection;
  if Assigned(FDriver) then
    FDriver.Free;
  inherited Destroy;
end;

procedure TAIPOSPrinter.InitDriver;
begin
  if Assigned(FDriver) then
  begin
    FDriver.Free;
    FDriver := nil;
  end;
  case FPrinterModel of
    pmElginI9:      FDriver := TIMP_ELGINI9.Create;
    pmQR203:        FDriver := TIMP_QR203.Create;
    pmElginL42DT:   FDriver := TIMP_ELGINL42DT.Create;
  end;
end;

procedure TAIPOSPrinter.SetPrinterModel(AValue: TPrinterModel);
begin
  if FPrinterModel = AValue then Exit;
  FPrinterModel := AValue;
  InitDriver;
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
      if Assigned(FDriver) then
        SendRawString(FDriver.InitPrint);
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
    if Assigned(FDriver) then
      SendRawString(FDriver.InitPrint);
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
  if Length(ABytes) = 0 then Exit(True);
  
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

function TAIPOSPrinter.SendRawString(const AStr: string): Boolean;
var
  Buffer: array of Byte;
  I: Integer;
begin
  Result := False;
  if Length(AStr) = 0 then Exit(True);
  SetLength(Buffer, Length(AStr));
  for I := 1 to Length(AStr) do
    Buffer[I - 1] := Byte(AStr[I]);
  Result := SendRawBytes(Buffer);
end;

function TAIPOSPrinter.PrintText(const AText: string): Boolean;
begin
  Result := SendRawString(AText);
end;

function TAIPOSPrinter.PrintTextLine(const AText: string): Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.LineText(AText))
  else
    Result := SendRawString(AText + #10);
end;

function TAIPOSPrinter.SetBold(const ABold: Boolean): Boolean;
begin
  if Assigned(FDriver) then
  begin
    if ABold then
      Result := SendRawString(FDriver.Negrito)
    else
      Result := SendRawString(FDriver.Normal);
  end
  else
    Result := False;
end;

// Alias to match old API if needed
function TAIPOSPrinter.SetNormal: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.Normal)
  else
    Result := False;
end;

function TAIPOSPrinter.SetDoubleText: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.DoubleTexto)
  else
    Result := False;
end;

function TAIPOSPrinter.SetUnderline(const AUnderline: Boolean): Boolean;
begin
  if Assigned(FDriver) then
  begin
    if AUnderline then
      Result := SendRawString(FDriver.Sublinhado)
    else
      Result := SendRawString(FDriver.Normal);
  end
  else
    Result := False;
end;

function TAIPOSPrinter.AlignCenter: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.Centralizado)
  else
    Result := False;
end;

// AlignLeft / AlignRight support
function TAIPOSPrinter.AlignLeft: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.AlinhadoEsquerda)
  else
    Result := False;
end;

function TAIPOSPrinter.AlignRight: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.AlinhadoDireita)
  else
    Result := False;
end;

function TAIPOSPrinter.CutPaper: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.Guilhotina)
  else
    Result := False;
end;

// OpenDrawer support
function TAIPOSPrinter.OpenDrawer: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.AcionaGaveta)
  else
    Result := False;
end;

// PrintBarcode / PrintQRCode / Beep
function TAIPOSPrinter.PrintBarcode(const ACode: string; H: Byte = 80; R: Byte = 3; I: Byte = 2): Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.Barra1D(ACode, H, R, I))
  else
    Result := False;
end;

function TAIPOSPrinter.PrintQRCode(const ACode: string): Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.Barra2D(ACode))
  else
    Result := False;
end;

function TAIPOSPrinter.Beep: Boolean;
begin
  if Assigned(FDriver) then
    Result := SendRawString(FDriver.Beep)
  else
    Result := False;
end;

initialization
  {$I aiposprinter_icon.lrs}

end.
