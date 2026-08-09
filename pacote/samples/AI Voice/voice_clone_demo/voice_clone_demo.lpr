program voice_clone_demo;
{$mode objfpc}{$H+}
uses Interfaces,Forms,main;
begin RequireDerivedFormResource:=False;Application.Initialize;
  Application.CreateForm(TVoiceCloneForm,VoiceCloneForm);Application.Run;end.
