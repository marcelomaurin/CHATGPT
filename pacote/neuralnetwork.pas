unit NeuralNetwork;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources, Controls, Graphics;

type
  TArray = array of Double;
  TMatrix = array of TArray;

  // Eventos para ativação e derivada da ativação
  TActivationEvent = procedure(Sender: TObject; var X: Double) of object;
  TDerivativeActivationEvent = procedure(Sender: TObject; var Y: Double) of object;

  TNeuralNetwork = class(TCustomControl)
  private
    FInputNodes: Integer;
    FHiddenNodes: Integer;
    FOutputNodes: Integer;
    FLearningRate: Double;
    FWeightsIH, FWeightsHO: TMatrix;
    FBiasH, FBiasO: TMatrix;

    FOnActivation: TActivationEvent; // Evento para a função de ativação
    FOnDerivativeActivation: TDerivativeActivationEvent; // Evento para a derivada

    function MatrixMultiply(LA, LB: TMatrix): TMatrix;
    function MatrixAdd(LA, LB: TMatrix): TMatrix;
    function MatrixMap(LA: TMatrix): TMatrix;
    function ArrayToMatrix(LArr: TArray): TMatrix;
    function MatrixToArray(LM: TMatrix): TArray;

    // Chamadores de eventos
    procedure DoActivation(var X: Double);
    procedure DoDerivativeActivation(var Y: Double);
  public
    constructor Create(LInputs, LHiddens, LOutputs: Integer; LLearningRate: Double);

    function Predict(LInputs: TArray): TArray;
    procedure Train(LInputs, LTargets: TArray);
    procedure SaveNetwork(LFileName: String);
    procedure LoadNetwork(LFileName: String);

    property InputNodes: Integer read FInputNodes;
    property HiddenNodes: Integer read FHiddenNodes;
    property OutputNodes: Integer read FOutputNodes;
    property LearningRate: Double read FLearningRate;

    // Propriedades de eventos
    property OnActivation: TActivationEvent read FOnActivation write FOnActivation;
    property OnDerivativeActivation: TDerivativeActivationEvent read FOnDerivativeActivation write FOnDerivativeActivation;
  end;

procedure Register;

implementation

constructor TNeuralNetwork.Create(LInputs, LHiddens, LOutputs: Integer; LLearningRate: Double);
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
      FWeightsIH[I, J] := Random * 2 - 1;

  for I := 0 to High(FWeightsHO) do
    for J := 0 to High(FWeightsHO[I]) do
      FWeightsHO[I, J] := Random * 2 - 1;

  for I := 0 to High(FBiasH) do
    FBiasH[I, 0] := Random * 2 - 1;

  for I := 0 to High(FBiasO) do
    FBiasO[I, 0] := Random * 2 - 1;
end;

function TNeuralNetwork.MatrixMultiply(LA, LB: TMatrix): TMatrix;
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

function TNeuralNetwork.MatrixAdd(LA, LB: TMatrix): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Length(LA), Length(LA[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LA[I]) do
      Result[I, J] := LA[I, J] + LB[I, J];
end;

function TNeuralNetwork.MatrixMap(LA: TMatrix): TMatrix;
var
  I, J: Integer;
begin
  SetLength(Result, Length(LA), Length(LA[0]));
  for I := 0 to High(LA) do
    for J := 0 to High(LA[I]) do
    begin
      Result[I, J] := LA[I, J];
      if Assigned(FOnActivation) then
        FOnActivation(Self, Result[I, J]); // Chama o evento de ativação se estiver atribuído
    end;
end;

function TNeuralNetwork.ArrayToMatrix(LArr: TArray): TMatrix;
var
  I: Integer;
begin
  SetLength(Result, Length(LArr), 1);
  for I := 0 to High(LArr) do
    Result[I, 0] := LArr[I];
end;

function TNeuralNetwork.MatrixToArray(LM: TMatrix): TArray;
var
  I: Integer;
begin
  SetLength(Result, Length(LM));
  for I := 0 to High(LM) do
    Result[I] := LM[I, 0];
end;

procedure TNeuralNetwork.DoActivation(var X: Double);
begin
  if Assigned(FOnActivation) then
    FOnActivation(Self, X);
end;

procedure TNeuralNetwork.DoDerivativeActivation(var Y: Double);
begin
  if Assigned(FOnDerivativeActivation) then
    FOnDerivativeActivation(Self, Y);
end;

function TNeuralNetwork.Predict(LInputs: TArray): TArray;
var
  InputMatrix, HiddenInputs, HiddenOutputs, FinalInputs, FinalOutputs: TMatrix;
begin
  InputMatrix := ArrayToMatrix(LInputs);
  HiddenInputs := MatrixAdd(MatrixMultiply(FWeightsIH, InputMatrix), FBiasH);
  HiddenOutputs := MatrixMap(HiddenInputs);
  FinalInputs := MatrixAdd(MatrixMultiply(FWeightsHO, HiddenOutputs), FBiasO);
  FinalOutputs := MatrixMap(FinalInputs);
  Result := MatrixToArray(FinalOutputs);
end;

procedure TNeuralNetwork.Train(LInputs, LTargets: TArray);
var
  InputMatrix, TargetMatrix, HiddenInputs, HiddenOutputs, FinalInputs, FinalOutputs: TMatrix;
  OutputErrors, HiddenErrors, Gradients, HiddenGradients: TMatrix;
  WeightsHODeltas, WeightsIHDeltas: TMatrix;
  I, J: Integer;
begin
  InputMatrix := ArrayToMatrix(LInputs);
  TargetMatrix := ArrayToMatrix(LTargets);

  HiddenInputs := MatrixAdd(MatrixMultiply(FWeightsIH, InputMatrix), FBiasH);
  HiddenOutputs := MatrixMap(HiddenInputs);
  FinalInputs := MatrixAdd(MatrixMultiply(FWeightsHO, HiddenOutputs), FBiasO);
  FinalOutputs := MatrixMap(FinalInputs);

  OutputErrors := MatrixAdd(TargetMatrix, MatrixMap(FinalOutputs));

  Gradients := MatrixMap(FinalOutputs);
  for I := 0 to High(Gradients) do
    for J := 0 to High(Gradients[I]) do
      Gradients[I, J] := Gradients[I, J] * OutputErrors[I, J] * FLearningRate;

  WeightsHODeltas := MatrixMultiply(Gradients, HiddenOutputs);
  FWeightsHO := MatrixAdd(FWeightsHO, WeightsHODeltas);
  FBiasO := MatrixAdd(FBiasO, Gradients);

  HiddenErrors := MatrixMultiply(FWeightsHO, OutputErrors);

  HiddenGradients := MatrixMap(HiddenOutputs);
  for I := 0 to High(HiddenGradients) do
    for J := 0 to High(HiddenGradients[I]) do
      HiddenGradients[I, J] := HiddenGradients[I, J] * HiddenErrors[I, J] * FLearningRate;

  WeightsIHDeltas := MatrixMultiply(HiddenGradients, InputMatrix);
  FWeightsIH := MatrixAdd(FWeightsIH, WeightsIHDeltas);
  FBiasH := MatrixAdd(FBiasH, HiddenGradients);
end;

procedure TNeuralNetwork.SaveNetwork(LFileName: String);
var
  FileOut: TextFile;
  I, J: Integer;
begin
  AssignFile(FileOut, LFileName);
  Rewrite(FileOut);

  for I := 0 to High(FWeightsIH) do
    for J := 0 to High(FWeightsIH[I]) do
      Write(FileOut, FWeightsIH[I, J]:0:6, ' ');
  Writeln(FileOut);

  for I := 0 to High(FWeightsHO) do
    for J := 0 to High(FWeightsHO[I]) do
      Write(FileOut, FWeightsHO[I, J]:0:6, ' ');
  Writeln(FileOut);

  for I := 0 to High(FBiasH) do
    Write(FileOut, FBiasH[I, 0]:0:6, ' ');
  Writeln(FileOut);

  for I := 0 to High(FBiasO) do
    Write(FileOut, FBiasO[I, 0]:0:6, ' ');
  Writeln(FileOut);

  CloseFile(FileOut);
end;

procedure TNeuralNetwork.LoadNetwork(LFileName: String);
var
  FileIn: TextFile;
  I, J: Integer;
begin
  AssignFile(FileIn, LFileName);
  Reset(FileIn);

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

  CloseFile(FileIn);
end;

procedure Register;
begin
  // Registrar o componente na aba "Samples"
  RegisterComponents('IA', [TNeuralNetwork]);

end;

end.

