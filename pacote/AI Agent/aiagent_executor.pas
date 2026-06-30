unit aiagent_executor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core;

type
  { TAIActionExecutor }
  TAIActionExecutor = class(TAIBaseComponent)
  private
    FMapaDeMemoria: TAIMapaDeMemoria;
    FChatGPT: TCHATGPT;
    FNomeAgente: string;
    FTipoAgenteMapa: TAITipoAgenteMapa;
    FForcarSimulacaoGlobal: Boolean;
    FAutoRegistrarNoMapa: Boolean;
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
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean; virtual;
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property MapaDeMemoria: TAIMapaDeMemoria read FMapaDeMemoria write FMapaDeMemoria;
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
  end;

implementation

{ TAIActionExecutor }

constructor TAIActionExecutor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FNomeAgente := 'ActionExecutor';
  FTipoAgenteMapa := tamExecutor;
  FForcarSimulacaoGlobal := False;
  FAutoRegistrarNoMapa := True;
end;

procedure TAIActionExecutor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FChatGPT then FChatGPT := nil;
    if AComponent = FMapaDeMemoria then FMapaDeMemoria := nil;
  end;
end;

function TAIActionExecutor.ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean;
var
  Item: TAIMapaDeMemoriaItem;
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
    LPrompt := 'Você é um Agente Executor de Ações.' + sLineBreak;
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
      '=== MAPA DE MEMÓRIA ATÉ AGORA ===' + sLineBreak + Ctx.ContextoAtual + sLineBreak +
      '=== PLANO A EXECUTAR ===' + sLineBreak + Ctx.PedidoAtual;

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
      SetError('ChatGPT não conectado ao Executor.');
      if Assigned(Item) and Assigned(MapaDeMemoria) then
        MapaDeMemoria.EndAgentStep(Item, 'Erro de hardware', 'ChatGPT não conectado', 'ERROR', '');
      Exit;
    end;

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Falha de rede ao executar plano: ' + ChatGPT.Response);
      if Assigned(Item) and Assigned(MapaDeMemoria) then
        MapaDeMemoria.EndAgentStep(Item, 'Erro de rede', ChatGPT.Response, 'ERROR', '');
      if Assigned(FOnExecutionFailed) then
        FOnExecutionFailed(Self, Ctx);
      Exit;
    end;

    ResponseText := ChatGPT.Response;
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

end.
