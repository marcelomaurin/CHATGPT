program speech_file_demo;
{$mode objfpc}{$H+}
uses Interfaces, Forms, main;
begin RequireDerivedFormResource := False; Application.Initialize;
  Application.CreateForm(TSpeechFileForm, SpeechFileForm); Application.Run; end.
