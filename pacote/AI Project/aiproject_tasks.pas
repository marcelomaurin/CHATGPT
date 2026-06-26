unit aiproject_tasks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, jsonparser, LResources;

type
  { TAIProjectTasks — manages task list, delegates to TAIProject }
  TAIProjectTasks = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    function GetTasks: TJSONArray;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;

    { Adds a new draft task. Returns the new task ID or empty on error. }
    function AddTask(const ATitle, ADescription, APriority,
                     AProfile, AAssignedTo: string;
                     AEstimatedHours: Integer): string;

    { Updates title/description/priority of an existing task by ID. }
    function UpdateTask(const ATaskID, ATitle, ADescription, APriority: string): Boolean;

    { Marks a task as 'canceled'. }
    function CancelTask(const ATaskID: string): Boolean;

    { Returns a TJSONObject for the given task ID, or nil. }
    function GetTaskByID(const ATaskID: string): TJSONObject;

    { Triggers schedule recalculation in the linked TAIProject. }
    function RecalculateEstimates: Boolean;

    { Long text property to store extended descriptions/specifications }
    function GetTaskLongDescription(const ATaskID: string): string;
    procedure SetTaskLongDescription(const ATaskID, AText: string);
    property TaskLongDescription[const ATaskID: string]: string read GetTaskLongDescription write SetTaskLongDescription;

    { Read-only access to the raw tasks JSON array. }
    property Tasks: TJSONArray read GetTasks;
    property Count: Integer read GetCount;
    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectTasks]);
end;

constructor TAIProjectTasks.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIProjectTasks.GetTasks: TJSONArray;
begin
  Result := nil;
  if Assigned(FProject) and Assigned(FProject.ProjectData) then
    Result := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
end;

function TAIProjectTasks.GetCount: Integer;
var
  Arr: TJSONArray;
begin
  Arr := GetTasks;
  if Assigned(Arr) then Result := Arr.Count else Result := 0;
end;

function TAIProjectTasks.AddTask(const ATitle, ADescription, APriority,
  AProfile, AAssignedTo: string; AEstimatedHours: Integer): string;
var
  Arr: TJSONArray;
  NewID: string;
begin
  Result := '';
  FLastError := '';
  Arr := GetTasks;
  if not Assigned(Arr) then
  begin
    FLastError := 'Task array not found. Generate initial plan first.';
    Exit;
  end;

  NewID := 'T' + Format('%.3d', [Arr.Count + 1]);

  Arr.Add(TJSONObject.Create([
    'id',                  NewID,
    'epic_id',             'E001',
    'title',               ATitle,
    'description',         ADescription,
    'acceptance_criteria', 'Defined by agent or user.',
    'priority',            APriority,
    'status',              'draft',
    'dependency_type',     'serial',
    'dependencies',        TJSONArray.Create,
    'can_run_in_parallel', false,
    'estimated_hours',     TJSONObject.Create(['mid_level', AEstimatedHours]),
    'suggested_skill_level', 'mid_level',
    'assigned_skill_level',  'mid_level',
    'assigned_to',           AAssignedTo,
    'responsible_profile',   AProfile,
    'estimated_duration_days', 1,
    'deliverable',           '',
    'notes',                 '',
    'progress_percent',      0,
    'revision_created',      1,
    'revision_updated',      1
  ]));

  FProject.RecalculateSchedule;
  Result := NewID;
end;

function TAIProjectTasks.UpdateTask(const ATaskID, ATitle, ADescription,
  APriority: string): Boolean;
var
  Task: TJSONObject;
begin
  Result := False;
  FLastError := '';
  Task := GetTaskByID(ATaskID);
  if not Assigned(Task) then
  begin
    FLastError := 'Task not found: ' + ATaskID;
    Exit;
  end;
  if ATitle <> '' then Task.Strings['title'] := ATitle;
  if ADescription <> '' then Task.Strings['description'] := ADescription;
  if APriority <> '' then Task.Strings['priority'] := APriority;
  Result := True;
end;

function TAIProjectTasks.CancelTask(const ATaskID: string): Boolean;
var
  Task: TJSONObject;
begin
  Result := False;
  FLastError := '';
  Task := GetTaskByID(ATaskID);
  if not Assigned(Task) then
  begin
    FLastError := 'Task not found: ' + ATaskID;
    Exit;
  end;
  Task.Strings['status'] := 'canceled';
  Result := True;
end;

function TAIProjectTasks.GetTaskByID(const ATaskID: string): TJSONObject;
var
  Arr: TJSONArray;
  i: Integer;
begin
  Result := nil;
  Arr := GetTasks;
  if not Assigned(Arr) then Exit;
  for i := 0 to Arr.Count - 1 do
    if Arr.Objects[i].Strings['id'] = ATaskID then
    begin
      Result := Arr.Objects[i];
      Exit;
    end;
end;

function TAIProjectTasks.GetTaskLongDescription(const ATaskID: string): string;
var
  Task: TJSONObject;
begin
  Result := '';
  Task := GetTaskByID(ATaskID);
  if Assigned(Task) then
    Result := Task.Get('long_description', Task.Get('description', '')); // fallback to description
end;

procedure TAIProjectTasks.SetTaskLongDescription(const ATaskID, AText: string);
var
  Task: TJSONObject;
  LIndex: Integer;
begin
  Task := GetTaskByID(ATaskID);
  if Assigned(Task) then
  begin
    LIndex := Task.IndexOfName('long_description');
    if LIndex >= 0 then
      Task.Delete(LIndex);
    Task.Add('long_description', AText);
  end;
end;

function TAIProjectTasks.RecalculateEstimates: Boolean;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked.';
    Exit;
  end;
  Result := FProject.RecalculateSchedule;
end;

initialization
  {$I taiprojecttasks_icon.lrs}

end.
