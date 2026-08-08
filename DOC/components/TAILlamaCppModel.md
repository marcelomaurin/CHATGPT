# TAILlamaCppModel

`TAILlamaCppModel` valida e carrega um modelo GGUF pelo bridge nativo x64.
O componente fica na aba **AI LlamaCpp** da paleta do Lazarus.

## Propriedades

- `Runtime`: instancia de `TAILlamaCppRuntime`.
- `ModelFile`: caminho do modelo `.gguf`.
- `ContextSize`: tamanho do contexto; padrao `2048`.
- `Threads`: numero de threads; `0` usa a escolha automatica do llama.cpp.
- `BatchSize`: configuracao reservada para evolucao da carga em lotes.
- `Valid`: indica que nome, existencia e extensao foram validados.
- `Loaded`: indica que o modelo esta carregado pelo bridge.

## Ciclo de vida

Chame `Load` antes da inferencia nativa e `Unload` ao terminar. O destrutor
tambem descarrega o modelo. A referencia a `Runtime` usa notificacao de
componentes e e removida com seguranca se o runtime for destruido.

```pascal
LlamaModel.Runtime := LlamaRuntime;
LlamaModel.ModelFile := 'C:\modelos\modelo.gguf';
if not LlamaModel.Load then
  raise Exception.Create(LlamaModel.LastError);
try
  // use TAILlamaCppInference
finally
  LlamaModel.Unload;
end;
```

`GenerateNative`, `GenerateStreamNative`, `ApplyLoRA` e `RemoveLoRA` sao a
camada de baixo nivel usada pelos demais componentes.
