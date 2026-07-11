unit aiagent_classifier;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt,
  aiagent_flowevents, aiagent_memorymap, aiagent_core, LResources;

type
  { TAIClassifierAgent }
  TAIClassifierAgent = class(TAICustomAgent)
  private
    FOnBeforeClassify: TAIFluxoEtapaControlEvent;
    FOnAfterClassify: TAIFluxoEtapaEvent;
    FOnBeforeSelectTargetAgents: TAIFluxoEtapaControlEvent;
    FOnAfterSelectTargetAgents: TAIFluxoEtapaEvent;
    FOnClassificationLowConfidence: TAIFluxoEtapaEvent;
  public
    constructor Create(AOwner: TComponent); override;
    function Classify(const AInput: string; out AOutput: string): Boolean; virtual;
  published
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
end;

function TAIClassifierAgent.Classify(const AInput: string; out AOutput: string): Boolean;
var
  Item: TAIAgentMemoryMapItem;
  CanContinue: Boolean;
  Ctx: TAIFluxoEtapaContexto;
  LPrompt, ResponseText: string;
  JSONData: TJSONData;
  Obj: TJSONObject;
  Confidence: Double;
  Intent, LCategory, Priority, TargetAgentsStr: string;
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

    // Build Prompt
    LPrompt := 'You are a Classification Agent.' + sLineBreak;
    if SystemPrompt <> '' then
      LPrompt := LPrompt + SystemPrompt + sLineBreak;
    LPrompt := LPrompt + sLineBreak +
      '=== DIRETRIZES DE RETORNO ===' + sLineBreak +
      'Retorne EXCLUSIVAMENTE um objeto JSON estruturado da seguinte forma:' + sLineBreak +
      '{' + sLineBreak +
      '  "intent": "intenção principal do pedido",' + sLineBreak +
      '  "category": "categoria do pedido (ex: manutencao, suporte, etc.)",' + sLineBreak +
      '  "priority": "alta, media ou baixa",' + sLineBreak +
      '  "confidence": 0.95,' + sLineBreak +
      '  "target_agents": ["nome_do_decisor_de_destino"],' + sLineBreak +
      '  "must_preserve": ["termos", "chave", "que", "nao", "podem", "sumir"],' + sLineBreak +
      '  "analysis_questions": [' + sLineBreak +
      '    {"question": "Qual é a intenção principal do pedido?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
      '    {"question": "Qual é a categoria?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
      '    {"question": "Qual é a prioridade?", "answer": "...", "analysis": "...", "confidence": 0.9},' + sLineBreak +
      '    {"question": "Quais informações não podem ser perdidas?", "answer": "...", "analysis": "...", "confidence": 0.9},' +
      '    {"question": "Para quais agentes decisores esse pedido deve ir?", "answer": "...", "analysis": "...", "confidence": 0.9}' +
      '  ]' + sLineBreak +
      '}' + sLineBreak + sLineBreak +
      '=== RECEIVED REQUEST ===' + sLineBreak + Ctx.PedidoAtual;

    if not Assigned(ChatGPT) then
    begin
      SetError('ChatGPT is not connected to the classifier.');
      if Assigned(Item) then
        EndMemoryStep(Item, 'Hardware error', 'ChatGPT is not connected', 'ERROR', '');
      Exit;
    end;

    // Send question to LLM
    if not ChatGPT.SendQuestion(LPrompt) then
    begin
      SetError('Network error while classifying: ' + ChatGPT.LastError);
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
          Intent := Obj.Get('intent', '');
          LCategory := Obj.Get('category', '');
          Priority := Obj.Get('priority', '');
          
          Ctx.ClassificationPriority := Priority;
          Ctx.AnaliseAtual := 'Intenção: ' + Intent + ', Categoria: ' + LCategory;
          Ctx.ExplicacaoAtual := 'Classificado com confiança ' + FloatToStr(Confidence);
          Ctx.AcaoTomada := 'CLASSIFIED_AND_ROUTED';
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
              TargetAgentsStr := Obj.Arrays['target_agents'].AsJSON;
              Ctx.NomeProximoAgente := Obj.Arrays['target_agents'].Items[0].AsString;
              Ctx.TipoProximoAgente := tamDecisor;
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
