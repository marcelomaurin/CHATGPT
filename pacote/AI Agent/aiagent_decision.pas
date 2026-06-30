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
  public
    constructor Create(AOwner: TComponent); override;
    function Decide(const AInput: string; out AOutput: string): Boolean; virtual;
  published
    property OnBeforeDecision: TAIFluxoEtapaControlEvent read FOnBeforeDecision write FOnBeforeDecision;
    property OnAfterDecision: TAIFluxoEtapaEvent read FOnAfterDecision write FOnAfterDecision;
    property OnBeforeActionPlanCreate: TAIFluxoEtapaControlEvent read FOnBeforeActionPlanCreate write FOnBeforeActionPlanCreate;
    property OnAfterActionPlanCreate: TAIFluxoEtapaEvent read FOnAfterActionPlanCreate write FOnAfterActionPlanCreate;
    property OnBeforeAddActionToPlan: TAIFluxoEtapaControlEvent read FOnBeforeAddActionToPlan write FOnBeforeAddActionToPlan;
    property OnAfterAddActionToPlan: TAIFluxoEtapaEvent read FOnAfterAddActionToPlan write FOnAfterAddActionToPlan;
    property OnInvalidActionSelected: TAIFluxoEtapaEvent read FOnInvalidActionSelected write FOnInvalidActionSelected;
    property OnDecisionLowConfidence: TAIFluxoEtapaEvent read FOnDecisionLowConfidence write FOnDecisionLowConfidence;
  end;

implementation

{ TAIDecisionAgent }

constructor TAIDecisionAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNomeAgente := 'DecisionAgent';
  FTipoAgenteMapa := tamDecisor;
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

initialization
  {$I taidecisionagent_icon.lrs}

end.
