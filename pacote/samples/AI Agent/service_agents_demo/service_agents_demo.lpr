program service_agents_demo;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiserviceagents;

var
  GitHub: TAIGitHubAgent;
  Facebook: TAIFacebookAgent;
  YouTube: TAIYouTubeAgent;
begin
  GitHub := TAIGitHubAgent.Create(nil);
  Facebook := TAIFacebookAgent.Create(nil);
  YouTube := TAIYouTubeAgent.Create(nil);
  try
    { GitHub }
    GitHub.Owner := 'marcelomaurin';
    GitHub.Repository := 'CHATGPT';
    GitHub.AccessToken := ''; // opcional para leitura publica; necessario para escrita/privado
    GitHub.AllowWrite := False;

    { Facebook Page / Graph API }
    Facebook.PageID := '';
    Facebook.APIVersion := ''; // configure uma versao Graph API suportada pelo seu app
    Facebook.AccessToken := ''; // Page Access Token
    Facebook.AllowWrite := False;

    { YouTube Data API v3 }
    YouTube.ChannelID := '';
    YouTube.APIKey := '';       // leitura publica
    YouTube.AccessToken := '';  // OAuth 2.0 para dados privados/escrita
    YouTube.AllowWrite := False;

    WriteLn('CHATGPT Lazarus service agents');
    WriteLn('  GitHubAgent  : ready');
    WriteLn('  FacebookAgent: ready');
    WriteLn('  YouTubeAgent : ready');
    WriteLn;
    WriteLn('Operacoes de escrita estao bloqueadas por padrao (AllowWrite=False).');
    WriteLn('Configure tokens/IDs antes de chamar as APIs reais.');
  finally
    YouTube.Free;
    Facebook.Free;
    GitHub.Free;
  end;
end.
