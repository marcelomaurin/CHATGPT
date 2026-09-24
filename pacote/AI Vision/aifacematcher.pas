unit aifacematcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aifaceprofile, aifacedescriptor;

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
    // Segundo colocado preservado para diagnostico de ambiguidade (Task 26)
    SecondProfileID: string;
    SecondProfileName: string;
    SecondScore: Double;
    ErrorMessage: string;
  end;
  TFaceMatchResultArray = array of TFaceMatchResult;

  { TMatchStrategy }
  TMatchStrategy = (
    msBestSample,
    msAverageSample
  );

  { TFaceThresholdReport }
  TFaceThresholdReport = record
    BestMatchScore: Double;
    WorstMatchScore: Double;
    BestNonMatchScore: Double;
    RecommendedThreshold: Double;
    Margin: Double;
    Summary: string;
  end;

  { TAIFaceMatcher }
  TAIFaceMatcher = class
  private
    FMatchThreshold: Double;
    FMaxEuclideanDistance: Double;
    FAmbiguityMargin: Double;
    FAllowCrossModel: Boolean;
    FStrategy: TMatchStrategy;
  public
    constructor Create;
    function CosineSimilarity(const V1, V2: TDoubleDynArray; out ASimilarity: Double): Boolean;
    function EuclideanDistance(const V1, V2: TDoubleDynArray; out ADistance: Double): Boolean;
    function CompareVectors(const V1, V2: TDoubleDynArray; out AScore, ADistance: Double): Boolean;
    function MatchProfile(const ATargetVector: TDoubleDynArray; AProfile: TAIFaceProfile;
      out AScore, ADistance: Double; out ASampleIndex: Integer): Boolean; overload;
    function MatchProfile(const ATargetData: TAIFaceDescriptorData; AProfile: TAIFaceProfile;
      out AScore, ADistance: Double; out ASampleIndex: Integer): Boolean; overload;
    function MatchProfiles(const ATargetVector: TDoubleDynArray; const AProfiles: TAIFaceProfileArray;
      out AResult: TFaceMatchResult): Boolean; overload;
    function MatchProfiles(const ATargetData: TAIFaceDescriptorData; const AProfiles: TAIFaceProfileArray;
      out AResult: TFaceMatchResult): Boolean; overload;

    property MatchThreshold: Double read FMatchThreshold write FMatchThreshold;
    property MaxEuclideanDistance: Double read FMaxEuclideanDistance write FMaxEuclideanDistance;
    property AmbiguityMargin: Double read FAmbiguityMargin write FAmbiguityMargin;
    property AllowCrossModel: Boolean read FAllowCrossModel write FAllowCrossModel default False;
    property Strategy: TMatchStrategy read FStrategy write FStrategy default msBestSample;
  end;

function EvaluateThreshold(const ASamePersonScores, ADifferentPersonScores: TDoubleDynArray): TFaceThresholdReport;

implementation

function EvaluateThreshold(const ASamePersonScores, ADifferentPersonScores: TDoubleDynArray): TFaceThresholdReport;
var
  i: Integer;
begin
  Result.BestMatchScore := 0.0;
  Result.WorstMatchScore := 1.0;
  Result.BestNonMatchScore := 0.0;
  Result.RecommendedThreshold := 0.82;
  Result.Margin := 0.0;

  if Length(ASamePersonScores) > 0 then
  begin
    for i := 0 to High(ASamePersonScores) do
    begin
      if ASamePersonScores[i] > Result.BestMatchScore then
        Result.BestMatchScore := ASamePersonScores[i];
      if ASamePersonScores[i] < Result.WorstMatchScore then
        Result.WorstMatchScore := ASamePersonScores[i];
    end;
  end;

  if Length(ADifferentPersonScores) > 0 then
  begin
    for i := 0 to High(ADifferentPersonScores) do
    begin
      if ADifferentPersonScores[i] > Result.BestNonMatchScore then
        Result.BestNonMatchScore := ADifferentPersonScores[i];
    end;
  end;

  Result.Margin := Result.WorstMatchScore - Result.BestNonMatchScore;
  if Result.Margin > 0.0 then
    Result.RecommendedThreshold := Result.BestNonMatchScore + (Result.Margin * 0.5)
  else
    Result.RecommendedThreshold := 0.82;

  Result.Summary := Format('Mesma pessoa min=%.4f max=%.4f | Outra pessoa max=%.4f | Margem=%.4f | Recomendado=%.4f',
    [Result.WorstMatchScore, Result.BestMatchScore, Result.BestNonMatchScore, Result.Margin, Result.RecommendedThreshold]);
end;

{ TAIFaceMatcher }

constructor TAIFaceMatcher.Create;
begin
  inherited Create;
  FMatchThreshold := 0.82;
  FMaxEuclideanDistance := 0.0; // Desabilitado por padrao (<= 0.0)
  FAmbiguityMargin := 0.05;
  FAllowCrossModel := False;
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

function TAIFaceMatcher.MatchProfile(const ATargetData: TAIFaceDescriptorData; AProfile: TAIFaceProfile;
  out AScore, ADistance: Double; out ASampleIndex: Integer): Boolean;
var
  i: Integer;
  CurScore, CurDist: Double;
  TotalScore, TotalDist: Double;
  ValidCount: Integer;
  Sample: TAIFaceSample;
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
    Sample := AProfile.Samples[i];
    // Validacao de compatibilidade de algoritmo, versao e modelo
    if not IsDescriptorCompatible(ATargetData.Algorithm, Sample.Algorithm,
      ATargetData.Version, Sample.DescriptorVersion,
      ATargetData.ModelID, Sample.ModelID, FAllowCrossModel) then
      Continue;

    if CompareVectors(ATargetData.Values, Sample.Vector, CurScore, CurDist) then
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
  BestIdx, SecondIdx, BestSampleIdx: Integer;
  CurScore, CurDist: Double;
  CurSampleIdx: Integer;
begin
  AResult.Status := fmsUnknown;
  AResult.ProfileID := '';
  AResult.ProfileName := '';
  AResult.Score := 0.0;
  AResult.Distance := 0.0;
  AResult.SampleIndex := -1;
  AResult.SecondProfileID := '';
  AResult.SecondProfileName := '';
  AResult.SecondScore := 0.0;
  AResult.ErrorMessage := '';

  if Length(ATargetVector) = 0 then
  begin
    AResult.Status := fmsError;
    AResult.ErrorMessage := 'Vetor descritor da face de consulta esta vazio.';
    Exit(False);
  end;

  BestScore := -1.0;
  SecondScore := -1.0;
  BestDist := 999999.0;
  BestIdx := -1;
  SecondIdx := -1;
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
          SecondIdx := BestIdx;
          BestScore := CurScore;
          BestDist := CurDist;
          BestIdx := i;
          BestSampleIdx := CurSampleIdx;
        end
        else if CurScore > SecondScore then
        begin
          SecondScore := CurScore;
          SecondIdx := i;
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

  if SecondIdx >= 0 then
  begin
    AResult.SecondProfileID := AProfiles[SecondIdx].ID;
    AResult.SecondProfileName := AProfiles[SecondIdx].Name;
    AResult.SecondScore := SecondScore;
  end;

  // Criterio duplo: Cosseno >= threshold AND (distancia euclidiana <= max se configurada)
  if (BestScore < FMatchThreshold) or
     ((FMaxEuclideanDistance > 0.0) and (BestDist > FMaxEuclideanDistance)) then
  begin
    AResult.Status := fmsUnknown;
    Exit(True);
  end;

  // Margem de ambiguidade somente aplicada se houver segundo candidato valido com score significativo
  if (SecondIdx >= 0) and (SecondScore >= FMatchThreshold) and
     ((BestScore - SecondScore) < FAmbiguityMargin) then
  begin
    AResult.Status := fmsAmbiguous;
    Exit(True);
  end;

  AResult.Status := fmsMatched;
  Result := True;
end;

function TAIFaceMatcher.MatchProfiles(const ATargetData: TAIFaceDescriptorData; const AProfiles: TAIFaceProfileArray;
  out AResult: TFaceMatchResult): Boolean;
var
  i: Integer;
  Prof: TAIFaceProfile;
  BestScore, SecondScore: Double;
  BestDist: Double;
  BestIdx, SecondIdx, BestSampleIdx: Integer;
  CurScore, CurDist: Double;
  CurSampleIdx: Integer;
begin
  AResult.Status := fmsUnknown;
  AResult.ProfileID := '';
  AResult.ProfileName := '';
  AResult.Score := 0.0;
  AResult.Distance := 0.0;
  AResult.SampleIndex := -1;
  AResult.SecondProfileID := '';
  AResult.SecondProfileName := '';
  AResult.SecondScore := 0.0;
  AResult.ErrorMessage := '';

  if Length(ATargetData.Values) = 0 then
  begin
    AResult.Status := fmsError;
    AResult.ErrorMessage := 'Vetor descritor da face de consulta esta vazio.';
    Exit(False);
  end;

  BestScore := -1.0;
  SecondScore := -1.0;
  BestDist := 999999.0;
  BestIdx := -1;
  SecondIdx := -1;
  BestSampleIdx := -1;

  for i := 0 to High(AProfiles) do
  begin
    Prof := AProfiles[i];
    if (Prof <> nil) and Prof.Enabled and (Prof.SampleCount > 0) then
    begin
      if MatchProfile(ATargetData, Prof, CurScore, CurDist, CurSampleIdx) then
      begin
        if CurScore > BestScore then
        begin
          SecondScore := BestScore;
          SecondIdx := BestIdx;
          BestScore := CurScore;
          BestDist := CurDist;
          BestIdx := i;
          BestSampleIdx := CurSampleIdx;
        end
        else if CurScore > SecondScore then
        begin
          SecondScore := CurScore;
          SecondIdx := i;
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

  if SecondIdx >= 0 then
  begin
    AResult.SecondProfileID := AProfiles[SecondIdx].ID;
    AResult.SecondProfileName := AProfiles[SecondIdx].Name;
    AResult.SecondScore := SecondScore;
  end;

  // Criterio duplo
  if (BestScore < FMatchThreshold) or
     ((FMaxEuclideanDistance > 0.0) and (BestDist > FMaxEuclideanDistance)) then
  begin
    AResult.Status := fmsUnknown;
    Exit(True);
  end;

  // Margem de ambiguidade
  if (SecondIdx >= 0) and (SecondScore >= FMatchThreshold) and
     ((BestScore - SecondScore) < FAmbiguityMargin) then
  begin
    AResult.Status := fmsAmbiguous;
    Exit(True);
  end;

  AResult.Status := fmsMatched;
  Result := True;
end;

end.
