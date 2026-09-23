program test_conversation_orchestrator;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aiinteractioncontext, aiconversationorchestrator;

type
  TTestRunner = class
  public
    InterruptionTriggered: Boolean;
    LastRAGQuery: string;
    procedure HandleInterruption(Sender: TObject);
    procedure HandleDynamicRAG(Sender: TObject; const AProjects: string; const AQuery: string; out RAGResult: string);
    procedure Run;
  end;

procedure TTestRunner.HandleInterruption(Sender: TObject);
begin
  InterruptionTriggered := True;
  WriteLn('  [EVENTO] Interrupcao de fala detectada (Barge-In)! Fala do avatar abortada com sucesso.');
end;

procedure TTestRunner.HandleDynamicRAG(Sender: TObject; const AProjects: string; const AQuery: string; out RAGResult: string);
begin
  LastRAGQuery := AProjects + ' -> ' + AQuery;
  WriteLn('  [RAG DINAMICO] Buscando base de conhecimento para o(s) projeto(s): ', AProjects);
  if Pos('Hemacias', AProjects) > 0 then
    RAGResult := 'O projeto Hemacias processa imagens de microscopia para contagem automatizada de celulas sanguineas.'
  else if Pos('ECG', AProjects) > 0 then
    RAGResult := 'O projeto ECG realiza analise de sinais temporais cardiacos para deteccao de arritmias.'
  else
    RAGResult := 'Dados tecnicos gerais.';
end;

procedure TTestRunner.Run;
var
  Orch: TAIConversationOrchestrator;
  Ctx: TAIInteractionContext;
  Response: string;
  Clarification: string;
begin
  WriteLn('======================================================================');
  WriteLn('TESTE AUTOMATIZADO: CONTEXTO CONTINUO, RAG DINAMICO E ORQUESTRADOR');
  WriteLn('======================================================================');

  Orch := TAIConversationOrchestrator.Create(nil);
  try
    Ctx := Orch.Context;
    Orch.OnInterruption := @HandleInterruption;
    Orch.OnDynamicRAG := @HandleDynamicRAG;

    // Cenario 1: Pessoa se aproxima
    WriteLn('[1] Pessoa se aproxima da camera...');
    Orch.NotifyPersonDetected('Marcelo');
    if Ctx.CurrentPerson <> 'Marcelo' then
      raise Exception.Create('Falha ao registrar pessoa atual');
    WriteLn('  - Pessoa identificada: ', Ctx.CurrentPerson);

    // Cenario 2: Pergunta apontando para Hemacias
    WriteLn('[2] Usuario aponta para Hemacias e pergunta "Esse aqui faz o que?"...');
    Orch.NotifyGestureDetected('Point', 'Hemacias');
    Orch.ProcessSpeechUtterance('Esse aqui faz o que?', Response);
    if Ctx.CurrentProject <> 'Hemacias' then
      raise Exception.Create('Deveria ter resolvido projeto para Hemacias');
    WriteLn('  - Projeto em foco resolvido: ', Ctx.CurrentProject);
    WriteLn('  - Resposta do Sistema: ', Response);

    // Cenario 3: Pergunta continua sem citar nome do projeto
    WriteLn('[3] Usuario continua: "E funciona com qualquer camera?"...');
    Orch.ProcessSpeechUtterance('E funciona com qualquer camera?', Response);
    if Ctx.CurrentProject <> 'Hemacias' then
      raise Exception.Create('Deveria ter mantido Hemacias no contexto continuo');
    WriteLn('  - Projeto mantido no contexto: ', Ctx.CurrentProject);

    // Cenario 4: Correcao natural de assunto
    WriteLn('[4] Usuario corrige: "Nao, eu estava falando daquele do coracao"...');
    Orch.ProcessSpeechUtterance('Nao, eu estava falando daquele do coracao', Response);
    if Ctx.CurrentProject <> 'ECG' then
      raise Exception.Create('Deveria ter mudado projeto para ECG');
    if Ctx.LastProjectCited <> 'Hemacias' then
      raise Exception.Create('Deveria ter guardado Hemacias como LastProjectCited');
    WriteLn('  - Novo foco: ', Ctx.CurrentProject, ' (Anterior: ', Ctx.LastProjectCited, ')');

    // Cenario 5: Comparacao entre os dois projetos
    WriteLn('[5] Usuario pergunta: "qual dos dois usa visao computacional?"...');
    Orch.ProcessSpeechUtterance('qual dos dois usa visao computacional?', Response);
    WriteLn('  - RAG consultado dinamicamente: ', LastRAGQuery);

    // Cenario 6: Pergunta de esclarecimento (quando realmente ambiguo)
    WriteLn('[6] Pergunta ambigua sem contexto previo...');
    Ctx.Clear; // Limpa contexto propositalmente para simular ambiguidade
    if Ctx.NeedsClarification('Esse equipamento funciona com camera?', Clarification) then
    begin
      WriteLn('  - Esclarecimento solicitado: "', Clarification, '"');
    end
    else
      raise Exception.Create('Deveria ter pedido esclarecimento para pronome sem contexto');

    // Cenario 7: Barge-in / Interrupcao de fala
    WriteLn('[7] Testando Barge-In (Interrupcao pelo usuario enquanto avatar fala)...');
    InterruptionTriggered := False;
    Orch.StartSpeaking;
    if not Orch.IsSpeaking then
      raise Exception.Create('Orchestrator deveria estar IsSpeaking');

    // Microfone detecta que usuario comecou a falar
    Orch.NotifySpeechStart;

    if Orch.IsSpeaking then
      raise Exception.Create('IsSpeaking deveria ter sido cancelado pelo Barge-In');
    if not InterruptionTriggered then
      raise Exception.Create('Evento OnInterruption nao disparou');

    WriteLn('======================================================================');
    WriteLn('[SUCESSO] TODOS OS CENARIOS DE CONVERSACAO NATURAL FORAM VALIDADOS!');
    WriteLn('======================================================================');
  finally
    Orch.Free;
  end;
end;

var
  Runner: TTestRunner;
begin
  Runner := TTestRunner.Create;
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
