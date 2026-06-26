unit aiproject_gantt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Graphics, aiproject, fpjson, LResources;

type
  TAIProjectGantt = class(TPaintBox)
  private
    FProject: TAIProject;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectGantt]);
end;

constructor TAIProjectGantt.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 400;
  Height := 150;
end;

procedure TAIProjectGantt.Paint;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  i, Y, BarX, BarW, ProgressW: Integer;
  TaskID, Title, Status: string;
  Progress: Integer;
begin
  inherited Paint;
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);
  
  Canvas.Pen.Color := clLtGray;
  Canvas.MoveTo(100, 0);
  Canvas.LineTo(100, Height);
  
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then
  begin
    Canvas.TextOut(10, 10, 'No project linked.');
    Exit;
  end;
  
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) or (Tasks.Count = 0) then
  begin
    Canvas.TextOut(10, 10, 'No tasks to display in Gantt.');
    Exit;
  end;
  
  Canvas.Font.Size := 8;
  for i := 0 to Tasks.Count - 1 do
  begin
    if i * 24 + 30 > Height then Break;
    Task := Tasks.Objects[i];
    TaskID := Task.Strings['id'];
    Title := Task.Strings['title'];
    Status := Task.Strings['status'];
    Progress := Task.Integers['progress_percent'];
    
    Y := i * 24 + 10;
    
    // Draw Text
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := clBlack;
    Canvas.TextOut(5, Y, TaskID + ': ' + Copy(Title, 1, 12));
    
    // Bar dimensions
    BarX := 120 + i * 25;
    BarW := 80;
    
    // Draw Bar Background
    if Status = 'done' then
      Canvas.Brush.Color := TColor($D0FFD0)
    else if Status = 'in_progress' then
      Canvas.Brush.Color := TColor($FFD0D0)
    else if Status = 'blocked' then
      Canvas.Brush.Color := TColor($D0D0D0)
    else
      Canvas.Brush.Color := TColor($E0E0E0);
      
    Canvas.Brush.Style := bsSolid;
    Canvas.Rectangle(BarX, Y, BarX + BarW, Y + 15);
    
    // Draw Progress fill
    if Progress > 0 then
    begin
      ProgressW := (BarW * Progress) div 100;
      Canvas.Brush.Color := clGreen;
      Canvas.Rectangle(BarX, Y, BarX + ProgressW, Y + 15);
    end;
  end;
end;

initialization
  {$I taiprojectgantt_icon.lrs}

end.
