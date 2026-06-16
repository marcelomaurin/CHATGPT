# TAIDatasetGenerator

## Finalidade

`TAIDatasetGenerator` auxilia na criação e organização de datasets para treinamento, classificação local ou exportação.

## Unit

```pascal
pacote/AI/aidatasetgenerator.pas
```

## Pacote

```text
openai_ml.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Orientação do componente |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `AddItem` | Adiciona item ao dataset, conforme API disponível |
| `Clear` | Limpa dataset |
| `SaveToFile` | Salva dataset em arquivo |
| `LoadFromFile` | Carrega dataset |

## Exemplo

```pascal
DatasetGenerator1.Clear;
// DatasetGenerator1.AddItem('texto de entrada', 'classe');
DatasetGenerator1.SaveToFile('dataset.json');
```

## Limitações

* Verificar formatos suportados diretamente na unit.
* Para exportações específicas, avaliar `TAITrainingExporter`.
