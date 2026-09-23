unit aiavatar3d;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIAvatar3D: Componente de Alto Nivel Coordenador do Avatar 3D
  (Tarefas 56 a 60, 83)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiavatartypes, aimodel3d, aiskeletonrig, 
  aiavatarcontroller, aiposelibrary, aianimationsequence, LResources;

type
  { TAIAvatar3D }

  TAIAvatar3D = class(TAIBaseComponent)
  private
    FModelFile: string;
    FActive: Boolean;

    FModel: TAIModel3D;
    FSkeleton: TAISkeletonRig;
    FController: TAIAvatarController;
    FPoseLibrary: TAIPoseLibrary;
    FAnimationSequence: TAIAnimationSequence;

    FInternalModel: Boolean;
    FInternalSkeleton: Boolean;
    FInternalController: Boolean;
    FInternalPoseLibrary: Boolean;
    FInternalAnimationSequence: Boolean;

    FOnLoaded: TNotifyEvent;
    FOnLoadError: TNotifyEvent;
    FOnStateChanged: TNotifyEvent;
    FOnGestureStart: TNotifyEvent;
    FOnGestureFinish: TNotifyEvent;

    procedure SetModel(AValue: TAIModel3D);
    procedure SetSkeleton(AValue: TAISkeletonRig);
    procedure SetController(AValue: TAIAvatarController);
    procedure SetPoseLibrary(AValue: TAIPoseLibrary);
    procedure SetAnimationSequence(AValue: TAIAnimationSequence);

    procedure SetStateProp(AValue: TAIAvatarState);
    function GetStateProp: TAIAvatarState;
    procedure SetEmotionProp(AValue: TAIAvatarEmotion);
    function GetEmotionProp: TAIAvatarEmotion;
    procedure SetGestureProp(AValue: TAIAvatarGesture);
    function GetGestureProp: TAIAvatarGesture;

    procedure SetAutoIdleProp(AValue: Boolean);
    function GetAutoIdleProp: Boolean;
    procedure SetAutoBlinkProp(AValue: Boolean);
    function GetAutoBlinkProp: Boolean;

    procedure ForwardStateChanged(Sender: TObject);
    procedure ForwardGestureStart(Sender: TObject);
    procedure ForwardGestureFinish(Sender: TObject);
    procedure EnsureComponentsCreated;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Gerenciamento do Ciclo de Vida do Avatar (Tarefas 57 e 58)
    procedure LoadAvatar(const AFileName: string = '');
    procedure UnloadAvatar;

    // Comandos de Alto Nivel
    procedure SetState(AState: TAIAvatarState);
    procedure SetEmotion(AEmotion: TAIAvatarEmotion; AIntensity: Single = 1.0);
    procedure PlayGesture(AGesture: TAIAvatarGesture; ADuration: Single = 1.8);
    procedure CancelGesture;
    procedure LookAt(ATarget: TAIAvatarLookTarget);

    // Frame Update
    procedure Update(DeltaTimeSec: Single);
  published
    property ModelFile: string read FModelFile write FModelFile;
    property Active: Boolean read FActive write FActive default False;

    property Model: TAIModel3D read FModel write SetModel;
    property Skeleton: TAISkeletonRig read FSkeleton write SetSkeleton;
    property Controller: TAIAvatarController read FController write SetController;
    property PoseLibrary: TAIPoseLibrary read FPoseLibrary write SetPoseLibrary;
    property AnimationSequence: TAIAnimationSequence read FAnimationSequence write SetAnimationSequence;

    property State: TAIAvatarState read GetStateProp write SetStateProp default avIdle;
    property Emotion: TAIAvatarEmotion read GetEmotionProp write SetEmotionProp default aeNeutral;
    property Gesture: TAIAvatarGesture read GetGestureProp write SetGestureProp default agNone;
    property AutoIdle: Boolean read GetAutoIdleProp write SetAutoIdleProp default True;
    property AutoBlink: Boolean read GetAutoBlinkProp write SetAutoBlinkProp default True;

    property OnLoaded: TNotifyEvent read FOnLoaded write FOnLoaded;
    property OnLoadError: TNotifyEvent read FOnLoadError write FOnLoadError;
    property OnStateChanged: TNotifyEvent read FOnStateChanged write FOnStateChanged;
    property OnGestureStart: TNotifyEvent read FOnGestureStart write FOnGestureStart;
    property OnGestureFinish: TNotifyEvent read FOnGestureFinish write FOnGestureFinish;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAvatar3D]);
end;

{ TAIAvatar3D }

constructor TAIAvatar3D.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAvatar3D is the high-level orchestrator for 3D humanoid avatars, coordinating models, skeleton rigs, controller, pose libraries and animation sequences. Properties: ModelFile, Active, State, Emotion, Gesture, AutoIdle, AutoBlink. Methods: LoadAvatar, UnloadAvatar, SetState, SetEmotion, PlayGesture, LookAt, Update.';

  FModelFile := '';
  FActive := False;

  FModel := nil;
  FSkeleton := nil;
  FController := nil;
  FPoseLibrary := nil;
  FAnimationSequence := nil;

  FInternalModel := False;
  FInternalSkeleton := False;
  FInternalController := False;
  FInternalPoseLibrary := False;
  FInternalAnimationSequence := False;

  ClearError;
end;

destructor TAIAvatar3D.Destroy;
begin
  UnloadAvatar;
  if FInternalModel and Assigned(FModel) then FreeAndNil(FModel);
  if FInternalSkeleton and Assigned(FSkeleton) then FreeAndNil(FSkeleton);
  if FInternalController and Assigned(FController) then FreeAndNil(FController);
  if FInternalPoseLibrary and Assigned(FPoseLibrary) then FreeAndNil(FPoseLibrary);
  if FInternalAnimationSequence and Assigned(FAnimationSequence) then FreeAndNil(FAnimationSequence);
  inherited Destroy;
end;

procedure TAIAvatar3D.EnsureComponentsCreated;
begin
  if FModel = nil then
  begin
    FModel := TAIModel3D.Create(Self);
    FInternalModel := True;
  end;

  if FSkeleton = nil then
  begin
    FSkeleton := TAISkeletonRig.Create(Self);
    FInternalSkeleton := True;
  end;

  if FPoseLibrary = nil then
  begin
    FPoseLibrary := TAIPoseLibrary.Create(Self);
    FInternalPoseLibrary := True;
  end;

  if FAnimationSequence = nil then
  begin
    FAnimationSequence := TAIAnimationSequence.Create(Self);
    FInternalAnimationSequence := True;
    FAnimationSequence.Model := FModel;
  end;

  if FController = nil then
  begin
    FController := TAIAvatarController.Create(Self);
    FInternalController := True;
    FController.Skeleton := FSkeleton;
    FController.PoseLibrary := FPoseLibrary;
    FController.AnimationSequence := FAnimationSequence;
    FController.OnStateChanged := @ForwardStateChanged;
    FController.OnGestureStart := @ForwardGestureStart;
    FController.OnGestureFinish := @ForwardGestureFinish;
  end;
end;

procedure TAIAvatar3D.SetModel(AValue: TAIModel3D);
begin
  if FModel <> AValue then
  begin
    if FInternalModel and Assigned(FModel) then FreeAndNil(FModel);
    FInternalModel := False;
    FModel := AValue;
    if FModel <> nil then
    begin
      FModel.FreeNotification(Self);
      if FAnimationSequence <> nil then
        FAnimationSequence.Model := FModel;
    end;
  end;
end;

procedure TAIAvatar3D.SetSkeleton(AValue: TAISkeletonRig);
begin
  if FSkeleton <> AValue then
  begin
    if FInternalSkeleton and Assigned(FSkeleton) then FreeAndNil(FSkeleton);
    FInternalSkeleton := False;
    FSkeleton := AValue;
    if FSkeleton <> nil then
    begin
      FSkeleton.FreeNotification(Self);
      if FController <> nil then
        FController.Skeleton := FSkeleton;
    end;
  end;
end;

procedure TAIAvatar3D.SetController(AValue: TAIAvatarController);
begin
  if FController <> AValue then
  begin
    if FInternalController and Assigned(FController) then FreeAndNil(FController);
    FInternalController := False;
    FController := AValue;
    if FController <> nil then
    begin
      FController.FreeNotification(Self);
      FController.OnStateChanged := @ForwardStateChanged;
      FController.OnGestureStart := @ForwardGestureStart;
      FController.OnGestureFinish := @ForwardGestureFinish;
    end;
  end;
end;

procedure TAIAvatar3D.SetPoseLibrary(AValue: TAIPoseLibrary);
begin
  if FPoseLibrary <> AValue then
  begin
    if FInternalPoseLibrary and Assigned(FPoseLibrary) then FreeAndNil(FPoseLibrary);
    FInternalPoseLibrary := False;
    FPoseLibrary := AValue;
    if FPoseLibrary <> nil then
    begin
      FPoseLibrary.FreeNotification(Self);
      if FController <> nil then
        FController.PoseLibrary := FPoseLibrary;
    end;
  end;
end;

procedure TAIAvatar3D.SetAnimationSequence(AValue: TAIAnimationSequence);
begin
  if FAnimationSequence <> AValue then
  begin
    if FInternalAnimationSequence and Assigned(FAnimationSequence) then FreeAndNil(FAnimationSequence);
    FInternalAnimationSequence := False;
    FAnimationSequence := AValue;
    if FAnimationSequence <> nil then
    begin
      FAnimationSequence.FreeNotification(Self);
      if FController <> nil then
        FController.AnimationSequence := FAnimationSequence;
    end;
  end;
end;

procedure TAIAvatar3D.SetStateProp(AValue: TAIAvatarState);
begin
  SetState(AValue);
end;

function TAIAvatar3D.GetStateProp: TAIAvatarState;
begin
  if FController <> nil then
    Result := FController.State
  else
    Result := avIdle;
end;

procedure TAIAvatar3D.SetEmotionProp(AValue: TAIAvatarEmotion);
begin
  SetEmotion(AValue);
end;

function TAIAvatar3D.GetEmotionProp: TAIAvatarEmotion;
begin
  if FController <> nil then
    Result := FController.Emotion
  else
    Result := aeNeutral;
end;

procedure TAIAvatar3D.SetGestureProp(AValue: TAIAvatarGesture);
begin
  PlayGesture(AValue);
end;

function TAIAvatar3D.GetGestureProp: TAIAvatarGesture;
begin
  if FController <> nil then
    Result := FController.Gesture
  else
    Result := agNone;
end;

procedure TAIAvatar3D.SetAutoIdleProp(AValue: Boolean);
begin
  EnsureComponentsCreated;
  FController.AutoIdle := AValue;
end;

function TAIAvatar3D.GetAutoIdleProp: Boolean;
begin
  if FController <> nil then
    Result := FController.AutoIdle
  else
    Result := True;
end;

procedure TAIAvatar3D.SetAutoBlinkProp(AValue: Boolean);
begin
  EnsureComponentsCreated;
  FController.AutoBlink := AValue;
end;

function TAIAvatar3D.GetAutoBlinkProp: Boolean;
begin
  if FController <> nil then
    Result := FController.AutoBlink
  else
    Result := True;
end;

procedure TAIAvatar3D.ForwardStateChanged(Sender: TObject);
begin
  if Assigned(FOnStateChanged) then
    FOnStateChanged(Self);
end;

procedure TAIAvatar3D.ForwardGestureStart(Sender: TObject);
begin
  if Assigned(FOnGestureStart) then
    FOnGestureStart(Self);
end;

procedure TAIAvatar3D.ForwardGestureFinish(Sender: TObject);
begin
  if Assigned(FOnGestureFinish) then
    FOnGestureFinish(Self);
end;

procedure TAIAvatar3D.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FModel then FModel := nil;
    if AComponent = FSkeleton then FSkeleton := nil;
    if AComponent = FController then FController := nil;
    if AComponent = FPoseLibrary then FPoseLibrary := nil;
    if AComponent = FAnimationSequence then FAnimationSequence := nil;
  end;
end;

procedure TAIAvatar3D.LoadAvatar(const AFileName: string);
var
  TargetFile: string;
begin
  TargetFile := Trim(AFileName);
  if TargetFile <> '' then
    FModelFile := TargetFile;

  if FModelFile = '' then
  begin
    SetError('No model file specified for avatar.');
    if Assigned(FOnLoadError) then FOnLoadError(Self);
    Exit;
  end;

  EnsureComponentsCreated;
  Log(llInfo, 'Loading 3D avatar from file: ' + FModelFile);

  FModel.LoadFromFile(FModelFile);
  if FModel.LastSuccess then
  begin
    FSkeleton.AutoMapHumanoidBones;
    FActive := True;
    Log(llInfo, Format('3D Avatar loaded successfully. Vertices: %d, Faces: %d, HasSkinning: %s',
      [FModel.VerticesCount, FModel.FacesCount, BoolToStr(FModel.HasSkinning, True)]));

    // Coloca o avatar em estado Idle por padrao
    SetState(avIdle);

    if Assigned(FOnLoaded) then
      FOnLoaded(Self);
  end
  else
  begin
    FActive := False;
    SetError('Failed to load avatar model: ' + FModel.LastResult);
    if Assigned(FOnLoadError) then
      FOnLoadError(Self);
  end;
end;

procedure TAIAvatar3D.UnloadAvatar;
begin
  FActive := False;
  if FController <> nil then
  begin
    FController.CancelGesture;
    FController.SetState(avIdle);
  end;
  if FAnimationSequence <> nil then
    FAnimationSequence.StopAnimation;
  Log(llInfo, '3D Avatar unloaded.');
end;

procedure TAIAvatar3D.SetState(AState: TAIAvatarState);
begin
  EnsureComponentsCreated;
  FController.SetState(AState);
end;

procedure TAIAvatar3D.SetEmotion(AEmotion: TAIAvatarEmotion; AIntensity: Single);
begin
  EnsureComponentsCreated;
  FController.SetEmotion(AEmotion, AIntensity);
end;

procedure TAIAvatar3D.PlayGesture(AGesture: TAIAvatarGesture; ADuration: Single);
begin
  EnsureComponentsCreated;
  FController.PlayGesture(AGesture, ADuration);
end;

procedure TAIAvatar3D.CancelGesture;
begin
  if FController <> nil then
    FController.CancelGesture;
end;

procedure TAIAvatar3D.LookAt(ATarget: TAIAvatarLookTarget);
begin
  EnsureComponentsCreated;
  FController.LookAt(ATarget);
end;

procedure TAIAvatar3D.Update(DeltaTimeSec: Single);
begin
  if not FActive then Exit;

  if FController <> nil then
    FController.Update(DeltaTimeSec);

  // Aplica deformacao de skinning se o modelo for baseado em ossos
  if (FModel <> nil) and FModel.HasSkinning and (FSkeleton <> nil) then
    FModel.ApplySkinning(FSkeleton);
end;

initialization
  {$I aiavatar3d_icon.lrs}

end.
