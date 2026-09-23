unit aiconversationorchestrator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  aiinteractioncontext, aiagent;

type
  TOnPersonDetectedEvent = procedure(Sender: TObject; const APersonName: string) of object;
  TOnSpeechDetectedEvent = procedure(Sender: TObject; const AText: string) of object;
  TOnGestureDetectedEvent = procedure(Sender: TObject; const AGestureName, ATargetObject: string) of object;
  TOnProjectChangedEvent = procedure(Sender: TObject; const AOldProject, ANewProject: string) of object;
  TOnInterruptionEvent = procedure(Sender: TObject) of object;
  TOnDynamicRAGEvent = procedure(Sender: TObject; const AProjects: string; const AQuery: string; out RAGResult: string) of object;

  { Orquestrador de Conversacao Multi-Modal Continua (Contexto + RAG Dinamico + Visao + Barge-in) }
  TAIConversationOrchestrator = class(TComponent)
  private
    FContext: TAIInteractionContext;
    FAgent: TAIAgent;
    FIsSpeaking: Boolean;
    FAutoRAG: Boolean;
    FOnPersonDetected: TOnPersonDetectedEvent;
    FOnSpeechDetected: TOnSpeechDetectedEvent;
    FOnGestureDetected: TOnGestureDetectedEvent;
    FOnProjectChanged: TOnProjectChangedEvent;
    FOnInterruption: TOnInterruptionEvent;
    FOnDynamicRAG: TOnDynamicRAGEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Percepcao Continua
    procedure NotifyPersonDetected(const APersonName: string);
    procedure NotifyGestureDetected(const AGestureName, ATargetObject: string);
    procedure NotifySpeechStart; // Dispara interrupcao (Barge-In) imediata se estiver falando
    procedure ProcessSpeechUtterance(const AText: string; out AResponse: string);

    // Controle de Fluxo e Interrupcao
    procedure StartSpeaking;
    procedure StopSpeaking;
    procedure RequestInterruption;

    property Context: TAIInteractionContext read FContext;
    property Agent: TAIAgent read FAgent write FAgent;
    property IsSpeaking: Boolean read FIsSpeaking write FIsSpeaking;
    property AutoRAG: Boolean read FAutoRAG write FAutoRAG default True;

    property OnPersonDetected: TOnPersonDetectedEvent read FOnPersonDetected write FOnPersonDetected;
    property OnSpeechDetected: TOnSpeechDetectedEvent read FOnSpeechDetected write FOnSpeechDetected;
    property OnGestureDetected: TOnGestureDetectedEvent read FOnGestureDetected write FOnGestureDetected;
    property OnProjectChanged: TOnProjectChangedEvent read FOnProjectChanged write FOnProjectChanged;
    property OnInterruption: TOnInterruptionEvent read FOnInterruption write FOnInterruption;
    property OnDynamicRAG: TOnDynamicRAGEvent read FOnDynamicRAG write FOnDynamicRAG;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('OpenAI Agent', [TAIConversationOrchestrator]);
end;

{ TAIConversationOrchestrator }

constructor TAIConversationOrchestrator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContext := TAIInteractionContext.Create;
  FIsSpeaking := False;
  FAutoRAG := True;
end;

destructor TAIConversationOrchestrator.Destroy;
begin
  FContext.Free;
  inherited Destroy;
end;

procedure TAIConversationOrchestrator.NotifyPersonDetected(const APersonName: string);
begin
  FContext.CurrentPerson := Trim(APersonName);
  if Assigned(FOnPersonDetected) then
    FOnPersonDetected(Self, FContext.CurrentPerson);
end;

procedure TAIConversationOrchestrator.NotifyGestureDetected(const AGestureName, ATargetObject: string);
var
  OldProject: string;
begin
  OldProject := FContext.CurrentProject;

  if Trim(ATargetObject) <> '' then
  begin
    FContext.ObjectPointed := Trim(ATargetObject);
    // Se apontou para um objeto/projeto conhecido, atualiza foco
    FContext.CurrentProject := Trim(ATargetObject);

    if (OldProject <> FContext.CurrentProject) and Assigned(FOnProjectChanged) then
      FOnProjectChanged(Self, OldProject, FContext.CurrentProject);
  end;

  if Assigned(FOnGestureDetected) then
    FOnGestureDetected(Self, AGestureName, ATargetObject);
end;

procedure TAIConversationOrchestrator.NotifySpeechStart;
begin
  // Barge-In: Se o usuario comecar a falar enquanto a IA estiver falando, interrompe imediatamente!
  if FIsSpeaking then
  begin
    RequestInterruption;
  end;
end;

procedure TAIConversationOrchestrator.RequestInterruption;
begin
  FIsSpeaking := False;
  if Assigned(FOnInterruption) then
    FOnInterruption(Self);
end;

procedure TAIConversationOrchestrator.StartSpeaking;
begin
  FIsSpeaking := True;
end;

procedure TAIConversationOrchestrator.StopSpeaking;
begin
  FIsSpeaking := False;
end;

procedure TAIConversationOrchestrator.ProcessSpeechUtterance(const AText: string; out AResponse: string);
var
  CleanText: string;
  Clarification: string;
  EnrichedPrompt: string;
  RAGInfo: string;
  TargetProjects: string;
begin
  CleanText := Trim(AText);
  AResponse := '';
  if CleanText = '' then Exit;

  // Notifica deteccao de fala
  if Assigned(FOnSpeechDetected) then
    FOnSpeechDetected(Self, CleanText);

  // 1. Verifica se ha necessidade real de pergunta de esclarecimento
  if FContext.NeedsClarification(CleanText, Clarification) then
  begin
    AResponse := Clarification;
    FContext.RecordInteraction(CleanText, AResponse);
    Exit;
  end;

  // 2. Resolve projeto em foco
  TargetProjects := FContext.ResolveReference(CleanText);

  // 3. Consulta RAG Dinamico se solicitado
  RAGInfo := '';
  if FAutoRAG and Assigned(FOnDynamicRAG) and (TargetProjects <> '') then
  begin
    FOnDynamicRAG(Self, TargetProjects, CleanText, RAGInfo);
  end;

  // 4. Monta prompt enriquecido continuo
  EnrichedPrompt := FContext.BuildEnrichedPrompt(CleanText);
  if Trim(RAGInfo) <> '' then
  begin
    EnrichedPrompt := EnrichedPrompt + LineEnding +
      '[CONHECIMENTO TÉCNICO RECUPERADO VIA RAG DINÂMICO]' + LineEnding +
      RAGInfo + LineEnding;
  end;

  // 5. Executa pelo Agente (se conectado) ou gera resposta
  if FAgent <> nil then
  begin
    if FAgent.Execute(EnrichedPrompt) then
      AResponse := FAgent.LastResult
    else
      AResponse := FAgent.LastError;
    if AResponse = '' then
      AResponse := FAgent.LastResult;
  end
  else
  begin
    // Fallback conversacional direto
    if TargetProjects <> '' then
      AResponse := Format('Com base no projeto %s, estamos utilizando visão e processamento inteligente para resolver essa demanda.', [TargetProjects])
    else
      AResponse := 'Entendido. Como posso ajudar com os nossos projetos ou soluções?';
  end;

  // 6. Grava no historico recente da interacao
  FContext.RecordInteraction(CleanText, AResponse);
end;

end.
