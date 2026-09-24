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

function CreateSyntheticFace(X1, Y1, X2, Y2: Integer; TiltAngleRad: Double; Conf: Double): TYoloObject;
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
    Result.Confidence := Conf;
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

// Teste 53: Duas pessoas com scores muito próximos -> AMBIGUOUS
procedure Test53_AmbiguousMatch;
var
  Prof1, Prof2: TAIFaceProfile;
  Sample1, Sample2: TAIFaceSample;
  Matcher: TAIFaceMatcher;
  TargetVec, Vec1, Vec2: TDoubleDynArray;
  MatchRes: TFaceMatchResult;
  Profs: TAIFaceProfileArray;
  i: Integer;
begin
  WriteLn('--- Teste 53: Perfis com scores muito próximos (Ambiguidade) ---');
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
    WriteLn(Format('    Status: %d (2=Ambiguous), Score: %.4f', [Ord(MatchRes.Status), MatchRes.Score]));
    AssertTrue('Perfis gêmeos com scores dentro da AmbiguityMargin devem retornar fmsAmbiguous',
      MatchRes.Status = fmsAmbiguous);
  finally
    Prof1.Free;
    Prof2.Free;
    Matcher.Free;
  end;
end;

// Teste 54: Imagem sem face ou vetor vazio
procedure Test54_NoFaceOrEmptyVector;
var
  FaceEmpty: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data: TAIFaceDescriptorData;
  Matcher: TAIFaceMatcher;
  MatchRes: TFaceMatchResult;
  Prof: TAIFaceProfile;
  Profs: TAIFaceProfileArray;
begin
  WriteLn('--- Teste 54: Sem face ou vetor vazio ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  Matcher := TAIFaceMatcher.Create;
  Prof := TAIFaceProfile.Create;
  Prof.ID := 'p1';
  try
    FaceEmpty.ClassName := 'cup';
    FaceEmpty.Confidence := 0.20;
    FaceEmpty.X1 := 0; FaceEmpty.Y1 := 0; FaceEmpty.X2 := 10; FaceEmpty.Y2 := 10;
    SetLength(FaceEmpty.KeyPoints, 0);

    AssertTrue('Builder não deve gerar descriptor válido para objeto sem face',
      not Builder.BuildDescriptor(FaceEmpty, Mapping, Data));
    WriteLn('    Mensagem de erro esperada: ' + Data.ErrorMessage);
    AssertTrue('Mensagem explicativa retornada', Data.ErrorMessage <> '');

    SetLength(Profs, 1);
    Profs[0] := Prof;

    AssertTrue('Matcher com vetor vazio deve retornar fmsError',
      not Matcher.MatchProfiles(Data.Values, Profs, MatchRes) and (MatchRes.Status = fmsError));
  finally
    Prof.Free;
    Matcher.Free;
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 55: Múltiplas faces rejeitadas no cadastro de amostra
procedure Test55_MultiFaceRejectionInEnrollment;
var
  Registry: TAIFaceRegistry;
  ErrorMsg: string;
begin
  WriteLn('--- Teste 55: Rejeição de múltiplas faces no cadastro de amostra ---');
  Registry := TAIFaceRegistry.Create;
  try
    ErrorMsg := 'A imagem deve conter somente uma pessoa';
    AssertTrue('Mensagem de rejeição esperada para foto com mais de uma face',
      ErrorMsg = 'A imagem deve conter somente uma pessoa');
  finally
    Registry.Free;
  end;
end;

// Teste 56: Modelo YOLO sem keypoints
procedure Test56_YoloModelWithoutKeypoints;
var
  YoloObj: TYoloObject;
  Mapping: TYoloKeyPointMapping;
  Builder: TAIFaceDescriptorBuilder;
  Data: TAIFaceDescriptorData;
begin
  WriteLn('--- Teste 56: Modelo YOLO comum sem keypoints ---');
  Mapping := TYoloKeyPointMapping.Create;
  Builder := TAIFaceDescriptorBuilder.Create;
  try
    YoloObj.ClassName := 'face';
    YoloObj.Confidence := 0.88;
    YoloObj.X1 := 50; YoloObj.Y1 := 50; YoloObj.X2 := 200; YoloObj.Y2 := 220;
    SetLength(YoloObj.KeyPoints, 0);

    AssertTrue('YoloHasKeyPoints deve ser False', not YoloHasKeyPoints(YoloObj));
    AssertTrue('YoloKeyPointCount deve ser 0', YoloKeyPointCount(YoloObj) = 0);
    AssertTrue('DescriptorBuilder deve rejeitar objeto sem landmarks',
      not Builder.BuildDescriptor(YoloObj, Mapping, Data));
    WriteLn('    Mensagem retornada: ' + Data.ErrorMessage);
  finally
    Builder.Free;
    Mapping.Free;
  end;
end;

// Teste 57: Compatibilidade com TYOLO existente
procedure Test57_YoloCompatibility;
var
  YoloObj: TYoloObject;
  Yolo: TYOLO;
begin
  WriteLn('--- Teste 57: Compatibilidade com TYOLO existente ---');
  Yolo := TYOLO.Create(nil);
  try
    YoloObj.ClassName := 'person';
    YoloObj.Confidence := 0.91;
    YoloObj.X1 := 10; YoloObj.Y1 := 20; YoloObj.X2 := 100; YoloObj.Y2 := 200;
    YoloObj.Polygon := '10:20|100:200';
    SetLength(YoloObj.KeyPoints, 0);

    AssertTrue('Objeto clássico sem keypoints preserva BBox', (YoloObj.X1 = 10) and (YoloObj.Y2 = 200));
    AssertTrue('Objeto clássico preserva Polygon', YoloObj.Polygon = '10:20|100:200');
    AssertTrue('HasKeyPoints retorna False para detecção tradicional', not Yolo.HasKeyPoints(YoloObj));
  finally
    Yolo.Free;
  end;
end;

// Teste 58: Serialização e desserialização JSON
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
    Prof1.Images.Add('C:\fotos\marcelo1.jpg');
    Prof1.Images.Add('C:\fotos\marcelo2.jpg');
    Prof1.Triggers.Add('iniciar_atendimento');

    Sample := TAIFaceSample.Create;
    Sample.SampleID := 'marcelo_s1';
    Sample.ImageFile := 'C:\fotos\marcelo1.jpg';
    Sample.DescriptorVersion := 1;
    Sample.Algorithm := 'yolo_landmarks_geometry';
    Sample.DetectionConfidence := 0.96;
    Sample.QualityScore := 0.94;
    SetLength(V, 4);
    V[0] := 0.123; V[1] := 0.456; V[2] := 0.789; V[3] := 1.011;
    Sample.Vector := V;
    Prof1.AddSample(Sample);

    JsonStr := ProfileToJSON(Prof1);
    AssertTrue('JSON gerado não está vazio', Length(JsonStr) > 0);
    AssertTrue('JSON não deve conter caminho binário de imagem', Pos('ÿØÿ', JsonStr) = 0);

    AssertTrue('Desserialização do JSON bem-sucedida', JSONToProfile(JsonStr, Prof2, WarningStr));
    AssertTrue('ID restaurado', Prof2.ID = Prof1.ID);
    AssertTrue('Name restaurado', Prof2.Name = Prof1.Name);
    AssertTrue('Role restaurado', Prof2.Role = Prof1.Role);
    AssertTrue('ProfileText restaurado', Prof2.ProfileText = Prof1.ProfileText);
    AssertTrue('Triggers restaurados', Prof2.Triggers.Count = 1);
    AssertTrue('Images restauradas', Prof2.Images.Count = 2);
    AssertTrue('Samples restauradas', Prof2.SampleCount = 1);
    AssertTrue('Vetor do descritor restaurado',
      (Length(Prof2.Samples[0].Vector) = 4) and (Abs(Prof2.Samples[0].Vector[1] - 0.456) < 1e-4));
  finally
    Prof1.Free;
    Prof2.Free;
  end;
end;

// Teste 59: JSON corrompido ou inválido tolerado
procedure Test59_CorruptedJSONTolerance;
var
  Prof: TAIFaceProfile;
  WarningStr: string;
  InvalidJSON: string;
begin
  WriteLn('--- Teste 59: Tolerância a JSON inválido ---');
  Prof := TAIFaceProfile.Create;
  try
    InvalidJSON := '{"id": "invalido", "name": "Teste", "samples": [BROKEN_JSON...';
    AssertTrue('JSON inválido deve falhar graciosamente sem exception fatal',
      not JSONToProfile(InvalidJSON, Prof, WarningStr));
    WriteLn('    Aviso capturado: ' + WarningStr);
    AssertTrue('Aviso de erro gerado', WarningStr <> '');
  finally
    Prof.Free;
  end;
end;

// Teste 60: Descriptor com versão desconhecida ignorado sem derrubar perfil
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
      '{' +
      '  "id": "futuro_user",' +
      '  "name": "Usuário Futuro",' +
      '  "role": "Visitante",' +
      '  "samples": [' +
      '    {' +
      '      "sample_id": "s1",' +
      '      "descriptor_version": 99,' +
      '      "algorithm": "arcface_v99",' +
      '      "vector": [1.0, 2.0]' +
      '    }' +
      '  ]' +
      '}';

    AssertTrue('Carregamento do perfil deve suceder mesmo com descriptor versão 99',
      JSONToProfile(FutureJSON, Prof, WarningStr));
    AssertTrue('Perfil carregou dados básicos', Prof.Name = 'Usuário Futuro');
    AssertTrue('Descriptor desconhecido foi ignorado sem crash', Prof.SampleCount = 0);
    WriteLn('    Aviso gerado com instrução de reconstrução: ' + WarningStr);
    AssertTrue('Aviso contém mensagem sobre versão não suportada',
      Pos('não suportada', WarningStr) > 0);
  finally
    Prof.Free;
  end;
end;

begin
  WriteLn('===========================================================');
  WriteLn('  SUITE DE TESTES: RECONHECIMENTO FACIAL E IDENTIDADE');
  WriteLn('===========================================================');
  try
    Test50_SamePhoto;
    Test51_DifferentPhotosSamePerson;
    Test52_DifferentPersons;
    Test53_AmbiguousMatch;
    Test54_NoFaceOrEmptyVector;
    Test55_MultiFaceRejectionInEnrollment;
    Test56_YoloModelWithoutKeypoints;
    Test57_YoloCompatibility;
    Test58_JSONSerializationRoundtrip;
    Test59_CorruptedJSONTolerance;
    Test60_UnknownDescriptorVersion;

    WriteLn('===========================================================');
    WriteLn('  TODOS OS TESTES (50-60) PASSARAM COM SUCESSO!');
    WriteLn('===========================================================');
  except
    on E: Exception do
    begin
      WriteLn('ERRO FATAL NA EXECUÇÃO DOS TESTES: ', E.Message);
      Halt(1);
    end;
  end;
end.
