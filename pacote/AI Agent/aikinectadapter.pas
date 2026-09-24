{===============================================================================
  AI Kinect Adapter
  Adaptador semantico conectando a percepcao do Kinect (TAIKinectPerception)
  ao Orquestrador de Conversacao Multi-Modal (TAIConversationOrchestrator) e
  ao Contexto de Interacao (TAIInteractionContext).

  MaurinSoft - Projeto CHATGPT
===============================================================================}
unit aikinectadapter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  aikinect_types, aikinectperception,
  aiinteractioncontext, aiconversationorchestrator;

type
  TOnDeicticTargetEvent = procedure(Sender: TObject; const AGesture, ATarget: string) of object;
  TOnKinectPersonLifecycleEvent = procedure(Sender: TObject; ATrackingID: Integer;
                                    ADistance: Single; const APosition: string) of object;
  TOnKinectPersonLeftEvent = procedure(Sender: TObject; ATrackingID: Integer) of object;

  { TAIKinectInteractionAdapter }
  TAIKinectInteractionAdapter = class(TComponent)
  private
    FPerception: TAIKinectPerception;
    FOrchestrator: TAIConversationOrchestrator;
    FTargetLeft: string;
    FTargetRight: string;
    FTargetCenter: string;
    FAutoEngageOnEntry: Boolean;
    FAutoResetOnExit: Boolean;
    FOnPersonEntered: TOnKinectPersonLifecycleEvent;
    FOnPersonLeft: TOnKinectPersonLeftEvent;
    FOnDeicticTargetResolved: TOnDeicticTargetEvent;

    procedure SetPerception(const AValue: TAIKinectPerception);
    procedure SetOrchestrator(const AValue: TAIConversationOrchestrator);

    procedure HandlePersonEntered(Sender: TObject; const APerson: TAIKinectPersonState);
    procedure HandlePersonUpdated(Sender: TObject; const APerson: TAIKinectPersonState);
    procedure HandlePersonLeft(Sender: TObject; ATrackingID: Integer);
    procedure HandleGesture(Sender: TObject; AGesture: TAIKinectGesture;
                ATrackingID: Integer; AConfidence: Single);
    procedure HandleSemanticEvent(Sender: TObject; const AEvent: TAIKinectSemanticEvent);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Processamento manual caso os eventos nao estejam associados diretamente }
    procedure FeedSemanticEvent(const AEvent: TAIKinectSemanticEvent);
  published
    property Perception: TAIKinectPerception read FPerception write SetPerception;
    property Orchestrator: TAIConversationOrchestrator read FOrchestrator write SetOrchestrator;
    property TargetLeft: string read FTargetLeft write FTargetLeft;
    property TargetRight: string read FTargetRight write FTargetRight;
    property TargetCenter: string read FTargetCenter write FTargetCenter;
    property AutoEngageOnEntry: Boolean read FAutoEngageOnEntry write FAutoEngageOnEntry default True;
    property AutoResetOnExit: Boolean read FAutoResetOnExit write FAutoResetOnExit default True;

    property OnPersonEntered: TOnKinectPersonLifecycleEvent read FOnPersonEntered write FOnPersonEntered;
    property OnPersonLeft: TOnKinectPersonLeftEvent read FOnPersonLeft write FOnPersonLeft;
    property OnDeicticTargetResolved: TOnDeicticTargetEvent read FOnDeicticTargetResolved write FOnDeicticTargetResolved;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('OpenAI Agent', [TAIKinectInteractionAdapter]);
end;

{ TAIKinectInteractionAdapter }

constructor TAIKinectInteractionAdapter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTargetLeft := 'ECG';
  FTargetRight := 'Hemacias';
  FTargetCenter := 'Robotinics';
  FAutoEngageOnEntry := True;
  FAutoResetOnExit := True;
end;

destructor TAIKinectInteractionAdapter.Destroy;
begin
  if Assigned(FPerception) then
  begin
    FPerception.OnPersonEntered := nil;
    FPerception.OnPersonUpdated := nil;
    FPerception.OnPersonLeft := nil;
    FPerception.OnGesture := nil;
    FPerception.OnSemanticEvent := nil;
  end;
  inherited Destroy;
end;

procedure TAIKinectInteractionAdapter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FPerception then FPerception := nil;
    if AComponent = FOrchestrator then FOrchestrator := nil;
  end;
end;

procedure TAIKinectInteractionAdapter.SetPerception(const AValue: TAIKinectPerception);
begin
  if FPerception = AValue then Exit;
  if Assigned(FPerception) then
  begin
    FPerception.OnPersonEntered := nil;
    FPerception.OnPersonUpdated := nil;
    FPerception.OnPersonLeft := nil;
    FPerception.OnGesture := nil;
    FPerception.OnSemanticEvent := nil;
  end;

  FPerception := AValue;

  if Assigned(FPerception) then
  begin
    FPerception.FreeNotification(Self);
    FPerception.OnPersonEntered := @HandlePersonEntered;
    FPerception.OnPersonUpdated := @HandlePersonUpdated;
    FPerception.OnPersonLeft := @HandlePersonLeft;
    FPerception.OnGesture := @HandleGesture;
    FPerception.OnSemanticEvent := @HandleSemanticEvent;
  end;
end;

procedure TAIKinectInteractionAdapter.SetOrchestrator(const AValue: TAIConversationOrchestrator);
begin
  if FOrchestrator = AValue then Exit;
  FOrchestrator := AValue;
  if Assigned(FOrchestrator) then
    FOrchestrator.FreeNotification(Self);
end;

procedure TAIKinectInteractionAdapter.HandlePersonEntered(Sender: TObject; const APerson: TAIKinectPersonState);
begin
  if Assigned(FOrchestrator) and Assigned(FOrchestrator.Context) then
  begin
    FOrchestrator.Context.PersonPresent := True;
    FOrchestrator.Context.BodyTrackingID := APerson.TrackingID;
    FOrchestrator.Context.PersonDistance := APerson.DistanceMeters;
    FOrchestrator.Context.PersonPosition := APerson.PositionName;
    FOrchestrator.Context.LastPerceptionJSON := FPerception.ToSemanticJSON;

    if FAutoEngageOnEntry and (FOrchestrator.Context.CurrentPerson = '') then
      FOrchestrator.NotifyPersonDetected(Format('Visitante #%d', [APerson.TrackingID]));
  end;

  if Assigned(FOnPersonEntered) then
    FOnPersonEntered(Self, APerson.TrackingID, APerson.DistanceMeters, APerson.PositionName);
end;

procedure TAIKinectInteractionAdapter.HandlePersonUpdated(Sender: TObject; const APerson: TAIKinectPersonState);
begin
  if Assigned(FOrchestrator) and Assigned(FOrchestrator.Context) then
  begin
    FOrchestrator.Context.PersonDistance := APerson.DistanceMeters;
    FOrchestrator.Context.PersonPosition := APerson.PositionName;
  end;
end;

procedure TAIKinectInteractionAdapter.HandlePersonLeft(Sender: TObject; ATrackingID: Integer);
begin
  if Assigned(FOrchestrator) and Assigned(FOrchestrator.Context) then
  begin
    FOrchestrator.Context.PersonPresent := False;
    FOrchestrator.Context.LastGesture := '';
    FOrchestrator.Context.LastGestureConfidence := 0.0;
    if FAutoResetOnExit then
    begin
      FOrchestrator.Context.ObjectPointed := '';
    end;
  end;

  if Assigned(FOnPersonLeft) then
    FOnPersonLeft(Self, ATrackingID);
end;

procedure TAIKinectInteractionAdapter.HandleGesture(Sender: TObject; AGesture: TAIKinectGesture;
  ATrackingID: Integer; AConfidence: Single);
var
  Target: string;
  GestureStr: string;
begin
  if not Assigned(FOrchestrator) or not Assigned(FOrchestrator.Context) then Exit;

  GestureStr := FPerception.GestureToString(AGesture);
  FOrchestrator.Context.LastGesture := GestureStr;
  FOrchestrator.Context.LastGestureConfidence := AConfidence;

  Target := '';
  case AGesture of
    kgPointLeft:
      Target := FTargetLeft;
    kgPointRight:
      Target := FTargetRight;
    kgPointCenter:
      Target := FTargetCenter;
    kgRaiseRightHand, kgRaiseLeftHand, kgRaiseBothHands:
      GestureStr := 'raise_hand';
    kgWave:
      GestureStr := 'wave';
    kgOpenArms:
      GestureStr := 'open_arms';
  end;

  if Trim(Target) <> '' then
  begin
    FOrchestrator.Context.ObjectPointed := Target;
    if Assigned(FOnDeicticTargetResolved) then
      FOnDeicticTargetResolved(Self, GestureStr, Target);
  end;

  FOrchestrator.NotifyGestureDetected(GestureStr, Target);
end;

procedure TAIKinectInteractionAdapter.HandleSemanticEvent(Sender: TObject; const AEvent: TAIKinectSemanticEvent);
begin
  FeedSemanticEvent(AEvent);
end;

procedure TAIKinectInteractionAdapter.FeedSemanticEvent(const AEvent: TAIKinectSemanticEvent);
begin
  if Assigned(FOrchestrator) and Assigned(FOrchestrator.Context) then
  begin
    FOrchestrator.Context.PersonDistance := AEvent.DistanceMeters;
    FOrchestrator.Context.PersonPosition := AEvent.PositionName;
    if AEvent.Gesture <> kgNone then
    begin
      FOrchestrator.Context.LastGesture := AEvent.GestureName;
      FOrchestrator.Context.LastGestureConfidence := AEvent.Confidence;
    end;
  end;
end;

end.
