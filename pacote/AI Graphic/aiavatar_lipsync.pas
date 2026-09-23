unit aiavatar_lipsync;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIAvatarLipSync: Sincronismo Labial por Amplitude e Visemas (Tarefas 61 a 65, 70)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, aiavatartypes, aiskeletonrig, LResources;

type
  { Visemas Padronizados (Tarefa 70) }
  TAIAvatarViseme = (
    visemeNeutral,
    visemeA,
    visemeE,
    visemeI,
    visemeO,
    visemeU,
    visemeMBP,
    visemeFV
  );

  { TAIAvatarLipSync }

  TAIAvatarLipSync = class(TAIBaseComponent)
  private
    FSkeleton: TAISkeletonRig;
    FActive: Boolean;
    FMaxJawAngle: Single;
    FSilenceThreshold: Single;
    FSmoothFactor: Single;

    FAudioLevel: Single;
    FTargetJawAngle: Single;
    FCurrentJawAngle: Single;
    FCurrentViseme: TAIAvatarViseme;

    procedure SetSkeleton(AValue: TAISkeletonRig);
    procedure ApplyJawRotation(AngleDeg: Single);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;

    // Processamento de Nivel Sonoro (Tarefas 62 a 65)
    procedure ProcessAudioLevel(ALevel: Single);
    procedure SetViseme(AViseme: TAIAvatarViseme; AWeight: Single = 1.0);
    procedure ResetJaw;

    // Atualizacao de Frame
    procedure Update(DeltaTimeSec: Single);

    property CurrentJawAngle: Single read FCurrentJawAngle;
    property CurrentViseme: TAIAvatarViseme read FCurrentViseme;
  published
    property Skeleton: TAISkeletonRig read FSkeleton write SetSkeleton;
    property Active: Boolean read FActive write FActive default True;
    property MaxJawAngle: Single read FMaxJawAngle write FMaxJawAngle;
    property SilenceThreshold: Single read FSilenceThreshold write FSilenceThreshold;
    property SmoothFactor: Single read FSmoothFactor write FSmoothFactor;
    property AudioLevel: Single read FAudioLevel write FAudioLevel;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAvatarLipSync]);
end;

{ TAIAvatarLipSync }

constructor TAIAvatarLipSync.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAvatarLipSync converts audio amplitude levels or phonetic visemes into smoothed mandibular (hbJaw) bone rotations. Properties: Skeleton, Active, MaxJawAngle, SilenceThreshold, SmoothFactor, AudioLevel. Methods: ProcessAudioLevel, SetViseme, ResetJaw, Update.';

  FSkeleton := nil;
  FActive := True;
  FMaxJawAngle := 18.0;      // maxima abertura em graus
  FSilenceThreshold := 0.04; // abaixo disso eh considerado silencio
  FSmoothFactor := 0.35;     // filtro exponencial de suavizacao

  FAudioLevel := 0.0;
  FTargetJawAngle := 0.0;
  FCurrentJawAngle := 0.0;
  FCurrentViseme := visemeNeutral;

  ClearError;
end;

procedure TAIAvatarLipSync.SetSkeleton(AValue: TAISkeletonRig);
begin
  if FSkeleton <> AValue then
  begin
    FSkeleton := AValue;
    if FSkeleton <> nil then
      FSkeleton.FreeNotification(Self);
  end;
end;

procedure TAIAvatarLipSync.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSkeleton) then
    FSkeleton := nil;
end;

procedure TAIAvatarLipSync.ProcessAudioLevel(ALevel: Single);
var
  ClampedLevel: Single;
begin
  if not FActive then Exit;

  // Clampar nivel entre 0.0 e 1.0
  ClampedLevel := Max(0.0, Min(1.0, ALevel));
  FAudioLevel := ClampedLevel;

  // Detector de silencio (Tarefa 64)
  if ClampedLevel < FSilenceThreshold then
  begin
    FTargetJawAngle := 0.0;
  end
  else
  begin
    // Mapeamento linear de amplitude para graus de rotacao (Tarefa 62)
    FTargetJawAngle := ((ClampedLevel - FSilenceThreshold) / (1.0 - FSilenceThreshold)) * FMaxJawAngle;
  end;
end;

procedure TAIAvatarLipSync.SetViseme(AViseme: TAIAvatarViseme; AWeight: Single);
begin
  FCurrentViseme := AViseme;
  if not FActive then Exit;

  case AViseme of
    visemeNeutral: FTargetJawAngle := 0.0;
    visemeA:       FTargetJawAngle := FMaxJawAngle * 1.00 * AWeight;
    visemeO:       FTargetJawAngle := FMaxJawAngle * 0.75 * AWeight;
    visemeE:       FTargetJawAngle := FMaxJawAngle * 0.50 * AWeight;
    visemeU:       FTargetJawAngle := FMaxJawAngle * 0.40 * AWeight;
    visemeI:       FTargetJawAngle := FMaxJawAngle * 0.30 * AWeight;
    visemeFV:      FTargetJawAngle := FMaxJawAngle * 0.20 * AWeight;
    visemeMBP:     FTargetJawAngle := 0.0; // labios fechados
  else
    FTargetJawAngle := 0.0;
  end;
end;

procedure TAIAvatarLipSync.ApplyJawRotation(AngleDeg: Single);
var
  BoneName: string;
begin
  if FSkeleton = nil then Exit;

  // Rotacionar mandibula se existir no esqueleto (Tarefas 63 e 96)
  if FSkeleton.HasHumanoidBone(hbJaw) then
  begin
    BoneName := FSkeleton.GetMappedBoneName(hbJaw);
    if BoneName <> '' then
    begin
      // Rotacao em X (abertura para baixo)
      FSkeleton.SetBoneRotation(BoneName, AngleDeg, 0.0, 0.0);
      FSkeleton.UpdateFK;
    end;
  end;
end;

procedure TAIAvatarLipSync.ResetJaw;
begin
  FTargetJawAngle := 0.0;
  FCurrentJawAngle := 0.0;
  FAudioLevel := 0.0;
  FCurrentViseme := visemeNeutral;
  ApplyJawRotation(0.0);
end;

procedure TAIAvatarLipSync.Update(DeltaTimeSec: Single);
var
  Diff: Single;
  Step: Single;
begin
  if not FActive then Exit;

  // Filtro exponencial simples de suavizacao (Tarefa 65)
  Diff := FTargetJawAngle - FCurrentJawAngle;
  Step := Diff * FSmoothFactor;

  FCurrentJawAngle := FCurrentJawAngle + Step;

  if Abs(FCurrentJawAngle) < 0.05 then
    FCurrentJawAngle := 0.0;

  ApplyJawRotation(FCurrentJawAngle);
end;

end.
