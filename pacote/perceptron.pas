unit perceptron;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources;

type
  TDoubleArray = array of Double;
  TDoubleMatrix = array of TDoubleArray;
  TIntegerArray = array of Integer;

  { TPerceptron }

  TPerceptron = class(TComponent)
  private
    FInputSize: Integer;
    FLearningRate: Double;
    FWeights: TDoubleArray;
    FBias: Double;
    procedure SetLearningRate(const AValue: Double);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Inicializa a rede com pesos aleatórios pequenos
    procedure Initialize(AInputSize: Integer; ALearningRate: Double = 0.1);

    // Realiza a predição para um conjunto de entradas (retorna 0 ou 1)
    function Predict(const AInputs: TDoubleArray): Integer;

    // Treina o perceptron com um único exemplo. Retorna o erro (Target - Predict)
    function Train(const AInputs: TDoubleArray; ATarget: Integer): Double;

    // Treina o perceptron por várias épocas em um conjunto de dados
    procedure TrainEpochs(const ADatasetInputs: TDoubleMatrix; const ADatasetTargets: TIntegerArray; AEpochs: Integer; out AFinalError: Double);

    // Salva e carrega o estado do perceptron
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    // Acesso direto aos pesos e bias para inspeção
    property Weights: TDoubleArray read FWeights;
    property Bias: Double read FBias write FBias;
    property InputSize: Integer read FInputSize;
  published
    property LearningRate: Double read FLearningRate write SetLearningRate;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TPerceptron]);
end;

{ TPerceptron }

constructor TPerceptron.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInputSize := 0;
  FLearningRate := 0.1;
  FBias := 0.0;
  SetLength(FWeights, 0);
end;

destructor TPerceptron.Destroy;
begin
  SetLength(FWeights, 0);
  inherited Destroy;
end;

procedure TPerceptron.SetLearningRate(const AValue: Double);
begin
  if AValue <= 0 then
    raise Exception.Create('A taxa de aprendizado deve ser maior que zero.');
  FLearningRate := AValue;
end;

procedure TPerceptron.Initialize(AInputSize: Integer; ALearningRate: Double);
var
  I: Integer;
begin
  if AInputSize <= 0 then
    raise Exception.Create('O tamanho de entrada deve ser maior que zero.');

  FInputSize := AInputSize;
  FLearningRate := ALearningRate;
  
  SetLength(FWeights, FInputSize);
  
  Randomize;
  // Inicialização com valores aleatórios pequenos entre -0.5 e 0.5
  for I := 0 to FInputSize - 1 do
  begin
    FWeights[I] := Random - 0.5;
  end;
  FBias := Random - 0.5;
end;

function TPerceptron.Predict(const AInputs: TDoubleArray): Integer;
var
  Sum: Double;
  I: Integer;
begin
  if FInputSize = 0 then
    raise Exception.Create('O perceptron não foi inicializado. Chame Initialize antes de usar.');
    
  if Length(AInputs) <> FInputSize then
    raise Exception.CreateFmt('O tamanho das entradas (%d) não corresponde ao tamanho de entrada inicializado (%d).', [Length(AInputs), FInputSize]);

  Sum := FBias;
  for I := 0 to FInputSize - 1 do
  begin
    Sum := Sum + AInputs[I] * FWeights[I];
  end;

  // Função de ativação Hard-Step (Rosenblatt Perceptron)
  if Sum >= 0.0 then
    Result := 1
  else
    Result := 0;
end;

function TPerceptron.Train(const AInputs: TDoubleArray; ATarget: Integer): Double;
var
  Prediction: Integer;
  Error: Double;
  I: Integer;
begin
  Prediction := Predict(AInputs);
  Error := ATarget - Prediction;

  // Se houver erro, ajusta os pesos e o bias (Regra de Aprendizado do Perceptron / Regra Delta)
  if Error <> 0.0 then
  begin
    for I := 0 to FInputSize - 1 do
    begin
      FWeights[I] := FWeights[I] + FLearningRate * Error * AInputs[I];
    end;
    FBias := FBias + FLearningRate * Error;
  end;

  Result := Error;
end;

procedure TPerceptron.TrainEpochs(const ADatasetInputs: TDoubleMatrix; const ADatasetTargets: TIntegerArray; AEpochs: Integer; out AFinalError: Double);
var
  Epoch, I: Integer;
  TotalError: Double;
  Error: Double;
begin
  if Length(ADatasetInputs) <> Length(ADatasetTargets) then
    raise Exception.Create('O número de entradas do dataset difere do número de alvos (targets).');

  if Length(ADatasetInputs) = 0 then
    raise Exception.Create('O dataset está vazio.');

  AFinalError := 0.0;

  for Epoch := 1 to AEpochs do
  begin
    TotalError := 0.0;
    for I := 0 to High(ADatasetInputs) do
    begin
      Error := Train(ADatasetInputs[I], ADatasetTargets[I]);
      TotalError := TotalError + Abs(Error);
    end;
    
    AFinalError := TotalError / Length(ADatasetInputs);
    
    // Se o erro for zero, convergiu e podemos parar mais cedo
    if TotalError = 0.0 then
      Break;
  end;
end;

procedure TPerceptron.SaveToFile(const AFileName: string);
var
  F: TextFile;
  I: Integer;
begin
  AssignFile(F, AFileName);
  Rewrite(F);
  try
    Writeln(F, FInputSize);
    Writeln(F, FBias:0:15);
    for I := 0 to FInputSize - 1 do
    begin
      if I = FInputSize - 1 then
        Write(F, FWeights[I]:0:15)
      else
        Write(F, FWeights[I]:0:15, ' ');
    end;
    Writeln(F);
  finally
    CloseFile(F);
  end;
end;

procedure TPerceptron.LoadFromFile(const AFileName: string);
var
  F: TextFile;
  I: Integer;
  NewInputSize: Integer;
  NewBias: Double;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Arquivo de configuração não encontrado: %s', [AFileName]);

  AssignFile(F, AFileName);
  Reset(F);
  try
    Readln(F, NewInputSize);
    if NewInputSize <= 0 then
      raise Exception.Create('Tamanho de entrada inválido no arquivo salvo.');
      
    Readln(F, NewBias);
    
    FInputSize := NewInputSize;
    FBias := NewBias;
    SetLength(FWeights, FInputSize);
    
    for I := 0 to FInputSize - 1 do
    begin
      Read(F, FWeights[I]);
    end;
  finally
    CloseFile(F);
  end;
end;

initialization
  {$I perceptron_icon.lrs}

end.
