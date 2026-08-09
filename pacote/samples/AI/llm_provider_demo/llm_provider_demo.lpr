program llm_provider_demo;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aillmproviders, aillmmodelcatalog;

const
  Kinds: array[0..9] of TAILLMProviderKind = (
    llmOpenAI, llmOpenAICompatible, llmLlamaCpp, llmNeuralAPI,
    llmGemini, llmClaude, llmDeepSeek, llmOpenRouter, llmCerebras,
    llmOllama
  );

var
  I: Integer;
  Provider: IAILLMProvider;
  Config: TAILLMProviderConfig;
  Models: TStringList;
begin
  InitAILLMProviderConfig(Config);
  Config.Model := 'custom-model';
  Config.SystemPrompt := 'Responda de forma objetiva.';
  Config.UserPrompt := 'Explique o contrato IAILLMProvider.';
  Config.Temperature := 0.4;

  Writeln('Providers disponiveis pela factory:');
  for I := Low(Kinds) to High(Kinds) do
  begin
    Provider := TAILLMProviderFactory.CreateProvider(Kinds[I]);
    Writeln('  ', Provider.GetProviderID:18, '  ', Provider.GetDefaultEndpoint);
  end;

  Provider := TAILLMProviderFactory.CreateProvider(llmOpenAICompatible);
  Writeln;
  Writeln('Payload OpenAI-compatible:');
  Writeln(Provider.BuildRequest(Config));

  Models := TStringList.Create;
  try
    GetAILLMModelsForProvider('OpenAI', Models);
    Writeln;
    Writeln('Catalogo OpenAI: ', Models.CommaText);
  finally
    Models.Free;
  end;
end.
