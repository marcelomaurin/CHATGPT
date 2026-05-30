unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Math, pythonconnector, lstmpredictor;

type

  { TfrmLSTMDemo }

  TfrmLSTMDemo = class(TForm)
    pnlConfig: TPanel;
    lblDLLPath: TLabel;
    edDLLPath: TEdit;
    btnInitPython: TButton;
    btnInstallDeps: TButton;
    
    pnlTrain: TPanel;
    lblWindowSize: TLabel;
    edWindowSize: TEdit;
    lblEpochs: TLabel;
    edEpochs: TEdit;
    btnGenerateData: TButton;
    btnTrainLSTM: TButton;
    btnPredict: TButton;
    
    pnlVisual: TPanel;
    lblVisualTitle: TLabel;
    imgChart: TImage;
    
    lstActual: TListBox;
    lblActualList: TLabel;
    lstPredicted: TListBox;
    lblPredictedList: TLabel;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitPythonClick(Sender: TObject);
    procedure btnInstallDepsClick(Sender: TObject);
    procedure btnGenerateDataClick(Sender: TObject);
    procedure btnTrainLSTMClick(Sender: TObject);
    procedure btnPredictClick(Sender: TObject);
  private
    FPython: TPythonConnector;
    FModel: TLSTMPredictor;
    FSeriesData: TDoubleArray;
    FPredictedData: TDoubleArray;
    FWindowSize: Integer;
    procedure LogMsg(const AMsg: string);
    procedure DrawChart;
  public

  end;

var
  frmLSTMDemo: TfrmLSTMDemo;

implementation

{$R *.lfm}

{ TfrmLSTMDemo }

procedure TfrmLSTMDemo.FormCreate(Sender: TObject);
begin
  FPython := TPythonConnector.Create(Self);
  FModel := TLSTMPredictor.Create(Self);
  
  FModel.PythonConnector := FPython;
  
  edDLLPath.Text := 'python3.dll';
  FWindowSize := 5;

  LogMsg('Previsor de Séries Temporais LSTM (Rede Recorrente) iniciado.');
  LogMsg('1. Defina o caminho do interpretador Python.');
  LogMsg('2. Clique em "Ativar Interpretador".');
  LogMsg('3. Se for a primeira execução, instale as dependências (numpy e tensorflow).');
  LogMsg('4. Clique em "Gerar Série Temporal" para obter a série senoidal com ruído.');
  LogMsg('5. Clique em "Treinar Rede LSTM" e "Prever Próximos Passos".');
  
  btnGenerateDataClick(nil);
end;

procedure TfrmLSTMDemo.FormDestroy(Sender: TObject);
begin
  // FPython e FModel são autoliberados pelo Owner (Self)
end;

procedure TfrmLSTMDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmLSTMDemo.btnInitPythonClick(Sender: TObject);
begin
  if FPython.Active then
  begin
    FPython.Active := False;
    btnInitPython.Caption := 'Ativar Interpretador';
    LogMsg('Interpretador Python desativado.');
  end
  else
  begin
    FPython.DLLPath := edDLLPath.Text;
    LogMsg('Carregando interpretador do Python: ' + FPython.DLLPath + '...');
    FPython.Active := True;
    
    if FPython.IsInitialized then
    begin
      btnInitPython.Caption := 'Desativar Interpretador';
      LogMsg('Interpretador Python carregado e inicializado com sucesso!');
      LogMsg('Versão: ' + FPython.Version);
    end
    else
    begin
      LogMsg('Erro ao inicializar Python: ' + FPython.LastError);
      ShowMessage('Falha ao carregar DLL do Python. Verifique o caminho/arquitetura.');
    end;
  end;
end;

procedure TfrmLSTMDemo.btnInstallDepsClick(Sender: TObject);
begin
  if not FPython.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de continuar.');
    Exit;
  end;

  LogMsg('Executando instalação silenciosa das bibliotecas numpy e tensorflow via pip...');
  LogMsg('Este procedimento pode levar de 2 a 5 minutos na primeira execução...');
  Application.ProcessMessages;

  if FModel.InstallDependencies then
  begin
    LogMsg('Dependências (numpy e tensorflow) instaladas com sucesso!');
    ShowMessage('Dependências instaladas com sucesso!');
  end
  else
  begin
    LogMsg('Erro ao instalar dependências: ' + FModel.LastError);
    ShowMessage('Falha na instalação. Consulte o log para detalhes.');
  end;
end;

procedure TfrmLSTMDemo.btnGenerateDataClick(Sender: TObject);
var
  I: Integer;
  Val: Double;
begin
  SetLength(FSeriesData, 40);
  lstActual.Items.Clear;
  lstPredicted.Items.Clear;
  SetLength(FPredictedData, 0);

  Randomize;
  LogMsg('Gerando série temporal (curva senoidal com ruído aleatório)...');
  for I := 0 to 39 do
  begin
    // Gera valor senoidal + ruído aleatório pequeno
    Val := Sin(I / 3.0) * 1.5 + (Random - 0.5) * 0.2;
    FSeriesData[I] := Val;
    lstActual.Items.Add(Format('%d: %0.4f', [I + 1, Val]));
  end;

  DrawChart;
  LogMsg('Série temporal gerada com sucesso.');
end;

procedure TfrmLSTMDemo.DrawChart;
var
  W, H, I: Integer;
  XStep, YScale: Double;
  X, Y: Integer;
begin
  W := imgChart.Width;
  H := imgChart.Height;

  imgChart.Canvas.Brush.Color := clWhite;
  imgChart.Canvas.FillRect(imgChart.ClientRect);

  // Desenha linha de base central
  imgChart.Canvas.Pen.Color := clSilver;
  imgChart.Canvas.Pen.Style := psDash;
  imgChart.Canvas.MoveTo(0, H div 2);
  imgChart.Canvas.LineTo(W, H div 2);

  // Plota série real em Verde
  if Length(FSeriesData) > 0 then
  begin
    XStep := W / 50.0;
    YScale := H / 5.0; // Escala vertical
    
    imgChart.Canvas.Pen.Color := RGBToColor(46, 125, 50); // Verde Escuro
    imgChart.Canvas.Pen.Style := psSolid;
    imgChart.Canvas.Pen.Width := 2;

    for I := 0 to High(FSeriesData) do
    begin
      X := Round(I * XStep);
      Y := Round((H div 2) - (FSeriesData[I] * YScale));
      if I = 0 then
        imgChart.Canvas.MoveTo(X, Y)
      else
        imgChart.Canvas.LineTo(X, Y);
    end;
  end;

  // Plota projeção predita em Vermelho
  if Length(FPredictedData) > 0 then
  begin
    imgChart.Canvas.Pen.Color := clRed;
    imgChart.Canvas.Pen.Style := psSolid;
    imgChart.Canvas.Pen.Width := 2;

    for I := 0 to High(FPredictedData) do
    begin
      X := Round((Length(FSeriesData) + I) * XStep);
      Y := Round((H div 2) - (FPredictedData[I] * YScale));
      if I = 0 then
        imgChart.Canvas.MoveTo(X, Y)
      else
        imgChart.Canvas.LineTo(X, Y);
    end;
  end;
end;

procedure TfrmLSTMDemo.btnTrainLSTMClick(Sender: TObject);
var
  EpochsCount: Integer;
begin
  if not FPython.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de treinar a rede LSTM.');
    Exit;
  end;

  FWindowSize := StrToIntDef(edWindowSize.Text, 5);
  EpochsCount := StrToIntDef(edEpochs.Text, 100);

  LogMsg(Format('Treinando rede recorrente LSTM (Janela = %d, Épocas = %d)...', [FWindowSize, EpochsCount]));
  LogMsg('Aguarde, processando épocas no TensorFlow...');
  Application.ProcessMessages;

  if FModel.TrainLSTM(FSeriesData, FWindowSize, EpochsCount) then
  begin
    LogMsg('Treinamento LSTM concluído com sucesso!');
    ShowMessage('Treinamento concluído com sucesso!');
  end
  else
  begin
    LogMsg('Erro no treinamento da rede LSTM: ' + FModel.LastError);
    ShowMessage('Falha ao treinar modelo LSTM.');
  end;
end;

procedure TfrmLSTMDemo.btnPredictClick(Sender: TObject);
var
  Window: TDoubleArray;
  NextVal: Double;
  I, J: Integer;
begin
  if not FPython.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de predizer.');
    Exit;
  end;

  FWindowSize := StrToIntDef(edWindowSize.Text, 5);
  lstPredicted.Items.Clear;
  SetLength(FPredictedData, 10); // Prever os próximos 10 passos sequenciais (Rolling Forecast)

  SetLength(Window, FWindowSize);

  // Copia a última janela de dados reais para iniciar a projeção contínua
  for I := 0 to FWindowSize - 1 do
  begin
    Window[I] := FSeriesData[Length(FSeriesData) - FWindowSize + I];
  end;

  LogMsg('Executando Rolling Forecast (projeção contínua de 10 passos à frente)...');

  for I := 0 to 9 do
  begin
    if FModel.PredictNext(Window, NextVal) then
    begin
      FPredictedData[I] := NextVal;
      lstPredicted.Items.Add(Format('%d: %0.4f', [Length(FSeriesData) + I + 1, NextVal]));

      // Desloca a janela para incluir o valor predito (Rolling Forecast feed-forward)
      for J := 0 to FWindowSize - 2 do
      begin
        Window[J] := Window[J + 1];
      end;
      Window[FWindowSize - 1] := NextVal;
    end
    else
    begin
      LogMsg('Erro ao prever passo ' + IntToStr(I + 1) + ': ' + FModel.LastError);
      Break;
    end;
  end;

  DrawChart;
  LogMsg('Previsão sequencial finalizada. Curva de tendência vermelha desenhada no gráfico.');
end;

end.
