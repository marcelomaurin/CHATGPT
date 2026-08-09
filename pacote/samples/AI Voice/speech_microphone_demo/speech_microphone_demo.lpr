program speech_microphone_demo;
{$mode objfpc}{$H+}
uses Interfaces, Forms, main;
begin RequireDerivedFormResource:=False; Application.Initialize;
  Application.CreateForm(TSpeechMicForm,SpeechMicForm); Application.Run; end.
