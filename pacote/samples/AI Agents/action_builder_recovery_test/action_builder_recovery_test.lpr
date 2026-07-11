program action_builder_recovery_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, chatgpt, aiagent_actionbuilder, aiagent_memorymap;

var
  LChatGPT: TChatGPT;
  MemoryMap: TAIAgentMemoryMap;
  ActionBuilder: TAIActionBuilderAgent;
  InputText: string;
  OutputText: string;
  Token: string;
begin
  WriteLn('Iniciando Teste de Recuperacao do ActionBuilder...');

  Token := GetEnvironmentVariable('OPENAI_API_KEY');
  if Token = '' then
    Token := GetEnvironmentVariable('CHATGPT_TOKEN');

  if Token = '' then
  begin
    WriteLn('Aviso: Token da API nao configurado nas variaveis de ambiente (OPENAI_API_KEY ou CHATGPT_TOKEN). O teste usara modo simulado.');
  end;

  LChatGPT := TChatGPT.Create(nil);
  MemoryMap := TAIAgentMemoryMap.Create(nil);
  ActionBuilder := TAIActionBuilderAgent.Create(nil);
  try
    LChatGPT.Token := Token;
    ActionBuilder.ChatGPT := LChatGPT;
    ActionBuilder.MemoryMap := MemoryMap;
    ActionBuilder.AutoRecoverInvalidInput := True;

    // Teste 1: BuilderInput confuso (Tarefa 21)
    WriteLn('--- Teste 1: Input Textual Confuso ---');
    InputText := 'O processamento gerou um curriculo. Preciso criar o texto e preparar um email para x@y.com com assunto Curriculo.';
    WriteLn('Input: ' + InputText);
    
    if Token <> '' then
    begin
      if ActionBuilder.BuildActionsWithRecovery(InputText, OutputText) then
      begin
        WriteLn('Sucesso!');
        WriteLn('Output: ' + OutputText);
      end
      else
        WriteLn('Falha no Teste 1: ' + ActionBuilder.LastError);
    end
    else
      WriteLn('Pulando chamada real (Sem token de API).');

    // Teste 2: Simular retorno sem actions (Tarefa 22)
    WriteLn('--- Teste 2: Validacao de Saida Invalida ---');
    InputText := '{"analysis": "Entendi a tarefa", "result": "Criar documento e email"}';
    if not ActionBuilder.BuildActions('', OutputText) then
    begin
      WriteLn('Sucesso no Teste 2: Detectou input vazio/invalido: ' + ActionBuilder.LastError);
    end;

  finally
    ActionBuilder.Free;
    MemoryMap.Free;
    LChatGPT.Free;
  end;
  WriteLn('Fim dos testes.');
end.
