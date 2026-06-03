program test_aigraphmap;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aigraphmap, aipipeline, aibase;

type
  { TMockTokenizer }
  TMockTokenizer = class(TAITokenizer)
  public
    function Tokenize(const AText: string): TStrings; override;
  end;

  { TMockTrainingExporter }
  TMockTrainingExporter = class(TAIBaseTrainingExporter)
  public
    procedure ExportData(ATraining: TAITrainingCollection); override;
    procedure ImportData(ATraining: TAITrainingCollection); override;
  end;

function TMockTokenizer.Tokenize(const AText: string): TStrings;
begin
  Result := TStringList.Create;
  ExtractStrings([' '], [], PChar(AText), Result);
end;

procedure TMockTrainingExporter.ExportData(ATraining: TAITrainingCollection);
begin
  // do nothing
end;

procedure TMockTrainingExporter.ImportData(ATraining: TAITrainingCollection);
var
  LItem: TAITrainingItem;
begin
  LItem := ATraining.Add;
  LItem.InputText := 'mock import text';
  LItem.OutputCategory := 'mock_cat';
  LItem.Weight := 1.0;
end;

procedure TestTokenizerAndSynonyms;
var
  GraphMap: TAIGraphMap;
  Tokens: TStrings;
begin
  WriteLn('Testing Tokenizer and Synonyms...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    GraphMap.LowerCaseTokens := True;
    GraphMap.RemoveAccents := True;
    GraphMap.RemoveStopWords := True;
    GraphMap.MinTokenLength := 3;
    
    // Add synonyms
    GraphMap.Synonyms.Add('postgresql=postgres');
    GraphMap.Synonyms.Add('database=banco');
    
    // Test TokenizeToStrings
    Tokens := TStringList.Create;
    try
      GraphMap.TokenizeToStrings('Não consigo conectar ao postgresql database!', Tokens);
      
      if Tokens.IndexOf('nao') >= 0 then
        raise Exception.Create('Tokenizer failed: "não" should be removed.');
      if Tokens.IndexOf('postgres') < 0 then
        raise Exception.Create('Synonyms failed: "postgresql" should be mapped to "postgres".');
      if Tokens.IndexOf('banco') < 0 then
        raise Exception.Create('Synonyms failed: "database" should be mapped to "banco".');
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
  TempDotFile: string;
begin
  WriteLn('Testing Training, Prediction, GraphViz...');
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

    // Verify LastMatchedTokens
    if GraphMap.LastMatchedTokens.IndexOf('postgres') < 0 then
      raise Exception.Create('LastMatchedTokens failed: "postgres" should be matched.');

    // Export GraphViz
    TempDotFile := 'temp_test_graph.dot';
    try
      GraphMap.ExportToGraphViz(TempDotFile);
      if not FileExists(TempDotFile) then
        raise Exception.Create('GraphViz Export failed: file was not created.');
    finally
      if FileExists(TempDotFile) then DeleteFile(TempDotFile);
    end;

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

procedure TestEmptyGraphCheck;
var
  GraphMap: TAIGraphMap;
  Cat: string;
begin
  WriteLn('Testing Empty Graph Check...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    Cat := GraphMap.Predict('algum texto');
    if Cat <> 'unknown' then
      raise Exception.Create('Empty graph check failed: should have returned "unknown".');
    if GraphMap.LastError = '' then
      raise Exception.Create('Empty graph check failed: LastError should be set.');
  finally
    GraphMap.Free;
  end;
end;

procedure TestNegativeRelations;
var
  GraphMap: TAIGraphMap;
  Item: TAITrainingItem;
  Cat: string;
  Ranking: TStringList;
begin
  WriteLn('Testing Negative Relations...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    Item := GraphMap.Training.Add;
    Item.InputText := 'impressora sem papel';
    Item.OutputCategory := 'impressora';
    Item.Weight := 1.0;
    
    Item := GraphMap.Training.Add;
    Item.InputText := 'conectar banco dados postgres';
    Item.OutputCategory := 'banco_dados';
    Item.Weight := 1.0;
    
    GraphMap.Train;
    
    // Add negative relation: impressora should penalize banco_dados
    GraphMap.NegativeRelations.Add('impressora=banco_dados');
    
    Ranking := TStringList.Create;
    try
      // If we ask for "impressora postgres", typically both categories get score.
      // But because "impressora" penalizes "banco_dados", impressora score should be much higher.
      GraphMap.PredictRanking('impressora postgres', Ranking);
      if Ranking.Count > 0 then
      begin
        if Ranking.Names[0] <> 'impressora' then
          raise Exception.Create('Negative relations failed: expected best match "impressora".');
      end;
    finally
      Ranking.Free;
    end;
  finally
    GraphMap.Free;
  end;
end;

procedure TestDepthSearch;
var
  GraphMap: TAIGraphMap;
  Cat: string;
  Explanation: TStringList;
begin
  WriteLn('Testing Graph Depth Search...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    GraphMap.UseGraphDepthSearch := True;
    GraphMap.MaxDepth := 2;
    GraphMap.DepthDecay := 0.5;

    GraphMap.TrainItem('febre tosse', 'respiratorio', 1.0);
    
    Cat := GraphMap.Predict('febre');
    if Cat <> 'respiratorio' then
      raise Exception.Create('Depth Search failed: expected "respiratorio" to be found via neighbor "tosse", got: ' + Cat);

    // Verify explanation contains indirect path details
    Explanation := TStringList.Create;
    try
      GraphMap.ExplainPrediction('febre', Explanation);
      if Explanation.Text = '' then
        raise Exception.Create('Depth Search explanation is empty.');
      // It should contain febre -> tosse -> respiratorio
      if Pos('febre -> tosse -> respiratorio', Explanation.Text) = 0 then
        raise Exception.Create('Depth Search explanation failed to trace indirect path.');
    finally
      Explanation.Free;
    end;
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
    GraphMap2.LoadTrainingFromFile(TempTrainFile);

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

    // Verify output has category + ranking (ranking starts on second line)
    // First line should be category "rede"
    if Pipeline.OutputText = '' then
      raise Exception.Create('Pipeline Output is empty.');
    
    // Check if the output has multiple lines and the first line contains the best category
    if Pos('rede', Pipeline.OutputText) = 0 then
      raise Exception.Create('Pipeline Output mismatch: expected category "rede" in output, got: ' + Pipeline.OutputText);
  finally
    Pipeline.Free;
    GraphMap.Free;
  end;
end;

procedure TestEvaluateAndMatrix;
var
  GraphMap: TAIGraphMap;
  TestData: TAITrainingCollection;
  Item: TAITrainingItem;
  Accuracy: Double;
  Matrix: TStringList;
begin
  WriteLn('Testing Evaluate and ConfusionMatrix...');
  GraphMap := TAIGraphMap.Create(nil);
  TestData := TAITrainingCollection.Create(nil);
  Matrix := TStringList.Create;
  try
    Item := GraphMap.Training.Add;
    Item.InputText := 'erro impressora';
    Item.OutputCategory := 'impressora';
    Item.Weight := 1.0;
    
    Item := GraphMap.Training.Add;
    Item.InputText := 'falha cabo rede';
    Item.OutputCategory := 'rede';
    Item.Weight := 1.0;
    
    GraphMap.Train;
    
    Item := TestData.Add;
    Item.InputText := 'cabo rede';
    Item.OutputCategory := 'rede';
    
    Item := TestData.Add;
    Item.InputText := 'impressora';
    Item.OutputCategory := 'hardware';
    
    Accuracy := GraphMap.Evaluate(TestData);
    if Accuracy <> 50.0 then
      raise Exception.Create('Evaluate failed: expected accuracy 50.0%, got: ' + FloatToStr(Accuracy));
      
    GraphMap.ConfusionMatrix(TestData, Matrix);
    if Matrix.Count <> 2 then
      raise Exception.Create('ConfusionMatrix failed: count should be 2, got: ' + IntToStr(Matrix.Count));
      
    if Pos('Esperado=rede;Previsto=rede;Qtd=1', Matrix.Text) = 0 then
      raise Exception.Create('ConfusionMatrix missing expected values.');
  finally
    Matrix.Free;
    TestData.Free;
    GraphMap.Free;
  end;
end;

procedure TestExportFormats;
var
  GraphMap: TAIGraphMap;
  Item: TAITrainingItem;
  DotFile, GexfFile, NodeFile, EdgeFile: string;
begin
  WriteLn('Testing Export Formats (DOT, GEXF, CSV)...');
  GraphMap := TAIGraphMap.Create(nil);
  try
    Item := GraphMap.Training.Add;
    Item.InputText := 'conectar postgres';
    Item.OutputCategory := 'banco';
    Item.Weight := 1.0;
    GraphMap.Train;
    
    DotFile := 'test_graph.dot';
    GexfFile := 'test_graph.gexf';
    NodeFile := 'test_nodes.csv';
    EdgeFile := 'test_edges.csv';
    
    GraphMap.SaveGraphAsDOT(DotFile);
    GraphMap.SaveGraphAsGEXF(GexfFile);
    GraphMap.SaveGraphAsCSV(NodeFile, EdgeFile);
    
    if not FileExists(DotFile) or not FileExists(GexfFile) or not FileExists(NodeFile) or not FileExists(EdgeFile) then
      raise Exception.Create('Export Formats failed: one or more files were not created.');
      
    DeleteFile(DotFile);
    DeleteFile(GexfFile);
    DeleteFile(NodeFile);
    DeleteFile(EdgeFile);
  finally
    GraphMap.Free;
  end;
end;

procedure TestExternalModules;
var
  GraphMap: TAIGraphMap;
  MockTokenizer: TMockTokenizer;
  MockExporter: TMockTrainingExporter;
  Item: TAITrainingItem;
  Tokens: TStrings;
begin
  WriteLn('Testing External Tokenizer and Exporter...');
  GraphMap := TAIGraphMap.Create(nil);
  MockTokenizer := TMockTokenizer.Create(nil);
  MockExporter := TMockTrainingExporter.Create(nil);
  try
    GraphMap.Tokenizer := MockTokenizer;
    Tokens := GraphMap.Tokenize('teste de split');
    try
      if Tokens.Count <> 3 then
        raise Exception.Create('Mock Tokenizer failed: expected 3 tokens, got ' + IntToStr(Tokens.Count));
    finally
      Tokens.Free;
    end;
    
    GraphMap.ImportTraining(MockExporter);
    if GraphMap.Training.Count <> 1 then
      raise Exception.Create('Mock Exporter Import failed: expected 1 item, got ' + IntToStr(GraphMap.Training.Count));
      
    if GraphMap.Training.Items[0].InputText <> 'mock import text' then
      raise Exception.Create('Mock Exporter Import content mismatch.');
      
    GraphMap.ExportTraining(MockExporter);
  finally
    MockExporter.Free;
    MockTokenizer.Free;
    GraphMap.Free;
  end;
end;

procedure TestSettingsPersistence;
var
  GraphMap1, GraphMap2: TAIGraphMap;
  TempFile: string;
begin
  WriteLn('Testing Settings Persistence in JSON...');
  TempFile := 'temp_settings_graph.json';
  GraphMap1 := TAIGraphMap.Create(nil);
  GraphMap2 := TAIGraphMap.Create(nil);
  try
    GraphMap1.MinTokenLength := 7;
    GraphMap1.WindowSize := 4;
    GraphMap1.TokenEdgeWeight := 3.5;
    GraphMap1.TrainItem('computador', 'hardware', 1.0);
    GraphMap1.SaveGraphToFile(TempFile);
    
    GraphMap2.LoadGraphFromFile(TempFile);
    
    if GraphMap2.MinTokenLength <> 7 then
      raise Exception.Create('Settings Persistence failed: MinTokenLength mismatch.');
    if GraphMap2.WindowSize <> 4 then
      raise Exception.Create('Settings Persistence failed: WindowSize mismatch.');
    if GraphMap2.TokenEdgeWeight <> 3.5 then
      raise Exception.Create('Settings Persistence failed: TokenEdgeWeight mismatch.');
  finally
    GraphMap1.Free;
    GraphMap2.Free;
    if FileExists(TempFile) then DeleteFile(TempFile);
  end;
end;

begin
  WriteLn('Running test_aigraphmap...');
  try
    TestTokenizerAndSynonyms;
    TestTrainingAndPrediction;
    TestEmptyGraphCheck;
    TestNegativeRelations;
    TestDepthSearch;
    TestJSONSerialization;
    TestPipelineIntegration;
    TestEvaluateAndMatrix;
    TestExportFormats;
    TestExternalModules;
    TestSettingsPersistence;
    WriteLn('test_aigraphmap COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
