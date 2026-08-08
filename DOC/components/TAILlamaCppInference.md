# TAILlamaCppInference

`TAILlamaCppInference` executa inferencia direta no modelo GGUF pelo bridge
nativo e oferece geracao sincrona ou streaming assincrono.

## Propriedades

- `Model`: instancia de `TAILlamaCppModel`.
- `AccessMode`: use `llamNative` para a implementacao direta atual.
- `Prompt`: texto enviado ao modelo.
- `MaxTokens`: limite de tokens gerados; padrao `128`.
- `Temperature`, `TopK`, `TopP` e `Seed`: parametros de amostragem.
- `LastResult`: texto completo da ultima geracao concluida.
- `GenerationRunning`: indica uma geracao assincrona ativa.

## Geracao sincrona

```pascal
LlamaInference.AccessMode := llamNative;
if LlamaInference.Generate('Responda somente: OK') then
  Memo1.Text := LlamaInference.LastResult
else
  Memo1.Text := LlamaInference.LastError;
```

## Streaming

Use `GenerateAsync` e trate `OnStart`, `OnToken`, `OnFinish` e `OnError`.
Os tokens sao entregues na thread principal por fila do Lazarus. `Cancel`
sinaliza a thread e solicita aborto no bridge nativo.

O modo `llamServer` serve para configuracoes baseadas no servidor HTTP; a
geracao implementada por este componente exige `llamNative`.
