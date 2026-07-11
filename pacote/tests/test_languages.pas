unit test_languages;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  aiprinter_types,
  aiprinter_bytebuilder,
  aiprinter_language_base,
  aiprinter_language_escpos,
  aiprinter_language_tspl,
  aiprinter_language_epl,
  aiprinter_language_zpl;

type
  TTestLanguages = class(TTestCase)
  private
    function BytesToHexPlain(const ABytes: TBytes): string;
  published
    procedure TestEscPosInit;
    procedure TestEscPosBold;
    procedure TestEscPosAlign;
    procedure TestEscPosCut;
    procedure TestEscPosQR;
    procedure TestEscPosCode128;
    
    procedure TestTsplPrint;
    procedure TestTsplBegin;
    
    procedure TestEplPrint;
    procedure TestEplNoLeak;
    procedure TestEplBarcode;
    
    procedure TestZplPrint;
    
    procedure TestCodePage850;
    procedure TestNoCutOnLabel;
  end;

implementation

function TTestLanguages.BytesToHexPlain(const ABytes: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(ABytes) - 1 do
  begin
    if Result <> '' then Result := Result + ' ';
    Result := Result + Format('%.2X', [ABytes[I]]);
  end;
end;

procedure TTestLanguages.TestEscPosInit;
var
  L: TAIEscPosLanguage;
  B: TBytes;
begin
  L := TAIEscPosLanguage.Create;
  try
    L.Encoding := peCP850;
    B := L.BeginLabel;
    AssertEquals('1B 40 1B 74 02', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEscPosBold;
var
  L: TAIEscPosLanguage;
  B: TBytes;
begin
  L := TAIEscPosLanguage.Create;
  try
    B := L.Bold(True);
    AssertEquals('1B 45 01', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEscPosAlign;
var
  L: TAIEscPosLanguage;
  B: TBytes;
begin
  L := TAIEscPosLanguage.Create;
  try
    B := L.Align(taCenter);
    AssertEquals('1B 61 01', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEscPosCut;
var
  L: TAIEscPosLanguage;
  B: TBytes;
begin
  L := TAIEscPosLanguage.Create;
  try
    B := L.Cut(True);
    AssertEquals('1D 56 41 0A', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEscPosQR;
var
  L: TAIEscPosLanguage;
  B: TBytes;
begin
  L := TAIEscPosLanguage.Create;
  try
    B := L.QRCode('ABC', 6);
    AssertEquals('1D 28 6B 04 00 31 41 32 00 ' +
                 '1D 28 6B 03 00 31 43 06 ' +
                 '1D 28 6B 03 00 31 45 31 ' +
                 '1D 28 6B 06 00 31 50 30 41 42 43 ' +
                 '1D 28 6B 03 00 31 51 30', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEscPosCode128;
var
  L: TAIEscPosLanguage;
  B: TBytes;
  Hex: string;
begin
  L := TAIEscPosLanguage.Create;
  try
    B := L.Barcode1D('12345', 80, 2, 2, bsCode128);
    Hex := BytesToHexPlain(B);
    AssertTrue('Contem code128 prefix', Pos('1D 6B 49 07 7B 42 31 32 33 34 35', Hex) > 0);
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestTsplPrint;
var
  L: TAITsplLanguage;
  B: TBytes;
begin
  L := TAITsplLanguage.Create;
  try
    B := L.PrintLabel(1);
    AssertEquals('50 52 49 4E 54 20 31 2C 31 0A', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestTsplBegin;
var
  L: TAITsplLanguage;
  B: TBytes;
  Hex: string;
begin
  L := TAITsplLanguage.Create;
  try
    L.LabelWidthMM := 100;
    L.LabelHeightMM := 50;
    L.GapMM := 2;
    B := L.BeginLabel;
    Hex := BytesToHexPlain(B);
    AssertTrue('Contem SIZE 100 mm,50 mm', Pos('53 49 5A 45 20 31 30 30 20 6D 6D 2C 35 30 20 6D 6D', Hex) > 0);
    AssertTrue('Contem GAP 2 mm,0', Pos('47 41 50 20 32 20 6D 6D 2C 30', Hex) > 0);
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEplPrint;
var
  L: TAIEplLanguage;
  B: TBytes;
begin
  L := TAIEplLanguage.Create;
  try
    B := L.PrintLabel(1);
    AssertEquals('50 31 0A', BytesToHexPlain(B));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEplNoLeak;
var
  L: TAIEplLanguage;
  B: TBytes;
  S: string;
begin
  L := TAIEplLanguage.Create;
  try
    B := L.QRCode('ABC', 4);
    SetLength(S, Length(B));
    if Length(B) > 0 then
      Move(B[0], S[1], Length(B));
    AssertTrue('Nao contem EXPERIMENTAL', Pos('EXPERIMENTAL', S) = 0);
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestEplBarcode;
var
  L: TAIEplLanguage;
  B: TBytes;
  S: string;
begin
  L := TAIEplLanguage.Create;
  try
    B := L.Barcode1D('7891234567890', 80, 2, 2, bsEan13);
    SetLength(S, Length(B));
    if Length(B) > 0 then
      Move(B[0], S[1], Length(B));
    AssertTrue('Gera Ean13 tipo E30', Pos(',"E30",', S) > 0);
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestZplPrint;
var
  L: TAIZplLanguage;
  B: TBytes;
  S: string;
begin
  L := TAIZplLanguage.Create;
  try
    B := L.EndLabel;
    SetLength(S, Length(B));
    if Length(B) > 0 then
      Move(B[0], S[1], Length(B));
    AssertTrue('Termina com ^XZ', (Pos('^XZ', S) > 0));
  finally
    L.Free;
  end;
end;

procedure TTestLanguages.TestCodePage850;
var
  BB: TAIByteBuilder;
  B: TBytes;
begin
  BB := TAIByteBuilder.Create;
  try
    BB.AddTextEncoded('AÇÃO', peCP850);
    B := BB.ToBytes;
    AssertEquals('41 80 C7 4F', BytesToHexPlain(B));
  finally
    BB.Free;
  end;
end;

procedure TTestLanguages.TestNoCutOnLabel;
var
  L: TAITsplLanguage;
  B: TBytes;
  S: string;
begin
  L := TAITsplLanguage.Create;
  try
    B := L.BeginLabel;
    SetLength(S, Length(B));
    if Length(B) > 0 then
      Move(B[0], S[1], Length(B));
    AssertTrue('Nao contem CUT', Pos('CUT', S) = 0);
  finally
    L.Free;
  end;
end;

initialization
  RegisterTest(TTestLanguages);
end.
