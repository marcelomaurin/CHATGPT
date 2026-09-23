{==============================================================================
  AI Person Session & Memory Subsystem
  Implementa:
  - TAIPersonSessionManager: Gestao de sessoes por pessoa reconhecida.
  - TAIPersonMemory: Separacao entre historico recente e memoria de longo prazo.
  - TAIActiveSpeakerManager: Arbitragem de interlocutor ativo (Presente vs Falando).
==============================================================================}
unit aipersonsession;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils;

type
  { Mensagem individual do dialogo }
  TPersonMessage = record
    ID: string;
    Role: string;       { 'user' ou 'assistant' }
    Content: string;
    Timestamp: TDateTime;
  end;

  { Item de Memoria de Longo Prazo }
  TPersonMemoryItem = record
    ID: string;
    Category: string;   { ex: 'Interesse', 'Preferência', 'Dúvida' }
    Content: string;
    UpdatedAt: TDateTime;
  end;

  { Sessao de uma pessoa reconhecida ou convidada }
  TAIPersonSession = class(TPersistent)
  private
    FPersonID: string;
    FName: string;
    FConversationID: string;
    FCurrentProject: string;
    FLastTopic: string;
    FLastQuestion: string;
    FStartedAt: TDateTime;
    FLastActiveAt: TDateTime;
    FIsGuest: Boolean;
    FMessages: array of TPersonMessage;
    FMemories: array of TPersonMemoryItem;
    FMaxRecentMessages: Integer;
    function GetMessageCount: Integer;
    function GetMemoryCount: Integer;
  public
    constructor Create(const APersonID, AName: string; AIsGuest: Boolean = False);
    destructor Destroy; override;

    procedure AddMessage(const ARole, AContent: string);
    procedure AddMemory(const ACategory, AContent: string);
    function GetRecentMessagesFormatted(AMaxCount: Integer = 5): string;
    function GetLongTermMemorySummary: string;
    function GetLastUserQuestion: string;

    property PersonID: string read FPersonID;
    property Name: string read FName write FName;
    property ConversationID: string read FConversationID write FConversationID;
    property CurrentProject: string read FCurrentProject write FCurrentProject;
    property LastTopic: string read FLastTopic write FLastTopic;
    property LastQuestion: string read FLastQuestion write FLastQuestion;
    property StartedAt: TDateTime read FStartedAt;
    property LastActiveAt: TDateTime read FLastActiveAt write FLastActiveAt;
    property IsGuest: Boolean read FIsGuest;
    property MessageCount: Integer read GetMessageCount;
    property MemoryCount: Integer read GetMemoryCount;
  end;

  TOnActivePersonChangedEvent = procedure(Sender: TObject; const AOldPersonID, ANewPersonID: string) of object;

  { Gerenciador de Sessoes por Pessoa }
  TAIPersonSessionManager = class(TComponent)
  private
    FSessions: TList; { Lista de TAIPersonSession }
    FActiveSession: TAIPersonSession;
    FRecognitionStableTimeMs: Integer;
    FRecognitionThreshold: Single;
    FCandidatePersonID: string;
    FCandidatePersonName: string;
    FCandidateStartTime: TDateTime;
    FSessionTimeoutMinutes: Integer;
    FGuestCounter: Integer;
    FOnActivePersonChanged: TOnActivePersonChangedEvent;

    function FindSession(const APersonID: string): TAIPersonSession;
    function GenerateGuestID: string;
    procedure SwitchActiveSession(ASession: TAIPersonSession);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Ativacao direta e controle de estabilidade visual (Anti-flicker)
    function ActivatePerson(const APersonID, AName: string): TAIPersonSession;
    function FeedVisualRecognition(const APersonID, AName: string; AConfidence: Single): Boolean;
    procedure SuspendCurrentPerson;
    procedure ResumePerson(const APersonID: string);
    function CreateGuestSession: TAIPersonSession;

    function BuildEnrichedPersonPrompt(const AUserUtterance: string): string;

    property ActiveSession: TAIPersonSession read FActiveSession;
    property RecognitionStableTimeMs: Integer read FRecognitionStableTimeMs write FRecognitionStableTimeMs default 1500;
    property RecognitionThreshold: Single read FRecognitionThreshold write FRecognitionThreshold;
    property SessionTimeoutMinutes: Integer read FSessionTimeoutMinutes write FSessionTimeoutMinutes default 30;
    property OnActivePersonChanged: TOnActivePersonChangedEvent read FOnActivePersonChanged write FOnActivePersonChanged;
  end;

  { Arbitrador de Interlocutor Ativo (Presente vs Falando) }
  TAIActiveSpeakerManager = class(TComponent)
  private
    FPersonsPresent: TStringList;
    FActiveSpeakerID: string;
    FActiveSpeakerName: string;
    FSessionManager: TAIPersonSessionManager;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddPersonPresent(const APersonID, AName: string);
    procedure RemovePersonPresent(const APersonID: string);
    procedure ClearPersonsPresent;
    procedure SetActiveSpeaker(const APersonID: string);
    function IsPersonPresent(const APersonID: string): Boolean;

    property PersonsPresent: TStringList read FPersonsPresent;
    property ActiveSpeakerID: string read FActiveSpeakerID;
    property ActiveSpeakerName: string read FActiveSpeakerName;
    property SessionManager: TAIPersonSessionManager read FSessionManager write FSessionManager;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('OpenAI Agent', [TAIPersonSessionManager, TAIActiveSpeakerManager]);
end;

{ TAIPersonSession }

constructor TAIPersonSession.Create(const APersonID, AName: string; AIsGuest: Boolean);
begin
  inherited Create;
  FPersonID := APersonID;
  FName := AName;
  FIsGuest := AIsGuest;
  FConversationID := FormatDateTime('yyyymmddhhnnss', Now) + '-' + APersonID;
  FStartedAt := Now;
  FLastActiveAt := Now;
  FCurrentProject := '';
  FLastTopic := '';
  FLastQuestion := '';
  FMaxRecentMessages := 10;
  SetLength(FMessages, 0);
  SetLength(FMemories, 0);
end;

destructor TAIPersonSession.Destroy;
begin
  SetLength(FMessages, 0);
  SetLength(FMemories, 0);
  inherited Destroy;
end;

function TAIPersonSession.GetMessageCount: Integer;
begin
  Result := Length(FMessages);
end;

function TAIPersonSession.GetMemoryCount: Integer;
begin
  Result := Length(FMemories);
end;

procedure TAIPersonSession.AddMessage(const ARole, AContent: string);
var
  Idx: Integer;
begin
  Idx := Length(FMessages);
  SetLength(FMessages, Idx + 1);
  FMessages[Idx].ID := IntToStr(Idx + 1);
  FMessages[Idx].Role := ARole;
  FMessages[Idx].Content := Trim(AContent);
  FMessages[Idx].Timestamp := Now;
  FLastActiveAt := Now;

  if SameText(ARole, 'user') then
    FLastQuestion := Trim(AContent);
end;

procedure TAIPersonSession.AddMemory(const ACategory, AContent: string);
var
  Idx: Integer;
begin
  Idx := Length(FMemories);
  SetLength(FMemories, Idx + 1);
  FMemories[Idx].ID := IntToStr(Idx + 1);
  FMemories[Idx].Category := ACategory;
  FMemories[Idx].Content := Trim(AContent);
  FMemories[Idx].UpdatedAt := Now;
end;

function TAIPersonSession.GetRecentMessagesFormatted(AMaxCount: Integer): string;
var
  SL: TStringList;
  I, StartIdx: Integer;
begin
  SL := TStringList.Create;
  try
    if Length(FMessages) = 0 then
      Exit('');

    StartIdx := Length(FMessages) - AMaxCount;
    if StartIdx < 0 then
      StartIdx := 0;

    for I := StartIdx to High(FMessages) do
    begin
      if SameText(FMessages[I].Role, 'user') then
        SL.Add('Usuário: ' + FMessages[I].Content)
      else
        SL.Add('Assistente: ' + FMessages[I].Content);
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TAIPersonSession.GetLongTermMemorySummary: string;
var
  SL: TStringList;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    if Length(FMemories) = 0 then
      Exit('');

    for I := 0 to High(FMemories) do
      SL.Add(Format('- [%s]: %s', [FMemories[I].Category, FMemories[I].Content]));

    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TAIPersonSession.GetLastUserQuestion: string;
begin
  Result := FLastQuestion;
end;

{ TAIPersonSessionManager }

constructor TAIPersonSessionManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSessions := TList.Create;
  FActiveSession := nil;
  FRecognitionStableTimeMs := 1500;
  FRecognitionThreshold := 0.85;
  FCandidatePersonID := '';
  FCandidatePersonName := '';
  FCandidateStartTime := 0;
  FSessionTimeoutMinutes := 30;
  FGuestCounter := 0;
end;

destructor TAIPersonSessionManager.Destroy;
var
  I: Integer;
begin
  for I := 0 to FSessions.Count - 1 do
    TAIPersonSession(FSessions[I]).Free;
  FSessions.Free;
  inherited Destroy;
end;

function TAIPersonSessionManager.FindSession(const APersonID: string): TAIPersonSession;
var
  I: Integer;
  S: TAIPersonSession;
begin
  for I := 0 to FSessions.Count - 1 do
  begin
    S := TAIPersonSession(FSessions[I]);
    if SameText(S.PersonID, APersonID) then
      Exit(S);
  end;
  Result := nil;
end;

function TAIPersonSessionManager.GenerateGuestID: string;
begin
  Inc(FGuestCounter);
  Result := Format('GuestSession-%s-%3.3d', [FormatDateTime('yyyymmdd', Now), FGuestCounter]);
end;

procedure TAIPersonSessionManager.SwitchActiveSession(ASession: TAIPersonSession);
var
  OldID, NewID: string;
begin
  if FActiveSession = ASession then Exit;

  OldID := '';
  if FActiveSession <> nil then
    OldID := FActiveSession.PersonID;

  FActiveSession := ASession;
  NewID := '';
  if FActiveSession <> nil then
  begin
    NewID := FActiveSession.PersonID;
    FActiveSession.LastActiveAt := Now;
  end;

  if Assigned(FOnActivePersonChanged) then
    FOnActivePersonChanged(Self, OldID, NewID);
end;

function TAIPersonSessionManager.ActivatePerson(const APersonID, AName: string): TAIPersonSession;
var
  S: TAIPersonSession;
begin
  S := FindSession(APersonID);
  if S = nil then
  begin
    S := TAIPersonSession.Create(APersonID, AName, False);
    FSessions.Add(S);
  end
  else if AName <> '' then
    S.Name := AName;

  SwitchActiveSession(S);
  Result := S;
end;

function TAIPersonSessionManager.FeedVisualRecognition(const APersonID, AName: string; AConfidence: Single): Boolean;
var
  NowTime: TDateTime;
  ElapsedMs: Int64;
begin
  Result := False;
  // Exige confianca minima para evitar trocas erradas
  if AConfidence < FRecognitionThreshold then
  begin
    FCandidatePersonID := '';
    Exit;
  end;

  // Se ja for a pessoa ativa, apenas atualiza timestamp
  if (FActiveSession <> nil) and SameText(FActiveSession.PersonID, APersonID) then
  begin
    FActiveSession.LastActiveAt := Now;
    FCandidatePersonID := '';
    Exit(True);
  end;

  NowTime := Now;
  if not SameText(FCandidatePersonID, APersonID) then
  begin
    FCandidatePersonID := APersonID;
    FCandidatePersonName := AName;
    FCandidateStartTime := NowTime;
    Exit(False);
  end;

  // Verifica tempo de estabilidade (ex: 1500 ms) antes de alternar contexto
  ElapsedMs := MilliSecondsBetween(NowTime, FCandidateStartTime);
  if ElapsedMs >= FRecognitionStableTimeMs then
  begin
    ActivatePerson(FCandidatePersonID, FCandidatePersonName);
    FCandidatePersonID := '';
    Result := True;
  end;
end;

procedure TAIPersonSessionManager.SuspendCurrentPerson;
begin
  if FActiveSession <> nil then
  begin
    FActiveSession.LastActiveAt := Now;
    SwitchActiveSession(nil);
  end;
end;

procedure TAIPersonSessionManager.ResumePerson(const APersonID: string);
var
  S: TAIPersonSession;
begin
  S := FindSession(APersonID);
  if S <> nil then
    SwitchActiveSession(S);
end;

function TAIPersonSessionManager.CreateGuestSession: TAIPersonSession;
var
  GuestID: string;
begin
  GuestID := GenerateGuestID;
  Result := TAIPersonSession.Create(GuestID, 'Convidado', True);
  FSessions.Add(Result);
  SwitchActiveSession(Result);
end;

function TAIPersonSessionManager.BuildEnrichedPersonPrompt(const AUserUtterance: string): string;
var
  SL: TStringList;
  MemSummary, RecMsgs: string;
begin
  SL := TStringList.Create;
  try
    SL.Add('[SESSÃO E CONTEXTO INDIVIDUAL DO INTERLOCUTOR]');

    if FActiveSession <> nil then
    begin
      SL.Add(Format('- Interlocutor Ativo: %s (ID: %s)', [FActiveSession.Name, FActiveSession.PersonID]));
      if FActiveSession.CurrentProject <> '' then
        SL.Add('- Projeto em foco para esta pessoa: ' + FActiveSession.CurrentProject);
      if FActiveSession.LastTopic <> '' then
        SL.Add('- Último tópico abordado: ' + FActiveSession.LastTopic);

      // Memória de Longo Prazo Resumida (Tarefas de interesse, perfil)
      MemSummary := FActiveSession.GetLongTermMemorySummary;
      if MemSummary <> '' then
      begin
        SL.Add('- Memória e Interesses Prévios:');
        SL.Add(MemSummary);
      end;

      // Histórico Recente Curto (Últimas mensagens para manter concisão)
      RecMsgs := FActiveSession.GetRecentMessagesFormatted(5);
      if RecMsgs <> '' then
      begin
        SL.Add('- Diálogo Recente Desta Pessoa:');
        SL.Add(RecMsgs);
      end;
    end
    else
    begin
      SL.Add('- Interlocutor: Visitante Anônimo');
    end;

    SL.Add('');
    SL.Add('Pergunta Atual do Interlocutor: "' + Trim(AUserUtterance) + '"');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

{ TAIActiveSpeakerManager }

constructor TAIActiveSpeakerManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPersonsPresent := TStringList.Create;
  FPersonsPresent.CaseSensitive := False;
  FActiveSpeakerID := '';
  FActiveSpeakerName := '';
end;

destructor TAIActiveSpeakerManager.Destroy;
begin
  FPersonsPresent.Free;
  inherited Destroy;
end;

procedure TAIActiveSpeakerManager.AddPersonPresent(const APersonID, AName: string);
begin
  if FPersonsPresent.IndexOf(APersonID) = -1 then
    FPersonsPresent.AddObject(APersonID, TObject(Pointer(PtrInt(1))));

  // Se nao ha interlocutor ativo no momento, assume o primeiro
  if FActiveSpeakerID = '' then
    SetActiveSpeaker(APersonID);
end;

procedure TAIActiveSpeakerManager.RemovePersonPresent(const APersonID: string);
var
  Idx: Integer;
begin
  Idx := FPersonsPresent.IndexOf(APersonID);
  if Idx <> -1 then
    FPersonsPresent.Delete(Idx);

  if SameText(FActiveSpeakerID, APersonID) then
  begin
    if FPersonsPresent.Count > 0 then
      SetActiveSpeaker(FPersonsPresent[0])
    else
      SetActiveSpeaker('');
  end;
end;

procedure TAIActiveSpeakerManager.ClearPersonsPresent;
begin
  FPersonsPresent.Clear;
  SetActiveSpeaker('');
end;

procedure TAIActiveSpeakerManager.SetActiveSpeaker(const APersonID: string);
begin
  if FActiveSpeakerID = APersonID then Exit;

  FActiveSpeakerID := APersonID;
  if FSessionManager <> nil then
  begin
    if FActiveSpeakerID <> '' then
      FSessionManager.ActivatePerson(FActiveSpeakerID, '')
    else
      FSessionManager.SuspendCurrentPerson;
  end;
end;

function TAIActiveSpeakerManager.IsPersonPresent(const APersonID: string): Boolean;
begin
  Result := FPersonsPresent.IndexOf(APersonID) <> -1;
end;

end.
