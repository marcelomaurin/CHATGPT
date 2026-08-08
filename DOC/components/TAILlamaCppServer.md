# TAILlamaCppServer

`TAILlamaCppServer` inicia e monitora `llama-server.exe` para um modelo GGUF.
O componente fica na aba **AI LlamaCpp** da paleta do Lazarus.

## Configuracao

- `Runtime`: runtime que fornece o executavel e as DLLs.
- `Model`: modelo com arquivo, contexto e threads configurados.
- `Host`: padrao `127.0.0.1`.
- `Port`: padrao `8080`.
- `BaseURL`: URL calculada, por exemplo `http://127.0.0.1:8080`.
- `StartupTimeout`: limite para o health check inicial, em milissegundos.
- `Running`: indica se o processo iniciado pelo componente esta ativo.

## Operacao

`BuildParameters` permite inspecionar os argumentos sem iniciar o processo.
`Start` valida o runtime e o modelo, inicia o servidor e somente dispara
`OnServerStarted` depois que `/health` responder. `Stop` encerra apenas o
processo criado pela propria instancia e dispara `OnServerStopped`.

Saida normal vai para `OnLog`; erros do processo e timeout tambem disparam
`OnError`. `ConfigureChatGPT` configura um `TCHATGPT` para o endpoint local
`/v1/chat/completions`.

```pascal
if not LlamaServer.Start then
  ShowMessage(LlamaServer.LastError);
```
