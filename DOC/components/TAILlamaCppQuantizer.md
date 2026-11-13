# TAILlamaCppQuantizer

`TAILlamaCppQuantizer` executa a ferramenta oficial `llama-quantize.exe` do
llama.cpp b5200 em um processo separado.

## Propriedades

- `Runtime`: runtime que contem o quantizador e suas DLLs.
- `SourceFile`: modelo GGUF de origem.
- `DestinationFile`: arquivo GGUF a ser criado.
- `QuantizationType`: tipo aceito pelo executavel b5200; o padrao e
  `lqtQ4_K_M`.
- `LastResult`: stdout e stderr capturados.
- `LastError`: erro de validacao, inicializacao ou retorno do processo.
- `OnLog`: recebe as linhas produzidas pela ferramenta.

## Uso

```pascal
LlamaQuantizer.Runtime := LlamaRuntime;
LlamaQuantizer.SourceFile := 'C:\modelos\modelo-f16.gguf';
LlamaQuantizer.DestinationFile := 'C:\modelos\modelo-q4_k_m.gguf';
LlamaQuantizer.QuantizationType := lqtQ4_K_M;
if not LlamaQuantizer.Execute then
  ShowMessage(LlamaQuantizer.LastError);
```

`BuildParameters` retorna, nesta ordem, origem, destino e nome oficial do tipo.
O componente valida existencia/extensao da origem e extensao do destino.

Requantizar um modelo ja quantizado pode reduzir significativamente a
qualidade. Prefira como origem um modelo F16, BF16 ou F32 adequado.
