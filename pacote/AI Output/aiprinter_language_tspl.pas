unit aiprinter_language_tspl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aiprinter_types, aiprinter_language_base, aiprinter_bytebuilder;

type
  { TAITsplLanguage }

  TAITsplLanguage = class(TAIPrinterLanguageBase)
  private
    FYPos: Integer;
    FAlign: TTextAlign;
    FLabelWidthMM: Integer;
    FLabelHeightMM: Integer;
    FGapMM: Integer;
    FDensity: Integer;
    FSpeed: Integer;
    FDirection: Integer;
  public
    constructor Create; override;
    
    function Reset: TBytes; override;
    function LineFeed: TBytes; override;
    function TextLine(const S: string): TBytes; override;
    function Align(AAlign: TTextAlign): TBytes; override;
    
    function Bold(AEnabled: Boolean): TBytes; override;
    function Underline(AEnabled: Boolean): TBytes; override;
    function TextSize(AWidth, AHeight: Byte): TBytes; override;
    function Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes; override;
    function QRCode(const ACode: string; ASize: Byte = 4): TBytes; override;
    
    function BeginLabel: TBytes; override;
    function EndLabel: TBytes; override;
    function PrintLabel(ACopies: Integer = 1): TBytes; override;
    function Cut(AFull: Boolean): TBytes; override;
    
    // Properties
    property LabelWidthMM: Integer read FLabelWidthMM write FLabelWidthMM;
    property LabelHeightMM: Integer read FLabelHeightMM write FLabelHeightMM;
    property GapMM: Integer read FGapMM write FGapMM;
    property Density: Integer read FDensity write FDensity;
    property Speed: Integer read FSpeed write FSpeed;
    property Direction: Integer read FDirection write FDirection;
  end;

function EscapeTsplString(const S: string): string;

implementation

function EscapeTsplString(const S: string): string;
begin
  Result := S;
  Result := ReplaceStr(Result, '\', '\\');
  Result := ReplaceStr(Result, '"', '\"');
end;

{ TAITsplLanguage }

constructor TAITsplLanguage.Create;
begin
  inherited Create;
  FYPos := 10;
  FAlign := taLeft;
  FLabelWidthMM := 100;
  FLabelHeightMM := 50;
  FGapMM := 2;
  FDensity := 8;
  FSpeed := 4;
  FDirection := 0;
end;

const
  LF = #10;

function TAITsplLanguage.Reset: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes('CLS' + LF);
end;

function TAITsplLanguage.LineFeed: TBytes;
begin
  Inc(FYPos, 30);
  SetLength(Result, 0);
end;

function TAITsplLanguage.TextLine(const S: string): TBytes;
var
  Escaped: string;
  XPos: Integer;
  Cmd: string;
  CharWidthDot: Integer;
  TextWidthDot: Integer;
begin
  Escaped := EscapeTsplString(S);
  
  // Basic layout coordinate calculation based on alignment
  CharWidthDot := 16; // Font "4" character width is ~16 dots
  TextWidthDot := Length(S) * CharWidthDot;
  XPos := 10;
  
  case FAlign of
    taCenter:
    begin
      XPos := (FLabelWidthMM * 8 - TextWidthDot) div 2;
      if XPos < 10 then XPos := 10;
    end;
    taRight:
    begin
      XPos := (FLabelWidthMM * 8) - TextWidthDot - 20;
      if XPos < 10 then XPos := 10;
    end;
  end;
  
  // TSPL command: TEXT x, y, "font", rotation, x-mult, y-mult, "text"
  Cmd := Format('TEXT %d,%d,"4",0,1,1,"%s"' + LF, [XPos, FYPos, Escaped]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, 30);
end;

function TAITsplLanguage.Align(AAlign: TTextAlign): TBytes;
begin
  FAlign := AAlign;
  SetLength(Result, 0);
end;

function TAITsplLanguage.Bold(AEnabled: Boolean): TBytes;
begin
  SetLength(Result, 0);
end;

function TAITsplLanguage.Underline(AEnabled: Boolean): TBytes;
begin
  SetLength(Result, 0);
end;

function TAITsplLanguage.TextSize(AWidth, AHeight: Byte): TBytes;
begin
  SetLength(Result, 0);
end;

function TAITsplLanguage.Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes;
var
  Cmd: string;
  TypeStr: string;
  PrintHri: Integer;
begin
  if I = 0 then PrintHri := 0 else PrintHri := 2; // 2 = printable below
  case ASymbology of
    bsEan13:   TypeStr := 'EAN13';
    bsEan8:    TypeStr := 'EAN8';
    bsCode39:  TypeStr := '39';
    bsItf:     TypeStr := 'ITF';
    bsCodabar: TypeStr := 'CODA';
    else       TypeStr := '128';
  end;
  // TSPL barcode: BARCODE x, y, "type", height, readable, rotation, narrow, wide, "code"
  Cmd := Format('BARCODE 10,%d,"%s",%d,%d,0,%d,%d,"%s"' + LF, [FYPos, TypeStr, H, PrintHri, R, R * 2, ACode]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, H + 20);
end;

function TAITsplLanguage.QRCode(const ACode: string; ASize: Byte): TBytes;
var
  Cmd: string;
begin
  // TSPL QR Code: QRCODE x, y, ecc_level, cell_width, mode, rotation, "code"
  Cmd := Format('QRCODE 10,%d,L,%d,A,0,"%s"' + LF, [FYPos, ASize, ACode]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, ASize * 25 + 20);
end;

function TAITsplLanguage.BeginLabel: TBytes;
var
  Cmd: string;
begin
  FYPos := 10;
  Cmd := Format('SIZE %d mm,%d mm' + LF +
                'GAP %d mm,0' + LF +
                'DIRECTION %d' + LF +
                'DENSITY %d' + LF +
                'SPEED %d' + LF +
                'CLS' + LF, [FLabelWidthMM, FLabelHeightMM, FGapMM, FDirection, FDensity, FSpeed]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
end;

function TAITsplLanguage.EndLabel: TBytes;
begin
  SetLength(Result, 0); // No explicit end marker in TSPL, just PRINT command
end;

function TAITsplLanguage.PrintLabel(ACopies: Integer): TBytes;
var
  Cmd: string;
begin
  if ACopies < 1 then ACopies := 1;
  Cmd := Format('PRINT 1,%d' + LF, [ACopies]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
end;

function TAITsplLanguage.Cut(AFull: Boolean): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes('CUT' + LF);
end;

end.
