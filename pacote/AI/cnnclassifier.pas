unit cnnclassifier;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pythonconnector, LResources, Math;

type
  { TCNNClassifier }

  TCNNClassifier = class(TComponent)
  private
    FPythonConnector: TPythonConnector;
    FLastError: string;
    FPreferProcessMode: Boolean;

    FWeightsFile: string;
    FThreshold: Double;
    FBackendMode: string;
    FLastLabel: string;
    FLastConfidence: Double;
    FModelLoaded: Boolean;

    FAutoInstallDependencies: Boolean;
    FDependencyChecked: Boolean;

    procedure SetPythonConnector(const AValue: TPythonConnector);
    procedure PrepareConnector;

    function CheckConnectorReady: Boolean;
    function PythonQuotedString(const AValue: string): string;

    function CheckDependencies: Boolean;
    function EnsureDependencies: Boolean;

  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

  public
    constructor Create(AOwner: TComponent); override;

    // Verifica se tensorflow, pillow/PIL e numpy existem e carregam.
    function DependenciesAvailable: Boolean;

    // Instala tensorflow, pillow e numpy usando pip dentro do Python já carregado.
    // Não chama python.exe externo.
    function InstallDependencies: Boolean;

    // Carrega/prepara o modelo CNN.
    function LoadWeights: Boolean;

    // Classifica uma imagem e grava LastLabel / LastConfidence.
    function ClassifyFrame(const AImageFile: string): Boolean;

    // Classificação direta, mantendo compatibilidade com a versão anterior.
    function ClassifyImage(
      const AImageFile: string;
      out AClassLabel: string;
      out AConfidence: Double
    ): Boolean;

  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;

    property PreferProcessMode: Boolean read FPreferProcessMode write FPreferProcessMode default True;

    property WeightsFile: string read FWeightsFile write FWeightsFile;
    property Threshold: Double read FThreshold write FThreshold;
    property BackendMode: string read FBackendMode write FBackendMode;

    property LastLabel: string read FLastLabel;
    property LastConfidence: Double read FLastConfidence;

    property AutoInstallDependencies: Boolean
      read FAutoInstallDependencies
      write FAutoInstallDependencies
      default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TCNNClassifier]);
end;

{ TCNNClassifier }

constructor TCNNClassifier.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPythonConnector := nil;
  FLastError := '';
  FPreferProcessMode := True;

  FWeightsFile := '';
  FThreshold := 0.0;
  FBackendMode := 'TensorFlow';

  FLastLabel := '';
  FLastConfidence := 0.0;
  FModelLoaded := False;

  FAutoInstallDependencies := True;
  FDependencyChecked := False;
end;

procedure TCNNClassifier.PrepareConnector;
begin
  if (FPythonConnector <> nil) and
     (not FPythonConnector.Active) and
     FPreferProcessMode then
  begin
    FPythonConnector.ExecutionMode := pemProcess;
  end;
end;

function TCNNClassifier.CheckConnectorReady: Boolean;
begin
  // Mask floating point exceptions to avoid HDF5 / TensorFlow initialization error.
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

  Result := False;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  PrepareConnector;

  if not FPythonConnector.Active then
  begin
    try
      FPythonConnector.Active := True;
    except
      on E: Exception do
      begin
        FLastError :=
          'Erro ao ativar o PythonConnector. ' +
          'DLL/SO: ' + FPythonConnector.DLLPath + '. ' +
          'Erro: ' + E.Message;

        if FPythonConnector.LastError <> '' then
          FLastError := FLastError + ' LastError: ' + FPythonConnector.LastError;

        Exit;
      end;
    end;
  end;

  if not FPythonConnector.Active then
  begin
    FLastError :=
      'PythonConnector não está ativo. ' +
      'DLL/SO: ' + FPythonConnector.DLLPath + '.';

    if FPythonConnector.LastError <> '' then
      FLastError := FLastError + ' LastError: ' + FPythonConnector.LastError;

    Exit;
  end;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError :=
      'O interpretador Python não está inicializado. ' +
      'DLL/SO: ' + FPythonConnector.DLLPath + '.';

    if FPythonConnector.LastError <> '' then
      FLastError := FLastError + ' LastError: ' + FPythonConnector.LastError;

    Exit;
  end;

  Result := True;
end;

function TCNNClassifier.PythonQuotedString(const AValue: string): string;
var
  S: string;
begin
  S := AValue;
  S := StringReplace(S, '\', '\\', [rfReplaceAll]);
  S := StringReplace(S, '"', '\"', [rfReplaceAll]);
  S := StringReplace(S, #13, '\r', [rfReplaceAll]);
  S := StringReplace(S, #10, '\n', [rfReplaceAll]);

  Result := '"' + S + '"';
end;

procedure TCNNClassifier.SetPythonConnector(const AValue: TPythonConnector);
begin
  if FPythonConnector = AValue then
    Exit;

  if FPythonConnector <> nil then
    FPythonConnector.RemoveFreeNotification(Self);

  FPythonConnector := AValue;
  FDependencyChecked := False;
  FModelLoaded := False;

  if FPythonConnector <> nil then
  begin
    FPythonConnector.FreeNotification(Self);
    PrepareConnector;
  end;
end;

procedure TCNNClassifier.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FPythonConnector) then
  begin
    FPythonConnector := nil;
    FDependencyChecked := False;
    FModelLoaded := False;
  end;
end;

function TCNNClassifier.CheckDependencies: Boolean;
var
  LMissing: string;
  LImportError: string;
  LRuntimeInfo: string;
begin
  Result := False;
  FLastError := '';

  if not CheckConnectorReady then
    Exit;

  if not FPythonConnector.ExecString(
    'import sys, platform, traceback' + sLineBreak +
    'cnn_missing = []' + sLineBreak +
    'cnn_import_error = ""' + sLineBreak +
    'cnn_runtime_info = "Python=" + sys.version.replace(chr(10), " ") + "; Machine=" + platform.machine() + "; Platform=" + platform.platform()' + sLineBreak +

    'try:' + sLineBreak +
    '    import numpy as np' + sLineBreak +
    'except Exception:' + sLineBreak +
    '    cnn_missing.append("numpy")' + sLineBreak +
    '    cnn_import_error += "NUMPY:" + traceback.format_exc() + chr(10)' + sLineBreak +

    'try:' + sLineBreak +
    '    from PIL import Image' + sLineBreak +
    'except Exception:' + sLineBreak +
    '    cnn_missing.append("pillow/PIL")' + sLineBreak +
    '    cnn_import_error += "PILLOW:" + traceback.format_exc() + chr(10)' + sLineBreak +

    'try:' + sLineBreak +
    '    import tensorflow as tf' + sLineBreak +
    'except Exception:' + sLineBreak +
    '    cnn_missing.append("tensorflow")' + sLineBreak +
    '    cnn_import_error += "TENSORFLOW:" + traceback.format_exc() + chr(10)' + sLineBreak +

    'cnn_dependencies_ok = len(cnn_missing) == 0' + sLineBreak +
    'cnn_dependencies_missing = ", ".join(cnn_missing)'
  ) then
  begin
    FLastError := 'Erro ao verificar dependências CNN: ' + FPythonConnector.LastError;
    Exit;
  end;

  Result := FPythonConnector.GetVar('cnn_dependencies_ok') = 'True';

  if not Result then
  begin
    LMissing := FPythonConnector.GetVar('cnn_dependencies_missing');
    LImportError := FPythonConnector.GetVar('cnn_import_error');
    LRuntimeInfo := FPythonConnector.GetVar('cnn_runtime_info');

    FLastError :=
      'Dependências CNN ausentes ou com falha de importação: ' + LMissing + '. ' +
      'Runtime: ' + LRuntimeInfo + '.';

    if Trim(LImportError) <> '' then
      FLastError := FLastError + sLineBreak + 'Detalhe da importação: ' + LImportError;
  end;
end;

function TCNNClassifier.DependenciesAvailable: Boolean;
begin
  Result := CheckDependencies;
end;

function TCNNClassifier.InstallDependencies: Boolean;
var
  LPyScript: string;
  LDepError: string;
  LRuntimeInfo: string;
begin
  Result := False;
  FLastError := '';

  if not CheckConnectorReady then
    Exit;

  LPyScript :=
    'import sys, runpy, traceback, platform' + sLineBreak +
    'dep_success = False' + sLineBreak +
    'dep_error = ""' + sLineBreak +
    'dep_runtime_info = "Python=" + sys.version.replace(chr(10), " ") + "; Machine=" + platform.machine() + "; Platform=" + platform.platform()' + sLineBreak +
    'try:' + sLineBreak +
    '    old_argv = sys.argv[:]' + sLineBreak +
    '    try:' + sLineBreak +
    '        sys.argv = ["pip", "install", "--user", "numpy", "pillow", "tensorflow"]' + sLineBreak +
    '        try:' + sLineBreak +
    '            runpy.run_module("pip", run_name="__main__", alter_sys=True)' + sLineBreak +
    '            dep_success = True' + sLineBreak +
    '        except SystemExit as e:' + sLineBreak +
    '            dep_success = (e.code is None) or (e.code == 0)' + sLineBreak +
    '            if not dep_success:' + sLineBreak +
    '                dep_error = "pip retornou código: " + str(e.code)' + sLineBreak +
    '        except Exception:' + sLineBreak +
    '            dep_success = False' + sLineBreak +
    '            dep_error = traceback.format_exc()' + sLineBreak +
    '    finally:' + sLineBreak +
    '        sys.argv = old_argv' + sLineBreak +
    'except Exception:' + sLineBreak +
    '    dep_success = False' + sLineBreak +
    '    dep_error = traceback.format_exc()';

  if not FPythonConnector.ExecString(LPyScript) then
  begin
    FLastError :=
      'Erro ao tentar instalar dependências CNN dentro da DLL/SO Python: ' +
      FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('dep_success') <> 'True' then
  begin
    LDepError := FPythonConnector.GetVar('dep_error');
    LRuntimeInfo := FPythonConnector.GetVar('dep_runtime_info');

    FLastError :=
      'Falha ao instalar dependências CNN dentro do Python carregado pela DLL/SO. ' +
      'Runtime: ' + LRuntimeInfo + '.';

    if Trim(LDepError) <> '' then
      FLastError := FLastError + sLineBreak + 'Detalhe: ' + LDepError;

    Result := False;
    Exit;
  end;

  FDependencyChecked := False;
  Result := True;
end;

function TCNNClassifier.EnsureDependencies: Boolean;
var
  LOriginalError: string;
begin
  Result := False;

  if FDependencyChecked then
  begin
    Result := True;
    Exit;
  end;

  if CheckDependencies then
  begin
    FDependencyChecked := True;
    Result := True;
    Exit;
  end;

  LOriginalError := FLastError;

  if not FAutoInstallDependencies then
  begin
    FLastError :=
      LOriginalError + sLineBreak +
      'AutoInstallDependencies está False. Instale manualmente: tensorflow, pillow e numpy.';
    Exit;
  end;

  if not InstallDependencies then
  begin
    FLastError :=
      LOriginalError + sLineBreak +
      'Tentativa de instalação automática falhou: ' + FLastError;
    Exit;
  end;

  if not CheckDependencies then
  begin
    FLastError :=
      'As dependências foram instaladas, mas ainda não carregam corretamente.' +
      sLineBreak +
      FLastError;
    Exit;
  end;

  FDependencyChecked := True;
  Result := True;
end;

function TCNNClassifier.LoadWeights: Boolean;
var
  PyScript: string;
  LWeights: string;
  LUseCustomWeights: Boolean;
  LLoadError: string;
  LRuntimeInfo: string;
begin
  Result := False;
  FLastError := '';
  FModelLoaded := False;

  if not CheckConnectorReady then
    Exit;

  if Trim(FBackendMode) = '' then
    FBackendMode := 'TensorFlow';

  if not SameText(FBackendMode, 'TensorFlow') then
  begin
    FLastError :=
      'BackendMode não suportado: ' + FBackendMode +
      '. Atualmente este componente usa TensorFlow.';
    Exit;
  end;

  if not EnsureDependencies then
    Exit;

  LUseCustomWeights := False;
  LWeights := Trim(FWeightsFile);

  if LWeights <> '' then
  begin
    if FileExists(LWeights) then
      LUseCustomWeights := True
    else
      LUseCustomWeights := False;
  end;

  PyScript :=
    'import os, sys, platform, traceback' + sLineBreak +
    'os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"' + sLineBreak +
    'cnn_load_success = False' + sLineBreak +
    'cnn_load_error = ""' + sLineBreak +
    'cnn_runtime_info = "Python=" + sys.version.replace(chr(10), " ") + "; Machine=" + platform.machine() + "; Platform=" + platform.platform()' + sLineBreak +
    'try:' + sLineBreak +
    '    import tensorflow as tf' + sLineBreak +
    '    cnn_backend = "TensorFlow"' + sLineBreak;

  if LUseCustomWeights then
  begin
    PyScript := PyScript +
      '    from tensorflow.keras.models import load_model' + sLineBreak +
      '    cnn_weights_file = ' + PythonQuotedString(LWeights) + sLineBreak +
      '    cnn_model = load_model(cnn_weights_file)' + sLineBreak +
      '    cnn_model_kind = "custom"' + sLineBreak;
  end
  else
  begin
    PyScript := PyScript +
      '    from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2' + sLineBreak +
      '    cnn_model = MobileNetV2(weights="imagenet")' + sLineBreak +
      '    cnn_model_kind = "mobilenetv2"' + sLineBreak;
  end;

  PyScript := PyScript +
    '    cnn_load_success = True' + sLineBreak +
    'except Exception:' + sLineBreak +
    '    cnn_load_success = False' + sLineBreak +
    '    cnn_load_error = traceback.format_exc()';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError := 'Erro ao carregar modelo CNN: ' + FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('cnn_load_success') <> 'True' then
  begin
    LLoadError := FPythonConnector.GetVar('cnn_load_error');
    LRuntimeInfo := FPythonConnector.GetVar('cnn_runtime_info');

    FLastError :=
      'Falha ao carregar modelo CNN. Runtime: ' + LRuntimeInfo + '.';

    if Trim(LWeights) <> '' then
    begin
      if FileExists(LWeights) then
        FLastError := FLastError + sLineBreak + 'WeightsFile informado: ' + LWeights
      else
        FLastError := FLastError + sLineBreak +
          'WeightsFile não encontrado, foi tentado fallback para MobileNetV2: ' + LWeights;
    end
    else
      FLastError := FLastError + sLineBreak + 'WeightsFile vazio, foi usado MobileNetV2 ImageNet.';

    if Trim(LLoadError) <> '' then
      FLastError := FLastError + sLineBreak + 'Detalhe: ' + LLoadError;

    Exit;
  end;

  FModelLoaded := True;
  Result := True;
end;

function TCNNClassifier.ClassifyFrame(const AImageFile: string): Boolean;
var
  LLabel: string;
  LConfidence: Double;
begin
  Result := False;
  FLastError := '';
  FLastLabel := '';
  FLastConfidence := 0.0;

  if not FModelLoaded then
  begin
    if not LoadWeights then
      Exit;
  end;

  if not ClassifyImage(AImageFile, LLabel, LConfidence) then
    Exit;

  FLastLabel := LLabel;
  FLastConfidence := LConfidence;

  if (FThreshold > 0) and (FLastConfidence < FThreshold) then
  begin
    FLastError :=
      'Confiança abaixo do limite definido. Confiança: ' +
      FloatToStr(FLastConfidence) +
      ' / Threshold: ' +
      FloatToStr(FThreshold);
    Exit;
  end;

  Result := True;
end;

function TCNNClassifier.ClassifyImage(
  const AImageFile: string;
  out AClassLabel: string;
  out AConfidence: Double
): Boolean;
var
  PyScript: string;
  ConfStr: string;
  FS: TFormatSettings;
  LProcessError: string;
begin
  Result := False;
  AClassLabel := '';
  AConfidence := 0.0;
  FLastError := '';

  if not CheckConnectorReady then
    Exit;

  if not FileExists(AImageFile) then
  begin
    FLastError := 'Arquivo de imagem não encontrado: ' + AImageFile;
    Exit;
  end;

  if not FModelLoaded then
  begin
    if not LoadWeights then
      Exit;
  end;

  PyScript :=
    'import os, traceback' + sLineBreak +
    'os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"' + sLineBreak +
    'cnn_success = False' + sLineBreak +
    'cnn_error = ""' + sLineBreak +
    'try:' + sLineBreak +
    '    import tensorflow as tf' + sLineBreak +
    '    import numpy as np' + sLineBreak +
    '    from tensorflow.keras.preprocessing import image' + sLineBreak +
    '    from tensorflow.keras.applications.mobilenet_v2 import preprocess_input, decode_predictions' + sLineBreak +
    '    img_path = ' + PythonQuotedString(AImageFile) + sLineBreak +

    '    try:' + sLineBreak +
    '        input_shape = cnn_model.input_shape' + sLineBreak +
    '        if isinstance(input_shape, list):' + sLineBreak +
    '            input_shape = input_shape[0]' + sLineBreak +
    '        if len(input_shape) >= 3 and input_shape[1] and input_shape[2]:' + sLineBreak +
    '            cnn_target_size = (int(input_shape[1]), int(input_shape[2]))' + sLineBreak +
    '        else:' + sLineBreak +
    '            cnn_target_size = (224, 224)' + sLineBreak +
    '    except Exception:' + sLineBreak +
    '        cnn_target_size = (224, 224)' + sLineBreak +

    '    img = image.load_img(img_path, target_size=cnn_target_size)' + sLineBreak +
    '    x = image.img_to_array(img)' + sLineBreak +
    '    x = np.expand_dims(x, axis=0)' + sLineBreak +

    '    if "cnn_model_kind" in globals() and cnn_model_kind == "mobilenetv2":' + sLineBreak +
    '        x = preprocess_input(x)' + sLineBreak +
    '    else:' + sLineBreak +
    '        x = x / 255.0' + sLineBreak +

    '    preds = cnn_model.predict(x, verbose=0)' + sLineBreak +

    '    if "cnn_model_kind" in globals() and cnn_model_kind == "mobilenetv2":' + sLineBreak +
    '        decoded = decode_predictions(preds, top=1)[0][0]' + sLineBreak +
    '        cnn_label = decoded[1].replace("_", " ")' + sLineBreak +
    '        cnn_confidence = float(decoded[2])' + sLineBreak +
    '    else:' + sLineBreak +
    '        arr = np.array(preds[0])' + sLineBreak +
    '        idx = int(np.argmax(arr))' + sLineBreak +
    '        cnn_label = "class_" + str(idx)' + sLineBreak +
    '        cnn_confidence = float(arr[idx])' + sLineBreak +

    '    cnn_confidence_str = "{:.8f}".format(cnn_confidence)' + sLineBreak +
    '    cnn_success = True' + sLineBreak +
    'except Exception:' + sLineBreak +
    '    cnn_label = ""' + sLineBreak +
    '    cnn_confidence = 0.0' + sLineBreak +
    '    cnn_confidence_str = "0.0"' + sLineBreak +
    '    cnn_success = False' + sLineBreak +
    '    cnn_error = traceback.format_exc()';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError :=
      'Erro na execução do script Python: ' +
      FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('cnn_success') <> 'True' then
  begin
    LProcessError := FPythonConnector.GetVar('cnn_error');

    FLastError :=
      'Falha no processamento CNN para a imagem: ' + AImageFile;

    if Trim(LProcessError) <> '' then
      FLastError := FLastError + sLineBreak + 'Detalhe: ' + LProcessError;

    Exit;
  end;

  AClassLabel := FPythonConnector.GetVar('cnn_label');

  ConfStr := Trim(FPythonConnector.GetVar('cnn_confidence_str'));

  if ConfStr = '' then
    ConfStr := Trim(FPythonConnector.GetVar('cnn_confidence'));

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  AConfidence := StrToFloatDef(ConfStr, 0.0, FS);

  FLastLabel := AClassLabel;
  FLastConfidence := AConfidence;

  Result := True;
end;

initialization
  {$I cnnclassifier_icon.lrs}

end.
