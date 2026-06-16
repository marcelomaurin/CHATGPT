unit aiwordunits;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

function MMToTwip(AValueMM: Double): Integer;
function TwipToMM(AValueTwip: Integer): Double;

function PtToHalfPoint(APointSize: Double): Integer;
function HalfPointToPt(AHalfPoint: Integer): Double;

function MMToEMU(AValueMM: Double): Int64;
function EMUToMM(AValueEMU: Int64): Double;

function ColorToHex(AColor: TColor): string;
function HexToColor(const AHex: string): TColor;

implementation

function MMToTwip(AValueMM: Double): Integer;
begin
  Result := Round(AValueMM * 56.692913);
end;

function TwipToMM(AValueTwip: Integer): Double;
begin
  Result := AValueTwip / 56.692913;
end;

function PtToHalfPoint(APointSize: Double): Integer;
begin
  Result := Round(APointSize * 2.0);
end;

function HalfPointToPt(AHalfPoint: Integer): Double;
begin
  Result := AHalfPoint / 2.0;
end;

function MMToEMU(AValueMM: Double): Int64;
begin
  Result := Round(AValueMM * 36000.0);
end;

function EMUToMM(AValueEMU: Int64): Double;
begin
  Result := AValueEMU / 36000.0;
end;

function ColorToHex(AColor: TColor): string;
var
  R, G, B: Byte;
  ColorVal: LongInt;
begin
  ColorVal := ColorToRGB(AColor);
  R := ColorVal and $FF;
  G := (ColorVal >> 8) and $FF;
  B := (ColorVal >> 16) and $FF;
  Result := Format('%.2X%.2X%.2X', [R, G, B]);
end;

function HexToColor(const AHex: string): TColor;
var
  R, G, B: Byte;
  CleanHex: string;
begin
  CleanHex := Trim(AHex);
  if (Length(CleanHex) > 0) and (CleanHex[1] = '#') then
    Delete(CleanHex, 1, 1);
  
  if Length(CleanHex) < 6 then
    CleanHex := CleanHex + StringOfChar('0', 6 - Length(CleanHex));
    
  try
    R := StrToInt('$' + Copy(CleanHex, 1, 2));
    G := StrToInt('$' + Copy(CleanHex, 3, 2));
    B := StrToInt('$' + Copy(CleanHex, 5, 2));
    Result := RGBToColor(R, G, B);
  except
    Result := clBlack;
  end;
end;

end.
