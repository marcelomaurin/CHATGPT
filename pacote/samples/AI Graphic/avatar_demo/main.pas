unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Math, StrUtils, aiskeletonrig, aiavatarcontroller, aiposelibrary, aibase;

type
  TProjectedJoint = record
    SX, SY: Integer;
    SZ: Double;
  end;

  TDrawElement = record
    IsBone: Boolean;
    Index: Integer;
    Depth: Double;
  end;

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
    procedure DrawJointProj(ACanvas: TCanvas; const Joint: TBoneJoint; const P: TProjectedJoint; Scale, D: Double);
    procedure DrawSolidBoneProj(ACanvas: TCanvas; const PStart, PEnd: TProjectedJoint; AColor: TColor; Width3D: Double; Scale, D: Double; const ABoneName: string);
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

procedure TfrmAvatarDemo.DrawJointProj(ACanvas: TCanvas; const Joint: TBoneJoint; const P: TProjectedJoint; Scale, D: Double);
var
  R: Integer;
  BaseR: Double;
begin
  // Determine dynamic radius based on the joint type
  if SameText(Joint.Name, 'head') then
    BaseR := 0.14
  else if SameText(Joint.Name, 'pelvis') or SameText(Joint.Name, 'spine') or SameText(Joint.Name, 'chest') then
    BaseR := 0.11
  else if ContainsText(Joint.Name, 'hip') or ContainsText(Joint.Name, 'knee') or ContainsText(Joint.Name, 'thigh') then
    BaseR := 0.095
  else if ContainsText(Joint.Name, 'shoulder') or ContainsText(Joint.Name, 'clavicle') then
    BaseR := 0.08
  else if ContainsText(Joint.Name, 'elbow') then
    BaseR := 0.07
  else
    BaseR := 0.055;

  R := Round(BaseR * Scale * D / (P.SZ + D));
  if R < 2 then R := 2;

  // Head, Spine, Pelvis: draw alternating black & yellow calibration target markers
  if SameText(Joint.Name, 'head') or SameText(Joint.Name, 'spine') or SameText(Joint.Name, 'pelvis') then
  begin
    // Base circle in yellow
    ACanvas.Brush.Color := RGBToColor(240, 200, 80);
    ACanvas.Pen.Color := RGBToColor(160, 120, 20);
    ACanvas.Ellipse(P.SX - R, P.SY - R, P.SX + R, P.SY + R);

    // Alternating black quadrants
    ACanvas.Brush.Color := clBlack;
    ACanvas.Pen.Color := clBlack;
    ACanvas.Pie(P.SX - R, P.SY - R, P.SX + R, P.SY + R, P.SX + R, P.SY, P.SX, P.SY - R);
    ACanvas.Pie(P.SX - R, P.SY - R, P.SX + R, P.SY + R, P.SX - R, P.SY, P.SX, P.SY + R);

    // Cross lines
    ACanvas.Pen.Color := clBlack;
    ACanvas.Pen.Width := 1;
    ACanvas.Line(P.SX - R, P.SY, P.SX + R, P.SY);
    ACanvas.Line(P.SX, P.SY - R, P.SX, P.SY + R);

    // Subtle highlight
    ACanvas.Brush.Color := RGBToColor(255, 230, 130);
    ACanvas.Pen.Color := clNone;
    ACanvas.Ellipse(P.SX - R div 2, P.SY - R div 2, P.SX - R div 4, P.SY - R div 4);
  end
  else
  begin
    // Dark steel mechanical ball joints with 3D radial highlights
    ACanvas.Brush.Color := RGBToColor(45, 45, 50);
    ACanvas.Pen.Color := RGBToColor(25, 25, 28);
    ACanvas.Ellipse(P.SX - R, P.SY - R, P.SX + R, P.SY + R);

    // Highlight
    ACanvas.Brush.Color := RGBToColor(135, 135, 145);
    ACanvas.Pen.Color := clNone;
    ACanvas.Ellipse(P.SX - R div 2, P.SY - R div 2, P.SX - R div 6, P.SY - R div 6);
  end;
end;

procedure TfrmAvatarDemo.DrawSolidBoneProj(ACanvas: TCanvas; const PStart, PEnd: TProjectedJoint; AColor: TColor; Width3D: Double; Scale, D: Double; const ABoneName: string);
var
  w1, w2: Double;
  dx, dy, len: Double;
  nx, ny: Double;
  pts: array[0..3] of TPoint;
begin
  w1 := Width3D * Scale * D / (PStart.SZ + D);
  w2 := Width3D * Scale * D / (PEnd.SZ + D);
  
  dx := PEnd.SX - PStart.SX;
  dy := PEnd.SY - PStart.SY;
  len := Sqrt(dx*dx + dy*dy);
  
  if len > 0.001 then
  begin
    nx := -dy / len;
    ny := dx / len;
    
    pts[0].X := Round(PStart.SX + nx * w1 * 0.5);
    pts[0].Y := Round(PStart.SY + ny * w1 * 0.5);
    
    pts[1].X := Round(PStart.SX - nx * w1 * 0.5);
    pts[1].Y := Round(PStart.SY - ny * w1 * 0.5);
    
    pts[2].X := Round(PEnd.SX - nx * w2 * 0.5);
    pts[2].Y := Round(PEnd.SY - ny * w2 * 0.5);
    
    pts[3].X := Round(PEnd.SX + nx * w2 * 0.5);
    pts[3].Y := Round(PEnd.SY + ny * w2 * 0.5);
    
    ACanvas.Brush.Color := AColor;
    ACanvas.Pen.Color := RGBToColor(Max(0, Red(AColor)-40), Max(0, Green(AColor)-40), Max(0, Blue(AColor)-40));
    ACanvas.Polygon(pts);
    
    // Custom ribbed style for the neck to look like a real segmented crash dummy neck
    if SameText(ABoneName, 'neck') then
    begin
      ACanvas.Pen.Color := RGBToColor(60, 60, 65);
      ACanvas.Pen.Width := 2;
      ACanvas.Line(Round(PStart.SX + (PEnd.SX - PStart.SX)*0.33 - nx * w1 * 0.45), Round(PStart.SY + (PEnd.SY - PStart.SY)*0.33 - ny * w1 * 0.45),
                   Round(PStart.SX + (PEnd.SX - PStart.SX)*0.33 + nx * w1 * 0.45), Round(PStart.SY + (PEnd.SY - PStart.SY)*0.33 + ny * w1 * 0.45));
      ACanvas.Line(Round(PStart.SX + (PEnd.SX - PStart.SX)*0.66 - nx * w1 * 0.45), Round(PStart.SY + (PEnd.SY - PStart.SY)*0.66 - ny * w1 * 0.45),
                   Round(PStart.SX + (PEnd.SX - PStart.SX)*0.66 + nx * w1 * 0.45), Round(PStart.SY + (PEnd.SY - PStart.SY)*0.66 + ny * w1 * 0.45));
      ACanvas.Pen.Width := 1;
    end
    else
    begin
      // Inner lighting line
      ACanvas.Pen.Color := RGBToColor(Min(255, Red(AColor)+40), Min(255, Green(AColor)+40), Min(255, Blue(AColor)+40));
      ACanvas.Line(Round(PStart.SX + nx * w1 * 0.1), Round(PStart.SY + ny * w1 * 0.1),
                   Round(PEnd.SX + nx * w2 * 0.1), Round(PEnd.SY + ny * w2 * 0.1));
    end;
  end;
end;

procedure TfrmAvatarDemo.pnlViewPaint(Sender: TObject);
var
  CanvasLocal: TCanvas;
  CX, CY: Integer;
  BaseScale, Scale: Double;
  D: Double;
  radX, radY: Double;
  cosX, sinX, cosY, sinY: Double;
  I, J, Idx, ParentIdx: Integer;
  Joint: TBoneJoint;
  LineColor: TColor;
  Width3D: Double;
  
  // Floor grid points
  GX, GZ: Double;
  sx, sy: Integer;
  x1, y1, z1, y2, z2, x2: Double;
  
  // Projection list and elements array
  Proj: array of TProjectedJoint;
  Elements: array of TDrawElement;
  ElementCount: Integer;
  Tmp: TDrawElement;
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

  if FSkeleton.GetJointCount = 0 then Exit;

  // 2. Project all joint coordinates
  SetLength(Proj, FSkeleton.GetJointCount);
  for I := 0 to FSkeleton.GetJointCount - 1 do
  begin
    Joint := FSkeleton.GetJoint(I);
    x1 := Joint.EndX * cosY - Joint.EndZ * sinY;
    z1 := Joint.EndX * sinY + Joint.EndZ * cosY;
    y1 := Joint.EndY;
    
    y2 := y1 * cosX - z1 * sinX;
    z2 := y1 * sinX + z1 * cosX;
    x2 := x1;
    
    Proj[I].SX := CX + Round(x2 * Scale * D / (z2 + D));
    Proj[I].SY := CY - Round(y2 * Scale * D / (z2 + D));
    Proj[I].SZ := z2;
  end;

  // 3. Build draw elements (joints and bones)
  SetLength(Elements, FSkeleton.GetJointCount * 2);
  ElementCount := 0;
  
  for I := 0 to FSkeleton.GetJointCount - 1 do
  begin
    // Add Joint element (with slight depth bias of -0.02 to ensure it is drawn on top of its connected bones)
    Elements[ElementCount].IsBone := False;
    Elements[ElementCount].Index := I;
    Elements[ElementCount].Depth := Proj[I].SZ - 0.02;
    Inc(ElementCount);
    
    // Add Bone element if joint has parent
    ParentIdx := FSkeleton.GetJoint(I).ParentIndex;
    if ParentIdx >= 0 then
    begin
      Elements[ElementCount].IsBone := True;
      Elements[ElementCount].Index := I;
      Elements[ElementCount].Depth := (Proj[I].SZ + Proj[ParentIdx].SZ) * 0.5;
      Inc(ElementCount);
    end;
  end;
  
  SetLength(Elements, ElementCount);

  // 4. Sort elements using depth (farthest first / descending)
  for I := 0 to ElementCount - 2 do
    for J := I + 1 to ElementCount - 1 do
      if Elements[I].Depth < Elements[J].Depth then
      begin
        Tmp := Elements[I];
        Elements[I] := Elements[J];
        Elements[J] := Tmp;
      end;

  // 5. Draw elements in sorted order (Painter's Algorithm)
  for I := 0 to ElementCount - 1 do
  begin
    Idx := Elements[I].Index;
    Joint := FSkeleton.GetJoint(Idx);
    
    if Elements[I].IsBone then
    begin
      ParentIdx := Joint.ParentIndex;
      LineColor := RGBToColor(210, 210, 215);
      Width3D := 0.08;
      
      if SameText(Joint.Name, 'spine') or SameText(Joint.Name, 'chest') then
      begin
        LineColor := RGBToColor(240, 200, 80); // Yellow chest/spine block
        Width3D := 0.22;
      end
      else if SameText(Joint.Name, 'pelvis') then
      begin
        LineColor := RGBToColor(240, 200, 80); // Yellow pelvis block
        Width3D := 0.22;
      end
      else if SameText(Joint.Name, 'neck') then
      begin
        LineColor := RGBToColor(140, 140, 145); // Grey neck
        Width3D := 0.07;
      end
      else if ContainsText(Joint.Name, 'left') or ContainsText(Joint.Name, 'l_') or StartsText('l', Joint.Name) then
      begin
        LineColor := RGBToColor(240, 100, 100); // Reddish segments for left limbs
        if ContainsText(Joint.Name, 'hip') or ContainsText(Joint.Name, 'knee') or ContainsText(Joint.Name, 'thigh') or ContainsText(Joint.Name, 'leg') or ContainsText(Joint.Name, 'shin') then
          Width3D := 0.11
        else if ContainsText(Joint.Name, 'shoulder') or ContainsText(Joint.Name, 'clavicle') then
          Width3D := 0.09
        else
          Width3D := 0.07;
      end
      else if ContainsText(Joint.Name, 'right') or ContainsText(Joint.Name, 'r_') or StartsText('r', Joint.Name) then
      begin
        LineColor := RGBToColor(100, 200, 100); // Greenish segments for right limbs
        if ContainsText(Joint.Name, 'hip') or ContainsText(Joint.Name, 'knee') or ContainsText(Joint.Name, 'thigh') or ContainsText(Joint.Name, 'leg') or ContainsText(Joint.Name, 'shin') then
          Width3D := 0.11
        else if ContainsText(Joint.Name, 'shoulder') or ContainsText(Joint.Name, 'clavicle') then
          Width3D := 0.09
        else
          Width3D := 0.07;
      end;
      
      DrawSolidBoneProj(CanvasLocal, Proj[ParentIdx], Proj[Idx], LineColor, Width3D, Scale, D, Joint.Name);
    end
    else
    begin
      DrawJointProj(CanvasLocal, Joint, Proj[Idx], Scale, D);
    end;
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
