program common_service_agents_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, aicommonserviceagents;

var
  GitLab: TAIGitLabAgent;
  Telegram: TAITelegramAgent;
  Email: TAIEmailAgent;
  RSS: TAIRSSAgent;
  Web: TAIWebAgent;
  SSH: TAISSHAgent;
  Database: TAIDatabaseAgent;
  WhatsApp: TAIWhatsAppAgent;
begin
  GitLab := TAIGitLabAgent.Create(nil);
  Telegram := TAITelegramAgent.Create(nil);
  Email := TAIEmailAgent.Create(nil);
  RSS := TAIRSSAgent.Create(nil);
  Web := TAIWebAgent.Create(nil);
  SSH := TAISSHAgent.Create(nil);
  Database := TAIDatabaseAgent.Create(nil);
  WhatsApp := TAIWhatsAppAgent.Create(nil);
  try
    GitLab.ProjectID := 'group/project';
    Telegram.ChatID := 'CHAT_ID';
    RSS.FeedURL := 'https://example.com/feed.xml';
    SSH.Host := 'server.example.com';
    WhatsApp.PhoneNumberID := 'PHONE_NUMBER_ID';

    { Escrita e execucao ficam bloqueadas por padrao. }
    GitLab.AllowWrite := False;
    Telegram.AllowWrite := False;
    Email.AllowWrite := False;
    Web.AllowWrite := False;
    SSH.AllowWrite := False;
    Database.AllowWrite := False;
    WhatsApp.AllowWrite := False;

    WriteLn('CHATGPT Lazarus common service agents');
    WriteLn(' GitLab   : ready');
    WriteLn(' Telegram : ready');
    WriteLn(' Email    : ready (reuses TAIEmailClient)');
    WriteLn(' RSS/Atom : ready');
    WriteLn(' Web      : ready');
    WriteLn(' SSH      : ready');
    WriteLn(' Database : ready (TSQLConnection)');
    WriteLn(' WhatsApp : ready (Cloud API)');
    WriteLn('All write actions are disabled by default.');
  finally
    WhatsApp.Free;
    Database.Free;
    SSH.Free;
    Web.Free;
    RSS.Free;
    Email.Free;
    Telegram.Free;
    GitLab.Free;
  end;
end.
