unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, aiarm_robot;

type
  TJointUI = record
    Panel: TPanel;
    Title: TLabel;
    AxisInfo: TLabel;
    Track: TTrackBar;
    Value: TLabel;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FArm: TAI_Arm_robot;
    FViewer: TAI_Arm_robotViewer;
    FHeader: TPanel;
    FMain: TPanel;
    FRightPanel: TPanel;
    FTargetPanel: TPanel;
    FJointsScroll: TScrollBox;
    FMemo: TMemo;
    FTitle: TLabel;
    FSubtitle: TLabel;
    FStatus: TLabel;
    FTargetX: TEdit;
    FTargetY: TEdit;
    FTargetZ: TEdit;
    FBtnSolve: TButton;
    FBtnReset: TButton;
    FBtnLoad: TButton;
    FBtnExport: TButton;
    FZoomTrack: TTrackBar;
    FUpdatingUI: Boolean;
    FJointUI: array of TJointUI;
    function ModelJsonPath: string;
    procedure ApplyModelVisualToViewer;
    procedure BuildUI;
    procedure BuildArm;
    procedure AddLog(const AMsg: string);
    procedure RefreshUI;
    procedure JointChanged(Sender: TObject);
    procedure SolveClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure ZoomChanged(Sender: TObject);
    procedure ModelChanged(Sender: TObject);
    procedure MakeJointRow(const AIndex: Integer; const AParent: TWinControl);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Color := $151515;
  Font.Name := 'Segoe UI';
  Font.Color := clWhite;
  Caption := 'AI_Arm_robot';
  Width := 1280;
  Height := 860;
  Position := poScreenCenter;

  BuildUI;
  BuildArm;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FArm);
end;

procedure TfrmMain.BuildUI;
begin
  FHeader := TPanel.Create(Self);
  FHeader.Parent := Self;
  FHeader.Align := alTop;
  FHeader.Height := 86;
  FHeader.BevelOuter := bvNone;
  FHeader.Color := $1C1C1C;
  FHeader.Font.Color := clWhite;

  FTitle := TLabel.Create(FHeader);
  FTitle.Parent := FHeader;
  FTitle.Left := 20;
  FTitle.Top := 12;
  FTitle.Font.Name := 'Segoe UI';
  FTitle.Font.Size := 18;
  FTitle.Font.Style := [fsBold];
  FTitle.Caption := 'AI_Arm_robot';

  FSubtitle := TLabel.Create(FHeader);
  FSubtitle.Parent := FHeader;
  FSubtitle.Left := 20;
  FSubtitle.Top := 44;
  FSubtitle.Caption := 'Cinematica 3D generica para braco robotico com 6 servos SG90';

  FStatus := TLabel.Create(FHeader);
  FStatus.Parent := FHeader;
  FStatus.Left := 20;
  FStatus.Top := 62;
  FStatus.Caption := 'Status: pronto';

  FMain := TPanel.Create(Self);
  FMain.Parent := Self;
  FMain.Align := alClient;
  FMain.BevelOuter := bvNone;
  FMain.Color := $151515;

  FRightPanel := TPanel.Create(FMain);
  FRightPanel.Parent := FMain;
  FRightPanel.Align := alRight;
  FRightPanel.Width := 430;
  FRightPanel.BevelOuter := bvNone;
  FRightPanel.Color := $202020;

  FViewer := TAI_Arm_robotViewer.Create(Self);
  FViewer.Parent := FMain;
  FViewer.Align := alClient;
  FViewer.BackgroundColor := $121212;
  FViewer.ArmColor := $36F2A5;
  FViewer.JointColor := $79D8FF;
  FViewer.GridColor := $2E2E2E;
  FViewer.BaseColor := $6F6F6F;
  FViewer.BaseHighlightColor := $D8D8D8;
  FViewer.BaseRadius := 20;
  FViewer.BaseHeight := 28;
  FViewer.LinkThickness := 13;
  FViewer.JointRadius := 9;
  FViewer.ShowBasePedestal := True;
  FViewer.ShowGrid := True;
  FViewer.ShowAxes := True;
  FViewer.ShowJointLabels := True;

  FTargetPanel := TPanel.Create(FRightPanel);
  FTargetPanel.Parent := FRightPanel;
  FTargetPanel.Align := alTop;
  FTargetPanel.Height := 210;
  FTargetPanel.BevelOuter := bvNone;
  FTargetPanel.Color := $252525;

  FJointsScroll := TScrollBox.Create(FRightPanel);
  FJointsScroll.Parent := FRightPanel;
  FJointsScroll.Align := alClient;
  FJointsScroll.BorderStyle := bsNone;
  FJointsScroll.Color := $202020;
  FJointsScroll.VertScrollBar.Visible := True;

  FMemo := TMemo.Create(FRightPanel);
  FMemo.Parent := FRightPanel;
  FMemo.Align := alBottom;
  FMemo.Height := 160;
  FMemo.Color := $111111;
  FMemo.Font.Color := clSilver;
  FMemo.ScrollBars := ssVertical;

  with TLabel.Create(FTargetPanel) do
  begin
    Parent := FTargetPanel;
    Left := 16;
    Top := 14;
    Font.Style := [fsBold];
    Caption := 'Alvo XYZ';
  end;

  with TLabel.Create(FTargetPanel) do
  begin
    Parent := FTargetPanel;
    Left := 16;
    Top := 48;
    Caption := 'X';
  end;
  FTargetX := TEdit.Create(FTargetPanel);
  FTargetX.Parent := FTargetPanel;
  FTargetX.SetBounds(40, 44, 70, 26);
  FTargetX.Text := '10';

  with TLabel.Create(FTargetPanel) do
  begin
    Parent := FTargetPanel;
    Left := 128;
    Top := 48;
    Caption := 'Y';
  end;
  FTargetY := TEdit.Create(FTargetPanel);
  FTargetY.Parent := FTargetPanel;
  FTargetY.SetBounds(152, 44, 70, 26);
  FTargetY.Text := '0';

  with TLabel.Create(FTargetPanel) do
  begin
    Parent := FTargetPanel;
    Left := 240;
    Top := 48;
    Caption := 'Z';
  end;
  FTargetZ := TEdit.Create(FTargetPanel);
  FTargetZ.Parent := FTargetPanel;
  FTargetZ.SetBounds(264, 44, 70, 26);
  FTargetZ.Text := '15';

  FBtnSolve := TButton.Create(FTargetPanel);
  FBtnSolve.Parent := FTargetPanel;
  FBtnSolve.SetBounds(16, 90, 110, 30);
  FBtnSolve.Caption := 'Resolver IK';
  FBtnSolve.OnClick := @SolveClick;

  FBtnReset := TButton.Create(FTargetPanel);
  FBtnReset.Parent := FTargetPanel;
  FBtnReset.SetBounds(136, 90, 110, 30);
  FBtnReset.Caption := 'Resetar';
  FBtnReset.OnClick := @ResetClick;

  FBtnLoad := TButton.Create(FTargetPanel);
  FBtnLoad.Parent := FTargetPanel;
  FBtnLoad.SetBounds(256, 90, 130, 30);
  FBtnLoad.Caption := 'Recarregar JSON';
  FBtnLoad.OnClick := @LoadClick;

  FBtnExport := TButton.Create(FTargetPanel);
  FBtnExport.Parent := FTargetPanel;
  FBtnExport.SetBounds(16, 126, 150, 30);
  FBtnExport.Caption := 'Exportar JSON';
  FBtnExport.OnClick := @ExportClick;

  with TLabel.Create(FTargetPanel) do
  begin
    Parent := FTargetPanel;
    Left := 184;
    Top := 136;
    Caption := 'Zoom:';
  end;

  FZoomTrack := TTrackBar.Create(FTargetPanel);
  FZoomTrack.Parent := FTargetPanel;
  FZoomTrack.SetBounds(230, 126, 160, 42);
  FZoomTrack.Min := 10;
  FZoomTrack.Max := 1000;
  FZoomTrack.Position := 50;
  FZoomTrack.Frequency := 25;
  FZoomTrack.OnChange := @ZoomChanged;
end;

function TfrmMain.ModelJsonPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'AI_Arm_robot.model.json';
end;

procedure TfrmMain.ApplyModelVisualToViewer;
begin
  if (FArm = nil) or (FViewer = nil) then Exit;

  FViewer.BackgroundColor := FArm.ViewBackgroundColor;
  FViewer.ArmColor := FArm.ViewArmColor;
  FViewer.JointColor := FArm.ViewJointColor;
  FViewer.GridColor := FArm.ViewGridColor;
  FViewer.BaseColor := FArm.ViewBaseColor;
  FViewer.BaseHighlightColor := FArm.ViewBaseHighlightColor;
  FViewer.ShowGrid := FArm.ViewShowGrid;
  FViewer.ShowJointLabels := FArm.ViewShowJointLabels;
  FViewer.ShowAxes := FArm.ViewShowAxes;
  FViewer.AutoFit := FArm.ViewAutoFit;
  FViewer.Scale := FArm.ViewScale;
  FViewer.AzimuthDeg := FArm.ViewAzimuthDeg;
  FViewer.ElevationDeg := FArm.ViewElevationDeg;
  FViewer.ShowBasePedestal := FArm.ViewShowBasePedestal;
  FViewer.BaseRadius := FArm.ViewBaseRadius;
  FViewer.BaseInnerRadius := FArm.ViewBaseInnerRadius;
  FViewer.BaseHeight := FArm.ViewBaseHeight;
  FViewer.LinkThickness := FArm.ViewLinkThickness;
  FViewer.JointRadius := FArm.ViewJointRadius;
  FViewer.GuideSize := FArm.ViewGuideSize;
  FViewer.CameraX := FArm.ViewCameraX;
  FViewer.CameraY := FArm.ViewCameraY;
  FViewer.CameraZ := FArm.ViewCameraZ;
  FViewer.CameraFocalLength := FArm.ViewCameraFocalLength;
  FViewer.CameraDepthOfView := FArm.ViewCameraDepthOfView;
  FViewer.LightX := FArm.ViewLightX;
  FViewer.LightY := FArm.ViewLightY;
  FViewer.LightZ := FArm.ViewLightZ;
  FViewer.ActorInterval := FArm.ViewActorInterval;
  FViewer.ModelStyle := FArm.ViewModelStyle;
  FViewer.PrintedColor := FArm.ViewPrintedColor;
  FViewer.ServoColor := FArm.ViewServoColor;
  FViewer.MetalColor := FArm.ViewMetalColor;
  FViewer.LinkWidth := FArm.ViewLinkWidth;
  FViewer.LinkDepth := FArm.ViewLinkDepth;
  FViewer.LinkSpacing := FArm.ViewLinkSpacing;
  FViewer.ServoWidth := FArm.ViewServoWidth;
  FViewer.ServoHeight := FArm.ViewServoHeight;
  FViewer.ServoDepth := FArm.ViewServoDepth;
  FViewer.GripperWidth := FArm.ViewGripperWidth;
  FViewer.GripperLength := FArm.ViewGripperLength;
  if Assigned(FZoomTrack) then
    FZoomTrack.Position := EnsureRange(Round(FArm.ViewCameraFocalLength),
      FZoomTrack.Min, FZoomTrack.Max);
end;

procedure TfrmMain.BuildArm;
var
  I: Integer;
  ModelPath: string;
begin
  FreeAndNil(FArm);
  FArm := TAI_Arm_robot.Create(Self);
  FArm.OnChange := @ModelChanged;
  FUpdatingUI := True;
  try
    ModelPath := ModelJsonPath;
    if FileExists(ModelPath) then
    begin
      try
        FArm.LoadFromJSONFile(ModelPath);
      except
        on E: Exception do
        begin
          AddLog('Falha ao ler o JSON do modelo: ' + E.Message);
          FArm.LoadSixAxisSample;
        end;
      end;
    end
    else
    begin
      FArm.LoadSixAxisSample;
      try
        FArm.SaveToJSONFile(ModelPath);
      except
        on E: Exception do
          AddLog('Nao foi possivel criar o JSON padrao: ' + E.Message);
      end;
    end;
    FArm.UpdatePromptFromJoints;
    ApplyModelVisualToViewer;
    FViewer.Arm := FArm;

    SetLength(FJointUI, FArm.JointCount);
    for I := 0 to FArm.JointCount - 1 do
      MakeJointRow(I, FJointsScroll);
  finally
    FUpdatingUI := False;
  end;

  RefreshUI;
  AddLog('Sample AI_Arm_robot carregado com 6 eixos.');
  AddLog(FArm.ToSetupText);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(FMemo) then
    FMemo.Lines.Add(AMsg);
end;

procedure TfrmMain.RefreshUI;
var
  I: Integer;
  Joint: TAI_Arm_robotJoint;
  EndPos: TAIArmVector3;
begin
  if FArm = nil then Exit;

  FUpdatingUI := True;
  try
    for I := 0 to FArm.JointCount - 1 do
    begin
      Joint := FArm.Joints[I];
      FJointUI[I].Track.Min := Round(Joint.MinAngleDeg);
      FJointUI[I].Track.Max := Round(Joint.MaxAngleDeg);
      FJointUI[I].Track.Position := Round(Joint.AngleDeg);
      if SameText(Joint.JointType, 'prismatic') or
         SameText(Joint.JointType, 'linear') or
         SameText(Joint.JointType, 'prismatica') then
        FJointUI[I].Value.Caption := Format('%.1f cm', [Joint.Value])
      else
        FJointUI[I].Value.Caption := Format('%.1f deg', [Joint.Value]);
    end;
    EndPos := FArm.GetEndEffectorPosition;
    FStatus.Caption := Format('Status: EE (%.2f, %.2f, %.2f)', [EndPos.X, EndPos.Y, EndPos.Z]);
    FViewer.SyncScene;
  finally
    FUpdatingUI := False;
  end;
end;

procedure TfrmMain.JointChanged(Sender: TObject);
var
  Idx: Integer;
  Track: TTrackBar;
begin
  if FUpdatingUI or (FArm = nil) then Exit;
  if not (Sender is TTrackBar) then Exit;

  Track := TTrackBar(Sender);
  Idx := Track.Tag;
  if (Idx < 0) or (Idx >= FArm.JointCount) then Exit;

  FArm.Joints[Idx].AngleDeg := Track.Position;
  RefreshUI;
end;

procedure TfrmMain.SolveClick(Sender: TObject);
var
  X, Y, Z: Double;
begin
  if FArm = nil then Exit;
  X := StrToFloatDef(FTargetX.Text, FArm.TargetX);
  Y := StrToFloatDef(FTargetY.Text, FArm.TargetY);
  Z := StrToFloatDef(FTargetZ.Text, FArm.TargetZ);
  if FArm.SolveInverseKinematics(X, Y, Z) then
    AddLog(Format('IK resolvida para alvo (%.2f, %.2f, %.2f).', [X, Y, Z]))
  else
    AddLog('IK nao convergiu: ' + FArm.LastError);
  RefreshUI;
end;

procedure TfrmMain.ResetClick(Sender: TObject);
begin
  if FArm = nil then Exit;
  FArm.ResetAngles;
  AddLog('Angulos reiniciados para os defaults.');
  RefreshUI;
end;

procedure TfrmMain.LoadClick(Sender: TObject);
begin
  BuildArm;
  AddLog('Modelo recarregado a partir do JSON.');
  AddLog(ModelJsonPath);
end;

procedure TfrmMain.ExportClick(Sender: TObject);
var
  ModelPath: string;
begin
  if FArm = nil then Exit;
  ModelPath := ModelJsonPath;
  try
    FArm.SaveToJSONFile(ModelPath);
    AddLog('Modelo exportado para JSON.');
    AddLog(ModelPath);
  except
    on E: Exception do
      AddLog('Falha ao exportar JSON: ' + E.Message);
  end;
end;

procedure TfrmMain.ZoomChanged(Sender: TObject);
begin
  if FUpdatingUI or not Assigned(FViewer) then Exit;
  FViewer.CameraFocalLength := FZoomTrack.Position;
end;

procedure TfrmMain.ModelChanged(Sender: TObject);
begin
  if FUpdatingUI then Exit;
  RefreshUI;
end;

procedure TfrmMain.MakeJointRow(const AIndex: Integer; const AParent: TWinControl);
var
  P: TPanel;
  T: TLabel;
  A: TLabel;
  V: TLabel;
  TB: TTrackBar;
  Joint: TAI_Arm_robotJoint;
  TopPos: Integer;
begin
  Joint := FArm.Joints[AIndex];
  TopPos := AIndex * 92;

  P := TPanel.Create(AParent);
  P.Parent := AParent;
  P.SetBounds(8, TopPos + 8, Max(320, FRightPanel.Width - 40), 84);
  P.BevelOuter := bvNone;
  P.Color := $262626;

  T := TLabel.Create(P);
  T.Parent := P;
  T.Left := 12;
  T.Top := 8;
  T.Font.Style := [fsBold];
  if Pos(IntToStr(AIndex) + ' - ', Joint.Name) = 1 then
    T.Caption := 'Eixo ' + Joint.Name
  else
    T.Caption := Format('Eixo %d - %s', [AIndex, Joint.Name]);

  A := TLabel.Create(P);
  A.Parent := P;
  A.Left := 12;
  A.Top := 28;
  A.Font.Color := clSilver;
  if SameText(Joint.JointType, 'prismatic') or
     SameText(Joint.JointType, 'linear') or
     SameText(Joint.JointType, 'prismatica') then
    A.Caption := Format('movimento vertical Y: sobe/desce  len=%.2f', [Joint.Length])
  else
    A.Caption := Format('direcao=(%.0f, %.0f, %.0f)  rot=(%.0f, %.0f, %.0f)  len=%.2f',
      [Joint.DirectionX, Joint.DirectionY, Joint.DirectionZ,
       Joint.RotationAxisX, Joint.RotationAxisY, Joint.RotationAxisZ,
       Joint.Length]);

  V := TLabel.Create(P);
  V.Parent := P;
  V.Left := 250;
  V.Top := 8;
  V.Font.Color := clAqua;
  if SameText(Joint.JointType, 'prismatic') or
     SameText(Joint.JointType, 'linear') or
     SameText(Joint.JointType, 'prismatica') then
    V.Caption := Format('%.1f cm', [Joint.Value])
  else
    V.Caption := Format('%.1f deg', [Joint.Value]);

  TB := TTrackBar.Create(P);
  TB.Parent := P;
  TB.SetBounds(8, 48, P.Width - 16, 30);
  TB.Min := Round(Joint.MinAngleDeg);
  TB.Max := Round(Joint.MaxAngleDeg);
  TB.Position := Round(Joint.AngleDeg);
  TB.Frequency := 5;
  TB.PageSize := 5;
  TB.Tag := AIndex;
  TB.OnChange := @JointChanged;
  TB.Enabled := not Joint.IsBase;

  FJointUI[AIndex].Panel := P;
  FJointUI[AIndex].Title := T;
  FJointUI[AIndex].AxisInfo := A;
  FJointUI[AIndex].Track := TB;
  FJointUI[AIndex].Value := V;
end;

end.
