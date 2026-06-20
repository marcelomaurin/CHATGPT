unit aiproject_timeline;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Graphics, aiproject, fpjson;

type
  TAIProjectTimeline = class(TPaintBox)
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
  RegisterComponents('AI Project', [TAIProjectTimeline]);
end;

constructor TAIProjectTimeline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 400;
  Height := 150;
end;

procedure TAIProjectTimeline.Paint;
var
  Timeline: TJSONArray;
  Ev: TJSONObject;
  i, Y: Integer;
  DateStr, TitleStr: string;
begin
  inherited Paint;
  Canvas.Brush.Color := TColor($F9F9F9);
  Canvas.FillRect(ClientRect);
  
  // Center line
  Canvas.Pen.Color := clSilver;
  Canvas.Pen.Width := 2;
  Canvas.MoveTo(80, 0);
  Canvas.LineTo(80, Height);
  
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then
  begin
    Canvas.TextOut(10, 10, 'No project linked.');
    Exit;
  end;
  
  Timeline := TJSONArray(FProject.ProjectData.FindPath('planning.timeline'));
  if not Assigned(Timeline) or (Timeline.Count = 0) then
  begin
    Canvas.TextOut(10, 10, 'No timeline events.');
    Exit;
  end;
  
  Canvas.Font.Size := 8;
  for i := 0 to Timeline.Count - 1 do
  begin
    if i * 30 + 30 > Height then Break;
    Ev := Timeline.Objects[i];
    DateStr := Ev.Strings['date'];
    TitleStr := Ev.Strings['title'];
    
    Y := i * 30 + 15;
    
    // Draw bubble
    Canvas.Brush.Color := clBlue;
    Canvas.Ellipse(76, Y - 4, 84, Y + 4);
    
    // Date on left
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := clGray;
    Canvas.TextOut(10, Y - 6, DateStr);
    
    // Title on right
    Canvas.Font.Color := clBlack;
    Canvas.TextOut(95, Y - 6, TitleStr);
  end;
end;

end.
