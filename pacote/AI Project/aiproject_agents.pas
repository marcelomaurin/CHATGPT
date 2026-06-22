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
  LAgents: TJSONArray;
begin
  LAgents := GetAgents;
  if not Assigned(LAgents) then Exit;
  LAgents.Clear;

  LAgents.Add(TJSONObject.Create(['id', 'AG001', 'name', 'UI Agent',
    'profile', 'UI', 'description', 'Specialist in screen flow and UX',
    'skill_level', 'senior', 'active', true,
    'responsibilities', TJSONArray.Create(['Design screens', 'Implement UX/UI']),
    'allowed_actions', TJSONArray.Create(['create_screen', 'update_layout']),
    'system_prompt', 'You are a Senior UI/UX Specialist.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG002', 'name', 'DBA Agent',
    'profile', 'DBA', 'description', 'Specialist in database and storage',
    'skill_level', 'senior', 'active', true,
    'responsibilities', TJSONArray.Create(['Design database schemas', 'Optimize queries']),
    'allowed_actions', TJSONArray.Create(['create_table', 'alter_schema']),
    'system_prompt', 'You are a Senior DBA.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG003', 'name', 'DEV Agent',
    'profile', 'DEV', 'description', 'Software Developer',
    'skill_level', 'mid_level', 'active', true,
    'responsibilities', TJSONArray.Create(['Write business logic', 'Fix bugs']),
    'allowed_actions', TJSONArray.Create(['write_code', 'run_tests']),
    'system_prompt', 'You are a Developer.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG004', 'name', 'Infra Agent',
    'profile', 'Infra', 'description', 'Deployment and infrastructure expert',
    'skill_level', 'senior', 'active', true,
    'responsibilities', TJSONArray.Create(['Manage infrastructure', 'Deploy applications']),
    'allowed_actions', TJSONArray.Create(['deploy', 'restart_server']),
    'system_prompt', 'You are an Infrastructure specialist.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG005', 'name', 'Operador',
    'profile', 'Operador', 'description', 'System operator',
    'skill_level', 'junior', 'active', true,
    'responsibilities', TJSONArray.Create(['Monitor system', 'Report issues']),
    'allowed_actions', TJSONArray.Create(['view_logs', 'create_ticket']),
    'system_prompt', 'You are a System Operator.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG006', 'name', 'Key User',
    'profile', 'Key User', 'description', 'Key business user and validator',
    'skill_level', 'mid_level', 'active', true,
    'responsibilities', TJSONArray.Create(['Validate features', 'Provide business rules']),
    'allowed_actions', TJSONArray.Create(['approve_feature', 'reject_feature']),
    'system_prompt', 'You represent the end user.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG007', 'name', 'Tester Agent',
    'profile', 'Tester', 'description', 'QA and functional validation',
    'skill_level', 'junior', 'active', true,
    'responsibilities', TJSONArray.Create(['Run test scripts', 'Find bugs']),
    'allowed_actions', TJSONArray.Create(['run_tests', 'log_bug']),
    'system_prompt', 'You are a QA Tester.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG008', 'name', 'Documentador',
    'profile', 'Documentador', 'description', 'Technical writer and documentation specialist',
    'skill_level', 'mid_level', 'active', true,
    'responsibilities', TJSONArray.Create(['Write manuals', 'Update wiki']),
    'allowed_actions', TJSONArray.Create(['write_doc', 'publish_doc']),
    'system_prompt', 'You are a Technical Writer.']));

  LAgents.Add(TJSONObject.Create(['id', 'AG009', 'name', 'Gerente de Projeto',
    'profile', 'Gerente', 'description', 'Project coordinator and stakeholder communicator',
    'skill_level', 'senior', 'active', true,
    'responsibilities', TJSONArray.Create(['Plan sprints', 'Manage risks']),
    'allowed_actions', TJSONArray.Create(['assign_task', 'approve_milestone']),
    'system_prompt', 'You are the Project Manager.']));
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

end.
