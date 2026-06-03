unit NeuralNetwork;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources, Controls, Graphics;

type
  TArray = array of Double;
  TMatrix = array of TArray;

  TActivationType = (atSigmoid, atReLU, atTanh, atCustom);

  // Eventos para ativação customizada
  TActivationEvent = procedure(Sender: TObject; var X: Double) of object;
  TDerivativeActivationEvent = procedure(Sender: TObject; var Y: Double) of object;

  TNeuralNetwork = class(TCustomControl)
  private
    FInputNodes: Integer;
    FHiddenNodes: Integer;
    FOutputNodes: Integer;
    FLearningRate: Double;
    FActivationType: TActivationType;
    FWeightsIH, FWeightsHO: TMatrix;
    FBiasH, FBiasO: TMatrix;

    FOnActivation: TActivationEvent;
    FOnDerivativeActivation: TDerivativeActivationEvent;

    FPrompt: string;
    FLastError: string;
    FLastResult: string;
    FLastSuccess: Boolean;

    function MatrixMultiply(const LA, LB: TMatrix): TMatrix;
    function MatrixAdd(const LA, LB: TMatrix): TMatrix;
    function MatrixSubtract(const LA, LB: TMatrix): TMatrix;
    function MatrixMap(const LA: TMatrix): TMatrix;
    function MatrixMapDerivative(const LA: TMatrix): TMatrix;
    function ArrayToMatrix(const LArr: TArray): TMatrix;
    function MatrixToArray(const LM: TMatrix): TArray;

    procedure DoActivation(var X: Double);
    procedure DoDerivativeActivation(var Y: Double);
    procedure ClearError;
    procedure SetError(const AMessage: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Initialize(LInputs, LHiddens, LOutputs: Integer; LLearningRate: Double);

    function Predict(const LInputs: TArray): TArray;
    procedure Train(const LInputs, LTargets: TArray);
    
    // Treinamento por épocas com cálculo de erro médio quadrado (MSE)
    procedure TrainEpochs(const LDatasetInputs, LDatasetTargets: TMatrix; LEpochs: Integer; out LFinalLoss: Double);
    
    procedure SaveNetwork(const LFileName: String);
    procedure LoadNetwork(const LFileName: String);

    property InputNodes: Integer read FInputNodes;
    property HiddenNodes: Integer read FHiddenNodes;
    property OutputNodes: Integer read FOutputNodes;
    property LearningRate: Double read FLearningRate write FLearningRate;
    property ActivationType: TActivationType read FActivationType write FActivationType;

    // Propriedades de eventos para ativação customizada
    property OnActivation: TActivationEvent read FOnActivation write FOnActivation;
    property OnDerivativeActivation: TDerivativeActivationEvent read FOnDerivativeActivation write FOnDerivativeActivation;
    
    property LastSuccess: Boolean read FLastSuccess;
  published
    property Prompt: string read FPrompt write FPrompt;
    property LastError: string read FLastError;
    property LastResult: string read FLastResult;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TNeuralNetwork]);
  RegisterComponents('IA', [TNeuralNetwork]);
end;

constructor TNeuralNetwork.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInputNodes := 0;
  FHiddenNodes := 0;
  FOutputNodes := 0;
  FLearningRate := 0.1;
  FActivationType := atSigmoid;
  FPrompt := '';
  FLastError := '';
  FLastResult := '';
  FLastSuccess := True;
end;

procedure TNeuralNetwork.ClearError;
begin
  FLastError := '';
  FLastSuccess := True;
end;

procedure TNeuralNetwork.SetError(const AMessage: string);
begin
  FLastError := AMessage;
  FLastSuccess := False;
end;

procedure TNeuralNetwork.Initialize(LInputs, LHiddens, LOutputs: Integer; LLearningRate: Double);
var
  I, J: Integer;
begin
  FInputNodes := LInputs;
  FHiddenNodes := LHiddens;
  FOutputNodes := LOutputs;
  FLearningRate := LLearningRate;

  SetLength(FWeightsIH, FHiddenNodes, FInputNodes);
  SetLength(FWeightsHO, FOutputNodes, FHiddenNodes);
  SetLength(FBiasH, FHiddenNodes, 1);
  SetLength(FBiasO, FOutputNodes, 1);

  Randomize;
  for I := 0 to High(FWeightsIH) do
    for J := 0 to High(FWeightsIH[I]) do
      FWeightsIH[I, J] := (Random * 2 - 1) * Sqrt(2.0 / FInputNodes); // He-initialization para estabilidade

  for I := 0 to High(FWeightsHO) do
    for J := 0 to High(FWeightsHO[I]) do
      FWeightsHO[I, J] := (Random * 2 - 1) * Sqrt(2.0 / FHiddenNodes);

  for I := 0 to High(FBiasH) do
    FBiasH[I, 0] := Random * 2 - 1;

  for I := 0 to High(FBiasO) do
    FBiasO[I, 0] := Random * 2 - 1;
end;

function TNeuralNetwork.MatrixMultiply(const LA, LB: TMatrix): TMatrix;
var
  I, J, K: Integer;
begin
  SetLength(Result, Length(LA), Length(LB[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LB[0]) do
    begin
      Result[I, J] := 0;
      for K := 0 to High(LA[0]) do
        Result[I, J] := Result[I, J] + LA[I, K] * LB[K, J];
    end;
end;

function TNeuralNetwork.MatrixAdd(const LA, LB: TMatrix): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Length(LA), Length(LA[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LA[I]) do
      Result[I, J] := LA[I, J] + LB[I, J];
end;

function TNeuralNetwork.MatrixSubtract(const LA, LB: TMatrix): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Length(LA), Length(LA[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LA[I]) do
      Result[I, J] := LA[I, J] - LB[I, J];
end;

procedure TNeuralNetwork.DoActivation(var X: Double);
begin
  case FActivationType of
    atSigmoid:
      X := 1.0 / (1.0 + Exp(-X));
    atReLU:
      if X < 0 then X := 0;
    atTanh:
      X := Tanh(X);
    atCustom:
      if Assigned(FOnActivation) then
        FOnActivation(Self, X);
  end;
end;

procedure TNeuralNetwork.DoDerivativeActivation(var Y: Double);
begin
  case FActivationType of
    atSigmoid:
      Y := Y * (1.0 - Y); // Sigmoid derivada usando o output ativado
    atReLU:
      if Y > 0 then Y := 1.0 else Y := 0.0;
    atTanh:
      Y := 1.0 - (Y * Y); // Tanh derivada usando o output ativado
    atCustom:
      if Assigned(FOnDerivativeActivation) then
        FOnDerivativeActivation(Self, Y);
  end;
end;

function TNeuralNetwork.MatrixMap(const LA: TMatrix): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Length(LA), Length(LA[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LA[I]) do
    begin
      Result[I, J] := LA[I, J];
      DoActivation(Result[I, J]);
    end;
end;

function TNeuralNetwork.MatrixMapDerivative(const LA: TMatrix): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Length(LA), Length(LA[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LA[I]) do
    begin
      Result[I, J] := LA[I, J];
      DoDerivativeActivation(Result[I, J]);
    end;
end;

function TNeuralNetwork.ArrayToMatrix(const LArr: TArray): TMatrix;
var
  I: Integer;
begin
  SetLength(Result, Length(LArr), 1);
  for I := 0 to High(LArr) do
    Result[I, 0] := LArr[I];
end;

function TNeuralNetwork.MatrixToArray(const LM: TMatrix): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(LM));
  for I := 0 to High(LM) do
    Result[I] := LM[I, 0];
end;

function TNeuralNetwork.Predict(const LInputs: TArray): TArray;
var
  InputMatrix, HiddenInputs, HiddenOutputs, FinalInputs, FinalOutputs: TMatrix;
begin
  SetLength(Result, 0);
  ClearError;
  try
    if (FInputNodes = 0) or (FHiddenNodes = 0) or (FOutputNodes = 0) then
      raise Exception.Create('A rede neural não foi inicializada. Chame Initialize antes de usar.');

    InputMatrix := ArrayToMatrix(LInputs);
    HiddenInputs := MatrixAdd(MatrixMultiply(FWeightsIH, InputMatrix), FBiasH);
    HiddenOutputs := MatrixMap(HiddenInputs);
    FinalInputs := MatrixAdd(MatrixMultiply(FWeightsHO, HiddenOutputs), FBiasO);
    FinalOutputs := MatrixMap(FinalInputs);
    Result := MatrixToArray(FinalOutputs);
    FLastResult := 'Prediction Succeeded';
    FLastSuccess := True;
  except
    on E: Exception do
    begin
      SetError(E.Message);
      raise;
    end;
  end;
end;

procedure TNeuralNetwork.Train(const LInputs, LTargets: TArray);
var
  InputMatrix, TargetMatrix, HiddenInputs, HiddenOutputs, FinalInputs, FinalOutputs: TMatrix;
  OutputErrors, HiddenErrors, Gradients, HiddenGradients: TMatrix;
  WeightsHODeltas, WeightsIHDeltas: TMatrix;
  TransposedHidden, TransposedInput, TransposedWeightsHO: TMatrix;
  I, J: Integer;
begin
  ClearError;
  try
    if (FInputNodes = 0) or (FHiddenNodes = 0) or (FOutputNodes = 0) then
      raise Exception.Create('A rede neural não foi inicializada. Chame Initialize antes de treinar.');

    InputMatrix := ArrayToMatrix(LInputs);
    TargetMatrix := ArrayToMatrix(LTargets);

    // Forward Pass
    HiddenInputs := MatrixAdd(MatrixMultiply(FWeightsIH, InputMatrix), FBiasH);
    HiddenOutputs := MatrixMap(HiddenInputs);
    FinalInputs := MatrixAdd(MatrixMultiply(FWeightsHO, HiddenOutputs), FBiasO);
    FinalOutputs := MatrixMap(FinalInputs);

    // Erros da camada de saída (Target - Output)
    OutputErrors := MatrixSubtract(TargetMatrix, FinalOutputs);

    // Gradients da saída = Derivada(Output) * Erro * LearningRate
    Gradients := MatrixMapDerivative(FinalOutputs);
    for I := 0 to High(Gradients) do
      for J := 0 to High(Gradients[I]) do
        Gradients[I, J] := Gradients[I, J] * OutputErrors[I, J] * FLearningRate;

    // Ajusta pesos da camada oculta para saída (WeightsHO)
    SetLength(TransposedHidden, Length(HiddenOutputs[0]), Length(HiddenOutputs));
    for I := 0 to High(HiddenOutputs) do
      for J := 0 to High(HiddenOutputs[I]) do
        TransposedHidden[J, I] := HiddenOutputs[I, J];

    WeightsHODeltas := MatrixMultiply(Gradients, TransposedHidden);
    FWeightsHO := MatrixAdd(FWeightsHO, WeightsHODeltas);
    FBiasO := MatrixAdd(FBiasO, Gradients);

    // Erros da camada oculta (Transposta dos pesos HO * Erros da Saída)
    SetLength(TransposedWeightsHO, Length(FWeightsHO[0]), Length(FWeightsHO));
    for I := 0 to High(FWeightsHO) do
      for J := 0 to High(FWeightsHO[I]) do
        TransposedWeightsHO[J, I] := FWeightsHO[I, J];

    HiddenErrors := MatrixMultiply(TransposedWeightsHO, OutputErrors);

    // Gradients da camada oculta = Derivada(HiddenOutputs) * ErroOculto * LearningRate
    HiddenGradients := MatrixMapDerivative(HiddenOutputs);
    for I := 0 to High(HiddenGradients) do
      for J := 0 to High(HiddenGradients[I]) do
        HiddenGradients[I, J] := HiddenGradients[I, J] * HiddenErrors[I, J] * FLearningRate;

    // Ajusta pesos da entrada para camada oculta (WeightsIH)
    SetLength(TransposedInput, Length(InputMatrix[0]), Length(InputMatrix));
    for I := 0 to High(InputMatrix) do
      for J := 0 to High(InputMatrix[I]) do
        TransposedInput[J, I] := InputMatrix[I, J];

    WeightsIHDeltas := MatrixMultiply(HiddenGradients, TransposedInput);
    FWeightsIH := MatrixAdd(FWeightsIH, WeightsIHDeltas);
    FBiasH := MatrixAdd(FBiasH, HiddenGradients);
    FLastResult := 'Training Pass Succeeded';
    FLastSuccess := True;
  except
    on E: Exception do
    begin
      SetError(E.Message);
      raise;
    end;
  end;
end;

procedure TNeuralNetwork.TrainEpochs(const LDatasetInputs, LDatasetTargets: TMatrix; LEpochs: Integer; out LFinalLoss: Double);
var
  Epoch, I, J: Integer;
  Predictions: TArray;
  TotalError, TargetVal, Diff: Double;
begin
  LFinalLoss := 0;
  ClearError;
  try
    if Length(LDatasetInputs) <> Length(LDatasetTargets) then
      raise Exception.Create('O número de entradas do dataset difere do número de alvos (targets).');

    for Epoch := 1 to LEpochs do
    begin
      TotalError := 0;
      for I := 0 to High(LDatasetInputs) do
      begin
        // Treina com a linha atual
        Train(LDatasetInputs[I], LDatasetTargets[I]);
        
        // Predição para calcular perda (Loss)
        Predictions := Predict(LDatasetInputs[I]);
        for J := 0 to High(Predictions) do
        begin
          TargetVal := LDatasetTargets[I, J];
          Diff := TargetVal - Predictions[J];
          TotalError := TotalError + (Diff * Diff);
        end;
      end;
      
      // MSE Loss
      LFinalLoss := TotalError / (Length(LDatasetInputs) * FOutputNodes);
    end;
    FLastResult := Format('Epoch training Succeeded. Final Loss: %f', [LFinalLoss]);
    FLastSuccess := True;
  except
    on E: Exception do
    begin
      SetError(E.Message);
      raise;
    end;
  end;
end;

procedure TNeuralNetwork.SaveNetwork(const LFileName: String);
var
  FileOut: TextFile;
  I, J: Integer;
begin
  ClearError;
  try
    AssignFile(FileOut, LFileName);
    Rewrite(FileOut);
    try
      Writeln(FileOut, FInputNodes, ' ', FHiddenNodes, ' ', FOutputNodes);
      Writeln(FileOut, Ord(FActivationType));

      for I := 0 to High(FWeightsIH) do
      begin
        for J := 0 to High(FWeightsIH[I]) do
          Write(FileOut, FWeightsIH[I, J]:0:10, ' ');
        Writeln(FileOut);
      end;

      for I := 0 to High(FWeightsHO) do
      begin
        for J := 0 to High(FWeightsHO[I]) do
          Write(FileOut, FWeightsHO[I, J]:0:10, ' ');
        Writeln(FileOut);
      end;

      for I := 0 to High(FBiasH) do
        Write(FileOut, FBiasH[I, 0]:0:10, ' ');
      Writeln(FileOut);

      for I := 0 to High(FBiasO) do
        Write(FileOut, FBiasO[I, 0]:0:10, ' ');
      Writeln(FileOut);
    finally
      CloseFile(FileOut);
    end;
    FLastResult := 'Network Saved Successfully';
    FLastSuccess := True;
  except
    on E: Exception do
    begin
      SetError(E.Message);
      raise;
    end;
  end;
end;

procedure TNeuralNetwork.LoadNetwork(const LFileName: String);
var
  FileIn: TextFile;
  I, J: Integer;
  LAct: Integer;
begin
  ClearError;
  try
    AssignFile(FileIn, LFileName);
    Reset(FileIn);
    try
      Read(FileIn, FInputNodes, FHiddenNodes, FOutputNodes);
      Read(FileIn, LAct);
      FActivationType := TActivationType(LAct);

      Initialize(FInputNodes, FHiddenNodes, FOutputNodes, FLearningRate);

      for I := 0 to High(FWeightsIH) do
        for J := 0 to High(FWeightsIH[I]) do
          Read(FileIn, FWeightsIH[I, J]);

      for I := 0 to High(FWeightsHO) do
        for J := 0 to High(FWeightsHO[I]) do
          Read(FileIn, FWeightsHO[I, J]);

      for I := 0 to High(FBiasH) do
        Read(FileIn, FBiasH[I, 0]);

      for I := 0 to High(FBiasO) do
        Read(FileIn, FBiasO[I, 0]);
    finally
      CloseFile(FileIn);
    end;
    FLastResult := 'Network Loaded Successfully';
    FLastSuccess := True;
  except
    on E: Exception do
    begin
      SetError(E.Message);
      raise;
    end;
  end;
end;

initialization
  {$I neuralnetwork_icon.lrs}

end.
