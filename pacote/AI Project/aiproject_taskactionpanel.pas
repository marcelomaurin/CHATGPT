unit aiproject_taskactionpanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Dialogs, aiproject, fpjson, LResources;

// TAIProjectTaskAction is defined in aiproject.pas:
//   taConfirmTask, taRejectTask, taStartTask, taFinishTask, taCancelTask,
//   taBlockTask, taUnblockTask, taReopenTask, taCommentTask, taRequestRevision

type
  TOnActionApplied = procedure(const ATaskID, AAgentID, AAction: string) of object;

  { TAITaskActionPanel — frame for selecting task, agent, action and applying it }
  TAITaskActionPanel = class(TCustomControl)
  private
    FProject: TAIProject;
    FCbTask: TComboBox;
    FCbAgent: TComboBox;
    FCbAction: TComboBox;
    FMemoComment: TMemo;
    FEdtDeliverable: TEdit;
    FBtnApply: TButton;
    FMemoHistory: TMemo;
    FOnActionApplied: TOnActionApplied;

    procedure OnApplyClick(Sender: TObject);
    procedure BuildUI;
  public
    constructor Create(AOwner: TComponent); override;

    { Populates combo boxes from project data. }
    procedure LoadCombos;

    { Appends a line to the action history memo. }
    procedure AppendHistory(const ALine: string);
  published
    property Project: TAIProject read FProject write FProject;
    property OnActionApplied: TOnActionApplied read FOnActionApplied write FOnActionApplied;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAITaskActionPanel]);
end;

procedure TAITaskActionPanel.BuildUI;
var
  LblTask, LblAgent, LblAction, LblComment, LblDeliv: TLabel;
begin
  Width := 700;
  Height := 320;

  LblTask := TLabel.Create(Self);
  LblTask.Parent := Self;
  LblTask.SetBounds(10, 5, 120, 18);
  LblTask.Caption := 'Task:';

  FCbTask := TComboBox.Create(Self);
  FCbTask.Parent := Self;
  FCbTask.SetBounds(10, 23, 200, 25);
  FCbTask.TextHint := 'Select Task';
  FCbTask.Style := csDropDownList;

  LblAgent := TLabel.Create(Self);
  LblAgent.Parent := Self;
  LblAgent.SetBounds(10, 55, 120, 18);
  LblAgent.Caption := 'Agent:';

  FCbAgent := TComboBox.Create(Self);
  FCbAgent.Parent := Self;
  FCbAgent.SetBounds(10, 73, 200, 25);
  FCbAgent.TextHint := 'Select Agent';
  FCbAgent.Style := csDropDownList;

  LblAction := TLabel.Create(Self);
  LblAction.Parent := Self;
  LblAction.SetBounds(10, 105, 120, 18);
  LblAction.Caption := 'Action:';

  FCbAction := TComboBox.Create(Self);
  FCbAction.Parent := Self;
  FCbAction.SetBounds(10, 123, 200, 25);
  FCbAction.Style := csDropDownList;
  FCbAction.Items.Add('Confirm Task');
  FCbAction.Items.Add('Reject Task');
  FCbAction.Items.Add('Start Task');
  FCbAction.Items.Add('Finish Task');
  FCbAction.Items.Add('Cancel Task');
  FCbAction.Items.Add('Block Task');
  FCbAction.Items.Add('Unblock Task');
  FCbAction.Items.Add('Reopen Task');
  FCbAction.Items.Add('Comment Task');
  FCbAction.Items.Add('Request Revision');
  FCbAction.ItemIndex := 2;

  LblComment := TLabel.Create(Self);
  LblComment.Parent := Self;
  LblComment.SetBounds(10, 155, 120, 18);
  LblComment.Caption := 'Comment:';

  FMemoComment := TMemo.Create(Self);
  FMemoComment.Parent := Self;
  FMemoComment.SetBounds(10, 173, 200, 70);
  FMemoComment.TextHint := 'Action comment';

  LblDeliv := TLabel.Create(Self);
  LblDeliv.Parent := Self;
  LblDeliv.SetBounds(10, 250, 200, 18);
  LblDeliv.Caption := 'Deliverable (for Finish):';

  FEdtDeliverable := TEdit.Create(Self);
  FEdtDeliverable.Parent := Self;
  FEdtDeliverable.SetBounds(10, 268, 200, 25);
  FEdtDeliverable.TextHint := 'Deliverable file or URL';

  FBtnApply := TButton.Create(Self);
  FBtnApply.Parent := Self;
  FBtnApply.SetBounds(10, 298, 150, 28);
  FBtnApply.Caption := 'Apply Task Action';
  FBtnApply.OnClick := @OnApplyClick;

  FMemoHistory := TMemo.Create(Self);
  FMemoHistory.Parent := Self;
  FMemoHistory.SetBounds(225, 5, 465, 315);
  FMemoHistory.ReadOnly := True;
  FMemoHistory.ScrollBars := ssAutoBoth;
  FMemoHistory.TextHint := 'Action History';
end;

constructor TAITaskActionPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BuildUI;
end;

procedure TAITaskActionPanel.LoadCombos;
var
  Tasks, Agents: TJSONArray;
  i: Integer;
begin
  FCbTask.Clear;
  FCbAgent.Clear;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;

  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if Assigned(Tasks) then
    for i := 0 to Tasks.Count - 1 do
      FCbTask.Items.Add(Tasks.Objects[i].Strings['id'] + ': ' +
                        Tasks.Objects[i].Strings['title']);
  if FCbTask.Items.Count > 0 then FCbTask.ItemIndex := 0;

  Agents := TJSONArray(FProject.ProjectData.FindPath('agents'));
  if Assigned(Agents) then
    for i := 0 to Agents.Count - 1 do
      FCbAgent.Items.Add(Agents.Objects[i].Strings['name']);
  if FCbAgent.Items.Count > 0 then FCbAgent.ItemIndex := 0;
end;

procedure TAITaskActionPanel.AppendHistory(const ALine: string);
begin
  FMemoHistory.Lines.Add(ALine);
end;

procedure TAITaskActionPanel.OnApplyClick(Sender: TObject);
var
  TaskID, AgentName, ActionStr, Comm, Deliv: string;
  ActionIdx: Integer;
begin
  if not Assigned(FProject) then
  begin
    ShowMessage('No project linked.');
    Exit;
  end;

  if FCbTask.ItemIndex < 0 then
  begin
    ShowMessage('Please select a task.');
    Exit;
  end;

  // Extract task ID (format "T001: Title")
  TaskID := Copy(FCbTask.Text, 1, Pos(':', FCbTask.Text) - 1);
  AgentName := FCbAgent.Text;
  ActionIdx := FCbAction.ItemIndex;
  Comm := FMemoComment.Text;
  Deliv := FEdtDeliverable.Text;
  ActionStr := FCbAction.Text;

  if FProject.ApplyTaskAction(TaskID, AgentName,
     TAIProjectTaskAction(Ord(taConfirmTask) + ActionIdx), Comm, Deliv) then
  begin
    AppendHistory(DateTimeToStr(Now) + ' | ' + TaskID + ' | ' +
                  AgentName + ' | ' + ActionStr);
    if Assigned(FOnActionApplied) then
      FOnActionApplied(TaskID, AgentName, ActionStr);
  end
  else
    ShowMessage('Action failed: ' + FProject.LastError);
end;

initialization
  {$I taitaskactionpanel_icon.lrs}

end.
