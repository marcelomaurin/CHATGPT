unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aigraphmap;

type

  { TfrmGraphMapDemo }

  TfrmGraphMapDemo = class(TForm)
    pnlConfig: TPanel;
    btnLoadDefaults: TButton;
    btnTrain: TButton;
    chkLowerCase: TCheckBox;
    chkRemoveAccents: TCheckBox;
    chkRemoveStopWords: TCheckBox;
    chkDepthSearch: TCheckBox;
    chkNormalize: TCheckBox;
    
    pnlTraining: TPanel;
    lblTrainingTitle: TLabel;
    meTraining: TMemo;
    
    pnlInfer: TPanel;
    lblInferTitle: TLabel;
    lblInput: TLabel;
    edInput: TEdit;
    btnPredict: TButton;
    lblPrediction: TLabel;
    edPrediction: TEdit;
    lblNodesEdges: TLabel;
    
    pnlRanking: TPanel;
    lblRankingTitle: TLabel;
    meRanking: TMemo;
    
    pnlExplanation: TPanel;
    lblExplanationTitle: TLabel;
    meExplanation: TMemo;
    
    pnlFileActions: TPanel;
    btnSaveGraph: TButton;
    btnLoadGraph: TButton;
    btnSaveTraining: TButton;
    btnLoadTraining: TButton;
    
    // Runtime controls
    btnEvaluate: TButton;
    btnConfusionMatrix: TButton;
    btnExportDOT: TButton;
    btnExportGEXF: TButton;
    btnExportCSV: TButton;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadDefaultsClick(Sender: TObject);
    procedure btnTrainClick(Sender: TObject);
    procedure btnPredictClick(Sender: TObject);
    procedure btnSaveGraphClick(Sender: TObject);
    procedure btnLoadGraphClick(Sender: TObject);
    procedure btnSaveTrainingClick(Sender: TObject);
    procedure btnLoadTrainingClick(Sender: TObject);
    procedure ConfigChanged(Sender: TObject);
    procedure btnEvaluateClick(Sender: TObject);
    procedure btnConfusionMatrixClick(Sender: TObject);
    procedure btnExportDOTClick(Sender: TObject);
    procedure btnExportGEXFClick(Sender: TObject);
    procedure btnExportCSVClick(Sender: TObject);
  private
    FGraphMap: TAIGraphMap;
    procedure LogMsg(const AMsg: string);
    procedure UpdateStats;
    procedure SyncConfigToComponent;
  public

  end;

var
  frmGraphMapDemo: TfrmGraphMapDemo;

implementation

{$R *.lfm}

{ TfrmGraphMapDemo }

procedure TfrmGraphMapDemo.FormCreate(Sender: TObject);
begin
  FGraphMap := TAIGraphMap.Create(Self);
  
  // Set default visual checkboxes
  chkLowerCase.Checked := FGraphMap.LowerCaseTokens;
  chkRemoveAccents.Checked := FGraphMap.RemoveAccents;
  chkRemoveStopWords.Checked := FGraphMap.RemoveStopWords;
  chkDepthSearch.Checked := FGraphMap.UseGraphDepthSearch;
  chkNormalize.Checked := FGraphMap.NormalizeScores;
  
  // Dynamic positioning and creation of new controls
  Self.Height := 760;
  pnlTraining.Height := 390;
  pnlInfer.Height := 390;
  pnlRanking.Height := 390;
  pnlFileActions.Height := 170;
  
  btnEvaluate := TButton.Create(Self);
  btnEvaluate.Parent := pnlFileActions;
  btnEvaluate.Left := 0;
  btnEvaluate.Top := 65;
  btnEvaluate.Width := 125;
  btnEvaluate.Height := 25;
  btnEvaluate.Caption := 'Avaliar Acurácia';
  btnEvaluate.OnClick := @btnEvaluateClick;

  btnConfusionMatrix := TButton.Create(Self);
  btnConfusionMatrix.Parent := pnlFileActions;
  btnConfusionMatrix.Left := 135;
  btnConfusionMatrix.Top := 65;
  btnConfusionMatrix.Width := 125;
  btnConfusionMatrix.Height := 25;
  btnConfusionMatrix.Caption := 'Matriz Confusão';
  btnConfusionMatrix.OnClick := @btnConfusionMatrixClick;

  btnExportDOT := TButton.Create(Self);
  btnExportDOT.Parent := pnlFileActions;
  btnExportDOT.Left := 0;
  btnExportDOT.Top := 95;
  btnExportDOT.Width := 125;
  btnExportDOT.Height := 25;
  btnExportDOT.Caption := 'Exportar DOT';
  btnExportDOT.OnClick := @btnExportDOTClick;

  btnExportGEXF := TButton.Create(Self);
  btnExportGEXF.Parent := pnlFileActions;
  btnExportGEXF.Left := 135;
  btnExportGEXF.Top := 95;
  btnExportGEXF.Width := 125;
  btnExportGEXF.Height := 25;
  btnExportGEXF.Caption := 'Exportar GEXF';
  btnExportGEXF.OnClick := @btnExportGEXFClick;

  btnExportCSV := TButton.Create(Self);
  btnExportCSV.Parent := pnlFileActions;
  btnExportCSV.Left := 0;
  btnExportCSV.Top := 125;
  btnExportCSV.Width := 260;
  btnExportCSV.Height := 25;
  btnExportCSV.Caption := 'Exportar CSV (Nós/Arestas)';
  btnExportCSV.OnClick := @btnExportCSVClick;
  
  btnLoadDefaultsClick(Self);
  LogMsg('TAIGraphMap Demo iniciado e pronto com recursos avançados.');
  UpdateStats;
end;

procedure TfrmGraphMapDemo.FormDestroy(Sender: TObject);
begin
  // FGraphMap is freed by Owner (Self)
end;

procedure TfrmGraphMapDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmGraphMapDemo.UpdateStats;
begin
  lblNodesEdges.Caption := Format('Grafo: %d nós, %d ramos', [FGraphMap.NodeCount, FGraphMap.EdgeCount]);
end;

procedure TfrmGraphMapDemo.SyncConfigToComponent;
begin
  FGraphMap.LowerCaseTokens := chkLowerCase.Checked;
  FGraphMap.RemoveAccents := chkRemoveAccents.Checked;
  FGraphMap.RemoveStopWords := chkRemoveStopWords.Checked;
  FGraphMap.UseGraphDepthSearch := chkDepthSearch.Checked;
  FGraphMap.NormalizeScores := chkNormalize.Checked;
end;

procedure TfrmGraphMapDemo.ConfigChanged(Sender: TObject);
begin
  SyncConfigToComponent;
  LogMsg('Configurações atualizadas no componente.');
end;

procedure TfrmGraphMapDemo.btnLoadDefaultsClick(Sender: TObject);
begin
  meTraining.Lines.Clear;
  meTraining.Lines.Add('erro ao conectar no postgres -> banco_dados');
  meTraining.Lines.Add('falha na porta serial do equipamento -> hardware_serial');
  meTraining.Lines.Add('impressora não imprime -> impressora');
  meTraining.Lines.Add('não consigo abrir o sistema hygia -> sistemas');
  meTraining.Lines.Add('computador não liga -> hardware');
  meTraining.Lines.Add('impressora sem papel -> impressora');
  meTraining.Lines.Add('erro de rede cabo desligado -> rede');
  LogMsg('Exemplos de treinamento padrão carregados.');
end;

procedure TfrmGraphMapDemo.btnTrainClick(Sender: TObject);
var
  i: Integer;
  Line: string;
  SepIdx: Integer;
  InputPart, CatPart: string;
  Item: TAITrainingItem;
begin
  SyncConfigToComponent;
  FGraphMap.ClearTraining;
  
  LogMsg('Lendo conjunto de treinamento...');
  for i := 0 to meTraining.Lines.Count - 1 do
  begin
    Line := Trim(meTraining.Lines[i]);
    if Line = '' then Continue;
    
    SepIdx := Pos('->', Line);
    if SepIdx > 0 then
    begin
      InputPart := Trim(Copy(Line, 1, SepIdx - 1));
      CatPart := Trim(Copy(Line, SepIdx + 2, Length(Line)));
      
      if (InputPart <> '') and (CatPart <> '') then
      begin
        Item := FGraphMap.Training.Add;
        Item.InputText := InputPart;
        Item.OutputCategory := CatPart;
        Item.Weight := 1.0;
      end;
    end;
  end;
  
  LogMsg(Format('Iniciando treinamento com %d itens...', [FGraphMap.Training.Count]));
  FGraphMap.Train;
  
  LogMsg(FGraphMap.LastResult);
  UpdateStats;
  ShowMessage('Treinamento concluído!');
end;

procedure TfrmGraphMapDemo.btnPredictClick(Sender: TObject);
var
  Cat: string;
begin
  SyncConfigToComponent;
  if FGraphMap.NodeCount = 0 then
  begin
    ShowMessage('Por favor, treine o grafo antes de realizar predições.');
    Exit;
  end;
  
  LogMsg('Classificando texto: "' + edInput.Text + '"');
  Cat := FGraphMap.Predict(edInput.Text);
  
  edPrediction.Text := Cat;
  meRanking.Lines.Assign(FGraphMap.LastRanking);
  meExplanation.Lines.Assign(FGraphMap.LastExplanation);
  
  LogMsg('Predição: ' + Cat);
end;

procedure TfrmGraphMapDemo.btnSaveGraphClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Salvar Grafo de IA';
    SaveDlg.Filter := 'Grafos JSON (*.json)|*.json';
    SaveDlg.DefaultExt := 'json';
    if SaveDlg.Execute then
    begin
      FGraphMap.SaveGraphToFile(SaveDlg.FileName);
      LogMsg('Grafo salvo com sucesso em: ' + SaveDlg.FileName);
      ShowMessage('Grafo salvo com sucesso!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnLoadGraphClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Carregar Grafo de IA';
    OpenDlg.Filter := 'Grafos JSON (*.json)|*.json';
    if OpenDlg.Execute then
    begin
      FGraphMap.LoadGraphFromFile(OpenDlg.FileName);
      LogMsg('Grafo carregado de: ' + OpenDlg.FileName);
      UpdateStats;
      ShowMessage('Grafo carregado com sucesso!');
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnSaveTrainingClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Salvar Dados de Treinamento';
    SaveDlg.Filter := 'Treino JSON (*.json)|*.json';
    SaveDlg.DefaultExt := 'json';
    if SaveDlg.Execute then
    begin
      btnTrainClick(Self); // Refresh FGraphMap.Training from Memo
      FGraphMap.SaveTrainingToFile(SaveDlg.FileName);
      LogMsg('Dados de treinamento salvos em: ' + SaveDlg.FileName);
      ShowMessage('Dados de treinamento salvos!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnLoadTrainingClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  i: Integer;
  Item: TAITrainingItem;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Carregar Dados de Treinamento';
    OpenDlg.Filter := 'Treino JSON (*.json)|*.json';
    if OpenDlg.Execute then
    begin
      FGraphMap.LoadTrainingFromFile(OpenDlg.FileName);
      
      // Update Training Memo
      meTraining.Lines.Clear;
      for i := 0 to FGraphMap.Training.Count - 1 do
      begin
        Item := FGraphMap.Training.Items[i];
        meTraining.Lines.Add(Item.InputText + ' -> ' + Item.OutputCategory);
      end;
      
      LogMsg('Dados de treinamento carregados de: ' + OpenDlg.FileName);
      ShowMessage('Treino carregado! Clique em "Treinar Grafo" para atualizar o modelo.');
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnEvaluateClick(Sender: TObject);
var
  LAccuracy: Double;
begin
  if FGraphMap.NodeCount = 0 then
  begin
    ShowMessage('Treine o grafo antes de avaliar.');
    Exit;
  end;
  
  LAccuracy := FGraphMap.Evaluate(FGraphMap.Training);
  LogMsg(Format('Avaliação de acurácia no conjunto de treino: %0.2f%%', [LAccuracy]));
  ShowMessage(Format('Acurácia obtida: %0.2f%%', [LAccuracy]));
end;

procedure TfrmGraphMapDemo.btnConfusionMatrixClick(Sender: TObject);
var
  LResult: TStringList;
begin
  if FGraphMap.NodeCount = 0 then
  begin
    ShowMessage('Treine o grafo antes de obter a matriz.');
    Exit;
  end;
  
  LResult := TStringList.Create;
  try
    FGraphMap.ConfusionMatrix(FGraphMap.Training, LResult);
    meExplanation.Lines.Clear;
    meExplanation.Lines.Add('=== Matriz de Confusão ===');
    meExplanation.Lines.AddStrings(LResult);
    LogMsg('Matriz de Confusão gerada com sucesso.');
  finally
    LResult.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnExportDOTClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if FGraphMap.NodeCount = 0 then
  begin
    ShowMessage('Treine o grafo antes de exportar.');
    Exit;
  end;
  
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Exportar Grafo para DOT (GraphViz)';
    SaveDlg.Filter := 'Arquivo DOT (*.dot)|*.dot';
    SaveDlg.DefaultExt := 'dot';
    if SaveDlg.Execute then
    begin
      FGraphMap.SaveGraphAsDOT(SaveDlg.FileName);
      LogMsg('Grafo exportado para DOT: ' + SaveDlg.FileName);
      ShowMessage('Grafo exportado para DOT com sucesso!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnExportGEXFClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if FGraphMap.NodeCount = 0 then
  begin
    ShowMessage('Treine o grafo antes de exportar.');
    Exit;
  end;
  
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Exportar Grafo para GEXF (Gephi)';
    SaveDlg.Filter := 'Arquivo GEXF (*.gexf)|*.gexf';
    SaveDlg.DefaultExt := 'gexf';
    if SaveDlg.Execute then
    begin
      FGraphMap.SaveGraphAsGEXF(SaveDlg.FileName);
      LogMsg('Grafo exportado para GEXF: ' + SaveDlg.FileName);
      ShowMessage('Grafo exportado para GEXF com sucesso!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmGraphMapDemo.btnExportCSVClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
  LNodeFile, LEdgeFile: string;
begin
  if FGraphMap.NodeCount = 0 then
  begin
    ShowMessage('Treine o grafo antes de exportar.');
    Exit;
  end;
  
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Exportar Grafo para CSV (Nós/Arestas)';
    SaveDlg.Filter := 'Arquivo CSV de Nós (*_nodes.csv)|*_nodes.csv';
    SaveDlg.DefaultExt := 'csv';
    if SaveDlg.Execute then
    begin
      LNodeFile := SaveDlg.FileName;
      if Pos('_nodes.csv', LNodeFile) > 0 then
        LEdgeFile := StringReplace(LNodeFile, '_nodes.csv', '_edges.csv', [])
      else
        LEdgeFile := ChangeFileExt(LNodeFile, '') + '_edges.csv';
        
      FGraphMap.SaveGraphAsCSV(LNodeFile, LEdgeFile);
      LogMsg('Grafo exportado para CSV: ' + LNodeFile + ' e ' + LEdgeFile);
      ShowMessage('Grafo exportado para CSV com sucesso!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

end.
