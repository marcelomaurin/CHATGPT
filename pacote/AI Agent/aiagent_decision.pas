unit aiagent_decision;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core, LResources;

type
  { TAIDecisionAgent }
  TAIDecisionAgent = class(TAICustomAgent)
  private
    FOnBeforeDecision: TAIFluxoEtapaControlEvent;
    FOnAfterDecision: TAIFluxoEtapaEvent;
    FOnBeforeActionPlanCreate: TAIFluxoEtapaControlEvent;
    FOnAfterActionPlanCreate: TAIFluxoEtapaEvent;
    FOnBeforeAddActionToPlan: TAIFluxoEtapaControlEvent;
    FOnAfterAddActionToPlan: TAIFluxoEtapaEvent;
    FOnInvalidActionSelected: TAIFluxoEtapaEvent;
    FOnDecisionLowConfidence: TAIFluxoEtapaEvent;

    // Tarefa 2: Campos privados para recuperação do processamento
    FAutoRecoverInvalidProcessInput: Boolean;
    FMaxProcessRecoverAttempts: Integer;
    FLastProcessRawOutput: string;
    FLastProcessRecoveredOutput: string;
    FLastProcessValidationError: string;

    // Métodos auxiliares privados de processamento
    function GetTaskProcessorSchema: string;
    function BuildTaskProcessorPrompt(const AInput: string; const AMemoryContext: string; const ASchemaText: string): string;
    function ValidateTaskProcessorInput(const AInput: string; out AError: string): Boolean;
    function ValidateTaskProcessorOutput(const AJSON: string; out AError: string): Boolean;
    function BuildTaskProcessorRecoverPrompt(const AOriginalInput: string; const AMemoryContext: string; const AInvalidOutput: string; const AValidationError: string; const ASchemaText: string): string;
    function RecoverInvalidTaskProcessorOutput(const AOriginalInput: string; const AMemoryContext: string; const AInvalidOutput: string; const AValidationError: string; const ASchemaText: string; out ARecoveredOutput: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function Decide(const AInput: string; out AOutput: string): Boolean; virtual;
    function DecideAsTaskList(const AInput: string; out AOutput: string): Boolean; virtual;
    // Tarefa 1: Criar método ProcessTask na interface
    function ProcessTask(const AInput: string; out AOutput: string): Boolean; virtual;
    // Tarefa 24: Criar helper para extrair result
    function ExtractTaskProcessResult(const AProcessorJSON: string; out AResultText: string): Boolean;
  published
    property OnBeforeDecision: TAIFluxoEtapaControlEvent read FOnBeforeDecision write FOnBeforeDecision;
    property OnAfterDecision: TAIFluxoEtapaEvent read FOnAfterDecision write FOnAfterDecision;
    property OnBeforeActionPlanCreate: TAIFluxoEtapaControlEvent read FOnBeforeActionPlanCreate write FOnBeforeActionPlanCreate;
    property OnAfterActionPlanCreate: TAIFluxoEtapaEvent read FOnAfterActionPlanCreate write FOnAfterActionPlanCreate;
    property OnBeforeAddActionToPlan: TAIFluxoEtapaControlEvent read FOnBeforeAddActionToPlan write FOnBeforeAddActionToPlan;
    property OnAfterAddActionToPlan: TAIFluxoEtapaEvent read FOnAfterAddActionToPlan write FOnAfterAddActionToPlan;
    property OnInvalidActionSelected: TAIFluxoEtapaEvent read FOnInvalidActionSelected write FOnInvalidActionSelected;
    property OnDecisionLowConfidence: TAIFluxoEtapaEvent read FOnDecisionLowConfidence write FOnDecisionLowConfidence;

    // Tarefa 3: Criar propriedades publicadas
    property AutoRecoverInvalidProcessInput: Boolean
      read FAutoRecoverInvalidProcessInput
      write FAutoRecoverInvalidProcessInput
      default True;

    property MaxProcessRecoverAttempts: Integer
      read FMaxProcessRecoverAttempts
      write FMaxProcessRecoverAttempts
      default 1;

    property LastProcessRawOutput: string read FLastProcessRawOutput;
    property LastProcessRecoveredOutput: string read FLastProcessRecoveredOutput;
    property LastProcessValidationError: string read FLastProcessValidationError;
  end;

implementation

function LimitTextForLLM(const AText: string; AMaxChars: Integer): string;
begin
  if AMaxChars <= 0 then
  begin
    Result := '';
    Exit;
  end;

  if Length(AText) <= AMaxChars then
    Result := AText
  else
    Result :=
      Copy(AText, 1, AMaxChars) +
      sLineBreak +
      sLineBreak +
      '[TEXTO CORTADO: conteúdo original possuía ' +
      IntToStr(Length(AText)) +
      ' caracteres]';
end;

{ TAIDecisionAgent }

constructor TAIDecisionAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNomeAgente := 'DecisionAgent';
  FTipoAgenteMapa := tamDecisor;

  // Tarefa 4: Inicializar propriedades no constructor
  FAutoRecoverInvalidProcessInput := True;
  FMaxProcessRecoverAttempts := 1;
  FLastProcessRawOutput := '';
  FLastProcessRecoveredOutput := '';
  FLastProcessValidationError := '';
end;

function TAIDecisionAgent.Decide(const AInput: string; out AOutput: string): Boolean;
var
  Item: TAIAgentMemoryMapItem;
  CanContinue: Boolean;
  Ctx: TAIFluxoEtapaContexto;
  LPrompt, ResponseText: string;
  JSONData: TJSONData;
  Obj, ActObj: TJSONObject;
  Confidence: Double;
  I: Integer;
  PArr, ActionsArr: TJSONArray;
  PObj: TJSONObject;
  ActionName: string;
begin
  Result := False;
  AOutput := '';
  ClearError;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MapaDeMemoria.SessionId;
    Ctx.FlowName := 'Decisão';
    Ctx.PedidoOriginal := AInput;
    Ctx.PedidoAtual := AInput;
    Ctx.NomeAgenteAtual := FNomeAgente;
    Ctx.TipoAgenteAtual := FTipoAgenteMapa;

    if Assigned(MapaDeMemoria) then
      Ctx.ContextoAtual := MapaDeMemoria.BuildContextForAgent(FNomeAgente, FTipoAgenteMapa);

    // Trigger BeforeDecision
    CanContinue := True;
    if Assigned(FOnBeforeDecision) then
      FOnBeforeDecision(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      SetError('Processo de decisão cancelado pelo evento OnBeforeDecision.');
      Exit;
    end;

    // Begin Memory Map Step
    Item := BeginMemoryStep(Ctx.PedidoAtual);

    // Build Prompt
    LPrompt := 'You are a Decision Agent.' + sLineBreak;
    if SystemPrompt <> '' then
      LPrompt := LPrompt + SystemPrompt + sLineBreak;
    
    LPrompt := LPrompt + sLineBreak +
      '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
      'Você DEVE analisar o pedido e o mapa de memória para selecionar uma ou mais ações.' + sLineBreak +
      'Retorne EXCLUSIVAMENTE um objeto JSON estruturado da seguinte forma:' + sLineBreak +
      '{' + sLineBreak +
      '  "confidence": 0.95,' + sLineBreak +
      '  "analysis": "sua análise sobre o caso aqui",' + sLineBreak +
      '  "explanation": "explicação da escolha de ações",' + sLineBreak +
      '  "action_taken": "ACTION_PLAN_CREATED",' + sLineBreak +
      '  "actions": [' + sLineBreak +
      '    {' + sLineBreak +
      '      "action": "NOME_DA_ACAO",' + sLineBreak +
      '      "parameters": {' + sLineBreak +
      '        "parametro1": "valor1"' + sLineBreak +
      '      }' + sLineBreak +
      '    }' + sLineBreak +
      '  ],' + sLineBreak +
      '  "analysis_questions": [' + sLineBreak +
      '    {"question": "A classificação recebida é suficiente?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
      '    {"question": "Alguma informação importante da solicitação original se perdeu?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Que ações são permitidas para este domínio?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Uma ação é suficiente ou são necessárias múltiplas ações?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Quais parâmetros mínimos cada ação precisa?", "answer": "...", "analysis": "...", "confidence": 0.9}' +
      '  ]' + sLineBreak +
      '}' + sLineBreak + sLineBreak +
      '=== MEMORY MAP SO FAR ===' + sLineBreak + Ctx.ContextoAtual + sLineBreak +
      '=== RECEIVED REQUEST AT THIS STAGE ===' + sLineBreak + Ctx.PedidoAtual;

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT is not connected to the decision agent.');
      if Assigned(Item) then
        EndMemoryStep(Item, 'Hardware error', 'ChatGPT is not connected', 'ERROR', '');
      Exit;
    end;

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Network error while deciding: ' + ChatGPT.LastError);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Network error', ChatGPT.LastError, 'ERROR', '');
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
          Ctx.AcaoTomada := Obj.Get('action_taken', 'ACTION_PLAN_CREATED');
          Ctx.SaidaAtual := ResponseText;

          // Register questions
          PArr := Obj.Arrays['analysis_questions'];
          if Assigned(PArr) and Assigned(Item) then
          begin
            for I := 0 to PArr.Count - 1 do
            begin
              PObj := PArr.Objects[I];
              AddMemoryQuestion(
                Item,
                PObj.Get('question', ''),
                PObj.Get('answer', ''),
                PObj.Get('analysis', ''),
                'LLM',
                PObj.Get('confidence', 0.0)
              );
            end;
          end;

          if Confidence < FMinConfidence then
          begin
            if Assigned(FOnDecisionLowConfidence) then
              FOnDecisionLowConfidence(Self, Ctx);
          end;

          // Trigger Action Plan events
          CanContinue := True;
          if Assigned(FOnBeforeActionPlanCreate) then
            FOnBeforeActionPlanCreate(Self, Ctx, CanContinue);

          if CanContinue then
          begin
            ActionsArr := Obj.Arrays['actions'];
            if Assigned(ActionsArr) then
            begin
              for I := 0 to ActionsArr.Count - 1 do
              begin
                ActObj := ActionsArr.Objects[I];
                ActionName := ActObj.Get('action', '');
                
                CanContinue := True;
                if Assigned(FOnBeforeAddActionToPlan) then
                  FOnBeforeAddActionToPlan(Self, Ctx, CanContinue);
                
                if not CanContinue then
                begin
                  if Assigned(FOnInvalidActionSelected) then
                    FOnInvalidActionSelected(Self, Ctx);
                end;

                if Assigned(FOnAfterAddActionToPlan) then
                  FOnAfterAddActionToPlan(Self, Ctx);
              end;
            end;
          end;

          if Assigned(FOnAfterActionPlanCreate) then
            FOnAfterActionPlanCreate(Self, Ctx);

          Ctx.NomeProximoAgente := 'ActionBuilderAgent';
          Ctx.TipoProximoAgente := tamAjustadorAcao;
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao interpretar JSON de decisão: ' + E.Message);
        if Assigned(Item) then
          EndMemoryStep(Item, 'Erro de análise', E.Message, 'ERROR', ResponseText);
        Exit;
      end;
    end;

    if Assigned(Item) then
    begin
      Item.SaidaGerada := AOutput;
      Item.Confianca := Confidence;
      EndMemoryStep(Item, Ctx.AnaliseAtual, Ctx.ExplicacaoAtual, Ctx.AcaoTomada, Ctx.SaidaAtual);
    end;

    Result := True;

    if Assigned(FOnAfterDecision) then
      FOnAfterDecision(Self, Ctx);
  finally
    Ctx.Free;
  end;
end;

function TAIDecisionAgent.DecideAsTaskList(const AInput: string; out AOutput: string): Boolean;
var
  Item: TAIAgentMemoryMapItem;
  CanContinue: Boolean;
  Ctx: TAIFluxoEtapaContexto;
  LPrompt, ResponseText, CorrectPrompt: string;
  JSONData: TJSONData;
  Obj: TJSONObject;
  HasTasks, HasActions: Boolean;
  D: TJSONData;
begin
  Result := False;
  AOutput := '';
  ClearError;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MapaDeMemoria.SessionId;
    Ctx.FlowName := 'Planejamento de Tarefas';
    Ctx.PedidoOriginal := AInput;
    Ctx.PedidoAtual := AInput;
    Ctx.NomeAgenteAtual := FNomeAgente;
    Ctx.TipoAgenteAtual := FTipoAgenteMapa;

    if Assigned(MapaDeMemoria) then
      Ctx.ContextoAtual := MapaDeMemoria.BuildContextForAgent(FNomeAgente, FTipoAgenteMapa);

    // Trigger BeforeDecision
    CanContinue := True;
    if Assigned(FOnBeforeDecision) then
      FOnBeforeDecision(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      SetError('Processo de decisão cancelado pelo evento OnBeforeDecision.');
      Exit;
    end;

    // Begin Memory Map Step
    Item := BeginMemoryStep(Ctx.PedidoAtual);

    // Build Prompt
    LPrompt := 'You are a Task Planner Agent.' + sLineBreak;
    if SystemPrompt <> '' then
      LPrompt := LPrompt + SystemPrompt + sLineBreak;
    
    LPrompt := LPrompt + sLineBreak +
      '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
      'Você deve planejar a lista de tarefas necessárias para atender ao pedido.' + sLineBreak +
      'Retorne EXCLUSIVAMENTE um objeto JSON no seguinte formato (schema de tarefas):' + sLineBreak +
      '{' + sLineBreak +
      '  "tasks": [' + sLineBreak +
      '    {' + sLineBreak +
      '      "id": "T001",' + sLineBreak +
      '      "order": 1,' + sLineBreak +
      '      "type": "content|action|condition",' + sLineBreak +
      '      "description": "descrição da tarefa",' + sLineBreak +
      '      "agent": "nome_do_agente",' + sLineBreak +
      '      "suggested_action": "nome_da_acao",' + sLineBreak +
      '      "depends_on": "ID_da_dependencia_se_houver_ou_vazio"' + sLineBreak +
      '    }' + sLineBreak +
      '  ]' + sLineBreak +
      '}' + sLineBreak + sLineBreak +
      '=== DIRETRIZES BROWSER E AUTOMAÇÃO REAL ===' + sLineBreak +
      'As ações sugeridas para automação de browser permitidas são:' + sLineBreak +
      '- BROWSER_NAVIGATE (url)' + sLineBreak +
      '- BROWSER_READ_PAGE (selector, dom_list_selector)' + sLineBreak +
      '- BROWSER_DOM_LIST (selector)' + sLineBreak +
      '- BROWSER_WAIT_SELECTOR (selector, timeout)' + sLineBreak +
      '- BROWSER_SET_VALUE (selector, index, value)' + sLineBreak +
      '- BROWSER_FOCUS (selector, index)' + sLineBreak +
      '- BROWSER_CLICK (selector, index)' + sLineBreak +
      '- BROWSER_PRESS_ENTER (selector, index)' + sLineBreak +
      '- BROWSER_SUBMIT_FORM (selector, index)' + sLineBreak +
      '- BROWSER_CAPTURE_TEXT (selector)' + sLineBreak +
      '- BROWSER_SCREENSHOT (filename)' + sLineBreak + sLineBreak +
      'REGRAS OBRIGATÓRIAS BROWSER:' + sLineBreak +
      '1. Regra de Leitura Prévia: Antes de qualquer ação que manipula o DOM (como BROWSER_SET_VALUE, BROWSER_CLICK, BROWSER_PRESS_ENTER ou BROWSER_SUBMIT_FORM), gere OBRIGATORIAMENTE uma tarefa anterior do tipo BROWSER_READ_PAGE ou BROWSER_DOM_LIST, exceto se o seletor CSS específico foi fornecido explicitamente no pedido.' + sLineBreak +
      '2. Fluxo para Pesquisa: Quando o pedido do usuário for realizar uma pesquisa/busca em um site:' + sLineBreak +
      '   - Tarefa 1: Navegar até a URL (BROWSER_NAVIGATE)' + sLineBreak +
      '   - Tarefa 2: Ler/Mapear a página (BROWSER_READ_PAGE ou BROWSER_DOM_LIST)' + sLineBreak +
      '   - Tarefa 3: Preencher campo de busca (BROWSER_SET_VALUE)' + sLineBreak +
      '   - Tarefa 4: Enviar busca (BROWSER_PRESS_ENTER ou BROWSER_SUBMIT_FORM)' + sLineBreak +
      '   - Tarefa 5: Capturar texto dos resultados obtidos (BROWSER_CAPTURE_TEXT)' + sLineBreak + sLineBreak +
      '=== MEMORY MAP SO FAR ===' + sLineBreak + Ctx.ContextoAtual + sLineBreak +
      '=== RECEIVED REQUEST ===' + sLineBreak + Ctx.PedidoAtual;

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT is not connected to the decision agent.');
      if Assigned(Item) then
        EndMemoryStep(Item, 'Hardware error', 'ChatGPT is not connected', 'ERROR', '');
      Exit;
    end;

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Network error while deciding tasks: ' + ChatGPT.LastError);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Network error', ChatGPT.LastError, 'ERROR', '');
      Exit;
    end;

    ResponseText := CleanJSONResponse(ChatGPT.Response);

    // Validate response
    HasTasks := False;
    HasActions := False;
    try
      JSONData := GetJSON(ResponseText);
      try
        if JSONData is TJSONObject then
        begin
          Obj := TJSONObject(JSONData);
          D := Obj.Find('tasks');
          if Assigned(D) and (D is TJSONArray) then
            HasTasks := True;

          D := Obj.Find('actions');
          if Assigned(D) and (D is TJSONArray) then
            HasActions := True;
        end;
      finally
        JSONData.Free;
      end;
    except
    end;

    // Retry if actions returned instead of tasks
    if HasActions and (not HasTasks) then
    begin
      CorrectPrompt := 'You previously returned a list of actions instead of a list of tasks.' + sLineBreak +
        'Please correct your response to follow the tasks schema instead of the actions schema.' + sLineBreak +
        'Schema correto:' + sLineBreak +
        '{' + sLineBreak +
        '  "tasks": [' + sLineBreak +
        '    {' + sLineBreak +
        '      "id": "T001",' + sLineBreak +
        '      "order": 1,' + sLineBreak +
        '      "type": "content|action|condition",' + sLineBreak +
        '      "description": "descrição da tarefa",' + sLineBreak +
        '      "agent": "nome_do_agente",' + sLineBreak +
        '      "suggested_action": "nome_da_acao",' + sLineBreak +
        '      "depends_on": "ID_da_dependencia_se_houver_ou_vazio"' + sLineBreak +
        '    }' + sLineBreak +
        '  ]' + sLineBreak +
        '}' + sLineBreak + sLineBreak +
        '=== RESPOSTA ANTERIOR INVÁLIDA ===' + sLineBreak + ResponseText + sLineBreak +
        '=== MEMORY MAP ===' + sLineBreak + Ctx.ContextoAtual;

      if ChatGPT.SendQuestion(CorrectPrompt) then
      begin
        ResponseText := CleanJSONResponse(ChatGPT.Response);
      end;
    end;

    AOutput := ResponseText;
    
    if Assigned(Item) then
    begin
      Item.SaidaGerada := AOutput;
      Item.Confianca := 1.0;
      EndMemoryStep(Item, 'Planejamento de tarefas concluído', '', 'DECISION_TASKLIST_CREATED', AOutput);
    end;

    Result := True;

    if Assigned(FOnAfterDecision) then
      FOnAfterDecision(Self, Ctx);
  finally
    Ctx.Free;
  end;
end;

function TAIDecisionAgent.GetTaskProcessorSchema: string;
begin
  Result :=
    '{' + sLineBreak +
    '  "confidence": 0.95,' + sLineBreak +
    '  "analysis": "Análise da tarefa recebida",' + sLineBreak +
    '  "explanation": "Explicação do processamento feito",' + sLineBreak +
    '  "action_taken": "TASK_PROCESSED",' + sLineBreak +
    '  "result_type": "text",' + sLineBreak +
    '  "result": "Conteúdo final produzido pela tarefa",' + sLineBreak +
    '  "missing_information": "",' + sLineBreak +
    '  "analysis_questions": []' + sLineBreak +
    '}';
end;

function TAIDecisionAgent.BuildTaskProcessorPrompt(
  const AInput: string;
  const AMemoryContext: string;
  const ASchemaText: string
): string;
var
  LPromptText: string;
begin
  LPromptText :=
    'Você é um agente processador de tarefas.' + sLineBreak + sLineBreak +
    'Analise a tarefa recebida.' + sLineBreak +
    'Execute mentalmente somente a tarefa solicitada.' + sLineBreak +
    'Não invente informações.' + sLineBreak +
    'Use apenas:' + sLineBreak +
    '1. o input recebido;' + sLineBreak +
    '2. o mapa de memória;' + sLineBreak +
    '3. resultados anteriores contidos no contexto.' + sLineBreak + sLineBreak +
    '=== REGRAS DE PROCESSAMENTO POR TIPO DE TAREFA ===' + sLineBreak +
    '1. Se a tarefa for de browser/DOM, não execute a ação no texto. Apenas analise a intenção e retorne em "result" o que deve ser feito, preservando seletores, URL, valor a inserir e ação esperada.' + sLineBreak +
    '2. Se a tarefa for gerar texto, currículo, resumo ou relatório, o campo "result" deve conter o texto final completo.' + sLineBreak +
    '3. Se a tarefa for preparar e-mail, o campo "result" deve conter destinatário, assunto e corpo sugerido, mas não deve enviar e-mail.' + sLineBreak + sLineBreak +
    'Retorne exclusivamente JSON no schema obrigatório.' + sLineBreak + sLineBreak +
    '=== SCHEMA OBRIGATÓRIO ===' + sLineBreak +
    ASchemaText + sLineBreak + sLineBreak +
    '=== CONTEXTO DE MEMÓRIA (MAPA) ===' + sLineBreak +
    AMemoryContext + sLineBreak + sLineBreak +
    '=== TAREFA RECEBIDA (INPUT) ===' + sLineBreak +
    AInput;

  if SystemPrompt <> '' then
    LPromptText := SystemPrompt + sLineBreak + sLineBreak + LPromptText;

  Result := LPromptText;
end;

function TAIDecisionAgent.ValidateTaskProcessorInput(const AInput: string; out AError: string): Boolean;
begin
  Result := False;
  AError := '';

  if Trim(AInput) = '' then
  begin
    AError := 'ProcessorInput vazio.';
    Exit;
  end;

  if Length(Trim(AInput)) < 20 then
  begin
    AError := 'ProcessorInput muito curto.';
    Exit;
  end;

  Result := True;
end;

function TAIDecisionAgent.ValidateTaskProcessorOutput(const AJSON: string; out AError: string): Boolean;
var
  JSONData: TJSONData;
  Obj: TJSONObject;
  ResVal: TJSONData;
  QData: TJSONData;
begin
  Result := False;
  AError := '';

  try
    JSONData := GetJSON(AJSON);
    try
      if not (JSONData is TJSONObject) then
      begin
        AError := 'O retorno não é um objeto JSON válido.';
        Exit;
      end;

      Obj := TJSONObject(JSONData);
      ResVal := Obj.Find('result');
      if not Assigned(ResVal) then
      begin
        AError := 'O campo obrigatório "result" está ausente no JSON.';
        Exit;
      end;

      if Trim(ResVal.AsString) = '' then
      begin
        AError := 'O campo "result" está vazio.';
        Exit;
      end;

      QData := Obj.Find('analysis_questions');
      if Assigned(QData) and not (QData is TJSONArray) then
      begin
        AError := 'O campo "analysis_questions" deve ser um array.';
        Exit;
      end;

      Result := True;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
      AError := 'Falha de parsing do JSON: ' + E.Message;
  end;
end;

function TAIDecisionAgent.BuildTaskProcessorRecoverPrompt(
  const AOriginalInput: string;
  const AMemoryContext: string;
  const AInvalidOutput: string;
  const AValidationError: string;
  const ASchemaText: string
): string;
begin
  Result :=
    'Você recebeu uma saída inválida ou fora do padrão esperado.' + sLineBreak + sLineBreak +
    'O ProcessorInput original não estava vazio.' + sLineBreak +
    'Analise o que está sendo pedido no ProcessorInput.' + sLineBreak +
    'Use também o mapa de memória.' + sLineBreak +
    'Não invente informações.' + sLineBreak +
    'Erro de validação encontrado: ' + AValidationError + sLineBreak + sLineBreak +
    '=== RETORNO INVÁLIDO ANTERIOR ===' + sLineBreak +
    AInvalidOutput + sLineBreak + sLineBreak +
    '=== SCHEMA OBRIGATÓRIO ===' + sLineBreak +
    ASchemaText + sLineBreak + sLineBreak +
    '=== CONTEXTO DE MEMÓRIA (MAPA) ===' + sLineBreak +
    AMemoryContext + sLineBreak + sLineBreak +
    '=== TAREFA ORIGINAL ===' + sLineBreak +
    AOriginalInput + sLineBreak + sLineBreak +
    'Converta a resposta para o schema obrigatório. Retorne somente JSON válido.';
end;

function TAIDecisionAgent.RecoverInvalidTaskProcessorOutput(
  const AOriginalInput: string;
  const AMemoryContext: string;
  const AInvalidOutput: string;
  const AValidationError: string;
  const ASchemaText: string;
  out ARecoveredOutput: string
): Boolean;
var
  LPrompt, ResponseText: string;
  LocalValidationError: string;
begin
  Result := False;
  ARecoveredOutput := '';

  LPrompt := BuildTaskProcessorRecoverPrompt(AOriginalInput, AMemoryContext, AInvalidOutput, AValidationError, ASchemaText);

  if not ChatGPT.SendQuestion(LPrompt) then
    Exit;

  ResponseText := CleanJSONResponse(ChatGPT.Response);
  if ValidateTaskProcessorOutput(ResponseText, LocalValidationError) then
  begin
    ARecoveredOutput := ResponseText;
    Result := True;
  end;
end;

function TAIDecisionAgent.ProcessTask(const AInput: string; out AOutput: string): Boolean;
var
  Item: TAIAgentMemoryMapItem;
  Ctx: TAIFluxoEtapaContexto;
  LPrompt: string;
  ResponseText: string;
  SchemaText: string;
  ValidationError: string;
  RecoveredText: string;
  JSONData: TJSONData;
  Obj: TJSONObject;
  Data: TJSONData;
  Confidence: Double;
  QArr: TJSONArray;
  QItemData: TJSONData;
  QObj: TJSONObject;
  i: Integer;
  // Tarefa 1.2 — Adicionar variáveis seguras em ProcessTask
  SafeInput: string;
  SafeMemoryContext: string;
begin
  Result := False;
  AOutput := '';
  ClearError;

  // Tarefa 8: Não chamar ChatGPT com input vazio ou inválido
  if Trim(AInput) = '' then
  begin
    SetError('ProcessorInput vazio. Não há tarefa para processar.');
    Exit;
  end;

  if not ValidateTaskProcessorInput(AInput, ValidationError) then
  begin
    SetError('ProcessorInput inválido: ' + ValidationError);
    Exit;
  end;

  if not Assigned(ChatGPT) then
  begin
    SetError('ChatGPT is not connected to the decision agent.');
    Exit;
  end;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MapaDeMemoria.SessionId;
    Ctx.FlowName := 'Processamento de Tarefa';
    Ctx.PedidoOriginal := AInput;
    Ctx.PedidoAtual := AInput;
    Ctx.NomeAgenteAtual := FNomeAgente;
    Ctx.TipoAgenteAtual := FTipoAgenteMapa;

    // Tarefa 13: Montar contexto com MemoryMap
    if Assigned(MapaDeMemoria) then
      Ctx.ContextoAtual := MapaDeMemoria.BuildContextForAgent(FNomeAgente, FTipoAgenteMapa);

    // Tarefa 1.3 — Limitar AInput e MemoryMap
    SafeInput := LimitTextForLLM(AInput, 30000);
    SafeMemoryContext := LimitTextForLLM(Ctx.ContextoAtual, 15000);

    // Tarefa 1.4 — Registrar no MemoryMap usando entrada limitada
    Item := BeginMemoryStep(SafeInput);

    // Tarefa 1.5 — Montar prompt com entrada limitada
    SchemaText := GetTaskProcessorSchema;
    LPrompt := BuildTaskProcessorPrompt(SafeInput, SafeMemoryContext, SchemaText);

    // Tarefa 1.6 — Limitar prompt final
    if Length(LPrompt) > 60000 then
      LPrompt := LimitTextForLLM(LPrompt, 60000);

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Network error while processing task: ' + ChatGPT.LastError);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Network error', ChatGPT.LastError, 'ERROR', '');
      Exit;
    end;

    // Tarefa 16: Salvar saída bruta
    ResponseText := CleanJSONResponse(ChatGPT.Response);
    FLastProcessRawOutput := ResponseText;
    FLastProcessRecoveredOutput := '';
    FLastProcessValidationError := '';

    // Tarefa 17: Validar saída inicial
    if not ValidateTaskProcessorOutput(ResponseText, ValidationError) then
    begin
      FLastProcessValidationError := ValidationError;

      // Tarefa 18: Recuperar saída inválida
      if FAutoRecoverInvalidProcessInput then
      begin
        // Tarefa 1.7 — Usar entrada limitada na recuperação
        if RecoverInvalidTaskProcessorOutput(
          SafeInput,
          SafeMemoryContext,
          ResponseText,
          ValidationError,
          SchemaText,
          RecoveredText
        ) then
        begin
          ResponseText := RecoveredText;
          FLastProcessRecoveredOutput := RecoveredText;
        end;
      end;
    end;

    // Tarefa 19: Falhar se recuperação não corrigir
    if not ValidateTaskProcessorOutput(ResponseText, ValidationError) then
    begin
      FLastProcessValidationError := ValidationError;
      SetError('TaskProcessor retornou saída fora do schema esperado: ' + ValidationError);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Validation error', ValidationError, 'ERROR', ResponseText);
      Exit;
    end;

    // Tarefa 20: Extrair campos do JSON final
    JSONData := GetJSON(ResponseText);
    try
      Obj := TJSONObject(JSONData);
      Ctx.AnaliseAtual := Obj.Get('analysis', '');
      Ctx.ExplicacaoAtual := Obj.Get('explanation', '');
      Ctx.AcaoTomada := Obj.Get('action_taken', 'TASK_PROCESSED');
      Ctx.SaidaAtual := ResponseText;
      Confidence := Obj.Get('confidence', 0.95);

      // Tarefa 21: Registrar perguntas com Find
      Data := Obj.Find('analysis_questions');
      if Assigned(Data) and (Data is TJSONArray) then
      begin
        QArr := TJSONArray(Data);
        for i := 0 to QArr.Count - 1 do
        begin
          QItemData := QArr.Items[i];
          if QItemData is TJSONObject then
          begin
            QObj := TJSONObject(QItemData);
            if Assigned(Item) then
              Item.AddPerguntaAnalise(
                QObj.Get('question', ''),
                QObj.Get('answer', ''),
                QObj.Get('analysis', ''),
                'ProcessorAgent',
                QObj.Get('confidence', 1.0)
              );
          end;
        end;
      end;

      AOutput := ResponseText;
      Result := True;

      // Tarefa 22: Registrar fim no MemoryMap
      if Assigned(Item) then
      begin
        Item.SaidaGerada := AOutput;
        Item.Confianca := Confidence;
        EndMemoryStep(Item, Ctx.AnaliseAtual, Ctx.ExplicacaoAtual, Ctx.AcaoTomada, Ctx.SaidaAtual);
      end;
    finally
      JSONData.Free;
    end;
  // Tarefa 1.8 — Corrigir finalização do ProcessTask
  finally
    Ctx.Free;
  end;
end;

function TAIDecisionAgent.ExtractTaskProcessResult(const AProcessorJSON: string; out AResultText: string): Boolean;
var
  JSONData: TJSONData;
  Obj: TJSONObject;
  ResVal: TJSONData;
begin
  Result := False;
  AResultText := '';
  try
    JSONData := GetJSON(AProcessorJSON);
    try
      if JSONData is TJSONObject then
      begin
        Obj := TJSONObject(JSONData);
        ResVal := Obj.Find('result');
        if Assigned(ResVal) then
        begin
          AResultText := ResVal.AsString;
          Result := True;
        end;
      end;
    finally
      JSONData.Free;
    end;
  except
  end;
end;

initialization
  {$I taidecisionagent_icon.lrs}

end.
