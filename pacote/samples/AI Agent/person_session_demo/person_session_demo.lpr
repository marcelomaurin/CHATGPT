program person_session_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils, aipersonsession;
var Manager: TAIPersonSessionManager; Speakers: TAIActiveSpeakerManager; Ana, Bruno: TAIPersonSession;
begin
  Manager := TAIPersonSessionManager.Create(nil);
  Speakers := TAIActiveSpeakerManager.Create(nil);
  try
    Ana := Manager.ActivatePerson('demo-ana', 'Ana');
    Ana.AddMessage('user', 'Quero conhecer o projeto Hemacias.');
    Ana.AddMemory('Interesse', 'Visão computacional'); Ana.CurrentProject := 'Hemacias';
    Bruno := Manager.ActivatePerson('demo-bruno', 'Bruno');
    Bruno.AddMessage('user', 'Como funciona o ECG?'); Bruno.CurrentProject := 'ECG';
    if Bruno.MemoryCount <> 0 then raise Exception.Create('Memórias de pessoas foram misturadas.');
    Speakers.SessionManager := Manager;
    Speakers.AddPersonPresent('demo-ana', 'Ana');
    Speakers.AddPersonPresent('demo-bruno', 'Bruno');
    Speakers.SetActiveSpeaker('demo-ana');
    if Manager.ActiveSession <> Ana then raise Exception.Create('Sessão da interlocutora não foi retomada.');
    WriteLn(Manager.BuildEnrichedPersonPrompt('Pode continuar?'));
    WriteLn('Histórico de Ana: ', Ana.GetRecentMessagesFormatted);
    WriteLn('Histórico de Bruno: ', Bruno.GetRecentMessagesFormatted);
    WriteLn('PASS: interlocutor e memórias separados por pessoa.');
  finally Speakers.Free; Manager.Free; end;
end.
