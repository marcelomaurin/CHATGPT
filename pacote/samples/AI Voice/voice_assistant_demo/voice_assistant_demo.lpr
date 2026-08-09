program voice_assistant_demo;
{$mode objfpc}{$H+}
uses Interfaces,Forms,main;
begin RequireDerivedFormResource:=False;Application.Initialize;
 Application.CreateForm(TVoiceAssistantForm,VoiceAssistantForm);Application.Run;end.
