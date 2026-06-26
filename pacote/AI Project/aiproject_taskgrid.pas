unit aiproject_taskgrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Grids, Graphics, aiproject, fpjson, LResources;

type
  { TAIProjectTaskGrid — TStringGrid pre-configured to display project tasks }
  TAIProjectTaskGrid = class(TStringGrid)
  private
    FProject: TAIProject;
    procedure SetProject(AValue: TAIProject);
    function StatusColor(const AStatus: string): TColor;
  public
    constructor Create(AOwner: TComponent); override;

    { Refreshes the grid from project data. }
    procedure LoadTasks;

    { Returns the task ID of the currently selected row, or empty string. }
    function SelectedTaskID: string;
  published
    property Project: TAIProject read FProject write SetProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectTaskGrid]);
end;

constructor TAIProjectTaskGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ColCount := 7;
  RowCount := 2;
  FixedRows := 1;
  FixedCols := 0;
  Options := Options + [goColSizing, goRowHighlight];

  Cells[0, 0] := 'ID';
  Cells[1, 0] := 'Task Title';
  Cells[2, 0] := 'Status';
  Cells[3, 0] := 'Priority';
  Cells[4, 0] := 'Start';
  Cells[5, 0] := 'End';
  Cells[6, 0] := 'Progress';

  ColWidths[0] := 55;
  ColWidths[1] := 180;
  ColWidths[2] := 80;
  ColWidths[3] := 65;
  ColWidths[4] := 80;
  ColWidths[5] := 80;
  ColWidths[6] := 65;
end;

procedure TAIProjectTaskGrid.SetProject(AValue: TAIProject);
begin
  if FProject = AValue then Exit;
  FProject := AValue;
  LoadTasks;
end;

function TAIProjectTaskGrid.StatusColor(const AStatus: string): TColor;
begin
  if AStatus = 'done' then           Result := $C0FFC0
  else if AStatus = 'in_progress' then Result := $C0DFFF
  else if AStatus = 'blocked' then   Result := $FFC0C0
  else if AStatus = 'canceled' then  Result := $D0D0D0
  else if AStatus = 'confirmed' then Result := $FFFFC0
  else                               Result := clWhite;
end;

procedure TAIProjectTaskGrid.LoadTasks;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  i: Integer;
  StatusStr: string;
begin
  RowCount := 1;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) or (Tasks.Count = 0) then Exit;

  RowCount := Tasks.Count + 1;
  for i := 0 to Tasks.Count - 1 do
  begin
    Task := Tasks.Objects[i];
    StatusStr := Task.Strings['status'];
    Cells[0, i + 1] := Task.Strings['id'];
    Cells[1, i + 1] := Task.Strings['title'];
    Cells[2, i + 1] := StatusStr;
    Cells[3, i + 1] := Task.Strings['priority'];
    Cells[4, i + 1] := Task.Strings['planned_start_date'];
    Cells[5, i + 1] := Task.Strings['planned_end_date'];
    Cells[6, i + 1] := IntToStr(Task.Integers['progress_percent']) + '%';

    // Color entire row by status
    RowHeights[i + 1] := 20;
  end;
end;

function TAIProjectTaskGrid.SelectedTaskID: string;
begin
  Result := '';
  if (Row > 0) and (Row < RowCount) then
    Result := Cells[0, Row];
end;

initialization
  {$I taiprojecttaskgrid_icon.lrs}

end.
