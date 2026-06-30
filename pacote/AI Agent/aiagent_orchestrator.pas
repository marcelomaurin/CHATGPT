unit aiagent_orchestrator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core,
  aiagent_classifier, aiagent_decision, aiagent_actionbuilder, aiagent_executor, LResources;

type
  { TAIAgentOrchestrator }
  TAIAgentOrchestrator = class(TAIBaseComponent)
  private
    FChatGPT: TCHATGPT;
    FMapaDeMemoria: TAIMapaDeMemoria;
    FCriarMapaAutomaticamente: Boolean;
    FRepassarMapaParaAgentes: Boolean;
    FClassifier: TAIClassifierAgent;
    FDecisionAgent: TAIDecisionAgent;
    FActionBuilder: TAIActionBuilderAgent;
    FExecutor: TAIActionExecutor;
    // Events
    FOnBeforeFlowStart: TAIFluxoEtapaControlEvent;
    FOnAfterFlowStart: TAIFluxoEtapaEvent;
    FOnBeforeClassifier: TAIFluxoEtapaControlEvent;
    FOnAfterClassifier: TAIFluxoEtapaEvent;
    FOnBeforeSelectDecisionAgents: TAIFluxoEtapaControlEvent;
    FOnAfterSelectDecisionAgents: TAIFluxoEtapaEvent;
    FOnBeforeDecisionAgent: TAIFluxoEtapaControlEvent;
    FOnAfterDecisionAgent: TAIFluxoEtapaEvent;
    FOnBeforeActionBuilder: TAIFluxoEtapaControlEvent;
    FOnAfterActionBuilder: TAIFluxoEtapaEvent;
    FOnBeforeExecutor: TAIFluxoEtapaControlEvent;
    FOnAfterExecutor: TAIFluxoEtapaEvent;
    FOnBeforeActionExecute: TAIFluxoEtapaControlEvent;
    FOnAfterActionExecute: TAIFluxoEtapaEvent;
    FOnInformationLossDetected: TAIFluxoEtapaEvent;
    FOnFlowError: TAIFluxoEtapaEvent;
    FOnFlowCanceled: TAIFluxoEtapaEvent;
    FOnFlowFinished: TAIFluxoEtapaEvent;
    FOnFlowStage: TAIFluxoEtapaEvent;
    function DoFlowStage(
      AEtapa: TAIFluxoEtapa;
      AContexto: TAIFluxoEtapaContexto;
      ABeforeEvent: TAIFluxoEtapaControlEvent;
      AAfterEvent: TAIFluxoEtapaEvent
    ): Boolean;
    procedure SetClassifier(AValue: TAIClassifierAgent);
    procedure SetDecisionAgent(AValue: TAIDecisionAgent);
    procedure SetActionBuilder(AValue: TAIActionBuilderAgent);
    procedure SetExecutor(AValue: TAIActionExecutor);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Run(const AInput: string): Boolean; virtual;
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property MapaDeMemoria: TAIMapaDeMemoria read FMapaDeMemoria write FMapaDeMemoria;
    property CriarMapaAutomaticamente: Boolean read FCriarMapaAutomaticamente write FCriarMapaAutomaticamente default True;
    property RepassarMapaParaAgentes: Boolean read FRepassarMapaParaAgentes write FRepassarMapaParaAgentes default True;
    property Classifier: TAIClassifierAgent read FClassifier write SetClassifier;
    property DecisionAgent: TAIDecisionAgent read FDecisionAgent write SetDecisionAgent;
    property ActionBuilder: TAIActionBuilderAgent read FActionBuilder write SetActionBuilder;
    property Executor: TAIActionExecutor read FExecutor write SetExecutor;
    // Events
    property OnBeforeFlowStart: TAIFluxoEtapaControlEvent read FOnBeforeFlowStart write FOnBeforeFlowStart;
    property OnAfterFlowStart: TAIFluxoEtapaEvent read FOnAfterFlowStart write FOnAfterFlowStart;
    property OnBeforeClassifier: TAIFluxoEtapaControlEvent read FOnBeforeClassifier write FOnBeforeClassifier;
    property OnAfterClassifier: TAIFluxoEtapaEvent read FOnAfterClassifier write FOnAfterClassifier;
    property OnBeforeSelectDecisionAgents: TAIFluxoEtapaControlEvent read FOnBeforeSelectDecisionAgents write FOnBeforeSelectDecisionAgents;
    property OnAfterSelectDecisionAgents: TAIFluxoEtapaEvent read FOnAfterSelectDecisionAgents write FOnAfterSelectDecisionAgents;
    property OnBeforeDecisionAgent: TAIFluxoEtapaControlEvent read FOnBeforeDecisionAgent write FOnBeforeDecisionAgent;
    property OnAfterDecisionAgent: TAIFluxoEtapaEvent read FOnAfterDecisionAgent write FOnAfterDecisionAgent;
    property OnBeforeActionBuilder: TAIFluxoEtapaControlEvent read FOnBeforeActionBuilder write FOnBeforeActionBuilder;
    property OnAfterActionBuilder: TAIFluxoEtapaEvent read FOnAfterActionBuilder write FOnAfterActionBuilder;
    property OnBeforeExecutor: TAIFluxoEtapaControlEvent read FOnBeforeExecutor write FOnBeforeExecutor;
    property OnAfterExecutor: TAIFluxoEtapaEvent read FOnAfterExecutor write FOnAfterExecutor;
    property OnBeforeActionExecute: TAIFluxoEtapaControlEvent read FOnBeforeActionExecute write FOnBeforeActionExecute;
    property OnAfterActionExecute: TAIFluxoEtapaEvent read FOnAfterActionExecute write FOnAfterActionExecute;
    property OnInformationLossDetected: TAIFluxoEtapaEvent read FOnInformationLossDetected write FOnInformationLossDetected;
    property OnFlowError: TAIFluxoEtapaEvent read FOnFlowError write FOnFlowError;
    property OnFlowCanceled: TAIFluxoEtapaEvent read FOnFlowCanceled write FOnFlowCanceled;
    property OnFlowFinished: TAIFluxoEtapaEvent read FOnFlowFinished write FOnFlowFinished;
    property OnFlowStage: TAIFluxoEtapaEvent read FOnFlowStage write FOnFlowStage;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [
    TAIAgentOrchestrator,
    TAIClassifierAgent,
    TAIDecisionAgent,
    TAIActionBuilderAgent,
    TAIActionExecutor
  ]);
end;

{ TAIAgentOrchestrator }

constructor TAIAgentOrchestrator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCriarMapaAutomaticamente := True;
  FRepassarMapaParaAgentes := True;
  FClassifier := nil;
  FDecisionAgent := nil;
  FActionBuilder := nil;
  FExecutor := nil;
end;

destructor TAIAgentOrchestrator.Destroy;
begin
  inherited Destroy;
end;

procedure TAIAgentOrchestrator.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FChatGPT then FChatGPT := nil;
    if AComponent = FMapaDeMemoria then FMapaDeMemoria := nil;
    if AComponent = FClassifier then FClassifier := nil;
    if AComponent = FDecisionAgent then FDecisionAgent := nil;
    if AComponent = FActionBuilder then FActionBuilder := nil;
    if AComponent = FExecutor then FExecutor := nil;
  end;
end;

procedure TAIAgentOrchestrator.SetClassifier(AValue: TAIClassifierAgent);
begin
  if FClassifier <> AValue then
  begin
    FClassifier := AValue;
    if FClassifier <> nil then FClassifier.FreeNotification(Self);
  end;
end;

procedure TAIAgentOrchestrator.SetDecisionAgent(AValue: TAIDecisionAgent);
begin
  if FDecisionAgent <> AValue then
  begin
    FDecisionAgent := AValue;
    if FDecisionAgent <> nil then FDecisionAgent.FreeNotification(Self);
  end;
end;

procedure TAIAgentOrchestrator.SetActionBuilder(AValue: TAIActionBuilderAgent);
begin
  if FActionBuilder <> AValue then
  begin
    FActionBuilder := AValue;
    if FActionBuilder <> nil then FActionBuilder.FreeNotification(Self);
  end;
end;

procedure TAIAgentOrchestrator.SetExecutor(AValue: TAIActionExecutor);
begin
  if FExecutor <> AValue then
  begin
    FExecutor := AValue;
    if FExecutor <> nil then FExecutor.FreeNotification(Self);
  end;
end;

function TAIAgentOrchestrator.DoFlowStage(
  AEtapa: TAIFluxoEtapa;
  AContexto: TAIFluxoEtapaContexto;
  ABeforeEvent: TAIFluxoEtapaControlEvent;
  AAfterEvent: TAIFluxoEtapaEvent
): Boolean;
var
  CanContinue: Boolean;
begin
  Result := True;
  AContexto.Etapa := AEtapa;

  if Assigned(ABeforeEvent) then
  begin
    CanContinue := True;
    ABeforeEvent(Self, AContexto, CanContinue);
    if not CanContinue or AContexto.CancelarFluxo then
    begin
      AContexto.CancelarFluxo := True;
      Result := False;
    end;
  end;

  if Assigned(FOnFlowStage) then
    FOnFlowStage(Self, AContexto);

  if Result and Assigned(AAfterEvent) then
  begin
    AAfterEvent(Self, AContexto);
    if Assigned(FOnFlowStage) then
      FOnFlowStage(Self, AContexto);
  end;
end;

function TAIAgentOrchestrator.Run(const AInput: string): Boolean;
var
  Ctx: TAIFluxoEtapaContexto;
  TempOutput: string;
  StatusMapItem: TAIMapaDeMemoriaItem;
  HasLostInfo: Boolean;
  LostInfoStr: string;
begin
  Result := False;
  ClearError;

  // 1. Manage Memory Map Auto creation
  if (FMapaDeMemoria = nil) and FCriarMapaAutomaticamente then
  begin
    FMapaDeMemoria := TAIMapaDeMemoria.Create(Self);
  end;

  if FMapaDeMemoria = nil then
  begin
    SetError('Mapa de Memória não está disponível e não foi possível criar automaticamente.');
    Exit;
  end;

  // Repass map
  if FRepassarMapaParaAgentes then
  begin
    if Assigned(FClassifier) then FClassifier.MapaDeMemoria := FMapaDeMemoria;
    if Assigned(FDecisionAgent) then FDecisionAgent.MapaDeMemoria := FMapaDeMemoria;
    if Assigned(FActionBuilder) then FActionBuilder.MapaDeMemoria := FMapaDeMemoria;
    if Assigned(FExecutor) then FExecutor.MapaDeMemoria := FMapaDeMemoria;
  end;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := FMapaDeMemoria.SessionId;
    Ctx.FlowName := 'Multi-Agent Orchestrator Flow';
    Ctx.PedidoOriginal := AInput;
    Ctx.PedidoAtual := AInput;
    Ctx.MapaDeMemoria := FMapaDeMemoria;

    // Start Flow stage
    if not DoFlowStage(afeInicioFluxo, Ctx, FOnBeforeFlowStart, FOnAfterFlowStart) then
    begin
      if Assigned(FOnFlowCanceled) then
        FOnFlowCanceled(Self, Ctx);
      Exit;
    end;

    FMapaDeMemoria.StartFlow(AInput, Ctx.FlowName);

    // 2. Classifier
    if Assigned(FClassifier) then
    begin
      if not DoFlowStage(afeAntesClassificador, Ctx, FOnBeforeClassifier, nil) then
      begin
        if Assigned(FOnFlowCanceled) then FOnFlowCanceled(Self, Ctx);
        Exit;
      end;

      if not FClassifier.Classify(Ctx.PedidoAtual, TempOutput) then
      begin
        Ctx.MensagemErro := FClassifier.LastError;
        if Assigned(FOnFlowError) then FOnFlowError(Self, Ctx);
        Exit;
      end;

      Ctx.PedidoAtual := TempOutput;
      DoFlowStage(afeDepoisClassificador, Ctx, nil, FOnAfterClassifier);
    end;

    // 3. Decision Agents
    if Assigned(FDecisionAgent) then
    begin
      if not DoFlowStage(afeAntesDecisor, Ctx, FOnBeforeDecisionAgent, nil) then
      begin
        if Assigned(FOnFlowCanceled) then FOnFlowCanceled(Self, Ctx);
        Exit;
      end;

      if not FDecisionAgent.Decide(Ctx.PedidoAtual, TempOutput) then
      begin
        Ctx.MensagemErro := FDecisionAgent.LastError;
        if Assigned(FOnFlowError) then FOnFlowError(Self, Ctx);
        Exit;
      end;

      Ctx.PedidoAtual := TempOutput;
      DoFlowStage(afeDepoisDecisor, Ctx, nil, FOnAfterDecisionAgent);
    end;

    // 4. Action Builder (Ajustador)
    if Assigned(FActionBuilder) then
    begin
      if not DoFlowStage(afeAntesAjustadorAcao, Ctx, FOnBeforeActionBuilder, nil) then
      begin
        if Assigned(FOnFlowCanceled) then FOnFlowCanceled(Self, Ctx);
        Exit;
      end;

      if not FActionBuilder.BuildActions(Ctx.PedidoAtual, TempOutput) then
      begin
        Ctx.MensagemErro := FActionBuilder.LastError;
        if Assigned(FOnFlowError) then FOnFlowError(Self, Ctx);
        Exit;
      end;

      Ctx.PedidoAtual := TempOutput;
      DoFlowStage(afeDepoisAjustadorAcao, Ctx, nil, FOnAfterActionBuilder);
    end;

    // 5. Action Executor
    if Assigned(FExecutor) then
    begin
      if not DoFlowStage(afeAntesExecutor, Ctx, FOnBeforeExecutor, nil) then
      begin
        if Assigned(FOnFlowCanceled) then FOnFlowCanceled(Self, Ctx);
        Exit;
      end;

      if not FExecutor.ExecutePlan(Ctx.PedidoAtual, TempOutput) then
      begin
        Ctx.MensagemErro := FExecutor.LastError;
        if Assigned(FOnFlowError) then FOnFlowError(Self, Ctx);
        Exit;
      end;

      Ctx.SaidaAtual := TempOutput;
      DoFlowStage(afeDepoisExecutor, Ctx, nil, FOnAfterExecutor);
    end;

    // Check Info loss at final flow
    StatusMapItem := FMapaDeMemoria.LastItem;
    if Assigned(StatusMapItem) then
    begin
      HasLostInfo := FMapaDeMemoria.CheckInformationLoss(StatusMapItem, LostInfoStr);
      if HasLostInfo then
      begin
        Ctx.Alertas.Add('Perda de informação detectada: ' + LostInfoStr);
        if Assigned(FOnInformationLossDetected) then
          FOnInformationLossDetected(Self, Ctx);
      end;
    end;

    // Finish flow
    DoFlowStage(afeFimFluxo, Ctx, nil, FOnFlowFinished);
    Result := True;

  finally
    Ctx.Free;
  end;
end;

initialization
  {$I taiagentorchestrator_icon.lrs}

end.
