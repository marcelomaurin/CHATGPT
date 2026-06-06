unit aigridrenderer2d;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, aibase, aigridworld, aigridcell, aisimentity;

type
  { TAIGridRenderer2D }

  TAIGridRenderer2D = class(TAIBaseComponent)
  private
    FGridWorld: TAIGridWorld;
    FEmptyColor: TColor;
    FBlockedColor: TColor;
    FGridLineColor: TColor;
    FShowGridLines: Boolean;
    FCellSize: Integer;
    FTypeColors: TStringList;
    
    procedure SetTypeColors(AValue: TStringList);
    function GetColorForType(const AType: string): TColor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure RenderToCanvas(ACanvas: TCanvas; const ARect: TRect);
    function ExportToBitmap: TBitmap;
  published
    property GridWorld: TAIGridWorld read FGridWorld write FGridWorld;
    property EmptyColor: TColor read FEmptyColor write FEmptyColor default clWhite;
    property BlockedColor: TColor read FBlockedColor write FBlockedColor default clGray;
    property GridLineColor: TColor read FGridLineColor write FGridLineColor default clSilver;
    property ShowGridLines: Boolean read FShowGridLines write FShowGridLines default True;
    property CellSize: Integer read FCellSize write FCellSize default 32;
    property TypeColors: TStringList read FTypeColors write SetTypeColors;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIGridRenderer2D]);
end;

{ TAIGridRenderer2D }

constructor TAIGridRenderer2D.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIGridRenderer2D renders cell terrain and entity overlays onto a TCanvas component.';
  
  FEmptyColor := clWhite;
  FBlockedColor := clGray;
  FGridLineColor := clSilver;
  FShowGridLines := True;
  FCellSize := 32;
  FTypeColors := TStringList.Create;
  
  // Set some default colors
  FTypeColors.Values['robot'] := '$00FF0000'; // Blue in BGR
  FTypeColors.Values['charging_station'] := '$0000FF00'; // Green in BGR
  FTypeColors.Values['obstacle'] := '$00808080';
  FTypeColors.Values['agent'] := '$000000FF'; // Red
end;

destructor TAIGridRenderer2D.Destroy;
begin
  FTypeColors.Free;
  inherited Destroy;
end;

procedure TAIGridRenderer2D.SetTypeColors(AValue: TStringList);
begin
  FTypeColors.Assign(AValue);
end;

function TAIGridRenderer2D.GetColorForType(const AType: string): TColor;
var
  LStr: string;
  LVal: Integer;
begin
  Result := clBlue; // Default entity color
  LStr := FTypeColors.Values[AType];
  if LStr <> '' then
  begin
    if TryStrToInt(LStr, LVal) then
      Result := TColor(LVal);
  end;
end;

procedure TAIGridRenderer2D.RenderToCanvas(ACanvas: TCanvas; const ARect: TRect);
var
  X, Y: Integer;
  LCell: TAIGridCell;
  LCellRect: TRect;
  LColor: TColor;
  LWorldWidth, LWorldHeight: Integer;
  LEntity: TAISimEntity;
begin
  if not Assigned(ACanvas) or not Assigned(FGridWorld) then Exit;
  
  LWorldWidth := FGridWorld.Width;
  LWorldHeight := FGridWorld.Height;
  
  ACanvas.Brush.Color := FEmptyColor;
  ACanvas.FillRect(ARect);
  
  for X := 0 to LWorldWidth - 1 do
  begin
    for Y := 0 to LWorldHeight - 1 do
    begin
      LCell := FGridWorld.Cells[X, Y];
      if not Assigned(LCell) then Continue;
      
      LCellRect.Left := ARect.Left + (X * FCellSize);
      LCellRect.Top := ARect.Top + (Y * FCellSize);
      LCellRect.Right := LCellRect.Left + FCellSize;
      LCellRect.Bottom := LCellRect.Top + FCellSize;
      
      // Check if within bounds of target rectangle
      if (LCellRect.Left >= ARect.Right) or (LCellRect.Top >= ARect.Bottom) then Continue;
      
      if LCell.Blocked then
      begin
        ACanvas.Brush.Color := FBlockedColor;
        ACanvas.FillRect(LCellRect);
      end
      else
      begin
        // Draw terrain type custom colors if any
        if SameText(LCell.TerrainType, 'default') then
          ACanvas.Brush.Color := FEmptyColor
        else if SameText(LCell.TerrainType, 'wall') then
          ACanvas.Brush.Color := clBlack
        else
          ACanvas.Brush.Color := FEmptyColor;
          
        ACanvas.FillRect(LCellRect);
      end;
      
      // Draw grid lines
      if FShowGridLines then
      begin
        ACanvas.Pen.Color := FGridLineColor;
        ACanvas.Frame(LCellRect);
      end;
      
      // Draw Entity
      if Assigned(LCell.Entity) then
      begin
        LEntity := LCell.Entity;
        LColor := GetColorForType(LEntity.EntityType);
        
        ACanvas.Brush.Color := LColor;
        ACanvas.Pen.Color := clBlack;
        
        // Draw a simple circle representing the entity
        ACanvas.Ellipse(
          LCellRect.Left + 4,
          LCellRect.Top + 4,
          LCellRect.Right - 4,
          LCellRect.Bottom - 4
        );
        
        // Draw first character of type name or name inside circle for visual cues
        if LEntity.EntityType <> '' then
        begin
          ACanvas.Brush.Style := bsClear;
          ACanvas.Font.Color := clWhite;
          ACanvas.Font.Size := FCellSize div 3;
          ACanvas.TextOut(
            LCellRect.Left + (FCellSize div 3),
            LCellRect.Top + (FCellSize div 4),
            Copy(LEntity.EntityType, 1, 1)
          );
          ACanvas.Brush.Style := bsSolid;
        end;
      end;
    end;
  end;
end;

function TAIGridRenderer2D.ExportToBitmap: TBitmap;
var
  LWidth, LHeight: Integer;
  LRect: TRect;
begin
  Result := TBitmap.Create;
  if not Assigned(FGridWorld) then Exit;
  
  LWidth := FGridWorld.Width * FCellSize;
  LHeight := FGridWorld.Height * FCellSize;
  
  Result.Width := LWidth;
  Result.Height := LHeight;
  
  LRect := Rect(0, 0, LWidth, LHeight);
  RenderToCanvas(Result.Canvas, LRect);
end;

end.
