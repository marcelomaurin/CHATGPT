unit aisimulationstats;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, fpjson;

type
  { TAISimulationStats }

  TAISimulationStats = class(TAIBaseComponent)
  private
    FCycleCount: Integer;
    FCreatedCount: Integer;
    FRemovedCount: Integer;
    FTypeStats: TJSONObject;
    FCycleDurations: TJSONArray;
    FHistoryLimit: Integer;
    
    procedure CleanStats;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure ClearStats;
    procedure RecordCycle(ADurationMs: Double);
    procedure RecordEntityCreated(const AType: string);
    procedure RecordEntityRemoved(const AType: string);
    
    function GetStatsJSON: string;
    function GetSummaryText: string;
  published
    property CycleCount: Integer read FCycleCount write FCycleCount default 0;
    property CreatedCount: Integer read FCreatedCount write FCreatedCount default 0;
    property RemovedCount: Integer read FRemovedCount write FRemovedCount default 0;
    property HistoryLimit: Integer read FHistoryLimit write FHistoryLimit default 1000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAISimulationStats]);
end;

{ TAISimulationStats }

constructor TAISimulationStats.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAISimulationStats tracks execution stats like cycle counts, active entities, execution speeds, and history.';
  FCycleCount := 0;
  FCreatedCount := 0;
  FRemovedCount := 0;
  FHistoryLimit := 1000;
  FTypeStats := TJSONObject.Create;
  FCycleDurations := TJSONArray.Create;
end;

destructor TAISimulationStats.Destroy;
begin
  FTypeStats.Free;
  FCycleDurations.Free;
  inherited Destroy;
end;

procedure TAISimulationStats.CleanStats;
begin
  FTypeStats.Clear;
  FCycleDurations.Clear;
  FCycleCount := 0;
  FCreatedCount := 0;
  FRemovedCount := 0;
end;

procedure TAISimulationStats.ClearStats;
begin
  CleanStats;
end;

procedure TAISimulationStats.RecordCycle(ADurationMs: Double);
begin
  Inc(FCycleCount);
  FCycleDurations.Add(ADurationMs);
  // Enforce history limit
  while FCycleDurations.Count > FHistoryLimit do
  begin
    FCycleDurations.Delete(0);
  end;
end;

procedure TAISimulationStats.RecordEntityCreated(const AType: string);
var
  LData: TJSONData;
  LVal: Integer;
begin
  Inc(FCreatedCount);
  LData := FTypeStats.Find(AType);
  if Assigned(LData) then
  begin
    LVal := LData.AsInteger;
    FTypeStats.Add(AType, LVal + 1);
  end
  else
  begin
    FTypeStats.Add(AType, 1);
  end;
end;

procedure TAISimulationStats.RecordEntityRemoved(const AType: string);
var
  LData: TJSONData;
  LVal: Integer;
begin
  Inc(FRemovedCount);
  LData := FTypeStats.Find(AType);
  if Assigned(LData) then
  begin
    LVal := LData.AsInteger;
    if LVal > 0 then
      FTypeStats.Add(AType, LVal - 1);
  end;
end;

function TAISimulationStats.GetStatsJSON: string;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  try
    LObj.Add('cycles', FCycleCount);
    LObj.Add('totalCreated', FCreatedCount);
    LObj.Add('totalRemoved', FRemovedCount);
    LObj.Add('activeCount', FCreatedCount - FRemovedCount);
    LObj.Add('typeStats', FTypeStats.Clone);
    LObj.Add('cycleTimes', FCycleDurations.Clone);
    Result := LObj.AsJSON;
  finally
    LObj.Free;
  end;
end;

function TAISimulationStats.GetSummaryText: string;
var
  LList: TStringList;
  i: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Add('=== SIMULATION STATISTICS ===');
    LList.Add(Format('Cycles Executed: %d', [FCycleCount]));
    LList.Add(Format('Total Created:   %d', [FCreatedCount]));
    LList.Add(Format('Total Removed:   %d', [FRemovedCount]));
    LList.Add(Format('Active Entities: %d', [FCreatedCount - FRemovedCount]));
    LList.Add('');
    LList.Add('Entities by Type:');
    for i := 0 to FTypeStats.Count - 1 do
    begin
      LList.Add(Format('  - %s: %d', [FTypeStats.Names[i], FTypeStats.Items[i].AsInteger]));
    end;
    Result := LList.Text;
  finally
    LList.Free;
  end;
end;

end.
