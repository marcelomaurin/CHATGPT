unit aiprinter_language_zpl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aiprinter_types, aiprinter_language_base, aiprinter_bytebuilder;

type
  { TAIZplLanguage }

  TAIZplLanguage = class(TAIPrinterLanguageBase)
  private
    FYPos: Integer;
    FAlign: TTextAlign;
    FLabelWidthPixels: Integer;
    FLabelHeightPixels: Integer;
  public
    constructor Create; override;
    
    function Reset: TBytes; override;
    function LineFeed: TBytes; override;
    function TextLine(const S: string): TBytes; override;
    function Align(AAlign: TTextAlign): TBytes; override;
    
    // ZPL specific
    function Bold(AEnabled: Boolean): TBytes; override;
    function Underline(AEnabled: Boolean): TBytes; override;
    function TextSize(AWidth, AHeight: Byte): TBytes; override;
    function Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes; override;
    function QRCode(const ACode: string; ASize: Byte = 4): TBytes; override;
    
    function BeginLabel: TBytes; override;
    function EndLabel: TBytes; override;
    function PrintLabel(ACopies: Integer = 1): TBytes; override;
    
    // Properties
    property LabelWidthPixels: Integer read FLabelWidthPixels write FLabelWidthPixels;
    property LabelHeightPixels: Integer read FLabelHeightPixels write FLabelHeightPixels;
  end;

function EscapeZplFieldData(const S: string): string;

implementation

function EscapeZplFieldData(const S: string): string;
begin
  Result := S;
  Result := ReplaceStr(Result, '\', '\\');
  Result := ReplaceStr(Result, '^', '_5e');
  Result := ReplaceStr(Result, '~', '_7e');
end;

{ TAIZplLanguage }

constructor TAIZplLanguage.Create;
begin
  inherited Create;
  FYPos := 10;
  FAlign := taLeft;
  FLabelWidthPixels := 832; // Default for 104mm label at 203 DPI (8 dots/mm)
  FLabelHeightPixels := 1200;
end;

const
  LF = #10;

function TAIZplLanguage.Reset: TBytes;
begin
  // Standard zebra reset
  Result := TEncoding.UTF8.GetBytes('~JR' + LF);
end;

function TAIZplLanguage.LineFeed: TBytes;
begin
  Inc(FYPos, 30);
  SetLength(Result, 0);
end;

function TAIZplLanguage.TextLine(const S: string): TBytes;
var
  Escaped: string;
  AlignChar: Char;
  Cmd: string;
begin
  Escaped := EscapeZplFieldData(S);
  case FAlign of
    taLeft:   AlignChar := 'L';
    taCenter: AlignChar := 'C';
    taRight:  AlignChar := 'R';
  end;
  // Use Field Block (^FB) for alignment support
  Cmd := Format('^FO10,%d^A0N,28,28^FB%d,1,,%s^FD%s^FS' + LF, [FYPos, FLabelWidthPixels - 20, AlignChar, Escaped]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, 32);
end;

function TAIZplLanguage.Align(AAlign: TTextAlign): TBytes;
begin
  FAlign := AAlign;
  SetLength(Result, 0);
end;

function TAIZplLanguage.Bold(AEnabled: Boolean): TBytes;
begin
  // Fonts are scaled or selected separately. We return empty here.
  SetLength(Result, 0);
end;

function TAIZplLanguage.Underline(AEnabled: Boolean): TBytes;
begin
  SetLength(Result, 0);
end;

function TAIZplLanguage.TextSize(AWidth, AHeight: Byte): TBytes;
begin
  SetLength(Result, 0);
end;

function TAIZplLanguage.Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes;
var
  Cmd: string;
  HriPrint: Char;
begin
  if I = 0 then HriPrint := 'N' else HriPrint := 'Y';
  // ZPL barcode: ^FO x, y ^BY narrow_width ^BC rotation, height, print_hri
  Cmd := Format('^FO10,%d^BY%d^BCN,%d,%s,N,N^FD%s^FS' + LF, [FYPos, R, H, HriPrint, ACode]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, H + 20);
end;

function TAIZplLanguage.QRCode(const ACode: string; ASize: Byte): TBytes;
var
  Cmd: string;
begin
  // ZPL QR Code: ^FO x, y ^BQN, model, magnification ^FD QA, data ^FS
  Cmd := Format('^FO10,%d^BQN,2,%d^FDQA,%s^FS' + LF, [FYPos, ASize, ACode]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
  Inc(FYPos, ASize * 25 + 20);
end;

function TAIZplLanguage.BeginLabel: TBytes;
var
  Cmd: string;
begin
  FYPos := 10;
  // ^XA: Start label, ^CI28: UTF-8 encoding, ^PW: Print Width, ^LL: Label Length
  Cmd := '^XA' + LF + '^CI28' + LF +
         Format('^PW%d' + LF + '^LL%d' + LF, [FLabelWidthPixels, FLabelHeightPixels]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
end;

function TAIZplLanguage.EndLabel: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes('^XZ' + LF);
end;

function TAIZplLanguage.PrintLabel(ACopies: Integer): TBytes;
var
  Cmd: string;
begin
  if ACopies < 1 then ACopies := 1;
  Cmd := Format('^PQ%d' + LF, [ACopies]);
  Result := TEncoding.UTF8.GetBytes(Cmd);
end;

end.
