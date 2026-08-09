program agent_rag_demo;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, chatgpt, aiagent, airag, aigraphmap;

function ProviderFromEnvironment: TAIProvider;
var
  Name: string;
begin
  Name := LowerCase(Trim(GetEnvironmentVariable('AI_PROVIDER')));
  if Name = 'gemini' then Exit(AIP_GEMINI);
  if Name = 'claude' then Exit(AIP_CLAUDE);
  if Name = 'deepseek' then Exit(AIP_DEEPSEEK);
  if Name = 'openrouter' then Exit(AIP_OPENROUTER);
  if Name = 'local' then Exit(AIP_LOCAL);
  Result := AIP_OPENAI;
end;

procedure ConfigureChat(Chat: TCHATGPT);
var
  Value: string;
begin
  Chat.Provider := ProviderFromEnvironment;
  Chat.TOKEN := GetEnvironmentVariable('AI_API_KEY');
  Value := Trim(GetEnvironmentVariable('AI_MODEL'));
  if Value <> '' then
  begin
    Chat.TipoChat := VCT_CUSTOM;
    Chat.CustomModel := Value;
  end;
  Value := Trim(GetEnvironmentVariable('AI_ENDPOINT'));
  if Value <> '' then
    Chat.URL := Value;
end;

procedure PrintSources(Sources: TStrings);
var
  I: Integer;
begin
  if Sources.Count = 0 then
    WriteLn('  (nenhuma)')
  else
    for I := 0 to Sources.Count - 1 do
      WriteLn('  - ', Sources[I]);
end;

var
  Owner: TComponent;
  Chat: TCHATGPT;
  Graph: TAIGraphMap;
  RAG: TAIRAG;
  Agent: TAIAgent;
  Question: string;
begin
  Owner := TComponent.Create(nil);
  try
    Chat := TCHATGPT.Create(Owner);
    Graph := TAIGraphMap.Create(Owner);
    RAG := TAIRAG.Create(Owner);
    Agent := TAIAgent.Create(Owner);

    ConfigureChat(Chat);
    RAG.ChatGPT := Chat;
    RAG.GraphMap := Graph;
    Agent.ChatGPT := Chat;
    Agent.RAG := RAG;
    Agent.SystemPrompt :=
      'Use o contexto RAG e retorne um objeto JSON valido para a decisao.';

    RAG.AddText('projeto',
      'CHATGPT e uma suite de componentes para Lazarus e Free Pascal. ' +
      'TAIRAG usa TAIGraphMap para recuperar contexto e fontes.');
    if not RAG.BuildIndex then
      raise Exception.Create('Falha ao indexar: ' + RAG.LastError);

    if ParamCount > 0 then
      Question := ParamStr(1)
    else
      Question := 'Como o RAG recupera contexto neste projeto?';

    WriteLn('Pergunta: ', Question);
    if Agent.Execute(Question) then
    begin
      WriteLn('Contexto recuperado:');
      WriteLn(Agent.LastRAGContext);
      WriteLn('Fontes:');
      PrintSources(Agent.LastRAGSources);
      WriteLn('Resposta/decisao:');
      WriteLn(Agent.LastDecision.RawJSON);
    end
    else
    begin
      WriteLn('ERRO Agent/RAG/provider: ', Agent.LastError);
      WriteLn('Contexto parcial: ', Agent.LastRAGContext);
      WriteLn('Fontes parciais:');
      PrintSources(Agent.LastRAGSources);
      ExitCode := 1;
    end;
  finally
    Owner.Free;
  end;
end.
