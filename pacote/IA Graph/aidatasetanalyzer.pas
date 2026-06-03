unit aidatasetanalyzer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aigraphmap, aitrainingexporter, LazUTF8, LResources;

type
  { TAIDatasetAnalyzer }

  TAIDatasetAnalyzer = class(TAIBaseComponent)
  private
    FGraphMap: TAIGraphMap;
    FTrainingExporter: TAITrainingExporter;
    FAlerts: TStrings;
    FSummaryText: TStrings;
    
    procedure CollectItems(AList: TAITrainingCollection);
    function CleanWord(const AWord: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Analyze;
    procedure ExportReport(const AFileName: string);
  published
    property GraphMap: TAIGraphMap read FGraphMap write FGraphMap;
    property TrainingExporter: TAITrainingExporter read FTrainingExporter write FTrainingExporter;
    property Alerts: TStrings read FAlerts write FAlerts;
    property SummaryText: TStrings read FSummaryText write FSummaryText;
    property Category default ccOther;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIDatasetAnalyzer]);
end;

{ TAIDatasetAnalyzer }

constructor TAIDatasetAnalyzer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIDatasetAnalyzer analyzes the quality, balance, and characteristics of training datasets prior to export or machine learning training. It evaluates missing fields, duplicate text entries, class count distributions, class imbalances, and basic vocabulary counts, raising clean alerts for developers.';
  
  FAlerts := TStringList.Create;
  FSummaryText := TStringList.Create;
  FGraphMap := nil;
  FTrainingExporter := nil;
  ClearError;
end;

destructor TAIDatasetAnalyzer.Destroy;
begin
  FAlerts.Free;
  FSummaryText.Free;
  inherited Destroy;
end;

procedure TAIDatasetAnalyzer.CollectItems(AList: TAITrainingCollection);
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
  
  // 2. Collect from TrainingExporter
  if Assigned(FTrainingExporter) and Assigned(FTrainingExporter.TrainingItems) then
  begin
    for i := 0 to FTrainingExporter.TrainingItems.Count - 1 do
    begin
      LItem := AList.Add;
      LItem.InputText := FTrainingExporter.TrainingItems[i].InputText;
      LItem.OutputCategory := FTrainingExporter.TrainingItems[i].OutputCategory;
      LItem.Weight := FTrainingExporter.TrainingItems[i].Weight;
    end;
  end;
end;

function TAIDatasetAnalyzer.CleanWord(const AWord: string): string;
var
  s: string;
  i: Integer;
begin
  s := UTF8LowerCase(AWord);
  for i := 1 to Length(s) do
  begin
    if not (s[i] in ['a'..'z', '0'..'9']) then
      s[i] := ' ';
  end;
  Result := Trim(s);
end;

procedure TAIDatasetAnalyzer.Analyze;
var
  LItems: TAITrainingCollection;
  LCats: TStringList;
  LDuplicates: TStringList;
  LTokens: TStringList;
  LWords: TStringList;
  i, j: Integer;
  LItem: TAITrainingItem;
  
  // Stats counters
  LEmptyInputs: Integer;
  LEmptyCategories: Integer;
  LShortTexts: Integer;
  LLongTexts: Integer;
  LTotalTokens: Integer;
  
  // Imbalance calculations
  LMaxCount, LMinCount: Integer;
  LCatName: string;
  LCatCount: Integer;
  
  // Token lists
  LTokenText: string;
  LIdx: Integer;
  LTokenCounts: TStringList;
  LFreq: Integer;
begin
  ClearError;
  FAlerts.Clear;
  FSummaryText.Clear;
  Log(llInfo, 'Iniciando análise do dataset.');
  
  LItems := TAITrainingCollection.Create(Self);
  LCats := TStringList.Create; // category counts
  LCats.Sorted := True;
  LCats.Duplicates := dupIgnore;
  
  LDuplicates := TStringList.Create;
  LDuplicates.Sorted := True;
  LDuplicates.Duplicates := dupIgnore;
  
  LTokens := TStringList.Create;
  LTokens.Sorted := True;
  LTokens.Duplicates := dupIgnore;
  
  LTokenCounts := TStringList.Create;
  LTokenCounts.Sorted := True;
  
  LWords := TStringList.Create;
  try
    CollectItems(LItems);
    
    if LItems.Count = 0 then
    begin
      SetError('Dataset está vazio. Associe uma fonte de dados populada.');
      Exit;
    end;
    
    LEmptyInputs := 0;
    LEmptyCategories := 0;
    LShortTexts := 0;
    LLongTexts := 0;
    LTotalTokens := 0;
    
    for i := 0 to LItems.Count - 1 do
    begin
      LItem := LItems[i];
      
      // Check empty inputs
      if Trim(LItem.InputText) = '' then
        Inc(LEmptyInputs)
      else
      begin
        // Check duplicates
        if LDuplicates.IndexOf(LItem.InputText) >= 0 then
          FAlerts.Add(Format('Alerta: Entrada duplicada encontrada na linha %d: "%s"', [i + 1, Copy(LItem.InputText, 1, 40)]))
        else
          LDuplicates.Add(LItem.InputText);
          
        // Check text length
        if Length(LItem.InputText) < 5 then
          Inc(LShortTexts);
        if Length(LItem.InputText) > 500 then
          Inc(LLongTexts);
          
        // Tokenize
        if Assigned(FGraphMap) then
          LWords.Assign(FGraphMap.Tokenize(LItem.InputText))
        else
        begin
          LWords.CommaText := CleanWord(LItem.InputText);
        end;
        
        Inc(LTotalTokens, LWords.Count);
        for j := 0 to LWords.Count - 1 do
        begin
          LTokenText := LWords[j];
          if Trim(LTokenText) = '' then Continue;
          
          LTokens.Add(LTokenText);
          LIdx := LTokenCounts.IndexOfName(LTokenText);
          if LIdx >= 0 then
          begin
            LFreq := StrToIntDef(LTokenCounts.ValueFromIndex[LIdx], 0) + 1;
            LTokenCounts.Strings[LIdx] := LTokenText + '=' + IntToStr(LFreq);
          end
          else
          begin
            LTokenCounts.Add(LTokenText + '=1');
          end;
        end;
      end;
      
      // Check empty categories
      if Trim(LItem.OutputCategory) = '' then
        Inc(LEmptyCategories)
      else
      begin
        LIdx := LCats.IndexOfName(LItem.OutputCategory);
        if LIdx >= 0 then
        begin
          LCatCount := StrToIntDef(LCats.ValueFromIndex[LIdx], 0) + 1;
          LCats.Strings[LIdx] := LItem.OutputCategory + '=' + IntToStr(LCatCount);
        end
        else
        begin
          LCats.Add(LItem.OutputCategory + '=1');
        end;
      end;
    end;
    
    // Process category counts alerts
    LMaxCount := 0;
    LMinCount := 999999;
    
    for i := 0 to LCats.Count - 1 do
    begin
      LCatName := LCats.Names[i];
      LCatCount := StrToIntDef(LCats.ValueFromIndex[i], 0);
      
      if LCatCount > LMaxCount then LMaxCount := LCatCount;
      if LCatCount < LMinCount then LMinCount := LCatCount;
      
      if LCatCount < 3 then
        FAlerts.Add(Format('Alerta: Categoria "%s" possui baixa representação (%d exemplos). Recomenda-se pelo menos 3.', [LCatName, LCatCount]));
    end;
    
    // Imbalance alert
    if (LCats.Count > 1) and (LMinCount > 0) and ((LMaxCount / LMinCount) > 5.0) then
    begin
      FAlerts.Add(Format('Alerta: Alto desequilíbrio de classes (Maior=%d, Menor=%d, Razão=%.2f).', [
        LMaxCount, LMinCount, LMaxCount / LMinCount
      ]));
    end;
    
    if LEmptyInputs > 0 then
      FAlerts.Add(Format('Crítico: Encontrados %d exemplos com entrada de texto vazia.', [LEmptyInputs]));
    if LEmptyCategories > 0 then
      FAlerts.Add(Format('Crítico: Encontrados %d exemplos com categoria de saída vazia.', [LEmptyCategories]));
    if LShortTexts > 0 then
      FAlerts.Add(Format('Alerta: %d textos muito curtos (menos de 5 caracteres).', [LShortTexts]));
    if LLongTexts > 0 then
      FAlerts.Add(Format('Alerta: %d textos muito longos (mais de 500 caracteres).', [LLongTexts]));
      
    // Summary generation
    FSummaryText.Add('=== Resumo Estatístico do Dataset ===');
    FSummaryText.Add('Total de Exemplos: ' + IntToStr(LItems.Count));
    FSummaryText.Add('Categorias Únicas: ' + IntToStr(LCats.Count));
    FSummaryText.Add('Tamanho do Vocabulário: ' + IntToStr(LTokens.Count));
    FSummaryText.Add('Total de Tokens: ' + IntToStr(LTotalTokens));
    if LItems.Count > 0 then
      FSummaryText.Add(Format('Média de Tokens por Texto: %.2f', [LTotalTokens / LItems.Count]))
    else
      FSummaryText.Add('Média de Tokens por Texto: 0.00');
    FSummaryText.Add('');
    
    FSummaryText.Add('=== Distribuição por Categoria ===');
    for i := 0 to LCats.Count - 1 do
      FSummaryText.Add(Format('  %s: %s exemplos', [LCats.Names[i], LCats.ValueFromIndex[i]]));
    FSummaryText.Add('');
    
    // List rare and frequent tokens
    FSummaryText.Add('=== Análise de Tokens ===');
    FSummaryText.Add('Tokens frequentes (em mais de 50% dos exemplos):');
    j := 0;
    for i := 0 to LTokenCounts.Count - 1 do
    begin
      LFreq := StrToIntDef(LTokenCounts.ValueFromIndex[i], 0);
      if (LItems.Count > 0) and ((LFreq / LItems.Count) > 0.5) then
      begin
        FSummaryText.Add(Format('  - %s (%d hits)', [LTokenCounts.Names[i], LFreq]));
        Inc(j);
      end;
    end;
    if j = 0 then FSummaryText.Add('  - Nenhum.');
    
    FSummaryText.Add('Tokens raros (apenas 1 ocorrência):');
    j := 0;
    for i := 0 to LTokenCounts.Count - 1 do
    begin
      LFreq := StrToIntDef(LTokenCounts.ValueFromIndex[i], 0);
      if LFreq = 1 then
      begin
        if j < 10 then // limit listing to top 10
          FSummaryText.Add('  - ' + LTokenCounts.Names[i]);
        Inc(j);
      end;
    end;
    if j > 10 then
      FSummaryText.Add(Format('  - ... e mais %d tokens raros.', [j - 10]));
    if j = 0 then FSummaryText.Add('  - Nenhum.');
    
    FLastResult := Format('Análise concluída. Exemplos: %d, Alertas: %d', [LItems.Count, FAlerts.Count]);
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  finally
    LWords.Free;
    LTokenCounts.Free;
    LTokens.Free;
    LDuplicates.Free;
    LCats.Free;
    LItems.Free;
  end;
end;

procedure TAIDatasetAnalyzer.ExportReport(const AFileName: string);
var
  LReport: TStringList;
  i: Integer;
begin
  ClearError;
  LReport := TStringList.Create;
  try
    try
      LReport.Add('================================================================================');
      LReport.Add('                  RELATÓRIO DE ANÁLISE DE QUALIDADE DO DATASET                  ');
      LReport.Add('================================================================================');
      LReport.Add('Gerado em: ' + DateTimeToStr(Now));
      LReport.Add('');
      LReport.AddStrings(FSummaryText);
      LReport.Add('=== Alertas e Problemas Identificados ===');
      if FAlerts.Count = 0 then
        LReport.Add('  - Nenhum problema detectado. Dataset de excelente qualidade!')
      else
      begin
        for i := 0 to FAlerts.Count - 1 do
          LReport.Add('  - ' + FAlerts[i]);
      end;
      LReport.Add('');
      LReport.Add('================================================================================');
      
      LReport.SaveToFile(AFileName);
      FLastResult := 'Relatório de análise salvo em: ' + AFileName;
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
        SetError('Erro ao exportar relatório: ' + E.Message);
    end;
  finally
    LReport.Free;
  end;
end;

initialization
  {$I aidatasetanalyzer_icon.lrs}

end.
