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
  public
    constructor Create(AOwner: TComponent); override;
    function BuildActions(const AInput: string; out AOutput: string): Boolean; virtual;
  published
    property OnBeforeBuildAction: TAIFluxoEtapaControlEvent read FOnBeforeBuildAction write FOnBeforeBuildAction;
    property OnAfterBuildAction: TAIFluxoEtapaEvent read FOnAfterBuildAction write FOnAfterBuildAction;
    property OnBeforeValidateParameters: TAIFluxoEtapaControlEvent read FOnBeforeValidateParameters write FOnBeforeValidateParameters;
    property OnAfterValidateParameters: TAIFluxoEtapaEvent read FOnAfterValidateParameters write FOnAfterValidateParameters;
    property OnBeforeApplyDefaults: TAIFluxoEtapaControlEvent read FOnBeforeApplyDefaults write FOnBeforeApplyDefaults;
    property OnAfterApplyDefaults: TAIFluxoEtapaEvent read FOnAfterApplyDefaults write FOnAfterApplyDefaults;
    property OnMissingRequiredParameter: TAIFluxoEtapaEvent read FOnMissingRequiredParameter write FOnMissingRequiredParameter;
    property OnUnsafeParameterDetected: TAIFluxoEtapaEvent read FOnUnsafeParameterDetected write FOnUnsafeParameterDetected;
  end;

implementation

{ TAIActionBuilderAgent }

constructor TAIActionBuilderAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNomeAgente := 'ActionBuilderAgent';
  FTipoAgenteMapa := tamAjustadorAcao;
end;

function TAIActionBuilderAgent.BuildActions(const AInput: string; out AOutput: string): Boolean;
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

    // Build Prompt
    LPrompt := 'Você é um Agente Ajustador e Validador de Parâmetros de Ação.' + sLineBreak;
    if SystemPrompt <> '' then
      LPrompt := LPrompt + SystemPrompt + sLineBreak;

    LPrompt := LPrompt + sLineBreak +
      '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
      'Analise o plano de ações gerado pelo decisor, corrija ou preencha parâmetros ausentes, e avalie a segurança deles.' + sLineBreak +
      'Retorne EXCLUSIVAMENTE um objeto JSON estruturado da seguinte forma:' + sLineBreak +
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
      '    {"question": "A ação escolhida existe no registry?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
      '    {"question": "Todos os parâmetros obrigatórios foram preenchidos?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Os valores estão normalizados?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Há parâmetro perigoso ou incoerente?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "O plano está pronto para execução ou precisa voltar ao decisor?", "answer": "...", "analysis": "...", "confidence": 0.9}' +
      '  ]' + sLineBreak +
      '}' + sLineBreak + sLineBreak +
      '=== MAPA DE MEMÓRIA ATÉ AGORA ===' + sLineBreak + Ctx.ContextoAtual + sLineBreak +
      '=== PLANO ANTERIOR RECEBIDO ===' + sLineBreak + Ctx.PedidoAtual;

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT não conectado ao Ajustador de Ações.');
      if Assigned(Item) then
        EndMemoryStep(Item, 'Erro de hardware', 'ChatGPT não conectado', 'ERROR', '');
      Exit;
    end;

    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Falha de rede ao ajustar ações: ' + ChatGPT.Response);
      if Assigned(Item) then
        EndMemoryStep(Item, 'Erro de rede', ChatGPT.Response, 'ERROR', '');
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
          Ctx.AcaoTomada := Obj.Get('action_taken', 'ACTION_PARAMETERS_PREPARED');
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

initialization
  {$I taiactionbuilderagent_icon.lrs}

end.
