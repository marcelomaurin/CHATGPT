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
  
  btnLoadDefaultsClick(Self);
  LogMsg('TAIGraphMap Demo iniciado e pronto.');
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
      FGraphMap.LoadTrainingToFile(OpenDlg.FileName);
      
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

end.
