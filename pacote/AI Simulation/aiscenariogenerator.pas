unit aiscenariogenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, chatgpt, aiscenarioconfig, fpjson, jsonparser;

type
  { TAIScenarioGenerator }

  TAIScenarioGenerator = class(TAIBaseComponent)
  private
    FChatGPT: TCHATGPT;
    FScenarioConfig: TAIScenarioConfig;
    
    function GenerateLocalTemplate(const ADescription: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    
    function GenerateScenario(const ADescription: string): Boolean;
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property ScenarioConfig: TAIScenarioConfig read FScenarioConfig write FScenarioConfig;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIScenarioGenerator]);
end;

{ TAIScenarioGenerator }

constructor TAIScenarioGenerator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIScenarioGenerator creates simulation scenarios using TCHATGPT or local fallback templates.';
  FChatGPT := nil;
  FScenarioConfig := nil;
end;

function TAIScenarioGenerator.GenerateLocalTemplate(const ADescription: string): string;
var
  LObj: TJSONObject;
  LCells: TJSONArray;
  LEntities: TJSONArray;
  LCellObj: TJSONObject;
  LEntityObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  try
    LObj.Add('name', 'fallback_local_scenario');
    LObj.Add('width', 15);
    LObj.Add('height', 15);
    
    LCells := TJSONArray.Create;
    // Add some default block cells (like a simple border)
    LCellObj := TJSONObject.Create;
    LCellObj.Add('x', 5);
    LCellObj.Add('y', 5);
    LCellObj.Add('blocked', True);
    LCellObj.Add('cost', 999.0);
    LCellObj.Add('terrain', 'wall');
    LCells.Add(LCellObj);
    
    LObj.Add('cells', LCells);
    
    LEntities := TJSONArray.Create;
    // Add a simple robot entity and a charging station entity
    LEntityObj := TJSONObject.Create;
    LEntityObj.Add('type', 'robot');
    LEntityObj.Add('name', 'bot_1');
    LEntityObj.Add('x', 2);
    LEntityObj.Add('y', 2);
    LEntities.Add(LEntityObj);
    
    LEntityObj := TJSONObject.Create;
    LEntityObj.Add('type', 'charging_station');
    LEntityObj.Add('name', 'station_1');
    LEntityObj.Add('x', 12);
    LEntityObj.Add('y', 12);
    LEntities.Add(LEntityObj);
    
    LObj.Add('entities', LEntities);
    
    Result := LObj.AsJSON;
  finally
    LObj.Free;
  end;
end;

function TAIScenarioGenerator.GenerateScenario(const ADescription: string): Boolean;
var
  LPrompt: string;
  LResponse: string;
  LParser: TJSONParser;
  LJSONData: TJSONData;
  i: Integer;
begin
  Result := False;
  ClearError;
  
  if not Assigned(FScenarioConfig) then
  begin
    SetError('ScenarioConfig property is not assigned.');
    Exit;
  end;
  
  if Assigned(FChatGPT) then
  begin
    LPrompt := 'Generate a JSON structure representing a 2D simulation scenario for a Lazarus AI Suite simulation grid based on this description: "' + ADescription + '". ' +
               'The JSON should have: "name" (string), "width" (int), "height" (int), "cells" (array of objects with keys: x, y, blocked, cost, terrain), ' +
               'and "entities" (array of objects with keys: type, name, x, y). Generate ONLY the raw JSON string without code blocks or extra text.';
               
    if FChatGPT.SendQuestion(LPrompt) then
    begin
      LResponse := FChatGPT.LastResult;
      // Clean up response if the LLM returned markdown code fences
      LResponse := Trim(LResponse);
      if Pos('```json', LResponse) = 1 then
        LResponse := Copy(LResponse, 8, Length(LResponse) - 10)
      else if Pos('```', LResponse) = 1 then
        LResponse := Copy(LResponse, 4, Length(LResponse) - 6);
      LResponse := Trim(LResponse);
      
      try
        LParser := TJSONParser.Create(LResponse);
        LJSONData := nil;
        try
          LJSONData := LParser.Parse;
          if Assigned(LJSONData) and (LJSONData is TJSONObject) then
          begin
            FScenarioConfig.ClearConfig;
            FScenarioConfig.ScenarioName := TJSONObject(LJSONData).Get('name', 'generated_scenario');
            FScenarioConfig.WorldWidth := TJSONObject(LJSONData).Get('width', 10);
            FScenarioConfig.WorldHeight := TJSONObject(LJSONData).Get('height', 10);
            
            FScenarioConfig.ConfigData.Clear;
            for i := 0 to TJSONObject(LJSONData).Count - 1 do
            begin
              FScenarioConfig.ConfigData.Add(
                TJSONObject(LJSONData).Names[i],
                TJSONObject(LJSONData).Items[i].Clone
              );
            end;
            Result := True;
          end;
        finally
          if Assigned(LJSONData) then LJSONData.Free;
          LParser.Free;
        end;
      except
        on E: Exception do
        begin
          SetError('Failed to parse AI generated JSON: ' + E.Message + '. Falling back to local template.');
        end;
      end;
    end
    else
    begin
      SetError('ChatGPT prompt failed: ' + FChatGPT.LastError + '. Falling back to local template.');
    end;
  end;
  
  if not Result then
  begin
    // Local fallback
    try
      LResponse := GenerateLocalTemplate(ADescription);
      LParser := TJSONParser.Create(LResponse);
      LJSONData := nil;
      try
        LJSONData := LParser.Parse;
        if Assigned(LJSONData) and (LJSONData is TJSONObject) then
        begin
          FScenarioConfig.ClearConfig;
          FScenarioConfig.ScenarioName := TJSONObject(LJSONData).Get('name', 'fallback_scenario');
          FScenarioConfig.WorldWidth := TJSONObject(LJSONData).Get('width', 15);
          FScenarioConfig.WorldHeight := TJSONObject(LJSONData).Get('height', 15);
          
          FScenarioConfig.ConfigData.Clear;
          for i := 0 to TJSONObject(LJSONData).Count - 1 do
          begin
            FScenarioConfig.ConfigData.Add(
              TJSONObject(LJSONData).Names[i],
              TJSONObject(LJSONData).Items[i].Clone
            );
          end;
          Result := True;
        end;
      finally
        if Assigned(LJSONData) then LJSONData.Free;
        LParser.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Fallback generation failed: ' + E.Message);
      end;
    end;
  end;
end;

end.
