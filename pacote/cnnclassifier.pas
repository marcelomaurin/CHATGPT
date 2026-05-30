unit cnnclassifier;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pythonconnector, LResources;

type
  { TCNNClassifier }

  TCNNClassifier = class(TComponent)
  private
    FPythonConnector: TPythonConnector;
    FLastError: string;
    procedure SetPythonConnector(const AValue: TPythonConnector);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    // Instala tensorflow e pillow no Python associado para uso do classificador
    function InstallDependencies: Boolean;

    // Carrega o modelo MobileNetV2 pré-treinado no ImageNet e classifica a imagem fornecida.
    // Retorna True em caso de sucesso e preenche o label e a confiança (de 0.0 a 1.0).
    function ClassifyImage(const AImageFile: string; out AClassLabel: string; out AConfidence: Double): Boolean;
  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TCNNClassifier]);
end;

{ TCNNClassifier }

constructor TCNNClassifier.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPythonConnector := nil;
  FLastError := '';
end;

procedure TCNNClassifier.SetPythonConnector(const AValue: TPythonConnector);
begin
  if FPythonConnector = AValue then Exit;
  FPythonConnector := AValue;
  if FPythonConnector <> nil then
    FPythonConnector.FreeNotification(Self);
end;

procedure TCNNClassifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPythonConnector) then
    FPythonConnector := nil;
end;

function TCNNClassifier.InstallDependencies: Boolean;
begin
  Result := False;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  // Executa pip install de dentro do Python para instalar tensorflow e pillow (PIL)
  Result := FPythonConnector.ExecString(
    'import subprocess, sys' + sLineBreak +
    'try:' + sLineBreak +
    '    subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflow", "pillow"])' + sLineBreak +
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

function TCNNClassifier.ClassifyImage(const AImageFile: string; out AClassLabel: string; out AConfidence: Double): Boolean;
var
  PyScript: string;
  EscapedPath: string;
begin
  Result := False;
  AClassLabel := '';
  AConfidence := 0.0;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  if not FileExists(AImageFile) then
  begin
    FLastError := 'Arquivo de imagem não encontrado: ' + AImageFile;
    Exit;
  end;

  // Escapa barras invertidas no caminho da imagem para o interpretador Python
  EscapedPath := StringReplace(AImageFile, '\', '\\', [rfReplaceAll]);

  // Script dinâmico em Python para classificação via MobileNetV2 (Carregado e cacheado globalmente no namespace)
  PyScript :=
    'import tensorflow as tf' + sLineBreak +
    'from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions' + sLineBreak +
    'from tensorflow.keras.preprocessing import image' + sLineBreak +
    'import numpy as np' + sLineBreak +
    'try:' + sLineBreak +
    '    if "cnn_model" not in globals():' + sLineBreak +
    '        cnn_model = MobileNetV2(weights="imagenet")' + sLineBreak +
    '    img = image.load_img(r"' + EscapedPath + '", target_size=(224, 224))' + sLineBreak +
    '    x = image.img_to_array(img)' + sLineBreak +
    '    x = np.expand_dims(x, axis=0)' + sLineBreak +
    '    x = preprocess_input(x)' + sLineBreak +
    '    preds = cnn_model.predict(x)' + sLineBreak +
    '    decoded = decode_predictions(preds, top=1)[0][0]' + sLineBreak +
    '    cnn_label = decoded[1].replace("_", " ")' + sLineBreak +
    '    cnn_confidence = float(decoded[2])' + sLineBreak +
    '    cnn_success = True' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    cnn_label = str(e)' + sLineBreak +
    '    cnn_confidence = 0.0' + sLineBreak +
    '    cnn_success = False';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError := 'Erro na execução do script do Python: ' + FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('cnn_success') <> 'True' then
  begin
    FLastError := 'Falha no processamento CNN: ' + FPythonConnector.GetVar('cnn_label');
    Exit;
  end;

  AClassLabel := FPythonConnector.GetVar('cnn_label');
  AConfidence := StrToFloatDef(FPythonConnector.GetVar('cnn_confidence'), 0.0);
  Result := True;
end;

initialization
  {$I cnnclassifier_icon.lrs}

end.
