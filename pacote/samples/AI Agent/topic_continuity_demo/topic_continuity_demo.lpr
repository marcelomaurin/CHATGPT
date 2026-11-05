program topic_continuity_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils, TypInfo, aitopiccontinuity;
var Classifier: TAITopicContinuityClassifier; Decision: TAIContinuityDecision; Prompt: string;
procedure Say(const Text: string);
begin
  if not Classifier.ProcessUtterance(Text, Decision, Prompt) then
    raise Exception.Create('Não foi possível classificar a fala.');
  WriteLn('Usuário: ', Text);
  WriteLn('Decisão: ', GetEnumName(TypeInfo(TAIContinuityDecision), Ord(Decision)));
  WriteLn('Motivo: ', Classifier.LastReason);
  WriteLn(Prompt); WriteLn;
end;
begin
  Classifier := TAITopicContinuityClassifier.Create(nil);
  try
    Classifier.RegisterKnownEntity('Prefeitura', 'empresa');
    Classifier.RegisterKnownEntity('Hemacias', 'projeto');
    Say('Preciso emitir o boleto 12345 da Prefeitura');
    Classifier.RecordAIResponse('Vamos conferir os dados do boleto.');
    Say('Na verdade o numero correto do boleto e 98765');
    Say('Mudando de assunto, quero saber sobre o projeto Hemacias');
    Say('Voltando ao boleto da Prefeitura');
    WriteLn(Classifier.FormatStackSummary);
    if Classifier.ActiveTopic = nil then raise Exception.Create('Tópico ativo ausente.');
    WriteLn('PASS: contexto construído sem chamadas a LLM.');
  finally Classifier.Free; end;
end.
