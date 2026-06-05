unit MatrizComponent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TAMatriz = class
  private
    FKey: Integer; // Real class
    FValue: Integer; // Predicted class
  public
    property Key: Integer read FKey write FKey; // Actual class
    property Value: Integer read FValue write FValue; // Predicted class
    constructor Create(AKey, AValue: Integer);
  end;

  TAMatrizComponent = class(TComponent)
  private
    FList: TList;
    function GetCount: Integer;
    function GetItem(Index: Integer): TAMatriz;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(AKey, AValue: Integer);
    function IndexOf(AKey: Integer): Integer;
    function Item(Index: Integer): TAMatriz;
    procedure ClearAll;
    procedure Delete(Index: Integer);
    procedure CalculateMetrics(out TruePositives, FalsePositives, FalseNegatives, TrueNegatives: Integer);
    function Precision: Double;
    function Recall: Double;
    function F1Score: Double;
    property Count: Integer read GetCount;
  end;

procedure Register;

implementation

constructor TAMatriz.Create(AKey, AValue: Integer);
begin
  inherited Create;
  FKey := AKey;
  FValue := AValue;
end;

constructor TAMatrizComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TList.Create;
end;

destructor TAMatrizComponent.Destroy;
begin
  ClearAll;
  FList.Free;
  inherited Destroy;
end;

procedure TAMatrizComponent.Add(AKey, AValue: Integer);
begin
  FList.Add(TAMatriz.Create(AKey, AValue));
end;

function TAMatrizComponent.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TAMatrizComponent.GetItem(Index: Integer): TAMatriz;
begin
  Result := TAMatriz(FList[Index]);
end;

function TAMatrizComponent.IndexOf(AKey: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FList.Count - 1 do
    if TAMatriz(FList[i]).Key = AKey then
    begin
      Result := i;
      Break;
    end;
end;

function TAMatrizComponent.Item(Index: Integer): TAMatriz;
begin
  Result := GetItem(Index);
end;

procedure TAMatrizComponent.ClearAll;
var
  i: Integer;
begin
  for i := FList.Count - 1 downto 0 do
  begin
    TAMatriz(FList[i]).Free;
    FList.Delete(i);
  end;
end;

procedure TAMatrizComponent.Delete(Index: Integer);
begin
  TAMatriz(FList[Index]).Free;
  FList.Delete(Index);
end;

procedure TAMatrizComponent.CalculateMetrics(out TruePositives, FalsePositives, FalseNegatives, TrueNegatives: Integer);
var
  i: Integer;
  Matriz: TAMatriz;
begin
  TruePositives := 0; TrueNegatives := 0; FalsePositives := 0; FalseNegatives := 0;
  for i := 0 to FList.Count - 1 do
  begin
    Matriz := TAMatriz(FList[i]);
    if (Matriz.Key = 1) and (Matriz.Value = 1) then Inc(TruePositives)
    else if (Matriz.Key = 0) and (Matriz.Value = 0) then Inc(TrueNegatives)
    else if (Matriz.Key = 1) and (Matriz.Value = 0) then Inc(FalseNegatives)
    else if (Matriz.Key = 0) and (Matriz.Value = 1) then Inc(FalsePositives);
  end;
end;

function TAMatrizComponent.Precision: Double;
var
  TruePositives, FalsePositives, FalseNegatives, TrueNegatives: Integer;
begin
  CalculateMetrics(TruePositives, FalsePositives, FalseNegatives, TrueNegatives);
  if TruePositives + FalsePositives = 0 then
    Result := 0
  else
    Result := TruePositives / (TruePositives + FalsePositives);
end;

function TAMatrizComponent.Recall: Double;
var
  TruePositives, FalsePositives, FalseNegatives, TrueNegatives: Integer;
begin
  CalculateMetrics(TruePositives, FalsePositives, FalseNegatives, TrueNegatives);
  if TruePositives + FalseNegatives = 0 then
    Result := 0
  else
    Result := TruePositives / (TruePositives + FalseNegatives);
end;

function TAMatrizComponent.F1Score: Double;
var
  P, R: Double;
begin
  P := Precision;
  R := Recall;
  if P + R = 0 then
    Result := 0
  else
    Result := 2 * (P * R) / (P + R);
end;

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TAMatrizComponent]);
end;

initialization
  {$I matrizcomponent_icon.lrs}

end.

