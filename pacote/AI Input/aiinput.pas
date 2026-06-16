unit aiinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, LResources;

type
  TArray = array of Double;

  { TAIInputData }

  TAIInputData = class(TAIBaseComponent)
  private
    FRawData: TArray;
    FNormalizedData: TArray;
    FMinRange: Double;
    FMaxRange: Double;
    procedure SetRawData(AValue: TArray);
  public
    constructor Create(AOwner: TComponent); override;
    
    procedure Normalize;
    procedure Denormalize;
    procedure LoadFromString(const AValue: string; const ADelimiter: Char = ',');
    function GetLength: Integer;
  published
    property RawData: TArray read FRawData write SetRawData;
    property NormalizedData: TArray read FNormalizedData write FNormalizedData;
    property MinRange: Double read FMinRange write FMinRange;
    property MaxRange: Double read FMaxRange write FMaxRange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIInputData]);
end;

constructor TAIInputData.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIInputData handles preprocessing raw numerical arrays. Properties: RawData: TArray (input), NormalizedData: TArray (output), MinRange/MaxRange: Double (normalization limits, e.g., 0.0 to 1.0). Methods: LoadFromString(const AValue: string; const ADelimiter: Char) to populate RawData, Normalize to scale RawData into NormalizedData, Denormalize to convert NormalizedData back, GetLength: Integer. AI Agent: Use this to scale raw neural inputs before predicting.';
  FMinRange := 0.0;
  FMaxRange := 1.0;
  SetLength(FRawData, 0);
  SetLength(FNormalizedData, 0);
end;

procedure TAIInputData.SetRawData(AValue: TArray);
begin
  FRawData := AValue;
end;

procedure TAIInputData.Normalize;
var
  I: Integer;
  VMin, VMax, Range: Double;
begin
  ClearError;
  try
    if Length(FRawData) = 0 then
      Exit;
    SetLength(FNormalizedData, Length(FRawData));
    
    VMin := FRawData[0];
    VMax := FRawData[0];
    for I := 1 to High(FRawData) do
    begin
      if FRawData[I] < VMin then
        VMin := FRawData[I];
      if FRawData[I] > VMax then
        VMax := FRawData[I];
    end;
    
    Range := VMax - VMin;
    if Range = 0.0 then
      Range := 1.0;
    
    for I := 0 to High(FRawData) do
    begin
      FNormalizedData[I] := FMinRange + ((FRawData[I] - VMin) / Range) * (FMaxRange - FMinRange);
    end;
    FLastResult := 'Normalization Completed';
    FLastSuccess := True;
  except
    on E: Exception do
      SetError('Normalize Error: ' + E.Message);
  end;
end;

procedure TAIInputData.Denormalize;
var
  I: Integer;
  VMin, VMax, Range: Double;
begin
  ClearError;
  try
    if Length(FNormalizedData) = 0 then
      Exit;
    SetLength(FRawData, Length(FNormalizedData));
    
    VMin := FMinRange;
    VMax := FMaxRange;
    Range := VMax - VMin;
    if Range = 0.0 then
      Range := 1.0;
    
    for I := 0 to High(FNormalizedData) do
    begin
      FRawData[I] := ((FNormalizedData[I] - FMinRange) / Range) * Range + VMin;
    end;
    FLastResult := 'Denormalization Completed';
    FLastSuccess := True;
  except
    on E: Exception do
      SetError('Denormalize Error: ' + E.Message);
  end;
end;

procedure TAIInputData.LoadFromString(const AValue: string; const ADelimiter: Char);
var
  StrList: TStringList;
  I: Integer;
begin
  ClearError;
  StrList := TStringList.Create;
  try
    try
      StrList.Delimiter := ADelimiter;
      StrList.StrictDelimiter := True;
      StrList.DelimitedText := AValue;
      
      SetLength(FRawData, StrList.Count);
      for I := 0 to StrList.Count - 1 do
        FRawData[I] := StrToFloatDef(Trim(StrList[I]), 0.0);
      FLastResult := 'Data Loaded From String';
      FLastSuccess := True;
    except
      on E: Exception do
        SetError('LoadFromString Error: ' + E.Message);
    end;
  finally
    StrList.Free;
  end;
end;

function TAIInputData.GetLength: Integer;
begin
  Result := Length(FRawData);
end;

initialization
  {$I aiinput_icon.lrs}

end.
