unit aiagent_actionbuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core, LResources;

type
  { TAIActionBuilderAgent }
  TAIActionBuilderAgent = class(TAICustomAgent)
  private
    FOnBeforeBuildAction: TAIFluxoEtapaControlEvent;
    FOnAfterBuildAction: TAIFluxoEtapaEvent;
    FOnBeforeValidateParameters: TAIFluxoEtapaControlEvent;
    FOnAfterValidateParameters: TAIFluxoEtapaEvent;
    FOnBeforeApplyDefaults: TAIFluxoEtapaControlEvent;
    FOnAfterApplyDefaults: TAIFluxoEtapaEvent;
    FOnMissingRequiredParameter: TAIFluxoEtapaEvent;
    FOnUnsafeParameterDetected: TAIFluxoEtapaEvent;

    // Recovery fields (Tarefa 1)
    FAutoRecoverInvalidInput: Boolean;
    FMaxRecoverAttempts: Integer;
    FLastRawOutput: string;
    FLastRecoveredOutput: string;
    FLastValidationError: string;

    // Helper methods (Tarefa 4, 5, 6, 9, 10)
    function GetExpectedActionBuilderSchema: string;
    function BuildActionBuilderPrompt(const AInput, AMemoryContext, ASchemaText: string): string;
    function ValidateActionBuilderOutput(const AJSON: string; out AError: string): Boolean;
    function BuildRecoverPrompt(const AOriginalInput, AMemoryContext, AInvalidOutput, AValidationError, ASchemaText: string): string;
    function RecoverInvalidActionBuilderOutput(
      const AOriginalInput, AMemoryContext, AInvalidOutput, AValidationError, ASchemaText: string;
      out ARecoveredOutput: string
    ): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function BuildActions(const AInput: string; out AOutput: string): Boolean; virtual;

    // Strict and Recovery methods (Tarefa 18, 19)
    function BuildActionsStrict(const AInput: string; out AOutput: string): Boolean;
    function BuildActionsWithRecovery(const AInput: string; out AOutput: string): Boolean;
  published
    property OnBeforeBuildAction: TAIFluxoEtapaControlEvent read FOnBeforeBuildAction write FOnBeforeBuildAction;
    property OnAfterBuildAction: TAIFluxoEtapaEvent read FOnAfterBuildAction write FOnAfterBuildAction;
    property OnBeforeValidateParameters: TAIFluxoEtapaControlEvent read FOnBeforeValidateParameters write FOnBeforeValidateParameters;
    property OnAfterValidateParameters: TAIFluxoEtapaEvent read FOnAfterValidateParameters write FOnAfterValidateParameters;
    property OnBeforeApplyDefaults: TAIFluxoEtapaControlEvent read FOnBeforeApplyDefaults write FOnBeforeApplyDefaults;
    property OnAfterApplyDefaults: TAIFluxoEtapaEvent read FOnAfterApplyDefaults write FOnAfterApplyDefaults;
    property OnMissingRequiredParameter: TAIFluxoEtapaEvent read FOnMissingRequiredParameter write FOnMissingRequiredParameter;
    property OnUnsafeParameterDetected: TAIFluxoEtapaEvent read FOnUnsafeParameterDetected write FOnUnsafeParameterDetected;

    // Recovery properties (Tarefa 2)
    property AutoRecoverInvalidInput: Boolean read FAutoRecoverInvalidInput write FAutoRecoverInvalidInput default True;
    property MaxRecoverAttempts: Integer read FMaxRecoverAttempts write FMaxRecoverAttempts default 1;
    property LastRawOutput: string read FLastRawOutput;
    property LastRecoveredOutput: string read FLastRecoveredOutput;
    property LastValidationError: string read FLastValidationError;
  end;

implementation

{ TAIActionBuilderAgent }

constructor TAIActionBuilderAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNomeAgente := 'ActionBuilderAgent';
  FTipoAgenteMapa := tamAjustadorAcao;

  // Initialize properties (Tarefa 3)
  FAutoRecoverInvalidInput := True;
  FMaxRecoverAttempts := 1;
  FLastRawOutput := '';
  FLastRecoveredOutput := '';
  FLastValidationError := '';
end;

function TAIActionBuilderAgent.GetExpectedActionBuilderSchema: string;
begin
  Result :=
    '{' + sLineBreak +
    '  "confidence": 0.98,' + sLineBreak +
    '  "analysis": "sua análise dos parâmetros",' + sLineBreak +
    '  "explanation": "explicação sobre os ajustes e validações realizados",' + sLineBreak +
    '  "action_taken": "ACTION_PARAMETERS_PREPARED",' + sLineBreak +
    '  "actions": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "action": "NOME_DA_ACAO",' + sLineBreak +
    '      "parameters": {' + sLineBreak +
    '        "parametro1": "valor1"' + sLineBreak +
    '      }' + sLineBreak +
    '    }' + sLineBreak +
    '  ],' + sLineBreak +
    '  "analysis_questions": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "question": "...",' + sLineBreak +
    '      "answer": "...",' + sLineBreak +
    '      "analysis": "...",' + sLineBreak +
    '      "confidence": 0.9' + sLineBreak +
    '    }' + sLineBreak +
    '  ]' + sLineBreak +
    '}';
end;

function TAIActionBuilderAgent.BuildActionBuilderPrompt(
  const AInput: string;
  const AMemoryContext: string;
  const ASchemaText: string
): string;
begin
  Result := 'Você é um Agente Ajustador e Validador de Parâmetros de Ação.' + sLineBreak;
  if SystemPrompt <> '' then
    Result := Result + SystemPrompt + sLineBreak;

  Result := Result + sLineBreak +
    '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
    'Analise o plano de ações gerado pelo decisor, corrija ou preencha parâmetros ausentes, e avalie a segurança deles.' + sLineBreak +
    'Retorne EXCLUSIVAMENTE um objeto JSON estruturado da seguinte forma:' + sLineBreak +
    ASchemaText + sLineBreak + sLineBreak +
    '=== MAPA DE MEMÓRIA ATÉ AGORA ===' + sLineBreak + AMemoryContext + sLineBreak +
    '=== PLANO ANTERIOR RECEBIDO ===' + sLineBreak + AInput;
end;

function TAIActionBuilderAgent.ValidateActionBuilderOutput(const AJSON: string; out AError: string): Boolean;
var
  JSONData: TJSONData;
  Obj: TJSONObject;
  ActionsData: TJSONData;
  ActionsArr: TJSONArray;
  I: Integer;
  Item: TJSONData;
  ItemObj: TJSONObject;
  ParamsData: TJSONData;
begin
  Result := False;
  AError := '';

  if Trim(AJSON) = '' then
  begin
    AError := 'JSON vazio';
    Exit;
  end;

  try
    JSONData := GetJSON(AJSON);
  except
    on E: Exception do
    begin
      AError := 'Erro de sintaxe JSON: ' + E.Message;
      Exit;
    end;
  end;

  try
    if not (JSONData is TJSONObject) then
    begin
      AError := 'JSON não é um objeto';
      Exit;
    end;

    Obj := TJSONObject(JSONData);
    ActionsData := Obj.Find('actions');
    if not Assigned(ActionsData) then
    begin
      AError := 'Campo "actions" ausente';
      Exit;
    end;

    if not (ActionsData is TJSONArray) then
    begin
      AError := 'Campo "actions" não é um array';
      Exit;
    end;

    ActionsArr := TJSONArray(ActionsData);
    if ActionsArr.Count = 0 then
    begin
      AError := 'O array "actions" está vazio';
      Exit;
    end;

    for I := 0 to ActionsArr.Count - 1 do
    begin
      Item := ActionsArr.Items[I];
      if not (Item is TJSONObject) then
      begin
        AError := Format('Item %d de "actions" não é um objeto', [I]);
        Exit;
      end;

      ItemObj := TJSONObject(Item);
      if (not Assigned(ItemObj.Find('action'))) and (not Assigned(ItemObj.Find('name'))) then
      begin
        AError := Format('Item %d de "actions" não possui o campo "action" ou "name"', [I]);
        Exit;
      end;

      ParamsData := ItemObj.Find('parameters');
      if Assigned(ParamsData) then
      begin
        if not (ParamsData is TJSONObject) then
        begin
          AError := Format('O campo "parameters" do item %d não é um objeto', [I]);
          Exit;
        end;
      end;
    end;

    Result := True;
  finally
    JSONData.Free;
  end;
end;

function TAIActionBuilderAgent.BuildRecoverPrompt(
  const AOriginalInput: string;
  const AMemoryContext: string;
  const AInvalidOutput: string;
  const AValidationError: string;
  const ASchemaText: string
): string;
begin
  Result := 'Você recebeu uma resposta inválida ou fora do formato esperado.' + sLineBreak +
    'Não invente informações.' + sLineBreak +
    'Use somente:' + sLineBreak +
    '1. o BuilderInput original;' + sLineBreak +
    '2. o mapa de memória;' + sLineBreak +
    '3. a resposta anterior inválida;' + sLineBreak +
    '4. o schema obrigatório.' + sLineBreak + sLineBreak +
    'Extraia o que realmente foi solicitado no BuilderInput.' + sLineBreak +
    'Converta para o schema obrigatório do ActionBuilder.' + sLineBreak +
    'Retorne somente JSON válido.' + sLineBreak + sLineBreak +
    '=== SCHEMA OBRIGATÓRIO ===' + sLineBreak + ASchemaText + sLineBreak + sLineBreak +
    '=== BUILDER INPUT ORIGINAL ===' + sLineBreak + AOriginalInput + sLineBreak + sLineBreak +
    '=== MAPA DE MEMÓRIA ===' + sLineBreak + AMemoryContext + sLineBreak + sLineBreak +
    '=== RESPOSTA ANTERIOR INVÁLIDA ===' + sLineBreak + AInvalidOutput + sLineBreak + sLineBreak +
    '=== ERRO DE VALIDAÇÃO ===' + sLineBreak + AValidationError;
end;

function TAIActionBuilderAgent.RecoverInvalidActionBuilderOutput(
  const AOriginalInput: string;
  const AMemoryContext: string;
  const AInvalidOutput: string;
  const AValidationError: string;
  const ASchemaText: string;
  out ARecoveredOutput: string
): Boolean;
var
  RecoverPrompt: string;
  RawRecovered: string;
  ValidationError: string;
begin
  Result := False;
  ARecoveredOutput := '';

  if not Assigned(ChatGPT) then
    Exit;

  RecoverPrompt := BuildRecoverPrompt(AOriginalInput, AMemoryContext, AInvalidOutput, AValidationError, ASchemaText);

  if ChatGPT.SendQuestion(RecoverPrompt) then
  begin
    RawRecovered := CleanJSONResponse(ChatGPT.Response);
    if ValidateActionBuilderOutput(RawRecovered, ValidationError) then
    begin
      ARecoveredOutput := RawRecovered;
      Result := True;
    end;
  end;
end;

function TAIActionBuilderAgent.BuildActions(const AInput: string; out AOutput: string): Boolean;
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
  Data: TJSONData;
  SchemaText: string;
  ValidationError: string;
  RecoveredText: string;
begin
  Result := False;
  AOutput := '';
  ClearError;

  // Block recovery if AInput is empty (Tarefa 11)
  if Trim(AInput) = '' then
  begin
    SetError('BuilderInput vazio. Não há conteúdo para montar ações.');
    Exit;
  end;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MapaDeMemoria.SessionId;
    Ctx.FlowName := 'Ajustador de Ações';
    Ctx.PedidoOriginal := AInput;
    Ctx.PedidoAtual := AInput;
    Ctx.NomeAgenteAtual := FNomeAgente;
    Ctx.TipoAgenteAtual := FTipoAgenteMapa;

    if Assigned(MapaDeMemoria) then
      Ctx.ContextoAtual := MapaDeMemoria.BuildContextForAgent(FNomeAgente, FTipoAgenteMapa);

    // Trigger BeforeBuildAction
    CanContinue := True;
    if Assigned(FOnBeforeBuildAction) then
      FOnBeforeBuildAction(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      SetError('Ajuste de ações cancelado pelo evento OnBeforeBuildAction.');
      Exit;
    end;

    // Begin Memory Map Step
    Item := BeginMemoryStep(Ctx.PedidoAtual);

    SchemaText := GetExpectedActionBuilderSchema;
    LPrompt := BuildActionBuilderPrompt(Ctx.PedidoAtual, Ctx.ContextoAtual, SchemaText);

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT is not connected to the Action Builder.');
      if Assigned(Item) then
        EndMemoryStep(Item, 'Hardware error', 'ChatGPT is not connected', 'ERROR', '');
      Exit;
    end;

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Network error while building actions: ' + ChatGPT.LastError);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Network error', ChatGPT.LastError, 'ERROR', '');
      Exit;
    end;

    ResponseText := CleanJSONResponse(ChatGPT.Response);

    // Save raw outputs (Tarefa 12)
    FLastRawOutput := ResponseText;
    FLastRecoveredOutput := '';
    FLastValidationError := '';

    // Validate before final parse (Tarefa 13, 14, 17)
    if not ValidateActionBuilderOutput(ResponseText, ValidationError) then
    begin
      FLastValidationError := ValidationError;

      if FAutoRecoverInvalidInput then
      begin
        if RecoverInvalidActionBuilderOutput(
          AInput,
          Ctx.ContextoAtual,
          ResponseText,
          ValidationError,
          SchemaText,
          RecoveredText
        ) then
        begin
          ResponseText := RecoveredText;
          FLastRecoveredOutput := RecoveredText;
          AOutput := ResponseText;

          // Register recovery in Memory Map (Tarefa 14)
          Ctx.AnaliseAtual := Ctx.AnaliseAtual + sLineBreak +
            'A saída inicial do ActionBuilder veio fora do schema esperado e foi recuperada usando o mapa de memória.';
          Ctx.ExplicacaoAtual := Ctx.ExplicacaoAtual + sLineBreak +
            'O componente reconstruiu o JSON operacional com base no BuilderInput original, no mapa de memória e no schema obrigatório.';
        end;
      end;
    end;

    // If validation failed and recovery failed or was disabled (Tarefa 17)
    if not ValidateActionBuilderOutput(ResponseText, ValidationError) then
    begin
      FLastValidationError := ValidationError;
      SetError('ActionBuilder retornou saída fora do layout esperado: ' + ValidationError);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Erro de schema', LastError, 'ERROR', ResponseText);
      Exit;
    end;

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
          Ctx.AcaoTomada := Obj.Get('action_taken', 'ACTION_PARAMETERS_PREPARED');
          Ctx.SaidaAtual := ResponseText;

          // Register questions using Find instead of Arrays (Tarefa 7, 8, 15, 16)
          PArr := nil;
          Data := Obj.Find('analysis_questions');
          if Assigned(Data) and (Data is TJSONArray) then
            PArr := TJSONArray(Data);

          if Assigned(PArr) and Assigned(Item) then
          begin
            for I := 0 to PArr.Count - 1 do
            begin
              if not (PArr.Items[I] is TJSONObject) then
                Continue;

              PObj := TJSONObject(PArr.Items[I]);
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

          // Trigger validations events
          CanContinue := True;
          if Assigned(FOnBeforeValidateParameters) then
            FOnBeforeValidateParameters(Self, Ctx, CanContinue);

          if Assigned(FOnAfterValidateParameters) then
            FOnAfterValidateParameters(Self, Ctx);

          // Apply defaults
          CanContinue := True;
          if Assigned(FOnBeforeApplyDefaults) then
            FOnBeforeApplyDefaults(Self, Ctx, CanContinue);

          if Assigned(FOnAfterApplyDefaults) then
            FOnAfterApplyDefaults(Self, Ctx);

          Ctx.NomeProximoAgente := 'ActionExecutor';
          Ctx.TipoProximoAgente := tamExecutor;
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao interpretar JSON do ajustador de ações: ' + E.Message);
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

    if Assigned(FOnAfterBuildAction) then
      FOnAfterBuildAction(Self, Ctx);
  finally
    Ctx.Free;
  end;
end;

function TAIActionBuilderAgent.BuildActionsStrict(const AInput: string; out AOutput: string): Boolean;
var
  OldRecover: Boolean;
begin
  OldRecover := FAutoRecoverInvalidInput;
  try
    FAutoRecoverInvalidInput := False;
    Result := BuildActions(AInput, AOutput);
  finally
    FAutoRecoverInvalidInput := OldRecover;
  end;
end;

function TAIActionBuilderAgent.BuildActionsWithRecovery(const AInput: string; out AOutput: string): Boolean;
var
  OldRecover: Boolean;
begin
  OldRecover := FAutoRecoverInvalidInput;
  try
    FAutoRecoverInvalidInput := True;
    Result := BuildActions(AInput, AOutput);
  finally
    FAutoRecoverInvalidInput := OldRecover;
  end;
end;

initialization
  {$I taiactionbuilderagent_icon.lrs}

end.
