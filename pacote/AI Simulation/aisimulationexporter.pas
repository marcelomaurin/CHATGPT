unit aisimulationexporter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimulationstats, aiscenarioconfig, fpjson, LResources;

type
  { TAISimulationExporter }

  TAISimulationExporter = class(TAIBaseComponent)
  public
    constructor Create(AOwner: TComponent); override;
    
    function ExportToCSV(const AFileName: string; AStats: TAISimulationStats): Boolean;
    function ExportToJSON(const AFileName: string; AConfig: TAIScenarioConfig): Boolean;
    function ExportToTXT(const AFileName: string; AStats: TAISimulationStats): Boolean;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAISimulationExporter]);
end;

{ TAISimulationExporter }

constructor TAISimulationExporter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAISimulationExporter exports simulation history, metrics and setup configurations to JSON, CSV and structured TXT formats.';
end;

function TAISimulationExporter.ExportToCSV(const AFileName: string; AStats: TAISimulationStats): Boolean;
var
  LFile: TStringList;
  LStatsJSON: string;
  LJSON: TJSONData;
  LObj: TJSONObject;
  LTypeStats: TJSONObject;
  i: Integer;
begin
  Result := False;
  ClearError;
  if not Assigned(AStats) then Exit;
  
  LFile := TStringList.Create;
  try
    LStatsJSON := AStats.GetStatsJSON;
    LJSON := GetJSON(LStatsJSON);
    if Assigned(LJSON) and (LJSON is TJSONObject) then
    begin
      LObj := TJSONObject(LJSON);
      LFile.Add('Metric,Value');
      LFile.Add(Format('CyclesExecuted,%d', [LObj.Get('cycles', 0)]));
      LFile.Add(Format('TotalCreated,%d', [LObj.Get('totalCreated', 0)]));
      LFile.Add(Format('TotalRemoved,%d', [LObj.Get('totalRemoved', 0)]));
      LFile.Add(Format('ActiveEntities,%d', [LObj.Get('activeCount', 0)]));
      
      LTypeStats := LObj.Objects['typeStats'];
      if Assigned(LTypeStats) then
      begin
        for i := 0 to LTypeStats.Count - 1 do
        begin
          LFile.Add(Format('TypePopulation_%s,%d', [LTypeStats.Names[i], LTypeStats.Items[i].AsInteger]));
        end;
      end;
      
      LFile.SaveToFile(AFileName);
      Result := True;
      LJSON.Free;
    end;
  except
    on E: Exception do
    begin
      SetError('CSV Export failed: ' + E.Message);
    end;
  end;
  LFile.Free;
end;

function TAISimulationExporter.ExportToJSON(const AFileName: string; AConfig: TAIScenarioConfig): Boolean;
begin
  Result := False;
  if Assigned(AConfig) then
  begin
    Result := AConfig.SaveToJSONFile(AFileName);
    if not Result then
      SetError(AConfig.LastError);
  end;
end;

function TAISimulationExporter.ExportToTXT(const AFileName: string; AStats: TAISimulationStats): Boolean;
var
  LList: TStringList;
begin
  Result := False;
  ClearError;
  if not Assigned(AStats) then Exit;
  
  LList := TStringList.Create;
  try
    LList.Text := AStats.GetSummaryText;
    LList.SaveToFile(AFileName);
    Result := True;
  except
    on E: Exception do
    begin
      SetError('TXT Export failed: ' + E.Message);
    end;
  end;
  LList.Free;
end;

initialization
  {$I aisimulationexporter_icon.lrs}

end.
