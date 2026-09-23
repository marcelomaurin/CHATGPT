unit aiinteractioncontext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { Gerenciador de Contexto Continuo de Interacao Multi-Modal }
  TAIInteractionContext = class(TPersistent)
  private
    FCurrentPerson: string;
    FCurrentProject: string;
    FLastProjectCited: string;
    FObjectPointed: string;
    FLastUtterance: string;
    FLastResponse: string;
    FCurrentTopic: string;
    FProbableIntent: string;
    FContextConfidence: Single;
    FRecentHistory: TStringList;
    FMaxHistoryEntries: Integer;
    procedure SetCurrentProject(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure RecordInteraction(const AUserUtterance, AAIResponse: string);
    function ResolveReference(const AInput: string): string;
    function BuildEnrichedPrompt(const AUserUtterance: string): string;
    function NeedsClarification(const AUserUtterance: string; out ClarificationQuestion: string): Boolean;

    property CurrentPerson: string read FCurrentPerson write FCurrentPerson;
    property CurrentProject: string read FCurrentProject write SetCurrentProject;
    property LastProjectCited: string read FLastProjectCited write FLastProjectCited;
    property ObjectPointed: string read FObjectPointed write FObjectPointed;
    property LastUtterance: string read FLastUtterance write FLastUtterance;
    property LastResponse: string read FLastResponse write FLastResponse;
    property CurrentTopic: string read FCurrentTopic write FCurrentTopic;
    property ProbableIntent: string read FProbableIntent write FProbableIntent;
    property ContextConfidence: Single read FContextConfidence write FContextConfidence;
    property RecentHistory: TStringList read FRecentHistory;
    property MaxHistoryEntries: Integer read FMaxHistoryEntries write FMaxHistoryEntries default 10;
  end;

implementation

{ TAIInteractionContext }

constructor TAIInteractionContext.Create;
begin
  inherited Create;
  FRecentHistory := TStringList.Create;
  FMaxHistoryEntries := 10;
  FContextConfidence := 1.0;
  Clear;
end;

destructor TAIInteractionContext.Destroy;
begin
  FRecentHistory.Free;
  inherited Destroy;
end;

procedure TAIInteractionContext.Clear;
begin
  FCurrentPerson := '';
  FCurrentProject := '';
  FLastProjectCited := '';
  FObjectPointed := '';
  FLastUtterance := '';
  FLastResponse := '';
  FCurrentTopic := '';
  FProbableIntent := '';
  FContextConfidence := 1.0;
  FRecentHistory.Clear;
end;

procedure TAIInteractionContext.SetCurrentProject(const AValue: string);
var
  CleanVal: string;
begin
  CleanVal := Trim(AValue);
  if (CleanVal <> '') and (CleanVal <> FCurrentProject) then
  begin
    FLastProjectCited := FCurrentProject;
    FCurrentProject := CleanVal;
  end;
end;

procedure TAIInteractionContext.RecordInteraction(const AUserUtterance, AAIResponse: string);
begin
  FLastUtterance := Trim(AUserUtterance);
  FLastResponse := Trim(AAIResponse);

  if FLastUtterance <> '' then
  begin
    FRecentHistory.Add('Usuário: ' + FLastUtterance);
    if FLastResponse <> '' then
      FRecentHistory.Add('Assistente: ' + FLastResponse);

    while FRecentHistory.Count > (FMaxHistoryEntries * 2) do
      FRecentHistory.Delete(0);
  end;
end;

function TAIInteractionContext.ResolveReference(const AInput: string): string;
var
  LowText: string;
begin
  LowText := LowerCase(Trim(AInput));

  // Detecta mencao direta ou correcao de contexto
  if (Pos('cora', LowText) > 0) or (Pos('ecg', LowText) > 0) or (Pos('card', LowText) > 0) then
  begin
    CurrentProject := 'ECG';
    Result := 'ECG';
    Exit;
  end;

  if (Pos('hemac', LowText) > 0) or (Pos('sangue', LowText) > 0) or (Pos('celula', LowText) > 0) or (Pos('microscop', LowText) > 0) then
  begin
    CurrentProject := 'Hemacias';
    Result := 'Hemacias';
    Exit;
  end;

  if (Pos('robotin', LowText) > 0) or (Pos('robo', LowText) > 0) or (Pos('braco', LowText) > 0) or (Pos('motor', LowText) > 0) then
  begin
    CurrentProject := 'Robotinics';
    Result := 'Robotinics';
    Exit;
  end;

  // Resolve demonstrativos ("esse", "aquele", "este", "o projeto")
  if (Pos('esse', LowText) > 0) or (Pos('este', LowText) > 0) or (Pos('aquele', LowText) > 0) or (Pos('dele', LowText) > 0) then
  begin
    if Trim(FObjectPointed) <> '' then
    begin
      CurrentProject := FObjectPointed;
      Result := FObjectPointed;
      Exit;
    end;

    if Trim(FCurrentProject) <> '' then
    begin
      Result := FCurrentProject;
      Exit;
    end;
  end;

  Result := FCurrentProject;
end;

function TAIInteractionContext.NeedsClarification(const AUserUtterance: string; out ClarificationQuestion: string): Boolean;
var
  LowText: string;
begin
  LowText := LowerCase(Trim(AUserUtterance));
  ClarificationQuestion := '';
  Result := False;

  // Se usuario usa pronome ambiguo ("esse funciona com camera?") sem foco nem apontamento
  if ((Pos('esse', LowText) > 0) or (Pos('este', LowText) > 0) or (Pos('o projeto', LowText) > 0)) and
     (Trim(FCurrentProject) = '') and (Trim(FObjectPointed) = '') then
  begin
    ClarificationQuestion := 'Você está se referindo ao projeto Hemácias, ao ECG ou à Robótica?';
    Result := True;
  end;
end;

function TAIInteractionContext.BuildEnrichedPrompt(const AUserUtterance: string): string;
var
  ResolvedTarget: string;
  SB: TStringList;
  I: Integer;
begin
  ResolvedTarget := ResolveReference(AUserUtterance);
  SB := TStringList.Create;
  try
    SB.Add('[CONTEXTO CONTÍNUO DE INTERAÇÃO MULTI-MODAL]');
    if Trim(FCurrentPerson) <> '' then
      SB.Add('- Pessoa presente / interlocutor: ' + FCurrentPerson)
    else
      SB.Add('- Interlocutor: Visitante presente em frente ao avatar');

    if Trim(FCurrentProject) <> '' then
      SB.Add('- Projeto atualmente em foco: ' + FCurrentProject)
    else if Trim(ResolvedTarget) <> '' then
      SB.Add('- Projeto inferido: ' + ResolvedTarget)
    else
      SB.Add('- Projeto em foco: Geral / Não especificado');

    if Trim(FObjectPointed) <> '' then
      SB.Add('- Objeto ou painel apontado fisicamente: ' + FObjectPointed);

    if Trim(FLastProjectCited) <> '' then
      SB.Add('- Último projeto citado anteriormente: ' + FLastProjectCited);

    if Trim(FCurrentTopic) <> '' then
      SB.Add('- Tópico recente: ' + FCurrentTopic);

    if FRecentHistory.Count > 0 then
    begin
      SB.Add('- Histórico recente da conversa:');
      for I := 0 to FRecentHistory.Count - 1 do
        SB.Add('    ' + FRecentHistory[I]);
    end;

    SB.Add('');
    SB.Add('Instruções de Conversação Natural:');
    SB.Add('- Responda de forma fluida, direta e amigável, como um apresentador humano real.');
    SB.Add('- Resolva pronomes como "esse", "aquele", "ele" usando o contexto e o objeto apontado acima.');
    SB.Add('- Se o usuário perguntou sobre múltiplos projetos ou comparações, compare-os pontualmente.');
    SB.Add('- Evite formulários rígidos, opções numeradas ou scripts engessados de quiosque.');
    SB.Add('- Responda em formato conversacional pronto para o avatar expressar.');
    SB.Add('');
    SB.Add('Fala do Usuário: "' + Trim(AUserUtterance) + '"');

    Result := SB.Text;
  finally
    SB.Free;
  end;
end;

end.
