unit aiproject_statuspanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Graphics, aiproject, fpjson;

type
  { TAIProjectStatusPanel — shows task summary counts }
  TAIProjectStatusPanel = class(TPanel)
  private
    FProject: TAIProject;
    FLblTotal: TLabel;
    FLblDone: TLabel;
    FLblInProgress: TLabel;
    FLblBlocked: TLabel;
    FLblCanceled: TLabel;
    FLblDraft: TLabel;
    procedure SetProject(AValue: TAIProject);
    procedure BuildLabels;
  public
    constructor Create(AOwner: TComponent); override;

    { Refreshes the counts from project data. }
    procedure RefreshStatus;
  published
    property Project: TAIProject read FProject write SetProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectStatusPanel]);
end;

procedure TAIProjectStatusPanel.BuildLabels;
  function MakeLabel(const ACaption: string; ATop: Integer; AColor: TColor): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Self;
    Result.SetBounds(10, ATop, 160, 20);
    Result.Caption := ACaption;
    Result.Font.Color := AColor;
    Result.Font.Style := [fsBold];
  end;
begin
  Caption := '';
  BevelOuter := bvLowered;
  Width := 180;
  Height := 160;

  FLblTotal      := MakeLabel('Total:       0', 10,  clBlack);
  FLblDone       := MakeLabel('Done:        0', 35,  $006600);
  FLblInProgress := MakeLabel('In Progress: 0', 60,  $0055AA);
  FLblBlocked    := MakeLabel('Blocked:     0', 85,  $AA0000);
  FLblCanceled   := MakeLabel('Canceled:    0', 110, $666666);
  FLblDraft      := MakeLabel('Draft:       0', 135, $885500);
end;

constructor TAIProjectStatusPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BuildLabels;
end;

procedure TAIProjectStatusPanel.SetProject(AValue: TAIProject);
begin
  if FProject = AValue then Exit;
  FProject := AValue;
  RefreshStatus;
end;

procedure TAIProjectStatusPanel.RefreshStatus;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  i, Total, Done, InProg, Blocked, Canceled, Draft: Integer;
  S: string;
begin
  Total := 0; Done := 0; InProg := 0; Blocked := 0; Canceled := 0; Draft := 0;

  if Assigned(FProject) and Assigned(FProject.ProjectData) then
  begin
    Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
    if Assigned(Tasks) then
    begin
      Total := Tasks.Count;
      for i := 0 to Tasks.Count - 1 do
      begin
        Task := Tasks.Objects[i];
        S := Task.Strings['status'];
        if S = 'done' then Inc(Done)
        else if S = 'in_progress' then Inc(InProg)
        else if S = 'blocked' then Inc(Blocked)
        else if S = 'canceled' then Inc(Canceled)
        else Inc(Draft);
      end;
    end;
  end;

  FLblTotal.Caption      := 'Total:       ' + IntToStr(Total);
  FLblDone.Caption       := 'Done:        ' + IntToStr(Done);
  FLblInProgress.Caption := 'In Progress: ' + IntToStr(InProg);
  FLblBlocked.Caption    := 'Blocked:     ' + IntToStr(Blocked);
  FLblCanceled.Caption   := 'Canceled:    ' + IntToStr(Canceled);
  FLblDraft.Caption      := 'Draft:       ' + IntToStr(Draft);
end;

end.
