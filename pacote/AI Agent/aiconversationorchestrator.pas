unit aiconversationorchestrator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  aiinteractioncontext, aipersonsession, aiagent;

type
  TOnPersonDetectedEvent = procedure(Sender: TObject; const APersonName: string) of object;
  TOnSpeechDetectedEvent = procedure(Sender: TObject; const AText: string) of object;
  TOnGestureDetectedEvent = procedure(Sender: TObject; const AGestureName, ATargetObject: string) of object;
  TOnProjectChangedEvent = procedure(Sender: TObject; const AOldProject, ANewProject: string) of object;
  TOnInterruptionEvent = procedure(Sender: TObject) of object;
  TOnDynamicRAGEvent = procedure(Sender: TObject; const AProjects: string; const AQuery: string; out RAGResult: string) of object;

  { Orquestrador de Conversacao Multi-Modal Continua (Contexto + RAG Dinamico + Visao + Sessoes por Pessoa + Barge-in) }
  TAIConversationOrchestrator = class(TComponent)
  private
    FContext: TAIInteractionContext;
    FSessionManager: TAIPersonSessionManager;
    FSpeakerManager: TAIActiveSpeakerManager;
    FInternalSessionManager: Boolean;
    FInternalSpeakerManager: Boolean;
    FAgent: TAIAgent;
    FIsSpeaking: Boolean;
    FAutoRAG: Boolean;
    FOnPersonDetected: TOnPersonDetectedEvent;
    FOnSpeechDetected: TOnSpeechDetectedEvent;
    FOnGestureDetected: TOnGestureDetectedEvent;
    FOnProjectChanged: TOnProjectChangedEvent;
    FOnInterruption: TOnInterruptionEvent;
    FOnDynamicRAG: TOnDynamicRAGEvent;

    procedure HandlePersonChanged(Sender: TObject; const AOldPersonID, ANewPersonID: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Percepcao Continua e Identificacao por Pessoa
    procedure NotifyPersonDetected(const APersonName: string);
    procedure NotifyVisualRecognition(const APersonID, AName: string; AConfidence: Single);
    procedure NotifyGestureDetected(const AGestureName, ATargetObject: string);
    procedure NotifySpeechStart; // Dispara interrupcao (Barge-In) imediata se estiver falando
    procedure ProcessSpeechUtterance(const AText: string; out AResponse: string);

    // Controle de Fluxo e Interrupcao
    procedure StartSpeaking;
    procedure StopSpeaking;
    procedure RequestInterruption;

    property Context: TAIInteractionContext read FContext;
    property SessionManager: TAIPersonSessionManager read FSessionManager write FSessionManager;
    property SpeakerManager: TAIActiveSpeakerManager read FSpeakerManager write FSpeakerManager;
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
  FSessionManager := TAIPersonSessionManager.Create(Self);
  FInternalSessionManager := True;
  FSessionManager.OnActivePersonChanged := @HandlePersonChanged;

  FSpeakerManager := TAIActiveSpeakerManager.Create(Self);
  FInternalSpeakerManager := True;
  FSpeakerManager.SessionManager := FSessionManager;

  FIsSpeaking := False;
  FAutoRAG := True;
end;

destructor TAIConversationOrchestrator.Destroy;
begin
  FContext.Free;
  inherited Destroy;
end;

procedure TAIConversationOrchestrator.HandlePersonChanged(Sender: TObject; const AOldPersonID, ANewPersonID: string);
var
  S: TAIPersonSession;
begin
  S := FSessionManager.ActiveSession;
  if S <> nil then
  begin
    FContext.CurrentPerson := S.Name;
    if S.CurrentProject <> '' then
      FContext.CurrentProject := S.CurrentProject;
  end
  else
    FContext.CurrentPerson := '';

  if Assigned(FOnPersonDetected) then
    FOnPersonDetected(Self, FContext.CurrentPerson);
end;

procedure TAIConversationOrchestrator.NotifyPersonDetected(const APersonName: string);
begin
  NotifyVisualRecognition(APersonName, APersonName, 1.0);
end;

procedure TAIConversationOrchestrator.NotifyVisualRecognition(const APersonID, AName: string; AConfidence: Single);
begin
  if FSessionManager <> nil then
  begin
    FSessionManager.FeedVisualRecognition(APersonID, AName, AConfidence);
    if FSpeakerManager <> nil then
      FSpeakerManager.AddPersonPresent(APersonID, AName);
  end;
end;

procedure TAIConversationOrchestrator.NotifyGestureDetected(const AGestureName, ATargetObject: string);
var
  OldProject: string;
  S: TAIPersonSession;
begin
  OldProject := FContext.CurrentProject;

  if Trim(ATargetObject) <> '' then
  begin
    FContext.ObjectPointed := Trim(ATargetObject);
    FContext.CurrentProject := Trim(ATargetObject);

    // Salva projeto na sessao da pessoa atual
    if FSessionManager <> nil then
    begin
      S := FSessionManager.ActiveSession;
      if S <> nil then
        S.CurrentProject := FContext.CurrentProject;
    end;

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
  PersonContextPrompt: string;
  RAGInfo: string;
  TargetProjects: string;
  S: TAIPersonSession;
begin
  CleanText := Trim(AText);
  AResponse := '';
  if CleanText = '' then Exit;

  // Se nao houver pessoa ativa definida, cria sessao de convidado
  if (FSessionManager <> nil) and (FSessionManager.ActiveSession = nil) then
    FSessionManager.CreateGuestSession;

  // Notifica deteccao de fala
  if Assigned(FOnSpeechDetected) then
    FOnSpeechDetected(Self, CleanText);

  // 1. Verifica se ha necessidade real de pergunta de esclarecimento
  if FContext.NeedsClarification(CleanText, Clarification) then
  begin
    AResponse := Clarification;
    FContext.RecordInteraction(CleanText, AResponse);
    if (FSessionManager <> nil) and (FSessionManager.ActiveSession <> nil) then
    begin
      FSessionManager.ActiveSession.AddMessage('user', CleanText);
      FSessionManager.ActiveSession.AddMessage('assistant', AResponse);
    end;
    Exit;
  end;

  // 2. Resolve projeto em foco
  TargetProjects := FContext.ResolveReference(CleanText);
  if (FSessionManager <> nil) and (FSessionManager.ActiveSession <> nil) and (TargetProjects <> '') then
    FSessionManager.ActiveSession.CurrentProject := TargetProjects;

  // 3. Consulta RAG Dinamico se solicitado
  RAGInfo := '';
  if FAutoRAG and Assigned(FOnDynamicRAG) and (TargetProjects <> '') then
  begin
    FOnDynamicRAG(Self, TargetProjects, CleanText, RAGInfo);
  end;

  // 4. Monta prompt enriquecido continuo com contexto da pessoa
  EnrichedPrompt := FContext.BuildEnrichedPrompt(CleanText);

  if FSessionManager <> nil then
  begin
    PersonContextPrompt := FSessionManager.BuildEnrichedPersonPrompt(CleanText);
    EnrichedPrompt := PersonContextPrompt + LineEnding + EnrichedPrompt;
  end;

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

  // 6. Grava no historico global e na sessao individual da pessoa
  FContext.RecordInteraction(CleanText, AResponse);
  if (FSessionManager <> nil) and (FSessionManager.ActiveSession <> nil) then
  begin
    S := FSessionManager.ActiveSession;
    S.AddMessage('user', CleanText);
    S.AddMessage('assistant', AResponse);
    S.LastTopic := TargetProjects;
  end;
end;

end.
