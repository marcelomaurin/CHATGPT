unit aifacematcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aifaceprofile;

type
  { TFaceMatchStatus }
  TFaceMatchStatus = (
    fmsUnknown,
    fmsMatched,
    fmsAmbiguous,
    fmsError
  );

  { TFaceMatchResult }
  TFaceMatchResult = record
    Status: TFaceMatchStatus;
    ProfileID: string;
    ProfileName: string;
    Score: Double;
    Distance: Double;
    SampleIndex: Integer;
    ErrorMessage: string;
  end;
  TFaceMatchResultArray = array of TFaceMatchResult;

  { TMatchStrategy }
  TMatchStrategy = (
    msBestSample,
    msAverageSample
  );

  { TAIFaceMatcher }
  TAIFaceMatcher = class
  private
    FMatchThreshold: Double;
    FAmbiguityMargin: Double;
    FStrategy: TMatchStrategy;
  public
    constructor Create;
    function CosineSimilarity(const V1, V2: TDoubleDynArray; out ASimilarity: Double): Boolean;
    function EuclideanDistance(const V1, V2: TDoubleDynArray; out ADistance: Double): Boolean;
    function CompareVectors(const V1, V2: TDoubleDynArray; out AScore, ADistance: Double): Boolean;
    function MatchProfile(const ATargetVector: TDoubleDynArray; AProfile: TAIFaceProfile;
      out AScore, ADistance: Double; out ASampleIndex: Integer): Boolean;
    function MatchProfiles(const ATargetVector: TDoubleDynArray; const AProfiles: TAIFaceProfileArray;
      out AResult: TFaceMatchResult): Boolean;

    property MatchThreshold: Double read FMatchThreshold write FMatchThreshold;
    property AmbiguityMargin: Double read FAmbiguityMargin write FAmbiguityMargin;
    property Strategy: TMatchStrategy read FStrategy write FStrategy default msBestSample;
  end;

implementation

{ TAIFaceMatcher }

constructor TAIFaceMatcher.Create;
begin
  inherited Create;
  FMatchThreshold := 0.82;
  FAmbiguityMargin := 0.05;
  FStrategy := msBestSample;
end;

function TAIFaceMatcher.CosineSimilarity(const V1, V2: TDoubleDynArray; out ASimilarity: Double): Boolean;
var
  i, Len: Integer;
  Dot, Norm1, Norm2: Double;
begin
  Result := False;
  ASimilarity := 0.0;

  Len := Length(V1);
  if (Len = 0) or (Len <> Length(V2)) then
    Exit;

  Dot := 0.0;
  Norm1 := 0.0;
  Norm2 := 0.0;

  for i := 0 to Len - 1 do
  begin
    Dot := Dot + (V1[i] * V2[i]);
    Norm1 := Norm1 + Sqr(V1[i]);
    Norm2 := Norm2 + Sqr(V2[i]);
  end;

  if (Norm1 <= 1e-12) or (Norm2 <= 1e-12) then
    Exit;

  ASimilarity := Dot / (Sqrt(Norm1) * Sqrt(Norm2));
  if ASimilarity > 1.0 then ASimilarity := 1.0
  else if ASimilarity < -1.0 then ASimilarity := -1.0;

  Result := True;
end;

function TAIFaceMatcher.EuclideanDistance(const V1, V2: TDoubleDynArray; out ADistance: Double): Boolean;
var
  i, Len: Integer;
  SumSq: Double;
begin
  Result := False;
  ADistance := 0.0;

  Len := Length(V1);
  if (Len = 0) or (Len <> Length(V2)) then
    Exit;

  SumSq := 0.0;
  for i := 0 to Len - 1 do
    SumSq := SumSq + Sqr(V1[i] - V2[i]);

  ADistance := Sqrt(SumSq);
  Result := True;
end;

function TAIFaceMatcher.CompareVectors(const V1, V2: TDoubleDynArray; out AScore, ADistance: Double): Boolean;
begin
  AScore := 0.0;
  ADistance := 0.0;
  if not CosineSimilarity(V1, V2, AScore) then
    Exit(False);
  EuclideanDistance(V1, V2, ADistance);
  Result := True;
end;

function TAIFaceMatcher.MatchProfile(const ATargetVector: TDoubleDynArray; AProfile: TAIFaceProfile;
  out AScore, ADistance: Double; out ASampleIndex: Integer): Boolean;
var
  i: Integer;
  CurScore, CurDist: Double;
  TotalScore, TotalDist: Double;
  ValidCount: Integer;
begin
  Result := False;
  AScore := -1.0;
  ADistance := 999999.0;
  ASampleIndex := -1;

  if (AProfile = nil) or not AProfile.Enabled or (AProfile.SampleCount = 0) then
    Exit;

  TotalScore := 0.0;
  TotalDist := 0.0;
  ValidCount := 0;

  for i := 0 to AProfile.SampleCount - 1 do
  begin
    if CompareVectors(ATargetVector, AProfile.Samples[i].Vector, CurScore, CurDist) then
    begin
      Inc(ValidCount);
      TotalScore := TotalScore + CurScore;
      TotalDist := TotalDist + CurDist;

      if (ASampleIndex = -1) or (CurScore > AScore) then
      begin
        AScore := CurScore;
        ADistance := CurDist;
        ASampleIndex := i;
      end;
    end;
  end;

  if ValidCount > 0 then
  begin
    if FStrategy = msAverageSample then
    begin
      AScore := TotalScore / ValidCount;
      ADistance := TotalDist / ValidCount;
    end;
    Result := True;
  end;
end;

function TAIFaceMatcher.MatchProfiles(const ATargetVector: TDoubleDynArray; const AProfiles: TAIFaceProfileArray;
  out AResult: TFaceMatchResult): Boolean;
var
  i: Integer;
  Prof: TAIFaceProfile;
  BestScore, SecondScore: Double;
  BestDist: Double;
  BestIdx, BestSampleIdx: Integer;
  CurScore, CurDist: Double;
  CurSampleIdx: Integer;
begin
  AResult.Status := fmsUnknown;
  AResult.ProfileID := '';
  AResult.ProfileName := '';
  AResult.Score := 0.0;
  AResult.Distance := 0.0;
  AResult.SampleIndex := -1;
  AResult.ErrorMessage := '';

  if Length(ATargetVector) = 0 then
  begin
    AResult.Status := fmsError;
    AResult.ErrorMessage := 'Vetor descritor da face de consulta está vazio.';
    Exit(False);
  end;

  BestScore := -1.0;
  SecondScore := -1.0;
  BestDist := 999999.0;
  BestIdx := -1;
  BestSampleIdx := -1;

  for i := 0 to High(AProfiles) do
  begin
    Prof := AProfiles[i];
    if (Prof <> nil) and Prof.Enabled and (Prof.SampleCount > 0) then
    begin
      if MatchProfile(ATargetVector, Prof, CurScore, CurDist, CurSampleIdx) then
      begin
        if CurScore > BestScore then
        begin
          SecondScore := BestScore;
          BestScore := CurScore;
          BestDist := CurDist;
          BestIdx := i;
          BestSampleIdx := CurSampleIdx;
        end
        else if CurScore > SecondScore then
        begin
          SecondScore := CurScore;
        end;
      end;
    end;
  end;

  if BestIdx < 0 then
  begin
    AResult.Status := fmsUnknown;
    Exit(True);
  end;

  AResult.Score := BestScore;
  AResult.Distance := BestDist;
  AResult.ProfileID := AProfiles[BestIdx].ID;
  AResult.ProfileName := AProfiles[BestIdx].Name;
  AResult.SampleIndex := BestSampleIdx;

  if BestScore < FMatchThreshold then
  begin
    AResult.Status := fmsUnknown;
    Exit(True);
  end;

  if (SecondScore >= FMatchThreshold) and ((BestScore - SecondScore) < FAmbiguityMargin) then
  begin
    AResult.Status := fmsAmbiguous;
    Exit(True);
  end;

  AResult.Status := fmsMatched;
  Result := True;
end;

end.
