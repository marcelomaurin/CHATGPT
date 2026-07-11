unit aiprinter_language_escpos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_types, aiprinter_language_base, aiprinter_bytebuilder;

type
  { TAIEscPosLanguage }

  TAIEscPosLanguage = class(TAIPrinterLanguageBase)
  public
    function BeginLabel: TBytes; override;
    function Reset: TBytes; override;
    function LineFeed: TBytes; override;
    function TextLine(const S: string): TBytes; override;
    function Align(AAlign: TTextAlign): TBytes; override;
    function Bold(AEnabled: Boolean): TBytes; override;
    function Underline(AEnabled: Boolean): TBytes; override;
    function TextSize(AWidth, AHeight: Byte): TBytes; override;
    function Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes; override;
    function QRCode(const ACode: string; ASize: Byte = 4): TBytes; override;
    
    function Cut(AFull: Boolean): TBytes; override;
    function OpenDrawer: TBytes; override;
    function Beep: TBytes; override;
    
    function CodePageCommand: TBytes;
  end;

implementation

{ TAIEscPosLanguage }

const
  ESC = 27;
  GS = 29;
  LF = 10;

function TAIEscPosLanguage.CodePageCommand: TBytes;
var N: Byte;
begin
  case FEncoding of
    peCP437:       N := 0;
    peCP850:       N := 2;    // padrão BR
    peWindows1252: N := 16;
  else Exit(nil);
  end;
  Result := TBytes.Create(ESC, 116, N);   // ESC t n
end;

function TAIEscPosLanguage.BeginLabel: TBytes;
var
  BB: TAIByteBuilder;
begin
  BB := TAIByteBuilder.Create;
  try
    BB.AddBytes(Reset);
    BB.AddBytes(CodePageCommand);
    Result := BB.ToBytes;
  finally
    BB.Free;
  end;
end;

function TAIEscPosLanguage.Reset: TBytes;
begin
  Result := TBytes.Create(ESC, 64); // ESC @
end;

function TAIEscPosLanguage.LineFeed: TBytes;
begin
  Result := TBytes.Create(LF);
end;

function TAIEscPosLanguage.TextLine(const S: string): TBytes;
var
  BB: TAIByteBuilder;
begin
  BB := TAIByteBuilder.Create;
  try
    BB.AddTextEncoded(S, FEncoding);
    BB.AddByte(LF);
    Result := BB.ToBytes;
  finally
    BB.Free;
  end;
end;

function TAIEscPosLanguage.Align(AAlign: TTextAlign): TBytes;
var
  Val: Byte;
begin
  case AAlign of
    taLeft:   Val := 0;
    taCenter: Val := 1;
    taRight:  Val := 2;
  end;
  Result := TBytes.Create(ESC, 97, Val); // ESC a n
end;

function TAIEscPosLanguage.Bold(AEnabled: Boolean): TBytes;
var
  Val: Byte;
begin
  if AEnabled then Val := 1 else Val := 0;
  Result := TBytes.Create(ESC, 69, Val); // ESC E n
end;

function TAIEscPosLanguage.Underline(AEnabled: Boolean): TBytes;
var
  Val: Byte;
begin
  if AEnabled then Val := 2 else Val := 0;
  Result := TBytes.Create(ESC, 45, Val); // ESC - n
end;

function TAIEscPosLanguage.TextSize(AWidth, AHeight: Byte): TBytes;
var
  Val: Byte;
begin
  // GS ! n
  // width: 1..8, height: 1..8
  if AWidth < 1 then AWidth := 1 else if AWidth > 8 then AWidth := 8;
  if AHeight < 1 then AHeight := 1 else if AHeight > 8 then AHeight := 8;
  Val := ((AWidth - 1) shl 4) or (AHeight - 1);
  Result := TBytes.Create(GS, 33, Val);
end;

function TAIEscPosLanguage.Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes;
var
  BB: TAIByteBuilder;
  Sym: Byte;
begin
  BB := TAIByteBuilder.Create;
  try
    // Set height: GS h H
    BB.AddBytes(TBytes.Create(GS, 104, H));
    // Set width: GS w R
    BB.AddBytes(TBytes.Create(GS, 119, R));
    // Set HRI position: GS H I (0=none, 1=above, 2=below)
    BB.AddBytes(TBytes.Create(GS, 72, I));
    
    case ASymbology of
      bsEan13:   Sym := 2;
      bsEan8:    Sym := 3;
      bsCode39:  Sym := 4;
      bsItf:     Sym := 5;
      bsCodabar: Sym := 6;
      bsCode128:
      begin
        // Format B for Code 128: GS k 73 len data
        // T3: Code 128 sem code set:
        BB.AddBytes(TBytes.Create(GS, 107, 73, Byte(Length(ACode) + 2)));
        BB.AddAscii('{B' + RawByteString(ACode));
        Exit(BB.ToBytes);
      end;
    else
      Sym := 4; // Code 39 default fallback
    end;
    // Format A
    BB.AddBytes(TBytes.Create(GS, 107, Sym));
    BB.AddAscii(RawByteString(ACode));
    BB.AddByte(0); // NUL terminator
    Result := BB.ToBytes;
  finally
    BB.Free;
  end;
end;

function TAIEscPosLanguage.QRCode(const ACode: string; ASize: Byte): TBytes;
var
  BB: TAIByteBuilder;
  Len: Integer;
begin
  BB := TAIByteBuilder.Create;
  try
    // modelo 2
    BB.AddBytes(TBytes.Create(GS, 40, 107, 4, 0, 49, 65, 50, 0));
    // tamanho do módulo (1..16)
    BB.AddBytes(TBytes.Create(GS, 40, 107, 3, 0, 49, 67, ASize));
    // correção de erro: 48=L 49=M 50=Q 51=H
    BB.AddBytes(TBytes.Create(GS, 40, 107, 3, 0, 49, 69, 49));
    // store: pL/pH = Length(data) + 3
    Len := Length(ACode) + 3;
    BB.AddBytes(TBytes.Create(GS, 40, 107, Len mod 256, Len div 256, 49, 80, 48));
    BB.AddAscii(RawByteString(ACode));
    // print
    BB.AddBytes(TBytes.Create(GS, 40, 107, 3, 0, 49, 81, 48));
    
    Result := BB.ToBytes;
  finally
    BB.Free;
  end;
end;

function TAIEscPosLanguage.Cut(AFull: Boolean): TBytes;
begin
  if AFull then
    Result := TBytes.Create(GS, 86, 65, 10)
  else
    Result := TBytes.Create(GS, 86, 66, 10);
end;

function TAIEscPosLanguage.OpenDrawer: TBytes;
begin
  // ESC p 0 25 250
  Result := TBytes.Create(ESC, 112, 0, 25, 250);
end;

function TAIEscPosLanguage.Beep: TBytes;
begin
  // Elgin i9 beep sequence
  Result := TBytes.Create(ESC, 40, 65, 5, 0, 97, 100, 1, 100, 100);
end;

end.
