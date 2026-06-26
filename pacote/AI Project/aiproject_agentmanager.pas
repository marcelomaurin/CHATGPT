unit aiproject_agentmanager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, ComCtrls, aiproject, fpjson, LResources;

type
  { TAIAgentManagerFrame — frame with agent list + edit panel }
  TAIAgentManagerFrame = class(TCustomControl)
  private
    FProject: TAIProject;
    FListBox: TListBox;
    FPanel: TPanel;
    FEdtName: TEdit;
    FCbProfile: TComboBox;
    FCbSkill: TComboBox;
    FMemoDesc: TMemo;
    FChkActive: TCheckBox;
    FBtnAdd: TButton;
    FBtnUpdate: TButton;
    FBtnRemove: TButton;

    procedure SetProject(AValue: TAIProject);
    procedure OnListClick(Sender: TObject);
    procedure OnAddClick(Sender: TObject);
    procedure OnUpdateClick(Sender: TObject);
    procedure OnRemoveClick(Sender: TObject);
    procedure BuildUI;
  public
    constructor Create(AOwner: TComponent); override;

    { Refreshes the agent list from project data. }
    procedure LoadAgents;

    { Returns the selected agent JSON or nil. }
    function SelectedAgent: TJSONObject;
  published
    property Project: TAIProject read FProject write SetProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIAgentManagerFrame]);
end;

procedure TAIAgentManagerFrame.BuildUI;
begin
  FListBox := TListBox.Create(Self);
  FListBox.Parent := Self;
  FListBox.SetBounds(0, 0, 160, 260);
  FListBox.OnClick := @OnListClick;

  FPanel := TPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.SetBounds(170, 0, 300, 260);
  FPanel.BevelOuter := bvNone;

  FEdtName := TEdit.Create(Self);
  FEdtName.Parent := FPanel;
  FEdtName.SetBounds(0, 0, 280, 25);
  FEdtName.TextHint := 'Agent Name';

  FCbProfile := TComboBox.Create(Self);
  FCbProfile.Parent := FPanel;
  FCbProfile.SetBounds(0, 30, 280, 25);
  FCbProfile.Items.CommaText :=
    'UI,DBA,DEV,Infra,Operador,Key User,Tester,Documentador,Gerente';
  FCbProfile.ItemIndex := 2;

  FCbSkill := TComboBox.Create(Self);
  FCbSkill.Parent := FPanel;
  FCbSkill.SetBounds(0, 60, 280, 25);
  FCbSkill.Items.CommaText := 'intern,junior,mid_level,senior';
  FCbSkill.ItemIndex := 3;

  FMemoDesc := TMemo.Create(Self);
  FMemoDesc.Parent := FPanel;
  FMemoDesc.SetBounds(0, 90, 280, 80);
  FMemoDesc.TextHint := 'Agent Description';

  FChkActive := TCheckBox.Create(Self);
  FChkActive.Parent := FPanel;
  FChkActive.SetBounds(0, 175, 150, 25);
  FChkActive.Caption := 'Active';
  FChkActive.Checked := True;

  FBtnAdd := TButton.Create(Self);
  FBtnAdd.Parent := FPanel;
  FBtnAdd.SetBounds(0, 205, 85, 28);
  FBtnAdd.Caption := 'Add';
  FBtnAdd.OnClick := @OnAddClick;

  FBtnUpdate := TButton.Create(Self);
  FBtnUpdate.Parent := FPanel;
  FBtnUpdate.SetBounds(90, 205, 85, 28);
  FBtnUpdate.Caption := 'Update';
  FBtnUpdate.OnClick := @OnUpdateClick;

  FBtnRemove := TButton.Create(Self);
  FBtnRemove.Parent := FPanel;
  FBtnRemove.SetBounds(180, 205, 85, 28);
  FBtnRemove.Caption := 'Remove';
  FBtnRemove.OnClick := @OnRemoveClick;

  Width := 480;
  Height := 265;
end;

constructor TAIAgentManagerFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BuildUI;
end;

procedure TAIAgentManagerFrame.SetProject(AValue: TAIProject);
begin
  if FProject = AValue then Exit;
  FProject := AValue;
  LoadAgents;
end;

procedure TAIAgentManagerFrame.LoadAgents;
var
  Agents: TJSONArray;
  i: Integer;
begin
  FListBox.Clear;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Agents := TJSONArray(FProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  for i := 0 to Agents.Count - 1 do
    FListBox.Items.Add(
      Agents.Objects[i].Strings['name'] + ' (' +
      Agents.Objects[i].Strings['profile'] + ')');
end;

function TAIAgentManagerFrame.SelectedAgent: TJSONObject;
var
  Agents: TJSONArray;
  Idx: Integer;
begin
  Result := nil;
  Idx := FListBox.ItemIndex;
  if Idx < 0 then Exit;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Agents := TJSONArray(FProject.ProjectData.FindPath('agents'));
  if Assigned(Agents) and (Idx < Agents.Count) then
    Result := Agents.Objects[Idx];
end;

procedure TAIAgentManagerFrame.OnListClick(Sender: TObject);
var
  Agent: TJSONObject;
begin
  Agent := SelectedAgent;
  if not Assigned(Agent) then Exit;
  FEdtName.Text := Agent.Strings['name'];
  FCbProfile.ItemIndex := FCbProfile.Items.IndexOf(Agent.Strings['profile']);
  FCbSkill.ItemIndex := FCbSkill.Items.IndexOf(Agent.Strings['skill_level']);
  FMemoDesc.Text := Agent.Strings['description'];
  FChkActive.Checked := Agent.Booleans['active'];
end;

procedure TAIAgentManagerFrame.OnAddClick(Sender: TObject);
var
  Agents: TJSONArray;
  NewID: string;
begin
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Agents := TJSONArray(FProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  NewID := 'AG' + Format('%.3d', [Agents.Count + 1]);
  Agents.Add(TJSONObject.Create([
    'id', NewID,
    'name', FEdtName.Text,
    'profile', FCbProfile.Text,
    'description', FMemoDesc.Text,
    'skill_level', FCbSkill.Text,
    'active', FChkActive.Checked
  ]));
  LoadAgents;
end;

procedure TAIAgentManagerFrame.OnUpdateClick(Sender: TObject);
var
  Agent: TJSONObject;
begin
  Agent := SelectedAgent;
  if not Assigned(Agent) then Exit;
  Agent.Strings['name'] := FEdtName.Text;
  Agent.Strings['profile'] := FCbProfile.Text;
  Agent.Strings['description'] := FMemoDesc.Text;
  Agent.Strings['skill_level'] := FCbSkill.Text;
  Agent.Booleans['active'] := FChkActive.Checked;
  LoadAgents;
end;

procedure TAIAgentManagerFrame.OnRemoveClick(Sender: TObject);
var
  Agents: TJSONArray;
  Idx: Integer;
begin
  Idx := FListBox.ItemIndex;
  if Idx < 0 then Exit;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Agents := TJSONArray(FProject.ProjectData.FindPath('agents'));
  if Assigned(Agents) and (Idx < Agents.Count) then
  begin
    Agents.Delete(Idx);
    LoadAgents;
  end;
end;

initialization
  {$I taiagentmanagerframe_icon.lrs}

end.
