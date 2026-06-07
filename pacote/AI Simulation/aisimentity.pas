unit aisimentity;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, fpjson, LResources;

type
  { TAISimEntity }

  TAISimEntity = class(TAIBaseComponent)
  private
    FId: string;
    FEntityType: string;
    FEntityName: string;
    FActive: Boolean;
    FX: Integer;
    FY: Integer;
    FProperties: TJSONObject;
    FOnStep: TNotifyEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Clone(AOwner: TComponent): TAISimEntity; virtual;
    procedure Step; virtual;
    
    procedure SetPropertyDouble(const AName: string; const AValue: Double);
    function GetPropertyDouble(const AName: string; const ADefault: Double = 0.0): Double;
    procedure SetPropertyInteger(const AName: string; const AValue: Integer);
    function GetPropertyInteger(const AName: string; const ADefault: Integer = 0): Integer;
    procedure SetPropertyString(const AName: string; const AValue: string);
    function GetPropertyString(const AName: string; const ADefault: string = ''): string;
    procedure SetPropertyBoolean(const AName: string; const AValue: Boolean);
    function GetPropertyBoolean(const AName: string; const ADefault: Boolean = False): Boolean;
    
    property Properties: TJSONObject read FProperties;
  published
    property Id: string read FId write FId;
    property EntityType: string read FEntityType write FEntityType;
    property EntityName: string read FEntityName write FEntityName;
    property Active: Boolean read FActive write FActive default True;
    property X: Integer read FX write FX default -1;
    property Y: Integer read FY write FY default -1;
    property OnStep: TNotifyEvent read FOnStep write FOnStep;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAISimEntity]);
end;

{ TAISimEntity }

constructor TAISimEntity.Create(AOwner: TComponent);
var
  LGUID: TGUID;
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAISimEntity represents a generic simulation entity with positions X, Y, unique ID, type, active status and arbitrary properties.';
  FId := '';
  if CreateGUID(LGUID) = 0 then
    FId := GUIDToString(LGUID);
  // Strip braces
  if (Length(FId) > 0) and (FId[1] = '{') then
    FId := Copy(FId, 2, Length(FId) - 2);
  FEntityType := 'generic';
  FEntityName := '';
  FActive := True;
  FX := -1;
  FY := -1;
  FProperties := TJSONObject.Create;
end;

destructor TAISimEntity.Destroy;
begin
  FProperties.Free;
  inherited Destroy;
end;

function TAISimEntity.Clone(AOwner: TComponent): TAISimEntity;
var
  LData: string;
  LGUID: TGUID;
begin
  Result := TAISimEntity.Create(AOwner);
  Result.Id := '';
  if CreateGUID(LGUID) = 0 then
    Result.Id := GUIDToString(LGUID);
  if (Length(Result.Id) > 0) and (Result.Id[1] = '{') then
    Result.Id := Copy(Result.Id, 2, Length(Result.Id) - 2);
  Result.EntityType := FEntityType;
  Result.EntityName := FEntityName;
  Result.Active := FActive;
  Result.X := FX;
  Result.Y := FY;
  
  // Clone properties
  LData := FProperties.AsJSON;
  Result.Properties.Free;
  Result.FProperties := TJSONObject(GetJSON(LData));
end;

procedure TAISimEntity.Step;
begin
  if FActive and Assigned(FOnStep) then
    FOnStep(Self);
end;

procedure TAISimEntity.SetPropertyDouble(const AName: string; const AValue: Double);
var
  Idx: Integer;
begin
  Idx := FProperties.IndexOfName(AName);
  if Idx >= 0 then
    FProperties.Delete(Idx);
  FProperties.Add(AName, AValue);
end;

function TAISimEntity.GetPropertyDouble(const AName: string; const ADefault: Double): Double;
var
  LData: TJSONData;
begin
  Result := ADefault;
  LData := FProperties.Find(AName);
  if Assigned(LData) then
    Result := LData.AsFloat;
end;

procedure TAISimEntity.SetPropertyInteger(const AName: string; const AValue: Integer);
var
  Idx: Integer;
begin
  Idx := FProperties.IndexOfName(AName);
  if Idx >= 0 then
    FProperties.Delete(Idx);
  FProperties.Add(AName, AValue);
end;

function TAISimEntity.GetPropertyInteger(const AName: string; const ADefault: Integer): Integer;
var
  LData: TJSONData;
begin
  Result := ADefault;
  LData := FProperties.Find(AName);
  if Assigned(LData) then
    Result := LData.AsInteger;
end;

procedure TAISimEntity.SetPropertyString(const AName: string; const AValue: string);
var
  Idx: Integer;
begin
  Idx := FProperties.IndexOfName(AName);
  if Idx >= 0 then
    FProperties.Delete(Idx);
  FProperties.Add(AName, AValue);
end;

function TAISimEntity.GetPropertyString(const AName: string; const ADefault: string): string;
var
  LData: TJSONData;
begin
  Result := ADefault;
  LData := FProperties.Find(AName);
  if Assigned(LData) then
    Result := LData.AsString;
end;

procedure TAISimEntity.SetPropertyBoolean(const AName: string; const AValue: Boolean);
var
  Idx: Integer;
begin
  Idx := FProperties.IndexOfName(AName);
  if Idx >= 0 then
    FProperties.Delete(Idx);
  FProperties.Add(AName, AValue);
end;

function TAISimEntity.GetPropertyBoolean(const AName: string; const ADefault: Boolean): Boolean;
var
  LData: TJSONData;
begin
  Result := ADefault;
  LData := FProperties.Find(AName);
  if Assigned(LData) then
    Result := LData.AsBoolean;
end;

initialization
  {$I aisimentity_icon.lrs}

end.
