unit aiproject_actions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, LResources;

// TAIProjectTaskAction is defined in aiproject.pas:
//   taConfirmTask, taRejectTask, taStartTask, taFinishTask, taCancelTask,
//   taBlockTask, taUnblockTask, taReopenTask, taCommentTask, taRequestRevision

type
  { TAITaskActions — applies lifecycle actions to tasks, records full history }
  TAITaskActions = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    function GetHistory: TJSONArray;
  public
    constructor Create(AOwner: TComponent); override;

    { Applies an action to a task. Records: task_id, agent_id, action,
      old_status, new_status, date, comment, revision. }
    function ApplyAction(const ATaskID, AAgentID: string;
                         AAction: TAIProjectTaskAction;
                         const AComment, ADeliverable: string): Boolean;

    { Returns the action history JSON array. }
    property History: TJSONArray read GetHistory;
    property LastError: string read FLastError;

    { Human-readable name for a task action. }
    class function ActionName(AAction: TAIProjectTaskAction): string;

    { Maps index (from ComboBox) to action enum. }
    class function ActionFromIndex(AIndex: Integer): TAIProjectTaskAction;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAITaskActions]);
end;

constructor TAITaskActions.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

class function TAITaskActions.ActionName(AAction: TAIProjectTaskAction): string;
begin
  case AAction of
    taConfirmTask:        Result := 'Confirm Task';
    taRejectTask:         Result := 'Reject Task';
    taStartTask:          Result := 'Start Task';
    taFinishTask:         Result := 'Finish Task';
    taCancelTask:         Result := 'Cancel Task';
    taBlockTask:          Result := 'Block Task';
    taUnblockTask:        Result := 'Unblock Task';
    taReopenTask:         Result := 'Reopen Task';
    taCommentTask:        Result := 'Comment Task';
    taRequestRevision:    Result := 'Request Revision';
  else
    Result := 'Unknown';
  end;
end;

class function TAITaskActions.ActionFromIndex(AIndex: Integer): TAIProjectTaskAction;
begin
  if (AIndex >= Ord(taConfirmTask)) and (AIndex <= Ord(taRequestRevision)) then
    Result := TAIProjectTaskAction(AIndex)
  else
    Result := taCommentTask;
end;

function TAITaskActions.GetHistory: TJSONArray;
begin
  Result := nil;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Result := TJSONArray(FProject.ProjectData.FindPath('task_action_history'));
end;

function TAITaskActions.ApplyAction(const ATaskID, AAgentID: string;
  AAction: TAIProjectTaskAction; const AComment, ADeliverable: string): Boolean;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked.';
    Exit;
  end;
  { Delegate to TAIProject.ApplyTaskAction which handles status transitions
    and history recording. }
  Result := FProject.ApplyTaskAction(ATaskID, AAgentID, AAction, AComment, ADeliverable);
  if not Result then
    FLastError := FProject.LastError;
end;

initialization
  {$I taittaskactions_icon.lrs}

end.
