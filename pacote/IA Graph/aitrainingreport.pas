unit aitrainingreport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aibase, aigraphmap, aitrainingexporter, aioutput_docs, LazUTF8;

type
  { TAITrainingReport }

  TAITrainingReport = class(TAIBaseComponent)
  private
    FGraphMap: TAIGraphMap;
    FTrainingExporter: TAITrainingExporter;
    FOutputDocs: TAIOutputDocs;
    FReportText: TStrings;
    
    procedure CollectItems(AList: TAITrainingCollection);
    function CleanWord(const AWord: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure GenerateReportText;
    procedure GenerateOutputDocs;
    procedure SaveReport(const AFileName: string);
  published
    property GraphMap: TAIGraphMap read FGraphMap write FGraphMap;
    property TrainingExporter: TAITrainingExporter read FTrainingExporter write FTrainingExporter;
    property OutputDocs: TAIOutputDocs read FOutputDocs write FOutputDocs;
    property ReportText: TStrings read FReportText write FReportText;
    property Category default ccOther;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Graph', [TAITrainingReport]);
end;

{ TAITrainingReport }

constructor TAITrainingReport.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAITrainingReport creates human-readable technical summaries and audit reports regarding training accuracy, average classification confidence, category distributions, token weights, and graph edge counts, linking seamlessly with TAIOutputDocs.';
  
  FReportText := TStringList.Create;
  FGraphMap := nil;
  FTrainingExporter := nil;
  FOutputDocs := nil;
  ClearError;
end;

destructor TAITrainingReport.Destroy;
begin
  FReportText.Free;
  inherited Destroy;
end;

procedure TAITrainingReport.CollectItems(AList: TAITrainingCollection);
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

function TAITrainingReport.CleanWord(const AWord: string): string;
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

procedure TAITrainingReport.GenerateReportText;
var
  LItems: TAITrainingCollection;
  LCats: TStringList;
  LTokens: TStringList;
  LWords: TStringList;
  i, j: Integer;
  LItem: TAITrainingItem;
  
  // Predict stats
  LCorrect: Integer;
  LIncorrect: Integer;
  LConfidenceSum: Double;
  LConfidenceCount: Integer;
  LPredicted: string;
  LConfVal: Double;
  LRanking: TStringList;
  
  // Detailed Category statistics
  LCatCorrect: TStringList;
  LCatTotal: TStringList;
  LCatErrors: TStringList;
  
  LIdx: Integer;
  LNodeCount, LEdgeCount: Integer;
  LTotalTokens: Integer;
  LPrecision: Double;
  LCatCount: Integer;
  LAvgConf: Double;
  LAccuracy: Double;
  LCatName: string;
begin
  ClearError;
  FReportText.Clear;
  Log(llInfo, 'Iniciando geração de relatório técnico.');
  
  LItems := TAITrainingCollection.Create(Self);
  LCats := TStringList.Create;
  LCats.Sorted := True;
  LCats.Duplicates := dupIgnore;
  
  LTokens := TStringList.Create;
  LTokens.Sorted := True;
  LTokens.Duplicates := dupIgnore;
  
  LWords := TStringList.Create;
  LRanking := TStringList.Create;
  
  LCatCorrect := TStringList.Create;
  LCatCorrect.Sorted := True;
  
  LCatTotal := TStringList.Create;
  LCatTotal.Sorted := True;
  
  LCatErrors := TStringList.Create;
  LCatErrors.Sorted := True;
  
  try
    CollectItems(LItems);
    if LItems.Count = 0 then
    begin
      SetError('Dataset está vazio. Associe uma fonte de dados populada.');
      Exit;
    end;
    
    LCorrect := 0;
    LIncorrect := 0;
    LConfidenceSum := 0.0;
    LConfidenceCount := 0;
    LTotalTokens := 0;
    
    // Analyze and run predictions
    for i := 0 to LItems.Count - 1 do
    begin
      LItem := LItems[i];
      
      // Increment category total counts
      LIdx := LCatTotal.IndexOfName(LItem.OutputCategory);
      if LIdx >= 0 then
        LCatTotal.Strings[LIdx] := LItem.OutputCategory + '=' + IntToStr(StrToInt(LCatTotal.ValueFromIndex[LIdx]) + 1)
      else
        LCatTotal.Add(LItem.OutputCategory + '=1');
        
      LCats.Add(LItem.OutputCategory);
      
      // Tokenization
      if Assigned(FGraphMap) then
        LWords.Assign(FGraphMap.Tokenize(LItem.InputText))
      else
      begin
        LWords.CommaText := CleanWord(LItem.InputText);
      end;
      
      Inc(LTotalTokens, LWords.Count);
      for j := 0 to LWords.Count - 1 do
        LTokens.Add(LWords[j]);
        
      // Prediction evaluation
      if Assigned(FGraphMap) and (FGraphMap.NodeCount > 0) then
      begin
        LPredicted := FGraphMap.Predict(LItem.InputText);
        LRanking.Clear;
        FGraphMap.PredictRanking(LItem.InputText, LRanking);
        
        if LRanking.Count > 0 then
        begin
          LConfVal := StrToFloatDef(LRanking.ValueFromIndex[0], 0.0);
          LConfidenceSum := LConfidenceSum + LConfVal;
          Inc(LConfidenceCount);
        end;
        
        if LPredicted = LItem.OutputCategory then
        begin
          Inc(LCorrect);
          LIdx := LCatCorrect.IndexOfName(LItem.OutputCategory);
          if LIdx >= 0 then
            LCatCorrect.Strings[LIdx] := LItem.OutputCategory + '=' + IntToStr(StrToInt(LCatCorrect.ValueFromIndex[LIdx]) + 1)
          else
            LCatCorrect.Add(LItem.OutputCategory + '=1');
        end
        else
        begin
          Inc(LIncorrect);
          LIdx := LCatErrors.IndexOfName(LItem.OutputCategory);
          if LIdx >= 0 then
            LCatErrors.Strings[LIdx] := LItem.OutputCategory + '=' + IntToStr(StrToInt(LCatErrors.ValueFromIndex[LIdx]) + 1)
          else
            LCatErrors.Add(LItem.OutputCategory + '=1');
        end;
      end;
    end;
    
    LNodeCount := 0;
    LEdgeCount := 0;
    if Assigned(FGraphMap) then
    begin
      LNodeCount := FGraphMap.NodeCount;
      LEdgeCount := FGraphMap.EdgeCount;
    end;
    
    // Add report headers
    FReportText.Add('================================================================================');
    FReportText.Add('                      RELATÓRIO TÉCNICO DE TREINAMENTO DE IA                    ');
    FReportText.Add('================================================================================');
    FReportText.Add('Data de Emissão: ' + DateTimeToStr(Now));
    FReportText.Add('');
    
    FReportText.Add('=== Estatísticas do Dataset e Grafo ===');
    FReportText.Add('Total de Exemplos Processados: ' + IntToStr(LItems.Count));
    FReportText.Add('Total de Categorias Encontradas: ' + IntToStr(LCats.Count));
    FReportText.Add('Tamanho do Vocabulário (Tokens Únicos): ' + IntToStr(LTokens.Count));
    FReportText.Add('Total de Tokens nos Textos: ' + IntToStr(LTotalTokens));
    FReportText.Add('Quantidade de Nós no Grafo: ' + IntToStr(LNodeCount));
    FReportText.Add('Quantidade de Arestas/Ramos no Grafo: ' + IntToStr(LEdgeCount));
    FReportText.Add('');
    
    // Quality evaluation summary
    if Assigned(FGraphMap) and (FGraphMap.NodeCount > 0) then
    begin
      LAccuracy := (LCorrect / LItems.Count) * 100.0;
      if LConfidenceCount > 0 then LAvgConf := LConfidenceSum / LConfidenceCount else LAvgConf := 0.0;
      
      FReportText.Add('=== Desempenho e Validação de Classificação ===');
      FReportText.Add(Format('Acurácia Geral: %.2f%% (%d acertos de %d exemplos)', [LAccuracy, LCorrect, LItems.Count]));
      FReportText.Add(Format('Confiança Média da Predição: %.2f%%', [LAvgConf]));
      FReportText.Add('');
      
      FReportText.Add('=== Distribuição Detalhada de Classes e Erros ===');
      FReportText.Add('Categoria | Amostras | Acertos | Erros | Precisão Estimada');
      FReportText.Add('----------------------------------------------------------------------');
      for i := 0 to LCats.Count - 1 do
      begin
        LCatName := LCats[i];
        LCatCount := StrToIntDef(LCatTotal.Values[LCatName], 0);
        LCorrect := StrToIntDef(LCatCorrect.Values[LCatName], 0);
        LIncorrect := StrToIntDef(LCatErrors.Values[LCatName], 0);
        
        if LCatCount > 0 then LPrecision := (LCorrect / LCatCount) * 100.0 else LPrecision := 0.0;
        
        FReportText.Add(Format('%s | %d | %d | %d | %.2f%%', [
          PadRight(LCatName, 15), LCatCount, LCorrect, LIncorrect, LPrecision
        ]));
      end;
    end
    else
    begin
      FReportText.Add('=== Desempenho e Validação de Classificação ===');
      FReportText.Add('Aviso: Modelo de Grafo não disponível ou não treinado. Métricas de validação indisponíveis.');
    end;
    FReportText.Add('');
    
    // Listing top relevant tokens by average node weight
    FReportText.Add('=== Tokens Mais Relevantes no Grafo ===');
    if Assigned(FGraphMap) and (LNodeCount > 0) then
    begin
      // Let's filter top tokens by weight from FGraphMap.Nodes
      j := 0;
      for i := 0 to FGraphMap.Nodes.Count - 1 do
      begin
        if TAIGraphNode(FGraphMap.Nodes[i]).NodeType = ntToken then
        begin
          if j < 10 then
          begin
            FReportText.Add(Format('  - "%s" (Peso: %.2f, Hits: %d)', [
              TAIGraphNode(FGraphMap.Nodes[i]).Text,
              TAIGraphNode(FGraphMap.Nodes[i]).Weight,
              TAIGraphNode(FGraphMap.Nodes[i]).HitCount
            ]));
            Inc(j);
          end;
        end;
      end;
      if j = 0 then FReportText.Add('  - Nenhum token no grafo.');
    end
    else
    begin
      FReportText.Add('  - Grafo está vazio.');
    end;
    
    FReportText.Add('');
    FReportText.Add('================================================================================');
    
    FLastResult := 'Relatório textual gerado com sucesso.';
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  finally
    LCatErrors.Free;
    LCatTotal.Free;
    LCatCorrect.Free;
    LRanking.Free;
    LWords.Free;
    LTokens.Free;
    LCats.Free;
    LItems.Free;
  end;
end;

procedure TAITrainingReport.GenerateOutputDocs;
var
  i: Integer;
begin
  ClearError;
  if not Assigned(FOutputDocs) then
  begin
    SetError('OutputDocs não está associado.');
    Exit;
  end;
  
  GenerateReportText;
  if FReportText.Count = 0 then Exit;
  
  try
    FOutputDocs.Clear;
    FOutputDocs.Title := 'Relatório Técnico de Treinamento';
    FOutputDocs.Author := 'Antigravity AI Suite';
    FOutputDocs.Subject := 'Métricas de Modelagem e Dataset';
    
    FOutputDocs.AddHeading('Relatório de Treinamento de IA', 1);
    FOutputDocs.AddParagraph('Emitido em: ' + DateTimeToStr(Now));
    
    for i := 0 to FReportText.Count - 1 do
    begin
      if FReportText[i] <> '' then
        FOutputDocs.AddParagraph(FReportText[i]);
    end;
    
    FLastResult := 'Documento do relatório configurado com sucesso no TAIOutputDocs.';
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  except
    on E: Exception do
      SetError('Erro ao alimentar TAIOutputDocs: ' + E.Message);
  end;
end;

procedure TAITrainingReport.SaveReport(const AFileName: string);
var
  LList: TStringList;
begin
  ClearError;
  GenerateReportText;
  if FReportText.Count = 0 then Exit;
  
  LList := TStringList.Create;
  try
    try
      LList.Assign(FReportText);
      LList.SaveToFile(AFileName);
      FLastResult := 'Relatório salvo com sucesso em: ' + AFileName;
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
        SetError('Erro ao salvar relatório: ' + E.Message);
    end;
  finally
    LList.Free;
  end;
end;

end.
