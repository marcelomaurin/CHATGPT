program test_person_session_memory;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aipersonsession;

type
  TTestSessionRunner = class
  private
    FPersonChangedCount: Integer;
    FLastOldID: string;
    FLastNewID: string;
  public
    procedure HandleActivePersonChanged(Sender: TObject; const AOldID, ANewID: string);
    procedure Run;
  end;

procedure TTestSessionRunner.HandleActivePersonChanged(Sender: TObject; const AOldID, ANewID: string);
begin
  Inc(FPersonChangedCount);
  FLastOldID := AOldID;
  FLastNewID := ANewID;
  WriteLn(Format('  [EVENTO OnActivePersonChanged] Troca de interlocutor: "%s" -> "%s"', [AOldID, ANewID]));
end;

procedure TTestSessionRunner.Run;
var
  Mgr: TAIPersonSessionManager;
  SpeakerMgr: TAIActiveSpeakerManager;
  S_Marcelo, S_Ana, S_Guest: TAIPersonSession;
  PromptMarcelo, PromptAna: string;
begin
  WriteLn('======================================================================');
  WriteLn('TESTE AUTOMATIZADO: SESSAO POR PESSOA, MEMORIA LONGA E SPEAKER ATIVO');
  WriteLn('======================================================================');

  Mgr := TAIPersonSessionManager.Create(nil);
  SpeakerMgr := TAIActiveSpeakerManager.Create(nil);
  try
    Mgr.OnActivePersonChanged := @HandleActivePersonChanged;
    SpeakerMgr.SessionManager := Mgr;

    // -------------------------------------------------------------
    // Teste 1: Marcelo se aproxima (PersonID = 15)
    // -------------------------------------------------------------
    WriteLn('[1] Ativando Marcelo (PersonID = 15)...');
    S_Marcelo := Mgr.ActivatePerson('15', 'Marcelo');
    S_Marcelo.CurrentProject := 'Hemacias';
    S_Marcelo.AddMessage('user', 'Como funciona o projeto Hemacias?');
    S_Marcelo.AddMessage('assistant', 'O projeto conta celulas em microscopia.');
    S_Marcelo.AddMessage('user', 'E sobre aquela camera que eu perguntei?');
    S_Marcelo.AddMessage('assistant', 'Funciona com cameras de microscopia padrao.');

    // Memoria de longo prazo
    S_Marcelo.AddMemory('Interesse', 'Captura microscopica e contagem automatizada');
    S_Marcelo.AddMemory('Modelo', 'Preferencia por YOLO');

    if Mgr.ActiveSession.PersonID <> '15' then
      raise Exception.Create('Pessoa ativa deveria ser 15 (Marcelo)');
    WriteLn('  - Mensagens no historico do Marcelo: ', S_Marcelo.MessageCount);
    WriteLn('  - Memorias de longo prazo do Marcelo: ', S_Marcelo.MemoryCount);

    PromptMarcelo := Mgr.BuildEnrichedPersonPrompt('E sobre o YOLO?');
    if Pos('Marcelo', PromptMarcelo) = 0 then
      raise Exception.Create('Prompt de Marcelo deveria conter o nome');
    if Pos('YOLO', PromptMarcelo) = 0 then
      raise Exception.Create('Prompt de Marcelo deveria conter memoria previa de YOLO');
    WriteLn('  - Prompt contextualizado com memoria longa gerado com sucesso.');

    // -------------------------------------------------------------
    // Teste 2: Ana chega (PersonID = 27) -> Troca automatica de sessao
    // -------------------------------------------------------------
    WriteLn('[2] Ana chega (PersonID = 27) e passa a falar...');
    S_Ana := Mgr.ActivatePerson('27', 'Ana');
    S_Ana.CurrentProject := 'Hemacias';
    S_Ana.AddMessage('user', 'Esse projeto usa IA?');
    S_Ana.AddMessage('assistant', 'Sim, utiliza redes neurais convolucionais.');

    if Mgr.ActiveSession.PersonID <> '27' then
      raise Exception.Create('Pessoa ativa deveria ser 27 (Ana)');

    // Verifica que o historico de Ana NAO contem a conversa do Marcelo sobre camera
    PromptAna := Mgr.BuildEnrichedPersonPrompt('Como treinaram?');
    if Pos('Marcelo', PromptAna) > 0 then
      raise Exception.Create('Prompt de Ana NAO deve conter dados de Marcelo');
    if Pos('camera', PromptAna) > 0 then
      raise Exception.Create('Prompt de Ana NAO deve conter historico de camera do Marcelo');
    WriteLn('  - Isolamento de sessao validado: Ana tem historico proprio e limpo.');

    // -------------------------------------------------------------
    // Teste 3: Marcelo volta -> Recuperacao instantanea da conversa
    // -------------------------------------------------------------
    WriteLn('[3] Marcelo volta a falar: "E sobre aquela camera que eu perguntei?"...');
    Mgr.ResumePerson('15');
    if Mgr.ActiveSession.PersonID <> '15' then
      raise Exception.Create('Falha ao restaurar sessao do Marcelo');
    if Mgr.ActiveSession.CurrentProject <> 'Hemacias' then
      raise Exception.Create('Projeto em foco do Marcelo deveria ser Hemacias');

    PromptMarcelo := Mgr.BuildEnrichedPersonPrompt('E sobre aquela camera que eu perguntei?');
    if Pos('microscopia', PromptMarcelo) = 0 then
      raise Exception.Create('Historico previo do Marcelo deveria ter sido recuperado');
    WriteLn('  - Contexto de Marcelo recuperado perfeitamente (Projeto: ', Mgr.ActiveSession.CurrentProject, ')');

    // -------------------------------------------------------------
    // Teste 4: Anti-flicker e Estabilidade Visual
    // -------------------------------------------------------------
    WriteLn('[4] Testando Anti-Flicker de Reconhecimento Facial...');
    Mgr.RecognitionStableTimeMs := 500; // 500 ms para teste
    Mgr.RecognitionThreshold := 0.85;

    // Reconhecimento instavel com confianca baixa (0.60) -> deve ser ignorado
    if Mgr.FeedVisualRecognition('99', 'Carlos', 0.60) then
      raise Exception.Create('Reconhecimento abaixo do threshold nao deveria alterar sessao');
    WriteLn('  - Frame de baixa confianca (0.60 < 0.85) descartado corretamente.');

    // Reconhecimento confiavel por tempo insuficiente (< 500 ms) -> nao troca
    Mgr.FeedVisualRecognition('99', 'Carlos', 0.95);
    if Mgr.ActiveSession.PersonID = '99' then
      raise Exception.Create('Nao deveria ter trocado para Carlos sem atingir tempo estavel');
    WriteLn('  - Frame inicial de Carlos registrado sem troca imediata.');

    // Espera tempo de estabilidade e reenvia
    Sleep(550);
    if not Mgr.FeedVisualRecognition('99', 'Carlos', 0.95) then
      raise Exception.Create('Deveria ter confirmado troca para Carlos apos tempo estavel');
    if Mgr.ActiveSession.PersonID <> '99' then
      raise Exception.Create('Sessao ativa agora deve ser Carlos (99)');
    WriteLn('  - Troca estavel confirmada para Carlos apos 500 ms de permanencia.');

    // -------------------------------------------------------------
    // Teste 5: Multiplas Pessoas Presentes vs Interlocutor Ativo
    // -------------------------------------------------------------
    WriteLn('[5] Testando TAIActiveSpeakerManager (Marcelo, Ana, Carlos presentes)...');
    SpeakerMgr.ClearPersonsPresent;
    SpeakerMgr.AddPersonPresent('15', 'Marcelo');
    SpeakerMgr.AddPersonPresent('27', 'Ana');
    SpeakerMgr.AddPersonPresent('99', 'Carlos');

    if SpeakerMgr.PersonsPresent.Count <> 3 then
      raise Exception.Create('Deveriam haver 3 pessoas presentes');

    // Define Ana como quem está falando
    SpeakerMgr.SetActiveSpeaker('27');
    if SpeakerMgr.ActiveSpeakerID <> '27' then
      raise Exception.Create('ActiveSpeaker deveria ser 27 (Ana)');
    if Mgr.ActiveSession.PersonID <> '27' then
      raise Exception.Create('SessionManager deveria ter ativado Ana');
    WriteLn('  - Multiplas presencas suportadas; interlocutor ativo (Ana) direciona a sessao.');

    // -------------------------------------------------------------
    // Teste 6: Visitante Desconhecido (GuestSession)
    // -------------------------------------------------------------
    WriteLn('[6] Testando Sessao de Convidado Temporario...');
    S_Guest := Mgr.CreateGuestSession;
    if not S_Guest.IsGuest then
      raise Exception.Create('Sessao de convidado deveria ter flag IsGuest=True');
    if Pos('GuestSession-', S_Guest.PersonID) = 0 then
      raise Exception.Create('ID de convidado fora do padrao esperado');
    WriteLn('  - Convidado criado com sucesso: ', S_Guest.PersonID);

    WriteLn('======================================================================');
    WriteLn('[SUCESSO] TODOS OS TESTES DE SESSAO E MEMORIA POR PESSOA PASSARAM!');
    WriteLn('======================================================================');
  finally
    SpeakerMgr.Free;
    Mgr.Free;
  end;
end;

var
  Runner: TTestSessionRunner;
begin
  Runner := TTestSessionRunner.Create;
  try
    Runner.Run;
  except
    on E: Exception do
    begin
      WriteLn('[FALHA] ', E.Message);
      Halt(1);
    end;
  end;
  Runner.Free;
end.
