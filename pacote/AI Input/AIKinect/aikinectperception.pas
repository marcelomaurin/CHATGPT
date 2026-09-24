unit aikinectperception;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpjson, jsonparser,
  aibase, aikinect_types, aikinectsensor, aikinectskeleton, aikinectdepth, aikinectcolor;

type
  { Enums semânticos de percepção e interação }
  TAIKinectGesture = (
    kgNone,
    kgRaiseLeftHand,
    kgRaiseRightHand,
    kgRaiseBothHands,
    kgPointLeft,
    kgPointRight,
    kgPointCenter,
    kgWave,
    kgOpenArms
  );

  TAIKinectPersonPosition = (
    kppUnknown,
    kppLeft,
    kppCenter,
    kppRight
  );

  TAIKinectSemanticEventType = (
    ksePersonEntered,
    ksePersonUpdated,
    ksePersonLeft,
    kseGestureDetected
  );

  { Estado resumido e semântico de uma pessoa rastreada }
  TAIKinectPersonState = record
    TrackingID         : Integer;
    Present            : Boolean;
    Tracked            : Boolean;
    X, Y, Z            : Single;             // Metros no espaço do sensor
    DistanceMeters     : Single;
    ScreenX, ScreenY   : Integer;            // Coordenadas projetadas 2D (cabeça/corpo)
    Position           : TAIKinectPersonPosition;
    PositionName       : string;             // 'left', 'center', 'right'
    LastSeenTick       : QWord;
    StableFrameCount   : Integer;
    Confidence         : Single;
    CurrentGesture     : TAIKinectGesture;
    GestureConfidence  : Single;
    RightHandRaised    : Boolean;
    LeftHandRaised     : Boolean;
  end;

  { Evento semântico compacto para o orquestrador }
  TAIKinectSemanticEvent = record
    EventType          : TAIKinectSemanticEventType;
    EventTypeName      : string;
    TrackingID         : Integer;
    Gesture            : TAIKinectGesture;
    GestureName        : string;
    DistanceMeters     : Single;
    PositionName       : string;
    Confidence         : Single;
    TimestampMS        : Int64;
  end;

  { Assinaturas de eventos }
  TAIKinectPersonEvent   = procedure(Sender: TObject; const APerson: TAIKinectPersonState) of object;
  TAIKinectPersonLeftEvent = procedure(Sender: TObject; ATrackingID: Integer) of object;
  TAIKinectGestureEvent  = procedure(Sender: TObject; AGesture: TAIKinectGesture;
                             ATrackingID: Integer; AConfidence: Single) of object;
  TAIKinectSemanticNotifyEvent = procedure(Sender: TObject; const AEvent: TAIKinectSemanticEvent) of object;

  { Histórico temporal para filtragem e detecção de gestos (aceno / estabilidade) }
  TBodyHistoryItem = record
    TimestampTick : QWord;
    HandRightX    : Single;
    HandRightY    : Single;
    HandLeftX     : Single;
    HandLeftY     : Single;
  end;

  TBodyTrackingHistory = record
    TrackingID    : Integer;
    History       : array[0..9] of TBodyHistoryItem;
    HistoryCount  : Integer;
    HistoryIndex  : Integer;
    LastGesture   : TAIKinectGesture;
    LastGestureTick: QWord;
  end;

  { TAIKinectPerception }
  TAIKinectPerception = class(TAIBaseComponent)
  private
    FSensor          : TAIKinectSensor;
    FSkeleton        : TAIKinectSkeleton;
    FDepth           : TAIKinectDepthStream;
    FColor           : TAIKinectColorStream;

    FMinDistance     : Double;
    FMaxDistance     : Double;
    FGestureCooldownMS: Integer;
    FRequiredFrames  : Integer;
    FExitTimeoutMS   : Integer;

    FActiveTrackingID: Integer;
    FPersonPresent   : Boolean;
    FPersonCount     : Integer;
    FDistanceMeters  : Double;
    FPositionName    : string;
    FLastGesture     : TAIKinectGesture;
    FGestureConfidence: Double;

    { Rastreamento interno dos corpos }
    FPersons         : array of TAIKinectPersonState;
    FHistories       : array of TBodyTrackingHistory;
    FSimulatedBodies : TAIKinectBodies;

    { Eventos }
    FOnPersonEntered : TAIKinectPersonEvent;
    FOnPersonUpdated : TAIKinectPersonEvent;
    FOnPersonLeft    : TAIKinectPersonLeftEvent;
    FOnGesture       : TAIKinectGestureEvent;
    FOnSemanticEvent : TAIKinectSemanticNotifyEvent;

    procedure HandleSkeletonFrame(Sender: TObject; const ABodies: TAIKinectBodies);
    function  FindPersonIndex(ATrackingID: Integer): Integer;
    function  FindOrCreateHistory(ATrackingID: Integer): Integer;
    procedure CleanupInactivePersons(ACurrentTick: QWord);
    procedure ClassifyGestures(var APerson: TAIKinectPersonState; const ABody: TAIKinectBody;
                AHistoryIdx: Integer; ACurrentTick: QWord);
    function  EvaluateWaveGesture(const AHistory: TBodyTrackingHistory; ARight: Boolean): Boolean;
    procedure DispatchSemanticEvent(AEventType: TAIKinectSemanticEventType;
                const APerson: TAIKinectPersonState; AGesture: TAIKinectGesture);
    function  GetGestureName: string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Processamento manual ou simulado }
    procedure ProcessBodies(const ABodies: TAIKinectBodies);
    procedure FeedSimulatedSkeleton(const ABodies: TAIKinectBodies);
    function  LoadSimulatedPoseFromJSON(const AJSON: string): Boolean;

    { Exportação semântica para LLM / Orchestrator }
    function  ToSemanticJSON: string;
    function  GestureToString(AGesture: TAIKinectGesture): string;
    function  PositionToString(APos: TAIKinectPersonPosition): string;

    property PersonPresent    : Boolean              read FPersonPresent;
    property PersonCount      : Integer              read FPersonCount;
    property ActiveTrackingID : Integer              read FActiveTrackingID;
    property DistanceMeters   : Double               read FDistanceMeters;
    property Position         : string               read FPositionName;
    property PositionName     : string               read FPositionName;
    property LastGesture      : TAIKinectGesture     read FLastGesture;
    property GestureName      : string               read GetGestureName;
    property GestureConfidence: Double               read FGestureConfidence;
  published
    property Sensor           : TAIKinectSensor      read FSensor write FSensor;
    property Skeleton         : TAIKinectSkeleton    read FSkeleton write FSkeleton;
    property Depth            : TAIKinectDepthStream read FDepth write FDepth;
    property Color            : TAIKinectColorStream read FColor write FColor;

    property MinDistanceMeters: Double               read FMinDistance write FMinDistance;
    property MaxDistanceMeters: Double               read FMaxDistance write FMaxDistance;
    property GestureCooldownMS: Integer              read FGestureCooldownMS write FGestureCooldownMS default 1500;
    property RequiredFramesForEntry: Integer         read FRequiredFrames write FRequiredFrames default 3;
    property ExitTimeoutMS    : Integer              read FExitTimeoutMS write FExitTimeoutMS default 2000;

    property OnPersonEntered  : TAIKinectPersonEvent read FOnPersonEntered write FOnPersonEntered;
    property OnPersonUpdated  : TAIKinectPersonEvent read FOnPersonUpdated write FOnPersonUpdated;
    property OnPersonLeft     : TAIKinectPersonLeftEvent read FOnPersonLeft write FOnPersonLeft;
    property OnGesture        : TAIKinectGestureEvent read FOnGesture write FOnGesture;
    property OnSemanticEvent  : TAIKinectSemanticNotifyEvent read FOnSemanticEvent write FOnSemanticEvent;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIKinectPerception]);
end;

{ TAIKinectPerception }

constructor TAIKinectPerception.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Transforms raw Kinect sensor data (Skeleton, Depth, Color) into ' +
    'semantic perception events (presence, distance, lateral position, gestures: ' +
    'pointing, raised hands, wave) for the AI conversation orchestrator.';

  FSensor := nil;
  FSkeleton := nil;
  FDepth := nil;
  FColor := nil;

  FMinDistance := 0.8;
  FMaxDistance := 3.5;
  FGestureCooldownMS := 1500;
  FRequiredFrames := 3;
  FExitTimeoutMS := 2000;

  FActiveTrackingID := 0;
  FPersonPresent := False;
  FPersonCount := 0;
  FDistanceMeters := 0.0;
  FPositionName := 'none';
  FLastGesture := kgNone;
  FGestureConfidence := 0.0;

  SetLength(FPersons, 0);
  SetLength(FHistories, 0);
  SetLength(FSimulatedBodies, 0);
end;

destructor TAIKinectPerception.Destroy;
begin
  if Assigned(FSkeleton) and (FSkeleton.OnSkeletonFrame = @HandleSkeletonFrame) then
    FSkeleton.OnSkeletonFrame := nil;
  SetLength(FPersons, 0);
  SetLength(FHistories, 0);
  SetLength(FSimulatedBodies, 0);
  inherited Destroy;
end;

function TAIKinectPerception.GetGestureName: string;
begin
  Result := GestureToString(FLastGesture);
end;

procedure TAIKinectPerception.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FSensor then FSensor := nil;
    if AComponent = FSkeleton then
    begin
      FSkeleton := nil;
    end;
    if AComponent = FDepth then FDepth := nil;
    if AComponent = FColor then FColor := nil;
  end;
end;

function TAIKinectPerception.GestureToString(AGesture: TAIKinectGesture): string;
begin
  case AGesture of
    kgRaiseLeftHand  : Result := 'raise_left_hand';
    kgRaiseRightHand : Result := 'raise_right_hand';
    kgRaiseBothHands : Result := 'raise_both_hands';
    kgPointLeft      : Result := 'point_left';
    kgPointRight     : Result := 'point_right';
    kgPointCenter    : Result := 'point_center';
    kgWave           : Result := 'wave';
    kgOpenArms       : Result := 'open_arms';
    else Result := 'none';
  end;
end;

function TAIKinectPerception.PositionToString(APos: TAIKinectPersonPosition): string;
begin
  case APos of
    kppLeft   : Result := 'left';
    kppCenter : Result := 'center';
    kppRight  : Result := 'right';
    else Result := 'unknown';
  end;
end;

function TAIKinectPerception.FindPersonIndex(ATrackingID: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to Length(FPersons) - 1 do
    if FPersons[I].TrackingID = ATrackingID then
      Exit(I);
  Result := -1;
end;

function TAIKinectPerception.FindOrCreateHistory(ATrackingID: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to Length(FHistories) - 1 do
    if FHistories[I].TrackingID = ATrackingID then
      Exit(I);

  I := Length(FHistories);
  SetLength(FHistories, I + 1);
  FHistories[I].TrackingID := ATrackingID;
  FHistories[I].HistoryCount := 0;
  FHistories[I].HistoryIndex := 0;
  FHistories[I].LastGesture := kgNone;
  FHistories[I].LastGestureTick := 0;
  Result := I;
end;

function TAIKinectPerception.EvaluateWaveGesture(const AHistory: TBodyTrackingHistory; ARight: Boolean): Boolean;
var
  I, Idx, PrevIdx: Integer;
  SignChanges: Integer;
  LastDiff, Diff: Single;
begin
  Result := False;
  if AHistory.HistoryCount < 6 then Exit;

  SignChanges := 0;
  LastDiff := 0;

  for I := 1 to AHistory.HistoryCount - 1 do
  begin
    Idx := (AHistory.HistoryIndex - I + 10) mod 10;
    PrevIdx := (AHistory.HistoryIndex - I - 1 + 10) mod 10;

    if ARight then
      Diff := AHistory.History[Idx].HandRightX - AHistory.History[PrevIdx].HandRightX
    else
      Diff := AHistory.History[Idx].HandLeftX - AHistory.History[PrevIdx].HandLeftX;

    if Abs(Diff) > 0.04 then // Movimento significativo
    begin
      if (LastDiff <> 0) and ((Diff > 0) <> (LastDiff > 0)) then
        Inc(SignChanges);
      LastDiff := Diff;
    end;
  end;

  Result := SignChanges >= 2;
end;

procedure TAIKinectPerception.ClassifyGestures(var APerson: TAIKinectPersonState;
  const ABody: TAIKinectBody; AHistoryIdx: Integer; ACurrentTick: QWord);
var
  Head, Hip, Spine, ShoulderL, ShoulderR, ElbowL, ElbowR, HandLeft, HandRight: TAIKinectJoint;
  ArmR_DX, ArmR_DY, ArmR_DZ: Single;
  ArmL_DX, ArmL_DY, ArmL_DZ: Single;
  ArmR_Len, ArmL_Len: Single;
  HistItem: TBodyHistoryItem;
  CooldownPassed: Boolean;
begin
  APerson.CurrentGesture := kgNone;
  APerson.GestureConfidence := 0.0;
  APerson.RightHandRaised := False;
  APerson.LeftHandRaised := False;

  if not ABody.Tracked then Exit;

  Head := ABody.Joints[kjHead];
  Hip := ABody.Joints[kjHipCenter];
  Spine := ABody.Joints[kjSpine];
  ShoulderL := ABody.Joints[kjShoulderLeft];
  ShoulderR := ABody.Joints[kjShoulderRight];
  ElbowL := ABody.Joints[kjElbowLeft];
  ElbowR := ABody.Joints[kjElbowRight];
  HandLeft := ABody.Joints[kjHandLeft];
  HandRight := ABody.Joints[kjHandRight];

  { Atualiza histórico de posições das mãos }
  HistItem.TimestampTick := ACurrentTick;
  HistItem.HandRightX := HandRight.X;
  HistItem.HandRightY := HandRight.Y;
  HistItem.HandLeftX := HandLeft.X;
  HistItem.HandLeftY := HandLeft.Y;

  FHistories[AHistoryIdx].HistoryIndex := (FHistories[AHistoryIdx].HistoryIndex + 1) mod 10;
  FHistories[AHistoryIdx].History[FHistories[AHistoryIdx].HistoryIndex] := HistItem;
  if FHistories[AHistoryIdx].HistoryCount < 10 then
    Inc(FHistories[AHistoryIdx].HistoryCount);

  CooldownPassed := (ACurrentTick - FHistories[AHistoryIdx].LastGestureTick) >= QWord(FGestureCooldownMS);

  { 1. Detecção de Mão Levantada (Y é positivo para cima) }
  if (HandRight.State = ktTracked) and (ShoulderR.State = ktTracked) then
  begin
    if HandRight.Y > (ShoulderR.Y + 0.15) then
      APerson.RightHandRaised := True;
  end;

  if (HandLeft.State = ktTracked) and (ShoulderL.State = ktTracked) then
  begin
    if HandLeft.Y > (ShoulderL.Y + 0.15) then
      APerson.LeftHandRaised := True;
  end;

  if APerson.RightHandRaised and APerson.LeftHandRaised then
  begin
    APerson.CurrentGesture := kgRaiseBothHands;
    APerson.GestureConfidence := 0.95;
  end
  else if APerson.RightHandRaised then
  begin
    { Verifica se é Aceno (Wave) }
    if EvaluateWaveGesture(FHistories[AHistoryIdx], True) then
    begin
      APerson.CurrentGesture := kgWave;
      APerson.GestureConfidence := 0.90;
    end
    else
    begin
      APerson.CurrentGesture := kgRaiseRightHand;
      APerson.GestureConfidence := 0.92;
    end;
  end
  else if APerson.LeftHandRaised then
  begin
    if EvaluateWaveGesture(FHistories[AHistoryIdx], False) then
    begin
      APerson.CurrentGesture := kgWave;
      APerson.GestureConfidence := 0.90;
    end
    else
    begin
      APerson.CurrentGesture := kgRaiseLeftHand;
      APerson.GestureConfidence := 0.92;
    end;
  end;

  { 2. Detecção de Braços Abertos (Open Arms) }
  if (APerson.CurrentGesture = kgNone) and (ShoulderL.State = ktTracked) and (ShoulderR.State = ktTracked) and
     (HandLeft.State = ktTracked) and (HandRight.State = ktTracked) then
  begin
    if (HandLeft.X < (ShoulderL.X - 0.35)) and (HandRight.X > (ShoulderR.X + 0.35)) and
       (Abs(HandLeft.Y - ShoulderL.Y) < 0.25) and (Abs(HandRight.Y - ShoulderR.Y) < 0.25) then
    begin
      APerson.CurrentGesture := kgOpenArms;
      APerson.GestureConfidence := 0.88;
    end;
  end;

  { 3. Detecção de Apontar (Point) baseado no vetor Ombro -> Cotovelo -> Mão }
  if (APerson.CurrentGesture = kgNone) then
  begin
    { Braço Direito }
    if (ShoulderR.State = ktTracked) and (HandRight.State = ktTracked) then
    begin
      ArmR_DX := HandRight.X - ShoulderR.X;
      ArmR_DY := HandRight.Y - ShoulderR.Y;
      ArmR_DZ := HandRight.Z - ShoulderR.Z;
      ArmR_Len := Sqrt(Sqr(ArmR_DX) + Sqr(ArmR_DY) + Sqr(ArmR_DZ));

      if (ArmR_Len > 0.40) and (Abs(ArmR_DY) < 0.35) then
      begin
        if ArmR_DX > 0.35 then
        begin
          APerson.CurrentGesture := kgPointRight;
          APerson.GestureConfidence := Min(1.0, 0.70 + (ArmR_DX * 0.4));
        end
        else if (ArmR_DZ < -0.30) or (Abs(ArmR_DX) < 0.20) then
        begin
          APerson.CurrentGesture := kgPointCenter;
          APerson.GestureConfidence := 0.82;
        end;
      end;
    end;

    { Braço Esquerdo }
    if (APerson.CurrentGesture = kgNone) and (ShoulderL.State = ktTracked) and (HandLeft.State = ktTracked) then
    begin
      ArmL_DX := HandLeft.X - ShoulderL.X;
      ArmL_DY := HandLeft.Y - ShoulderL.Y;
      ArmL_DZ := HandLeft.Z - ShoulderL.Z;
      ArmL_Len := Sqrt(Sqr(ArmL_DX) + Sqr(ArmL_DY) + Sqr(ArmL_DZ));

      if (ArmL_Len > 0.40) and (Abs(ArmL_DY) < 0.35) then
      begin
        if ArmL_DX < -0.35 then
        begin
          APerson.CurrentGesture := kgPointLeft;
          APerson.GestureConfidence := Min(1.0, 0.70 + (Abs(ArmL_DX) * 0.4));
        end;
      end;
    end;
  end;

  { Disparo de evento de gesto com cooldown }
  if (APerson.CurrentGesture <> kgNone) and CooldownPassed and
     (APerson.CurrentGesture <> FHistories[AHistoryIdx].LastGesture) then
  begin
    FHistories[AHistoryIdx].LastGesture := APerson.CurrentGesture;
    FHistories[AHistoryIdx].LastGestureTick := ACurrentTick;
    FLastGesture := APerson.CurrentGesture;
    FGestureConfidence := APerson.GestureConfidence;

    if Assigned(FOnGesture) then
      FOnGesture(Self, APerson.CurrentGesture, APerson.TrackingID, APerson.GestureConfidence);

    DispatchSemanticEvent(kseGestureDetected, APerson, APerson.CurrentGesture);
  end;
end;

procedure TAIKinectPerception.DispatchSemanticEvent(AEventType: TAIKinectSemanticEventType;
  const APerson: TAIKinectPersonState; AGesture: TAIKinectGesture);
var
  SemEvent: TAIKinectSemanticEvent;
begin
  SemEvent.EventType := AEventType;
  case AEventType of
    ksePersonEntered   : SemEvent.EventTypeName := 'person_entered';
    ksePersonUpdated   : SemEvent.EventTypeName := 'person_updated';
    ksePersonLeft      : SemEvent.EventTypeName := 'person_left';
    kseGestureDetected : SemEvent.EventTypeName := 'gesture_detected';
  end;

  SemEvent.TrackingID := APerson.TrackingID;
  SemEvent.Gesture := AGesture;
  SemEvent.GestureName := GestureToString(AGesture);
  SemEvent.DistanceMeters := APerson.DistanceMeters;
  SemEvent.PositionName := APerson.PositionName;
  SemEvent.Confidence := APerson.Confidence;
  SemEvent.TimestampMS := DateTimeToTimeStamp(Now).Time;

  if Assigned(FOnSemanticEvent) then
    FOnSemanticEvent(Self, SemEvent);
end;

procedure TAIKinectPerception.CleanupInactivePersons(ACurrentTick: QWord);
var
  I, J: Integer;
  TID: Integer;
begin
  I := Length(FPersons) - 1;
  while I >= 0 do
  begin
    if (ACurrentTick - FPersons[I].LastSeenTick) > QWord(FExitTimeoutMS) then
    begin
      TID := FPersons[I].TrackingID;

      if Assigned(FOnPersonLeft) then
        FOnPersonLeft(Self, TID);

      DispatchSemanticEvent(ksePersonLeft, FPersons[I], kgNone);

      for J := I to Length(FPersons) - 2 do
        FPersons[J] := FPersons[J + 1];
      SetLength(FPersons, Length(FPersons) - 1);
    end;
    Dec(I);
  end;
end;

procedure TAIKinectPerception.ProcessBodies(const ABodies: TAIKinectBodies);
var
  I, PIdx, HIdx: Integer;
  CurrentTick: QWord;
  Body: TAIKinectBody;
  X, Y, Z, Dist: Single;
  ScrX, ScrY: Integer;
  Pos: TAIKinectPersonPosition;
  PosStr: string;
  ClosestDist: Single;
  NewActiveID: Integer;
begin
  CurrentTick := GetTickCount64;

  for I := 0 to Length(ABodies) - 1 do
  begin
    Body := ABodies[I];
    if not Body.Tracked then Continue;

    { Localiza junta principal para distância e posição (Torso / HipCenter / Spine) }
    if Body.Joints[kjSpine].State = ktTracked then
    begin
      X := Body.Joints[kjSpine].X;
      Y := Body.Joints[kjSpine].Y;
      Z := Body.Joints[kjSpine].Z;
      ScrX := Body.Joints[kjSpine].ScreenX;
      ScrY := Body.Joints[kjSpine].ScreenY;
    end
    else
    begin
      X := Body.Joints[kjHipCenter].X;
      Y := Body.Joints[kjHipCenter].Y;
      Z := Body.Joints[kjHipCenter].Z;
      ScrX := Body.Joints[kjHipCenter].ScreenX;
      ScrY := Body.Joints[kjHipCenter].ScreenY;
    end;

    Dist := Sqrt(Sqr(X) + Sqr(Y) + Sqr(Z));
    if Dist < 0.1 then Dist := Z;

    { Posição semântica lateral }
    if X < -0.30 then
    begin
      Pos := kppLeft;
      PosStr := 'left';
    end
    else if X > 0.30 then
    begin
      Pos := kppRight;
      PosStr := 'right';
    end
    else
    begin
      Pos := kppCenter;
      PosStr := 'center';
    end;

    PIdx := FindPersonIndex(Body.TrackingId);
    HIdx := FindOrCreateHistory(Body.TrackingId);

    if PIdx < 0 then
    begin
      { Novo corpo detectado }
      PIdx := Length(FPersons);
      SetLength(FPersons, PIdx + 1);
      FPersons[PIdx].TrackingID := Body.TrackingId;
      FPersons[PIdx].Present := False;
      FPersons[PIdx].Tracked := True;
      FPersons[PIdx].StableFrameCount := 1;
    end
    else
    begin
      Inc(FPersons[PIdx].StableFrameCount);
    end;

    FPersons[PIdx].X := X;
    FPersons[PIdx].Y := Y;
    FPersons[PIdx].Z := Z;
    FPersons[PIdx].DistanceMeters := Dist;
    FPersons[PIdx].ScreenX := ScrX;
    FPersons[PIdx].ScreenY := ScrY;
    FPersons[PIdx].Position := Pos;
    FPersons[PIdx].PositionName := PosStr;
    FPersons[PIdx].LastSeenTick := CurrentTick;
    FPersons[PIdx].Confidence := 0.90;

    { Confirma entrada se estável e dentro da zona de interação }
    if not FPersons[PIdx].Present then
    begin
      if (FPersons[PIdx].StableFrameCount >= FRequiredFrames) and
         (Dist >= FMinDistance) and (Dist <= FMaxDistance) then
      begin
        FPersons[PIdx].Present := True;
        if Assigned(FOnPersonEntered) then
          FOnPersonEntered(Self, FPersons[PIdx]);
        DispatchSemanticEvent(ksePersonEntered, FPersons[PIdx], kgNone);
      end;
    end
    else
    begin
      if Assigned(FOnPersonUpdated) then
        FOnPersonUpdated(Self, FPersons[PIdx]);
    end;

    { Analisa gestos deste corpo }
    ClassifyGestures(FPersons[PIdx], Body, HIdx, CurrentTick);
  end;

  { Remove pessoas ausentes por timeout }
  CleanupInactivePersons(CurrentTick);

  { Seleciona o corpo ativo (mais próximo e presente) }
  FPersonCount := 0;
  NewActiveID := 0;
  ClosestDist := 999.0;

  for I := 0 to Length(FPersons) - 1 do
  begin
    if FPersons[I].Present then
    begin
      Inc(FPersonCount);
      if FPersons[I].DistanceMeters < ClosestDist then
      begin
        ClosestDist := FPersons[I].DistanceMeters;
        NewActiveID := FPersons[I].TrackingID;
        FDistanceMeters := FPersons[I].DistanceMeters;
        FPositionName := FPersons[I].PositionName;
        FLastGesture := FPersons[I].CurrentGesture;
        FGestureConfidence := FPersons[I].GestureConfidence;
      end;
    end;
  end;

  FPersonPresent := FPersonCount > 0;
  FActiveTrackingID := NewActiveID;
  if not FPersonPresent then
  begin
    FDistanceMeters := 0.0;
    FPositionName := 'none';
    FLastGesture := kgNone;
    FGestureConfidence := 0.0;
  end;
end;

procedure TAIKinectPerception.HandleSkeletonFrame(Sender: TObject; const ABodies: TAIKinectBodies);
begin
  ProcessBodies(ABodies);
end;

procedure TAIKinectPerception.FeedSimulatedSkeleton(const ABodies: TAIKinectBodies);
begin
  FSimulatedBodies := ABodies;
  ProcessBodies(FSimulatedBodies);
end;

function TAIKinectPerception.LoadSimulatedPoseFromJSON(const AJSON: string): Boolean;
var
  Data: TJSONData;
  Parser: TJSONParser;
  RootObj, BodyObj, JointsObj, JObj: TJSONObject;
  BodiesArr: TJSONArray;
  I, J: Integer;
  JT: TAIKinectJointType;
  Bodies: TAIKinectBodies;
  JointName: string;
begin
  Result := False;
  if Trim(AJSON) = '' then Exit;
  Parser := TJSONParser.Create(AJSON);
  try
    Data := Parser.Parse;
    if Data = nil then Exit;
    try
      SetLength(Bodies, 0);
      if Data.JSONType = jtObject then
      begin
        RootObj := TJSONObject(Data);
        if RootObj.IndexOfName('bodies') >= 0 then
          BodiesArr := RootObj.Arrays['bodies']
        else
          BodiesArr := nil;

        if BodiesArr <> nil then
        begin
          SetLength(Bodies, BodiesArr.Count);
          for I := 0 to BodiesArr.Count - 1 do
          begin
            BodyObj := BodiesArr.Objects[I];
            Bodies[I].TrackingId := BodyObj.Get('tracking_id', I + 1);
            Bodies[I].Tracked := BodyObj.Get('tracked', True);

            for JT := Low(TAIKinectJointType) to High(TAIKinectJointType) do
            begin
              Bodies[I].Joints[JT].JointType := JT;
              Bodies[I].Joints[JT].State := ktTracked;
              Bodies[I].Joints[JT].X := 0;
              Bodies[I].Joints[JT].Y := 0;
              Bodies[I].Joints[JT].Z := 1.8;
            end;

            if BodyObj.IndexOfName('joints') >= 0 then
            begin
              JointsObj := BodyObj.Objects['joints'];
              for J := 0 to JointsObj.Count - 1 do
              begin
                JointName := LowerCase(JointsObj.Names[J]);
                JObj := JointsObj.Objects[JointsObj.Names[J]];

                if JointName = 'head' then JT := kjHead
                else if JointName = 'spine' then JT := kjSpine
                else if JointName = 'hip_center' then JT := kjHipCenter
                else if JointName = 'shoulder_left' then JT := kjShoulderLeft
                else if JointName = 'shoulder_right' then JT := kjShoulderRight
                else if JointName = 'elbow_left' then JT := kjElbowLeft
                else if JointName = 'elbow_right' then JT := kjElbowRight
                else if JointName = 'hand_left' then JT := kjHandLeft
                else if JointName = 'hand_right' then JT := kjHandRight
                else Continue;

                Bodies[I].Joints[JT].X := JObj.Get('x', 0.0);
                Bodies[I].Joints[JT].Y := JObj.Get('y', 0.0);
                Bodies[I].Joints[JT].Z := JObj.Get('z', 1.8);
                Bodies[I].Joints[JT].State := ktTracked;
              end;
            end;
          end;
        end;
      end;

      if Length(Bodies) > 0 then
      begin
        FeedSimulatedSkeleton(Bodies);
        Result := True;
      end;
    finally
      Data.Free;
    end;
  finally
    Parser.Free;
  end;
end;

function TAIKinectPerception.ToSemanticJSON: string;
var
  Obj: TJSONObject;
  RightRaised, LeftRaised: Boolean;
  PIdx: Integer;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('person_present', FPersonPresent);
    Obj.Add('person_count', FPersonCount);
    Obj.Add('tracking_id', FActiveTrackingID);
    Obj.Add('distance_m', RoundTo(FDistanceMeters, -2));
    Obj.Add('position', FPositionName);
    Obj.Add('body_direction', 'front');
    Obj.Add('gesture', GestureToString(FLastGesture));

    RightRaised := False;
    LeftRaised := False;
    PIdx := FindPersonIndex(FActiveTrackingID);
    if PIdx >= 0 then
    begin
      RightRaised := FPersons[PIdx].RightHandRaised;
      LeftRaised := FPersons[PIdx].LeftHandRaised;
    end;

    Obj.Add('right_hand_raised', RightRaised);
    Obj.Add('left_hand_raised', LeftRaised);
    Obj.Add('confidence', RoundTo(FGestureConfidence, -2));

    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

end.
