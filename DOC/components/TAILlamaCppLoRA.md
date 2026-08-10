# TAILlamaCppLoRA

`TAILlamaCppLoRA` aplica e remove um adapter LoRA GGUF no modelo nativo
carregado. O componente fica na aba **AI LlamaCpp**.

## Propriedades

- `Model`: modelo base usado pelo adapter.
- `AdapterFile`: arquivo LoRA com extensao `.gguf`.
- `Scale`: escala aplicada ao adapter; padrao `1.0` e nao pode ser negativa.
- `Applied`: indica que o adapter foi aplicado por esta instancia.

## Uso

```pascal
LlamaLoRA.Model := LlamaModel;
LlamaLoRA.AdapterFile := 'C:\modelos\adapter-lora.gguf';
LlamaLoRA.Scale := 1.0;
if not LlamaLoRA.Apply then
  raise Exception.Create(LlamaLoRA.LastError);
try
  LlamaInference.Generate('Seu prompt');
finally
  LlamaLoRA.Remove;
end;
```

`Apply` carrega o modelo automaticamente se necessario. O adapter precisa ser
compativel com a arquitetura e os tensores do modelo base. A compilacao do
recurso foi validada; a validacao funcional depende de um par real e
compativel de modelo e adapter.
