program test_virtual_professor_presentation;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aipresentation;

var
  ResMgr: TAIPresentationResourceManager;
  ProfAgent: TAIPresentationAgent;
  Narrative: string;
  BestRes: TPresentationResource;

procedure Assert(Condition: Boolean; const Msg: string);
begin
  if not Condition then
  begin
    WriteLn('[FALHA] ' + Msg);
    Halt(1);
  end;
  WriteLn('  ✓ ' + Msg);
end;

begin
  WriteLn('======================================================================');
  WriteLn('TESTE: PROFESSOR VIRTUAL AUTONOMO & PACOTES DE EXPOSICAO MULTIMIDIA');
  WriteLn('======================================================================');

  ResMgr := TAIPresentationResourceManager.Create(nil);
  ProfAgent := TAIPresentationAgent.Create(nil);
  try
    ProfAgent.ResourceManager := ResMgr;

    WriteLn('[1] Validando catalogo de pacotes academicos...');
    Assert(ResMgr.PackageCount >= 4, 'Pelo menos 4 projetos de exposicao cadastrados');
    Assert(ResMgr.FindPackage('HEMACIAS') <> nil, 'Pacote HEMACIAS encontrado');
    Assert(ResMgr.FindPackage('ROBOTINICS') <> nil, 'Pacote ROBOTINICS encontrado');

    WriteLn('[2] Testando busca semantica de recursos por topico...');
    BestRes := ResMgr.FindBestResource('HEMACIAS', 'deteccao celulas yolo');
    Assert(BestRes <> nil, 'Recurso encontrado para busca YOLO');
    Assert(BestRes.ID = 'img_yolo', 'Recurso mais relevante selecionado foi img_yolo');

    BestRes := ResMgr.FindBestResource('ROBOTINICS', 'planta do laboratorio com lidar slam');
    Assert(BestRes <> nil, 'Recurso encontrado para SLAM');
    Assert(BestRes.ID = 'img_slam', 'Recurso selecionado foi img_slam');

    WriteLn('[3] Visitante Marcelo se aproxima: inicio autonomo da apresentacao...');
    Narrative := ProfAgent.StartPresentation('15', 'Marcelo');
    WriteLn('  [Professor]: ' + Narrative);
    Assert(ProfAgent.CurrentPackage <> nil, 'Projeto atual definido');
    Assert(ProfAgent.CurrentPackage.ProjectCode = 'HEMACIAS', 'Projeto inicial selecionado foi HEMACIAS');
    Assert(ProfAgent.CurrentResource <> nil, 'Recurso visual selecionado para exibicao');
    Assert(ProfAgent.State = psPresentingConcept, 'Estado do agente e psPresentingConcept');

    WriteLn('[4] Avancando a narrativa para o proximo conceito...');
    Narrative := ProfAgent.ContinuePresentation;
    WriteLn('  [Professor]: ' + Narrative);
    Assert(ProfAgent.CurrentConcept.ID = 'yolo', 'Conceito avancado para YOLO');
    Assert(ProfAgent.CurrentResource.ID = 'img_yolo', 'Recurso visual atualizado para img_yolo');

    WriteLn('[5] Marcelo interrompe com duvida: "Qual inteligencia artificial voces usam?"...');
    Narrative := ProfAgent.AnswerQuestion('Qual inteligencia artificial voces usam?');
    WriteLn('  [Professor - Resposta]: ' + Narrative);
    Assert(ProfAgent.State = psAnsweringQuestion, 'Estado mudou temporariamente para psAnsweringQuestion');
    Assert(Pos('YOLO', Narrative) > 0, 'Resposta contem explicacao sobre YOLO');

    WriteLn('[6] Professor retoma a apresentacao sem perder o fio condutor...');
    Narrative := ProfAgent.ResumePresentation;
    WriteLn('  [Professor - Retomada]: ' + Narrative);
    Assert(ProfAgent.State = psPresentingConcept, 'Estado retornou para psPresentingConcept');
    Assert(ProfAgent.CurrentConcept.ID = 'yolo', 'Manteve o conceito em que estava antes da pergunta');

    WriteLn('[7] Concluindo conceitos de Hemacias e transicao autonoma para Robotinics...');
    ProfAgent.ContinuePresentation; // contagem
    ProfAgent.ContinuePresentation; // calibracao
    Narrative := ProfAgent.ContinuePresentation; // Deve transicionar para o proximo projeto
    WriteLn('  [Professor - Transicao]: ' + Narrative);
    Assert(ProfAgent.CurrentPackage.ProjectCode = 'ROBOTINICS', 'Transicao autonoma efetuada para ROBOTINICS');
    Assert(ProfAgent.CurrentResource <> nil, 'Recurso visual do Robotinics exibido na tela');

    WriteLn('[8] Marcelo se afasta e retorna mais tarde...');
    Narrative := ProfAgent.StartPresentation('15', 'Marcelo', 'HEMACIAS');
    WriteLn('  [Professor - Retorno]: ' + Narrative);
    Assert(Pos('novamente', Narrative) > 0, 'Reconheceu que Marcelo ja visitou');

    WriteLn('======================================================================');
    WriteLn('[SUCESSO] TODOS OS TESTES DO PROFESSOR VIRTUAL PASSARAM 100%!');
    WriteLn('======================================================================');
  finally
    ProfAgent.Free;
    ResMgr.Free;
  end;
end.
