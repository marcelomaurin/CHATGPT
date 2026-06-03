program test_new_components;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, chatgpt, aiproject, aipipeline, aigraphmap, aioutput_docs,
  aimodelregistry, aiwizardconfig, aitrainingexporter, aidatasetanalyzer,
  aitrainingreport, aigraphvisualizer;

procedure TestModelRegistryAndWizard;
var
  Registry: TAIModelRegistry;
  Wizard: TAIWizardConfig;
  Project: TAIProject;
  CGPT: TCHATGPT;
  Pipe: TAIPipeline;
  ProvList, ModList: TStringList;
begin
  WriteLn('Testing TAIModelRegistry & TAIWizardConfig...');
  Registry := TAIModelRegistry.Create(nil);
  Wizard := TAIWizardConfig.Create(nil);
  Project := TAIProject.Create(nil);
  CGPT := TCHATGPT.Create(nil);
  Pipe := TAIPipeline.Create(nil);
  ProvList := TStringList.Create;
  ModList := TStringList.Create;
  try
    // Test Registry
    Registry.GetProviders(ProvList);
    if ProvList.IndexOf('OpenAI') < 0 then
      raise Exception.Create('ModelRegistry: OpenAI provider not found.');
      
    Registry.GetModels('OpenAI', ModList);
    if ModList.Count = 0 then
      raise Exception.Create('ModelRegistry: OpenAI models list is empty.');
      
    // Test ApplyModel
    Registry.ApplyModel('gpt-4o-mini', CGPT);
    if CGPT.CustomModel <> 'gpt-4o-mini' then
      raise Exception.Create('ModelRegistry ApplyModel failed: expected gpt-4o-mini.');

    // Save & Load Registry JSON
    Registry.SaveToFile('temp_models.json');
    if not FileExists('temp_models.json') then
      raise Exception.Create('ModelRegistry SaveToFile failed.');
    Registry.LoadFromFile('temp_models.json');
    DeleteFile('temp_models.json');

    // Test Wizard
    Wizard.Project := Project;
    Wizard.ChatGPT := CGPT;
    Wizard.Pipeline := Pipe;
    Wizard.ModelRegistry := Registry;
    Wizard.ProjectType := 'classificador GraphMap';
    Wizard.ModelName := 'gpt-4o-mini';
    Wizard.SimulationMode := True;
    
    Wizard.Apply;
    
    if Pipe.Mode <> pmGraphMapClassification then
      raise Exception.Create('Wizard Apply failed: Pipeline mode should be pmGraphMapClassification.');
    if Project.SimulationMode <> True then
      raise Exception.Create('Wizard Apply failed: Project SimulationMode should be True.');
      
    // Test Wizard connection test (simulated)
    if not Wizard.TestConnection then
      raise Exception.Create('Wizard TestConnection failed.');

    // Save & Load Wizard config
    Wizard.SaveToFile('temp_wizard.json');
    if not FileExists('temp_wizard.json') then
      raise Exception.Create('Wizard SaveToFile failed.');
    Wizard.LoadFromFile('temp_wizard.json');
    DeleteFile('temp_wizard.json');
    
  finally
    ModList.Free;
    ProvList.Free;
    Pipe.Free;
    CGPT.Free;
    Project.Free;
    Wizard.Free;
    Registry.Free;
  end;
end;

procedure TestGraphMapCycle;
var
  GraphMap: TAIGraphMap;
  Exporter: TAITrainingExporter;
  Analyzer: TAIDatasetAnalyzer;
  Report: TAITrainingReport;
  Visualizer: TAIGraphVisualizer;
  Docs: TAIOutputDocs;
  Item: TAITrainingItem;
  Count, Cats, Tokens: Integer;
begin
  WriteLn('Testing GraphMap Cycle (Exporter, Analyzer, Report, Visualizer)...');
  GraphMap := TAIGraphMap.Create(nil);
  Exporter := TAITrainingExporter.Create(nil);
  Analyzer := TAIDatasetAnalyzer.Create(nil);
  Report := TAITrainingReport.Create(nil);
  Visualizer := TAIGraphVisualizer.Create(nil);
  Docs := TAIOutputDocs.Create(nil);
  try
    // Populate dataset
    Item := GraphMap.Training.Add;
    Item.InputText := 'erro ao conectar no postgresql';
    Item.OutputCategory := 'banco';
    Item.Weight := 1.0;

    Item := GraphMap.Training.Add;
    Item.InputText := 'impressora com atolamento papel';
    Item.OutputCategory := 'impressora';
    Item.Weight := 1.0;

    GraphMap.Train;

    // Test Exporter
    Exporter.GraphMap := GraphMap;
    Exporter.OutputDocs := Docs;
    Exporter.ExportFormat := efCSV;
    if not Exporter.ExportToFile('temp_export.csv') then
      raise Exception.Create('Exporter failed: ' + Exporter.LastError);
    if not FileExists('temp_export.csv') then
      raise Exception.Create('Exporter file not created.');
    DeleteFile('temp_export.csv');
    
    // Test Exporter in JSONL
    Exporter.ExportFormat := efJSONL;
    if not Exporter.ExportToFile('temp_export.jsonl') then
      raise Exception.Create('Exporter JSONL failed: ' + Exporter.LastError);
    DeleteFile('temp_export.jsonl');

    // Test Exporter in CSVNumeric
    Exporter.ExportFormat := efCSVNumeric;
    Exporter.VectorizationMode := vmBinary;
    if not Exporter.ExportToFile('temp_export_num.csv') then
      raise Exception.Create('Exporter CSVNumeric failed: ' + Exporter.LastError);
    DeleteFile('temp_export_num.csv');

    // Test Analyzer
    Analyzer.GraphMap := GraphMap;
    Analyzer.Analyze;
    if Analyzer.Alerts.Count > 0 then
      WriteLn('Analyzer alerts: ', Analyzer.Alerts.Text);
    if Analyzer.SummaryText.Count = 0 then
      raise Exception.Create('Analyzer summary is empty.');
    Analyzer.ExportReport('temp_analise.txt');
    DeleteFile('temp_analise.txt');

    // Test Report
    Report.GraphMap := GraphMap;
    Report.OutputDocs := Docs;
    Report.GenerateReportText;
    if Report.ReportText.Count = 0 then
      raise Exception.Create('ReportText is empty.');
    Report.GenerateOutputDocs;
    
    // Test Visualizer
    Visualizer.GraphMap := GraphMap;
    Visualizer.OutputDocs := Docs;
    Visualizer.ExportToMermaid('temp_mermaid.md');
    if not FileExists('temp_mermaid.md') then
      raise Exception.Create('Visualizer Mermaid export failed.');
    DeleteFile('temp_mermaid.md');
    
    Visualizer.ExportToDOT('temp_dot.dot');
    DeleteFile('temp_dot.dot');

  finally
    Docs.Free;
    Visualizer.Free;
    Report.Free;
    Analyzer.Free;
    Exporter.Free;
    GraphMap.Free;
  end;
end;

begin
  WriteLn('Running test_new_components...');
  try
    TestModelRegistryAndWizard;
    TestGraphMapCycle;
    WriteLn('test_new_components COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
