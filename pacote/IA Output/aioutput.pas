unit aioutput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  TArray = array of Double;

  { TAIOutputData }

  TAIOutputData = class(TComponent)
  private
    FProbabilities: TArray;
    FClasses: TStrings;
    FClassificationResult: string;
    procedure SetClasses(AValue: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SoftMax;
    function GetBestClassIndex: Integer;
    function GetBestClassName: string;
    procedure UpdateResult;
  published
    property Probabilities: TArray read FProbabilities write FProbabilities;
    property Classes: TStrings read FClasses write SetClasses;
    property ClassificationResult: string read FClassificationResult write FClassificationResult;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Output', [TAIOutputData]);
end;

constructor TAIOutputData.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClasses := TStringList.Create;
  FClassificationResult := '';
  SetLength(FProbabilities, 0);
end;

destructor TAIOutputData.Destroy;
begin
  FClasses.Free;
  inherited Destroy;
end;

procedure TAIOutputData.SetClasses(AValue: TStrings);
begin
  FClasses.Assign(AValue);
end;

procedure TAIOutputData.SoftMax;
var
  I: Integer;
  MaxVal, SumExp: Double;
  ExpVals: TArray;
begin
  if Length(FProbabilities) = 0 then
    Exit;
  
  // Encontra o maior valor para estabilidade numérica
  MaxVal := FProbabilities[0];
  for I := 1 to High(FProbabilities) do
    if FProbabilities[I] > MaxVal then
      MaxVal := FProbabilities[I];
    
  SetLength(ExpVals, Length(FProbabilities));
  SumExp := 0.0;
  for I := 0 to High(FProbabilities) do
  begin
    ExpVals[I] := Exp(FProbabilities[I] - MaxVal);
    SumExp := SumExp + ExpVals[I];
  end;
  
  if SumExp = 0.0 then
    SumExp := 1.0;
  
  for I := 0 to High(FProbabilities) do
    FProbabilities[I] := ExpVals[I] / SumExp;
    
  UpdateResult;
end;

function TAIOutputData.GetBestClassIndex: Integer;
var
  I: Integer;
  MaxProb: Double;
begin
  Result := -1;
  if Length(FProbabilities) = 0 then
    Exit;
  
  Result := 0;
  MaxProb := FProbabilities[0];
  for I := 1 to High(FProbabilities) do
  begin
    if FProbabilities[I] > MaxProb then
    begin
      MaxProb := FProbabilities[I];
      Result := I;
    end;
  end;
end;

function TAIOutputData.GetBestClassName: string;
var
  Idx: Integer;
begin
  Result := '';
  Idx := GetBestClassIndex;
  if (Idx >= 0) and (Idx < FClasses.Count) then
    Result := FClasses[Idx]
  else if Idx >= 0 then
    Result := 'Classe ' + IntToStr(Idx);
end;

procedure TAIOutputData.UpdateResult;
var
  Idx: Integer;
begin
  Idx := GetBestClassIndex;
  if Idx >= 0 then
  begin
    if GetBestClassName <> '' then
      FClassificationResult := Format('%s (%0.2f%%)', [GetBestClassName, FProbabilities[Idx] * 100.0])
    else
      FClassificationResult := Format('Classe %d (%0.2f%%)', [Idx, FProbabilities[Idx] * 100.0]);
  end
  else
    FClassificationResult := '';
end;

end.
