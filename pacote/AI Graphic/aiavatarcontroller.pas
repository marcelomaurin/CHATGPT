unit aiavatarcontroller;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIAvatarController: Controlador de Estados, Emocoes, Gestos e Fallbacks
  (Tarefas 41 a 55)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, aiavatartypes, aiskeletonrig, aiposelibrary, aianimationsequence, LResources;

type
  { Estado interno de execucao de gesto procedural }
  TProceduralGestureState = record
    Active: Boolean;
    Gesture: TAIAvatarGesture;
    Progress: Single;   // 0.0 a 1.0
    Duration: Single;   // em segundos
  end;

  { TAIAvatarController }

  TAIAvatarController = class(TAIBaseComponent)
  private
    FSkeleton: TAISkeletonRig;
    FPoseLibrary: TAIPoseLibrary;
    FAnimationSequence: TAIAnimationSequence;

    FState: TAIAvatarState;
    FEmotion: TAIAvatarEmotion;
    FGesture: TAIAvatarGesture;
    FEmotionIntensity: Single;

    FAutoIdle: Boolean;
    FAutoBlink: Boolean;
    FBreathingAmplitude: Single;
    FIdleTimer: Single;
    FBlinkTimer: Single;
    FNextBlinkInterval: Single;
    FIsBlinking: Boolean;

    FLookTarget: TAIAvatarLookTarget;
    FCustomLookPoint: TVector3D;
    FMaxHeadPitch: Single;
    FMaxHeadYaw: Single;
    FMaxEyePitch: Single;
    FMaxEyeYaw: Single;

    FGestureState: TProceduralGestureState;

    FOnStateChanged: TNotifyEvent;
    FOnEmotionChanged: TNotifyEvent;
    FOnGestureStart: TNotifyEvent;
    FOnGestureFinish: TNotifyEvent;

    procedure SetSkeleton(AValue: TAISkeletonRig);
    procedure SetPoseLibrary(AValue: TAIPoseLibrary);
    procedure SetAnimationSequence(AValue: TAIAnimationSequence);
    procedure SetStateProp(AValue: TAIAvatarState);
    procedure SetEmotionProp(AValue: TAIAvatarEmotion);
    procedure SetGestureProp(AValue: TAIAvatarGesture);

    procedure UpdateProceduralBreathing(DeltaTime: Single);
    procedure UpdateProceduralBlink(DeltaTime: Single);
    procedure UpdateProceduralGesture(DeltaTime: Single);
    procedure ApplyLookAtAngles(YawDeg, PitchDeg: Single);
    procedure ResetHeadAndEyes;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    // Controle de Estados e Emocoes (Tarefas 42 e 43)
    procedure SetState(AState: TAIAvatarState);
    procedure SetEmotion(AEmotion: TAIAvatarEmotion; AIntensity: Single = 1.0);

    // Controle de Gestos e Fallbacks Procedurais (Tarefas 44 a 49)
    procedure PlayGesture(AGesture: TAIAvatarGesture; ADuration: Single = 1.8);
    procedure CancelGesture;

    // Controle de Olhar e Atencao Visual (Tarefas 53 a 55)
    procedure LookAt(ATarget: TAIAvatarLookTarget); overload;
    procedure LookAt(const ACustomPoint: TVector3D); overload;

    // Atualizacao de Frame (Tick de Animacao)
    procedure Update(DeltaTimeSec: Single);

    property GestureProgress: Single read FGestureState.Progress;
    property IsPerformingGesture: Boolean read FGestureState.Active;
  published
    property Skeleton: TAISkeletonRig read FSkeleton write SetSkeleton;
    property PoseLibrary: TAIPoseLibrary read FPoseLibrary write SetPoseLibrary;
    property AnimationSequence: TAIAnimationSequence read FAnimationSequence write SetAnimationSequence;

    property State: TAIAvatarState read FState write SetStateProp default avIdle;
    property Emotion: TAIAvatarEmotion read FEmotion write SetEmotionProp default aeNeutral;
    property Gesture: TAIAvatarGesture read FGesture write SetGestureProp default agNone;
    property EmotionIntensity: Single read FEmotionIntensity write FEmotionIntensity;

    property AutoIdle: Boolean read FAutoIdle write FAutoIdle default True;
    property AutoBlink: Boolean read FAutoBlink write FAutoBlink default True;
    property BreathingAmplitude: Single read FBreathingAmplitude write FBreathingAmplitude;

    property LookTargetProp: TAIAvatarLookTarget read FLookTarget write FLookTarget default ltCenter;
    property MaxHeadPitch: Single read FMaxHeadPitch write FMaxHeadPitch;
    property MaxHeadYaw: Single read FMaxHeadYaw write FMaxHeadYaw;
    property MaxEyePitch: Single read FMaxEyePitch write FMaxEyePitch;
    property MaxEyeYaw: Single read FMaxEyeYaw write FMaxEyeYaw;

    property OnStateChanged: TNotifyEvent read FOnStateChanged write FOnStateChanged;
    property OnEmotionChanged: TNotifyEvent read FOnEmotionChanged write FOnEmotionChanged;
    property OnGestureStart: TNotifyEvent read FOnGestureStart write FOnGestureStart;
    property OnGestureFinish: TNotifyEvent read FOnGestureFinish write FOnGestureFinish;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAvatarController]);
end;

{ TAIAvatarController }

constructor TAIAvatarController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAvatarController coordinates avatar states, facial expressions, emotional poses, expressive gestures, look-at targeting, breathing, and eye blinking. Properties: Skeleton, PoseLibrary, AnimationSequence, State, Emotion, Gesture, AutoIdle, AutoBlink. Methods: SetState, SetEmotion, PlayGesture, CancelGesture, LookAt, Update.';
  FSkeleton := nil;
  FPoseLibrary := nil;
  FAnimationSequence := nil;

  FState := avIdle;
  FEmotion := aeNeutral;
  FGesture := agNone;
  FEmotionIntensity := 1.0;

  FAutoIdle := True;
  FAutoBlink := True;
  FBreathingAmplitude := 2.5; // graus sutis no peito
  FIdleTimer := 0.0;
  FBlinkTimer := 0.0;
  FNextBlinkInterval := 3.0;
  FIsBlinking := False;

  FLookTarget := ltCenter;
  FCustomLookPoint := Vector3D(0, 0, 0);
  FMaxHeadPitch := 25.0;
  FMaxHeadYaw := 40.0;
  FMaxEyePitch := 20.0;
  FMaxEyeYaw := 30.0;

  FGestureState.Active := False;
  FGestureState.Gesture := agNone;
  FGestureState.Progress := 0.0;
  FGestureState.Duration := 1.8;

  ClearError;
end;

procedure TAIAvatarController.SetSkeleton(AValue: TAISkeletonRig);
begin
  if FSkeleton <> AValue then
  begin
    FSkeleton := AValue;
    if FSkeleton <> nil then
      FSkeleton.FreeNotification(Self);
  end;
end;

procedure TAIAvatarController.SetPoseLibrary(AValue: TAIPoseLibrary);
begin
  if FPoseLibrary <> AValue then
  begin
    FPoseLibrary := AValue;
    if FPoseLibrary <> nil then
      FPoseLibrary.FreeNotification(Self);
  end;
end;

procedure TAIAvatarController.SetAnimationSequence(AValue: TAIAnimationSequence);
begin
  if FAnimationSequence <> AValue then
  begin
    FAnimationSequence := AValue;
    if FAnimationSequence <> nil then
      FAnimationSequence.FreeNotification(Self);
  end;
end;

procedure TAIAvatarController.SetStateProp(AValue: TAIAvatarState);
begin
  SetState(AValue);
end;

procedure TAIAvatarController.SetEmotionProp(AValue: TAIAvatarEmotion);
begin
  SetEmotion(AValue, FEmotionIntensity);
end;

procedure TAIAvatarController.SetGestureProp(AValue: TAIAvatarGesture);
begin
  if AValue <> agNone then
    PlayGesture(AValue)
  else
    CancelGesture;
end;

procedure TAIAvatarController.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FSkeleton then FSkeleton := nil;
    if AComponent = FPoseLibrary then FPoseLibrary := nil;
    if AComponent = FAnimationSequence then FAnimationSequence := nil;
  end;
end;

procedure TAIAvatarController.SetState(AState: TAIAvatarState);
begin
  if FState <> AState then
  begin
    FState := AState;
    Log(llInfo, 'Avatar state changed to: ' + AvatarStateToString(FState));

    // Comportamento associado ao estado
    case FState of
      avListening:
        begin
          SetEmotion(aeNeutral, 0.8);
          LookAt(ltUser);
        end;
      avThinking:
        begin
          SetEmotion(aeThinking, 0.9);
          LookAt(ltUp);
        end;
      avSpeaking:
        begin
          // Fala mantém olhar no usuário
          LookAt(ltUser);
        end;
      avError:
        begin
          SetEmotion(aeConcerned, 1.0);
        end;
      avSuccess:
        begin
          SetEmotion(aeHappy, 1.0);
        end;
    end;

    if Assigned(FOnStateChanged) then
      FOnStateChanged(Self);
  end;
end;

procedure TAIAvatarController.SetEmotion(AEmotion: TAIAvatarEmotion; AIntensity: Single);
var
  PoseName: string;
begin
  FEmotion := AEmotion;
  FEmotionIntensity := AIntensity;

  case FEmotion of
    aeNeutral:    PoseName := 'Neutral';
    aeHappy:      PoseName := 'Neutral'; // Pode ser extendido com blend
    aeSad:        PoseName := 'Concerned';
    aeConcerned:  PoseName := 'Concerned';
    aeSurprised:  PoseName := 'Neutral';
    aeThinking:   PoseName := 'Thinking';
    aeConfused:   PoseName := 'Listening';
    aeConfident:  PoseName := 'Confident';
    aeExcited:    PoseName := 'Confident';
  else
    PoseName := 'Neutral';
  end;

  if (FPoseLibrary <> nil) and (FSkeleton <> nil) then
    FPoseLibrary.ApplyPose(PoseName, FSkeleton, FEmotionIntensity);

  Log(llDebug, Format('Avatar emotion set to: %s (Pose: %s, Intensity: %.2f)',
    [AvatarEmotionToString(FEmotion), PoseName, FEmotionIntensity]));

  if Assigned(FOnEmotionChanged) then
    FOnEmotionChanged(Self);
end;

procedure TAIAvatarController.PlayGesture(AGesture: TAIAvatarGesture; ADuration: Single);
begin
  if AGesture = agNone then
  begin
    CancelGesture;
    Exit;
  end;

  FGesture := AGesture;
  FGestureState.Active := True;
  FGestureState.Gesture := AGesture;
  FGestureState.Progress := 0.0;
  if ADuration > 0.1 then
    FGestureState.Duration := ADuration
  else
    FGestureState.Duration := 1.8;

  Log(llInfo, Format('Avatar playing gesture: %s (Duration: %.2fs)',
    [AvatarGestureToString(FGesture), FGestureState.Duration]));

  if Assigned(FOnGestureStart) then
    FOnGestureStart(Self);
end;

procedure TAIAvatarController.CancelGesture;
begin
  if FGestureState.Active then
  begin
    FGestureState.Active := False;
    FGestureState.Progress := 0.0;
    FGesture := agNone;

    // Retorna para pose da emocao atual
    SetEmotion(FEmotion, FEmotionIntensity);
    Log(llDebug, 'Avatar gesture canceled, returned to base pose.');

    if Assigned(FOnGestureFinish) then
      FOnGestureFinish(Self);
  end;
end;

procedure TAIAvatarController.LookAt(ATarget: TAIAvatarLookTarget);
begin
  FLookTarget := ATarget;
  case FLookTarget of
    ltUser, ltCenter: ApplyLookAtAngles(0.0, 0.0);
    ltLeft:           ApplyLookAtAngles(-18.0, 0.0);
    ltRight:          ApplyLookAtAngles(18.0, 0.0);
    ltUp:             ApplyLookAtAngles(0.0, -12.0);
    ltDown:           ApplyLookAtAngles(0.0, 12.0);
    ltCustomPoint:    LookAt(FCustomLookPoint);
  end;
end;

procedure TAIAvatarController.LookAt(const ACustomPoint: TVector3D);
var
  Yaw, Pitch: Single;
begin
  FLookTarget := ltCustomPoint;
  FCustomLookPoint := ACustomPoint;
  // Calculo angular simples a partir de coordenadas espaciais
  Yaw := ArcTan2(ACustomPoint.X, Max(0.001, ACustomPoint.Z)) * 180.0 / Pi;
  Pitch := -ArcTan2(ACustomPoint.Y, Max(0.001, ACustomPoint.Z)) * 180.0 / Pi;
  ApplyLookAtAngles(Yaw, Pitch);
end;

procedure TAIAvatarController.ApplyLookAtAngles(YawDeg, PitchDeg: Single);
var
  ClampedYaw, ClampedPitch: Double;
  BoneName: string;
begin
  if FSkeleton = nil then Exit;

  // Clampar angulos (Tarefa 55)
  ClampedYaw := Min(Max(YawDeg, -FMaxHeadYaw), FMaxHeadYaw);
  ClampedPitch := Min(Max(PitchDeg, -FMaxHeadPitch), FMaxHeadPitch);

  // Mover olhos se existirem no esqueleto (Tarefa 53)
  if FSkeleton.HasHumanoidBone(hbLeftEye) and FSkeleton.HasHumanoidBone(hbRightEye) then
  begin
    BoneName := FSkeleton.GetMappedBoneName(hbLeftEye);
    if BoneName <> '' then
      FSkeleton.SetBoneRotation(BoneName, ClampedPitch * 0.5, ClampedYaw * 0.5, 0.0);

    BoneName := FSkeleton.GetMappedBoneName(hbRightEye);
    if BoneName <> '' then
      FSkeleton.SetBoneRotation(BoneName, ClampedPitch * 0.5, ClampedYaw * 0.5, 0.0);

    // Complementa com a cabeca
    if FSkeleton.HasHumanoidBone(hbHead) then
    begin
      BoneName := FSkeleton.GetMappedBoneName(hbHead);
      if BoneName <> '' then
        FSkeleton.SetBoneRotation(BoneName, ClampedPitch * 0.5, ClampedYaw * 0.5, 0.0);
    end;
  end
  else if FSkeleton.HasHumanoidBone(hbHead) then
  begin
    // Fallback: rotaciona a cabeca inteira (Tarefa 53)
    BoneName := FSkeleton.GetMappedBoneName(hbHead);
    if BoneName <> '' then
      FSkeleton.SetBoneRotation(BoneName, ClampedPitch, ClampedYaw, 0.0);
  end;

  FSkeleton.UpdateFK;
end;

procedure TAIAvatarController.ResetHeadAndEyes;
begin
  ApplyLookAtAngles(0.0, 0.0);
end;

procedure TAIAvatarController.UpdateProceduralBreathing(DeltaTime: Single);
var
  BreathOffset: Double;
  BoneName: string;
begin
  if not FAutoIdle or (FSkeleton = nil) then Exit;

  FIdleTimer := FIdleTimer + DeltaTime * 1.5; // ciclo de respiracao ~4s
  if FIdleTimer > 2.0 * Pi then FIdleTimer := FIdleTimer - 2.0 * Pi;

  // Movimento senoidal sutil no peito (Tarefa 50)
  BreathOffset := Sin(FIdleTimer) * FBreathingAmplitude;

  if FSkeleton.HasHumanoidBone(hbChest) then
  begin
    BoneName := FSkeleton.GetMappedBoneName(hbChest);
    if BoneName <> '' then
      FSkeleton.SetBoneRotation(BoneName, BreathOffset, 0.0, 0.0);
  end;
end;

procedure TAIAvatarController.UpdateProceduralBlink(DeltaTime: Single);
begin
  if not FAutoBlink or (FSkeleton = nil) then Exit;

  FBlinkTimer := FBlinkTimer + DeltaTime;
  if not FIsBlinking then
  begin
    if FBlinkTimer >= FNextBlinkInterval then
    begin
      FIsBlinking := True;
      FBlinkTimer := 0.0;
    end;
  end
  else
  begin
    // Piscada dura ~0.15 segundos
    if FBlinkTimer >= 0.15 then
    begin
      FIsBlinking := False;
      FBlinkTimer := 0.0;
      // Proximo intervalo aleatorio entre 2.5s e 5.5s (Tarefa 52)
      FNextBlinkInterval := 2.5 + Random * 3.0;
    end;
  end;
end;

procedure TAIAvatarController.UpdateProceduralGesture(DeltaTime: Single);
var
  P, WaveAngle, ArmAngle: Double;
  BoneName: string;
begin
  if not FGestureState.Active or (FSkeleton = nil) then Exit;

  FGestureState.Progress := FGestureState.Progress + (DeltaTime / FGestureState.Duration);
  P := FGestureState.Progress;

  if P >= 1.0 then
  begin
    FGestureState.Active := False;
    FGesture := agNone;
    SetEmotion(FEmotion, FEmotionIntensity);
    if Assigned(FOnGestureFinish) then
      FOnGestureFinish(Self);
    Exit;
  end;

  case FGestureState.Gesture of
    agNod: // Tarefa 45: Balançar a cabeça verticalmente (sim)
      begin
        // Senóide que vai para baixo e volta (2 ciclos suaves)
        WaveAngle := Sin(P * 2.0 * Pi) * 14.0;
        if FSkeleton.HasHumanoidBone(hbHead) then
        begin
          BoneName := FSkeleton.GetMappedBoneName(hbHead);
          if BoneName <> '' then
            FSkeleton.SetBoneRotation(BoneName, WaveAngle, 0.0, 0.0);
        end;
      end;

    agShakeHead: // Tarefa 46: Balançar a cabeça horizontalmente (não)
      begin
        // Senóide que oscila esquerda/direita e retorna ao centro
        WaveAngle := Sin(P * 2.0 * Pi) * 18.0;
        if FSkeleton.HasHumanoidBone(hbHead) then
        begin
          BoneName := FSkeleton.GetMappedBoneName(hbHead);
          if BoneName <> '' then
            FSkeleton.SetBoneRotation(BoneName, 0.0, WaveAngle, 0.0);
        end;
      end;

    agWave: // Tarefa 47: Acenar com o braço direito
      begin
        // Envelope suave: sobe nos primeiros 20%, oscila entre 20% e 80%, desce no final
        if P < 0.2 then
          ArmAngle := (P / 0.2) * 55.0
        else if P > 0.8 then
          ArmAngle := ((1.0 - P) / 0.2) * 55.0
        else
          ArmAngle := 55.0;

        WaveAngle := Sin((P - 0.2) * 8.0 * Pi) * 20.0;

        if FSkeleton.HasHumanoidBone(hbRightUpperArm) then
        begin
          BoneName := FSkeleton.GetMappedBoneName(hbRightUpperArm);
          if BoneName <> '' then
            FSkeleton.SetBoneRotation(BoneName, 0.0, 0.0, -ArmAngle);
        end;

        if FSkeleton.HasHumanoidBone(hbRightLowerArm) then
        begin
          BoneName := FSkeleton.GetMappedBoneName(hbRightLowerArm);
          if BoneName <> '' then
            FSkeleton.SetBoneRotation(BoneName, 40.0, 0.0, WaveAngle);
        end;
      end;

    agExplain: // Tarefa 48: Gestual explicativo de mãos
      begin
        WaveAngle := Sin(P * 3.0 * Pi) * 15.0;
        if FSkeleton.HasHumanoidBone(hbLeftUpperArm) then
        begin
          BoneName := FSkeleton.GetMappedBoneName(hbLeftUpperArm);
          if BoneName <> '' then
            FSkeleton.SetBoneRotation(BoneName, 25.0, 0.0, 15.0 + WaveAngle);
        end;

        if FSkeleton.HasHumanoidBone(hbRightUpperArm) then
        begin
          BoneName := FSkeleton.GetMappedBoneName(hbRightUpperArm);
          if BoneName <> '' then
            FSkeleton.SetBoneRotation(BoneName, 25.0, 0.0, -15.0 - WaveAngle);
        end;
      end;

    agThink: // Tarefa 49: Postura pensativa
      begin
        if (FPoseLibrary <> nil) then
          FPoseLibrary.ApplyPose('Thinking', FSkeleton, Min(1.0, P * 2.0));
      end;
  end;

  FSkeleton.UpdateFK;
end;

procedure TAIAvatarController.Update(DeltaTimeSec: Single);
begin
  // 1. Atualizar respiracao auto-idle
  if FAutoIdle then
    UpdateProceduralBreathing(DeltaTimeSec);

  // 2. Atualizar auto-blink
  if FAutoBlink then
    UpdateProceduralBlink(DeltaTimeSec);

  // 3. Atualizar gestos procedurais em andamento
  if FGestureState.Active then
    UpdateProceduralGesture(DeltaTimeSec);

  // 4. Se tiver animation sequence associada, avança o frame
  if FAnimationSequence <> nil then
    FAnimationSequence.Update(DeltaTimeSec);
end;

initialization
  {$I aiavatarcontroller_icon.lrs}

end.
