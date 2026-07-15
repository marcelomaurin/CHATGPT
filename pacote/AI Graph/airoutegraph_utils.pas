unit airoutegraph_utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LazUTF8, airoutegraph_types;

function NormalizeRouteText(const AValue: string): string;
function HaversineDistanceMeters(
  const ALat1, ALon1, ALat2, ALon2: Double
): Double;
function CalculateLineStringDistance(const APoints: TAIGeoPointArray): Double;
function ParseMaxSpeedKmH(const AValue: string; const ADefault: Double): Double;
function RoadTypeFromText(const AValue: string): TAIRoadType;
function DefaultSpeedForRoadType(ARoadType: TAIRoadType): Double;

implementation

function NormalizeRouteText(const AValue: string): string;
var
  S: string;
  I: Integer;
begin
  S := UTF8LowerCase(Trim(AValue));
  S := StringReplace(S, 'á', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'à', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'â', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'ã', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'ä', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'é', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'ê', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'è', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'í', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ï', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ó', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ô', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'õ', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ö', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ú', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ü', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ç', 'c', [rfReplaceAll]);
  for I := 1 to Length(S) do
    if not (S[I] in ['a'..'z', '0'..'9']) then
      if not (S[I] in [' ', '-', '_']) then
        S[I] := ' ';
  while Pos('  ', S) > 0 do
    S := StringReplace(S, '  ', ' ', [rfReplaceAll]);
  Result := Trim(S);
end;

function HaversineDistanceMeters(
  const ALat1, ALon1, ALat2, ALon2: Double
): Double;
const
  EARTH_RADIUS_METERS = 6371008.8;
var
  Lat1Rad, Lat2Rad: Double;
  DeltaLat, DeltaLon: Double;
  A, C: Double;
begin
  Lat1Rad := DegToRad(ALat1);
  Lat2Rad := DegToRad(ALat2);

  DeltaLat := DegToRad(ALat2 - ALat1);
  DeltaLon := DegToRad(ALon2 - ALon1);

  A := Sqr(Sin(DeltaLat / 2)) +
    Cos(Lat1Rad) * Cos(Lat2Rad) * Sqr(Sin(DeltaLon / 2));
  C := 2 * ArcTan2(Sqrt(A), Sqrt(Max(0, 1 - A)));
  Result := EARTH_RADIUS_METERS * C;
end;

function CalculateLineStringDistance(const APoints: TAIGeoPointArray): Double;
var
  I: Integer;
begin
  Result := 0;
  if Length(APoints) < 2 then
    Exit;

  for I := 1 to High(APoints) do
    Result += HaversineDistanceMeters(
      APoints[I - 1].Latitude,
      APoints[I - 1].Longitude,
      APoints[I].Latitude,
      APoints[I].Longitude
    );
end;

function ParseMaxSpeedKmH(const AValue: string; const ADefault: Double): Double;
var
  S: string;
  I, P: Integer;
  Num: Double;
begin
  S := Trim(LowerCase(AValue));
  if S = '' then
    Exit(ADefault);

  P := Pos(';', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);
  P := Pos(',', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);
  P := Pos(' ', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);
  P := Pos('km', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);
  P := Pos('mph', S);
  if P > 0 then
  begin
    Delete(S, P, MaxInt);
    if TryStrToFloat(S, Num) then
      Exit(Num * 1.609344);
    Exit(ADefault);
  end;

  if TryStrToFloat(S, Num) then
    Exit(Num);

  Result := ADefault;
end;

function RoadTypeFromText(const AValue: string): TAIRoadType;
var
  S: string;
begin
  S := NormalizeRouteText(AValue);
  if Pos('motorway', S) > 0 then Exit(rtMotorway);
  if Pos('trunk', S) > 0 then Exit(rtTrunk);
  if Pos('primary', S) > 0 then Exit(rtPrimary);
  if Pos('secondary', S) > 0 then Exit(rtSecondary);
  if Pos('tertiary', S) > 0 then Exit(rtTertiary);
  if Pos('residential', S) > 0 then Exit(rtResidential);
  if Pos('service', S) > 0 then Exit(rtService);
  if Pos('track', S) > 0 then Exit(rtTrack);
  if Pos('unclassified', S) > 0 then Exit(rtUnclassified);
  Result := rtUnknown;
end;

function DefaultSpeedForRoadType(ARoadType: TAIRoadType): Double;
begin
  case ARoadType of
    rtMotorway: Result := 100;
    rtTrunk: Result := 90;
    rtPrimary: Result := 80;
    rtSecondary: Result := 70;
    rtTertiary: Result := 60;
    rtUnclassified: Result := 50;
    rtResidential: Result := 30;
    rtService: Result := 20;
    rtTrack: Result := 15;
  else
    Result := 40;
  end;
end;

end.
