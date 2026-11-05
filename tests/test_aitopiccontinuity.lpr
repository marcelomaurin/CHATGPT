program test_aitopiccontinuity;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aitopiccontinuity;

procedure AssertTrue(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise Exception.Create('FALHA DE ASSERCAO: ' + Msg);
end;

var
  Classifier: TAITopicContinuityClassifier;
  Decision: TAIContinuityDecision;
  Score: Double;
  Reason: string;
  EnrichedPrompt: string;
begin
  WriteLn('======================================================================');
  WriteLn('TESTE AUTOMATIZADO: DETECCAO DE MUDANCA DE TOPICO E CONTINUIDADE');
  WriteLn('======================================================================');

  Classifier := TAITopicContinuityClassifier.Create(nil);
  try
    Classifier.RegisterKnownEntity('Prefeitura', 'empresa');
    Classifier.RegisterKnownEntity('Coderp', 'empresa');
    Classifier.RegisterKnownEntity('Hemacias', 'projeto');
    Classifier.RegisterKnownEntity('ECG', 'projeto');

    // -----------------------------------------------------------------------
    // Cenario 1: Primeira mensagem - inicia tarefa de boleto
    // -----------------------------------------------------------------------
    WriteLn('[1] Primeira mensagem: "Preciso emitir o boleto 12345 da Prefeitura"...');
    Classifier.ProcessUtterance('Preciso emitir o boleto 12345 da Prefeitura', Decision, EnrichedPrompt);
    WriteLn('  - Decisao: ', Decision, ' | Razao: ', Classifier.LastReason);
    AssertTrue(Decision = cdNewTopic, 'Primeira interacao deveria iniciar um novo topico');
    AssertTrue(Assigned(Classifier.ActiveTopic), 'Topico ativo nao foi criado');
    AssertTrue(Classifier.ActiveTopic.Entities.FindByCategory('documento') <> nil, 'Documento 12345 nao foi extraido');
    AssertTrue(Classifier.ActiveTopic.Entities.FindByCategory('empresa') <> nil, 'Entidade Prefeitura nao foi extraida');
    Classifier.RecordAIResponse('Boleto 12345 localizado com vencimento para amanha.');

    // -----------------------------------------------------------------------
    // Cenario 2: Continuidade natural da mesma tarefa
    // -----------------------------------------------------------------------
    WriteLn('[2] Usuario continua: "Qual e o valor dele e posso pagar pelo PIX?"...');
    Classifier.ProcessUtterance('Qual e o valor dele e posso pagar pelo PIX?', Decision, EnrichedPrompt);
    WriteLn('  - Decisao: ', Decision, ' | Escore: ', Classifier.LastScore:0:2, ' | Razao: ', Classifier.LastReason);
    AssertTrue(Decision = cdContinue, 'Deveria classificar como continuacao de tarefa (cdContinue)');
    AssertTrue(Classifier.ActiveTopic.Utterances.Count >= 2, 'Historico da tarefa deveria ter sido incrementado');
    Classifier.RecordAIResponse('O valor e de R$ 150,00 e aceita PIX.');

    // -----------------------------------------------------------------------
    // Cenario 3: Correcao de entidade ("Nao, na verdade e o boleto 98765")
    // -----------------------------------------------------------------------
    WriteLn('[3] Usuario corrige: "Nao, na verdade o boleto correto e 98765"...');
    Classifier.ProcessUtterance('Nao, na verdade o boleto correto e 98765', Decision, EnrichedPrompt);
    WriteLn('  - Decisao: ', Decision, ' | Razao: ', Classifier.LastReason);
    AssertTrue(Decision = cdCorrection, 'Deveria identificar correcao de dados (cdCorrection)');
    AssertTrue(Classifier.ActiveTopic.Entities.FindByCategory('documento').Value = '98765',
      'Entidade documento deveria ter sido atualizada para 98765');
    Classifier.RecordAIResponse('Entendido, atualizei para o boleto 98765.');

    // -----------------------------------------------------------------------
    // Cenario 4: Mudanca explicita de topico
    // -----------------------------------------------------------------------
    WriteLn('[4] Usuario muda de assunto: "Mudando de assunto, como esta o andamento do projeto Hemacias?"...');
    Classifier.ProcessUtterance('Mudando de assunto, como esta o andamento do projeto Hemacias?', Decision, EnrichedPrompt);
    WriteLn('  - Decisao: ', Decision, ' | Razao: ', Classifier.LastReason);
    AssertTrue(Decision = cdNewTopic, 'Deveria detectar mudanca de topico (cdNewTopic)');
    AssertTrue(Classifier.TopicStack.GetPausedCount = 1, 'Topico anterior deveria ter sido pausado na pilha');
    AssertTrue(Classifier.ActiveTopic.Entities.FindByCategory('projeto') <> nil, 'Projeto Hemacias deveria ser ativo');
    Classifier.RecordAIResponse('O projeto Hemacias esta na fase de treinamento do modelo YOLO.');

    // -----------------------------------------------------------------------
    // Cenario 5: Encerramento de tarefa
    // -----------------------------------------------------------------------
    WriteLn('[5] Usuario finaliza a tarefa atual: "Muito obrigado, por hoje era so isso"...');
    Classifier.ProcessUtterance('Muito obrigado, por hoje era so isso', Decision, EnrichedPrompt);
    WriteLn('  - Decisao: ', Decision, ' | Razao: ', Classifier.LastReason);
    AssertTrue(Decision = cdFinishTask, 'Deveria identificar finalizacao de tarefa (cdFinishTask)');
    AssertTrue(Classifier.TopicStack.GetCompletedCount = 1, 'Tarefa deveria ser marcada como concluida');

    // -----------------------------------------------------------------------
    // Cenario 6: Retomada do topico anterior da pilha
    // -----------------------------------------------------------------------
    WriteLn('[6] Usuario retoma assunto anterior: "Voltando ao boleto da prefeitura"...');
    Classifier.ProcessUtterance('Voltando ao boleto da prefeitura', Decision, EnrichedPrompt);
    WriteLn('  - Decisao: ', Decision, ' | Razao: ', Classifier.LastReason);
    AssertTrue(Decision = cdResumeTopic, 'Deveria desempilhar e retomar assunto anterior (cdResumeTopic)');
    AssertTrue(Assigned(Classifier.ActiveTopic), 'Deveria haver um topico ativo retomado');
    AssertTrue(Classifier.ActiveTopic.Entities.FindByCategory('documento') <> nil, 'Topico retomado deveria ter o documento');
    WriteLn('  - Topico reativado: ', Classifier.ActiveTopic.Title, ' com doc: ', Classifier.ActiveTopic.Entities.FindByCategory('documento').Value);

    WriteLn('');
    WriteLn('--- RESUMO DA PILHA DE TOPICOS ---');
    WriteLn(Classifier.FormatStackSummary);
    WriteLn('======================================================================');
    WriteLn('TODOS OS 6 CENARIOS DO CLASSIFICADOR PASSARAM COM SUCESSO!');
    WriteLn('======================================================================');
  finally
    Classifier.Free;
  end;
end.
