unit aiproject_agents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson;

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

    { Populates project with the 9 standard agent profiles. }
    procedure CreateDefaultAgents;

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

procedure TAIProjectAgents.CreateDefaultAgents;
var
  Agents: TJSONArray;
begin
  Agents := GetAgents;
  if not Assigned(Agents) then Exit;
  Agents.Clear;

  Agents.Add(TJSONObject.Create(['id', 'AG001', 'name', 'UI Agent',
    'profile', 'UI', 'description', 'Specialist in screen flow and UX',
    'skill_level', 'senior', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG002', 'name', 'DBA Agent',
    'profile', 'DBA', 'description', 'Specialist in database and storage',
    'skill_level', 'senior', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG003', 'name', 'DEV Agent',
    'profile', 'DEV', 'description', 'Software Developer',
    'skill_level', 'mid_level', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG004', 'name', 'Infra Agent',
    'profile', 'Infra', 'description', 'Deployment and infrastructure expert',
    'skill_level', 'senior', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG005', 'name', 'Operador',
    'profile', 'Operador', 'description', 'System operator',
    'skill_level', 'junior', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG006', 'name', 'Key User',
    'profile', 'Key User', 'description', 'Key business user and validator',
    'skill_level', 'mid_level', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG007', 'name', 'Tester Agent',
    'profile', 'Tester', 'description', 'QA and functional validation',
    'skill_level', 'junior', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG008', 'name', 'Documentador',
    'profile', 'Documentador', 'description', 'Technical writer and documentation specialist',
    'skill_level', 'mid_level', 'active', true]));

  Agents.Add(TJSONObject.Create(['id', 'AG009', 'name', 'Gerente de Projeto',
    'profile', 'Gerente', 'description', 'Project coordinator and stakeholder communicator',
    'skill_level', 'senior', 'active', true]));
end;

function TAIProjectAgents.AddAgent(const AName, AProfile, ADescription,
  ASkillLevel: string; AActive: Boolean): string;
var
  Agents: TJSONArray;
  NewID: string;
begin
  Result := '';
  FLastError := '';
  Agents := GetAgents;
  if not Assigned(Agents) then
  begin
    FLastError := 'Agent array not found. Generate initial plan first.';
    Exit;
  end;
  NewID := 'AG' + Format('%.3d', [Agents.Count + 1]);
  Agents.Add(TJSONObject.Create([
    'id', NewID, 'name', AName, 'profile', AProfile,
    'description', ADescription, 'skill_level', ASkillLevel, 'active', AActive
  ]));
  Result := NewID;
end;

function TAIProjectAgents.UpdateAgent(const AAgentID, AName, AProfile,
  ADescription, ASkillLevel: string; AActive: Boolean): Boolean;
var
  Agents: TJSONArray;
  Obj: TJSONObject;
  i: Integer;
begin
  Result := False;
  FLastError := '';
  Agents := GetAgents;
  if not Assigned(Agents) then Exit;
  for i := 0 to Agents.Count - 1 do
  begin
    Obj := Agents.Objects[i];
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
  Agents: TJSONArray;
begin
  Result := False;
  FLastError := '';
  Agents := GetAgents;
  if not Assigned(Agents) then Exit;
  if (AIndex < 0) or (AIndex >= Agents.Count) then
  begin
    FLastError := 'Invalid agent index: ' + IntToStr(AIndex);
    Exit;
  end;
  Agents.Delete(AIndex);
  Result := True;
end;

function TAIProjectAgents.GetAgentByIndex(AIndex: Integer): TJSONObject;
var
  Agents: TJSONArray;
begin
  Result := nil;
  Agents := GetAgents;
  if Assigned(Agents) and (AIndex >= 0) and (AIndex < Agents.Count) then
    Result := Agents.Objects[AIndex];
end;

function TAIProjectAgents.GetAgentByName(const AName: string): TJSONObject;
var
  Agents: TJSONArray;
  i: Integer;
begin
  Result := nil;
  Agents := GetAgents;
  if not Assigned(Agents) then Exit;
  for i := 0 to Agents.Count - 1 do
    if Agents.Objects[i].Strings['name'] = AName then
    begin
      Result := Agents.Objects[i];
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

end.
