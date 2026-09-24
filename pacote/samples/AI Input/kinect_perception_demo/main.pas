unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Math,
  aikinect_types, aikinectsensor, aikinectcolor, aikinectdepth,
  aikinectskeleton, aikinectperception;

type
  { TfrmMain }
  TfrmMain = class(TForm)
    lblKinectTitle: TLabel;
    lblBackend: TLabel;
    lblSimulation: TLabel;
    lblStateTitle: TLabel;
    lblPresenceTitle: TLabel;
    lblPresenceValue: TLabel;
    lblTrackingID: TLabel;
    lblDistTitle: TLabel;
    lblDistValue: TLabel;
    lblGestureTitle: TLabel;
    lblGestureValue: TLabel;
    lblConfidence: TLabel;
    lblEventsTitle: TLabel;
    lblJSONTitle: TLabel;

    pnlLeft: TPanel;
    pnlCenter: TPanel;
    pnlRight: TPanel;
    pnlPresenceCard: TPanel;
    pnlDistanceCard: TPanel;
    pnlGestureCard: TPanel;
    pnlSemanticJSON: TPanel;

    btnConnect: TButton;
    btnDisconnect: TButton;
    btnSimEnter: TButton;
    btnSimRaiseRight: TButton;
    btnSimRaiseLeft: TButton;
    btnSimBothHands: TButton;
    btnSimPointRight: TButton;
    btnSimOpenArms: TButton;
    btnSimMoveLeft: TButton;
    btnSimMoveFar: TButton;
    btnSimLeave: TButton;

    chkRenderRGB: TCheckBox;
    chkRenderSkeleton: TCheckBox;
    paintBox: TPaintBox;
    memJSON: TMemo;
    memEvents: TMemo;
    tmrUI: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnSimEnterClick(Sender: TObject);
    procedure btnSimRaiseRightClick(Sender: TObject);
    procedure btnSimRaiseLeftClick(Sender: TObject);
    procedure btnSimBothHandsClick(Sender: TObject);
    procedure btnSimPointRightClick(Sender: TObject);
    procedure btnSimOpenArmsClick(Sender: TObject);
    procedure btnSimMoveLeftClick(Sender: TObject);
    procedure btnSimMoveFarClick(Sender: TObject);
    procedure btnSimLeaveClick(Sender: TObject);
    procedure paintBoxPaint(Sender: TObject);
    procedure tmrUITimer(Sender: TObject);
  private
    FSensor: TAIKinectSensor;
    FColorStream: TAIKinectColorStream;
    FDepthStream: TAIKinectDepthStream;
    FSkeleton: TAIKinectSkeleton;
    FPerception: TAIKinectPerception;

    FCurrentBodies: TAIKinectBodies;
    FSimulatedBodies: TAIKinectBodies;
    FIsSimulating: Boolean;
    FLastJSON: string;

    procedure HandlePersonEntered(Sender: TObject; const APerson: TAIKinectPersonState);
    procedure HandlePersonUpdated(Sender: TObject; const APerson: TAIKinectPersonState);
    procedure HandlePersonLeft(Sender: TObject; ATrackingID: Integer);
    procedure HandleGesture(Sender: TObject; AGesture: TAIKinectGesture; ATrackingID: Integer; AConfidence: Single);
    procedure HandleSemanticEvent(Sender: TObject; const AEvent: TAIKinectSemanticEvent);
    procedure HandleSkeletonFrame(Sender: TObject; const ABodies: TAIKinectBodies);

    function MakeSimBody(ATrackingID: Integer; AX, AY, AZ: Single): TAIKinectBody;
    procedure LogEvent(const AMsg: string);
    procedure UpdateDashboardUI;
    procedure DrawSkeletonWireframe(ACanvas: TCanvas; const ABody: TAIKinectBody);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FSensor := TAIKinectSensor.Create(Self);
  FColorStream := TAIKinectColorStream.Create(Self);
  FDepthStream := TAIKinectDepthStream.Create(Self);
  FSkeleton := TAIKinectSkeleton.Create(Self);
  FPerception := TAIKinectPerception.Create(Self);

  FColorStream.Sensor := FSensor;
  FDepthStream.Sensor := FSensor;
  FSkeleton.Sensor := FSensor;

  FPerception.Sensor := FSensor;
  FPerception.Skeleton := FSkeleton;
  FPerception.Depth := FDepthStream;
  FPerception.Color := FColorStream;

  { Wire semantic events }
  FPerception.OnPersonEntered := @HandlePersonEntered;
  FPerception.OnPersonUpdated := @HandlePersonUpdated;
  FPerception.OnPersonLeft := @HandlePersonLeft;
  FPerception.OnGesture := @HandleGesture;
  FPerception.OnSemanticEvent := @HandleSemanticEvent;
  FSkeleton.OnSkeletonFrame := @HandleSkeletonFrame;

  lblBackend.Caption := 'Backend: ' + FSensor.BackendName;
  FIsSimulating := False;
  SetLength(FCurrentBodies, 0);
  LogEvent('[SISTEMA] TAIKinectPerception inicializado com sucesso.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FSkeleton) then
    FSkeleton.Active := False;
  if Assigned(FColorStream) then
    FColorStream.Active := False;
  if Assigned(FSensor) and FSensor.IsConnected then
    FSensor.Close;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
var
  DevList: TStringList;
begin
  DevList := FSensor.ListDevices;
  try
    if DevList.Count = 0 then
    begin
      LogEvent('[AVISO] Nenhum sensor Kinect v1 fisico detectado.');
      LogEvent('[DICA] Utilize os botoes do simulador para testar a percepcao.');
      Exit;
    end;
  finally
    DevList.Free;
  end;

  FSensor.DeviceIndex := 0;
  FSensor.Backend := kbKinectSDK10;
  FSensor.KinectModel := kmXbox360;

  if FSensor.Open then
  begin
    FColorStream.Active := chkRenderRGB.Checked;
    FSkeleton.Active := True;
    btnConnect.Enabled := False;
    btnDisconnect.Enabled := True;
    FIsSimulating := False;
    LogEvent('[SISTEMA] Kinect conectado e streams ativados.');
  end
  else
    LogEvent('[ERRO] Falha ao conectar ao sensor Kinect: ' + FSensor.LastError);
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  FSkeleton.Active := False;
  FColorStream.Active := False;
  FSensor.Close;
  btnConnect.Enabled := True;
  btnDisconnect.Enabled := False;
  LogEvent('[SISTEMA] Kinect desconectado.');
end;

function TfrmMain.MakeSimBody(ATrackingID: Integer; AX, AY, AZ: Single): TAIKinectBody;
var
  JT: TAIKinectJointType;
  CX, CY: Integer;
begin
  Result.TrackingId := ATrackingID;
  Result.Tracked := True;

  CX := paintBox.Width div 2;
  CY := paintBox.Height div 2;

  for JT := Low(TAIKinectJointType) to High(TAIKinectJointType) do
  begin
    Result.Joints[JT].JointType := JT;
    Result.Joints[JT].State := ktTracked;
    Result.Joints[JT].X := AX;
    Result.Joints[JT].Y := AY;
    Result.Joints[JT].Z := AZ;
    Result.Joints[JT].ScreenX := Round(CX + (AX * 200));
    Result.Joints[JT].ScreenY := Round(CY - (AY * 200));
  end;

  { Posicionamento anatomico em metros }
  Result.Joints[kjHead].Y := AY + 0.65;
  Result.Joints[kjShoulderCenter].Y := AY + 0.45;
  Result.Joints[kjSpine].Y := AY + 0.20;
  Result.Joints[kjHipCenter].Y := AY;

  Result.Joints[kjShoulderLeft].X := AX - 0.20;
  Result.Joints[kjShoulderLeft].Y := AY + 0.45;
  Result.Joints[kjElbowLeft].X := AX - 0.28;
  Result.Joints[kjElbowLeft].Y := AY + 0.22;
  Result.Joints[kjWristLeft].X := AX - 0.30;
  Result.Joints[kjWristLeft].Y := AY + 0.00;
  Result.Joints[kjHandLeft].X := AX - 0.32;
  Result.Joints[kjHandLeft].Y := AY - 0.05;

  Result.Joints[kjShoulderRight].X := AX + 0.20;
  Result.Joints[kjShoulderRight].Y := AY + 0.45;
  Result.Joints[kjElbowRight].X := AX + 0.28;
  Result.Joints[kjElbowRight].Y := AY + 0.22;
  Result.Joints[kjWristRight].X := AX + 0.30;
  Result.Joints[kjWristRight].Y := AY + 0.00;
  Result.Joints[kjHandRight].X := AX + 0.32;
  Result.Joints[kjHandRight].Y := AY - 0.05;

  Result.Joints[kjHipLeft].X := AX - 0.12;
  Result.Joints[kjHipLeft].Y := AY - 0.05;
  Result.Joints[kjKneeLeft].X := AX - 0.14;
  Result.Joints[kjKneeLeft].Y := AY - 0.45;
  Result.Joints[kjAnkleLeft].X := AX - 0.14;
  Result.Joints[kjAnkleLeft].Y := AY - 0.80;
  Result.Joints[kjFootLeft].X := AX - 0.14;
  Result.Joints[kjFootLeft].Y := AY - 0.85;

  Result.Joints[kjHipRight].X := AX + 0.12;
  Result.Joints[kjHipRight].Y := AY - 0.05;
  Result.Joints[kjKneeRight].X := AX + 0.14;
  Result.Joints[kjKneeRight].Y := AY - 0.45;
  Result.Joints[kjAnkleRight].X := AX + 0.14;
  Result.Joints[kjAnkleRight].Y := AY - 0.80;
  Result.Joints[kjFootRight].X := AX + 0.14;
  Result.Joints[kjFootRight].Y := AY - 0.85;

  { Recomputa coordenadas de tela para todos os joints }
  for JT := Low(TAIKinectJointType) to High(TAIKinectJointType) do
  begin
    Result.Joints[JT].ScreenX := Round(CX + (Result.Joints[JT].X * 220));
    Result.Joints[JT].ScreenY := Round(CY - (Result.Joints[JT].Y * 220));
  end;
end;

procedure TfrmMain.btnSimEnterClick(Sender: TObject);
var
  I: Integer;
begin
  FIsSimulating := True;
  SetLength(FSimulatedBodies, 1);
  FSimulatedBodies[0] := MakeSimBody(101, 0.0, 0.0, 1.8);
  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimRaiseRightClick(Sender: TObject);
var
  I: Integer;
begin
  if Length(FSimulatedBodies) = 0 then
    btnSimEnterClick(Sender);

  FSimulatedBodies[0].Joints[kjHandRight].Y := FSimulatedBodies[0].Joints[kjHead].Y + 0.10;
  FSimulatedBodies[0].Joints[kjWristRight].Y := FSimulatedBodies[0].Joints[kjHead].Y;
  FSimulatedBodies[0].Joints[kjElbowRight].Y := FSimulatedBodies[0].Joints[kjShoulderRight].Y + 0.15;
  FSimulatedBodies[0].Joints[kjHandRight].ScreenY := Round((paintBox.Height div 2) - (FSimulatedBodies[0].Joints[kjHandRight].Y * 220));

  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimRaiseLeftClick(Sender: TObject);
var
  I: Integer;
begin
  if Length(FSimulatedBodies) = 0 then
    btnSimEnterClick(Sender);

  { Baixa a direita }
  FSimulatedBodies[0].Joints[kjHandRight].Y := -0.05;
  { Levanta a esquerda }
  FSimulatedBodies[0].Joints[kjHandLeft].Y := FSimulatedBodies[0].Joints[kjHead].Y + 0.10;
  FSimulatedBodies[0].Joints[kjWristLeft].Y := FSimulatedBodies[0].Joints[kjHead].Y;
  FSimulatedBodies[0].Joints[kjElbowLeft].Y := FSimulatedBodies[0].Joints[kjShoulderLeft].Y + 0.15;

  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimBothHandsClick(Sender: TObject);
var
  I: Integer;
begin
  if Length(FSimulatedBodies) = 0 then
    btnSimEnterClick(Sender);

  FSimulatedBodies[0].Joints[kjHandRight].Y := FSimulatedBodies[0].Joints[kjHead].Y + 0.10;
  FSimulatedBodies[0].Joints[kjHandLeft].Y := FSimulatedBodies[0].Joints[kjHead].Y + 0.10;

  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimPointRightClick(Sender: TObject);
var
  I: Integer;
begin
  if Length(FSimulatedBodies) = 0 then
    btnSimEnterClick(Sender);

  { Braco direito esticado na horizontal para a direita }
  FSimulatedBodies[0].Joints[kjShoulderRight].X := 0.20;
  FSimulatedBodies[0].Joints[kjElbowRight].X := 0.45;
  FSimulatedBodies[0].Joints[kjElbowRight].Y := FSimulatedBodies[0].Joints[kjShoulderRight].Y;
  FSimulatedBodies[0].Joints[kjHandRight].X := 0.70;
  FSimulatedBodies[0].Joints[kjHandRight].Y := FSimulatedBodies[0].Joints[kjShoulderRight].Y;

  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimOpenArmsClick(Sender: TObject);
var
  I: Integer;
begin
  if Length(FSimulatedBodies) = 0 then
    btnSimEnterClick(Sender);

  FSimulatedBodies[0].Joints[kjHandLeft].X := -0.65;
  FSimulatedBodies[0].Joints[kjHandLeft].Y := FSimulatedBodies[0].Joints[kjShoulderLeft].Y;
  FSimulatedBodies[0].Joints[kjHandRight].X := 0.65;
  FSimulatedBodies[0].Joints[kjHandRight].Y := FSimulatedBodies[0].Joints[kjShoulderRight].Y;

  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimMoveLeftClick(Sender: TObject);
var
  I: Integer;
begin
  FSimulatedBodies[0] := MakeSimBody(101, -0.60, 0.0, 1.8);
  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimMoveFarClick(Sender: TObject);
var
  I: Integer;
begin
  { Distancia de 3.5m - fora da zona maxima padrao de 2.5m }
  FSimulatedBodies[0] := MakeSimBody(101, 0.0, 0.0, 3.5);
  for I := 1 to 3 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.btnSimLeaveClick(Sender: TObject);
var
  I: Integer;
begin
  SetLength(FSimulatedBodies, 0);
  for I := 1 to 6 do
    FPerception.FeedSimulatedSkeleton(FSimulatedBodies);
  FCurrentBodies := FSimulatedBodies;
  paintBox.Invalidate;
end;

procedure TfrmMain.HandlePersonEntered(Sender: TObject; const APerson: TAIKinectPersonState);
begin
  LogEvent(Format('[EVENTO] OnPersonEntered: ID=%d Dist=%.2fm Pos=%s',
    [APerson.TrackingID, APerson.DistanceMeters, APerson.PositionName]));
end;

procedure TfrmMain.HandlePersonUpdated(Sender: TObject; const APerson: TAIKinectPersonState);
begin
  { Atualizacao continua silenciosa, refletida no dashboard }
end;

procedure TfrmMain.HandlePersonLeft(Sender: TObject; ATrackingID: Integer);
begin
  LogEvent(Format('[EVENTO] OnPersonLeft: ID=%d', [ATrackingID]));
end;

procedure TfrmMain.HandleGesture(Sender: TObject; AGesture: TAIKinectGesture;
  ATrackingID: Integer; AConfidence: Single);
begin
  LogEvent(Format('[EVENTO] OnGesture: %s (ID=%d, Conf=%.0f%%)',
    [FPerception.GestureToString(AGesture), ATrackingID, AConfidence * 100]));
end;

procedure TfrmMain.HandleSemanticEvent(Sender: TObject; const AEvent: TAIKinectSemanticEvent);
begin
  LogEvent(Format('  >> Semantico: tipo=%s gesto=%s pos=%s',
    [AEvent.EventTypeName, AEvent.GestureName, AEvent.PositionName]));
end;

procedure TfrmMain.HandleSkeletonFrame(Sender: TObject; const ABodies: TAIKinectBodies);
begin
  if not FIsSimulating then
  begin
    FCurrentBodies := ABodies;
    paintBox.Invalidate;
  end;
end;

procedure TfrmMain.LogEvent(const AMsg: string);
begin
  memEvents.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' ' + AMsg);
  if memEvents.Lines.Count > 150 then
    memEvents.Lines.Delete(0);
end;

procedure TfrmMain.tmrUITimer(Sender: TObject);
begin
  UpdateDashboardUI;
end;

procedure TfrmMain.UpdateDashboardUI;
var
  JSONStr: string;
begin
  if FPerception.PersonPresent then
  begin
    lblPresenceValue.Caption := 'PRESENTE';
    lblPresenceValue.Font.Color := clLime;
    lblTrackingID.Caption := 'ID: #' + IntToStr(FPerception.ActiveTrackingID);

    lblDistValue.Caption := Format('%.2fm (%s)', [FPerception.DistanceMeters, FPerception.PositionName]);
    lblDistValue.Font.Color := clWhite;

    if FPerception.LastGesture <> kgNone then
    begin
      lblGestureValue.Caption := FPerception.GestureToString(FPerception.LastGesture);
      lblGestureValue.Font.Color := $00FFFF;
      lblConfidence.Caption := Format('Confianca: %.0f%%', [FPerception.GestureConfidence * 100]);
    end
    else
    begin
      lblGestureValue.Caption := 'Nenhum';
      lblGestureValue.Font.Color := clSilver;
      lblConfidence.Caption := 'Confianca: --';
    end;
  end
  else
  begin
    lblPresenceValue.Caption := 'AUSENTE';
    lblPresenceValue.Font.Color := clRed;
    lblTrackingID.Caption := 'ID: Nenhum';
    lblDistValue.Caption := '-- m';
    lblDistValue.Font.Color := clSilver;
    lblGestureValue.Caption := 'Nenhum';
    lblGestureValue.Font.Color := clSilver;
    lblConfidence.Caption := 'Confianca: 0%';
  end;

  JSONStr := FPerception.ToSemanticJSON;
  if JSONStr <> FLastJSON then
  begin
    FLastJSON := JSONStr;
    memJSON.Text := JSONStr;
  end;
end;

procedure TfrmMain.DrawSkeletonWireframe(ACanvas: TCanvas; const ABody: TAIKinectBody);
  procedure DrawBone(J1, J2: TAIKinectJointType; AColor: TColor);
  var
    P1, P2: TPoint;
  begin
    if (ABody.Joints[J1].State = ktNotTracked) or (ABody.Joints[J2].State = ktNotTracked) then
      Exit;
    P1.X := ABody.Joints[J1].ScreenX;
    P1.Y := ABody.Joints[J1].ScreenY;
    P2.X := ABody.Joints[J2].ScreenX;
    P2.Y := ABody.Joints[J2].ScreenY;
    ACanvas.Pen.Color := AColor;
    ACanvas.Pen.Width := 3;
    ACanvas.Line(P1, P2);
  end;

var
  JT: TAIKinectJointType;
  PX, PY: Integer;
begin
  { Tronco }
  DrawBone(kjHead, kjShoulderCenter, clYellow);
  DrawBone(kjShoulderCenter, kjSpine, clYellow);
  DrawBone(kjSpine, kjHipCenter, clYellow);

  { Braco esquerdo }
  DrawBone(kjShoulderCenter, kjShoulderLeft, clAqua);
  DrawBone(kjShoulderLeft, kjElbowLeft, clAqua);
  DrawBone(kjElbowLeft, kjWristLeft, clAqua);
  DrawBone(kjWristLeft, kjHandLeft, clAqua);

  { Braco direito }
  DrawBone(kjShoulderCenter, kjShoulderRight, clLime);
  DrawBone(kjShoulderRight, kjElbowRight, clLime);
  DrawBone(kjElbowRight, kjWristRight, clLime);
  DrawBone(kjWristRight, kjHandRight, clLime);

  { Pernas }
  DrawBone(kjHipCenter, kjHipLeft, clSkyBlue);
  DrawBone(kjHipLeft, kjKneeLeft, clSkyBlue);
  DrawBone(kjKneeLeft, kjAnkleLeft, clSkyBlue);
  DrawBone(kjAnkleLeft, kjFootLeft, clSkyBlue);

  DrawBone(kjHipCenter, kjHipRight, clSkyBlue);
  DrawBone(kjHipRight, kjKneeRight, clSkyBlue);
  DrawBone(kjKneeRight, kjAnkleRight, clSkyBlue);
  DrawBone(kjAnkleRight, kjFootRight, clSkyBlue);

  { Articulacoes }
  for JT := Low(TAIKinectJointType) to High(TAIKinectJointType) do
  begin
    if ABody.Joints[JT].State = ktNotTracked then Continue;
    PX := ABody.Joints[JT].ScreenX;
    PY := ABody.Joints[JT].ScreenY;
    if JT in [kjHandLeft, kjHandRight] then
    begin
      ACanvas.Brush.Color := clFuchsia;
      ACanvas.Pen.Color := clWhite;
      ACanvas.Ellipse(PX - 7, PY - 7, PX + 7, PY + 7);
    end
    else
    begin
      ACanvas.Brush.Color := clWhite;
      ACanvas.Pen.Color := clBlack;
      ACanvas.Ellipse(PX - 4, PY - 4, PX + 4, PY + 4);
    end;
  end;
end;

procedure TfrmMain.paintBoxPaint(Sender: TObject);
var
  I: Integer;
  CX, CY: Integer;
begin
  paintBox.Canvas.Brush.Color := $121212;
  paintBox.Canvas.FillRect(paintBox.ClientRect);

  CX := paintBox.Width div 2;
  CY := paintBox.Height div 2;

  { Grade de referencia espacial }
  paintBox.Canvas.Pen.Color := $282828;
  paintBox.Canvas.Pen.Width := 1;
  paintBox.Canvas.Line(CX, 0, CX, paintBox.Height);
  paintBox.Canvas.Line(0, CY, paintBox.Width, CY);

  { Zonas laterais }
  paintBox.Canvas.Font.Color := $555555;
  paintBox.Canvas.Font.Size := 9;
  paintBox.Canvas.TextOut(20, 20, 'ZONA ESQUERDA');
  paintBox.Canvas.TextOut(CX - 40, 20, 'ZONA CENTRO');
  paintBox.Canvas.TextOut(paintBox.Width - 110, 20, 'ZONA DIREITA');

  { Renderiza corpos detectados / simulados }
  if chkRenderSkeleton.Checked then
  begin
    for I := 0 to High(FCurrentBodies) do
    begin
      if FCurrentBodies[I].Tracked then
      begin
        DrawSkeletonWireframe(paintBox.Canvas, FCurrentBodies[I]);

        { Rótulo de ID e Distância acima da cabeça }
        paintBox.Canvas.Font.Color := clYellow;
        paintBox.Canvas.Font.Style := [fsBold];
        paintBox.Canvas.TextOut(FCurrentBodies[I].Joints[kjHead].ScreenX - 35,
                                FCurrentBodies[I].Joints[kjHead].ScreenY - 24,
                                Format('Corpo #%d', [FCurrentBodies[I].TrackingId]));
      end;
    end;
  end;

  { Se ausente, aviso no viewport }
  if not FPerception.PersonPresent then
  begin
    paintBox.Canvas.Font.Color := $444444;
    paintBox.Canvas.Font.Size := 14;
    paintBox.Canvas.Font.Style := [fsBold];
    paintBox.Canvas.TextOut(CX - 120, CY - 10, 'AGUARDANDO VISITANTE NA ZONA...');
  end;
end;

end.
