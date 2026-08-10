program unified_llm_router_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, aillmproviders, aicapabilities, aimodelrouter,
  aiunifiedllm;

var
  Router: TAIModelRouter;
  LLM: TAIUnifiedLLM;
  Answer: string;
begin
  Router := TAIModelRouter.Create(nil);
  LLM := TAIUnifiedLLM.Create(nil);
  try
    Router.PreferLocal := True;

    { Primeira opcao: llama.cpp local. }
    Router.AddRoute(
      llmLlamaCpp,
      'local-model',
      'http://127.0.0.1:8080',
      '',
      10
    );

    { Fallback: OpenAI compativel. Preencha endpoint/token se desejar. }
    Router.AddRoute(
      llmOpenAICompatible,
      'fallback-model',
      '',
      '',
      100
    );

    LLM.Router := Router;
    LLM.AutoRoute := True;
    LLM.PreferLocal := True;
    LLM.RequiredCapabilities := [aicChat];
    LLM.SystemPrompt := 'Responda de forma curta.';
    LLM.MaxTokens := 128;

    WriteLn('Rota selecionada: ', Router.Select([aicChat]).Model);
    WriteLn('Provider: ', AILLMProviderKindName(Router.Select([aicChat]).ProviderKind));

    if ParamCount = 0 then
    begin
      WriteLn('Uso: unified_llm_router_demo "sua pergunta"');
      Halt(0);
    end;

    Answer := LLM.AskText(ParamStr(1));
    if LLM.LastSuccess then
      WriteLn(Answer)
    else
    begin
      WriteLn(StdErr, 'Erro: ', LLM.LastError);
      Halt(1);
    end;
  finally
    LLM.Free;
    Router.Free;
  end;
end.
