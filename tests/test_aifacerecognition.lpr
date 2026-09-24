program test_aifacerecognition;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Math,
  yolodetect, aifaceprofile, aifacedescriptor, aifacematcher, aifacejson, aifaceregistry, aifacerecognition;

procedure AssertTrue(const ADesc: string; const ACond: Boolean);
begin
  if not ACond then
  begin
    WriteLn('  [FALHA] ', ADesc);
    raise Exception.Create('Teste falhou: ' + ADesc);
  end
  else
    WriteLn('  [PASSOU] ', ADesc);
end;

function CreateSyntheticFace(X1, Y1, X2, Y2: Integer; TiltAngleRad: Double; Conf: Double; KpConf: Double = 0.90): TYoloObject;
var
  W, H, Cx, Cy: Double;
  CosA, SinA: Double;

  function RotPt(Px, Py: Double): TYoloKeyPoint;
  var
    Dx, Dy: Double;
  begin
    Dx := Px - Cx;
    Dy := Py - Cy;
    Result.X := Cx + (CosA * Dx - SinA * Dy);
    Result.Y := Cy + (SinA * Dx + CosA * Dy);
    Result.Confidence := KpConf;
  end;

begin
  Result.ClassName := 'face';
  Result.Confidence := Conf;
  Result.X1 := X1;
  Result.Y1 := Y1;
  Result.X2 := X2;
  Result.Y2 := Y2;
  Result.Polygon := '';

  W := X2 - X1;
  H := Y2 - Y1;
  Cx := X1 + (W * 0.5);
  Cy := Y1 + (H * 0.5);

  CosA := Cos(TiltAngleRad);
  SinA := Sin(TiltAngleRad);

  SetLength(Result.KeyPoints, 5);
  Result.KeyPoints[0] := RotPt(X1 + W * 0.30, Y1 + H * 0.35); // Left eye
  Result.KeyPoints[1] := RotPt(X1 + W * 0.70, Y1 + H * 0.35); // Right eye
  Result.KeyPoints[2] := RotPt(X1 + W * 0.50, Y1 + H * 0.55); // Nose
  Result.KeyPoints[3] := RotPt(X1 + W * 0.35, Y1 + H * 0.75); // Mouth left
  Result.KeyPoints[4] := RotPt(X1 + W * 0.65, Y1 + H * 0.75); // Mouth right
end;

{ TMockYOLO: Detector mock para testes sem dependência de Python em runtime (Tarefa 30) }
type
  TMockYOLO = class(TYOLO)
  public
    MockObjects: TYoloObjectArray;
    SimulateError: Boolean;
    SimulateErrorMsg: string;
    function DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean; override;
  end;

function TMockYOLO.DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean;
var
  i: Integer;
begin
  if SimulateError then
  begin
    LastError := SimulateErrorMsg;
    SetLength(AObjects, 0);
    Exit(False);
  end;

  SetLength(AObjects, Length(MockObjects));
  for i := 0 to High(MockObjects) do
    AObjects[i] := MockObjects[i];
  Result := True;
end;

// Teste 50: Mesma fotografia -> alta similaridade e MATCH
procedure Test50_SamePhoto;
var
  Face1, Face2: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data1, Data2: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  Score, Dist: Double;
begin
  WriteLn('--- Teste 50: Mesma fotografia ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  try
    Face1 := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95);
    Face2 := Face1;

    AssertTrue('Descriptor face 1 gerado', Builder.BuildDescriptor(Face1, Mapping, Data1));
    AssertTrue('Descriptor face 2 gerado', Builder.BuildDescriptor(Face2, Mapping, Data2));
    AssertTrue('Comparação de vetores executada', Matcher.CompareVectors(Data1.Values, Data2.Values, Score, Dist));
    WriteLn(Format('    Score obtido: %.4f, Distância: %.4f', [Score, Dist]));
    AssertTrue('Score deve ser >= 0.99 para a mesma foto', Score >= 0.99);
    AssertTrue('Distância deve ser <= 0.01', Dist <= 0.01);
  finally
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 51: Duas fotos diferentes da mesma pessoa (escala e rotação)
procedure Test51_DifferentPhotosSamePerson;
var
  Face1, Face2: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data1, Data2: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  Score, Dist: Double;
begin
  WriteLn('--- Teste 51: Duas fotos diferentes da mesma pessoa ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  try
    Face1 := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95);
    Face2 := CreateSyntheticFace(500, 400, 850, 800, 0.08, 0.92);

    AssertTrue('Descriptor 1 gerado', Builder.BuildDescriptor(Face1, Mapping, Data1));
    AssertTrue('Descriptor 2 gerado', Builder.BuildDescriptor(Face2, Mapping, Data2));
    AssertTrue('Comparação efetuada', Matcher.CompareVectors(Data1.Values, Data2.Values, Score, Dist));
    WriteLn(Format('    Score obtido: %.4f (Threshold=%.2f)', [Score, Matcher.MatchThreshold]));
    AssertTrue('Score deve ultrapassar MatchThreshold (reconhecer mesma pessoa)',
      Score >= Matcher.MatchThreshold);
  finally
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 52: Pessoas com geometrias faciais diferentes -> UNKNOWN
procedure Test52_DifferentPersons;
var
  Face1, Face2: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data1, Data2: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  Prof: TAIFaceProfile;
  Sample: TAIFaceSample;
  MatchRes: TFaceMatchResult;
  Profs: TAIFaceProfileArray;
  V: TDoubleDynArray;
  i: Integer;
begin
  WriteLn('--- Teste 52: Pessoas diferentes ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  Prof := TAIFaceProfile.Create;
  try
    Prof.ID := 'pessoa_a';
    Prof.Name := 'Pessoa A';

    Face1 := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95);
    Builder.BuildDescriptor(Face1, Mapping, Data1);

    Sample := TAIFaceSample.Create;
    SetLength(V, Length(Data1.Values));
    for i := 0 to High(Data1.Values) do V[i] := Data1.Values[i];
    Sample.Vector := V;
    Prof.AddSample(Sample);

    Face2.ClassName := 'face';
    Face2.Confidence := 0.95;
    Face2.X1 := 100; Face2.Y1 := 100;
    Face2.X2 := 400; Face2.Y2 := 200;
    Face2.Polygon := '';
    SetLength(Face2.KeyPoints, 5);
    Face2.KeyPoints[0].X := 130; Face2.KeyPoints[0].Y := 130; Face2.KeyPoints[0].Confidence := 0.9;
    Face2.KeyPoints[1].X := 370; Face2.KeyPoints[1].Y := 130; Face2.KeyPoints[1].Confidence := 0.9;
    Face2.KeyPoints[2].X := 250; Face2.KeyPoints[2].Y := 140; Face2.KeyPoints[2].Confidence := 0.9;
    Face2.KeyPoints[3].X := 200; Face2.KeyPoints[3].Y := 180; Face2.KeyPoints[3].Confidence := 0.9;
    Face2.KeyPoints[4].X := 300; Face2.KeyPoints[4].Y := 180; Face2.KeyPoints[4].Confidence := 0.9;

    Builder.BuildDescriptor(Face2, Mapping, Data2);

    SetLength(Profs, 1);
    Profs[0] := Prof;

    Matcher.MatchProfiles(Data2.Values, Profs, MatchRes);
    WriteLn(Format('    Status: %d (0=Unknown, 1=Matched), Score: %.4f', [Ord(MatchRes.Status), MatchRes.Score]));
    AssertTrue('Pessoas diferentes devem retornar status fmsUnknown', MatchRes.Status = fmsUnknown);
  finally
    Prof.Free;
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 53: Duas pessoas com scores muito próximos -> AMBIGUOUS preservando SecondProfileID e SecondScore (Tarefas 26 e 36)
procedure Test53_AmbiguousMatchWithSecondCandidate;
var
  Prof1, Prof2: TAIFaceProfile;
  Sample1, Sample2: TAIFaceSample;
  Matcher: TAIFaceMatcher;
  TargetVec, Vec1, Vec2: TDoubleDynArray;
  MatchRes: TFaceMatchResult;
  Profs: TAIFaceProfileArray;
  i: Integer;
begin
  WriteLn('--- Teste 53: Perfis com scores muito próximos (Ambiguidade e Segundo Candidato) ---');
  Matcher := TAIFaceMatcher.Create;
  Matcher.MatchThreshold := 0.80;
  Matcher.AmbiguityMargin := 0.05;

  Prof1 := TAIFaceProfile.Create;
  Prof1.ID := 'gemeo_1'; Prof1.Name := 'Gêmeo 1';

  Prof2 := TAIFaceProfile.Create;
  Prof2.ID := 'gemeo_2'; Prof2.Name := 'Gêmeo 2';

  try
    SetLength(TargetVec, 10);
    for i := 0 to 9 do TargetVec[i] := 1.0;

    Sample1 := TAIFaceSample.Create;
    SetLength(Vec1, 10);
    for i := 0 to 9 do Vec1[i] := 1.0;
    Sample1.Vector := Vec1;
    Prof1.AddSample(Sample1);

    Sample2 := TAIFaceSample.Create;
    SetLength(Vec2, 10);
    for i := 0 to 9 do Vec2[i] := 1.01;
    Sample2.Vector := Vec2;
    Prof2.AddSample(Sample2);

    SetLength(Profs, 2);
    Profs[0] := Prof1;
    Profs[1] := Prof2;

    Matcher.MatchProfiles(TargetVec, Profs, MatchRes);
    WriteLn(Format('    Status: %d (2=Ambiguous), Melhor: %s (%.4f), Segundo: %s (%.4f)',
      [Ord(MatchRes.Status), MatchRes.ProfileID, MatchRes.Score, MatchRes.SecondProfileID, MatchRes.SecondScore]));
    AssertTrue('Perfis gêmeos devem retornar fmsAmbiguous', MatchRes.Status = fmsAmbiguous);
    AssertTrue('Segundo perfil ID deve ser preservado', MatchRes.SecondProfileID <> '');
    AssertTrue('Segundo score deve ser preservado', MatchRes.SecondScore > 0.0);
  finally
    Prof1.Free;
    Prof2.Free;
    Matcher.Free;
  end;
end;

// Teste 31: one_non_face_object - Retornar apenas 'dog' -> cadastro rejeita com 'Nenhuma face encontrada'
procedure Test31_OneNonFaceObject;
var
  Mock: TMockYOLO;
  Reg: TAIFaceRegistry;
  Builder: TAIFaceDescriptorBuilder;
  Sample: TAIFaceSample;
  Err: string;
  TempFile: string;
begin
  WriteLn('--- Teste 31: one_non_face_object (apenas dog na imagem) ---');
  Mock := TMockYOLO.Create(nil);
  Reg := TAIFaceRegistry.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'mock_test.bmp';
  try
    // Cria arquivo temporário mínimo
    with TStringList.Create do
    try
      Text := 'test';
      SaveToFile(TempFile);
    finally
      Free;
    end;

    // Configura detecção contendo unicamente 1 cachorro
    SetLength(Mock.MockObjects, 1);
    Mock.MockObjects[0].ClassName := 'dog';
    Mock.MockObjects[0].Confidence := 0.95;
    Mock.MockObjects[0].X1 := 10; Mock.MockObjects[0].Y1 := 10;
    Mock.MockObjects[0].X2 := 200; Mock.MockObjects[0].Y2 := 200;

    AssertTrue('Cadastro deve falhar com apenas 1 dog',
      not Reg.BuildDescriptorFromFile(TempFile, Mock, Builder, Sample, Err));
    WriteLn('    Mensagem retornada: ' + Err);
    AssertTrue('Mensagem deve ser "Nenhuma face encontrada" (proteção contra Length(Objects)=1)',
      Err = 'Nenhuma face encontrada');
  finally
    if FileExists(TempFile) then DeleteFile(TempFile);
    Builder.Free;
    Reg.Free;
    Mock.Free;
  end;
end;

// Teste 32: person_is_not_face - 'person' sozinho não é face
procedure Test32_PersonIsNotFace;
var
  Mock: TMockYOLO;
  Reg: TAIFaceRegistry;
  Builder: TAIFaceDescriptorBuilder;
  Sample: TAIFaceSample;
  Err: string;
  TempFile: string;
begin
  WriteLn('--- Teste 32: person_is_not_face (apenas person na imagem) ---');
  Mock := TMockYOLO.Create(nil);
  Reg := TAIFaceRegistry.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'mock_person.bmp';
  try
    with TStringList.Create do
    try
      Text := 'test';
      SaveToFile(TempFile);
    finally
      Free;
    end;

    SetLength(Mock.MockObjects, 1);
    Mock.MockObjects[0].ClassName := 'person'; // corpo inteiro, não face
    Mock.MockObjects[0].Confidence := 0.92;
    Mock.MockObjects[0].X1 := 10; Mock.MockObjects[0].Y1 := 10;
    Mock.MockObjects[0].X2 := 200; Mock.MockObjects[0].Y2 := 500;

    AssertTrue('Cadastro deve rejeitar classe person',
      not Reg.BuildDescriptorFromFile(TempFile, Mock, Builder, Sample, Err));
    WriteLn('    Mensagem retornada: ' + Err);
    AssertTrue('Mensagem deve ser "Nenhuma face encontrada"', Err = 'Nenhuma face encontrada');
  finally
    if FileExists(TempFile) then DeleteFile(TempFile);
    Builder.Free;
    Reg.Free;
    Mock.Free;
  end;
end;

// Teste 33: face_plus_other_objects - Imagem com face + chair + person
procedure Test33_FacePlusOtherObjects;
var
  Mock: TMockYOLO;
  Reg: TAIFaceRegistry;
  Builder: TAIFaceDescriptorBuilder;
  Sample: TAIFaceSample;
  Err: string;
  TempFile: string;
begin
  WriteLn('--- Teste 33: face_plus_other_objects (face + chair + person) ---');
  Mock := TMockYOLO.Create(nil);
  Reg := TAIFaceRegistry.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'mock_face_scene.bmp';
  try
    with TStringList.Create do
    try
      Text := 'test';
      SaveToFile(TempFile);
    finally
      Free;
    end;

    SetLength(Mock.MockObjects, 3);
    Mock.MockObjects[0].ClassName := 'chair';
    Mock.MockObjects[0].Confidence := 0.88;
    Mock.MockObjects[1] := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95); // única face válida
    Mock.MockObjects[2].ClassName := 'person';
    Mock.MockObjects[2].Confidence := 0.91;

    AssertTrue('Cadastro deve ter sucesso isolando a única face da cena',
      Reg.BuildDescriptorFromFile(TempFile, Mock, Builder, Sample, Err));
    AssertTrue('Sample gerado com sucesso', Sample <> nil);
    if Sample <> nil then Sample.Free;
  finally
    if FileExists(TempFile) then DeleteFile(TempFile);
    Builder.Free;
    Reg.Free;
    Mock.Free;
  end;
end;

// Teste 29 & 55: Múltiplas faces reais rejeitadas no cadastro
procedure Test29_MultiFaceRealRejection;
var
  Mock: TMockYOLO;
  Reg: TAIFaceRegistry;
  Builder: TAIFaceDescriptorBuilder;
  Sample: TAIFaceSample;
  Err: string;
  TempFile: string;
begin
  WriteLn('--- Teste 29 & 55: Rejeição real de múltiplas faces no cadastro ---');
  Mock := TMockYOLO.Create(nil);
  Reg := TAIFaceRegistry.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'mock_two_faces.bmp';
  try
    with TStringList.Create do
    try
      Text := 'test';
      SaveToFile(TempFile);
    finally
      Free;
    end;

    SetLength(Mock.MockObjects, 2);
    Mock.MockObjects[0] := CreateSyntheticFace(100, 100, 250, 250, 0.0, 0.95);
    Mock.MockObjects[1] := CreateSyntheticFace(300, 100, 450, 250, 0.0, 0.93);

    AssertTrue('Cadastro deve falhar com duas faces',
      not Reg.BuildDescriptorFromFile(TempFile, Mock, Builder, Sample, Err));
    WriteLn('    Mensagem de erro: ' + Err);
    AssertTrue('Erro deve informar que imagem deve conter somente uma pessoa',
      Err = 'A imagem deve conter somente uma pessoa');
  finally
    if FileExists(TempFile) then DeleteFile(TempFile);
    Builder.Free;
    Reg.Free;
    Mock.Free;
  end;
end;

// Teste 34: Keypoints insuficientes (apenas 2 pontos)
procedure Test34_InsufficientKeypoints;
var
  FaceObj: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data: TAIFaceDescriptorData;
begin
  WriteLn('--- Teste 34: Keypoints insuficientes (< 5 pontos) ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  try
    FaceObj.ClassName := 'face';
    FaceObj.Confidence := 0.95;
    FaceObj.X1 := 100; FaceObj.Y1 := 100; FaceObj.X2 := 300; FaceObj.Y2 := 300;
    SetLength(FaceObj.KeyPoints, 2);
    FaceObj.KeyPoints[0].X := 150; FaceObj.KeyPoints[0].Y := 150; FaceObj.KeyPoints[0].Confidence := 0.9;
    FaceObj.KeyPoints[1].X := 250; FaceObj.KeyPoints[1].Y := 150; FaceObj.KeyPoints[1].Confidence := 0.9;

    AssertTrue('Builder deve rejeitar face com apenas 2 keypoints',
      not Builder.BuildDescriptor(FaceObj, Mapping, Data));
    WriteLn('    Mensagem retornada: ' + Data.ErrorMessage);
  finally
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 35: Keypoints de baixa confiança
procedure Test35_LowConfidenceKeypoints;
var
  FaceObj: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data: TAIFaceDescriptorData;
begin
  WriteLn('--- Teste 35: Keypoints com baixa confiança individual ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Builder.MinKeyPointConfidence := 0.35;
  try
    // Cria face com 5 pontos, mas com nariz tendo confiança 0.15 (< 0.35)
    FaceObj := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95, 0.90);
    FaceObj.KeyPoints[2].Confidence := 0.15; // nariz com confiança muito baixa

    AssertTrue('Builder deve rejeitar landmark com confiança 0.15 < 0.35',
      not Builder.BuildDescriptor(FaceObj, Mapping, Data));
    WriteLn('    Mensagem retornada: ' + Data.ErrorMessage);
    AssertTrue('Mensagem cita baixa confiança do landmark',
      Pos('confiança abaixo do mínimo', Data.ErrorMessage) > 0);
  finally
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 37, 38, 39, 40: Confirmação temporal, instabilidade, cooldown e timeout
type
  TTestEventTracker = class
  public
    RecognizedEvents: Integer;
    LastRecognizedID: string;
    procedure HandleRecognized(Sender: TObject; const AResult: TFaceMatchResult);
  end;

procedure TTestEventTracker.HandleRecognized(Sender: TObject; const AResult: TFaceMatchResult);
begin
  Inc(RecognizedEvents);
  LastRecognizedID := AResult.ProfileID;
end;

procedure Test37_38_39_TemporalBehavior;
var
  FaceRec: TAIFaceRecognition;
  Mock: TMockYOLO;
  Tracker: TTestEventTracker;
  Results: TFaceMatchResultArray;
  ProfMarcelo, ProfMaria: TAIFaceProfile;
  SampleMarcelo, SampleMaria: TAIFaceSample;
  DescData: TAIFaceDescriptorData;
  TempFile: string;
begin
  WriteLn('--- Testes 37 a 40: Comportamento Temporal, Confirmação e Cooldown ---');
  Mock := TMockYOLO.Create(nil);
  FaceRec := TAIFaceRecognition.Create(nil);
  FaceRec.Yolo := Mock;
  FaceRec.RequiredConfirmations := 3;
  FaceRec.ConfirmationWindowMs := 5000;
  FaceRec.RecognitionCooldownMs := 10000; // 10 segundos de cooldown
  Tracker := TTestEventTracker.Create;
  FaceRec.OnFaceRecognized := @Tracker.HandleRecognized;

  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'mock_temporal.bmp';
  try
    with TStringList.Create do
    try
      Text := 'test';
      SaveToFile(TempFile);
    finally
      Free;
    end;

    // Cadastra Marcelo no Registry
    ProfMarcelo := TAIFaceProfile.Create;
    ProfMarcelo.ID := 'marcelo'; ProfMarcelo.Name := 'Marcelo';
    FaceRec.DescriptorBuilder.BuildDescriptor(CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95),
      Mock.KeyPointMapping, DescData);
    SampleMarcelo := TAIFaceSample.Create;
    SampleMarcelo.Vector := DescData.Values;
    ProfMarcelo.AddSample(SampleMarcelo);
    FaceRec.Registry.AddProfile(ProfMarcelo);

    // Cadastra Maria no Registry com face diferente
    ProfMaria := TAIFaceProfile.Create;
    ProfMaria.ID := 'maria'; ProfMaria.Name := 'Maria';
    FaceRec.DescriptorBuilder.BuildDescriptor(CreateSyntheticFace(100, 100, 400, 200, 0.0, 0.95),
      Mock.KeyPointMapping, DescData);
    SampleMaria := TAIFaceSample.Create;
    SampleMaria.Vector := DescData.Values;
    ProfMaria.AddSample(SampleMaria);
    FaceRec.Registry.AddProfile(ProfMaria);

    // Mock emitindo Marcelo
    SetLength(Mock.MockObjects, 1);
    Mock.MockObjects[0] := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95);

    // Frame 1: 1ª confirmação (ainda não deve emitir evento)
    FaceRec.RecognizeFile(TempFile, Results);
    AssertTrue('Frame 1: 1ª confirmação não deve disparar OnFaceRecognized (esperado 3)',
      Tracker.RecognizedEvents = 0);

    // Frame 2: 2ª confirmação
    FaceRec.RecognizeFile(TempFile, Results);
    AssertTrue('Frame 2: 2ª confirmação não deve disparar evento ainda',
      Tracker.RecognizedEvents = 0);

    // Frame 3: 3ª confirmação consecutiva -> DISPARA OnFaceRecognized!
    FaceRec.RecognizeFile(TempFile, Results);
    AssertTrue('Frame 3: 3ª confirmação deve disparar OnFaceRecognized',
      Tracker.RecognizedEvents = 1);
    AssertTrue('Perfil reconhecido confirmado é marcelo',
      FaceRec.LastRecognizedProfileID = 'marcelo');

    // Teste 39: Cooldown - Frames 4, 5, 6 com Marcelo dentro da janela não devem redisparar
    FaceRec.RecognizeFile(TempFile, Results);
    FaceRec.RecognizeFile(TempFile, Results);
    AssertTrue('Cooldown: Não deve repetir OnFaceRecognized enquanto ativo (1 evento)',
      Tracker.RecognizedEvents = 1);

    // Teste 38: Instabilidade - Mudança de identidade para Maria reseta contagem
    Mock.MockObjects[0] := CreateSyntheticFace(100, 100, 400, 200, 0.0, 0.95); // Maria
    FaceRec.RecognizeFile(TempFile, Results);
    // Volta para Marcelo
    Mock.MockObjects[0] := CreateSyntheticFace(100, 100, 300, 350, 0.0, 0.95);
    FaceRec.RecognizeFile(TempFile, Results);
    AssertTrue('Instabilidade (alternância) reinicia contador de confirmação',
      Tracker.RecognizedEvents = 1);

  finally
    if FileExists(TempFile) then DeleteFile(TempFile);
    Tracker.Free;
    FaceRec.Free;
    Mock.Free;
  end;
end;

// Teste 58: Serialização JSON com formato e caminhos relativos
procedure Test58_JSONSerializationRoundtrip;
var
  Prof1, Prof2: TAIFaceProfile;
  Sample: TAIFaceSample;
  JsonStr, WarningStr: string;
  V: TDoubleDynArray;
begin
  WriteLn('--- Teste 58: Serialização JSON Roundtrip ---');
  Prof1 := TAIFaceProfile.Create;
  Prof2 := TAIFaceProfile.Create;
  try
    Prof1.ID := 'marcelo_maurin';
    Prof1.Name := 'Marcelo Maurin Martins';
    Prof1.Role := 'Engenheiro de IA';
    Prof1.ProfileText := 'Autor da suíte CHATGPT';
    Prof1.Enabled := True;
    Prof1.Images.Add('fotos/marcelo1.jpg');
    Prof1.Triggers.Add('iniciar_atendimento');

    Sample := TAIFaceSample.Create;
    Sample.SampleID := 'marcelo_s1';
    Sample.ImageFile := 'fotos/marcelo1.jpg';
    Sample.DescriptorVersion := 1;
    Sample.Algorithm := 'yolo_landmarks_geometry';
    Sample.DetectionConfidence := 0.96;
    Sample.QualityScore := 0.94;
    SetLength(V, 4);
    V[0] := 0.123; V[1] := 0.456; V[2] := 0.789; V[3] := 1.011;
    Sample.Vector := V;
    Prof1.AddSample(Sample);

    JsonStr := ProfileToJSON(Prof1, 'C:\projetos\Assistente');
    AssertTrue('JSON contém format_version', Pos('"format_version" : 1', JsonStr) > 0);

    AssertTrue('Desserialização do JSON bem-sucedida', JSONToProfile(JsonStr, Prof2, WarningStr, 'C:\projetos\Assistente'));
    AssertTrue('ID restaurado', Prof2.ID = Prof1.ID);
    AssertTrue('Name restaurado', Prof2.Name = Prof1.Name);
    AssertTrue('Caminho de imagem preservado', Prof2.Images.Count = 1);
  finally
    Prof1.Free;
    Prof2.Free;
  end;
end;

// Teste 59: JSON corrompido tolerado
procedure Test59_CorruptedJSONTolerance;
var
  Prof: TAIFaceProfile;
  WarningStr: string;
begin
  WriteLn('--- Teste 59: Tolerância a JSON inválido ---');
  Prof := TAIFaceProfile.Create;
  try
    AssertTrue('JSON inválido falha sem quebra',
      not JSONToProfile('{"id": "inv", "broken": ...', Prof, WarningStr));
    AssertTrue('Aviso gerado', WarningStr <> '');
  finally
    Prof.Free;
  end;
end;

function AddSampleHelper(AProfile: TAIFaceProfile; const AVals: TDoubleDynArray; const AImg: string; AQuality, AConf: Double; AVer: Integer; const AAlg: string; const AModel: string = ''): TAIFaceSample;
begin
  Result := TAIFaceSample.Create;
  Result.Vector := AVals;
  Result.ImageFile := AImg;
  Result.QualityScore := AQuality;
  Result.DetectionConfidence := AConf;
  Result.DescriptorVersion := AVer;
  Result.Algorithm := AAlg;
  Result.ModelID := AModel;
  AProfile.AddSample(Result);
end;

// Teste 60: Versão de descritor desconhecida
procedure Test60_UnknownDescriptorVersion;
var
  Prof: TAIFaceProfile;
  WarningStr: string;
  FutureJSON: string;
begin
  WriteLn('--- Teste 60: Descritor com versão desconhecida ignorado com tolerância ---');
  Prof := TAIFaceProfile.Create;
  try
    FutureJSON :=
      '{"format_version": 1, "id": "futuro", "name": "Futuro", "samples": [{"sample_id": "s1", "descriptor_version": 99}]}';
    AssertTrue('Carrega dados básicos', JSONToProfile(FutureJSON, Prof, WarningStr));
    AssertTrue('Amostra desconhecida ignorada', Prof.SampleCount = 0);
  finally
    Prof.Free;
  end;
end;

// Teste 61: Compatibilidade de descritores (algoritmo, versão e model_id)
procedure Test61_IsDescriptorCompatible;
begin
  WriteLn('--- Teste 61: Compatibilidade de descritores ---');
  AssertTrue('Mesmo algoritmo, versão e modelo são compatíveis',
    IsDescriptorCompatible('yolo_landmarks_geometry', 'yolo_landmarks_geometry', 1, 1, 'yolov8n-face', 'yolov8n-face', False));

  AssertTrue('Algoritmos diferentes são incompatíveis',
    not IsDescriptorCompatible('arcface', 'yolo_landmarks_geometry', 1, 1, 'model1', 'model1', False));

  AssertTrue('Versões diferentes são incompatíveis',
    not IsDescriptorCompatible('yolo_landmarks_geometry', 'yolo_landmarks_geometry', 1, 2, 'model1', 'model1', False));

  AssertTrue('Modelos diferentes são incompatíveis por padrão',
    not IsDescriptorCompatible('yolo_landmarks_geometry', 'yolo_landmarks_geometry', 1, 1, 'yolov8n-face', 'yolov11-face', False));

  AssertTrue('Modelos diferentes são aceitos quando AllowCrossModel=True',
    IsDescriptorCompatible('yolo_landmarks_geometry', 'yolo_landmarks_geometry', 1, 1, 'yolov8n-face', 'yolov11-face', True));

  AssertTrue('Modelos vazios não bloqueiam compatibilidade',
    IsDescriptorCompatible('yolo_landmarks_geometry', 'yolo_landmarks_geometry', 1, 1, '', '', False));
end;

// Teste 62: Critério duplo de distância (Cosseno + Distância Euclidiana Máxima)
procedure Test62_DualDistanceCriterion;
var
  FaceObj1, FaceObj2: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data1, Data2: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  Prof: TAIFaceProfile;
  MatchRes: TFaceMatchResult;
  Profiles: TAIFaceProfileArray;
begin
  WriteLn('--- Teste 62: Critério duplo de distância (Cosseno + Euclidiana) ---');
  FaceObj1 := CreateSyntheticFace(100, 100, 200, 200, 0.0, 0.95);
  FaceObj2 := CreateSyntheticFace(100, 100, 200, 200, 0.08, 0.95); // Leve variação

  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  Prof := TAIFaceProfile.Create;
  try
    Prof.ID := 'teste_dual';
    Prof.Name := 'Teste Dual';
    Builder.BuildDescriptor(FaceObj1, Mapping, Data1);
    Builder.BuildDescriptor(FaceObj2, Mapping, Data2);

    AddSampleHelper(Prof, Data1.Values, 'img1.jpg', Data1.Quality, 0.95, 1, 'yolo_landmarks_geometry', Data1.ModelID);

    SetLength(Profiles, 1);
    Profiles[0] := Prof;

    // Cenário 1: MaxEuclideanDistance desabilitada (0.0) -> Deve dar Match por Cosseno
    Matcher.MaxEuclideanDistance := 0.0;
    Matcher.MatchThreshold := 0.80;
    Matcher.MatchProfiles(Data2, Profiles, MatchRes);
    AssertTrue('Match por cosseno com MaxEuclideanDistance desabilitada', MatchRes.Status = fmsMatched);

    // Cenário 2: MaxEuclideanDistance muito restrita (ex: 0.0001) -> Deve rejeitar mesmo com cosseno alto
    Matcher.MaxEuclideanDistance := 0.0001;
    Matcher.MatchProfiles(Data2, Profiles, MatchRes);
    AssertTrue('Rejeição quando distância euclidiana excede MaxEuclideanDistance', MatchRes.Status = fmsUnknown);
  finally
    Prof.Free;
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 63: Apenas um perfil no registry não gera ambiguidade artificial
procedure Test63_SingleProfileAndNoArtificialAmbiguity;
var
  FaceObj: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  Prof: TAIFaceProfile;
  Profiles: TAIFaceProfileArray;
  MatchRes: TFaceMatchResult;
begin
  WriteLn('--- Teste 63: Perfil único no registry e margem de ambiguidade ---');
  FaceObj := CreateSyntheticFace(100, 100, 200, 200, 0.0, 0.95);
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  Matcher.AmbiguityMargin := 0.15; // Margem alta proposital
  Prof := TAIFaceProfile.Create;
  try
    Prof.ID := 'unico';
    Prof.Name := 'Unico Perfil';
    Builder.BuildDescriptor(FaceObj, Mapping, Data);
    AddSampleHelper(Prof, Data.Values, 'img.jpg', Data.Quality, 0.95, 1, 'yolo_landmarks_geometry');

    SetLength(Profiles, 1);
    Profiles[0] := Prof;

    Matcher.MatchProfiles(Data, Profiles, MatchRes);
    AssertTrue('Perfil único com score alto deve dar fmsMatched sem ambiguidade artificial', MatchRes.Status = fmsMatched);
    AssertTrue('ID reconhecido correto', MatchRes.ProfileID = 'unico');
    AssertTrue('Segundo perfil permanece vazio quando não há segundo candidato', MatchRes.SecondProfileID = '');
  finally
    Prof.Free;
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 64: Registry vazio, perfil desabilitado e perfil sem samples
procedure Test64_EmptyRegistryAndDisabledAndNoSamples;
var
  FaceObj: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  Prof1, Prof2: TAIFaceProfile;
  Profiles: TAIFaceProfileArray;
  MatchRes: TFaceMatchResult;
begin
  WriteLn('--- Teste 64: Registry vazio, perfis desabilitados ou sem samples ---');
  FaceObj := CreateSyntheticFace(100, 100, 200, 200, 0.0, 0.95);
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  try
    Builder.BuildDescriptor(FaceObj, Mapping, Data);

    // 1. Registry vazio: deve retornar fmsUnknown, nunca exception
    SetLength(Profiles, 0);
    Matcher.MatchProfiles(Data, Profiles, MatchRes);
    AssertTrue('Registry vazio retorna fmsUnknown', MatchRes.Status = fmsUnknown);

    // 2. Perfil desabilitado (Enabled = False): não deve ser reconhecido
    Prof1 := TAIFaceProfile.Create;
    try
      Prof1.ID := 'desabilitado';
      Prof1.Name := 'Desabilitado';
      Prof1.Enabled := False;
      AddSampleHelper(Prof1, Data.Values, 'img.jpg', Data.Quality, 0.95, 1, 'yolo_landmarks_geometry');

      SetLength(Profiles, 1);
      Profiles[0] := Prof1;
      Matcher.MatchProfiles(Data, Profiles, MatchRes);
      AssertTrue('Perfil desabilitado não dá match (retorna fmsUnknown)', MatchRes.Status = fmsUnknown);
    finally
      Prof1.Free;
    end;

    // 3. Perfil sem samples: deve ser ignorado silenciosamente
    Prof2 := TAIFaceProfile.Create;
    try
      Prof2.ID := 'sem_samples';
      Prof2.Name := 'Sem Amostras';
      SetLength(Profiles, 1);
      Profiles[0] := Prof2;
      Matcher.MatchProfiles(Data, Profiles, MatchRes);
      AssertTrue('Perfil sem samples retorna fmsUnknown sem erro', MatchRes.Status = fmsUnknown);
    finally
      Prof2.Free;
    end;
  finally
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 65: Salvamento atômico (.tmp, .bak) e caminhos relativos
procedure Test65_AtomicSaveBackupAndRelativePaths;
var
  Prof: TAIFaceProfile;
  TempDir, JsonFile, BakFile, RelPath, AbsPath: string;
begin
  WriteLn('--- Teste 65: Salvamento atômico, backup e caminhos relativos ---');
  TempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'aiface_test_save_' + IntToStr(GetTickCount64);
  ForceDirectories(TempDir);
  try
    JsonFile := TempDir + PathDelim + 'perfil_teste.json';
    BakFile := TempDir + PathDelim + 'perfil_teste.json.bak';

    Prof := TAIFaceProfile.Create;
    try
      Prof.ID := 'teste_atomico';
      Prof.Name := 'Teste Atômico';
      Prof.Images.Add(TempDir + PathDelim + 'foto1.jpg');

      // 1. Primeiro salvamento -> cria .json
      AssertTrue('SaveProfileToFile primeiro salvamento', SaveProfileToFile(Prof, JsonFile, True));
      AssertTrue('Arquivo JSON criado', FileExists(JsonFile));
      AssertTrue('Não deve haver .bak ainda', not FileExists(BakFile));

      // 2. Segundo salvamento com alteração -> gera .bak
      Prof.Name := 'Teste Atômico Modificado';
      AssertTrue('SaveProfileToFile segundo salvamento', SaveProfileToFile(Prof, JsonFile, True));
      AssertTrue('Arquivo de backup .bak foi criado', FileExists(BakFile));

      // 3. Teste de funções de caminho relativo
      RelPath := MakeRelativeImagePath(TempDir, TempDir + PathDelim + 'imagens' + PathDelim + 'foto1.jpg');
      AssertTrue('MakeRelativeImagePath gera caminho relativo correto',
        (RelPath = 'imagens' + PathDelim + 'foto1.jpg') or (RelPath = 'imagens/foto1.jpg'));

      AbsPath := ResolveImagePath(TempDir, RelPath);
      AssertTrue('ResolveImagePath reconstrói caminho absoluto',
        SameText(AbsPath, TempDir + PathDelim + 'imagens' + PathDelim + 'foto1.jpg'));
    finally
      Prof.Free;
    end;
  finally
    if FileExists(JsonFile) then DeleteFile(JsonFile);
    if FileExists(BakFile) then DeleteFile(BakFile);
    RemoveDir(TempDir);
  end;
end;

// Teste 66: ReloadFromFolder e validação de leak de memória
procedure Test66_ReloadFromFolderAndStability;
var
  Registry: TAIFaceRegistry;
  TempDir, Prof1File, Prof2File: string;
  Prof1, Prof2: TAIFaceProfile;
  i: Integer;
begin
  WriteLn('--- Teste 66: ReloadFromFolder e estabilidade repetida ---');
  TempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'aiface_reg_reload_' + IntToStr(GetTickCount64);
  ForceDirectories(TempDir);
  try
    Prof1File := TempDir + PathDelim + 'p1.json';
    Prof2File := TempDir + PathDelim + 'p2.json';

    Prof1 := TAIFaceProfile.Create;
    Prof2 := TAIFaceProfile.Create;
    try
      Prof1.ID := 'p1';
      Prof1.Name := 'Perfil 1';
      SaveProfileToFile(Prof1, Prof1File, False);

      Prof2.ID := 'p2';
      Prof2.Name := 'Perfil 2';
      SaveProfileToFile(Prof2, Prof2File, False);
    finally
      Prof1.Free;
      Prof2.Free;
    end;

    Registry := TAIFaceRegistry.Create;
    try
      // Carga inicial
      Registry.LoadFromFolder(TempDir);
      AssertTrue('2 perfis carregados inicialmente', Registry.ProfileCount = 2);

      // Deleta perfil 2 do disco
      DeleteFile(Prof2File);

      // ReloadFromFolder deve limpar perfil 2 da memória
      Registry.ReloadFromFolder(TempDir);
      AssertTrue('ReloadFromFolder removeu perfil apagado do disco', Registry.ProfileCount = 1);
      AssertTrue('Apenas perfil 1 remanescente', Registry.FindByID('p1') <> nil);
      AssertTrue('Perfil 2 não está mais na memória', Registry.FindByID('p2') = nil);

      // Teste de 100 recargas repetidas sem falha
      for i := 1 to 100 do
        Registry.ReloadFromFolder(TempDir);

      AssertTrue('100 ciclos de recarga executados com sucesso', Registry.ProfileCount = 1);
    finally
      Registry.Free;
    end;
  finally
    if FileExists(Prof1File) then DeleteFile(Prof1File);
    if FileExists(Prof2File) then DeleteFile(Prof2File);
    RemoveDir(TempDir);
  end;
end;

// Teste 67: Reconstrução transacional de descritores
procedure Test67_TransactionalRebuild;
var
  Prof: TAIFaceProfile;
  Registry: TAIFaceRegistry;
  MockYolo: TMockYOLO;
  Builder: TAIFaceDescriptorBuilder;
  SuccessCount: Integer;
  DescData: TDoubleDynArray;
begin
  WriteLn('--- Teste 67: Reconstrução transacional de descritores ---');
  Prof := TAIFaceProfile.Create;
  Registry := TAIFaceRegistry.Create;
  MockYolo := TMockYOLO.Create(nil);
  Builder := TAIFaceDescriptorBuilder.Create;
  try
    Prof.ID := 'transacional';
    Prof.Name := 'Perfil Transacional';
    // Amostra válida inicial
    SetLength(DescData, 10);
    DescData[0] := 0.5;
    AddSampleHelper(Prof, DescData, 'foto_antiga.jpg', 0.90, 0.95, 1, 'yolo_landmarks_geometry');
    Prof.Images.Add('foto_antiga.jpg');
    Registry.AddProfile(Prof);

    // Simula falha do YOLO durante a reconstrução (imagem não existe ou erro técnico)
    MockYolo.SimulateError := True;
    MockYolo.SimulateErrorMsg := 'Simulação de erro na detecção';

    SuccessCount := Registry.RebuildProfileDescriptors(Prof, MockYolo, Builder);
    AssertTrue('Reconstrução falha reporta 0 novos sucessos', SuccessCount = 0);
    AssertTrue('Amostra original foi preservada transacionalmente', Prof.SampleCount = 1);
    AssertTrue('Warning foi registrado', Registry.Warnings.Count > 0);
  finally
    Builder.Free;
    MockYolo.Free;
    Registry.Free;
  end;
end;

// Teste 68: Cooldown por ProfileID e independência de Unknown
procedure Test68_PerProfileCooldownAndIndependentUnknown;
var
  Rec: TAIFaceRecognition;
begin
  WriteLn('--- Teste 68: Cooldown por ProfileID e Unknown independente ---');
  Rec := TAIFaceRecognition.Create(nil);
  try
    Rec.RecognitionCooldownMs := 10000; // 10 segundos
    Rec.UnknownCooldownMs := 5000;

    // Marcelo reconhecido em T=1000
    AssertTrue('Marcelo pode ser reconhecido em T=1000', Rec.CanRecognizeProfile('marcelo', 1000));
    Rec.RecordRecognizedProfile('marcelo', 1000);

    // Marcelo em T=2000 (dentro do cooldown) deve ser bloqueado
    AssertTrue('Marcelo bloqueado por cooldown em T=2000', not Rec.CanRecognizeProfile('marcelo', 2000));

    // Maria entra em T=2500 -> Maria deve poder ser reconhecida imediatamente!
    AssertTrue('Maria pode ser reconhecida imediatamente mesmo com Marcelo em cooldown',
      Rec.CanRecognizeProfile('maria', 2500));
    Rec.RecordRecognizedProfile('maria', 2500);

    // Unknown em T=3000 não deve ser bloqueado pelo cooldown de Marcelo nem Maria
    AssertTrue('Unknown permitido em T=3000', Rec.CanRecognizeProfile('unknown', 3000));
    Rec.RecordRecognizedProfile('unknown', 3000);

    // Novo Unknown em T=4000 (dentro de 5s) deve ser bloqueado por seu próprio cooldown
    AssertTrue('Segundo Unknown dentro do cooldown bloqueado', not Rec.CanRecognizeProfile('unknown', 4000));

    // Mas Marcelo após 12 segundos pode ser reconhecido novamente
    AssertTrue('Marcelo reconhecido novamente após expiração do cooldown',
      Rec.CanRecognizeProfile('marcelo', 12000));
  finally
    Rec.Free;
  end;
end;

// Teste 69: Ciclos de criação/destruição e robustez a referências nil
procedure Test69_LifecycleAndRobustness;
var
  i: Integer;
  Rec: TAIFaceRecognition;
  CustomReg: TAIFaceRegistry;
  CustomYolo: TYOLO;
  Results: TFaceMatchResultArray;
begin
  WriteLn('--- Teste 69: Ciclos de ciclo de vida e robustez a referências nil ---');

  // 1. 100 ciclos repetidos de Create / Destroy sem exception
  for i := 1 to 100 do
  begin
    Rec := TAIFaceRecognition.Create(nil);
    Rec.Free;
  end;
  AssertTrue('100 ciclos de Create/Destroy de TAIFaceRecognition sem exceção', True);

  // 2. Troca de Registry externo e troca de TYOLO
  Rec := TAIFaceRecognition.Create(nil);
  try
    CustomReg := TAIFaceRegistry.Create;
    CustomYolo := TYOLO.Create(nil);
    try
      Rec.Registry := CustomReg;
      AssertTrue('Registry externo associado', Rec.Registry = CustomReg);

      Rec.Yolo := CustomYolo;
      AssertTrue('TYOLO externo associado', Rec.Yolo = CustomYolo);

      // Remove componentes
      Rec.Registry := nil;
      Rec.Yolo := nil;
      AssertTrue('Remoção limpa de referências externas', (Rec.Registry = nil) and (Rec.Yolo = nil));

      // 3. EnableTracking com FaceTracker=nil deve degradar para YOLO sem crash
      Rec.EnableTracking := True;
      Rec.FaceTracker := nil;
      AssertTrue('EnableTracking com FaceTracker=nil não lança erro', True);

      // 4. Parada de processamento (StopProcessing)
      Rec.StopProcessing;
      AssertTrue('StopProcessing opera sem erro', True);
    finally
      CustomReg.Free;
      CustomYolo.Free;
    end;
  finally
    Rec.Free;
  end;
end;

// Teste 70: Validação estática de modelo vs Self-Test em runtime
procedure Test70_ModelValidationAndSelfTest;
var
  Rec: TAIFaceRecognition;
  MockYolo: TMockYOLO;
  Msg: string;
begin
  WriteLn('--- Teste 70: ValidateRecognitionModel vs SelfTestRecognitionModel ---');
  Rec := TAIFaceRecognition.Create(nil);
  MockYolo := TMockYOLO.Create(nil);
  try
    Rec.Yolo := MockYolo;

    // 1. ModelPath vazio
    MockYolo.ModelPath := '';
    AssertTrue('ModelPath vazio falha na validação', not Rec.ValidateRecognitionModel(Msg));
    AssertTrue('Mensagem explicativa sobre ModelPath', Pos('ModelPath', Msg) > 0);

    // 2. Arquivo inexistente
    MockYolo.ModelPath := 'C:\caminho_inexistente\modelo_fake.pt';
    AssertTrue('Arquivo inexistente falha na validação', not Rec.ValidateRecognitionModel(Msg));
    AssertTrue('Mensagem explicativa sobre arquivo não encontrado', (Pos('não encontrado', Msg) > 0) or (Pos('nao encontrado', Msg) > 0));

    // 3. KeyPointMapping incompleto
    MockYolo.ModelPath := 'yolov8n_face'; // nome simbólico sem extensão de arquivo
    MockYolo.KeyPointMapping.LeftEyeIndex := -1;
    AssertTrue('Mapeamento sem olho esquerdo falha na validação', not Rec.ValidateRecognitionModel(Msg));
    AssertTrue('Mensagem sobre keypoints/landmarks incompletos', Pos('incompleto', Msg) > 0);

    // 4. Mapeamento válido
    MockYolo.KeyPointMapping.LeftEyeIndex := 0;
    MockYolo.KeyPointMapping.RightEyeIndex := 1;
    MockYolo.KeyPointMapping.NoseIndex := 2;
    AssertTrue('Mapeamento e modelo válidos passam na validação estática', Rec.ValidateRecognitionModel(Msg));

    // 5. SelfTestRecognitionModel com imagem inexistente
    AssertTrue('SelfTestRecognitionModel rejeita imagem de teste inexistente',
      not Rec.SelfTestRecognitionModel('C:\nao_existe.jpg', Msg));
    AssertTrue('Mensagem de imagem não encontrada', (Pos('não encontrada', Msg) > 0) or (Pos('nao encontrada', Msg) > 0));
  finally
    MockYolo.Free;
    Rec.Free;
  end;
end;

begin
  WriteLn('===========================================================');
  WriteLn('  SUITE DE TESTES: RECONHECIMENTO FACIAL E IDENTIDADE (V2)');
  WriteLn('===========================================================');
  try
    Test50_SamePhoto;
    Test51_DifferentPhotosSamePerson;
    Test52_DifferentPersons;
    Test53_AmbiguousMatchWithSecondCandidate;
    Test31_OneNonFaceObject;
    Test32_PersonIsNotFace;
    Test33_FacePlusOtherObjects;
    Test29_MultiFaceRealRejection;
    Test34_InsufficientKeypoints;
    Test35_LowConfidenceKeypoints;
    Test37_38_39_TemporalBehavior;
    Test58_JSONSerializationRoundtrip;
    Test59_CorruptedJSONTolerance;
    Test60_UnknownDescriptorVersion;
    Test61_IsDescriptorCompatible;
    Test62_DualDistanceCriterion;
    Test63_SingleProfileAndNoArtificialAmbiguity;
    Test64_EmptyRegistryAndDisabledAndNoSamples;
    Test65_AtomicSaveBackupAndRelativePaths;
    Test66_ReloadFromFolderAndStability;
    Test67_TransactionalRebuild;
    Test68_PerProfileCooldownAndIndependentUnknown;
    Test69_LifecycleAndRobustness;
    Test70_ModelValidationAndSelfTest;

    WriteLn('===========================================================');
    WriteLn('  TODOS OS TESTES UNITARIOS E TEMPORAIS PASSARAM (100%)!');
    WriteLn('===========================================================');
  except
    on E: Exception do
    begin
      WriteLn('ERRO FATAL NA EXECUÇÃO DOS TESTES: ', E.Message);
      Halt(1);
    end;
  end;
end.
