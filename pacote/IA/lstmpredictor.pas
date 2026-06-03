unit lstmpredictor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pythonconnector, LResources;

type
  TDoubleArray = array of Double;

  { TLSTMPredictor }

  TLSTMPredictor = class(TComponent)
  private
    FPythonConnector: TPythonConnector;
    FLastError: string;
    FPreferProcessMode: Boolean;
    procedure SetPythonConnector(const AValue: TPythonConnector);
    procedure PrepareConnector;
    function ArrayToPythonList(const AArray: TDoubleArray): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    // Instala numpy e tensorflow no Python associado para uso da LSTM
    function InstallDependencies: Boolean;

    // Constrói e treina localmente um modelo LSTM simples baseado em uma série temporal
    // AWindowSize especifica quantos passos no passado são usados para prever o próximo.
    function TrainLSTM(const ATimeSeries: TDoubleArray; AWindowSize, AEpochs: Integer): Boolean;

    // Prediz o próximo passo temporal com base nos últimos valores fornecidos (tamanho deve ser AWindowSize)
    function PredictNext(const ALastWindow: TDoubleArray; out APredictedValue: Double): Boolean;
  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;
    property PreferProcessMode: Boolean read FPreferProcessMode write FPreferProcessMode default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TLSTMPredictor]);
end;

{ TLSTMPredictor }

constructor TLSTMPredictor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPythonConnector := nil;
  FLastError := '';
  FPreferProcessMode := True;
end;

procedure TLSTMPredictor.PrepareConnector;
begin
  if (FPythonConnector <> nil) and not FPythonConnector.Active and FPreferProcessMode then
  begin
    FPythonConnector.ExecutionMode := pemProcess;
  end;
end;

procedure TLSTMPredictor.SetPythonConnector(const AValue: TPythonConnector);
begin
  if FPythonConnector = AValue then Exit;
  FPythonConnector := AValue;
  if FPythonConnector <> nil then
  begin
    FPythonConnector.FreeNotification(Self);
    PrepareConnector;
  end;
end;

procedure TLSTMPredictor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPythonConnector) then
    FPythonConnector := nil;
end;

function TLSTMPredictor.ArrayToPythonList(const AArray: TDoubleArray): string;
var
  I: Integer;
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.'; // Garante que floats sejam representados com ponto decimal para o Python

  Result := '[';
  for I := 0 to High(AArray) do
  begin
    if I = High(AArray) then
      Result := Result + FloatToStr(AArray[I], FS)
    else
      Result := Result + FloatToStr(AArray[I], FS) + ', ';
  end;
  Result := Result + ']';
end;

function TLSTMPredictor.InstallDependencies: Boolean;
begin
  Result := False;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  PrepareConnector;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  // Executa pip install de dentro do Python para instalar numpy e tensorflow
  Result := FPythonConnector.ExecString(
    'import subprocess, sys' + sLineBreak +
    'try:' + sLineBreak +
    '    subprocess.check_call([sys.executable, "-m", "pip", "install", "numpy", "tensorflow"])' + sLineBreak +
    '    dep_success = True' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    dep_success = False' + sLineBreak +
    '    dep_error = str(e)'
  );

  if not Result then
    FLastError := FPythonConnector.LastError
  else
  begin
    if FPythonConnector.GetVar('dep_success') <> 'True' then
    begin
      FLastError := FPythonConnector.GetVar('dep_error');
      Result := False;
    end
    else
      Result := True;
  end;
end;

function TLSTMPredictor.TrainLSTM(const ATimeSeries: TDoubleArray; AWindowSize, AEpochs: Integer): Boolean;
var
  PyScript: string;
  DataListStr: string;
begin
  Result := False;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  PrepareConnector;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  if Length(ATimeSeries) <= AWindowSize then
  begin
    FLastError := 'O tamanho da série temporal deve ser maior que o tamanho da janela.';
    Exit;
  end;

  DataListStr := ArrayToPythonList(ATimeSeries);

  // Script para criar e treinar a rede recorrente LSTM de previsão local no interpretador
  PyScript :=
    'import numpy as np' + sLineBreak +
    'import tensorflow as tf' + sLineBreak +
    'from tensorflow.keras.models import Sequential' + sLineBreak +
    'from tensorflow.keras.layers import LSTM, Dense' + sLineBreak +
    'try:' + sLineBreak +
    '    data = np.array(' + DataListStr + ')' + sLineBreak +
    '    window_size = ' + IntToStr(AWindowSize) + sLineBreak +
    '    X, y = [], []' + sLineBreak +
    '    for i in range(len(data) - window_size):' + sLineBreak +
    '        X.append(data[i:i+window_size])' + sLineBreak +
    '        y.append(data[i+window_size])' + sLineBreak +
    '    X = np.array(X)' + sLineBreak +
    '    y = np.array(y)' + sLineBreak +
    '    X = np.reshape(X, (X.shape[0], X.shape[1], 1))' + sLineBreak +
    '    ' + sLineBreak +
    '    # Configura o modelo de rede recorrente LSTM' + sLineBreak +
    '    lstm_model = Sequential()' + sLineBreak +
    '    lstm_model.add(LSTM(32, activation="tanh", input_shape=(window_size, 1)))' + sLineBreak +
    '    lstm_model.add(Dense(1))' + sLineBreak +
    '    lstm_model.compile(optimizer="adam", loss="mse")' + sLineBreak +
    '    ' + sLineBreak +
    '    # Treinamento silencioso' + sLineBreak +
    '    lstm_model.fit(X, y, epochs=' + IntToStr(AEpochs) + ', batch_size=4, verbose=0)' + sLineBreak +
    '    lstm_success = True' + sLineBreak +
    '    lstm_error = ""' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    lstm_success = False' + sLineBreak +
    '    lstm_error = str(e)';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError := 'Erro na execução do script do Python: ' + FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('lstm_success') <> 'True' then
  begin
    FLastError := 'Falha no treinamento LSTM: ' + FPythonConnector.GetVar('lstm_error');
    Exit;
  end;

  Result := True;
end;

function TLSTMPredictor.PredictNext(const ALastWindow: TDoubleArray; out APredictedValue: Double): Boolean;
var
  PyScript: string;
  WindowListStr: string;
  FS: TFormatSettings;
begin
  Result := False;
  APredictedValue := 0.0;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  PrepareConnector;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  WindowListStr := ArrayToPythonList(ALastWindow);

  // Script para inferência com o modelo LSTM treinado no namespace global do Python
  PyScript :=
    'try:' + sLineBreak +
    '    x_input = np.array(' + WindowListStr + ')' + sLineBreak +
    '    x_input = np.reshape(x_input, (1, len(x_input), 1))' + sLineBreak +
    '    predicted_val = float(lstm_model.predict(x_input, verbose=0)[0][0])' + sLineBreak +
    '    lstm_predict_success = True' + sLineBreak +
    '    lstm_predict_error = ""' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    predicted_val = 0.0' + sLineBreak +
    '    lstm_predict_success = False' + sLineBreak +
    '    lstm_predict_error = str(e)';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError := 'Erro na execução do script do Python: ' + FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('lstm_predict_success') <> 'True' then
  begin
    FLastError := 'Falha na predição LSTM: ' + FPythonConnector.GetVar('lstm_predict_error');
    Exit;
  end;

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  APredictedValue := StrToFloatDef(FPythonConnector.GetVar('predicted_val'), 0.0);
  Result := True;
end;

initialization
  {$I lstmpredictor_icon.lrs}

end.
