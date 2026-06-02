unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  perceptron;

type

  { TfrmPerceptronDemo }

  TfrmPerceptronDemo = class(TForm)
    pnlConfig: TPanel;
    lblLearningRate: TLabel;
    edLearningRate: TEdit;
    lblEpochs: TLabel;
    edEpochs: TEdit;
    lblGate: TLabel;
    cbGate: TComboBox;
    btnTrain: TButton;
    
    pnlInfer: TPanel;
    lblInferTitle: TLabel;
    lblInput1: TLabel;
    edInput1: TEdit;
    lblInput2: TLabel;
    edInput2: TEdit;
    btnPredict: TButton;
    lblPrediction: TLabel;
    edPrediction: TEdit;
    
    pnlSave: TPanel;
    lblSaveTitle: TLabel;
    btnSaveModel: TButton;
    btnLoadModel: TButton;
    
    pnlWeights: TPanel;
    lblWeightsTitle: TLabel;
    lblW1: TLabel;
    lblW2: TLabel;
    lblBias: TLabel;
    edW1: TEdit;
    edW2: TEdit;
    edBias: TEdit;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTrainClick(Sender: TObject);
    procedure btnPredictClick(Sender: TObject);
    procedure btnSaveModelClick(Sender: TObject);
    procedure btnLoadModelClick(Sender: TObject);
  private
    FPerceptron: TPerceptron;
    procedure LogMsg(const AMsg: string);
    procedure UpdateWeightsDisplay;
  public

  end;

var
  frmPerceptronDemo: TfrmPerceptronDemo;

implementation

{$R *.lfm}

{ TfrmPerceptronDemo }

procedure TfrmPerceptronDemo.FormCreate(Sender: TObject);
begin
  FPerceptron := TPerceptron.Create(Self);
  cbGate.Items.Clear;
  cbGate.Items.Add('AND (Porta E)');
  cbGate.Items.Add('OR (Porta OU)');
  cbGate.Items.Add('NAND (Porta NÃO-E)');
  cbGate.Items.Add('NOR (Porta NÃO-OU)');
  cbGate.ItemIndex := 0;
  
  LogMsg('Perceptron Rosenblatt iniciado e pronto.');
  LogMsg('Escolha uma porta lógica e clique em Iniciar Treinamento.');
  UpdateWeightsDisplay;
end;

procedure TfrmPerceptronDemo.FormDestroy(Sender: TObject);
begin
  // FPerceptron é autoliberado pelo Owner
end;

procedure TfrmPerceptronDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmPerceptronDemo.UpdateWeightsDisplay;
begin
  if (FPerceptron <> nil) and (FPerceptron.InputSize = 2) then
  begin
    edW1.Text := Format('%0.6f', [FPerceptron.Weights[0]]);
    edW2.Text := Format('%0.6f', [FPerceptron.Weights[1]]);
    edBias.Text := Format('%0.6f', [FPerceptron.Bias]);
  end
  else
  begin
    edW1.Text := 'N/A';
    edW2.Text := 'N/A';
    edBias.Text := 'N/A';
  end;
end;

procedure TfrmPerceptronDemo.btnTrainClick(Sender: TObject);
var
  LR: Double;
  EpochsCount: Integer;
  Inputs: TDoubleMatrix;
  Targets: TIntegerArray;
  FinalError: Double;
begin
  LR := StrToFloatDef(edLearningRate.Text, 0.1);
  EpochsCount := StrToIntDef(edEpochs.Text, 100);
  
  LogMsg(Format('Inicializando Perceptron (2 entradas, LR = %0.3f)...', [LR]));
  FPerceptron.Initialize(2, LR);
  
  // Define dataset com base no gate selecionado
  SetLength(Inputs, 4);
  SetLength(Inputs[0], 2); Inputs[0, 0] := 0; Inputs[0, 1] := 0;
  SetLength(Inputs[1], 2); Inputs[1, 0] := 0; Inputs[1, 1] := 1;
  SetLength(Inputs[2], 2); Inputs[2, 0] := 1; Inputs[2, 1] := 0;
  SetLength(Inputs[3], 2); Inputs[3, 0] := 1; Inputs[3, 1] := 1;
  
  SetLength(Targets, 4);
  
  case cbGate.ItemIndex of
    0: // AND
      begin
        Targets[0] := 0;
        Targets[1] := 0;
        Targets[2] := 0;
        Targets[3] := 1;
        LogMsg('Treinando Perceptron para a porta lógica AND...');
      end;
    1: // OR
      begin
        Targets[0] := 0;
        Targets[1] := 1;
        Targets[2] := 1;
        Targets[3] := 1;
        LogMsg('Treinando Perceptron para a porta lógica OR...');
      end;
    2: // NAND
      begin
        Targets[0] := 1;
        Targets[1] := 1;
        Targets[2] := 1;
        Targets[3] := 0;
        LogMsg('Treinando Perceptron para a porta lógica NAND...');
      end;
    3: // NOR
      begin
        Targets[0] := 1;
        Targets[1] := 0;
        Targets[2] := 0;
        Targets[3] := 0;
        LogMsg('Treinando Perceptron para a porta lógica NOR...');
      end;
  end;
  
  FPerceptron.TrainEpochs(Inputs, Targets, EpochsCount, FinalError);
  
  LogMsg(Format('Treinamento finalizado. Erro Médio Absoluto Final: %0.6f', [FinalError]));
  UpdateWeightsDisplay;
  
  if FinalError = 0.0 then
    LogMsg('Sucesso: Perceptron convergiu com 0 erros!')
  else
    LogMsg('Aviso: Perceptron não convergiu totalmente dentro das épocas estipuladas. Experimente aumentar as épocas ou ajustar a Taxa de Aprendizado.');
    
  ShowMessage(Format('Treino Concluído! Erro final: %0.6f', [FinalError]));
end;

procedure TfrmPerceptronDemo.btnPredictClick(Sender: TObject);
var
  InArr: TDoubleArray;
  Prediction: Integer;
begin
  if FPerceptron.InputSize <> 2 then
  begin
    ShowMessage('Por favor, inicialize e treine o Perceptron antes de realizar predições.');
    Exit;
  end;

  SetLength(InArr, 2);
  InArr[0] := StrToFloatDef(edInput1.Text, 0);
  InArr[1] := StrToFloatDef(edInput2.Text, 0);
  
  LogMsg(Format('Inferencia para entradas: [%0.1f, %0.1f]...', [InArr[0], InArr[1]]));
  
  Prediction := FPerceptron.Predict(InArr);
  edPrediction.Text := IntToStr(Prediction);
  LogMsg('Resultado predito da saída (0 ou 1): ' + edPrediction.Text);
end;

procedure TfrmPerceptronDemo.btnSaveModelClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if FPerceptron.InputSize = 0 then
  begin
    ShowMessage('Nenhum modelo inicializado para salvar.');
    Exit;
  end;

  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Salvar pesos do Perceptron';
    SaveDlg.Filter := 'Modelos Perceptron (*.perc)|*.perc';
    SaveDlg.DefaultExt := 'perc';
    if SaveDlg.Execute then
    begin
      FPerceptron.SaveToFile(SaveDlg.FileName);
      LogMsg('Modelo salvo com sucesso: ' + SaveDlg.FileName);
      ShowMessage('Modelo salvo com sucesso!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmPerceptronDemo.btnLoadModelClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Carregar pesos do Perceptron';
    OpenDlg.Filter := 'Modelos Perceptron (*.perc)|*.perc';
    if OpenDlg.Execute then
    begin
      if FileExists(OpenDlg.FileName) then
      begin
        FPerceptron.LoadFromFile(OpenDlg.FileName);
        LogMsg('Modelo carregado com sucesso do arquivo: ' + OpenDlg.FileName);
        UpdateWeightsDisplay;
        ShowMessage('Modelo carregado com sucesso!');
      end
      else
        ShowMessage('Arquivo não encontrado.');
    end;
  finally
    OpenDlg.Free;
  end;
end;

end.
