unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, aiarm_robot, aiarm_robotcontrol;

type
  { TfrmMain }
 
  TfrmMain = class(TForm)
  published
    { Componentes definidos no .lfm. Precisam estar em published para o
      streaming do Lazarus ({$R *.lfm}) conseguir ligar cada campo ao objeto. }
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
    LabelTargetTitle: TLabel;
    LabelX: TLabel;
    LabelY: TLabel;
    LabelZ: TLabel;
    LabelZoom: TLabel;
    FTargetX: TEdit;
    FTargetY: TEdit;
    FTargetZ: TEdit;
    FBtnSolve: TButton;
    FBtnReset: TButton;
    FBtnLoad: TButton;
    FBtnExport: TButton;
    FZoomTrack: TTrackBar;
    FModelCombo: TComboBox;
    FControl: TAI_ARM_RobotControl;
    FPosition: TAI_Arm_robotPosition;
    { Eventos referenciados pelo .lfm. Também precisam ser published. }
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SolveClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure ZoomChanged(Sender: TObject);
    procedure PositionSolved(Sender: TObject; const AX, AY, AZ: Double;
      const ASuccess: Boolean; const AError: string);
    procedure PositionFailed(Sender: TObject; const AX, AY, AZ: Double;
      const ASuccess: Boolean; const AError: string);
  private
    { Estado interno e handlers atribuidos apenas por codigo (@Metodo). }
    FUpdatingUI: Boolean;
    function ModelJsonPath: string;
    procedure ApplyModelVisualToViewer;
    procedure BuildUI;
    procedure BuildArm;
    procedure AddLog(const AMsg: string);
    procedure RefreshUI;
    procedure ModelChanged(Sender: TObject);
    function NormalizarDecimal(const S: string): string;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  { Tamanho, cor e caption ja vem do .lfm; aqui so garantimos a posicao
    e a fonte base do form. }
  Font.Name := 'Segoe UI';
  Font.Color := clWhite;
  Position := poScreenCenter;

  BuildUI;
  BuildArm;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FControl);
end;

procedure TfrmMain.BuildUI;
begin
  if FHeader <> nil then
  begin
    FHeader.BevelOuter := bvNone;
    FHeader.Color := $1C1C1C;
    FHeader.Font.Color := clWhite;
  end;

  if FTitle <> nil then
  begin
    FTitle.Font.Name := 'Segoe UI';
    FTitle.Font.Size := 18;
    FTitle.Font.Style := [fsBold];
    FTitle.Caption := 'AI_Arm_robot';
  end;

  if FSubtitle <> nil then
    FSubtitle.Caption := 'Cinematica 3D generica para braco robotico com 6 servos SG90';

  if FStatus <> nil then
    FStatus.Caption := 'Status: pronto';

  if FMain <> nil then
  begin
    FMain.BevelOuter := bvNone;
    FMain.Color := $151515;
  end;

  if FRightPanel <> nil then
  begin
    FRightPanel.BevelOuter := bvNone;
    FRightPanel.Color := $202020;
  end;

  if FViewer <> nil then
  begin
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
  end;

  if FTargetPanel <> nil then
  begin
    FTargetPanel.BevelOuter := bvNone;
    FTargetPanel.Color := $252525;
  end;

  if FJointsScroll <> nil then
  begin
    FJointsScroll.BorderStyle := bsNone;
    FJointsScroll.Color := $202020;
    FJointsScroll.VertScrollBar.Visible := True;
  end;

  if FMemo <> nil then
  begin
    FMemo.Color := $111111;
    FMemo.Font.Color := clSilver;
    FMemo.ScrollBars := ssVertical;
  end;

  if FTargetX <> nil then
    FTargetX.Text := '10';
  if FTargetY <> nil then
    FTargetY.Text := '0';
  if FTargetZ <> nil then
    FTargetZ.Text := '15';

  if FBtnSolve <> nil then
  begin
    FBtnSolve.Caption := 'Resolver IK';
    FBtnSolve.OnClick := @SolveClick;
  end;

  if FBtnReset <> nil then
  begin
    FBtnReset.Caption := 'Resetar';
    FBtnReset.OnClick := @ResetClick;
  end;

  if FBtnLoad <> nil then
  begin
    FBtnLoad.Caption := 'Recarregar JSON';
    FBtnLoad.OnClick := @LoadClick;
  end;

  if FBtnExport <> nil then
  begin
    FBtnExport.Caption := 'Exportar JSON';
    FBtnExport.OnClick := @ExportClick;
  end;

  if FZoomTrack <> nil then
  begin
    FZoomTrack.Min := 10;
    FZoomTrack.Max := 1000;
    FZoomTrack.Position := 50;
    FZoomTrack.Frequency := 25;
    FZoomTrack.OnChange := @ZoomChanged;
  end;
end;

function TfrmMain.ModelJsonPath: string;
var
  FileName: string;
begin
  if (FModelCombo <> nil) and (FModelCombo.ItemIndex >= 0) then
    FileName := FModelCombo.Items[FModelCombo.ItemIndex]
  else
    FileName := 'AI_Arm_robot.model.json';
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + FileName;
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
  ModelPath: string;
begin
  if FArm = nil then
    FArm := TAI_Arm_robot.Create(Self);

  if FControl <> nil then
  begin
    FControl.Arm := nil;
    FArm.OnChange := @ModelChanged;
    FControl.Arm := FArm;
  end
  else
    FArm.OnChange := @ModelChanged;

  if FPosition = nil then
  begin
    FPosition := TAI_Arm_robotPosition.Create(Self);
    FPosition.OnSolved := @PositionSolved;
    FPosition.OnFailed := @PositionFailed;
  end;
  FPosition.Arm := FArm;

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
    FArm.GraphicComponent := FViewer;
  finally
    FUpdatingUI := False;
  end;

  RefreshUI;
  AddLog('Sample AI_Arm_robot carregado com ' + IntToStr(FArm.JointCount) + ' eixos.');
  AddLog(FArm.ToSetupText);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(FMemo) then
    FMemo.Lines.Add(AMsg);
end;

procedure TfrmMain.RefreshUI;
var
  EndPos: TAIArmVector3;
begin
  if FArm = nil then Exit;

  FUpdatingUI := True;
  try
    EndPos := FArm.GetEndEffectorPosition;
    if Assigned(FStatus) then
      FStatus.Caption := Format('Status: EE (%.2f, %.2f, %.2f)', [EndPos.X, EndPos.Y, EndPos.Z]);
    if Assigned(FViewer) then
      FViewer.SyncScene;
  finally
    FUpdatingUI := False;
  end;
end;

function TfrmMain.NormalizarDecimal(const S: string): string;
begin
  Result := StringReplace(S, ',', '.', [rfReplaceAll]);
end;

procedure TfrmMain.SolveClick(Sender: TObject);
var
  X, Y, Z: Double;
  FS: TFormatSettings;
begin
  if (FArm = nil) or (FPosition = nil) then Exit;
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  X := StrToFloatDef(NormalizarDecimal(FTargetX.Text), FArm.TargetX, FS);
  Y := StrToFloatDef(NormalizarDecimal(FTargetY.Text), FArm.TargetY, FS);
  Z := StrToFloatDef(NormalizarDecimal(FTargetZ.Text), FArm.TargetZ, FS);

  FPosition.MoveTo(X, Y, Z);
end;

procedure TfrmMain.PositionSolved(Sender: TObject; const AX, AY, AZ: Double;
  const ASuccess: Boolean; const AError: string);
begin
  AddLog(Format('IK resolvida para alvo (%.2f, %.2f, %.2f).', [AX, AY, AZ]));
  RefreshUI;
end;

procedure TfrmMain.PositionFailed(Sender: TObject; const AX, AY, AZ: Double;
  const ASuccess: Boolean; const AError: string);
begin
  AddLog('IK nao convergiu: ' + AError);
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

end.
