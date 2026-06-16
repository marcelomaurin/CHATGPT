# TAIPipeline

## Finalidade

`TAIPipeline` orquestra etapas de processamento entre entrada, modelo, agente, grafo e saída.

Use quando precisar montar um fluxo como: entrada → processamento → modelo/IA → saída.

## Unit

```pascal
pacote/AI/aipipeline.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Mode` | Modo do pipeline |
| `ChatGPT` | Componente LLM associado |
| `NeuralNetwork` | Rede neural associada |
| `Agent` | Agente associado |
| `InputData` | Entrada estruturada |
| `OutputData` | Saída estruturada |
| `OutputDocs` | Gerador de documentos |
| `GraphMap` | Classificador por grafo |
| `InputText` | Texto de entrada |
| `OutputText` | Texto de saída |

## Métodos principais

| Método | Descrição |
|---|---|
| `Run` | Executa conforme `Mode` |
| `RunText` | Executa fluxo textual com LLM |
| `RunNumeric` | Executa fluxo numérico/ML |
| `RunAgent` | Executa agente |
| `RunDocument` | Gera documento |
| `RunIndustrialMonitor` | Fluxo industrial |
| `RunGraphMapClassification` | Classificação por grafo |

## Exemplo

```pascal
AIPipeline1.Mode := pmTextLLM;
AIPipeline1.ChatGPT := ChatGPT1;
AIPipeline1.InputText := 'Resuma este chamado técnico.';

if AIPipeline1.Run then
  Memo1.Lines.Text := AIPipeline1.OutputText
else
  ShowMessage(AIPipeline1.LastError);
```

## Limitações

* Atualmente possui acoplamento com várias áreas.
* Recomenda-se validar dependências antes de instalar em pacote mínimo.
* Futuramente pode ser movido para `openai_pipeline.lpk`.
