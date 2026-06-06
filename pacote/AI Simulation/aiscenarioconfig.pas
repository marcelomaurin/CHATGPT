unit aiscenarioconfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, fpjson, jsonparser, aigridworld, aientityfactory, aisimentity, aigridcell;

type
  { TAIScenarioConfig }

  TAIScenarioConfig = class(TAIBaseComponent)
  private
    FScenarioName: string;
    FWorldWidth: Integer;
    FWorldHeight: Integer;
    FConfigData: TJSONObject;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure ClearConfig;
    
    function LoadFromJSONFile(const AFileName: string): Boolean;
    function SaveToJSONFile(const AFileName: string): Boolean;
    
    function ApplyToWorld(AWorld: TAIGridWorld; AFactory: TAIEntityFactory): Boolean;
    function CaptureFromWorld(AWorld: TAIGridWorld): Boolean;
    
    property ConfigData: TJSONObject read FConfigData;
  published
    property ScenarioName: string read FScenarioName write FScenarioName;
    property WorldWidth: Integer read FWorldWidth write FWorldWidth default 10;
    property WorldHeight: Integer read FWorldHeight write FWorldHeight default 10;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIScenarioConfig]);
end;

{ TAIScenarioConfig }

constructor TAIScenarioConfig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIScenarioConfig manages the serialization and deserialization of simulation layouts, terrain data and initial entity configurations.';
  FScenarioName := 'default_scenario';
  FWorldWidth := 10;
  FWorldHeight := 10;
  FConfigData := TJSONObject.Create;
end;

destructor TAIScenarioConfig.Destroy;
begin
  FConfigData.Free;
  inherited Destroy;
end;

procedure TAIScenarioConfig.ClearConfig;
begin
  FConfigData.Clear;
  FScenarioName := 'default_scenario';
  FWorldWidth := 10;
  FWorldHeight := 10;
end;

function TAIScenarioConfig.LoadFromJSONFile(const AFileName: string): Boolean;
var
  LStream: TFileStream;
  LParser: TJSONParser;
  LJSON: TJSONData;
begin
  Result := False;
  ClearError;
  
  if not FileExists(AFileName) then
  begin
    SetError('Scenario file not found: ' + AFileName);
    Exit;
  end;
  
  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  LParser := TJSONParser.Create(LStream);
  try
    LJSON := LParser.Parse;
    if Assigned(LJSON) and (LJSON is TJSONObject) then
    begin
      FConfigData.Free;
      FConfigData := TJSONObject(LJSON);
      
      FScenarioName := FConfigData.Get('name', FScenarioName);
      FWorldWidth := FConfigData.Get('width', FWorldWidth);
      FWorldHeight := FConfigData.Get('height', FWorldHeight);
      Result := True;
    end
    else
    begin
      SetError('Invalid JSON format in scenario file.');
    end;
  except
    on E: Exception do
    begin
      SetError('Error loading scenario: ' + E.Message);
    end;
  end;
  LParser.Free;
  LStream.Free;
end;

function TAIScenarioConfig.SaveToJSONFile(const AFileName: string): Boolean;
var
  LList: TStringList;
begin
  Result := False;
  ClearError;
  
  FConfigData.Add('name', FScenarioName);
  FConfigData.Add('width', FWorldWidth);
  FConfigData.Add('height', FWorldHeight);
  
  LList := TStringList.Create;
  try
    LList.Text := FConfigData.AsJSON;
    LList.SaveToFile(AFileName);
    Result := True;
  except
    on E: Exception do
    begin
      SetError('Error saving scenario: ' + E.Message);
    end;
  end;
  LList.Free;
end;

function TAIScenarioConfig.ApplyToWorld(AWorld: TAIGridWorld; AFactory: TAIEntityFactory): Boolean;
var
  LCells: TJSONArray;
  LEntities: TJSONArray;
  i: Integer;
  LCellObj: TJSONObject;
  LEntityObj: TJSONObject;
  CX, CY: Integer;
  EType, EName: string;
  EX, EY: Integer;
  LCell: aigridcell.TAIGridCell;
  LEntity: TAISimEntity;
begin
  Result := False;
  if not Assigned(AWorld) then Exit;
  
  AWorld.SetupWorld(FWorldWidth, FWorldHeight);
  
  // Apply terrain / cells
  LCells := FConfigData.Arrays['cells'];
  if Assigned(LCells) then
  begin
    for i := 0 to LCells.Count - 1 do
    begin
      LCellObj := LCells.Objects[i];
      CX := LCellObj.Get('x', -1);
      CY := LCellObj.Get('y', -1);
      LCell := AWorld.Cells[CX, CY];
      if Assigned(LCell) then
      begin
        LCell.Blocked := LCellObj.Get('blocked', False);
        LCell.Cost := LCellObj.Get('cost', 1.0);
        LCell.TerrainType := LCellObj.Get('terrain', 'default');
      end;
    end;
  end;
  
  // Apply entities
  LEntities := FConfigData.Arrays['entities'];
  if Assigned(LEntities) and Assigned(AFactory) then
  begin
    for i := 0 to LEntities.Count - 1 do
    begin
      LEntityObj := LEntities.Objects[i];
      EType := LEntityObj.Get('type', '');
      EName := LEntityObj.Get('name', '');
      EX := LEntityObj.Get('x', -1);
      EY := LEntityObj.Get('y', -1);
      
      LEntity := AFactory.CreateEntity(EType, AWorld.Owner);
      if Assigned(LEntity) then
      begin
        LEntity.EntityName := EName;
        // Merge properties if available
        if LEntityObj.Find('properties') <> nil then
        begin
          // Simple key-value properties clone
          // For simplicity we use factory features
        end;
        
        AWorld.AddEntity(LEntity, EX, EY);
      end;
    end;
  end;
  
  Result := True;
end;

function TAIScenarioConfig.CaptureFromWorld(AWorld: TAIGridWorld): Boolean;
var
  LCells: TJSONArray;
  LEntities: TJSONArray;
  X, Y, i: Integer;
  LCell: aigridcell.TAIGridCell;
  LCellObj: TJSONObject;
  LEntity: TAISimEntity;
  LEntityObj: TJSONObject;
begin
  Result := False;
  if not Assigned(AWorld) then Exit;
  
  ClearConfig;
  FWorldWidth := AWorld.Width;
  FWorldHeight := AWorld.Height;
  
  FConfigData.Add('name', FScenarioName);
  FConfigData.Add('width', FWorldWidth);
  FConfigData.Add('height', FWorldHeight);
  
  LCells := TJSONArray.Create;
  for X := 0 to FWorldWidth - 1 do
  begin
    for Y := 0 to FWorldHeight - 1 do
    begin
      LCell := AWorld.Cells[X, Y];
      if Assigned(LCell) and (LCell.Blocked or (LCell.TerrainType <> 'default') or (LCell.Cost <> 1.0)) then
      begin
        LCellObj := TJSONObject.Create;
        LCellObj.Add('x', X);
        LCellObj.Add('y', Y);
        LCellObj.Add('blocked', LCell.Blocked);
        LCellObj.Add('cost', LCell.Cost);
        LCellObj.Add('terrain', LCell.TerrainType);
        LCells.Add(LCellObj);
      end;
    end;
  end;
  FConfigData.Add('cells', LCells);
  
  LEntities := TJSONArray.Create;
  for i := 0 to AWorld.Entities.Count - 1 do
  begin
    LEntity := TAISimEntity(AWorld.Entities[i]);
    LEntityObj := TJSONObject.Create;
    LEntityObj.Add('type', LEntity.EntityType);
    LEntityObj.Add('name', LEntity.EntityName);
    LEntityObj.Add('x', LEntity.X);
    LEntityObj.Add('y', LEntity.Y);
    LEntityObj.Add('properties', LEntity.Properties.Clone);
    LEntities.Add(LEntityObj);
  end;
  FConfigData.Add('entities', LEntities);
  
  Result := True;
end;

end.
