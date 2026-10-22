unit aispeakersignature;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Math;
type
  TAISpeakerDecision = (sdSame, sdDifferent, sdInconclusive);
  TAISpeakerSignature = array of Double;
  TAISpeakerSession = class
  private
    FReference: TAISpeakerSignature;
    FActive: Boolean;
    FSameThreshold: Double;
    FDifferentThreshold: Double;
    function Similarity(const A, B: TAISpeakerSignature): Double;
  public
    constructor Create;
    procedure Reset;
    function Evaluate(const ASignature: TAISpeakerSignature;
      out ADecision: TAISpeakerDecision): Boolean;
    property Active: Boolean read FActive;
    property SameThreshold: Double read FSameThreshold write FSameThreshold;
    property DifferentThreshold: Double read FDifferentThreshold write FDifferentThreshold;
  end;
implementation
constructor TAISpeakerSession.Create;
begin
  inherited Create;
  FSameThreshold := 0.82;
  FDifferentThreshold := 0.58;
end;
procedure TAISpeakerSession.Reset;
begin
  FActive := False;
  SetLength(FReference, 0);
end;
function TAISpeakerSession.Similarity(const A, B: TAISpeakerSignature): Double;
var I: Integer; Dot, NormA, NormB: Double;
begin
  Result := NaN;
  if (Length(A) = 0) or (Length(A) <> Length(B)) then Exit;
  Dot := 0; NormA := 0; NormB := 0;
  for I := 0 to High(A) do
  begin
    if IsNan(A[I]) or IsInfinite(A[I]) or IsNan(B[I]) or IsInfinite(B[I]) then Exit;
    Dot := Dot + A[I] * B[I];
    NormA := NormA + Sqr(A[I]);
    NormB := NormB + Sqr(B[I]);
  end;
  if (NormA <= 0) or (NormB <= 0) then Exit;
  Result := Dot / Sqrt(NormA * NormB);
end;
function TAISpeakerSession.Evaluate(const ASignature: TAISpeakerSignature;
  out ADecision: TAISpeakerDecision): Boolean;
var Score: Double;
begin
  ADecision := sdInconclusive;
  if not FActive then
  begin
    if Length(ASignature) > 0 then
    begin
      Score := Similarity(ASignature, ASignature);
      if not IsNan(Score) then
      begin
        FReference := Copy(ASignature, 0, Length(ASignature));
        FActive := True;
      end;
    end;
    Result := True;
    Exit;
  end;
  Score := Similarity(FReference, ASignature);
  if not IsNan(Score) then
  begin
    if Score >= FSameThreshold then ADecision := sdSame
    else if Score <= FDifferentThreshold then ADecision := sdDifferent;
  end;
  { Inconclusive is always accepted; reference is never changed by it. }
  Result := ADecision <> sdDifferent;
end;
end.
