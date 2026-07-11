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
  aiprinter_transport_spooler,
  aiprinter_language_base,
  aiprinter_language_escpos,
  aiprinter_language_zpl,
  aiprinter_language_tspl,
  aiprinter_language_epl;

type


  { TAIPOSPrinter }

  TAIPOSPrinter = class(TComponent)
  private
    FPrompt: string;
    
    // Core parameters
    FPrinterModelName: string;
    FPrinterModel: TAIPosModel;
    FLanguage: TPrinterLanguage;
    FRenderMode: TPrinterRenderMode;
    FTransportKind: TPrinterTransportKind;
    FCodePage: TPrinterEncoding;
    FRemoveAccents: Boolean;
    
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
    FLabelPrinted: Boolean;
    FProfile: TAIPrinterProfile;
    


    procedure SetActive(AValue: Boolean);
    procedure SetPrinterModelName(const AValue: string);
    procedure SetPrinterModel(AValue: TAIPosModel);
    procedure SetLanguage(AValue: TPrinterLanguage);
    procedure SetCodePage(AValue: TPrinterEncoding);
    function GetPrinterModel: TAIPosModel;
    function HasCapability(C: Integer): Boolean;
    
    procedure InitLanguageEngine;
    procedure InitTransport;
    function IsLabelLanguage: Boolean;
    
    function GetColumns: Integer;
    function GetDpi: Integer;
    function GetSupportsCut: Boolean;
    function GetSupportsDrawer: Boolean;
    function GetSupportsBeep: Boolean;
    function GetSupportsLabel: Boolean;
    function GetSupportsReceipt: Boolean;
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
    function PrintLabel(ACopies: Integer = 1): Boolean;
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
    
    property Columns: Integer read GetColumns;
    property Dpi: Integer read GetDpi;
    property SupportsCut: Boolean read GetSupportsCut;
    property SupportsDrawer: Boolean read GetSupportsDrawer;
    property SupportsBeep: Boolean read GetSupportsBeep;
    property SupportsLabel: Boolean read GetSupportsLabel;
    property SupportsReceipt: Boolean read GetSupportsReceipt;
  published
    property Prompt: string read FPrompt write FPrompt;
    
    // Modern properties
    property PrinterModelName: string read FPrinterModelName write SetPrinterModelName;
    property PrinterModel: TAIPosModel read GetPrinterModel write SetPrinterModel;
    property Language: TPrinterLanguage read FLanguage write SetLanguage default plEscPos;
    property RenderMode: TPrinterRenderMode read FRenderMode write FRenderMode default rmRawCommand;
    property TransportKind: TPrinterTransportKind read FTransportKind write FTransportKind default ptTcp9100;
    property CodePage: TPrinterEncoding read FCodePage write SetCodePage default peCP850;
    property RemoveAccents: Boolean read FRemoveAccents write FRemoveAccents default False;
    
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
    

  end;

procedure Register;

implementation

uses Printers;

procedure Register;
begin
  RegisterComponents('AI Output', [TAIPOSPrinter]);
end;

{ TAIPOSPrinter }

constructor TAIPOSPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'TAIPOSPrinter handles ESC/POS, ZPL, TSPL, and EPL printer hardware and OS Native printing.';
  
  FPrinterModelName := 'Elgin i9 (80mm)';
  FPrinterModel := pmElginI9;
  FLanguage := plEscPos;
  FRenderMode := rmRawCommand;
  FTransportKind := ptTcp9100;
  FCodePage := peCP850;
  FRemoveAccents := False;
  
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
  FLabelPrinted := False;
  FProfile := TAIPrinterProfile.GetProfile(FPrinterModelName);
  
  InitLanguageEngine;
end;

destructor TAIPOSPrinter.Destroy;
begin
  CloseConnection;
  if Assigned(FLanguageEngine) then
    FLanguageEngine.Free;
  if Assigned(FProfile) then
    FProfile.Free;
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
    end
    else if FLanguageEngine is TAIEplLanguage then
    begin
      TAIEplLanguage(FLanguageEngine).LabelWidthDots := Round(FLabelWidthMM * 8);
      TAIEplLanguage(FLanguageEngine).LabelHeightDots := Round(FLabelHeightMM * 8);
      TAIEplLanguage(FLanguageEngine).GapDots := Round(FGapMM * 8);
    end;
  end;
end;

procedure TAIPOSPrinter.InitTransport;
begin
  FTransport := nil;
  if FRenderMode = rmNativeCanvas then Exit;
  
  case FTransportKind of
    ptSerial:     FTransport := TAIPrinterSerialTransport.Create(FDeviceName, FSerialBaud);
    ptTcp9100:    FTransport := TAIPrinterTcpTransport.Create(FHost, FPort);
    ptFile:       FTransport := TAIPrinterFileTransport.Create(FDeviceName);
    ptPrinterRaw: FTransport := TAIPrinterSpoolerTransport.Create(FDeviceName);
  end;
  
  if Assigned(FTransport) then
    FTransport.SetTimeoutMs(FTimeoutMs);
end;

procedure TAIPOSPrinter.SetPrinterModelName(const AValue: string);
begin
  if FPrinterModelName = AValue then Exit;
  FPrinterModelName := AValue;
  
  if Assigned(FProfile) then
    FreeAndNil(FProfile);
  
  FProfile := TAIPrinterProfile.GetProfile(FPrinterModelName);
  if Assigned(FProfile) then
  begin
    if plEscPos in FProfile.SupportedLanguages then
      SetLanguage(plEscPos)
    else if plZpl in FProfile.SupportedLanguages then
      SetLanguage(plZpl)
    else if plTspl in FProfile.SupportedLanguages then
      SetLanguage(plTspl)
    else if plEpl in FProfile.SupportedLanguages then
      SetLanguage(plEpl);
  end;
end;

procedure TAIPOSPrinter.SetPrinterModel(AValue: TAIPosModel);
begin
  if FPrinterModel = AValue then Exit;
  FPrinterModel := AValue;
  case FPrinterModel of
    pmGenerico: FPrinterModelName := 'Generic ESC/POS 80mm';
    pmElginI9: FPrinterModelName := 'Elgin i9 (80mm)';
    pmElginI7: FPrinterModelName := 'Elgin i7';
    pmElginL42DT: FPrinterModelName := 'Elgin L42DT (Label)';
    pmQR203: FPrinterModelName := 'QR203 (58mm)';
    pmBematech4200: FPrinterModelName := 'Bematech 4200';
    pmBematechMP20: FPrinterModelName := 'Bematech MP20';
    pmDarumaDR800: FPrinterModelName := 'Daruma DR800';
    pmDarumaDR700: FPrinterModelName := 'Daruma DR700';
    pmSweda: FPrinterModelName := 'Sweda';
    pmTanca: FPrinterModelName := 'Tanca';
    pmControlID: FPrinterModelName := 'Control ID';
    pmStarTSP100: FPrinterModelName := 'Star TSP100';
    pmZebraZPL: FPrinterModelName := 'Zebra ZPL';
    pmEltronEPL: FPrinterModelName := 'Eltron EPL';
  end;
  SetPrinterModelName(FPrinterModelName);
end;

function TAIPOSPrinter.GetPrinterModel: TAIPosModel;
begin
  Result := FPrinterModel;
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
    FActive := OpenConnection
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

function TAIPOSPrinter.IsLabelLanguage: Boolean;
begin
  Result := FLanguage in [plZpl, plTspl, plEpl];
end;

function TAIPOSPrinter.GetColumns: Integer;
begin
  if Assigned(FProfile) then Result := FProfile.ColumnsNormal else Result := 48;
end;

function TAIPOSPrinter.GetDpi: Integer;
begin
  if Assigned(FProfile) then Result := FProfile.Dpi else Result := 203;
end;

function TAIPOSPrinter.GetSupportsCut: Boolean;
begin
  if Assigned(FProfile) then Result := FProfile.SupportsCut else Result := True;
end;

function TAIPOSPrinter.GetSupportsDrawer: Boolean;
begin
  if Assigned(FProfile) then Result := FProfile.SupportsDrawer else Result := True;
end;

function TAIPOSPrinter.GetSupportsBeep: Boolean;
begin
  if Assigned(FProfile) then Result := FProfile.SupportsBeep else Result := True;
end;

function TAIPOSPrinter.GetSupportsLabel: Boolean;
begin
  if Assigned(FProfile) then Result := FProfile.SupportsLabel else Result := True;
end;

function TAIPOSPrinter.GetSupportsReceipt: Boolean;
begin
  if Assigned(FProfile) then Result := FProfile.SupportsReceipt else Result := True;
end;

function TAIPOSPrinter.BeginJob: Boolean;
begin
  FJobBuilder.Clear;
  FPageLines.Clear;
  FLabelPrinted := False;
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
  if FRenderMode <> rmRawCommand then Exit;
  if not Assigned(FLanguageEngine) then Exit;

  if IsLabelLanguage then
  begin
    if not FLabelPrinted then
    begin
      FJobBuilder.AddBytes(FLanguageEngine.EndLabel);
      FJobBuilder.AddBytes(FLanguageEngine.PrintLabel(1));
      FLabelPrinted := True;
    end;
  end
  else
    FJobBuilder.AddBytes(FLanguageEngine.EndLabel);
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
var
  BB: TAIByteBuilder;
begin
  if not FActive then Exit(False);
  BB := TAIByteBuilder.Create;
  try
    BB.AddTextEncoded(AStr, FCodePage);
    Result := SendDocument(BB.ToBytes);
  finally
    BB.Free;
  end;
end;

function SemAcento(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, 'á', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'à', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'â', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'ã', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'ä', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'Á', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'À', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'Â', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ä', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'é', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'è', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'ê', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'ë', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'É', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'È', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ê', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ë', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'í', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'ì', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'î', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'ï', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'Í', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ì', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Î', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ï', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'ó', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ò', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ô', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'õ', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ö', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ó', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ò', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ô', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Õ', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ö', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'ú', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'ù', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'û', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'ü', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ú', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ù', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Û', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ü', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'ç', 'c', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ç', 'C', [rfReplaceAll]);
  Result := StringReplace(Result, 'ñ', 'n', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ñ', 'N', [rfReplaceAll]);
end;

function TAIPOSPrinter.PrintText(const AText: string): Boolean;
var
  TextToPrint: string;
begin
  Result := False;
  TextToPrint := AText;
  if FRemoveAccents then
    TextToPrint := SemAcento(TextToPrint);
  if FRenderMode = rmNativeCanvas then
  begin
    FPageLines.Add(TextToPrint);
    Result := True;
  end
  else
  begin
    if Assigned(FLanguageEngine) then
    begin
      // Low-level sequential print adds raw encoded text to builder
      FJobBuilder.AddTextEncoded(TextToPrint, FCodePage);
      Result := True;
    end;
  end;
end;

function TAIPOSPrinter.HasCapability(C: Integer): Boolean;
begin
  Result := True;
  case C of
    0: Result := True;
  end;
end;

function TAIPOSPrinter.PrintTextLine(const AText: string): Boolean;
var
  TextToPrint: string;
begin
  Result := False;
  TextToPrint := AText;
  if FRemoveAccents then
    TextToPrint := SemAcento(TextToPrint);
  if FRenderMode = rmNativeCanvas then
  begin
    FPageLines.Add(TextToPrint);
    Result := True;
  end
  else
  begin
    if Assigned(FLanguageEngine) then
    begin
      FJobBuilder.AddBytes(FLanguageEngine.TextLine(TextToPrint));
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
    FJobBuilder.AddBytes(FLanguageEngine.Reset);
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
    FJobBuilder.AddBytes(FLanguageEngine.TextSize(2, 2));
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
  else
  begin
    if Assigned(FProfile) and not FProfile.SupportsCut then
    begin
      FLastError := FProfile.ModelName + ' não possui guilhotina.';
      Exit;
    end;
    if Assigned(FLanguageEngine) then
    begin
      FJobBuilder.AddBytes(FLanguageEngine.Cut(True));
      Result := True;
    end;
  end;
end;

function TAIPOSPrinter.PrintLabel(ACopies: Integer): Boolean;
begin
  Result := False;
  if FRenderMode = rmNativeCanvas then
    Exit(CutPaper);
  if not Assigned(FLanguageEngine) then Exit;
  if ACopies < 1 then ACopies := 1;
  FJobBuilder.AddBytes(FLanguageEngine.EndLabel);
  FJobBuilder.AddBytes(FLanguageEngine.PrintLabel(ACopies));
  FLabelPrinted := True;
  Result := True;
end;

function TAIPOSPrinter.OpenDrawer: Boolean;
begin
  Result := False;
  if Assigned(FProfile) and not FProfile.SupportsDrawer then
  begin
    FLastError := FProfile.ModelName + ' não possui gaveta.';
    Exit;
  end;
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
  if Assigned(FProfile) and not FProfile.SupportsBeep then
  begin
    FLastError := FProfile.ModelName + ' não possui beep.';
    Exit;
  end;
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
  FLastBytesSent := Length(ABytes);
  FLastCommandHex := BytesToHex(ABytes);
  
  if FLastBytesSent = 0 then Exit(True);
  
  if not FActive or not Assigned(FTransport) then
  begin
    if FLastError = '' then
      FLastError := 'Transporte não conectado.';
    Exit;
  end;
  
  FLastError := '';
  Result := FTransport.WriteAll(ABytes);
  if not Result then
    FLastError := FTransport.LastError;
end;

function TAIPOSPrinter.PreviewDocument(const ABytes: TBytes): string;
var
  Raw: RawByteString;
begin
  if FLanguage = plEscPos then
    Result := BytesToHex(ABytes)
  else
  begin
    SetLength(Raw, Length(ABytes));
    if Length(ABytes) > 0 then
      Move(ABytes[0], Raw[1], Length(ABytes));
    Result := string(Raw);
  end;
end;

initialization
  {$I aiposprinter_icon.lrs}

end.
