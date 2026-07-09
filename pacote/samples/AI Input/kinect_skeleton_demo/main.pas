{===============================================================================
  Kinect Skeleton Demo
  Exibe video RGB e skeleton tracking do Kinect v1 usando o SDK 1.8.

  Projeto: https://github.com/marcelomaurin/CHATGPT
  Licenca: conforme a licenca do repositorio principal.
===============================================================================}
unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls, ComCtrls,
  Dialogs, fpjson, aibase, aikinect_types, aikinectsensor, aikinectcolor,
  aikinectskeleton;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    btnClose: TButton;
    btnExport: TButton;
    btnOpen: TButton;
    chkSeated: TCheckBox;
    chkShowVideo: TCheckBox;
    lblBodies: TLabel;
    lblSmooth: TLabel;
    lblStatus: TLabel;
    memLog: TMemo;
    pbView: TPaintBox;
    pnlControl: TPanel;
    pnlView: TPanel;
    tbSmooth: TTrackBar;
    tmrLog: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure pbViewPaint(Sender: TObject);
    procedure tmrLogTimer(Sender: TObject);

    procedure OnKinectConnect(Sender: TObject);
    procedure OnKinectDisconnect(Sender: TObject);
    procedure OnKinectError(Sender: TObject; const AError: string);
    procedure OnColorFrame(Sender: TObject; const AFrameFile: string);
    procedure OnSkeletonFrame(Sender: TObject; const ABodies: TAIKinectBodies);
  private
    FSensor: TAIKinectSensor;
    FColor: TAIKinectColorStream;
    FSkeleton: TAIKinectSkeleton;
    FVideoBmp: TBitmap;
    FBodies: TAIKinectBodies;
    FLoadFailCount: Integer;
    FOpening: Boolean;
    FBackendLogFile: string;
    FBackendLogPos: Int64;
    procedure Log(const AMsg: string);
    procedure LoadBackendLog;
    function JointName(AJoint: TAIKinectJointType): string;
    function StateName(AState: TAIKinectTrackState): string;
    function JointColor(AState: TAIKinectTrackState; ABase: TColor): TColor;
    procedure DrawBone(ACanvas: TCanvas; const ABody: TAIKinectBody;
      AJointA, AJointB: TAIKinectJointType; AScaleX, AScaleY: Double;
      ABase: TColor);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  Bones: array[0..18, 0..1] of TAIKinectJointType = (
    (kjHipCenter, kjSpine), (kjSpine, kjShoulderCenter),
    (kjShoulderCenter, kjHead), (kjShoulderCenter, kjShoulderLeft),
    (kjShoulderLeft, kjElbowLeft), (kjElbowLeft, kjWristLeft),
    (kjWristLeft, kjHandLeft), (kjShoulderCenter, kjShoulderRight),
    (kjShoulderRight, kjElbowRight), (kjElbowRight, kjWristRight),
    (kjWristRight, kjHandRight), (kjHipCenter, kjHipLeft),
    (kjHipLeft, kjKneeLeft), (kjKneeLeft, kjAnkleLeft),
    (kjAnkleLeft, kjFootLeft), (kjHipCenter, kjHipRight),
    (kjHipRight, kjKneeRight), (kjKneeRight, kjAnkleRight),
    (kjAnkleRight, kjFootRight));

  BodyColors: array[0..5] of TColor = (
    clLime, clAqua, clFuchsia, clYellow, clRed, clWhite);

  JointNames: array[TAIKinectJointType] of string = (
    'kjHipCenter', 'kjSpine', 'kjShoulderCenter', 'kjHead',
    'kjShoulderLeft', 'kjElbowLeft', 'kjWristLeft', 'kjHandLeft',
    'kjShoulderRight', 'kjElbowRight', 'kjWristRight', 'kjHandRight',
    'kjHipLeft', 'kjKneeLeft', 'kjAnkleLeft', 'kjFootLeft',
    'kjHipRight', 'kjKneeRight', 'kjAnkleRight', 'kjFootRight');

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FSensor := TAIKinectSensor.Create(Self);
  FSensor.Backend := kbKinectSDK10;
  FSensor.KinectModel := kmXbox360;
  FSensor.OnConnect := @OnKinectConnect;
  FSensor.OnDisconnect := @OnKinectDisconnect;
  FSensor.OnError := @OnKinectError;

  FColor := TAIKinectColorStream.Create(Self);
  FColor.Sensor := FSensor;
  FColor.OnFrame := @OnColorFrame;

  FSkeleton := TAIKinectSkeleton.Create(Self);
  FSkeleton.Sensor := FSensor;
  FSkeleton.OnSkeletonFrame := @OnSkeletonFrame;

  FVideoBmp := TBitmap.Create;
  SetLength(FBodies, 0);
  FBackendLogFile := IncludeTrailingPathDelimiter(GetTempDir) + 'aikinect_sdk10_backend.log';
  FBackendLogPos := 0;
  tmrLog.Enabled := True;
  memLog.Clear;
  chkSeated.Checked := True;
  Log('Demo iniciado. Modo sentado ativo por padrao. Conecte o Kinect e clique em Conectar.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FSkeleton) then
    FSkeleton.Active := False;
  if Assigned(FColor) then
    FColor.Active := False;
  if Assigned(FSensor) then
    FSensor.Close;
  FreeAndNil(FVideoBmp);
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if FOpening then Exit;
  FOpening := True;
  btnOpen.Enabled := False;
  try
    Log('Conectar solicitado.');
    FSensor.DeviceIndex := 0;
    FSensor.Backend := kbKinectSDK10;
    FSensor.KinectModel := kmXbox360;

    if not FSensor.Open then
    begin
      lblStatus.Caption := 'Erro';
      Log('Falha ao conectar: ' + FSensor.LastError);
      btnOpen.Enabled := True;
      Exit;
    end;

    if chkShowVideo.Checked then
    begin
      Log('Ativando video de fundo.');
      FColor.Active := True;
      if not FColor.Active then
        Log('Falha ao iniciar video: ' + FColor.LastError)
      else
        Log('Video ativo.');
    end;

    FSkeleton.SeatedMode := chkSeated.Checked;
    FSkeleton.SmoothFactor := tbSmooth.Position / 100;
    Log('Ativando skeleton.');
    FSkeleton.Active := True;
    if not FSkeleton.Active then
      Log('Falha ao iniciar skeleton: ' + FSkeleton.LastError)
    else
      Log('Skeleton ativo.');
  finally
    FOpening := False;
  end;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Log('Desconectar solicitado.');
  if Assigned(FSkeleton) then
    FSkeleton.Active := False;
  if Assigned(FColor) then
    FColor.Active := False;
  if Assigned(FSensor) then
    FSensor.Close;
  SetLength(FBodies, 0);
  lblBodies.Caption := 'Corpos: 0';
  pbView.Invalidate;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Root, BodyObj, JointObj: TJSONObject;
  BodyArray, JointArray: TJSONArray;
  BodyIndex: Integer;
  Joint: TAIKinectJointType;
  SL: TStringList;
begin
  if Length(FBodies) = 0 then
  begin
    Log('Nenhuma pose para exportar.');
    Exit;
  end;

  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Filter := 'JSON (*.json)|*.json|Todos os arquivos (*.*)|*.*';
    Dlg.DefaultExt := 'json';
    Dlg.InitialDir := ExtractFilePath(ParamStr(0));
    Dlg.FileName := 'pose_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.json';
    if not Dlg.Execute then Exit;

    Root := TJSONObject.Create;
    try
      Root.Add('createdAt', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
      BodyArray := TJSONArray.Create;
      Root.Add('bodies', BodyArray);

      for BodyIndex := 0 to Length(FBodies) - 1 do
      begin
        BodyObj := TJSONObject.Create;
        BodyObj.Add('trackingId', FBodies[BodyIndex].TrackingId);
        JointArray := TJSONArray.Create;
        BodyObj.Add('joints', JointArray);
        BodyArray.Add(BodyObj);

        for Joint := Low(TAIKinectJointType) to High(TAIKinectJointType) do
        begin
          JointObj := TJSONObject.Create;
          JointObj.Add('joint', JointName(Joint));
          JointObj.Add('x', FBodies[BodyIndex].Joints[Joint].X);
          JointObj.Add('y', FBodies[BodyIndex].Joints[Joint].Y);
          JointObj.Add('z', FBodies[BodyIndex].Joints[Joint].Z);
          JointObj.Add('screenX', FBodies[BodyIndex].Joints[Joint].ScreenX);
          JointObj.Add('screenY', FBodies[BodyIndex].Joints[Joint].ScreenY);
          JointObj.Add('state', StateName(FBodies[BodyIndex].Joints[Joint].State));
          JointArray.Add(JointObj);
        end;
      end;

      SL := TStringList.Create;
      try
        SL.Text := Root.FormatJSON;
        SL.SaveToFile(Dlg.FileName);
      finally
        SL.Free;
      end;
    finally
      Root.Free;
    end;

    Log('Pose exportada: ' + Dlg.FileName);
    Log('ToPoseLandmarks(0): ' + FSkeleton.ToPoseLandmarks(0));
  finally
    Dlg.Free;
  end;
end;

procedure TfrmMain.pbViewPaint(Sender: TObject);
var
  SX, SY: Double;
  BodyIndex, BoneIndex: Integer;
  Joint: TAIKinectJointType;
  R, X, Y: Integer;
  Base: TColor;
begin
  pbView.Canvas.Brush.Color := clBlack;
  pbView.Canvas.FillRect(0, 0, pbView.Width, pbView.Height);

  if chkShowVideo.Checked and (FVideoBmp.Width > 0) and (FVideoBmp.Height > 0) then
    pbView.Canvas.StretchDraw(Rect(0, 0, pbView.Width, pbView.Height), FVideoBmp);

  if (pbView.Width <= 0) or (pbView.Height <= 0) then Exit;
  SX := pbView.Width / 640;
  SY := pbView.Height / 480;

  for BodyIndex := 0 to Length(FBodies) - 1 do
  begin
    Base := BodyColors[BodyIndex mod Length(BodyColors)];

    if not FBodies[BodyIndex].Tracked then
    begin
      if FBodies[BodyIndex].Joints[kjHipCenter].ScreenX < 0 then Continue;
      X := Round(FBodies[BodyIndex].Joints[kjHipCenter].ScreenX * SX);
      Y := Round(FBodies[BodyIndex].Joints[kjHipCenter].ScreenY * SY);
      R := 24;
      pbView.Canvas.Pen.Style := psDash;
      pbView.Canvas.Pen.Width := 3;
      pbView.Canvas.Pen.Color := clYellow;
      pbView.Canvas.Brush.Style := bsClear;
      pbView.Canvas.Ellipse(X - R, Y - R, X + R, Y + R);
      pbView.Canvas.Pen.Style := psSolid;
      pbView.Canvas.Brush.Style := bsSolid;
      pbView.Canvas.Font.Color := clYellow;
      pbView.Canvas.TextOut(X + R + 6, Y - 8, 'detectado (sem pose)');
      Continue;
    end;

    for BoneIndex := Low(Bones) to High(Bones) do
      DrawBone(pbView.Canvas, FBodies[BodyIndex], Bones[BoneIndex, 0],
        Bones[BoneIndex, 1], SX, SY, Base);

    for Joint := Low(TAIKinectJointType) to High(TAIKinectJointType) do
    begin
      if FBodies[BodyIndex].Joints[Joint].ScreenX < 0 then Continue;
      X := Round(FBodies[BodyIndex].Joints[Joint].ScreenX * SX);
      Y := Round(FBodies[BodyIndex].Joints[Joint].ScreenY * SY);
      if Joint = kjHead then
        R := 12
      else
        R := 5;
      pbView.Canvas.Pen.Color := clBlack;
      pbView.Canvas.Pen.Width := 1;
      pbView.Canvas.Brush.Color := JointColor(FBodies[BodyIndex].Joints[Joint].State, Base);
      pbView.Canvas.Ellipse(X - R, Y - R, X + R, Y + R);
    end;
  end;
end;


procedure TfrmMain.tmrLogTimer(Sender: TObject);
begin
  LoadBackendLog;
end;
procedure TfrmMain.OnKinectConnect(Sender: TObject);
begin
  Log('Evento OnConnect.');
  lblStatus.Caption := 'Conectado';
  btnOpen.Enabled := False;
  btnClose.Enabled := True;
  chkSeated.Enabled := False;
  tbSmooth.Enabled := False;
end;

procedure TfrmMain.OnKinectDisconnect(Sender: TObject);
begin
  Log('Evento OnDisconnect.');
  lblStatus.Caption := 'Desconectado';
  btnOpen.Enabled := True;
  btnClose.Enabled := False;
  chkSeated.Enabled := True;
  tbSmooth.Enabled := True;
  FVideoBmp.SetSize(0, 0);
  SetLength(FBodies, 0);
  lblBodies.Caption := 'Corpos: 0';
  pbView.Invalidate;
end;

procedure TfrmMain.OnKinectError(Sender: TObject; const AError: string);
begin
  lblStatus.Caption := 'Erro';
  Log('Erro: ' + AError);
end;

procedure TfrmMain.OnColorFrame(Sender: TObject; const AFrameFile: string);
begin
  try
    FVideoBmp.LoadFromFile(AFrameFile);
    FLoadFailCount := 0;
    pbView.Invalidate;
  except
    on E: Exception do
    begin
      Inc(FLoadFailCount);
      if (FLoadFailCount mod 30) = 1 then
        Log('Falha ao carregar frame (' + IntToStr(FLoadFailCount) + '): ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.OnSkeletonFrame(Sender: TObject; const ABodies: TAIKinectBodies);
begin
  FBodies := ABodies;
  lblBodies.Caption := 'Corpos: ' + IntToStr(Length(FBodies));
  pbView.Invalidate;
end;

procedure TfrmMain.Log(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + AMsg);
  while memLog.Lines.Count > 500 do
    memLog.Lines.Delete(0);
  memLog.SelStart := Length(memLog.Text);
end;


procedure TfrmMain.LoadBackendLog;
var
  FS: TFileStream;
  Buffer: string;
  SL: TStringList;
  I: Integer;
  Line: string;
begin
  if (FBackendLogFile = '') or (not FileExists(FBackendLogFile)) then Exit;

  try
    FS := TFileStream.Create(FBackendLogFile, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size < FBackendLogPos then
        FBackendLogPos := 0;
      if FS.Size <= FBackendLogPos then Exit;

      FS.Position := FBackendLogPos;
      SetLength(Buffer, FS.Size - FBackendLogPos);
      if Length(Buffer) > 0 then
        FS.ReadBuffer(Buffer[1], Length(Buffer));
      FBackendLogPos := FS.Position;
    finally
      FS.Free;
    end;

    SL := TStringList.Create;
    try
      SL.Text := Buffer;
      for I := 0 to SL.Count - 1 do
      begin
        Line := Trim(SL[I]);
        if Line = '' then Continue;
        if (Pos('Skeleton', Line) > 0) or (Pos('NuiSkeleton', Line) > 0) or
           (Pos('NuiInitialize', Line) > 0) or (Pos('NuiShutdown', Line) > 0) then
          Log('[backend] ' + Line);
      end;
    finally
      SL.Free;
    end;
  except
    on E: Exception do
      Log('Falha ao ler log do backend: ' + E.Message);
  end;
end;
function TfrmMain.JointName(AJoint: TAIKinectJointType): string;
begin
  Result := JointNames[AJoint];
end;

function TfrmMain.StateName(AState: TAIKinectTrackState): string;
begin
  case AState of
    ktTracked: Result := 'tracked';
    ktInferred: Result := 'inferred';
    else Result := 'notTracked';
  end;
end;

function TfrmMain.JointColor(AState: TAIKinectTrackState; ABase: TColor): TColor;
begin
  case AState of
    ktTracked: Result := ABase;
    ktInferred: Result := clYellow;
    else Result := clGray;
  end;
end;

procedure TfrmMain.DrawBone(ACanvas: TCanvas; const ABody: TAIKinectBody;
  AJointA, AJointB: TAIKinectJointType; AScaleX, AScaleY: Double; ABase: TColor);
var
  A, B: TAIKinectJoint;
begin
  A := ABody.Joints[AJointA];
  B := ABody.Joints[AJointB];
  if (A.ScreenX < 0) or (B.ScreenX < 0) then Exit;
  if (A.State = ktNotTracked) or (B.State = ktNotTracked) then Exit;

  ACanvas.Pen.Width := 3;
  if (A.State = ktTracked) and (B.State = ktTracked) then
    ACanvas.Pen.Color := ABase
  else
    ACanvas.Pen.Color := clYellow;
  ACanvas.MoveTo(Round(A.ScreenX * AScaleX), Round(A.ScreenY * AScaleY));
  ACanvas.LineTo(Round(B.ScreenX * AScaleX), Round(B.ScreenY * AScaleY));
end;

end.