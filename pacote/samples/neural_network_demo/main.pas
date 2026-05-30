unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  NeuralNetwork;

type

  { TfrmNeuralDemo }

  TfrmNeuralDemo = class(TForm)
    pnlConfig: TPanel;
    lblLearningRate: TLabel;
    edLearningRate: TEdit;
    lblHidden: TLabel;
    edHidden: TEdit;
    lblEpochs: TLabel;
    edEpochs: TEdit;
    lblActivation: TLabel;
    cbActivation: TComboBox;
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
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTrainClick(Sender: TObject);
    procedure btnPredictClick(Sender: TObject);
    procedure btnSaveModelClick(Sender: TObject);
    procedure btnLoadModelClick(Sender: TObject);
  private
    FNeuralNet: TNeuralNetwork;
    procedure LogMsg(const AMsg: string);
  public

  end;

var
  frmNeuralDemo: TfrmNeuralDemo;

implementation

{$R *.lfm}

{ TfrmNeuralDemo }

procedure TfrmNeuralDemo.FormCreate(Sender: TObject);
begin
  FNeuralNet := TNeuralNetwork.Create(Self);
  cbActivation.Items.Clear;
  cbActivation.Items.Add('Sigmoid (padrão)');
  cbActivation.Items.Add('ReLU');
  cbActivation.Items.Add('Tanh');
  cbActivation.ItemIndex := 0;
  
  LogMsg('Rede Neural iniciada e pronta.');
  LogMsg('Use os botões para configurar e treinar a rede para resolver a lógica XOR.');
end;

procedure TfrmNeuralDemo.FormDestroy(Sender: TObject);
begin
  // FNeuralNet é auto-liberado pelo Owner (Self)
end;

procedure TfrmNeuralDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmNeuralDemo.btnTrainClick(Sender: TObject);
var
  LR: Double;
  Hiddens, EpochsCount: Integer;
  Inputs, Targets: TMatrix;
  FinalLoss: Double;
begin
  LR := StrToFloatDef(edLearningRate.Text, 0.1);
  Hiddens := StrToIntDef(edHidden.Text, 4);
  EpochsCount := StrToIntDef(edEpochs.Text, 5000);
  
  LogMsg(Format('Inicializando Rede Neural (2 entradas, %d ocultos, 1 saída, LR = %0.3f)...', [Hiddens, LR]));
  FNeuralNet.Initialize(2, Hiddens, 1, LR);
  
  case cbActivation.ItemIndex of
    0: FNeuralNet.ActivationType := atSigmoid;
    1: FNeuralNet.ActivationType := atReLU;
    2: FNeuralNet.ActivationType := atTanh;
  end;
  
  // Dataset XOR clássico
  SetLength(Inputs, 4);
  SetLength(Inputs[0], 2); Inputs[0, 0] := 0; Inputs[0, 1] := 0;
  SetLength(Inputs[1], 2); Inputs[1, 0] := 0; Inputs[1, 1] := 1;
  SetLength(Inputs[2], 2); Inputs[2, 0] := 1; Inputs[2, 1] := 0;
  SetLength(Inputs[3], 2); Inputs[3, 0] := 1; Inputs[3, 1] := 1;
  
  SetLength(Targets, 4);
  SetLength(Targets[0], 1); Targets[0, 0] := 0;
  SetLength(Targets[1], 1); Targets[1, 0] := 1;
  SetLength(Targets[2], 1); Targets[2, 0] := 1;
  SetLength(Targets[3], 1); Targets[3, 0] := 0;
  
  LogMsg('Treinando Rede Neural localmente...');
  
  // Realiza treinamento em lote por épocas
  FNeuralNet.TrainEpochs(Inputs, Targets, EpochsCount, FinalLoss);
  
  LogMsg(Format('Treinamento finalizado em %d épocas com MSE Loss: %0.6f', [EpochsCount, FinalLoss]));
  ShowMessage(Format('Treino Concluído com MSE Loss final: %0.6f!', [FinalLoss]));
end;

procedure TfrmNeuralDemo.btnPredictClick(Sender: TObject);
var
  InArr, OutArr: TArray;
begin
  SetLength(InArr, 2);
  InArr[0] := StrToFloatDef(edInput1.Text, 0);
  InArr[1] := StrToFloatDef(edInput2.Text, 0);
  
  LogMsg(Format('Predizendo para as entradas: [%0.1f, %0.1f]...', [InArr[0], InArr[1]]));
  
  OutArr := FNeuralNet.Predict(InArr);
  
  if Length(OutArr) > 0 then
  begin
    edPrediction.Text := Format('%0.6f', [OutArr[0]]);
    LogMsg('Resultado predito da saída: ' + edPrediction.Text);
  end
  else
    LogMsg('Nenhum resultado retornado da predição.');
end;

procedure TfrmNeuralDemo.btnSaveModelClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Salvar pesos da Rede Neural';
    SaveDlg.Filter := 'Redes Neurais (*.net)|*.net';
    SaveDlg.DefaultExt := 'net';
    if SaveDlg.Execute then
    begin
      FNeuralNet.SaveNetwork(SaveDlg.FileName);
      LogMsg('Modelo salvo com sucesso no arquivo: ' + SaveDlg.FileName);
      ShowMessage('Modelo salvo!');
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmNeuralDemo.btnLoadModelClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Carregar pesos da Rede Neural';
    OpenDlg.Filter := 'Redes Neurais (*.net)|*.net';
    if OpenDlg.Execute then
    begin
      if FileExists(OpenDlg.FileName) then
      begin
        FNeuralNet.LoadNetwork(OpenDlg.FileName);
        LogMsg('Modelo de rede carregado com sucesso do arquivo: ' + OpenDlg.FileName);
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
