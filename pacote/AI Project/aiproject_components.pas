unit aiproject_components;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Grids, ExtCtrls, StdCtrls, Graphics, Dialogs, aiproject, fpjson, jsonparser;

type
  { Non-visual Wrapper Components }

  TAIProjectLLMConfig = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectDescription = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIFunctionalRequirements = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAINonFunctionalRequirements = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIBusinessVision = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIStakeholders = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIRiskMap = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectTasks = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectDependencies = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectRevisions = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectAgents = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAITaskActions = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectReports = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIAgileDocuments = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  TAIProjectStorage = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;


  { Visual Custom Components }

  TAIProjectLLMConfigFrame = class(TFrame)
  end;

  TAIProjectDescriptionFrame = class(TFrame)
  end;

  TAIBusinessVisionEditor = class(TFrame)
  end;

  TAIProjectReportViewer = class(TFrame)
  end;

  TAIAgileDocumentsViewer = class(TFrame)
  end;

  TAIProjectStatusPanel = class(TPanel)
  end;

  TAIRevisionViewer = class(TFrame)
  end;

  TAIAgentManagerFrame = class(TFrame)
  end;

  TAITaskActionPanel = class(TPanel)
  end;

  TAIDependencyViewer = class(TFrame)
  end;

  // Grids
  TAIFunctionalRequirementsGrid = class(TStringGrid)
  end;

  TAINonFunctionalRequirementsGrid = class(TStringGrid)
  end;

  TAIStakeholderGrid = class(TStringGrid)
  end;

  TAIRiskMapGrid = class(TStringGrid)
  end;

  TAIProjectTaskGrid = class(TStringGrid)
  end;

  // Risk Matrix
  TAIRiskMatrix = class(TPaintBox)
  private
    FProject: TAIProject;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Project: TAIProject read FProject write FProject;
  end;

  // Gantt Chart
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

  // Timeline Event Viewer
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
  RegisterComponents('AI Project', [
    TAIProjectLLMConfig,
    TAIProjectDescription,
    TAIFunctionalRequirements,
    TAINonFunctionalRequirements,
    TAIBusinessVision,
    TAIStakeholders,
    TAIRiskMap,
    TAIProjectTasks,
    TAIProjectDependencies,
    TAIProjectRevisions,
    TAIProjectAgents,
    TAITaskActions,
    TAIProjectReports,
    TAIAgileDocuments,
    TAIProjectStorage,
    TAIRiskMatrix,
    TAIProjectGantt,
    TAIProjectTimeline
  ]);
end;

{ TAIRiskMatrix }

constructor TAIRiskMatrix.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 200;
end;

procedure TAIRiskMatrix.Paint;
var
  W, H, CellW, CellH, i, j: Integer;
  Risks: TJSONArray;
  Risk: TJSONObject;
  ImpactStr, ProbStr: string;
  XIdx, YIdx: Integer;
begin
  inherited Paint;
  W := Width;
  H := Height;
  CellW := W div 3;
  CellH := H div 3;
  
  Canvas.Pen.Color := clGray;
  Canvas.Pen.Style := psSolid;
  
  // Fill matrix quadrants
  for i := 0 to 2 do
  begin
    for j := 0 to 2 do
    begin
      // Color coding for Heat Map
      if (i + j) >= 3 then
        Canvas.Brush.Color := TColor($D0D0FF) // Reddish/Coral for High Risk
      else if (i + j) >= 1 then
        Canvas.Brush.Color := TColor($D0FFFF) // Yellowish for Medium Risk
      else
        Canvas.Brush.Color := TColor($D0FFD0); // Greenish for Low Risk
        
      Canvas.Rectangle(i * CellW, (2 - j) * CellH, (i + 1) * CellW, (3 - j) * CellH);
    end;
  end;
  
  // Draw risk dots
  if Assigned(FProject) and Assigned(FProject.ProjectData) then
  begin
    Risks := TJSONArray(FProject.ProjectData.FindPath('agile_documents.risk_map'));
    if Assigned(Risks) then
    begin
      Canvas.Brush.Color := clRed;
      for i := 0 to Risks.Count - 1 do
      begin
        Risk := Risks.Objects[i];
        ImpactStr := LowerCase(Risk.Strings['impact']);
        ProbStr := LowerCase(Risk.Strings['probability']);
        
        if ImpactStr = 'high' then XIdx := 2
        else if ImpactStr = 'medium' then XIdx := 1
        else XIdx := 0;
        
        if ProbStr = 'high' then YIdx := 2
        else if ProbStr = 'medium' then YIdx := 1
        else YIdx := 0;
        
        Canvas.Ellipse(
          XIdx * CellW + CellW div 2 - 6,
          (2 - YIdx) * CellH + CellH div 2 - 6,
          XIdx * CellW + CellW div 2 + 6,
          (2 - YIdx) * CellH + CellH div 2 + 6
        );
        Canvas.TextOut(XIdx * CellW + CellW div 2 + 8, (2 - YIdx) * CellH + CellH div 2 - 6, Risk.Strings['id']);
      end;
    end;
  end;
end;

{ TAIProjectGantt }

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
    BarX := 120 + i * 25; // Simple successive spacing for visualization
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

{ TAIProjectTimeline }

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
