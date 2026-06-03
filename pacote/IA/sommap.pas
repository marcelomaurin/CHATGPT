unit sommap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources;

type
  TDoubleArray = array of Double;
  TSOMGrid = array of array of TDoubleArray;

  { TSOMMap }

  TSOMMap = class(TComponent)
  private
    FGridWidth: Integer;
    FGridHeight: Integer;
    FInputDim: Integer;
    FWeights: TSOMGrid;
    procedure ClearWeights;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Inicializa a grade SOM com pesos aleatórios entre 0.0 e 1.0 (ótimo para RGB)
    procedure Initialize(AWidth, AHeight, AInputDim: Integer);

    // Encontra o neurônio vencedor (Best Matching Unit - BMU).
    // Retorna a distância euclidiana do BMU e preenche ABMUX e ABMUY.
    function FindBMU(const AInput: TDoubleArray; out ABMUX, ABMUY: Integer): Double;

    // Treina a grade SOM com uma única amostra de entrada
    procedure TrainStep(const AInput: TDoubleArray; ALearningRate, ARadius: Double);

    // Treina a grade SOM com um dataset completo de amostras por várias épocas.
    // Opcionalmente dispara um callback a cada época concluída para visualização em tempo real.
    procedure Train(const ADataset: array of TDoubleArray; AEpochs: Integer; AInitialLearningRate: Double = 0.1);

    // Salva e carrega o estado da grade em um arquivo de texto estruturado
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    property GridWidth: Integer read FGridWidth;
    property GridHeight: Integer read FGridHeight;
    property InputDim: Integer read FInputDim;
    property Weights: TSOMGrid read FWeights;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TSOMMap]);
end;

{ TSOMMap }

constructor TSOMMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGridWidth := 0;
  FGridHeight := 0;
  FInputDim := 0;
end;

destructor TSOMMap.Destroy;
begin
  ClearWeights;
  inherited Destroy;
end;

procedure TSOMMap.ClearWeights;
var
  X, Y: Integer;
begin
  for X := 0 to FGridWidth - 1 do
  begin
    for Y := 0 to FGridHeight - 1 do
    begin
      SetLength(FWeights[X, Y], 0);
    end;
    SetLength(FWeights[X], 0);
  end;
  SetLength(FWeights, 0);
  FGridWidth := 0;
  FGridHeight := 0;
  FInputDim := 0;
end;

procedure TSOMMap.Initialize(AWidth, AHeight, AInputDim: Integer);
var
  X, Y, D: Integer;
begin
  if (AWidth <= 0) or (AHeight <= 0) or (AInputDim <= 0) then
    raise Exception.Create('Dimensões da grade e dos dados de entrada devem ser maiores que zero.');

  ClearWeights;

  FGridWidth := AWidth;
  FGridHeight := AHeight;
  FInputDim := AInputDim;

  SetLength(FWeights, FGridWidth, FGridHeight);

  Randomize;
  for X := 0 to FGridWidth - 1 do
  begin
    for Y := 0 to FGridHeight - 1 do
    begin
      SetLength(FWeights[X, Y], FInputDim);
      for D := 0 to FInputDim - 1 do
      begin
        FWeights[X, Y, D] := Random; // Pesos aleatórios entre 0 e 1 (perfeito para cores RGB normalizadas)
      end;
    end;
  end;
end;

function TSOMMap.FindBMU(const AInput: TDoubleArray; out ABMUX, ABMUY: Integer): Double;
var
  X, Y, D: Integer;
  MinDist, CurrentDist, Diff: Double;
begin
  if FGridWidth = 0 then
    raise Exception.Create('SOM não foi inicializado.');

  if Length(AInput) <> FInputDim then
    raise Exception.Create('Dimensionalidade da entrada incorreta.');

  ABMUX := 0;
  ABMUY := 0;
  MinDist := 1e30;

  for X := 0 to FGridWidth - 1 do
  begin
    for Y := 0 to FGridHeight - 1 do
    begin
      CurrentDist := 0.0;
      for D := 0 to FInputDim - 1 do
      begin
        Diff := AInput[D] - FWeights[X, Y, D];
        CurrentDist := CurrentDist + (Diff * Diff);
      end;
      
      if CurrentDist < MinDist then
      begin
        MinDist := CurrentDist;
        ABMUX := X;
        ABMUY := Y;
      end;
    end;
  end;

  Result := Sqrt(MinDist); // Retorna a distância euclidiana real
end;

procedure TSOMMap.TrainStep(const AInput: TDoubleArray; ALearningRate, ARadius: Double);
var
  BMUX, BMUY: Integer;
  X, Y, D: Integer;
  DistSq, RadiusSq, Influence, Diff: Double;
begin
  FindBMU(AInput, BMUX, BMUY);
  RadiusSq := ARadius * ARadius;

  for X := 0 to FGridWidth - 1 do
  begin
    for Y := 0 to FGridHeight - 1 do
    begin
      // Calcula a distância euclidiana ao quadrado na grade bidimensional entre o neurônio atual e o BMU
      DistSq := Sqr(X - BMUX) + Sqr(Y - BMUY);
      
      // Se o neurônio estiver dentro da vizinhança atual
      if DistSq <= RadiusSq then
      begin
        // Função de influência Gaussiana
        Influence := Exp(-DistSq / (2.0 * RadiusSq));
        
        // Ajusta os pesos
        for D := 0 to FInputDim - 1 do
        begin
          Diff := AInput[D] - FWeights[X, Y, D];
          FWeights[X, Y, D] := FWeights[X, Y, D] + Influence * ALearningRate * Diff;
        end;
      end;
    end;
  end;
end;

procedure TSOMMap.Train(const ADataset: array of TDoubleArray; AEpochs: Integer; AInitialLearningRate: Double);
var
  Epoch, I: Integer;
  TimeConstant, CurrentRadius, CurrentLR, StartRadius: Double;
begin
  if Length(ADataset) = 0 then
    raise Exception.Create('Dataset vazio.');

  StartRadius := Max(FGridWidth, FGridHeight) / 2.0;
  TimeConstant := AEpochs / LogN(2.718281828459, StartRadius);

  for Epoch := 1 to AEpochs do
  begin
    // Decaimento exponencial do raio de vizinhança e da taxa de aprendizado
    CurrentRadius := StartRadius * Exp(-Epoch / TimeConstant);
    CurrentLR := AInitialLearningRate * Exp(-Epoch / AEpochs);

    // Treina com todas as amostras do dataset de forma estocástica
    for I := 0 to High(ADataset) do
    begin
      TrainStep(ADataset[I], CurrentLR, Max(CurrentRadius, 0.1));
    end;
  end;
end;

procedure TSOMMap.SaveToFile(const AFileName: string);
var
  F: TextFile;
  X, Y, D: Integer;
begin
  AssignFile(F, AFileName);
  Rewrite(F);
  try
    Writeln(F, FGridWidth, ' ', FGridHeight, ' ', FInputDim);
    for X := 0 to FGridWidth - 1 do
    begin
      for Y := 0 to FGridHeight - 1 do
      begin
        for D := 0 to FInputDim - 1 do
        begin
          if D = FInputDim - 1 then
            Write(F, FWeights[X, Y, D]:0:15)
          else
            Write(F, FWeights[X, Y, D]:0:15, ' ');
        end;
        Writeln(F);
      end;
    end;
  finally
    CloseFile(F);
  end;
end;

procedure TSOMMap.LoadFromFile(const AFileName: string);
var
  F: TextFile;
  X, Y, D: Integer;
  NewW, NewH, NewDim: Integer;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Arquivo SOM não encontrado: %s', [AFileName]);

  AssignFile(F, AFileName);
  Reset(F);
  try
    Read(F, NewW, NewH, NewDim);
    Initialize(NewW, NewH, NewDim);

    for X := 0 to FGridWidth - 1 do
    begin
      for Y := 0 to FGridHeight - 1 do
      begin
        for D := 0 to FInputDim - 1 do
        begin
          Read(F, FWeights[X, Y, D]);
        end;
      end;
    end;
  finally
    CloseFile(F);
  end;
end;

initialization
  {$I sommap_icon.lrs}

end.
