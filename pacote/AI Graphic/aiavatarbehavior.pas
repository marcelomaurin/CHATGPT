unit aiavatarbehavior;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIAvatarBehavior: Regras de Comportamento, Expressividade e Prioridades
  (Tarefas 71 a 77)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, aiavatartypes, aiavatarcontroller, LResources;

type
  { Perfis de Expressividade do Avatar (Tarefa 75) }
  TAIAvatarExpressivenessProfile = (
    epReserved,
    epNormal,
    epExpressive,
    epVeryExpressive
  );

  { Niveis de Prioridade de Acao (Tarefa 76) }
  TAIAvatarPriority = (
    prIdle,
    prGesture,
    prSpeech,
    prCriticalAction
  );

  { TAIAvatarBehavior }

  TAIAvatarBehavior = class(TAIBaseComponent)
  private
    FController: TAIAvatarController;
    FProfile: TAIAvatarExpressivenessProfile;
    FMaxIntensity: Single;
    FGestureCooldown: Single;
    FCurrentCooldown: Single;
    FLastGesture: TAIAvatarGesture;
    FCurrentPriority: TAIAvatarPriority;

    procedure SetController(AValue: TAIAvatarController);
    procedure SetProfile(AValue: TAIAvatarExpressivenessProfile);
    procedure ApplyProfileDefaults;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    // Processamento de Intencoes e Regras (Tarefas 71 a 77)
    procedure ApplyIntent(const AResponse: TAIAvatarResponse);
    function CanExecuteGesture(AGesture: TAIAvatarGesture): Boolean;
    procedure CancelGesture;
    procedure Update(DeltaTimeSec: Single);

    property CurrentPriority: TAIAvatarPriority read FCurrentPriority write FCurrentPriority;
    property LastGesture: TAIAvatarGesture read FLastGesture;
  published
    property Controller: TAIAvatarController read FController write SetController;
    property Profile: TAIAvatarExpressivenessProfile read FProfile write SetProfile default epNormal;
    property MaxIntensity: Single read FMaxIntensity write FMaxIntensity;
    property GestureCooldown: Single read FGestureCooldown write FGestureCooldown;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAvatarBehavior]);
end;

{ TAIAvatarBehavior }

constructor TAIAvatarBehavior.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAvatarBehavior applies natural behavior rules, expressiveness profiling, gesture cooldowns and priority arbitration to avatar motions. Properties: Controller, Profile, MaxIntensity, GestureCooldown. Methods: ApplyIntent, CanExecuteGesture, CancelGesture, Update.';

  FController := nil;
  FProfile := epNormal;
  ApplyProfileDefaults;

  FCurrentCooldown := 0.0;
  FLastGesture := agNone;
  FCurrentPriority := prIdle;

  ClearError;
end;

procedure TAIAvatarBehavior.ApplyProfileDefaults;
begin
  // Perfis de Expressividade (Tarefas 74 e 75)
  case FProfile of
    epReserved:
      begin
        FMaxIntensity := 0.45;
        FGestureCooldown := 3.5;
      end;
    epNormal:
      begin
        FMaxIntensity := 0.75;
        FGestureCooldown := 2.0;
      end;
    epExpressive:
      begin
        FMaxIntensity := 0.90;
        FGestureCooldown := 1.2;
      end;
    epVeryExpressive:
      begin
        FMaxIntensity := 1.00;
        FGestureCooldown := 0.6;
      end;
  end;
end;

procedure TAIAvatarBehavior.SetController(AValue: TAIAvatarController);
begin
  if FController <> AValue then
  begin
    FController := AValue;
    if FController <> nil then
      FController.FreeNotification(Self);
  end;
end;

procedure TAIAvatarBehavior.SetProfile(AValue: TAIAvatarExpressivenessProfile);
begin
  FProfile := AValue;
  ApplyProfileDefaults;
end;

procedure TAIAvatarBehavior.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FController) then
    FController := nil;
end;

function TAIAvatarBehavior.CanExecuteGesture(AGesture: TAIAvatarGesture): Boolean;
begin
  Result := False;
  if AGesture = agNone then Exit;

  // Regra de Gesto: Cooldown contra repeticao excessiva do mesmo gesto (Tarefa 73)
  if (AGesture = FLastGesture) and (FCurrentCooldown > 0.0) then
  begin
    Log(llDebug, Format('Gesture %s blocked by cooldown (%.2fs remaining)',
      [AvatarGestureToString(AGesture), FCurrentCooldown]));
    Exit;
  end;

  Result := True;
end;

procedure TAIAvatarBehavior.ApplyIntent(const AResponse: TAIAvatarResponse);
var
  EffectiveIntensity: Single;
begin
  if FController = nil then Exit;

  // 1. Regra de Intensidade (Tarefa 74)
  EffectiveIntensity := Min(AResponse.Intensity, FMaxIntensity);

  // 2. Regra de Emocao (Tarefa 72)
  FController.SetEmotion(AResponse.Emotion, EffectiveIntensity);

  // 3. Gerenciamento de Prioridade e Gestos (Tarefas 73, 76)
  if (AResponse.Gesture <> agNone) and CanExecuteGesture(AResponse.Gesture) then
  begin
    FLastGesture := AResponse.Gesture;
    FCurrentCooldown := FGestureCooldown;
    FCurrentPriority := prGesture;
    FController.PlayGesture(AResponse.Gesture);
  end;

  // 4. Look target e estado
  FController.LookAt(AResponse.LookTarget);

  if AResponse.State <> avIdle then
    FController.SetState(AResponse.State);
end;

procedure TAIAvatarBehavior.CancelGesture;
begin
  if FController <> nil then
    FController.CancelGesture;
  FCurrentPriority := prIdle;
end;

procedure TAIAvatarBehavior.Update(DeltaTimeSec: Single);
begin
  if FCurrentCooldown > 0.0 then
  begin
    FCurrentCooldown := FCurrentCooldown - DeltaTimeSec;
    if FCurrentCooldown < 0.0 then
      FCurrentCooldown := 0.0;
  end;
end;

initialization
  {$I aiavatarcontroller_icon.lrs}

end.
