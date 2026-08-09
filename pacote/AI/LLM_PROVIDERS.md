# Arquitetura de LLM e providers

## Auditoria B01/C01

Antes desta revisão, toda a seleção de endpoint, headers, payload, parser e
transporte estava concentrada em `chatgpt.pas`. OpenAI, OpenRouter, Cerebras,
Ollama/local, Gemini, Claude e DeepSeek já eram aceitos, mas não existiam um
contrato genérico, factory, streaming, execução assíncrona ou cancelamento real.
`Cancel` era um método vazio. `TAIModelRegistry` existia parcialmente e mantinha
uma segunda lista de modelos.

Depois da revisão:

- `aillmproviders.pas` contém o único contrato `IAILLMProvider`, a base comum,
  providers concretos e `TAILLMProviderFactory`;
- `aillmmodelcatalog.pas` é a fonte de verdade dos metadados de modelos; o
  registry e as listas públicas de `TCHATGPT` consultam esse catálogo;
- `TCHATGPT` preserva as propriedades e `SendQuestion`, mas delega endpoint,
  headers, payload, parser e HTTP ao provider resolvido;
- `SendQuestionAsync`, streaming SSE OpenAI-compatible, estados e cancelamento
  real foram adicionados.

## Contrato e extensão

`IAILLMProvider` expõe identificação, endpoint padrão, montagem de request e
headers, parsing, envio, erro bruto e `Cancel`. Configurações comuns ficam em
`TAILLMProviderConfig`: endpoint, token, modelo, timeout, `MaxTokens`,
`Temperature`, prompt de sistema, prompt do usuário e streaming.

Para adicionar um provider, herde de `TAILLMProviderBase` ou
`TAILLMOpenAICompatibleProvider`, sobrescreva apenas o que divergir e registre a
classe em `TAILLMProviderFactory.CreateProvider`. Não coloque regras de provider
em formulários.

| Provider | Classe | Streaming | Temperature |
|---|---|---:|---:|
| OpenAI | `TAILLMOpenAIProvider` | SSE | sim |
| OpenAI-compatible | `TAILLMOpenAICompatibleProvider` | SSE | sim |
| llama.cpp | `TAILLMLlamaCppProvider` | SSE | sim |
| neural-api | `TAILLMNeuralAPIProvider` | SSE | sim |
| Ollama | `TAILLMOllamaProvider` | SSE | sim |
| OpenRouter | `TAILLMOpenRouterProvider` | SSE | sim |
| Cerebras | `TAILLMCerebrasProvider` | SSE | sim |
| DeepSeek | `TAILLMDeepSeekProvider` | SSE | sim |
| Gemini | `TAILLMGeminiProvider` | não neste transporte | sim |
| Claude | `TAILLMClaudeProvider` | não neste transporte | sim |

`Temperature` é limitada por `TCHATGPT` à faixa 0..2, usa 0,7 como padrão e é
incluída nos payloads compatíveis. `CustomModel`, quando preenchido, prevalece
sobre os enums antigos. Os enums continuam disponíveis para projetos legados.

## Uso com TCHATGPT

O fluxo síncrono existente continua válido:

```pascal
Chat.Provider := AIP_OPENAI_COMPATIBLE;
Chat.URL := 'http://localhost:8000/v1/chat/completions';
Chat.CustomModel := 'meu-modelo';
Chat.Temperature := 0.4;
Chat.SendQuestion('Olá');
```

Para não bloquear a UI:

```pascal
Chat.Streaming := True;
Chat.OnStreamData := @ReceberTrecho;
Chat.OnRequestComplete := @Concluir;
Chat.SendQuestionAsync('Olá');
```

As transições são `Idle -> Connecting -> Receiving -> Completed`, com saídas
alternativas `Cancelled` e `Error`. `Receiving` ocorre quando chega o primeiro
trecho. `Cancel` chama `TFPHttpClient.Terminate`, encerra depois do chunk atual e
permite outra requisição no mesmo componente.

Nos métodos assíncronos, `OnStreamStart`, `OnStreamData`, `OnStreamEnd`,
`OnStateChange`, `OnRequestError` e `OnRequestComplete` são entregues na thread
principal. No método síncrono, os eventos rodam na thread que fez a chamada.
Não destrua controles a partir de callbacks síncronos executados por uma worker
criada pelo próprio aplicativo.

Veja `samples/AI/llm_provider_demo`, `samples/AI/async_chat_demo` e o teste
`tests/llm_provider_streaming_test`.
