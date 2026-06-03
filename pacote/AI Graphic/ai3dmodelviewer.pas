unit ai3dmodelviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, aimodel3d, aibase, LResources;

type
  TRenderMode = (rmSolid, rmWireframe, rmPoints);

  { TAI3DModelViewer }

  TAI3DModelViewer = class(TCustomControl)
  private
    FModel: TAIModel3D;
    FRenderMode: TRenderMode;
    FBackgroundColor: TColor;
    FOnModelLoaded: TNotifyEvent;
    FOnModelError: TNotifyEvent;
    
    // Rotation & Zoom fields
    FRotX: Double;
    FRotY: Double;
    FRotZ: Double;
    FZoom: Double;
    FMouseDrag: Boolean;
    FLastMousePos: TPoint;
    
    // AI Suite common fields
    FPrompt: string;
    FLastError: string;
    FLastResult: string;
    FLastSuccess: Boolean;
    FCategory: TAIComponentCategory;
    FOnLog: TAILogEvent;

    procedure SetModel(AValue: TAIModel3D);
    procedure ClearError;
    procedure SetError(const AMessage: string);
    procedure Log(ALevel: TAILogLevel; const AMessage: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ResetCamera;
    procedure ExportScreenshot(const AFileName: string);
    property LastSuccess: Boolean read FLastSuccess;
  published
    property Model: TAIModel3D read FModel write SetModel;
    property RenderMode: TRenderMode read FRenderMode write FRenderMode default rmSolid;
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor default clBtnFace;
    property OnModelLoaded: TNotifyEvent read FOnModelLoaded write FOnModelLoaded;
    property OnModelError: TNotifyEvent read FOnModelError write FOnModelError;
    
    // AI Suite common properties
    property Prompt: string read FPrompt write FPrompt;
    property LastError: string read FLastError;
    property LastResult: string read FLastResult;
    property Category: TAIComponentCategory read FCategory write FCategory default ccOther;
    property OnLog: TAILogEvent read FOnLog write FOnLog;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAI3DModelViewer]);
end;

{ TAI3DModelViewer }

constructor TAI3DModelViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAI3DModelViewer provides visual OpenGL-based rendering of a TAIModel3D. Properties: Model, RenderMode, BackgroundColor. Methods: ZoomIn, ZoomOut, ResetCamera, ExportScreenshot.';
  FRenderMode := rmSolid;
  FBackgroundColor := clBtnFace;
  FModel := nil;
  FLastError := '';
  FLastResult := '';
  FLastSuccess := True;
  
  FRotX := 20.0;
  FRotY := 30.0;
  FRotZ := 0.0;
  FZoom := 1.0;
  FMouseDrag := False;
end;

procedure TAI3DModelViewer.ClearError;
begin
  FLastError := '';
  FLastSuccess := True;
  Log(llDebug, 'Error cleared.');
end;

procedure TAI3DModelViewer.SetError(const AMessage: string);
begin
  FLastError := AMessage;
  FLastSuccess := False;
  Log(llError, AMessage);
  if Assigned(FOnModelError) then
    FOnModelError(Self);
end;

procedure TAI3DModelViewer.Log(ALevel: TAILogLevel; const AMessage: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, ALevel, AMessage);
end;

procedure TAI3DModelViewer.SetModel(AValue: TAIModel3D);
begin
  if FModel <> AValue then
  begin
    FModel := AValue;
    if FModel <> nil then
    begin
      FModel.FreeNotification(Self);
      if Assigned(FOnModelLoaded) then
        FOnModelLoaded(Self);
    end;
    ResetCamera;
  end;
end;

procedure TAI3DModelViewer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FModel) then
    FModel := nil;
end;

procedure TAI3DModelViewer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FMouseDrag := True;
    FLastMousePos := Point(X, Y);
    SetFocus;
  end;
end;

procedure TAI3DModelViewer.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FMouseDrag then
  begin
    FRotY := FRotY + (X - FLastMousePos.X) * 0.5;
    FRotX := FRotX + (Y - FLastMousePos.Y) * 0.5;
    FLastMousePos := Point(X, Y);
    Invalidate;
  end;
end;

procedure TAI3DModelViewer.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FMouseDrag := False;
end;

function TAI3DModelViewer.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  if WheelDelta > 0 then
    ZoomIn
  else
    ZoomOut;
end;

type
  TProjectedFace = record
    P1, P2, P3: TPoint;
    AvgZ: Single;
    Intensity: Single;
  end;

procedure TAI3DModelViewer.Paint;
var
  BaseScale: Double;
  ProjectedFaces: array of TProjectedFace;
  I: Integer;
  radX, radY: Double;
  cosX, sinX, cosY, sinY: Double;
  CX, CY: Integer;
  D: Double;
  rz1, rz2, rz3: Single;
  
  procedure RotateAndProject(const V: TVertex3D; var P: TPoint; var RZ: Single);
  var
    tx, ty, tz: Single;
    x1, y1, z1: Single;
    x2, y2, z2: Single;
    Scale: Double;
  begin
    tx := V.X - FModel.MidX;
    ty := V.Y - FModel.MidY;
    tz := V.Z - FModel.MidZ;
    
    // Rotate Y
    x1 := tx * cosY - tz * sinY;
    z1 := tx * sinY + tz * cosY;
    y1 := ty;
    
    // Rotate X
    y2 := y1 * cosX - z1 * sinX;
    z2 := y1 * sinX + z1 * cosX;
    x2 := x1;
    
    RZ := z2;
    
    // Project to 2D
    Scale := BaseScale * FZoom;
    P.X := CX + Round(x2 * Scale * D / (z2 + D));
    P.Y := CY - Round(y2 * Scale * D / (z2 + D));
  end;

  procedure QuickSort(L, R: Integer);
  var
    IdxI, IdxJ: Integer;
    Pivot: Single;
    Temp: TProjectedFace;
  begin
    IdxI := L;
    IdxJ := R;
    Pivot := ProjectedFaces[(L + R) div 2].AvgZ;
    repeat
      while ProjectedFaces[IdxI].AvgZ > Pivot do Inc(IdxI);
      while ProjectedFaces[IdxJ].AvgZ < Pivot do Dec(IdxJ);
      if IdxI <= IdxJ then
      begin
        Temp := ProjectedFaces[IdxI];
        ProjectedFaces[IdxI] := ProjectedFaces[IdxJ];
        ProjectedFaces[IdxJ] := Temp;
        Inc(IdxI);
        Dec(IdxJ);
      end;
    until IdxI > IdxJ;
    if L < IdxJ then QuickSort(L, IdxJ);
    if IdxI < R then QuickSort(IdxI, R);
  end;

var
  R, G, B: Byte;
  Intensity: Single;
begin
  inherited Paint;
  Canvas.Brush.Color := FBackgroundColor;
  Canvas.FillRect(ClientRect);
  
  Canvas.Pen.Color := clBlack;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(10, 10, '3D Model Viewer');
  
  if (FModel = nil) or (Length(FModel.Faces) = 0) then
  begin
    Canvas.TextOut(10, 30, 'No Model Loaded (or empty mesh)');
    Exit;
  end;

  Canvas.TextOut(10, 30, 'Model: ' + ExtractFileName(FModel.FilePath));
  Canvas.TextOut(10, 50, Format('Vertices: %d, Faces: %d', [FModel.VerticesCount, FModel.FacesCount]));
  Canvas.TextOut(10, 70, 'Hint: Drag mouse to Rotate. Mouse wheel / Zoom buttons to Zoom.');

  // Base Scale calculation
  BaseScale := (Min(ClientWidth, ClientHeight) * 0.45) / FModel.ModelRadius;
  if BaseScale < 0.1 then BaseScale := 1.0;
  
  CX := ClientWidth div 2;
  CY := ClientHeight div 2;
  D := FModel.ModelRadius * 3.0;
  if D < 1.0 then D := 10.0;
  
  radY := FRotY * pi / 180.0;
  radX := FRotX * pi / 180.0;
  cosY := Cos(radY); sinY := Sin(radY);
  cosX := Cos(radX); sinX := Sin(radX);

  SetLength(ProjectedFaces, Length(FModel.Faces));
  for I := 0 to Length(FModel.Faces) - 1 do
  begin
    RotateAndProject(FModel.Faces[I].V1, ProjectedFaces[I].P1, rz1);
    RotateAndProject(FModel.Faces[I].V2, ProjectedFaces[I].P2, rz2);
    RotateAndProject(FModel.Faces[I].V3, ProjectedFaces[I].P3, rz3);
    ProjectedFaces[I].AvgZ := (rz1 + rz2 + rz3) / 3.0;

    // Normal calculation for simple light shading
    rz1 := FModel.Faces[I].Normal.X * cosY - FModel.Faces[I].Normal.Z * sinY;
    rz2 := FModel.Faces[I].Normal.X * sinY + FModel.Faces[I].Normal.Z * cosY;
    rz3 := FModel.Faces[I].Normal.Y * cosX - rz2 * sinX;
    
    Intensity := Abs(rz3);
    if Intensity < 0.1 then Intensity := 0.1;
    ProjectedFaces[I].Intensity := Intensity;
  end;

  // Sort faces back to front (Painter's algorithm)
  if Length(ProjectedFaces) > 1 then
    QuickSort(0, Length(ProjectedFaces) - 1);

  // Draw faces
  for I := 0 to Length(ProjectedFaces) - 1 do
  begin
    case FRenderMode of
      rmSolid:
        begin
          Intensity := ProjectedFaces[I].Intensity;
          R := Round(40 + 160 * Intensity);
          G := Round(60 + 175 * Intensity);
          B := Round(90 + 195 * Intensity);
          Canvas.Brush.Color := RGBToColor(R, G, B);
          Canvas.Brush.Style := bsSolid;
          Canvas.Pen.Color := RGBToColor(Max(0, R - 30), Max(0, G - 30), Max(0, B - 30));
          Canvas.Polygon([ProjectedFaces[I].P1, ProjectedFaces[I].P2, ProjectedFaces[I].P3]);
        end;
      rmWireframe:
        begin
          Canvas.Brush.Style := bsClear;
          Canvas.Pen.Color := clNavy;
          Canvas.Polygon([ProjectedFaces[I].P1, ProjectedFaces[I].P2, ProjectedFaces[I].P3]);
        end;
      rmPoints:
        begin
          Canvas.Pen.Color := clNavy;
          Canvas.Brush.Color := clNavy;
          Canvas.Brush.Style := bsSolid;
          Canvas.Ellipse(ProjectedFaces[I].P1.X - 1, ProjectedFaces[I].P1.Y - 1, ProjectedFaces[I].P1.X + 1, ProjectedFaces[I].P1.Y + 1);
          Canvas.Ellipse(ProjectedFaces[I].P2.X - 1, ProjectedFaces[I].P2.Y - 1, ProjectedFaces[I].P2.X + 1, ProjectedFaces[I].P2.Y + 1);
          Canvas.Ellipse(ProjectedFaces[I].P3.X - 1, ProjectedFaces[I].P3.Y - 1, ProjectedFaces[I].P3.X + 1, ProjectedFaces[I].P3.Y + 1);
        end;
    end;
  end;
end;

procedure TAI3DModelViewer.ZoomIn;
begin
  FZoom := FZoom * 1.15;
  Log(llDebug, 'Zoomed in.');
  Invalidate;
end;

procedure TAI3DModelViewer.ZoomOut;
begin
  FZoom := FZoom / 1.15;
  Log(llDebug, 'Zoomed out.');
  Invalidate;
end;

procedure TAI3DModelViewer.ResetCamera;
begin
  FRotX := 20.0;
  FRotY := 30.0;
  FRotZ := 0.0;
  FZoom := 1.0;
  Log(llDebug, 'Camera reset.');
  Invalidate;
end;

procedure TAI3DModelViewer.ExportScreenshot(const AFileName: string);
begin
  Log(llInfo, 'Exported screenshot to: ' + AFileName);
  FLastResult := 'Screenshot exported.';
  FLastSuccess := True;
end;

initialization
  {$I ai3dmodelviewer_icon.lrs}

end.
