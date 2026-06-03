unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Math, StrUtils, aiskeletonrig, aiavatarcontroller, aiposelibrary, aibase;

type

  { TfrmAvatarDemo }

  TfrmAvatarDemo = class(TForm)
    pnlLeft: TPanel;
    pnlScene: TPanel;
    lblSceneTitle: TLabel;
    btnLoadRig: TButton;
    lblBoneSelect: TLabel;
    cbBones: TComboBox;
    lblAxisSelect: TLabel;
    cbAxis: TComboBox;
    lblAngle: TLabel;
    tbAngle: TTrackBar;
    lblAngleVal: TLabel;
    
    pnlPose: TPanel;
    lblPoseTitle: TLabel;
    btnTPose: TButton;
    btnSit: TButton;
    btnWave: TButton;
    btnWalk: TButton;
    
    pnlView: TPanel;
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadRigClick(Sender: TObject);
    procedure cbBonesChange(Sender: TObject);
    procedure cbAxisChange(Sender: TObject);
    procedure tbAngleChange(Sender: TObject);
    procedure btnTPoseClick(Sender: TObject);
    procedure btnSitClick(Sender: TObject);
    procedure btnWaveClick(Sender: TObject);
    procedure btnWalkClick(Sender: TObject);
    
    procedure pnlViewPaint(Sender: TObject);
    procedure pnlViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pnlViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pnlViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FSkeleton: TAISkeletonRig;
    FAvatar: TAIAvatarController;
    FPoseLib: TAIPoseLibrary;
    
    // View camera angles & zoom
    FRotX: Double;
    FRotY: Double;
    FZoom: Double;
    FMouseDrag: Boolean;
    FLastMousePos: TPoint;
    
    procedure LogMsg(const AMsg: string);
    procedure ComponentLog(Sender: TObject; ALevel: TAILogLevel; const AMsg: string);
    procedure UpdateBoneControls;
    procedure DrawJoint(ACanvas: TCanvas; const Joint: TBoneJoint; cosX, sinX, cosY, sinY: Double; CX, CY: Integer; Scale, D: Double);
    procedure DrawBoneLine(ACanvas: TCanvas; const JStart, JEnd: TBoneJoint; cosX, sinX, cosY, sinY: Double; CX, CY: Integer; Scale, D: Double; AColor: TColor; Thickness: Integer);
  public

  end;

var
  frmAvatarDemo: TfrmAvatarDemo;

implementation

{$R *.lfm}

{ TfrmAvatarDemo }

procedure TfrmAvatarDemo.FormCreate(Sender: TObject);
begin
  // 1. Create AI components
  FSkeleton := TAISkeletonRig.Create(Self);
  FAvatar := TAIAvatarController.Create(Self);
  FAvatar.Skeleton := FSkeleton;
  FPoseLib := TAIPoseLibrary.Create(Self);
  
  // Set logs
  FSkeleton.OnLog := @ComponentLog;
  FAvatar.OnLog := @ComponentLog;
  FPoseLib.OnLog := @ComponentLog;

  // Initialize camera settings
  FRotX := 15.0;
  FRotY := -30.0;
  FZoom := 1.0;
  FMouseDrag := False;

  // Populate Bone combo
  cbBones.Items.Assign(FSkeleton.BonesList);
  cbBones.ItemIndex := 1; // Start on spine

  // Populate Axis combo
  cbAxis.Items.Clear;
  cbAxis.Items.Add('Axis X (Pitch)');
  cbAxis.Items.Add('Axis Y (Yaw)');
  cbAxis.Items.Add('Axis Z (Roll)');
  cbAxis.ItemIndex := 2; // Default Z

  UpdateBoneControls;
  LogMsg('Avatar/Robot Kinematics Simulator initialized.');
  LogMsg('Hint: Click "Load Model / Rig" to load any hierarchical 3D object definition.');
end;

procedure TfrmAvatarDemo.FormDestroy(Sender: TObject);
begin
  // Freed by Owner (Self)
end;

procedure TfrmAvatarDemo.btnLoadRigClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Load 3D Hierarchical Rig/Model';
    OpenDlg.Filter := 'All Supported Rigs (*.rig;*.bvh;*.dae;*.gltf;*.glb;*.blend)|*.rig;*.bvh;*.dae;*.gltf;*.glb;*.blend|Rig files (*.rig)|*.rig|BVH Files (*.bvh)|*.bvh|Collada Files (*.dae)|*.dae|glTF Files (*.gltf;*.glb)|*.gltf;*.glb|Blender Files (*.blend)|*.blend|All Files (*.*)|*.*';
    OpenDlg.InitialDir := ExtractFilePath(Application.ExeName);
    if OpenDlg.Execute then
    begin
      LogMsg('Loading model hierarchy: ' + OpenDlg.FileName);
      FSkeleton.LoadRigFromFile(OpenDlg.FileName);
      
      // Update the UI controls
      cbBones.Items.Assign(FSkeleton.BonesList);
      if cbBones.Items.Count > 0 then
        cbBones.ItemIndex := 0
      else
        cbBones.ItemIndex := -1;
      
      UpdateBoneControls;
      
      // Redraw the view
      pnlView.Invalidate;
      LogMsg(Format('Model hierarchy loaded successfully. %d joints identified.', [FSkeleton.GetJointCount]));
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmAvatarDemo.ComponentLog(Sender: TObject; ALevel: TAILogLevel; const AMsg: string);
var
  Prefix: string;
begin
  case ALevel of
    llDebug: Prefix := '[DEBUG] ';
    llInfo: Prefix := '[INFO] ';
    llWarning: Prefix := '[WARNING] ';
    llError: Prefix := '[ERROR] ';
  end;
  LogMsg(Prefix + Sender.ClassName + ': ' + AMsg);
end;

procedure TfrmAvatarDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss.zzz', Now) + '] ' + AMsg);
end;

procedure TfrmAvatarDemo.UpdateBoneControls;
var
  BoneName: string;
  I: Integer;
  Joint: TBoneJoint;
  Angle: Double;
begin
  if cbBones.ItemIndex < 0 then Exit;
  BoneName := cbBones.Text;
  
  // Find current angle for selected bone and axis
  Angle := 0;
  for I := 0 to FSkeleton.GetJointCount - 1 do
  begin
    Joint := FSkeleton.GetJoint(I);
    if SameText(Joint.Name, BoneName) then
    begin
      case cbAxis.ItemIndex of
        0: Angle := Joint.AngleX;
        1: Angle := Joint.AngleY;
        2: Angle := Joint.AngleZ;
      end;
      Break;
    end;
  end;
  
  // Temporarily disable event to avoid recursion
  tbAngle.OnChange := nil;
  try
    tbAngle.Position := Round(Angle);
    lblAngleVal.Caption := Format('%d°', [Round(Angle)]);
  finally
    tbAngle.OnChange := @tbAngleChange;
  end;
end;

procedure TfrmAvatarDemo.cbBonesChange(Sender: TObject);
begin
  UpdateBoneControls;
end;

procedure TfrmAvatarDemo.cbAxisChange(Sender: TObject);
begin
  UpdateBoneControls;
end;

procedure TfrmAvatarDemo.tbAngleChange(Sender: TObject);
var
  BoneName: string;
  I: Integer;
  Joint: TBoneJoint;
  AX, AY, AZ: Double;
begin
  if cbBones.ItemIndex < 0 then Exit;
  BoneName := cbBones.Text;
  
  AX := 0; AY := 0; AZ := 0;
  
  // Find current angles
  for I := 0 to FSkeleton.GetJointCount - 1 do
  begin
    Joint := FSkeleton.GetJoint(I);
    if SameText(Joint.Name, BoneName) then
    begin
      AX := Joint.AngleX;
      AY := Joint.AngleY;
      AZ := Joint.AngleZ;
      Break;
    end;
  end;
  
  // Update selected axis
  case cbAxis.ItemIndex of
    0: AX := tbAngle.Position;
    1: AY := tbAngle.Position;
    2: AZ := tbAngle.Position;
  end;
  
  lblAngleVal.Caption := Format('%d°', [tbAngle.Position]);
  
  // Apply rotation
  FSkeleton.SetBoneRotation(BoneName, AX, AY, AZ);
  pnlView.Invalidate;
end;

procedure TfrmAvatarDemo.btnTPoseClick(Sender: TObject);
var
  I: Integer;
begin
  LogMsg('Applying T-Pose...');
  FAvatar.SetPose('T-Pose');
  for I := 0 to FSkeleton.GetJointCount - 1 do
    FSkeleton.SetBoneRotation(FSkeleton.GetJoint(I).Name, 0, 0, 0);
  UpdateBoneControls;
  pnlView.Invalidate;
end;

procedure TfrmAvatarDemo.btnSitClick(Sender: TObject);
begin
  LogMsg('Applying sitting pose...');
  FAvatar.SetPose('Sitting');
  
  // Reset all
  btnTPoseClick(nil);
  
  // Try to apply sit pose to human structure if bones exist
  FSkeleton.SetBoneRotation('left_hip', 90, 0, 0);
  FSkeleton.SetBoneRotation('right_hip', 90, 0, 0);
  FSkeleton.SetBoneRotation('left_knee', -90, 0, 0);
  FSkeleton.SetBoneRotation('right_knee', -90, 0, 0);
  FSkeleton.SetBoneRotation('left_shoulder', 0, 0, -30);
  FSkeleton.SetBoneRotation('right_shoulder', 0, 0, 30);
  
  UpdateBoneControls;
  pnlView.Invalidate;
end;

procedure TfrmAvatarDemo.btnWaveClick(Sender: TObject);
begin
  LogMsg('Applying waving pose...');
  FAvatar.SetPose('Waving');
  
  btnTPoseClick(nil);
  
  FSkeleton.SetBoneRotation('right_shoulder', 0, 0, 130);
  FSkeleton.SetBoneRotation('right_elbow', 0, 0, 90);
  
  UpdateBoneControls;
  pnlView.Invalidate;
end;

procedure TfrmAvatarDemo.btnWalkClick(Sender: TObject);
begin
  LogMsg('Applying walking stance...');
  FAvatar.SetPose('Walking');
  
  btnTPoseClick(nil);
  
  FSkeleton.SetBoneRotation('left_hip', 30, 0, 0);
  FSkeleton.SetBoneRotation('left_knee', -20, 0, 0);
  FSkeleton.SetBoneRotation('right_hip', -30, 0, 0);
  FSkeleton.SetBoneRotation('right_knee', -5, 0, 0);
  FSkeleton.SetBoneRotation('left_shoulder', -25, 0, -10);
  FSkeleton.SetBoneRotation('right_shoulder', 25, 0, 10);
  FSkeleton.SetBoneRotation('right_elbow', 0, 0, 30);
  
  UpdateBoneControls;
  pnlView.Invalidate;
end;

procedure TfrmAvatarDemo.DrawJoint(ACanvas: TCanvas; const Joint: TBoneJoint; cosX, sinX, cosY, sinY: Double; CX, CY: Integer; Scale, D: Double);
var
  x1, y1, z1, x2, y2, z2: Double;
  sx, sy: Integer;
  R: Integer;
begin
  // Project end point of joint
  x1 := Joint.EndX * cosY - Joint.EndZ * sinY;
  z1 := Joint.EndX * sinY + Joint.EndZ * cosY;
  y1 := Joint.EndY;
  
  y2 := y1 * cosX - z1 * sinX;
  z2 := y1 * sinX + z1 * cosX;
  x2 := x1;
  
  sx := CX + Round(x2 * Scale * D / (z2 + D));
  sy := CY - Round(y2 * Scale * D / (z2 + D));
  
  R := Max(2, Round(8 * D / (z2 + D)));
  
  if SameText(Joint.Name, 'head') then
  begin
    // Head oval
    ACanvas.Brush.Color := RGBToColor(255, 210, 120);
    ACanvas.Pen.Color := RGBToColor(200, 150, 80);
    ACanvas.Ellipse(sx - R * 2, sy - R * 3, sx + R * 2, sy + R * 1);
    
    // Draw face cross or dummy crash test marker!
    ACanvas.Pen.Color := clBlack;
    ACanvas.Line(sx - R * 2, sy - R, sx + R * 2, sy - R);
    ACanvas.Line(sx, sy - R * 3, sx, sy + R * 1);
  end
  else
  begin
    // General joint marker
    ACanvas.Brush.Color := clYellow;
    ACanvas.Pen.Color := RGBToColor(255, 127, 0);
    ACanvas.Ellipse(sx - R, sy - R, sx + R, sy + R);
  end;
end;

procedure TfrmAvatarDemo.DrawBoneLine(ACanvas: TCanvas; const JStart, JEnd: TBoneJoint; cosX, sinX, cosY, sinY: Double; CX, CY: Integer; Scale, D: Double; AColor: TColor; Thickness: Integer);
var
  x1, y1, z1, x2, y2, z2: Double;
  sx1, sy1, sx2, sy2: Integer;
begin
  // Start Point Project
  x1 := JStart.EndX * cosY - JStart.EndZ * sinY;
  z1 := JStart.EndX * sinY + JStart.EndZ * cosY;
  y1 := JStart.EndY;
  y2 := y1 * cosX - z1 * sinX;
  z2 := y1 * sinX + z1 * cosX;
  x2 := x1;
  sx1 := CX + Round(x2 * Scale * D / (z2 + D));
  sy1 := CY - Round(y2 * Scale * D / (z2 + D));
  
  // End Point Project
  x1 := JEnd.EndX * cosY - JEnd.EndZ * sinY;
  z1 := JEnd.EndX * sinY + JEnd.EndZ * cosY;
  y1 := JEnd.EndY;
  y2 := y1 * cosX - z1 * sinX;
  z2 := y1 * sinX + z1 * cosX;
  x2 := x1;
  sx2 := CX + Round(x2 * Scale * D / (z2 + D));
  sy2 := CY - Round(y2 * Scale * D / (z2 + D));
  
  ACanvas.Pen.Color := AColor;
  ACanvas.Pen.Width := Thickness;
  ACanvas.Line(sx1, sy1, sx2, sy2);
  ACanvas.Pen.Width := 1; // restore
end;

procedure TfrmAvatarDemo.pnlViewPaint(Sender: TObject);
var
  CanvasLocal: TCanvas;
  CX, CY: Integer;
  BaseScale, Scale: Double;
  D: Double;
  radX, radY: Double;
  cosX, sinX, cosY, sinY: Double;
  I: Integer;
  Joint: TBoneJoint;
  ParentIdx: Integer;
  LineColor: TColor;
  
  // Floor grid points
  GX, GZ: Double;
  sx, sy: Integer;
  x1, z1, y2, z2, x2: Double;
begin
  CanvasLocal := pnlView.Canvas;
  CanvasLocal.Brush.Color := clWhite;
  CanvasLocal.FillRect(pnlView.ClientRect);
  
  CX := pnlView.ClientWidth div 2;
  CY := pnlView.ClientHeight div 2 - 30; // Shift origin slightly up to see floor better
  
  BaseScale := Min(pnlView.ClientWidth, pnlView.ClientHeight) * 0.35;
  Scale := BaseScale * FZoom;
  D := 5.0; // Camera distance
  
  radY := FRotY * pi / 180.0;
  radX := FRotX * pi / 180.0;
  cosY := Cos(radY); sinY := Sin(radY);
  cosX := Cos(radX); sinX := Sin(radX);
  
  // 1. Draw floor grid for depth perspective
  CanvasLocal.Pen.Color := RGBToColor(220, 220, 220);
  for I := -5 to 5 do
  begin
    // Grid lines parallel to Z axis (from left to right)
    GX := I * 0.3;
    x1 := GX * cosY - (-1.5) * sinY;
    z1 := GX * sinY + (-1.5) * cosY;
    y2 := 0.0 * cosX - z1 * sinX;
    z2 := 0.0 * sinX + z1 * cosX;
    x2 := x1;
    sx := CX + Round(x2 * Scale * D / (z2 + D));
    sy := CY - Round(y2 * Scale * D / (z2 + D));
    CanvasLocal.MoveTo(sx, sy);
    
    x1 := GX * cosY - 1.5 * sinY;
    z1 := GX * sinY + 1.5 * cosY;
    y2 := 0.0 * cosX - z1 * sinX;
    z2 := 0.0 * sinX + z1 * cosX;
    x2 := x1;
    sx := CX + Round(x2 * Scale * D / (z2 + D));
    sy := CY - Round(y2 * Scale * D / (z2 + D));
    CanvasLocal.LineTo(sx, sy);
    
    // Grid lines parallel to X axis (from back to front)
    GZ := I * 0.3;
    x1 := (-1.5) * cosY - GZ * sinY;
    z1 := (-1.5) * sinY + GZ * cosY;
    y2 := 0.0 * cosX - z1 * sinX;
    z2 := 0.0 * sinX + z1 * cosX;
    x2 := x1;
    sx := CX + Round(x2 * Scale * D / (z2 + D));
    sy := CY - Round(y2 * Scale * D / (z2 + D));
    CanvasLocal.MoveTo(sx, sy);
    
    x1 := 1.5 * cosY - GZ * sinY;
    z1 := 1.5 * sinY + GZ * cosY;
    y2 := 0.0 * cosX - z1 * sinX;
    z2 := 0.0 * sinX + z1 * cosX;
    x2 := x1;
    sx := CX + Round(x2 * Scale * D / (z2 + D));
    sy := CY - Round(y2 * Scale * D / (z2 + D));
    CanvasLocal.LineTo(sx, sy);
  end;

  // 2. Draw skeleton bones hierarchically (fully generic loop)
  for I := 0 to FSkeleton.GetJointCount - 1 do
  begin
    Joint := FSkeleton.GetJoint(I);
    ParentIdx := Joint.ParentIndex;
    if ParentIdx >= 0 then
    begin
      LineColor := clBlack;
      if ContainsText(Joint.Name, 'left') then
        LineColor := clRed
      else if ContainsText(Joint.Name, 'right') then
        LineColor := clGreen
      else if ContainsText(Joint.Name, 'base') or ContainsText(Joint.Name, 'pelvis') then
        LineColor := clNavy;
        
      DrawBoneLine(CanvasLocal, FSkeleton.GetJoint(ParentIdx), Joint, cosX, sinX, cosY, sinY, CX, CY, Scale, D, LineColor, 3);
    end;
  end;

  // 3. Draw joint dots
  for I := 0 to FSkeleton.GetJointCount - 1 do
  begin
    Joint := FSkeleton.GetJoint(I);
    DrawJoint(CanvasLocal, Joint, cosX, sinX, cosY, sinY, CX, CY, Scale, D);
  end;
  
  // Draw Coordinate axes at corner
  CanvasLocal.Pen.Color := clRed; CanvasLocal.Line(10, pnlView.Height - 10, 40, pnlView.Height - 10); // X
  CanvasLocal.TextOut(42, pnlView.Height - 18, 'X');
  CanvasLocal.Pen.Color := clGreen; CanvasLocal.Line(10, pnlView.Height - 10, 10, pnlView.Height - 40); // Y
  CanvasLocal.TextOut(6, pnlView.Height - 52, 'Y');
end;

procedure TfrmAvatarDemo.pnlViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FMouseDrag := True;
    FLastMousePos := Point(X, Y);
  end;
end;

procedure TfrmAvatarDemo.pnlViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FMouseDrag then
  begin
    FRotY := FRotY + (X - FLastMousePos.X) * 0.5;
    FRotX := FRotX + (Y - FLastMousePos.Y) * 0.5;
    FLastMousePos := Point(X, Y);
    pnlView.Invalidate;
  end;
end;

procedure TfrmAvatarDemo.pnlViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    FMouseDrag := False;
end;

end.
