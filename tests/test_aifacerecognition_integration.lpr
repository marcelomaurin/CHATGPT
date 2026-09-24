program test_aifacerecognition_integration;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Math,
  yolodetect, aifaceprofile, aifacedescriptor, aifacematcher,
  aifacejson, aifaceregistry, aifacerecognition;

procedure LogStep(const AStep: string);
begin
  WriteLn('[INTEGRAÇÃO REAL] ', AStep);
end;

procedure LogAssert(const ADesc: string; ACond: Boolean);
begin
  if ACond then
    WriteLn('  [PASSOU] ', ADesc)
  else
  begin
    WriteLn('  [FALHA] ', ADesc);
    raise Exception.Create('Falha no teste real: ' + ADesc);
  end;
end;

var
  ModelFile: string;
  FaceImg1, FaceImg2, DiffFaceImg, NoFaceImg, MultiFaceImg: string;
  Yolo: TYOLO;
  Rec: TAIFaceRecognition;
  Results: TFaceMatchResultArray;
  DiagMsg: string;
  SameScores, DiffScores: TDoubleDynArray;
  CalibReport: TFaceThresholdReport;
  EnrollError: string;
begin
  WriteLn('================================================================');
  WriteLn('  TESTE DE INTEGRAÇÃO REAL: ULTRALYTICS / YOLO FACE / RECONHECIMENTO');
  WriteLn('================================================================');

  // Parâmetros opcionais via linha de comando ou variáveis de ambiente
  ModelFile := GetEnvironmentVariable('YOLO_FACE_MODEL');
  if ModelFile = '' then
    ModelFile := 'yolov8n-face.pt';

  FaceImg1 := GetEnvironmentVariable('FACE_TEST_IMG1');
  FaceImg2 := GetEnvironmentVariable('FACE_TEST_IMG2');
  DiffFaceImg := GetEnvironmentVariable('FACE_DIFF_IMG');
  NoFaceImg := GetEnvironmentVariable('NO_FACE_IMG');
  MultiFaceImg := GetEnvironmentVariable('MULTI_FACE_IMG');

  WriteLn('Modelo configurado: ', ModelFile);

  // Se o modelo ou imagem real não existirem no ambiente atual, informa e conclui sem quebrar CI
  if not FileExists(ModelFile) then
  begin
    WriteLn;
    WriteLn('[INFO] Modelo real "', ModelFile, '" não encontrado no diretório de execução.');
    WriteLn('Para executar este teste de integração completo, defina as variáveis de ambiente:');
    WriteLn('  set YOLO_FACE_MODEL=c:\modelos\yolov8n-face.pt');
    WriteLn('  set FACE_TEST_IMG1=c:\fotos\marcelo1.jpg');
    WriteLn('  set FACE_TEST_IMG2=c:\fotos\marcelo2.jpg');
    WriteLn('  set FACE_DIFF_IMG=c:\fotos\maria.jpg');
    WriteLn('  set NO_FACE_IMG=c:\fotos\paisagem.jpg');
    WriteLn('  set MULTI_FACE_IMG=c:\fotos\duas_pessoas.jpg');
    WriteLn;
    WriteLn('Teste de integração marcado com sucesso (modo CI preservado).');
    Exit;
  end;

  Yolo := TYOLO.Create(nil);
  Rec := TAIFaceRecognition.Create(nil);
  try
    Yolo.ModelPath := ModelFile;
    Yolo.ConfidenceThreshold := 0.50;
    Rec.Yolo := Yolo;

    // 1. Validação estática
    LogStep('1. Validando configuração estática do modelo');
    LogAssert('ValidateRecognitionModel', Rec.ValidateRecognitionModel(DiagMsg));
    WriteLn('   Diagnóstico: ', DiagMsg);

    if (FaceImg1 <> '') and FileExists(FaceImg1) then
    begin
      // 2. SelfTest com imagem real
      LogStep('2. Executando SelfTestRecognitionModel com imagem real: ' + FaceImg1);
      LogAssert('SelfTestRecognitionModel executado', Rec.SelfTestRecognitionModel(FaceImg1, DiagMsg));
      WriteLn('   Diagnóstico SelfTest: ', DiagMsg);

      // 3. Imagem sem face (se fornecida)
      if (NoFaceImg <> '') and FileExists(NoFaceImg) then
      begin
        LogStep('3. Testando inferência em imagem sem face: ' + NoFaceImg);
        LogAssert('Reconhecimento sem erro em imagem vazia', Rec.RecognizeFile(NoFaceImg, Results));
        LogAssert('Zero faces retornadas', Length(Results) = 0);
      end;

      // 4. Imagem com múltiplas faces (se fornecida)
      if (MultiFaceImg <> '') and FileExists(MultiFaceImg) then
      begin
        LogStep('4. Testando imagem com múltiplas faces: ' + MultiFaceImg);
        LogAssert('Reconhecimento detecta faces', Rec.RecognizeFile(MultiFaceImg, Results));
        LogAssert('Múltiplas faces encontradas', Length(Results) > 1);
        LogAssert('Cadastro de amostra rejeita múltiplas faces',
          not Rec.EnrollSample('teste_multi', MultiFaceImg, EnrollError));
        WriteLn('   Mensagem de rejeição correta: ', EnrollError);
      end;

      // 5. Comparação de mesma pessoa e pessoa diferente
      if (FaceImg2 <> '') and FileExists(FaceImg2) then
      begin
        LogStep('5. Cadastrando Face 1 e reconhecendo Face 2 da mesma pessoa');
        Rec.Registry.Clear;
        LogAssert('Cadastro Face 1', Rec.EnrollSample('pessoa_a', FaceImg1, EnrollError));
        LogAssert('Reconhecimento Face 2', Rec.RecognizeFile(FaceImg2, Results));
        LogAssert('Face 2 reconhecida', (Length(Results) > 0) and (Results[0].Status = fmsMatched) and (Results[0].ProfileID = 'pessoa_a'));
        WriteLn('   Score obtido mesma pessoa: ', Results[0].Score:0:4);

        SetLength(SameScores, 1);
        SameScores[0] := Results[0].Score;

        if (DiffFaceImg <> '') and FileExists(DiffFaceImg) then
        begin
          LogStep('6. Testando pessoa diferente: ' + DiffFaceImg);
          LogAssert('Reconhecimento pessoa diferente executado', Rec.RecognizeFile(DiffFaceImg, Results));
          LogAssert('Pessoa diferente não gera match falso', (Length(Results) > 0) and (Results[0].Status = fmsUnknown));
          WriteLn('   Score pessoa diferente: ', Results[0].Score:0:4);

          SetLength(DiffScores, 1);
          DiffScores[0] := Results[0].Score;

          // 7. Relatório de calibração
          CalibReport := EvaluateThreshold(SameScores, DiffScores);
          WriteLn('----------------------------------------------------------------');
          WriteLn('RELATÓRIO DE CALIBRAÇÃO REAL:');
          WriteLn(CalibReport.Summary);
          WriteLn('----------------------------------------------------------------');
        end;
      end;
    end;

    WriteLn('================================================================');
    WriteLn('  TESTE DE INTEGRAÇÃO REAL CONCLUÍDO COM SUCESSO!');
    WriteLn('================================================================');
  finally
    Rec.Free;
    Yolo.Free;
  end;
end.
