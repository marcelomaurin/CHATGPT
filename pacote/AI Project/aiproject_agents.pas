unit aiproject_agents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, LResources;

type
  { TAIProjectAgents — manages agents list and agent-task analysis }
  TAIProjectAgents = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    function GetAgents: TJSONArray;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;

    { Adds a new agent. Returns the new agent ID or empty on error. }
    function AddAgent(const AName, AProfile, ADescription,
                      ASkillLevel: string; AActive: Boolean): string;

    { Updates an existing agent by ID. }
    function UpdateAgent(const AAgentID, AName, AProfile,
                         ADescription, ASkillLevel: string;
                         AActive: Boolean): Boolean;

    { Removes an agent by list index. }
    function RemoveAgentByIndex(AIndex: Integer): Boolean;

    { Returns the TJSONObject for the agent at a given list index. }
    function GetAgentByIndex(AIndex: Integer): TJSONObject;

    { Returns the TJSONObject for the agent matching the given name. }
    function GetAgentByName(const AName: string): TJSONObject;

    { Asks the AI agent to analyze a task. User must confirm suggested action. }
    function AskAgentToAnalyzeTask(const ATaskID, AAgentID: string): Boolean;

    property Agents: TJSONArray read GetAgents;
    property Count: Integer read GetCount;
    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectAgents]);
end;

constructor TAIProjectAgents.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIProjectAgents.GetAgents: TJSONArray;
begin
  Result := nil;
  if Assigned(FProject) and Assigned(FProject.ProjectData) then
    Result := TJSONArray(FProject.ProjectData.FindPath('agents'));
end;

function TAIProjectAgents.GetCount: Integer;
var
  Arr: TJSONArray;
begin
  Arr := GetAgents;
  if Assigned(Arr) then Result := Arr.Count else Result := 0;
end;

function TAIProjectAgents.AddAgent(const AName, AProfile, ADescription,
  ASkillLevel: string; AActive: Boolean): string;
var
  LAgents: TJSONArray;
  NewID: string;
begin
  Result := '';
  FLastError := '';
  LAgents := GetAgents;
  if not Assigned(LAgents) then
  begin
    FLastError := 'Agent array not found. Generate initial plan first.';
    Exit;
  end;
  NewID := 'AG' + Format('%.3d', [LAgents.Count + 1]);
  LAgents.Add(TJSONObject.Create([
    'id', NewID, 'name', AName, 'profile', AProfile,
    'description', ADescription, 'skill_level', ASkillLevel, 'active', AActive
  ]));
  Result := NewID;
end;

function TAIProjectAgents.UpdateAgent(const AAgentID, AName, AProfile,
  ADescription, ASkillLevel: string; AActive: Boolean): Boolean;
var
  LAgents: TJSONArray;
  Obj: TJSONObject;
  i: Integer;
begin
  Result := False;
  FLastError := '';
  LAgents := GetAgents;
  if not Assigned(LAgents) then Exit;
  for i := 0 to LAgents.Count - 1 do
  begin
    Obj := LAgents.Objects[i];
    if Obj.Strings['id'] = AAgentID then
    begin
      Obj.Strings['name'] := AName;
      Obj.Strings['profile'] := AProfile;
      Obj.Strings['description'] := ADescription;
      Obj.Strings['skill_level'] := ASkillLevel;
      Obj.Booleans['active'] := AActive;
      Result := True;
      Exit;
    end;
  end;
  FLastError := 'Agent not found: ' + AAgentID;
end;

function TAIProjectAgents.RemoveAgentByIndex(AIndex: Integer): Boolean;
var
  LAgents: TJSONArray;
begin
  Result := False;
  FLastError := '';
  LAgents := GetAgents;
  if not Assigned(LAgents) then Exit;
  if (AIndex < 0) or (AIndex >= LAgents.Count) then
  begin
    FLastError := 'Invalid agent index: ' + IntToStr(AIndex);
    Exit;
  end;
  LAgents.Delete(AIndex);
  Result := True;
end;

function TAIProjectAgents.GetAgentByIndex(AIndex: Integer): TJSONObject;
var
  LAgents: TJSONArray;
begin
  Result := nil;
  LAgents := GetAgents;
  if Assigned(LAgents) and (AIndex >= 0) and (AIndex < LAgents.Count) then
    Result := LAgents.Objects[AIndex];
end;

function TAIProjectAgents.GetAgentByName(const AName: string): TJSONObject;
var
  LAgents: TJSONArray;
  i: Integer;
begin
  Result := nil;
  LAgents := GetAgents;
  if not Assigned(LAgents) then Exit;
  for i := 0 to LAgents.Count - 1 do
    if LAgents.Objects[i].Strings['name'] = AName then
    begin
      Result := LAgents.Objects[i];
      Exit;
    end;
end;

function TAIProjectAgents.AskAgentToAnalyzeTask(const ATaskID,
  AAgentID: string): Boolean;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked.';
    Exit;
  end;
  { Delegates to TAIProject — the AI will suggest an action.
    The user must confirm via TAITaskActions.ApplyAction. }
  Result := FProject.AskAgentToAnalyzeTask(ATaskID, AAgentID);
  if not Result then
    FLastError := FProject.LastError;
end;

initialization
  {$I taiprojectagents_icon.lrs}

end.
