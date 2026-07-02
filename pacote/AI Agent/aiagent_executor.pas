unit aiagent_executor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core, aiagent_actions, LResources;

type
  TAIActionBeforeExecuteEvent = procedure(
    Sender: TObject;
    const AActionName: string;
    AParams: TStrings;
    AExecutionContext: TStrings
  ) of object;

  TAIActionAfterExecuteEvent = procedure(
    Sender: TObject;
    const AActionName: string;
    AParams: TStrings;
    AResult: TStrings;
    AExecutionContext: TStrings
  ) of object;

  // New events for Fase 1 (Tarefa 9, 10)
  TAIExecutorBeforePreparedActionEvent = procedure(
    Sender: TObject;
    const AActionName: string;
    AParams: TStrings;
    AExecutionContext: TStrings;
    var ACanExecute: Boolean
  ) of object;

  TAIExecutorAfterPreparedActionEvent = procedure(
    Sender: TObject;
    const AActionName: string;
    AParams: TStrings;
    AExecutionContext: TStrings;
    AResult: TStrings
  ) of object;

  { TAIActionExecutor }
  TAIActionExecutor = class(TAIBaseComponent)
  private
    FMemoryMap: TAIAgentMemoryMap;
    FChatGPT: TCHATGPT;
    FNomeAgente: string;
    FTipoAgenteMapa: TAITipoAgenteMapa;
    FForcarSimulacaoGlobal: Boolean;
    FAutoRegistrarNoMapa: Boolean;
    FExecutionContext: TStringList;
    FRegisteredActions: TList; // Tarefa 2
    // Events
    FOnBeforeExecutePlan: TAIFluxoEtapaControlEvent;
    FOnAfterExecutePlan: TAIFluxoEtapaEvent;
    FOnBeforeExecutePlanItem: TAIFluxoEtapaControlEvent;
    FOnAfterExecutePlanItem: TAIFluxoEtapaEvent;
    FOnBeforeRealExecution: TAIFluxoEtapaControlEvent;
    FOnAfterRealExecution: TAIFluxoEtapaEvent;
    FOnBeforeSimulation: TAIFluxoEtapaControlEvent;
    FOnAfterSimulation: TAIFluxoEtapaEvent;
    FOnExecutionBlocked: TAIFluxoEtapaEvent;
    FOnExecutionFailed: TAIFluxoEtapaEvent;
    FOnBeforeActionExecute: TAIActionBeforeExecuteEvent;
    FOnAfterActionExecute: TAIActionAfterExecuteEvent;
    FOnBeforePreparedAction: TAIExecutorBeforePreparedActionEvent; // Tarefa 9
    FOnAfterPreparedAction: TAIExecutorAfterPreparedActionEvent; // Tarefa 10

    function FindActionByName(const AActionName: string): TAICustomAgentAction; // Tarefa 6
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetMemoryMap(AValue: TAIAgentMemoryMap);
  public
    property MapaDeMemoria: TAIAgentMemoryMap read FMemoryMap write SetMemoryMap;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override; // Tarefa 4
    procedure ClearExecutionContext; // Tarefa 8
    procedure RegisterAction(AAction: TAICustomAgentAction); // Tarefa 5
    function ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean; virtual;
    function ExecutePreparedActionsReal(const APreparedActionsJSON: string; out AOutput: string): Boolean; // Tarefa 11
    property ExecutionContext: TStringList read FExecutionContext; // Tarefa 7
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property MemoryMap: TAIAgentMemoryMap read FMemoryMap write SetMemoryMap;
    property NomeAgente: string read FNomeAgente write FNomeAgente;
    property TipoAgenteMapa: TAITipoAgenteMapa read FTipoAgenteMapa write FTipoAgenteMapa default tamExecutor;
    property ForcarSimulacaoGlobal: Boolean read FForcarSimulacaoGlobal write FForcarSimulacaoGlobal default False;
    property AutoRegistrarNoMapa: Boolean read FAutoRegistrarNoMapa write FAutoRegistrarNoMapa default True;
    // Events
    property OnBeforeExecutePlan: TAIFluxoEtapaControlEvent read FOnBeforeExecutePlan write FOnBeforeExecutePlan;
    property OnAfterExecutePlan: TAIFluxoEtapaEvent read FOnAfterExecutePlan write FOnAfterExecutePlan;
    property OnBeforeExecutePlanItem: TAIFluxoEtapaControlEvent read FOnBeforeExecutePlanItem write FOnBeforeExecutePlanItem;
    property OnAfterExecutePlanItem: TAIFluxoEtapaEvent read FOnAfterExecutePlanItem write FOnAfterExecutePlanItem;
    property OnBeforeRealExecution: TAIFluxoEtapaControlEvent read FOnBeforeRealExecution write FOnBeforeRealExecution;
    property OnAfterRealExecution: TAIFluxoEtapaEvent read FOnAfterRealExecution write FOnAfterRealExecution;
    property OnBeforeSimulation: TAIFluxoEtapaControlEvent read FOnBeforeSimulation write FOnBeforeSimulation;
    property OnAfterSimulation: TAIFluxoEtapaEvent read FOnAfterSimulation write FOnAfterSimulation;
    property OnExecutionBlocked: TAIFluxoEtapaEvent read FOnExecutionBlocked write FOnExecutionBlocked;
    property OnExecutionFailed: TAIFluxoEtapaEvent read FOnExecutionFailed write FOnExecutionFailed;
    property OnBeforeActionExecute: TAIActionBeforeExecuteEvent read FOnBeforeActionExecute write FOnBeforeActionExecute;
    property OnAfterActionExecute: TAIActionAfterExecuteEvent read FOnAfterActionExecute write FOnAfterActionExecute;
    property OnBeforePreparedAction: TAIExecutorBeforePreparedActionEvent read FOnBeforePreparedAction write FOnBeforePreparedAction;
    property OnAfterPreparedAction: TAIExecutorAfterPreparedActionEvent read FOnAfterPreparedAction write FOnAfterPreparedAction;
  end;

implementation

{ TAIActionExecutor }

procedure TAIActionExecutor.SetMemoryMap(AValue: TAIAgentMemoryMap);
begin
  if FMemoryMap <> AValue then
  begin
    if Assigned(FMemoryMap) then
      FMemoryMap.RemoveFreeNotification(Self);

    FMemoryMap := AValue;

    if Assigned(FMemoryMap) then
      FMemoryMap.FreeNotification(Self);
  end;
end;

constructor TAIActionExecutor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FNomeAgente := 'ActionExecutor';
  FTipoAgenteMapa := tamExecutor;
  FForcarSimulacaoGlobal := False;
  FAutoRegistrarNoMapa := True;
  FExecutionContext := TStringList.Create;
  FRegisteredActions := TList.Create; // Tarefa 3
end;

destructor TAIActionExecutor.Destroy;
begin
  FreeAndNil(FRegisteredActions); // Tarefa 4
  FreeAndNil(FExecutionContext);
  inherited Destroy;
end;

procedure TAIActionExecutor.ClearExecutionContext;
begin
  if Assigned(FExecutionContext) then
    FExecutionContext.Clear;
end;

procedure TAIActionExecutor.RegisterAction(AAction: TAICustomAgentAction);
begin
  if not Assigned(AAction) then
    Exit;

  if FRegisteredActions.IndexOf(AAction) < 0 then
    FRegisteredActions.Add(AAction);
end;

function TAIActionExecutor.FindActionByName(const AActionName: string): TAICustomAgentAction;
var
  I: Integer;
  A: TAICustomAgentAction;
begin
  Result := nil;
  for I := 0 to FRegisteredActions.Count - 1 do
  begin
    A := TAICustomAgentAction(FRegisteredActions[I]);
    if SameText(A.ActionName, AActionName) then
    begin
      Result := A;
      Exit;
    end;
  end;
end;

procedure TAIActionExecutor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FChatGPT then FChatGPT := nil;
    if AComponent = FMemoryMap then FMemoryMap := nil;
  end;
end;

function TAIActionExecutor.ExecutePreparedActionsReal(const APreparedActionsJSON: string; out AOutput: string): Boolean;
var
  JSONData: TJSONData;
  Obj, ActObj, ParamsObj: TJSONObject;
  ActionsArr: TJSONArray;
  ItemData: TJSONData;
  ParamsData: TJSONData;
  ActionName: string;
  Params: TStringList;
  ActionResultList: TStringList;
  CleanJSON: string;
  i, j: Integer;
  ActionOk: Boolean;
  ActionObj: TAICustomAgentAction;
  CanExecute: Boolean;
  MemItem: TAIAgentMemoryMapItem;
begin
  Result := False;
  AOutput := '';
  ClearError;

  // Tarefa 11
  if Trim(APreparedActionsJSON) = '' then
  begin
    SetError('Plano de ações vazio.');
    Exit;
  end;

  CleanJSON := CleanJSONResponse(APreparedActionsJSON);

  try
    JSONData := GetJSON(CleanJSON);
  except
    on E: Exception do
    begin
      SetError(
        'JSON inválido recebido pelo ExecutePreparedActionsReal: ' +
        E.Message +
        sLineBreak +
        'Trecho recebido: ' +
        Copy(CleanJSON, 1, 1000)
      );
      Exit(False);
    end;
  end;

  try
    try
      ActionsArr := nil;

      // Tarefa 12 & 13
      if JSONData is TJSONObject then
      begin
        Obj := TJSONObject(JSONData);
        ParamsData := Obj.Find('actions');
        if Assigned(ParamsData) and (ParamsData is TJSONArray) then
          ActionsArr := TJSONArray(ParamsData)
        else
        begin
          SetError('Plano de ações não possui array "actions" no objeto.');
          Exit;
        end;
      end
      else if JSONData is TJSONArray then
        ActionsArr := TJSONArray(JSONData)
      else
      begin
        SetError('Plano de ações não é objeto nem array JSON.');
        Exit;
      end;

      if ActionsArr.Count = 0 then
      begin
        SetError('O array "actions" está vazio.');
        Exit;
      end;

      Params := TStringList.Create;
      try
        Result := True;

        for i := 0 to ActionsArr.Count - 1 do
        begin
          ItemData := ActionsArr.Items[i];
          if not (ItemData is TJSONObject) then
            Continue;

          ActObj := TJSONObject(ItemData);
          
          // Tarefa 14
          ActionName := Trim(ActObj.Get('action', ''));
          if ActionName = '' then
            ActionName := Trim(ActObj.Get('name', ''));

          if ActionName = '' then
          begin
            SetError(Format('Ação %d sem campo "action/name".', [i]));
            Result := False;
            Exit;
          end;

          Params.Clear;
          ParamsData := ActObj.Find('parameters');
          if Assigned(ParamsData) and (ParamsData is TJSONObject) then
          begin
            ParamsObj := TJSONObject(ParamsData);
            for j := 0 to ParamsObj.Count - 1 do
              Params.Values[ParamsObj.Names[j]] := ParamsObj.Items[j].AsString;
          end;

          // Tarefa 15
          ActionObj := FindActionByName(ActionName);
          if not Assigned(ActionObj) then
          begin
            SetError(
              'Ação não registrada no executor: ' + ActionName +
              '. Verifique WireRuntimeObjects/RegisterAction.'
            );
            Result := False;
            Exit;
          end;

          // Tarefa 16 — Evento antes
          CanExecute := True;
          if Assigned(FOnBeforePreparedAction) then
            FOnBeforePreparedAction(Self, ActionName, Params, FExecutionContext, CanExecute);

          if not CanExecute then
          begin
            SetError('Ação bloqueada pelo evento: ' + ActionName);
            Result := False;
            Exit;
          end;

          // Tarefa 18 — Registrar início no MemoryMap
          MemItem := nil;
          if Assigned(MapaDeMemoria) and FAutoRegistrarNoMapa then
          begin
            MemItem := MapaDeMemoria.BeginAgentStep(FNomeAgente + '_' + ActionName, FTipoAgenteMapa, Params.Text, '');
          end;

          // Executar ação real
          ActionOk := False;
          try
            ActionOk := ActionObj.RunAction(Params, FForcarSimulacaoGlobal);
          except
            on E: Exception do
            begin
              SetError(Format('Exception na ação "%s": %s', [ActionName, E.Message]));
            end;
          end;

          AOutput := AOutput + Format('Action=%s Result=%s', [ActionName, BoolToStr(ActionOk, True)]) + sLineBreak;

          if not ActionOk then
          begin
            if ActionObj.LastError <> '' then
              SetError('Falha na ação "' + ActionName + '": ' + ActionObj.LastError)
            else if LastError = '' then
              SetError('Falha na ação "' + ActionName + '" sem mensagem de erro.');
          end;

          // Tarefa 18 — Registrar conclusão no MemoryMap
          if Assigned(MemItem) and Assigned(MapaDeMemoria) then
          begin
            if ActionOk then
              MapaDeMemoria.EndAgentStep(MemItem, 'Ação executada com sucesso.', '', 'SUCCESS', '')
            else
              MapaDeMemoria.EndAgentStep(MemItem, 'Falha ao executar ação: ' + LastError, '', 'ERROR', '');
          end;

          // Tarefa 17 — Evento depois
          if ActionOk then
          begin
            ActionResultList := TStringList.Create;
            try
              // If it has results properties from the specific actions, we could fetch them.
              // We pass it to the event.
              if Assigned(FOnAfterPreparedAction) then
                FOnAfterPreparedAction(Self, ActionName, Params, FExecutionContext, ActionResultList);
            finally
              ActionResultList.Free;
            end;
          end;

          if not ActionOk then
          begin
            Result := False;
            Exit;
          end;
        end;
      finally
        Params.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao executar plano preparado: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    JSONData.Free;
  end;
end;

function TAIActionExecutor.ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean;
var
  Item: TAIAgentMemoryMapItem;
  CanContinue: Boolean;
  Ctx: TAIFluxoEtapaContexto;
  LPrompt, ResponseText: string;
  JSONData: TJSONData;
  Obj: TJSONObject;
  Confidence: Double;
  I: Integer;
  PArr: TJSONArray;
  PObj: TJSONObject;
begin
  Result := False;
  AOutput := '';
  ClearError;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MapaDeMemoria.SessionId;
    Ctx.FlowName := 'Executor de Ações';
    Ctx.PedidoOriginal := AInputPlan;
    Ctx.PedidoAtual := AInputPlan;
    Ctx.NomeAgenteAtual := FNomeAgente;
    Ctx.TipoAgenteAtual := FTipoAgenteMapa;
    Ctx.ForcarSimulacao := FForcarSimulacaoGlobal;

    if Assigned(MapaDeMemoria) then
      Ctx.ContextoAtual := MapaDeMemoria.BuildContextForAgent(FNomeAgente, FTipoAgenteMapa);

    // Trigger BeforeExecutePlan
    CanContinue := True;
    if Assigned(FOnBeforeExecutePlan) then
      FOnBeforeExecutePlan(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      SetError('Execução de plano cancelada pelo evento OnBeforeExecutePlan.');
      if Assigned(FOnExecutionBlocked) then
        FOnExecutionBlocked(Self, Ctx);
      Exit;
    end;

    // Begin Memory Map Step
    Item := nil;
    if Assigned(MapaDeMemoria) and FAutoRegistrarNoMapa then
    begin
      Item := MapaDeMemoria.BeginAgentStep(FNomeAgente, FTipoAgenteMapa, Ctx.PedidoAtual, Ctx.ContextoAtual);
    end;

    // Build Prompt
    LPrompt := 'You are an Action Execution Agent.' + sLineBreak;
    LPrompt := LPrompt + sLineBreak +
      '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
      'Simule ou execute as ações solicitadas e retorne o resultado de cada uma.' + sLineBreak +
      'Retorne EXCLUSIVAMENTE um objeto JSON estruturado da seguinte forma:' + sLineBreak +
      '{' + sLineBreak +
      '  "confidence": 0.99,' + sLineBreak +
      '  "analysis": "sua análise sobre a execução",' + sLineBreak +
      '  "explanation": "explicação sobre os passos de execução",' + sLineBreak +
      '  "action_taken": "ACTION_EXECUTED_SIMULATION",' + sLineBreak +
      '  "execution_result": "Detalhes dos resultados obtidos",' + sLineBreak +
      '  "analysis_questions": [' + sLineBreak +
      '    {"question": "A ação está validada?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
      '    {"question": "A execução deve ser simulada ou real?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "O risco da ação permite execução?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Existe componente alvo associado?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "A execução foi concluída?", "answer": "...", "analysis": "...", "confidence": 0.9}' +
      '  ]' + sLineBreak +
      '}' + sLineBreak + sLineBreak +
      '=== MEMORY MAP SO FAR ===' + sLineBreak + Ctx.ContextoAtual + sLineBreak +
      '=== PLAN TO EXECUTE ===' + sLineBreak + Ctx.PedidoAtual;

    // Check if simulation is forced
    if Ctx.ForcarSimulacao then
    begin
      CanContinue := True;
      if Assigned(FOnBeforeSimulation) then
        FOnBeforeSimulation(Self, Ctx, CanContinue);
      
      // We append simulation command to prompt instructions
      LPrompt := LPrompt + sLineBreak + sLineBreak + 'CRITICAL WARNING: FORÇAR APENAS SIMULAÇÃO. NÃO execute comandos reais.';
    end
    else
    begin
      CanContinue := True;
      if Assigned(FOnBeforeRealExecution) then
        FOnBeforeRealExecution(Self, Ctx, CanContinue);
    end;

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT is not connected to the Executor.');
      if Assigned(Item) and Assigned(MapaDeMemoria) then
        MapaDeMemoria.EndAgentStep(Item, 'Hardware error', 'ChatGPT is not connected', 'ERROR', '');
      Exit;
    end;

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Network error while executing plan: ' + ChatGPT.LastError);
      if Assigned(Item) and Assigned(MapaDeMemoria) then
        MapaDeMemoria.EndAgentStep(Item, 'Network error', ChatGPT.LastError, 'ERROR', '');
      if Assigned(FOnExecutionFailed) then
        FOnExecutionFailed(Self, Ctx);
      Exit;
    end;

    ResponseText := CleanJSONResponse(ChatGPT.Response);
    AOutput := ResponseText;

    // Parse JSON
    try
      JSONData := GetJSON(ResponseText);
      try
        if JSONData is TJSONObject then
        begin
          Obj := TJSONObject(JSONData);
          Confidence := Obj.Get('confidence', 1.0);
          Ctx.AnaliseAtual := Obj.Get('analysis', '');
          Ctx.ExplicacaoAtual := Obj.Get('explanation', '');
          Ctx.AcaoTomada := Obj.Get('action_taken', 'ACTION_EXECUTED_SIMULATION');
          Ctx.SaidaAtual := ResponseText;

          // Register questions
          PArr := Obj.Arrays['analysis_questions'];
          if Assigned(PArr) and Assigned(Item) and Assigned(MapaDeMemoria) then
          begin
            for I := 0 to PArr.Count - 1 do
            begin
              PObj := PArr.Objects[I];
              MapaDeMemoria.AddQuestion(
                Item,
                PObj.Get('question', ''),
                PObj.Get('answer', ''),
                PObj.Get('analysis', ''),
                'LLM',
                PObj.Get('confidence', 0.0)
              );
            end;
          end;

          if Ctx.ForcarSimulacao then
          begin
            if Assigned(FOnAfterSimulation) then
              FOnAfterSimulation(Self, Ctx);
          end;

          if Assigned(FOnAfterRealExecution) then
            FOnAfterRealExecution(Self, Ctx);
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao interpretar JSON do executor: ' + E.Message);
        if Assigned(Item) and Assigned(MapaDeMemoria) then
          MapaDeMemoria.EndAgentStep(Item, 'Erro de análise', E.Message, 'ERROR', ResponseText);
        Exit;
      end;
    end;

    if Assigned(Item) and Assigned(MapaDeMemoria) then
    begin
      Item.SaidaGerada := AOutput;
      Item.Confianca := Confidence;
      MapaDeMemoria.EndAgentStep(Item, Ctx.AnaliseAtual, Ctx.ExplicacaoAtual, Ctx.AcaoTomada, Ctx.SaidaAtual);
    end;

    Result := True;

    if Assigned(FOnAfterExecutePlan) then
      FOnAfterExecutePlan(Self, Ctx);
  finally
    Ctx.Free;
  end;
end;

initialization
  {$I taiactionexecutor_icon.lrs}

end.
