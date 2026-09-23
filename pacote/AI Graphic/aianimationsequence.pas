unit aianimationsequence;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIAnimationSequence: Player de Animacao, Fila, Blending e Procedural Idle
  (Tarefas 30 a 37)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, aiavatartypes, aimodel3d, LResources;

type
  { Item da Fila de Animacoes (Tarefa 35) }
  TQueuedAnimation = record
    Name: string;
    Loop: Boolean;
    Speed: Single;
    Priority: Integer;
    Cancelable: Boolean;
  end;

  { TAIAnimationSequence }

  TAIAnimationSequence = class(TAIBaseComponent)
  private
    FModel: TAIModel3D;
    FCurrentAnimation: string;
    FLoop: Boolean;
    FSpeed: Single;
    FDuration: Single;
    FCurrentTime: Single;
    FBlendTime: Single;
    FCurrentBlendTime: Single;
    FPriority: Integer;
    FCancelable: Boolean;
    FIsPlaying: Boolean;
    FIsPaused: Boolean;
    FProceduralIdle: Boolean;
    FIdlePhase: Single;

    FQueue: array of TQueuedAnimation;
    FOnAnimationFinished: TNotifyEvent;
    FOnFrame: TNotifyEvent;

    procedure SetSpeed(AValue: Single);
    procedure SetModel(AValue: TAIModel3D);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    
    // Controle de Reproducao (Tarefas 30, 31, 32, 33)
    procedure PlayAnimation(const AName: string = '');
    procedure PauseAnimation;
    procedure ResumeAnimation;
    procedure StopAnimation;
    
    // Gerenciamento de Fila (Tarefa 35)
    procedure QueueAnimation(const AName: string; ALoop: Boolean = False; ASpeed: Single = 1.0; APriority: Integer = 0; ACancelable: Boolean = True);
    procedure ClearQueue;
    function GetQueueCount: Integer;

    // Atualizacao de Frame e Blending (Tarefas 36 e 37)
    procedure Update(DeltaTimeSec: Single);

    property CurrentTime: Single read FCurrentTime write FCurrentTime;
    property CurrentAnimation: string read FCurrentAnimation;
    property IsPlaying: Boolean read FIsPlaying;
    property IsPaused: Boolean read FIsPaused;
    property Duration: Single read FDuration;
  published
    property Model: TAIModel3D read FModel write SetModel;
    property Loop: Boolean read FLoop write FLoop default False;
    property Speed: Single read FSpeed write SetSpeed;
    property BlendTime: Single read FBlendTime write FBlendTime;
    property Priority: Integer read FPriority write FPriority default 0;
    property Cancelable: Boolean read FCancelable write FCancelable default True;
    property ProceduralIdle: Boolean read FProceduralIdle write FProceduralIdle default True;

    property OnAnimationFinished: TNotifyEvent read FOnAnimationFinished write FOnAnimationFinished;
    property OnFrame: TNotifyEvent read FOnFrame write FOnFrame;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAnimationSequence]);
end;

{ TAIAnimationSequence }

constructor TAIAnimationSequence.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAnimationSequence manages animation playback, queueing, interpolation, blending and procedural idle for 3D avatars. Properties: Model, CurrentAnimation, Loop, Speed, BlendTime, Priority, ProceduralIdle. Methods: PlayAnimation, PauseAnimation, StopAnimation, QueueAnimation, Update.';
  FModel := nil;
  FCurrentAnimation := '';
  FLoop := False;
  FSpeed := 1.0;
  FDuration := 0.0;
  FCurrentTime := 0.0;
  FBlendTime := 0.25; // 250 ms default
  FCurrentBlendTime := 0.0;
  FPriority := 0;
  FCancelable := True;
  FIsPlaying := False;
  FIsPaused := False;
  FProceduralIdle := True;
  FIdlePhase := 0.0;
  SetLength(FQueue, 0);
  ClearError;
end;

procedure TAIAnimationSequence.SetSpeed(AValue: Single);
begin
  if AValue < 0.01 then AValue := 0.01;
  FSpeed := AValue;
end;

procedure TAIAnimationSequence.SetModel(AValue: TAIModel3D);
begin
  if FModel <> AValue then
  begin
    FModel := AValue;
    if FModel <> nil then
      FModel.FreeNotification(Self);
  end;
end;

procedure TAIAnimationSequence.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FModel) then
    FModel := nil;
end;

procedure TAIAnimationSequence.PlayAnimation(const AName: string);
var
  TargetName: string;
  Anim: TAIAvatarAnimation;
begin
  TargetName := Trim(AName);
  if (TargetName = '') and (FCurrentAnimation <> '') then
    TargetName := FCurrentAnimation;

  if TargetName = '' then
  begin
    // Se o modelo possuir animacoes, pega a primeira (ex: Idle)
    if (FModel <> nil) and (FModel.GetAnimationCount > 0) then
      TargetName := FModel.Animations[0].Name
    else
      TargetName := 'Idle';
  end;

  FCurrentAnimation := TargetName;
  FCurrentTime := 0.0;
  FCurrentBlendTime := FBlendTime;
  FIsPlaying := True;
  FIsPaused := False;

  // Obter duracao se disponivel no modelo
  if (FModel <> nil) and FModel.FindAnimation(TargetName, Anim) then
    FDuration := Anim.Duration
  else
    FDuration := 1.0; // fallback procedural

  Log(llInfo, Format('Playing animation: "%s" (Duration: %.2fs, Loop: %s, Speed: %.1fx)',
    [FCurrentAnimation, FDuration, BoolToStr(FLoop, True), FSpeed]));
  FLastResult := 'Animation playing: ' + FCurrentAnimation;
  FLastSuccess := True;
end;

procedure TAIAnimationSequence.PauseAnimation;
begin
  if FIsPlaying then
  begin
    FIsPaused := True;
    FIsPlaying := False;
    Log(llInfo, 'Animation paused: ' + FCurrentAnimation);
  end;
end;

procedure TAIAnimationSequence.ResumeAnimation;
begin
  if FIsPaused then
  begin
    FIsPlaying := True;
    FIsPaused := False;
    Log(llInfo, 'Animation resumed: ' + FCurrentAnimation);
  end;
end;

procedure TAIAnimationSequence.StopAnimation;
begin
  FIsPlaying := False;
  FIsPaused := False;
  FCurrentTime := 0.0;
  Log(llInfo, 'Animation stopped.');
  FLastResult := 'Animation stopped.';
  FLastSuccess := True;
end;

procedure TAIAnimationSequence.QueueAnimation(const AName: string; ALoop: Boolean; ASpeed: Single; APriority: Integer; ACancelable: Boolean);
var
  Idx: Integer;
begin
  Idx := Length(FQueue);
  SetLength(FQueue, Idx + 1);
  FQueue[Idx].Name := AName;
  FQueue[Idx].Loop := ALoop;
  FQueue[Idx].Speed := ASpeed;
  FQueue[Idx].Priority := APriority;
  FQueue[Idx].Cancelable := ACancelable;

  Log(llDebug, Format('Queued animation: "%s" (Pos: %d)', [AName, Idx + 1]));

  // Se nao houver animacao tocando, inicia imediatamente
  if not FIsPlaying and not FIsPaused then
  begin
    FLoop := ALoop;
    FSpeed := ASpeed;
    FPriority := APriority;
    FCancelable := ACancelable;
    PlayAnimation(AName);
    // Remove o item iniciado da fila
    Delete(FQueue, 0, 1);
  end;
end;

procedure TAIAnimationSequence.ClearQueue;
begin
  SetLength(FQueue, 0);
  Log(llDebug, 'Animation queue cleared.');
end;

function TAIAnimationSequence.GetQueueCount: Integer;
begin
  Result := Length(FQueue);
end;

procedure TAIAnimationSequence.Update(DeltaTimeSec: Single);
var
  EffectiveDelta: Single;
  NextItem: TQueuedAnimation;
begin
  // Avanco do Procedural Idle independente ou integrado
  FIdlePhase := FIdlePhase + DeltaTimeSec * 2.0;
  if FIdlePhase > 2.0 * Pi then
    FIdlePhase := FIdlePhase - 2.0 * Pi;

  if not FIsPlaying or FIsPaused then
  begin
    // Se estiver em idle procedural e nenhum clipe tocando
    if FProceduralIdle and Assigned(FOnFrame) then
      FOnFrame(Self);
    Exit;
  end;

  EffectiveDelta := DeltaTimeSec * FSpeed;
  FCurrentTime := FCurrentTime + EffectiveDelta;

  // Reduzir contagem de blend time
  if FCurrentBlendTime > 0.0 then
  begin
    FCurrentBlendTime := FCurrentBlendTime - DeltaTimeSec;
    if FCurrentBlendTime < 0.0 then
      FCurrentBlendTime := 0.0;
  end;

  // Checar fim da duracao
  if (FDuration > 0.0) and (FCurrentTime >= FDuration) then
  begin
    if FLoop then
    begin
      // Retorno ao inicio (Tarefa 31)
      FCurrentTime := FCurrentTime - FDuration;
    end
    else
    begin
      // Termino da animacao nao-loop (Tarefa 33)
      FIsPlaying := False;
      FCurrentTime := FDuration;
      Log(llInfo, 'Animation finished: ' + FCurrentAnimation);

      if Assigned(FOnAnimationFinished) then
        FOnAnimationFinished(Self);

      // Consumir proxima animacao da fila (Tarefa 35)
      if Length(FQueue) > 0 then
      begin
        NextItem := FQueue[0];
        Delete(FQueue, 0, 1);
        FLoop := NextItem.Loop;
        FSpeed := NextItem.Speed;
        FPriority := NextItem.Priority;
        FCancelable := NextItem.Cancelable;
        PlayAnimation(NextItem.Name);
      end;
    end;
  end;

  if Assigned(FOnFrame) then
    FOnFrame(Self);
end;

initialization
  {$I aianimationsequence_icon.lrs}

end.
