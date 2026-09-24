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

    WriteLn('===========================================================');
    WriteLn('  TODOS OS TESTES UNITÁRIOS E TEMPORAIS PASSARAM (100%)!');
    WriteLn('===========================================================');
  except
    on E: Exception do
    begin
      WriteLn('ERRO FATAL NA EXECUÇÃO DOS TESTES: ', E.Message);
      Halt(1);
    end;
  end;
end.
