unit aiagent_classifier;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core, LResources;

type
  TAIClassifierOutputMode = (
    comFullAnalysis,
    comCompactRouting
  );

  { TAIClassifierAgent }
  TAIClassifierAgent = class(TAICustomAgent)
  private
    FOutputMode: TAIClassifierOutputMode;
    FOnBeforeClassify: TAIFluxoEtapaControlEvent;
    FOnAfterClassify: TAIFluxoEtapaEvent;
    FOnBeforeSelectTargetAgents: TAIFluxoEtapaControlEvent;
    FOnAfterSelectTargetAgents: TAIFluxoEtapaEvent;
    FOnClassificationLowConfidence: TAIFluxoEtapaEvent;
  public
    constructor Create(AOwner: TComponent); override;
    function Classify(const AInput: string; out AOutput: string): Boolean; virtual;
  published
    property OutputMode: TAIClassifierOutputMode read FOutputMode write FOutputMode default comFullAnalysis;
    property OnBeforeClassify: TAIFluxoEtapaControlEvent read FOnBeforeClassify write FOnBeforeClassify;
    property OnAfterClassify: TAIFluxoEtapaEvent read FOnAfterClassify write FOnAfterClassify;
    property OnBeforeSelectTargetAgents: TAIFluxoEtapaControlEvent read FOnBeforeSelectTargetAgents write FOnBeforeSelectTargetAgents;
    property OnAfterSelectTargetAgents: TAIFluxoEtapaEvent read FOnAfterSelectTargetAgents write FOnAfterSelectTargetAgents;
    property OnClassificationLowConfidence: TAIFluxoEtapaEvent read FOnClassificationLowConfidence write FOnClassificationLowConfidence;
  end;

implementation

{ TAIClassifierAgent }

constructor TAIClassifierAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNomeAgente := 'ClassifierAgent';
  FTipoAgenteMapa := tamClassificador;
  FOutputMode := comFullAnalysis;
end;

function TAIClassifierAgent.Classify(const AInput: string; out AOutput: string): Boolean;
var
  Item: TAIAgentMemoryMapItem;
  CanContinue: Boolean;
  Ctx: TAIFluxoEtapaContexto;
  LPrompt, ResponseText: string;
  LOriginalDev: WideString;
  JSONData: TJSONData;
  Obj: TJSONObject;
  Confidence: Double;
  Intent, LCategory, Priority, TargetAgentsStr: string;
  I: Integer;
  PArr: TJSONArray;
  PObj: TJSONObject;
  LMustPreserveArr: TJSONArray;
begin
  Result := False;
  AOutput := '';
  ClearError;

  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MapaDeMemoria.SessionId;
    Ctx.FlowName := 'Classificação';
    Ctx.PedidoOriginal := AInput;
    Ctx.PedidoAtual := AInput;
    Ctx.NomeAgenteAtual := FNomeAgente;
    Ctx.TipoAgenteAtual := FTipoAgenteMapa;

    // Trigger BeforeClassify event
    CanContinue := True;
    if Assigned(FOnBeforeClassify) then
      FOnBeforeClassify(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      SetError('Classificação cancelada pelo evento OnBeforeClassify.');
      Exit;
    end;

    // Begin Memory Map Step
    Item := BeginMemoryStep(Ctx.PedidoAtual);

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT is not connected to the classifier.');
      if Assigned(Item) then
        EndMemoryStep(Item, 'Hardware error', 'ChatGPT is not connected', 'ERROR', '');
      Exit;
    end;

    // Build Prompt for system role (FDev)
    if Trim(SystemPrompt) <> '' then
      LPrompt := SystemPrompt + sLineBreak
    else
      LPrompt := 'Você é o Agente Classificador do sistema de suporte da TI.' + sLineBreak;

    LPrompt := LPrompt + sLineBreak +
      '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
      'Retorne EXCLUSIVAMENTE um objeto JSON estruturado da seguinte forma:' + sLineBreak;

    if FOutputMode = comCompactRouting then
    begin
      LPrompt := LPrompt +
        '{' + sLineBreak +
        '  "confidence": 0.95,' + sLineBreak +
        '  "target_agents": ["identificador_do_plano_de_acao"],' + sLineBreak +
        '  "must_preserve": []' + sLineBreak +
        '}' + sLineBreak + sLineBreak +
        'REGRAS ADICIONAIS:' + sLineBreak +
        '1. O campo "target_agents" deve conter exatamente um item do array com um dos identificadores de plano cadastrados, ou "nenhuma".' + sLineBreak +
        '2. Preencha "must_preserve" apenas com informações concretas e importantes extraídas do pedido atual (como equipamento, local, identificação, defeito ou restrição). Se não houver informação concreta, retorne um array vazio.';
    end
    else
    begin
      LPrompt := LPrompt +
        '{' + sLineBreak +
        '  "intent": "intent", "category": "category", "priority": "priority",' + sLineBreak +
        '  "confidence": 0.95,' + sLineBreak +
        '  "target_agents": ["nome_do_decisor_de_destino"],' + sLineBreak +
        '  "must_preserve": [],' + sLineBreak +
        '  "analysis_questions": [' + sLineBreak +
        '    {"question": "Qual é a intenção principal do pedido?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
        '    {"question": "Qual é a categoria?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
        '    {"question": "Qual é a prioridade?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
        '    {"question": "Quais informações não podem ser perdidas?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
        '    {"question": "Para quais agentes decisores esse pedido deve ir?", "answer": "...", "analysis": "...", "confidence": 0.9}' + sLineBreak +
        '  ]' + sLineBreak +
        '}' + sLineBreak + sLineBreak +
        'Preencha "must_preserve" apenas com informações concretas e importantes extraídas do pedido atual, como equipamento, local, identificação, defeito ou restrição. Se não houver informação concreta, retorne um array vazio.';
    end;

    LOriginalDev := ChatGPT.Dev;
    try
      ChatGPT.Dev := LPrompt;

      // Send question to LLM (only user request is sent as user message)
      if not ChatGPT.SendQuestion(Ctx.PedidoAtual) then
      begin
        SetError('Network error while classifying: ' + ChatGPT.LastError);
        if Assigned(Item) then
          EndMemoryStep(Item, 'Network error', ChatGPT.LastError, 'ERROR', '');
        Exit;
      end;
    finally
      ChatGPT.Dev := LOriginalDev;
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
          Intent := Obj.Get('intent', '');
          LCategory := Obj.Get('category', '');
          Priority := Obj.Get('priority', '');
          
          Ctx.ClassificationPriority := Priority;
          Ctx.AnaliseAtual := 'Intenção: ' + Intent + ', Categoria: ' + LCategory;
          Ctx.ExplicacaoAtual := 'Classificado com confiança ' + FloatToStr(Confidence);
          Ctx.AcaoTomada := 'CLASSIFIED_AND_ROUTED';
          Ctx.SaidaAtual := ResponseText;

          // Register questions
          if Obj.IndexOfName('analysis_questions') >= 0 then
          begin
            if Obj.Items[Obj.IndexOfName('analysis_questions')].JSONType = jtArray then
            begin
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
            end;
          end;

          // Parse must_preserve
          if Assigned(Item) and (Obj.IndexOfName('must_preserve') >= 0) then
          begin
            if Obj.Items[Obj.IndexOfName('must_preserve')].JSONType = jtArray then
            begin
              LMustPreserveArr := Obj.Arrays['must_preserve'];
              if Assigned(LMustPreserveArr) then
              begin
                Item.InformacoesObrigatorias.Clear;
                for I := 0 to LMustPreserveArr.Count - 1 do
                  Item.InformacoesObrigatorias.Add(LMustPreserveArr.Items[I].AsString);
              end;
            end;
          end;

          if Confidence < MinConfidence then
          begin
            if Assigned(FOnClassificationLowConfidence) then
              FOnClassificationLowConfidence(Self, Ctx);
          end;

          // Trigger target agent selection
          CanContinue := True;
          if Assigned(FOnBeforeSelectTargetAgents) then
            FOnBeforeSelectTargetAgents(Self, Ctx, CanContinue);

          if CanContinue then
          begin
            // Simulate agent routing
            if Obj.IndexOfName('target_agents') >= 0 then
            begin
              if Obj.Items[Obj.IndexOfName('target_agents')].JSONType = jtArray then
              begin
                PArr := Obj.Arrays['target_agents'];
                if Assigned(PArr) and (PArr.Count > 0) then
                begin
                  TargetAgentsStr := PArr.AsJSON;
                  Ctx.NomeProximoAgente := PArr.Items[0].AsString;
                  Ctx.TipoProximoAgente := tamDecisor;
                end;
              end;
            end;
          end;

          if Assigned(FOnAfterSelectTargetAgents) then
            FOnAfterSelectTargetAgents(Self, Ctx);
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao interpretar JSON de classificação: ' + E.Message);
        if Assigned(Item) then
          EndMemoryStep(Item, 'Erro de análise', E.Message, 'ERROR', ResponseText);
        Exit;
      end;
    end;

    // End memory step
    if Assigned(Item) then
    begin
      Item.SaidaGerada := AOutput;
      Item.Confianca := Confidence;
      EndMemoryStep(Item, Ctx.AnaliseAtual, Ctx.ExplicacaoAtual, Ctx.AcaoTomada, Ctx.SaidaAtual);
    end;

    Result := True;

    if Assigned(FOnAfterClassify) then
      FOnAfterClassify(Self, Ctx);
  finally
    Ctx.Free;
  end;
end;

initialization
  {$I taiclassifieragent_icon.lrs}

end.
