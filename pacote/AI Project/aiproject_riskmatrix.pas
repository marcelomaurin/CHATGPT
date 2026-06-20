unit aiproject_riskmatrix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Graphics, aiproject, fpjson;

type
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

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIRiskMatrix]);
end;

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
      if (i + j) >= 3 then
        Canvas.Brush.Color := TColor($D0D0FF)
      else if (i + j) >= 1 then
        Canvas.Brush.Color := TColor($D0FFFF)
      else
        Canvas.Brush.Color := TColor($D0FFD0);
        
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

end.
