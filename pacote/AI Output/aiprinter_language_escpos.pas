unit aiprinter_language_escpos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_types, aiprinter_language_base, aiprinter_bytebuilder;

type
  { TAIEscPosLanguage }

  TAIEscPosLanguage = class(TAIPrinterLanguageBase)
  public
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
  end;

implementation

{ TAIEscPosLanguage }

const
  ESC = 27;
  GS = 29;
  LF = 10;

function TAIEscPosLanguage.Reset: TBytes;
begin
  Result := [ESC, 64]; // ESC @
end;

function TAIEscPosLanguage.LineFeed: TBytes;
begin
  Result := [LF];
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
  Result := [ESC, 97, Val]; // ESC a n
end;

function TAIEscPosLanguage.Bold(AEnabled: Boolean): TBytes;
var
  Val: Byte;
begin
  if AEnabled then Val := 1 else Val := 0;
  Result := [ESC, 69, Val]; // ESC E n
end;

function TAIEscPosLanguage.Underline(AEnabled: Boolean): TBytes;
var
  Val: Byte;
begin
  if AEnabled then Val := 2 else Val := 0;
  Result := [ESC, 45, Val]; // ESC - n
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
  Result := [GS, 33, Val];
end;

function TAIEscPosLanguage.Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes;
var
  BB: TAIByteBuilder;
  Sym: Byte;
begin
  BB := TAIByteBuilder.Create;
  try
    // Set height: GS h H
    BB.AddBytes([GS, 104, H]);
    // Set width: GS w R
    BB.AddBytes([GS, 119, R]);
    // Set HRI position: GS H I (0=none, 1=above, 2=below)
    BB.AddBytes([GS, 72, I]);
    
    case ASymbology of
      bsEan13:   Sym := 2;
      bsEan8:    Sym := 3;
      bsCode39:  Sym := 4;
      bsItf:     Sym := 5;
      bsCodabar: Sym := 6;
      bsCode128:
      begin
        // Format B for Code 128: GS k 73 len data
        BB.AddBytes([GS, 107, 73, Length(ACode)]);
        BB.AddAscii(RawByteString(ACode));
        Exit(BB.ToBytes);
      end;
    end;
    // Format A
    BB.AddBytes([GS, 107, Sym]);
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
  PL, PH: Byte;
begin
  BB := TAIByteBuilder.Create;
  try
    Len := Length(ACode) + 3;
    PL := Len mod 256;
    PH := Len div 256;
    
    // 1. Model 2: GS ( k 4 0 49 67 49 0
    BB.AddBytes([GS, 40, 107, 4, 0, 49, 67, 49, 0]);
    // 2. Size: GS ( k 3 0 49 69 size
    BB.AddBytes([GS, 40, 107, 3, 0, 49, 69, ASize]);
    // 3. Error Correction M: GS ( k 3 0 49 70 48
    BB.AddBytes([GS, 40, 107, 3, 0, 49, 70, 48]);
    // 4. Store: GS ( k pL pH 49 80 48 data
    BB.AddBytes([GS, 40, 107, PL, PH, 49, 80, 48]);
    BB.AddAscii(RawByteString(ACode));
    // 5. Print: GS ( k 3 0 49 81 48
    BB.AddBytes([GS, 40, 107, 3, 0, 49, 81, 48]);
    
    Result := BB.ToBytes;
  finally
    BB.Free;
  end;
end;

function TAIEscPosLanguage.Cut(AFull: Boolean): TBytes;
begin
  // GS V 66 0
  Result := [GS, 86, 66, 0];
end;

function TAIEscPosLanguage.OpenDrawer: TBytes;
begin
  // ESC p 0 25 250
  Result := [ESC, 112, 0, 25, 250];
end;

function TAIEscPosLanguage.Beep: TBytes;
begin
  // Elgin i9 beep sequence
  Result := [ESC, 40, 65, 5, 0, 97, 100, 1, 100, 100];
end;

end.
