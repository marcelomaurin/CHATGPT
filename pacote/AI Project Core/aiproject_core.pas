unit aiproject_core;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  TAIProjectTaskAction = (taConfirmTask, taRejectTask, taStartTask,
    taFinishTask, taCancelTask, taBlockTask, taUnblockTask, taReopenTask,
    taCommentTask, taRequestRevision);

  TAIProject = class
  private
    FProjectData: TJSONObject;
    procedure EnsureStructure;
    function GetProjectValue(AIndex: Integer): string;
    procedure SetProjectValue(AIndex: Integer; const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure NewProject;
    function LoadJSON(const AJSON: string): Boolean;
    function AsJSON: string;
    function AddRevision(const ATitle, AInput,
      AGeneratedJSON: string): Integer;
    property ProjectData: TJSONObject read FProjectData;
    property Name: string index 0 read GetProjectValue write SetProjectValue;
    property Root: string index 1 read GetProjectValue write SetProjectValue;
    property Description: string index 2 read GetProjectValue write SetProjectValue;
    property Goal: string index 3 read GetProjectValue write SetProjectValue;
    property Scope: string index 4 read GetProjectValue write SetProjectValue;
    property Constraints: string index 5 read GetProjectValue write SetProjectValue;
    property ExpectedDeliverables: string index 6 read GetProjectValue write SetProjectValue;
  end;

  TAIProjectStorage = class
  private
    FProject: TAIProject;
    FLastError: string;
  public
    constructor Create(AProject: TAIProject);
    function LoadFromFile(const AFileName: string): Boolean;
    function SaveToFile(const AFileName: string): Boolean;
    property LastError: string read FLastError;
  end;

  TAIProjectTasks = class
  private
    FProject: TAIProject;
    FLastError: string;
    function GetTasks: TJSONArray;
    function GetCount: Integer;
  public
    constructor Create(AProject: TAIProject);
    function AddTask(const ATitle, ADescription, APriority, AProfile,
      AAssignedTo: string; AEstimatedHours: Integer): string;
    function UpdateTask(const ATaskID, ATitle, ADescription,
      ALongDescription, APriority, AAssignedTo: string;
      AEstimatedHours: Integer): Boolean;
    function GetTaskByID(const ATaskID: string): TJSONObject;
    function LinkCommit(const ATaskID, ACommit: string): Boolean;
    function HasExclusiveConflict(const ATaskID: string;
      out AConflictingTask, AFileName: string): Boolean;
    property Tasks: TJSONArray read GetTasks;
    property Count: Integer read GetCount;
    property LastError: string read FLastError;
  end;

  TAITaskActions = class
  private
    FProject: TAIProject;
    FTasks: TAIProjectTasks;
    FLastError: string;
    class function ActionName(AAction: TAIProjectTaskAction): string; static;
    class function NewStatus(AAction: TAIProjectTaskAction;
      const AOldStatus: string): string; static;
  public
    constructor Create(AProject: TAIProject; ATasks: TAIProjectTasks);
    function ApplyAction(const ATaskID, AActor: string;
      AAction: TAIProjectTaskAction; const AComment: string): Boolean;
    property LastError: string read FLastError;
  end;

procedure JSONSetString(AObject: TJSONObject; const AName, AValue: string);
procedure JSONSetInteger(AObject: TJSONObject; const AName: string;
  AValue: Integer);
function ISODateTimeNow: string;

implementation

procedure JSONSetString(AObject: TJSONObject; const AName, AValue: string);
var
  Index: Integer;
begin
  Index := AObject.IndexOfName(AName);
  if Index >= 0 then AObject.Delete(Index);
  AObject.Add(AName, AValue);
end;

procedure JSONSetInteger(AObject: TJSONObject; const AName: string;
  AValue: Integer);
var
  Index: Integer;
begin
  Index := AObject.IndexOfName(AName);
  if Index >= 0 then AObject.Delete(Index);
  AObject.Add(AName, AValue);
end;

function ISODateTimeNow: string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', Now);
end;

procedure EnsureObject(AParent: TJSONObject; const AName: string);
begin
  if not (AParent.Find(AName) is TJSONObject) then
  begin
    if AParent.IndexOfName(AName) >= 0 then AParent.Delete(AName);
    AParent.Add(AName, TJSONObject.Create);
  end;
end;

procedure EnsureArray(AParent: TJSONObject; const AName: string);
begin
  if not (AParent.Find(AName) is TJSONArray) then
  begin
    if AParent.IndexOfName(AName) >= 0 then AParent.Delete(AName);
    AParent.Add(AName, TJSONArray.Create);
  end;
end;

constructor TAIProject.Create;
begin
  inherited Create;
  NewProject;
end;

destructor TAIProject.Destroy;
begin
  FProjectData.Free;
  inherited Destroy;
end;

procedure TAIProject.NewProject;
begin
  FreeAndNil(FProjectData);
  FProjectData := TJSONObject.Create;
  FProjectData.Add('file_version', '1.1');
  FProjectData.Add('saved_at', ISODateTimeNow);
  EnsureStructure;
end;

procedure TAIProject.EnsureStructure;
var
  ProjectObject, Planning, Agile: TJSONObject;
  Task: TJSONObject;
  I: Integer;
begin
  EnsureObject(FProjectData, 'project');
  ProjectObject := FProjectData.Objects['project'];
  if ProjectObject.IndexOfName('name') < 0 then ProjectObject.Add('name', '');
  if ProjectObject.IndexOfName('root') < 0 then ProjectObject.Add('root', '.');
  if ProjectObject.IndexOfName('description') < 0 then ProjectObject.Add('description', '');
  if ProjectObject.IndexOfName('goal') < 0 then ProjectObject.Add('goal', '');
  if ProjectObject.IndexOfName('scope') < 0 then ProjectObject.Add('scope', '');
  if ProjectObject.IndexOfName('constraints') < 0 then ProjectObject.Add('constraints', '');
  if ProjectObject.IndexOfName('expected_deliverables') < 0 then
    ProjectObject.Add('expected_deliverables', '');
  EnsureObject(FProjectData, 'agile_documents');
  Agile := FProjectData.Objects['agile_documents'];
  EnsureArray(Agile, 'functional_requirements');
  EnsureArray(Agile, 'non_functional_requirements');
  EnsureArray(Agile, 'stakeholders');
  EnsureArray(Agile, 'risk_map');
  EnsureArray(Agile, 'epics');
  EnsureArray(Agile, 'user_stories');
  EnsureArray(FProjectData, 'agents');
  EnsureObject(FProjectData, 'planning');
  Planning := FProjectData.Objects['planning'];
  EnsureArray(Planning, 'tasks');
  EnsureArray(Planning, 'dependencies');
  EnsureArray(Planning, 'execution_plan');
  EnsureArray(Planning, 'parallel_groups');
  EnsureArray(Planning, 'milestones');
  EnsureArray(Planning, 'gantt');
  EnsureArray(Planning, 'timeline');
  for I := 0 to Planning.Arrays['tasks'].Count - 1 do
    if Planning.Arrays['tasks'].Items[I] is TJSONObject then
    begin
      Task := Planning.Arrays['tasks'].Objects[I];
      EnsureArray(Task, 'files_affected');
      EnsureArray(Task, 'must_not_do');
      EnsureArray(Task, 'commits');
      EnsureArray(Task, 'exclusive_files');
      EnsureObject(Task, 'origin');
      if Task.IndexOfName('long_description') < 0 then
        Task.Add('long_description', '');
    end;
  EnsureArray(FProjectData, 'task_actions');
  EnsureArray(FProjectData, 'agent_task_analysis');
  EnsureArray(FProjectData, 'revisions');
  if FProjectData.IndexOfName('last_generated_json') < 0 then
    FProjectData.Add('last_generated_json', '');
  if FProjectData.IndexOfName('last_generated_markdown') < 0 then
    FProjectData.Add('last_generated_markdown', '');
end;

function TAIProject.LoadJSON(const AJSON: string): Boolean;
var
  Data: TJSONData;
begin
  Result := False;
  Data := nil;
  try
    Data := GetJSON(AJSON);
    if not (Data is TJSONObject) then Exit;
    FreeAndNil(FProjectData);
    FProjectData := TJSONObject(Data);
    Data := nil;
    EnsureStructure;
    Result := True;
  except
    Result := False;
  end;
  Data.Free;
end;

function TAIProject.AsJSON: string;
begin
  Result := FProjectData.FormatJSON;
end;

function TAIProject.GetProjectValue(AIndex: Integer): string;
const
  Names: array[0..6] of string = ('name', 'root', 'description', 'goal',
    'scope', 'constraints', 'expected_deliverables');
begin
  Result := FProjectData.Objects['project'].Get(Names[AIndex], '');
end;

procedure TAIProject.SetProjectValue(AIndex: Integer; const AValue: string);
const
  Names: array[0..6] of string = ('name', 'root', 'description', 'goal',
    'scope', 'constraints', 'expected_deliverables');
begin
  JSONSetString(FProjectData.Objects['project'], Names[AIndex], AValue);
end;

function TAIProject.AddRevision(const ATitle, AInput,
  AGeneratedJSON: string): Integer;
var
  Revisions: TJSONArray;
begin
  Revisions := FProjectData.Arrays['revisions'];
  Result := Revisions.Count + 1;
  Revisions.Add(TJSONObject.Create(['revision', Result, 'title', ATitle,
    'input', AInput, 'generated_json', AGeneratedJSON,
    'created_at', ISODateTimeNow]));
end;

constructor TAIProjectStorage.Create(AProject: TAIProject);
begin
  inherited Create;
  FProject := AProject;
end;

function TAIProjectStorage.LoadFromFile(const AFileName: string): Boolean;
var
  Stream: TFileStream;
  Text: string;
begin
  Result := False;
  FLastError := '';
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Text, Stream.Size);
      if Stream.Size > 0 then Stream.ReadBuffer(Text[1], Stream.Size);
    finally
      Stream.Free;
    end;
    Result := FProject.LoadJSON(Text);
    if not Result then FLastError := 'JSON de projeto inválido.';
  except
    on E: Exception do FLastError := E.Message;
  end;
end;

function TAIProjectStorage.SaveToFile(const AFileName: string): Boolean;
var
  Stream: TFileStream;
  Text, TempFile: string;
begin
  Result := False;
  FLastError := '';
  TempFile := AFileName + '.tmp';
  try
    if ExtractFileDir(AFileName) <> '' then ForceDirectories(ExtractFileDir(AFileName));
    JSONSetString(FProject.ProjectData, 'saved_at', ISODateTimeNow);
    Text := FProject.AsJSON;
    Stream := TFileStream.Create(TempFile, fmCreate);
    try
      if Text <> '' then Stream.WriteBuffer(Text[1], Length(Text));
    finally
      Stream.Free;
    end;
    if FileExists(AFileName) and (not DeleteFile(AFileName)) then
      raise Exception.Create('Não foi possível substituir o projeto.');
    if not RenameFile(TempFile, AFileName) then
      raise Exception.Create('Não foi possível concluir a gravação atômica.');
    Result := True;
  except
    on E: Exception do FLastError := E.Message;
  end;
  if FileExists(TempFile) then DeleteFile(TempFile);
end;

constructor TAIProjectTasks.Create(AProject: TAIProject);
begin
  inherited Create;
  FProject := AProject;
end;

function TAIProjectTasks.GetTasks: TJSONArray;
begin
  Result := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
end;

function TAIProjectTasks.GetCount: Integer;
begin
  Result := GetTasks.Count;
end;

function TAIProjectTasks.GetTaskByID(const ATaskID: string): TJSONObject;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Tasks.Count - 1 do
    if SameText(Tasks.Objects[I].Get('id', ''), ATaskID) then
      Exit(Tasks.Objects[I]);
end;

function TAIProjectTasks.AddTask(const ATitle, ADescription, APriority,
  AProfile, AAssignedTo: string; AEstimatedHours: Integer): string;
var
  Task: TJSONObject;
begin
  Result := 'T' + Format('%.3d', [Count + 1]);
  Task := TJSONObject.Create([
    'id', Result, 'epic_id', 'E001', 'title', ATitle,
    'description', ADescription, 'acceptance_criteria', '',
    'priority', APriority, 'status', 'draft', 'dependency_type', 'serial',
    'dependencies', TJSONArray.Create, 'can_run_in_parallel', False,
    'estimated_hours', TJSONObject.Create(['intern', AEstimatedHours * 2,
      'junior', AEstimatedHours, 'mid_level', AEstimatedHours,
      'senior', AEstimatedHours]),
    'suggested_skill_level', 'mid_level', 'assigned_skill_level', 'mid_level',
    'assigned_to', AAssignedTo, 'responsible_profile', AProfile,
    'estimated_duration_days', 1, 'deliverable', '', 'notes', '',
    'progress_percent', 0, 'revision_created', 1, 'revision_updated', 1,
    'long_description', '', 'files_affected', TJSONArray.Create,
    'must_not_do', TJSONArray.Create, 'commits', TJSONArray.Create,
    'exclusive_files', TJSONArray.Create, 'origin', TJSONObject.Create]);
  Tasks.Add(Task);
end;

function TAIProjectTasks.UpdateTask(const ATaskID, ATitle, ADescription,
  ALongDescription, APriority, AAssignedTo: string;
  AEstimatedHours: Integer): Boolean;
var
  Task, Hours: TJSONObject;
begin
  Task := GetTaskByID(ATaskID);
  Result := Task <> nil;
  if not Result then
  begin
    FLastError := 'Tarefa não encontrada: ' + ATaskID;
    Exit;
  end;
  JSONSetString(Task, 'title', ATitle);
  JSONSetString(Task, 'description', ADescription);
  JSONSetString(Task, 'long_description', ALongDescription);
  JSONSetString(Task, 'priority', APriority);
  JSONSetString(Task, 'assigned_to', AAssignedTo);
  if Task.Find('estimated_hours') is TJSONObject then
    Hours := Task.Objects['estimated_hours']
  else
  begin
    if Task.IndexOfName('estimated_hours') >= 0 then Task.Delete('estimated_hours');
    Hours := TJSONObject.Create;
    Task.Add('estimated_hours', Hours);
  end;
  JSONSetInteger(Hours, 'mid_level', AEstimatedHours);
  JSONSetInteger(Task, 'revision_updated', Task.Get('revision_updated', 0) + 1);
end;

function TAIProjectTasks.LinkCommit(const ATaskID, ACommit: string): Boolean;
var
  Task: TJSONObject;
  Commits: TJSONArray;
  I: Integer;
begin
  Result := False;
  Task := GetTaskByID(ATaskID);
  if Task = nil then
  begin
    FLastError := 'Tarefa não encontrada: ' + ATaskID;
    Exit;
  end;
  Commits := Task.Arrays['commits'];
  for I := 0 to Commits.Count - 1 do
    if SameText(Commits.Strings[I], ACommit) then Exit(True);
  Commits.Add(ACommit);
  Result := True;
end;

function TAIProjectTasks.HasExclusiveConflict(const ATaskID: string;
  out AConflictingTask, AFileName: string): Boolean;
var
  Task, Other: TJSONObject;
  Files, OtherFiles: TJSONArray;
  I, J, K: Integer;
begin
  Result := False;
  AConflictingTask := '';
  AFileName := '';
  Task := GetTaskByID(ATaskID);
  if (Task = nil) or not (Task.Find('exclusive_files') is TJSONArray) then Exit;
  Files := Task.Arrays['exclusive_files'];
  for I := 0 to Tasks.Count - 1 do
  begin
    Other := Tasks.Objects[I];
    if SameText(Other.Get('id', ''), ATaskID) or
      not SameText(Other.Get('status', ''), 'in_progress') or
      not (Other.Find('exclusive_files') is TJSONArray) then Continue;
    OtherFiles := Other.Arrays['exclusive_files'];
    for J := 0 to Files.Count - 1 do
      for K := 0 to OtherFiles.Count - 1 do
        if SameFileName(Files.Strings[J], OtherFiles.Strings[K]) then
        begin
          AConflictingTask := Other.Get('id', '');
          AFileName := Files.Strings[J];
          Exit(True);
        end;
  end;
end;

constructor TAITaskActions.Create(AProject: TAIProject;
  ATasks: TAIProjectTasks);
begin
  inherited Create;
  FProject := AProject;
  FTasks := ATasks;
end;

class function TAITaskActions.ActionName(
  AAction: TAIProjectTaskAction): string;
const
  Names: array[TAIProjectTaskAction] of string = ('confirm', 'reject', 'start',
    'finish', 'cancel', 'block', 'unblock', 'reopen', 'comment',
    'request_revision');
begin
  Result := Names[AAction];
end;

class function TAITaskActions.NewStatus(AAction: TAIProjectTaskAction;
  const AOldStatus: string): string;
begin
  Result := AOldStatus;
  case AAction of
    taConfirmTask: if SameText(AOldStatus, 'draft') then Result := 'confirmed';
    taRejectTask: Result := 'rejected';
    taStartTask: if SameText(AOldStatus, 'confirmed') or
      SameText(AOldStatus, 'reopened') then Result := 'in_progress';
    taFinishTask: if SameText(AOldStatus, 'in_progress') then Result := 'completed';
    taCancelTask: Result := 'canceled';
    taBlockTask: if not SameText(AOldStatus, 'completed') then Result := 'blocked';
    taUnblockTask: if SameText(AOldStatus, 'blocked') then Result := 'confirmed';
    taReopenTask: if SameText(AOldStatus, 'completed') or
      SameText(AOldStatus, 'rejected') or SameText(AOldStatus, 'canceled') then
      Result := 'reopened';
    taRequestRevision: Result := 'revision_requested';
  end;
end;

function TAITaskActions.ApplyAction(const ATaskID, AActor: string;
  AAction: TAIProjectTaskAction; const AComment: string): Boolean;
var
  Task: TJSONObject;
  OldStatus, Status, ConflictTask, ConflictFile: string;
  History: TJSONArray;
begin
  FLastError := '';
  Task := FTasks.GetTaskByID(ATaskID);
  Result := Task <> nil;
  if not Result then
  begin
    FLastError := 'Tarefa não encontrada: ' + ATaskID;
    Exit;
  end;
  OldStatus := Task.Get('status', 'draft');
  Status := NewStatus(AAction, OldStatus);
  if (AAction <> taCommentTask) and SameText(Status, OldStatus) then
  begin
    FLastError := 'Transição inválida: ' + OldStatus + ' -> ' + ActionName(AAction);
    Exit(False);
  end;
  if (AAction = taStartTask) and FTasks.HasExclusiveConflict(ATaskID,
    ConflictTask, ConflictFile) then
  begin
    FLastError := 'Conflito exclusivo com ' + ConflictTask + ': ' + ConflictFile;
    Exit(False);
  end;
  if AAction <> taCommentTask then JSONSetString(Task, 'status', Status);
  if AAction = taFinishTask then JSONSetInteger(Task, 'progress_percent', 100);
  History := FProject.ProjectData.Arrays['task_actions'];
  History.Add(TJSONObject.Create(['task_id', ATaskID,
    'action', ActionName(AAction), 'actor', AActor, 'comment', AComment,
    'previous_status', OldStatus, 'new_status', Status,
    'created_at', ISODateTimeNow]));
  Result := True;
end;

end.
