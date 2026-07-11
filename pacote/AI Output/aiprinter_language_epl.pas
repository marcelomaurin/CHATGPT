unit aiprinter_language_epl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aiprinter_types, aiprinter_language_base, aiprinter_bytebuilder;

type
  { TAIEplLanguage }

  TAIEplLanguage = class(TAIPrinterLanguageBase)
  private
    FYPos: Integer;
    FAlign: TTextAlign;
    FLabelWidthDots: Integer;
    FLabelHeightDots: Integer;
    FGapDots: Integer;
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
    
    property LabelWidthDots: Integer read FLabelWidthDots write FLabelWidthDots;
    property LabelHeightDots: Integer read FLabelHeightDots write FLabelHeightDots;
    property GapDots: Integer read FGapDots write FGapDots;
  end;

function EscapeEplString(const S: string): string;

implementation

function EscapeEplString(const S: string): string;
begin
  Result := S;
  Result := ReplaceStr(Result, '\', '\\');
  Result := ReplaceStr(Result, '"', '\"');
end;

{ TAIEplLanguage }

constructor TAIEplLanguage.Create;
begin
  inherited Create;
  FYPos := 10;
  FAlign := taLeft;
  FLabelWidthDots := 800;  // 100mm default at 203 dpi
  FLabelHeightDots := 400; // 50mm default
  FGapDots := 16;          // 2mm default
end;

const
  LF = #10;
  CR = #13;

function TAIEplLanguage.Reset: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(CR + LF + 'O' + LF);
end;

function TAIEplLanguage.LineFeed: TBytes;
begin
  Inc(FYPos, 30);
  SetLength(Result, 0);
end;

// Helper to construct TBytes from string in UTF-8
function TAIEplLanguage.TextLine(const S: string): TBytes;
var
  Escaped: string;
  Cmd: string;
begin
  Escaped := EscapeEplString(S);
  Cmd := Format('A10,%d,0,4,1,1,N,"%s"' + LF, [FYPos, Escaped]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, 30);
end;

function TAIEplLanguage.Align(AAlign: TTextAlign): TBytes;
begin
  FAlign := AAlign;
  SetLength(Result, 0);
end;

function TAIEplLanguage.Bold(AEnabled: Boolean): TBytes;
begin
  SetLength(Result, 0);
end;

function TAIEplLanguage.Underline(AEnabled: Boolean): TBytes;
begin
  SetLength(Result, 0);
end;

function TAIEplLanguage.TextSize(AWidth, AHeight: Byte): TBytes;
begin
  SetLength(Result, 0);
end;

function TAIEplLanguage.Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes;
var
  Cmd: string;
  HriPrint: string;
  TypeStr: string;
begin
  case ASymbology of
    bsEan13:   TypeStr := 'E30';
    bsEan8:    TypeStr := 'E80';
    bsCode39:  TypeStr := '3';
    bsCode128: TypeStr := '1';
    bsItf:     TypeStr := '2';
    bsCodabar: TypeStr := 'K';
  else         TypeStr := '1';
  end;
  if I = 0 then HriPrint := 'N' else HriPrint := 'B';
  Cmd := Format('B10,%d,0,"%s",%d,%d,%d,%s,"%s"' + LF, [FYPos, TypeStr, R, R * 2, H, HriPrint, ACode]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, H + 20);
end;

function TAIEplLanguage.QRCode(const ACode: string; ASize: Byte): TBytes;
var
  Cmd: string;
begin
  Cmd := Format('b10,%d,Q,m2,s%d,"%s"' + LF, [FYPos, ASize, ACode]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, 120);
end;

function TAIEplLanguage.BeginLabel: TBytes;
var
  Cmd: string;
begin
  FYPos := 10;
  Cmd := CR + LF +
         Format('q%d' + LF, [FLabelWidthDots]) +
         Format('Q%d,%d' + LF, [FLabelHeightDots, FGapDots]) +
         'N' + LF;
  Result := TEncoding.UTF8.GetBytes(Cmd);
end;

function TAIEplLanguage.EndLabel: TBytes;
begin
  SetLength(Result, 0);
end;

function TAIEplLanguage.PrintLabel(ACopies: Integer): TBytes;
var
  Cmd: string;
begin
  if ACopies < 1 then ACopies := 1;
  Cmd := Format('P%d' + LF, [ACopies]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
end;

end.
