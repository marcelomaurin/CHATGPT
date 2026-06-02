program test_aigraphmap;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aigraphmap, aipipeline, aibase;

procedure TestTokenizer;
var
  GraphMap: TAIGraphMap;
  Tokens: TStrings;
begin
  WriteLn('Testing Tokenizer...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    GraphMap.LowerCaseTokens := True;
    GraphMap.RemoveAccents := True;
    GraphMap.RemoveStopWords := True;
    GraphMap.MinTokenLength := 3;
    
    // "Não" is a stopword. "conectar" and "postgres" should remain. "ao" is a stopword.
    Tokens := GraphMap.Tokenize('Não consigo conectar ao postgres!');
    try
      // "Não", "ao" removed. "consigo", "conectar", "postgres" left.
      if Tokens.IndexOf('nao') >= 0 then
        raise Exception.Create('Tokenizer failed: "não" should be removed as a stopword.');
      if Tokens.IndexOf('conectar') < 0 then
        raise Exception.Create('Tokenizer failed: "conectar" should be present.');
      if Tokens.IndexOf('postgres') < 0 then
        raise Exception.Create('Tokenizer failed: "postgres" should be present.');
    finally
      Tokens.Free;
    end;
  finally
    GraphMap.Free;
  end;
end;

procedure TestTrainingAndPrediction;
var
  GraphMap: TAIGraphMap;
  Item: TAITrainingItem;
  Cat: string;
  Ranking: TStringList;
  Explanation: TStringList;
begin
  WriteLn('Testing Training and Prediction...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    // Add training items
    Item := GraphMap.Training.Add;
    Item.InputText := 'erro ao conectar no postgres';
    Item.OutputCategory := 'banco_dados';
    Item.Weight := 1.0;

    Item := GraphMap.Training.Add;
    Item.InputText := 'falha na porta impressora';
    Item.OutputCategory := 'impressora';
    Item.Weight := 1.0;

    // Train
    GraphMap.Train;

    if GraphMap.NodeCount = 0 then
      raise Exception.Create('Training failed: NodeCount is 0.');
    if GraphMap.EdgeCount = 0 then
      raise Exception.Create('Training failed: EdgeCount is 0.');

    // Predict
    Cat := GraphMap.Predict('conectar postgres');
    if Cat <> 'banco_dados' then
      raise Exception.Create('Prediction failed: expected "banco_dados", got: ' + Cat);

    Ranking := TStringList.Create;
    Explanation := TStringList.Create;
    try
      GraphMap.PredictRanking('impressora', Ranking);
      if Ranking.Count = 0 then
        raise Exception.Create('PredictRanking failed: empty list.');
      if Ranking.Names[0] <> 'impressora' then
        raise Exception.Create('PredictRanking failed: expected best match "impressora", got: ' + Ranking.Names[0]);

      GraphMap.ExplainPrediction('impressora', Explanation);
      if Explanation.Count = 0 then
        raise Exception.Create('ExplainPrediction failed: empty explanation.');
    finally
      Ranking.Free;
      Explanation.Free;
    end;
  finally
    GraphMap.Free;
  end;
end;

procedure TestDepthSearch;
var
  GraphMap: TAIGraphMap;
  Cat: string;
begin
  WriteLn('Testing Graph Depth Search...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    // Set depth search
    GraphMap.UseGraphDepthSearch := True;
    GraphMap.MaxDepth := 2;
    GraphMap.DepthDecay := 0.5;

    // We train: "febre" -> "tosse" -> "respiratorio"
    // Let's train using TrainItem:
    GraphMap.TrainItem('febre tosse', 'respiratorio', 1.0);
    // Directly connection between "tosse" and "respiratorio" is built.
    // "febre" connects to "tosse" (since they are adjacent tokens).
    // "febre" has no direct connection to "respiratorio" because we'll query only "febre" below.
    // Wait! Let's verify that tosse is connected to respiratorio, and febre is connected to tosse.
    
    // Query "febre"
    Cat := GraphMap.Predict('febre');
    // Since febre connects to tosse (depth 1), which connects to respiratorio, respiratorio should match!
    if Cat <> 'respiratorio' then
      raise Exception.Create('Depth Search failed: expected "respiratorio" to be found via neighbor "tosse", got: ' + Cat);
  finally
    GraphMap.Free;
  end;
end;

procedure TestJSONSerialization;
var
  GraphMap1, GraphMap2: TAIGraphMap;
  TempGraphFile, TempTrainFile: string;
  Item: TAITrainingItem;
  Cat: string;
begin
  WriteLn('Testing JSON Serialization...');
  TempGraphFile := 'temp_test_graph.json';
  TempTrainFile := 'temp_test_train.json';

  GraphMap1 := TAIGraphMap.Create(nil);
  GraphMap2 := TAIGraphMap.Create(nil);
  try
    Item := GraphMap1.Training.Add;
    Item.InputText := 'erro ao conectar no postgres';
    Item.OutputCategory := 'banco_dados';
    Item.Weight := 1.0;

    GraphMap1.Train;
    GraphMap1.SaveGraphToFile(TempGraphFile);
    GraphMap1.SaveTrainingToFile(TempTrainFile);

    // Load into GraphMap2
    GraphMap2.LoadGraphFromFile(TempGraphFile);
    GraphMap2.LoadTrainingToFile(TempTrainFile);

    if GraphMap2.NodeCount <> GraphMap1.NodeCount then
      raise Exception.Create('Graph Load/Save failed: NodeCount mismatch.');
    if GraphMap2.EdgeCount <> GraphMap1.EdgeCount then
      raise Exception.Create('Graph Load/Save failed: EdgeCount mismatch.');
    if GraphMap2.Training.Count <> 1 then
      raise Exception.Create('Training Load/Save failed: Training count mismatch.');

    Cat := GraphMap2.Predict('postgres');
    if Cat <> 'banco_dados' then
      raise Exception.Create('Loaded graph prediction failed: expected "banco_dados", got: ' + Cat);

  finally
    GraphMap1.Free;
    GraphMap2.Free;
    if FileExists(TempGraphFile) then DeleteFile(TempGraphFile);
    if FileExists(TempTrainFile) then DeleteFile(TempTrainFile);
  end;
end;

procedure TestPipelineIntegration;
var
  Pipeline: TAIPipeline;
  GraphMap: TAIGraphMap;
  Item: TAITrainingItem;
begin
  WriteLn('Testing Pipeline Integration...');
  Pipeline := TAIPipeline.Create(nil);
  GraphMap := TAIGraphMap.Create(nil);
  try
    Item := GraphMap.Training.Add;
    Item.InputText := 'falha de rede cabo';
    Item.OutputCategory := 'rede';
    Item.Weight := 1.0;
    GraphMap.Train;

    Pipeline.Mode := pmGraphMapClassification;
    Pipeline.GraphMap := GraphMap;
    Pipeline.InputText := 'rede cabo';

    if not Pipeline.Run then
      raise Exception.Create('Pipeline Run failed: ' + Pipeline.LastError);

    if Pos('rede', Pipeline.OutputText) = 0 then
      raise Exception.Create('Pipeline Output mismatch: expected category "rede" in output, got: ' + Pipeline.OutputText);
  finally
    Pipeline.Free;
    GraphMap.Free;
  end;
end;

begin
  WriteLn('Running test_aigraphmap...');
  try
    TestTokenizer;
    TestTrainingAndPrediction;
    TestDepthSearch;
    TestJSONSerialization;
    TestPipelineIntegration;
    WriteLn('test_aigraphmap COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
