unit aitrainingexporter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, aigraphmap, aipipeline, aiinput, aioutput, aidatasetgenerator, aioutput_docs, LazUTF8, LResources;

type
  TAIExportFormat = (
    efCSV,
    efCSVRanking,
    efJSON,
    efJSONL,
    efCSVNumeric,
    efGraphJSON,
    efGraphViz,
    efTXT,
    efARFF
  );

  TAIVectorizationMode = (
    vmBinary,
    vmFrequency
  );

  { TAITrainingExporter }

  TAITrainingExporter = class(TAIBaseTrainingExporter)
  private
    FGraphMap: TAIGraphMap;
    FPipeline: TAIPipeline;
    FInputData: TAIInputData;
    FOutputData: TAIOutputData;
    FDatasetGenerator: TAIDatasetGenerator;
    FOutputDocs: TAIOutputDocs;
    FTrainingItems: TAITrainingCollection;
    
    FExportFormat: TAIExportFormat;
    FVectorizationMode: TAIVectorizationMode;
    FOneHotOutput: Boolean;
    FTargetFileName: string;
    FOverwrite: Boolean;

    procedure CollectAllItems(AList: TAITrainingCollection);
    function GenerateVocabulary(AList: TAITrainingCollection; AVocab: TStringList): Boolean;
    function CleanTextForVocab(const AText: string): string;
    
    // Specific Export methods
    function ExportToCSV(AList: TAITrainingCollection; const AFileName: string): Boolean;
    function ExportToCSVRanking(AList: TAITrainingCollection; const AFileName: string): Boolean;
    function ExportToJSON(AList: TAITrainingCollection; const AFileName: string): Boolean;
    function ExportToJSONL(AList: TAITrainingCollection; const AFileName: string): Boolean;
    function ExportToCSVNumeric(AList: TAITrainingCollection; const AFileName: string): Boolean;
    function ExportToGraphJSON(const AFileName: string): Boolean;
    function ExportToGraphViz(const AFileName: string): Boolean;
    function ExportToTXT(AList: TAITrainingCollection; const AFileName: string): Boolean;
    function ExportToARFF(AList: TAITrainingCollection; const AFileName: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure ExportData(ATraining: TAITrainingCollection); override;
    procedure ImportData(ATraining: TAITrainingCollection); override;
    
    function ExportToFile(const AFileName: string): Boolean;
    function ValidateDataset(var AMessage: string): Boolean;
    procedure GetDatasetStats(var ACount, ACategories, ATokens: Integer);
  published
    property GraphMap: TAIGraphMap read FGraphMap write FGraphMap;
    property Pipeline: TAIPipeline read FPipeline write FPipeline;
    property InputData: TAIInputData read FInputData write FInputData;
    property OutputData: TAIOutputData read FOutputData write FOutputData;
    property DatasetGenerator: TAIDatasetGenerator read FDatasetGenerator write FDatasetGenerator;
    property OutputDocs: TAIOutputDocs read FOutputDocs write FOutputDocs;
    property TrainingItems: TAITrainingCollection read FTrainingItems write FTrainingItems;
    
    property ExportFormat: TAIExportFormat read FExportFormat write FExportFormat default efCSV;
    property VectorizationMode: TAIVectorizationMode read FVectorizationMode write FVectorizationMode default vmBinary;
    property OneHotOutput: Boolean read FOneHotOutput write FOneHotOutput default True;
    property TargetFileName: string read FTargetFileName write FTargetFileName;
    property Overwrite: Boolean read FOverwrite write FOverwrite default True;
    property Category default ccOther;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAITrainingExporter]);
end;

{ TAITrainingExporter }

constructor TAITrainingExporter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAITrainingExporter collects, organizes, validates, and exports training data from several suite sources (TAIGraphMap, TAIPipeline, numerical vectors, generators, manual inputs) into various analytical and fine-tuning formats including CSV, JSON, JSONL, numerical CSV with binary/frequency text vectorization, GraphViz DOT, and ARFF.';
  
  FTrainingItems := TAITrainingCollection.Create(Self);
  FExportFormat := efCSV;
  FVectorizationMode := vmBinary;
  FOneHotOutput := True;
  FTargetFileName := 'dataset_export.csv';
  FOverwrite := True;
  
  FGraphMap := nil;
  FPipeline := nil;
  FInputData := nil;
  FOutputData := nil;
  FDatasetGenerator := nil;
  FOutputDocs := nil;
  ClearError;
end;

destructor TAITrainingExporter.Destroy;
begin
  FTrainingItems.Free;
  inherited Destroy;
end;

procedure TAITrainingExporter.ExportData(ATraining: TAITrainingCollection);
var
  i: Integer;
  LNewItem: TAITrainingItem;
begin
  ClearError;
  FTrainingItems.Clear;
  if not Assigned(ATraining) then Exit;
  
  for i := 0 to ATraining.Count - 1 do
  begin
    LNewItem := FTrainingItems.Add;
    LNewItem.InputText := ATraining[i].InputText;
    LNewItem.OutputCategory := ATraining[i].OutputCategory;
    LNewItem.Weight := ATraining[i].Weight;
  end;
  Log(llInfo, 'ExportData copied ' + IntToStr(FTrainingItems.Count) + ' items from external collection.');
end;

procedure TAITrainingExporter.ImportData(ATraining: TAITrainingCollection);
var
  i: Integer;
  LNewItem: TAITrainingItem;
begin
  ClearError;
  if not Assigned(ATraining) then Exit;
  
  for i := 0 to FTrainingItems.Count - 1 do
  begin
    LNewItem := ATraining.Add;
    LNewItem.InputText := FTrainingItems[i].InputText;
    LNewItem.OutputCategory := FTrainingItems[i].OutputCategory;
    LNewItem.Weight := FTrainingItems[i].Weight;
  end;
  Log(llInfo, 'ImportData copied ' + IntToStr(FTrainingItems.Count) + ' items to external collection.');
end;

procedure TAITrainingExporter.CollectAllItems(AList: TAITrainingCollection);
var
  i: Integer;
  LItem: TAITrainingItem;
begin
  AList.Clear;
  
  // 1. Collect from GraphMap
  if Assigned(FGraphMap) and Assigned(FGraphMap.Training) then
  begin
    for i := 0 to FGraphMap.Training.Count - 1 do
    begin
      LItem := AList.Add;
      LItem.InputText := FGraphMap.Training[i].InputText;
      LItem.OutputCategory := FGraphMap.Training[i].OutputCategory;
      LItem.Weight := FGraphMap.Training[i].Weight;
    end;
  end;
  
  // 2. Collect from TrainingItems (manual collection)
  for i := 0 to FTrainingItems.Count - 1 do
  begin
    LItem := AList.Add;
    LItem.InputText := FTrainingItems[i].InputText;
    LItem.OutputCategory := FTrainingItems[i].OutputCategory;
    LItem.Weight := FTrainingItems[i].Weight;
  end;
  
  // 3. Collect from Pipeline's GraphMap if assigned
  if Assigned(FPipeline) and Assigned(FPipeline.GraphMap) and Assigned(FPipeline.GraphMap.Training) then
  begin
    for i := 0 to FPipeline.GraphMap.Training.Count - 1 do
    begin
      LItem := AList.Add;
      LItem.InputText := FPipeline.GraphMap.Training[i].InputText;
      LItem.OutputCategory := FPipeline.GraphMap.Training[i].OutputCategory;
      LItem.Weight := FPipeline.GraphMap.Training[i].Weight;
    end;
  end;

  // 4. Collect from DatasetGenerator
  if Assigned(FDatasetGenerator) and (FDatasetGenerator.Count > 0) then
  begin
    for i := 0 to FDatasetGenerator.Items.Count - 1 do
    begin
      LItem := AList.Add;
      LItem.InputText := TDatasetItem(FDatasetGenerator.Items[i]).Input;
      LItem.OutputCategory := TDatasetItem(FDatasetGenerator.Items[i]).Output;
      LItem.Weight := 1.0;
    end;
  end;
  
  // 5. Collect from InputData and OutputData if present
  if Assigned(FInputData) and Assigned(FOutputData) then
  begin
    // Add raw representation if available
    LItem := AList.Add;
    LItem.InputText := FInputData.Prompt;
    LItem.OutputCategory := FOutputData.GetBestClassName;
    LItem.Weight := 1.0;
  end;
end;

function TAITrainingExporter.ValidateDataset(var AMessage: string): Boolean;
var
  LTempList: TAITrainingCollection;
  i: Integer;
begin
  Result := True;
  AMessage := '';
  
  LTempList := TAITrainingCollection.Create(Self);
  try
    CollectAllItems(LTempList);
    if LTempList.Count = 0 then
    begin
      AMessage := 'Dataset está vazio. Adicione itens antes de validar.';
      Exit(False);
    end;
    
    for i := 0 to LTempList.Count - 1 do
    begin
      if Trim(LTempList[i].InputText) = '' then
      begin
        AMessage := Format('Linha %d possui entrada vazia.', [i + 1]);
        Exit(False);
      end;
      if Trim(LTempList[i].OutputCategory) = '' then
      begin
        AMessage := Format('Linha %d possui categoria vazia.', [i + 1]);
        Exit(False);
      end;
    end;
  finally
    LTempList.Free;
  end;
end;

procedure TAITrainingExporter.GetDatasetStats(var ACount, ACategories, ATokens: Integer);
var
  LTempList: TAITrainingCollection;
  LCats: TStringList;
  LTokensList: TStringList;
  i: Integer;
  LWords: TStringList;
begin
  ACount := 0;
  ACategories := 0;
  ATokens := 0;
  
  LTempList := TAITrainingCollection.Create(Self);
  LCats := TStringList.Create;
  LCats.Sorted := True;
  LCats.Duplicates := dupIgnore;
  
  LTokensList := TStringList.Create;
  LTokensList.Sorted := True;
  LTokensList.Duplicates := dupIgnore;
  
  LWords := TStringList.Create;
  try
    CollectAllItems(LTempList);
    ACount := LTempList.Count;
    
    for i := 0 to LTempList.Count - 1 do
    begin
      LCats.Add(LTempList[i].OutputCategory);
      if Assigned(FGraphMap) then
        FGraphMap.TokenizeToStrings(LTempList[i].InputText, LWords)
      else
        LWords.CommaText := CleanTextForVocab(LTempList[i].InputText);
      
      LTokensList.AddStrings(LWords);
    end;
    ACategories := LCats.Count;
    ATokens := LTokensList.Count;
  finally
    LWords.Free;
    LTokensList.Free;
    LCats.Free;
    LTempList.Free;
  end;
end;

function TAITrainingExporter.ExportToFile(const AFileName: string): Boolean;
var
  LTempList: TAITrainingCollection;
  LValMsg: string;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Iniciando exportação para o arquivo: ' + AFileName);
  
  if not FOverwrite and FileExists(AFileName) then
  begin
    SetError('Arquivo destino já existe e a opção Overwrite está desativada.');
    Exit;
  end;
  
  if not ValidateDataset(LValMsg) then
  begin
    SetError('Erro de validação no dataset: ' + LValMsg);
    Exit;
  end;
  
  LTempList := TAITrainingCollection.Create(Self);
  try
    CollectAllItems(LTempList);
    
    case FExportFormat of
      efCSV: Result := ExportToCSV(LTempList, AFileName);
      efCSVRanking: Result := ExportToCSVRanking(LTempList, AFileName);
      efJSON: Result := ExportToJSON(LTempList, AFileName);
      efJSONL: Result := ExportToJSONL(LTempList, AFileName);
      efCSVNumeric: Result := ExportToCSVNumeric(LTempList, AFileName);
      efGraphJSON: Result := ExportToGraphJSON(AFileName);
      efGraphViz: Result := ExportToGraphViz(AFileName);
      efTXT: Result := ExportToTXT(LTempList, AFileName);
      efARFF: Result := ExportToARFF(LTempList, AFileName);
    end;
    
    if Result then
    begin
      FLastResult := Format('Exportação concluída. Formato: %d, Itens: %d', [Ord(FExportFormat), LTempList.Count]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
      
      // Export report also via OutputDocs if connected
      if Assigned(FOutputDocs) then
      begin
        FOutputDocs.Clear;
        FOutputDocs.Title := 'Relatório de Exportação de Dados';
        FOutputDocs.AddHeading('Estatísticas de Exportação', 1);
        FOutputDocs.AddParagraph('Arquivo destino: ' + AFileName);
        FOutputDocs.AddParagraph('Total de registros: ' + IntToStr(LTempList.Count));
        FOutputDocs.SaveToTXT;
      end;
    end;
  finally
    LTempList.Free;
  end;
end;

function TAITrainingExporter.CleanTextForVocab(const AText: string): string;
var
  s: string;
  i: Integer;
begin
  s := UTF8LowerCase(AText);
  for i := 1 to Length(s) do
  begin
    if not (s[i] in ['a'..'z', '0'..'9', ' ']) then
      s[i] := ' ';
  end;
  Result := s;
end;

function TAITrainingExporter.GenerateVocabulary(AList: TAITrainingCollection; AVocab: TStringList): Boolean;
var
  i, j: Integer;
  LTokens: TStrings;
begin
  AVocab.Clear;
  AVocab.Sorted := True;
  AVocab.Duplicates := dupIgnore;
  
  for i := 0 to AList.Count - 1 do
  begin
    if Assigned(FGraphMap) then
      LTokens := FGraphMap.Tokenize(AList[i].InputText)
    else
    begin
      LTokens := TStringList.Create;
      LTokens.CommaText := CleanTextForVocab(AList[i].InputText);
    end;
    
    try
      for j := 0 to LTokens.Count - 1 do
      begin
        if Trim(LTokens[j]) <> '' then
          AVocab.Add(LTokens[j]);
      end;
    finally
      LTokens.Free;
    end;
  end;
  Result := AVocab.Count > 0;
end;

// Format Exporters

function TAITrainingExporter.ExportToCSV(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LOut: TStringList;
  i: Integer;
begin
  Result := False;
  LOut := TStringList.Create;
  try
    LOut.Add('input_text;expected_output;weight');
    for i := 0 to AList.Count - 1 do
    begin
      LOut.Add(Format('"%s";"%s";%s', [
        StringReplace(AList[i].InputText, '"', '""', [rfReplaceAll]),
        StringReplace(AList[i].OutputCategory, '"', '""', [rfReplaceAll]),
        FormatFloat('0.00', AList[i].Weight)
      ]));
    end;
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LOut.Free;
  end;
end;

function TAITrainingExporter.ExportToCSVRanking(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LOut: TStringList;
  i: Integer;
  LRanking: TStringList;
  LPredicted, LConfStr: string;
  LIsCorrect: Integer;
begin
  Result := False;
  if not Assigned(FGraphMap) then
  begin
    SetError('GraphMap é obrigatório para exportar com predição e ranking.');
    Exit;
  end;
  
  LOut := TStringList.Create;
  LRanking := TStringList.Create;
  try
    LOut.Add('input_text;expected_output;predicted_output;confidence;is_correct');
    for i := 0 to AList.Count - 1 do
    begin
      LRanking.Clear;
      FGraphMap.PredictRanking(AList[i].InputText, LRanking);
      if LRanking.Count > 0 then
      begin
        LPredicted := LRanking.Names[0];
        LConfStr := LRanking.ValueFromIndex[0];
      end
      else
      begin
        LPredicted := 'unknown';
        LConfStr := '0.00';
      end;
      
      if LPredicted = AList[i].OutputCategory then LIsCorrect := 1 else LIsCorrect := 0;
      
      LOut.Add(Format('"%s";"%s";"%s";%s;%d', [
        StringReplace(AList[i].InputText, '"', '""', [rfReplaceAll]),
        StringReplace(AList[i].OutputCategory, '"', '""', [rfReplaceAll]),
        StringReplace(LPredicted, '"', '""', [rfReplaceAll]),
        LConfStr,
        LIsCorrect
      ]));
    end;
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LRanking.Free;
    LOut.Free;
  end;
end;

function TAITrainingExporter.ExportToJSON(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LRoot: TJSONArray;
  LItem: TJSONObject;
  LOut: TStringList;
  i: Integer;
begin
  Result := False;
  LRoot := TJSONArray.Create;
  LOut := TStringList.Create;
  try
    for i := 0 to AList.Count - 1 do
    begin
      LItem := TJSONObject.Create;
      LItem.Add('input_text', AList[i].InputText);
      LItem.Add('expected_output', AList[i].OutputCategory);
      LItem.Add('weight', AList[i].Weight);
      LRoot.Add(LItem);
    end;
    LOut.Text := LRoot.AsJSON;
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LOut.Free;
    LRoot.Free;
  end;
end;

function TAITrainingExporter.ExportToJSONL(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LOut: TStringList;
  i: Integer;
  LRoot, LMsgSystem, LMsgUser, LMsgAssistant: TJSONObject;
  LMsgs: TJSONArray;
begin
  Result := False;
  LOut := TStringList.Create;
  try
    for i := 0 to AList.Count - 1 do
    begin
      LRoot := TJSONObject.Create;
      LMsgs := TJSONArray.Create;
      LRoot.Add('messages', LMsgs);
      
      LMsgSystem := TJSONObject.Create;
      LMsgSystem.Add('role', 'system');
      LMsgSystem.Add('content', 'Você é um modelo classificador textual.');
      LMsgs.Add(LMsgSystem);
      
      LMsgUser := TJSONObject.Create;
      LMsgUser.Add('role', 'user');
      LMsgUser.Add('content', AList[i].InputText);
      LMsgs.Add(LMsgUser);
      
      LMsgAssistant := TJSONObject.Create;
      LMsgAssistant.Add('role', 'assistant');
      LMsgAssistant.Add('content', AList[i].OutputCategory);
      LMsgs.Add(LMsgAssistant);
      
      LOut.Add(LRoot.AsJSON);
      LRoot.Free; // Freeing LRoot frees all inner objects in fpJSON
    end;
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LOut.Free;
  end;
end;

function TAITrainingExporter.ExportToCSVNumeric(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LOut: TStringList;
  LVocab: TStringList;
  LCats: TStringList;
  i, j: Integer;
  LTokens: TStrings;
  LHeader: string;
  LRow: string;
  LIdx: Integer;
  LCounts: array of Integer;
  LCatIdx: Integer;
begin
  Result := False;
  LOut := TStringList.Create;
  LVocab := TStringList.Create;
  LCats := TStringList.Create;
  try
    if not GenerateVocabulary(AList, LVocab) then
    begin
      SetError('Erro ao gerar vocabulário para vetorização.');
      Exit;
    end;
    
    LCats.Sorted := True;
    LCats.Duplicates := dupIgnore;
    for i := 0 to AList.Count - 1 do
      LCats.Add(AList[i].OutputCategory);
      
    // Write CSV Headers
    LHeader := '';
    for j := 0 to LVocab.Count - 1 do
      LHeader := LHeader + 't_' + LVocab[j] + ';';
      
    if FOneHotOutput then
    begin
      for j := 0 to LCats.Count - 1 do
        LHeader := LHeader + 'c_' + LCats[j] + ';';
      // Remove trailing semicolon
      if LHeader <> '' then Delete(LHeader, Length(LHeader), 1);
    end;
    LOut.Add(LHeader);
    
    // Write data rows
    SetLength(LCounts, LVocab.Count);
    for i := 0 to AList.Count - 1 do
    begin
      if Assigned(FGraphMap) then
        LTokens := FGraphMap.Tokenize(AList[i].InputText)
      else
      begin
        LTokens := TStringList.Create;
        LTokens.CommaText := CleanTextForVocab(AList[i].InputText);
      end;
      
      try
        FillChar(LCounts[0], Length(LCounts) * SizeOf(Integer), 0);
        for j := 0 to LTokens.Count - 1 do
        begin
          if LVocab.Find(LTokens[j], LIdx) then
            Inc(LCounts[LIdx]);
        end;
        
        LRow := '';
        for j := 0 to LVocab.Count - 1 do
        begin
          if FVectorizationMode = vmBinary then
          begin
            if LCounts[j] > 0 then LRow := LRow + '1;' else LRow := LRow + '0;';
          end
          else // vmFrequency
          begin
            LRow := LRow + IntToStr(LCounts[j]) + ';';
          end;
        end;
        
        if FOneHotOutput then
        begin
          LCats.Find(AList[i].OutputCategory, LCatIdx);
          for j := 0 to LCats.Count - 1 do
          begin
            if j = LCatIdx then
              LRow := LRow + '1;'
            else
              LRow := LRow + '0;';
          end;
          if LRow <> '' then Delete(LRow, Length(LRow), 1);
        end;
        LOut.Add(LRow);
      finally
        LTokens.Free;
      end;
    end;
    
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LCats.Free;
    LVocab.Free;
    LOut.Free;
  end;
end;

function TAITrainingExporter.ExportToGraphJSON(const AFileName: string): Boolean;
begin
  Result := False;
  if Assigned(FGraphMap) then
  begin
    try
      FGraphMap.SaveGraphToFile(AFileName);
      Result := True;
    except
      on E: Exception do
        SetError('Erro ao exportar Graph JSON: ' + E.Message);
    end;
  end
  else
    SetError('GraphMap é obrigatório para exportar Graph JSON.');
end;

function TAITrainingExporter.ExportToGraphViz(const AFileName: string): Boolean;
begin
  Result := False;
  if Assigned(FGraphMap) then
  begin
    try
      FGraphMap.SaveGraphAsDOT(AFileName);
      Result := True;
    except
      on E: Exception do
        SetError('Erro ao exportar GraphViz DOT: ' + E.Message);
    end;
  end
  else
    SetError('GraphMap é obrigatório para exportar GraphViz DOT.');
end;

function TAITrainingExporter.ExportToTXT(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LOut: TStringList;
  i: Integer;
begin
  Result := False;
  LOut := TStringList.Create;
  try
    for i := 0 to AList.Count - 1 do
    begin
      LOut.Add(Format('%s => %s', [AList[i].InputText, AList[i].OutputCategory]));
    end;
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LOut.Free;
  end;
end;

function TAITrainingExporter.ExportToARFF(AList: TAITrainingCollection; const AFileName: string): Boolean;
var
  LOut: TStringList;
  LVocab: TStringList;
  LCats: TStringList;
  i, j: Integer;
  LTokens: TStrings;
  LCatsStr: string;
  LRow: string;
  LIdx: Integer;
  LCounts: array of Integer;
  LCatIdx: Integer;
begin
  Result := False;
  LOut := TStringList.Create;
  LVocab := TStringList.Create;
  LCats := TStringList.Create;
  try
    if not GenerateVocabulary(AList, LVocab) then
    begin
      SetError('Erro ao gerar vocabulário para ARFF.');
      Exit;
    end;
    
    LCats.Sorted := True;
    LCats.Duplicates := dupIgnore;
    for i := 0 to AList.Count - 1 do
      LCats.Add(AList[i].OutputCategory);
      
    LOut.Add('@relation dataset_export');
    LOut.Add('');
    
    // Add token attributes
    for j := 0 to LVocab.Count - 1 do
      LOut.Add('@attribute t_' + LVocab[j] + ' numeric');
      
    // Class Attribute
    LCatsStr := '{';
    for j := 0 to LCats.Count - 1 do
      LCatsStr := LCatsStr + LCats[j] + ',';
    if LCats.Count > 0 then
      Delete(LCatsStr, Length(LCatsStr), 1);
    LCatsStr := LCatsStr + '}';
    
    LOut.Add('@attribute class ' + LCatsStr);
    LOut.Add('');
    LOut.Add('@data');
    
    // Add instances
    SetLength(LCounts, LVocab.Count);
    for i := 0 to AList.Count - 1 do
    begin
      if Assigned(FGraphMap) then
        LTokens := FGraphMap.Tokenize(AList[i].InputText)
      else
      begin
        LTokens := TStringList.Create;
        LTokens.CommaText := CleanTextForVocab(AList[i].InputText);
      end;
      
      try
        FillChar(LCounts[0], Length(LCounts) * SizeOf(Integer), 0);
        for j := 0 to LTokens.Count - 1 do
        begin
          if LVocab.Find(LTokens[j], LIdx) then
            Inc(LCounts[LIdx]);
        end;
        
        LRow := '';
        for j := 0 to LVocab.Count - 1 do
        begin
          if FVectorizationMode = vmBinary then
          begin
            if LCounts[j] > 0 then LRow := LRow + '1,' else LRow := LRow + '0,';
          end
          else // vmFrequency
          begin
            LRow := LRow + IntToStr(LCounts[j]) + ',';
          end;
        end;
        
        LRow := LRow + AList[i].OutputCategory;
        LOut.Add(LRow);
      finally
        LTokens.Free;
      end;
    end;
    
    LOut.SaveToFile(AFileName);
    Result := True;
  finally
    LCats.Free;
    LVocab.Free;
    LOut.Free;
  end;
end;

initialization
  {$I aitrainingexporter_icon.lrs}

end.
