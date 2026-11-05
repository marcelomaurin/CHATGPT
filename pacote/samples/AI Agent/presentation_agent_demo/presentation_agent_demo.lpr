program presentation_agent_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils, aipresentation;
var Resources: TAIPresentationResourceManager; Agent: TAIPresentationAgent;
    Package: TPresentationPackage; Narrative: string;
begin
  Resources := TAIPresentationResourceManager.Create(nil);
  Agent := TAIPresentationAgent.Create(nil);
  try
    Package := Resources.AddPackage('demo', 'Projeto de exemplo',
      'Apresentação local de uma solução educacional.', 'Explicar o fluxo de trabalho.',
      'Entrada, processamento e saída.', 'Protótipo demonstrativo.', 'Validar com usuários.');
    Package.AddConcept('intro', 'Visão geral', 'Objetivo e público da solução.', 0, prtSlide);
    Package.AddConcept('flow', 'Fluxo de trabalho', 'Etapas de entrada e processamento.', 1, prtDiagram);
    Package.AddResource('slide-intro', 'Visão geral', 'Recurso didático textual.', prtSlide,
      '', 'visao,geral,objetivo');
    Agent.ResourceManager := Resources;
    Narrative := Agent.StartPresentation('demo-ana', 'Ana', 'demo');
    if Narrative = '' then raise Exception.Create('Narrativa inicial vazia.');
    WriteLn(Narrative);
    Agent.PausePresentation;
    WriteLn('Pergunta: ', Agent.AnswerQuestion('Qual o objetivo do projeto?'));
    WriteLn('Retomada: ', Agent.ResumePresentation);
    WriteLn('Próximo conceito: ', Agent.ContinuePresentation);
    WriteLn(Agent.GetStatusSummary);
    WriteLn('PASS: roteiro e retomada demonstrados em texto.');
  finally Agent.Free; Resources.Free; end;
end.
