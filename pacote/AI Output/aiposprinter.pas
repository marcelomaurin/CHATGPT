unit aiposprinter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources,
  aiprinter_types,
  aiprinter_bytebuilder,
  aiprinter_profile,
  aiprinter_transport,
  aiprinter_transport_tcp,
  aiprinter_transport_serial,
  aiprinter_transport_file,
  aiprinter_language_base,
  aiprinter_language_escpos,
  aiprinter_language_zpl,
  aiprinter_language_tspl,
  aiprinter_language_epl;

type
  // Legacy aliases for backward compatibility
  TPrinterInterface = (piSerial, piEthernet);
  TPrinterProtocol = (ppEscPos, ppNative, ppEpl, ppZpl, ppTspl) deprecated;

  { TAIPOSPrinter }

  TAIPOSPrinter = class(TComponent)
  private
    FPrompt: string;
    
    // Core parameters
    FPrinterModelName: string;
    FLanguage: TPrinterLanguage;
    FRenderMode: TPrinterRenderMode;
    FTransportKind: TPrinterTransportKind;
    FCodePage: TPrinterEncoding;
    
    // Connectivity
    FDeviceName: string; // e.g. COM1
    FHost: string;       // e.g. 192.168.1.100
    FPort: Integer;      // e.g. 9100
    FSerialBaud: Integer;
    FTimeoutMs: Integer;
    FActive: Boolean;
    FLastError: string;
    
    // Label settings
    FLabelWidthMM: Integer;
    FLabelHeightMM: Integer;
    FGapMM: Integer;
    FDensity: Integer;
    FSpeed: Integer;
    FDirection: Integer;
    
    // Internals
    FTransport: IAIPrinterTransport;
    FLanguageEngine: TAIPrinterLanguageBase;
    FJobBuilder: TAIByteBuilder;
    FPageLines: TStringList;
    FLastBytesSent: Integer;
    FLastCommandHex: string;
    
    // Compatibility backing fields
    FInterfaceType: TPrinterInterface;
    FPrinterModelLegacy: Integer; // pmElginI9, etc.
    FProtocolLegacy: TPrinterProtocol;

    procedure SetActive(AValue: Boolean);
    procedure SetPrinterModelName(const AValue: string);
    procedure SetLanguage(AValue: TPrinterLanguage);
    procedure SetCodePage(AValue: TPrinterEncoding);
    
    procedure InitLanguageEngine;
    procedure InitTransport;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    // Real printing job API
    function OpenConnection: Boolean;
    procedure CloseConnection;
    
    function BeginJob: Boolean;
    function EndJob: Boolean;
    function PrintJob: Boolean;
    function CancelJob: Boolean;
    
    function SendRawBytes(const ABytes: array of Byte): Boolean;
    function SendRawString(const AStr: string): Boolean;
    
    // Sequential text commands
    function PrintText(const AText: string): Boolean;
    function PrintTextLine(const AText: string): Boolean;
    function SetBold(const ABold: Boolean): Boolean;
    function SetNormal: Boolean;
    function SetDoubleText: Boolean;
    function SetUnderline(const AUnderline: Boolean): Boolean;
    function AlignCenter: Boolean;
    function AlignLeft: Boolean;
    function AlignRight: Boolean;
    
    // Actions
    function CutPaper: Boolean;
    function OpenDrawer: Boolean;
    function PrintBarcode(const ACode: string; H: Byte = 80; R: Byte = 3; I: Byte = 2): Boolean;
    function PrintQRCode(const ACode: string): Boolean;
    function Beep: Boolean;
    
    // Raw transmissions & previews
    function SendDocument(const ABytes: TBytes): Boolean;
    function PreviewDocument(const ABytes: TBytes): string;
    
    // Properties
    property ActiveTransport: IAIPrinterTransport read FTransport;
    property ActiveLanguageEngine: TAIPrinterLanguageBase read FLanguageEngine;
    property PageLines: TStringList read FPageLines;
  published
    property Prompt: string read FPrompt write FPrompt;
    
    // Modern properties
    property PrinterModelName: string read FPrinterModelName write SetPrinterModelName;
    property Language: TPrinterLanguage read FLanguage write SetLanguage default plEscPos;
    property RenderMode: TPrinterRenderMode read FRenderMode write FRenderMode default rmRawCommand;
    property TransportKind: TPrinterTransportKind read FTransportKind write FTransportKind default ptTcp9100;
    property CodePage: TPrinterEncoding read FCodePage write SetCodePage default peCP850;
    
    // Connectivity
    property DeviceName: string read FDeviceName write FDeviceName;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 9100;
    property SerialBaud: Integer read FSerialBaud write FSerialBaud default 9600;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 5000;
    property Active: Boolean read FActive write SetActive default False;
    property LastError: string read FLastError;
    property LastBytesSent: Integer read FLastBytesSent;
    property LastCommandHex: string read FLastCommandHex;
    
    // Label settings
    property LabelWidthMM: Integer read FLabelWidthMM write FLabelWidthMM default 100;
    property LabelHeightMM: Integer read FLabelHeightMM write FLabelHeightMM default 50;
    property GapMM: Integer read FGapMM write FGapMM default 2;
    property Density: Integer read FDensity write FDensity default 8;
    property Speed: Integer read FSpeed write FSpeed default 4;
    property Direction: Integer read FDirection write FDirection default 0;
    
    // Legacy properties for backwards compatibility
    property InterfaceType: TPrinterInterface read FInterfaceType write FInterfaceType default piSerial;
    property Protocol: TPrinterProtocol read FProtocolLegacy write FProtocolLegacy default ppEscPos; deprecated;
  end;

procedure Register;

implementation

uses Printers;

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIPOSPrinter]);
end;

{ TAIPOSPrinter }

constructor TAIPOSPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'TAIPOSPrinter handles ESC/POS, ZPL, TSPL, and EPL printer hardware and OS Native printing.';
  
  FPrinterModelName := 'Elgin i9 (80mm)';
  FLanguage := plEscPos;
  FRenderMode := rmRawCommand;
  FTransportKind := ptTcp9100;
  FCodePage := peCP850;
  
  FDeviceName := 'COM1';
  FHost := '192.168.1.100';
  FPort := 9100;
  FSerialBaud := 9600;
  FTimeoutMs := 5000;
  FActive := False;
  FLastError := '';
  
  FLabelWidthMM := 100;
  FLabelHeightMM := 50;
  FGapMM := 2;
  FDensity := 8;
  FSpeed := 4;
  FDirection := 0;
  
  FTransport := nil;
  FLanguageEngine := nil;
  FJobBuilder := TAIByteBuilder.Create;
  FPageLines := TStringList.Create;
  
  FLastBytesSent := 0;
  FLastCommandHex := '';
  
  InitLanguageEngine;
end;

destructor TAIPOSPrinter.Destroy;
begin
  CloseConnection;
  if Assigned(FLanguageEngine) then
    FLanguageEngine.Free;
  FJobBuilder.Free;
  FPageLines.Free;
  inherited Destroy;
end;

procedure TAIPOSPrinter.InitLanguageEngine;
begin
  if Assigned(FLanguageEngine) then
  begin
    FreeAndNil(FLanguageEngine);
  end;
  
  case FLanguage of
    plEscPos: FLanguageEngine := TAIEscPosLanguage.Create;
    plZpl:    FLanguageEngine := TAIZplLanguage.Create;
    plTspl:   FLanguageEngine := TAITsplLanguage.Create;
    plEpl:    FLanguageEngine := TAIEplLanguage.Create;
  end;
  
  if Assigned(FLanguageEngine) then
  begin
    FLanguageEngine.Encoding := FCodePage;
    if FLanguageEngine is TAIZplLanguage then
    begin
      // ZPL DPI is 203 by default, calculate width/height in pixels
      TAIZplLanguage(FLanguageEngine).LabelWidthPixels := Round(FLabelWidthMM * 8);
      TAIZplLanguage(FLanguageEngine).LabelHeightPixels := Round(FLabelHeightMM * 8);
    end
    else if FLanguageEngine is TAITsplLanguage then
    begin
      TAITsplLanguage(FLanguageEngine).LabelWidthMM := FLabelWidthMM;
      TAITsplLanguage(FLanguageEngine).LabelHeightMM := FLabelHeightMM;
      TAITsplLanguage(FLanguageEngine).GapMM := FGapMM;
      TAITsplLanguage(FLanguageEngine).Density := FDensity;
      TAITsplLanguage(FLanguageEngine).Speed := FSpeed;
      TAITsplLanguage(FLanguageEngine).Direction := FDirection;
    end;
  end;
end;

procedure TAIPOSPrinter.InitTransport;
begin
  FTransport := nil;
  if FRenderMode = rmNativeCanvas then Exit;
  
  case FTransportKind of
    ptSerial:  FTransport := TAIPrinterSerialTransport.Create(FDeviceName, FSerialBaud);
    ptTcp9100: FTransport := TAIPrinterTcpTransport.Create(FHost, FPort);
    ptFile:    FTransport := TAIPrinterFileTransport.Create(ConcatPaths([ExtractFilePath(ParamStr(0)), 'output', 'test_print.bin']));
  end;
  
  if Assigned(FTransport) then
    FTransport.SetTimeoutMs(FTimeoutMs);
end;

procedure TAIPOSPrinter.SetPrinterModelName(const AValue: string);
var
  Profile: TAIPrinterProfile;
begin
  if FPrinterModelName = AValue then Exit;
  FPrinterModelName := AValue;
  
  Profile := TAIPrinterProfile.GetProfile(FPrinterModelName);
  try
    // Auto-update capabilities
    FLabelWidthMM := Profile.PaperWidthMM;
    if plEscPos in Profile.SupportedLanguages then
      SetLanguage(plEscPos)
    else if plZpl in Profile.SupportedLanguages then
      SetLanguage(plZpl)
    else if plTspl in Profile.SupportedLanguages then
      SetLanguage(plTspl);
  finally
    Profile.Free;
  end;
end;

procedure TAIPOSPrinter.SetLanguage(AValue: TPrinterLanguage);
begin
  if FLanguage = AValue then Exit;
  FLanguage := AValue;
  InitLanguageEngine;
end;

procedure TAIPOSPrinter.SetCodePage(AValue: TPrinterEncoding);
begin
  if FCodePage = AValue then Exit;
  FCodePage := AValue;
  if Assigned(FLanguageEngine) then
    FLanguageEngine.Encoding := FCodePage;
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
begin
  Result := False;
  FLastError := '';
  
  if FRenderMode = rmNativeCanvas then
  begin
    FActive := True;
    Result := True;
    Exit;
  end;
  
  InitTransport;
  if not Assigned(FTransport) then
  begin
    FLastError := 'No transport configured.';
    Exit;
  end;
  
  Result := FTransport.Open;
  if Result then
    FActive := True;
end;

procedure TAIPOSPrinter.CloseConnection;
begin
  if not FActive then Exit;
  
  if Assigned(FTransport) then
    FTransport.Close;
    
  FActive := False;
end;

function TAIPOSPrinter.BeginJob: Boolean;
begin
  FJobBuilder.Clear;
  FPageLines.Clear;
  Result := True;
  
  if FRenderMode = rmRawCommand then
  begin
    if Assigned(FLanguageEngine) then
      FJobBuilder.AddBytes(FLanguageEngine.BeginLabel);
  end;
end;

function TAIPOSPrinter.EndJob: Boolean;
begin
  Result := True;
  if FRenderMode = rmRawCommand then
  begin
    if Assigned(FLanguageEngine) then
    begin
      FJobBuilder.AddBytes(FLanguageEngine.EndLabel);
    end;
  end;
end;

function TAIPOSPrinter.PrintJob: Boolean;
begin
  Result := False;
  if not FActive then
  begin
    FLastError := 'Printer not active/connected.';
    Exit;
  end;
  
  if FRenderMode = rmNativeCanvas then
  begin
    Result := CutPaper; // Native OS Spooling is triggered by CutPaper/Document print
    Exit;
  end;
  
  Result := SendDocument(FJobBuilder.ToBytes);
end;

function TAIPOSPrinter.CancelJob: Boolean;
begin
  FJobBuilder.Clear;
  FPageLines.Clear;
  Result := True;
end;

function TAIPOSPrinter.SendRawBytes(const ABytes: array of Byte): Boolean;
var
  T: TBytes;
  I: Integer;
begin
  SetLength(T, Length(ABytes));
  for I := 0 to Length(ABytes) - 1 do
    T[I] := ABytes[I];
  Result := SendDocument(T);
end;

function TAIPOSPrinter.SendRawString(const AStr: string): Boolean;
begin
  if not FActive then Exit(False);
  Result := SendDocument(TEncoding.UTF8.GetBytes(AStr));
end;

function TAIPOSPrinter.PrintText(const AText: string): Boolean;
var
  Bytes: TBytes;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
  begin
    FPageLines.Add(AText);
    Result := True;
  end
  else
  begin
    if Assigned(FLanguageEngine) then
    begin
      // Low-level sequential print adds raw encoded text to builder
      FJobBuilder.AddTextEncoded(AText, FCodePage);
      Result := True;
    end;
  end;
end;

function TAIPOSPrinter.PrintTextLine(const AText: string): Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
  begin
    FPageLines.Add(AText);
    Result := True;
  end
  else
  begin
    if Assigned(FLanguageEngine) then
    begin
      FJobBuilder.AddBytes(FLanguageEngine.TextLine(AText));
      Result := True;
    end;
  end;
end;

function TAIPOSPrinter.SetBold(const ABold: Boolean): Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Bold(ABold));
    Result := True;
  end;
end;

function TAIPOSPrinter.SetNormal: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Normal);
    Result := True;
  end;
end;

function TAIPOSPrinter.SetDoubleText: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.DoubleTexto);
    Result := True;
  end;
end;

function TAIPOSPrinter.SetUnderline(const AUnderline: Boolean): Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Underline(AUnderline));
    Result := True;
  end;
end;

function TAIPOSPrinter.AlignCenter: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Align(taCenter));
    Result := True;
  end;
end;

function TAIPOSPrinter.AlignLeft: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Align(taLeft));
    Result := True;
  end;
end;

function TAIPOSPrinter.AlignRight: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Align(taRight));
    Result := True;
  end;
end;

function TAIPOSPrinter.CutPaper: Boolean;
var
  I, Y: Integer;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
  begin
    Result := True;
    try
      if FPageLines.Count > 0 then
      begin
        Printer.BeginDoc;
        Printer.Canvas.Font.Name := 'Courier New';
        Printer.Canvas.Font.Size := 10;
        Y := 20;
        for I := 0 to FPageLines.Count - 1 do
        begin
          Printer.Canvas.TextOut(20, Y, FPageLines[I]);
          Y := Y + Printer.Canvas.TextHeight(FPageLines[I]) + 5;
        end;
        Printer.EndDoc;
        FPageLines.Clear;
      end;
    except
      on E: Exception do
      begin
        Result := False;
        FLastError := 'Native Print Error: ' + E.Message;
      end;
    end;
  end
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Cut(True));
    Result := True;
  end;
end;

function TAIPOSPrinter.OpenDrawer: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.OpenDrawer);
    Result := True;
  end;
end;

function TAIPOSPrinter.PrintBarcode(const ACode: string; H: Byte = 80; R: Byte = 3; I: Byte = 2): Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
  begin
    FPageLines.Add('[Barcode: ' + ACode + ']');
    Result := True;
  end
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Barcode1D(ACode, H, R, I, bsCode128));
    Result := True;
  end;
end;

function TAIPOSPrinter.PrintQRCode(const ACode: string): Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
  begin
    FPageLines.Add('[QR Code: ' + ACode + ']');
    Result := True;
  end
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.QRCode(ACode, 4));
    Result := True;
  end;
end;

function TAIPOSPrinter.Beep: Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Result := True
  else if Assigned(FLanguageEngine) then
  begin
    FJobBuilder.AddBytes(FLanguageEngine.Beep);
    Result := True;
  end;
end;

function TAIPOSPrinter.SendDocument(const ABytes: TBytes): Boolean;
begin
  Result := False;
  FLastError := '';
  FLastBytesSent := Length(ABytes);
  FLastCommandHex := BytesToHex(ABytes);
  
  if FLastBytesSent = 0 then Exit(True);
  
  if not FActive or not Assigned(FTransport) then
  begin
    FLastError := 'Transport connection not active.';
    Exit;
  end;
  
  Result := FTransport.WriteAll(ABytes);
  if not Result then
    FLastError := FTransport.LastError;
end;

function TAIPOSPrinter.PreviewDocument(const ABytes: TBytes): string;
var
  I: Integer;
begin
  if FLanguage = plEscPos then
    Result := BytesToHex(ABytes)
  else
  begin
    // Return textual representation for text-based languages
    SetLength(Result, Length(ABytes));
    if Length(ABytes) > 0 then
      Move(ABytes[0], Result[1], Length(ABytes));
  end;
end;

initialization
  {$I aiposprinter_icon.lrs}

end.
