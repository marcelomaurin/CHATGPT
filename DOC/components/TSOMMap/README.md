# TSOMMap

## Finalidade

`TSOMMap` representa um mapa auto-organizável (Self-Organizing Map) para agrupamento e visualização simples de padrões.

## Unit

```pascal
pacote/IA/sommap.pas
```

## Pacote

```text
openai_ml.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Width` / `Height` | Dimensões do mapa |
| `InputCount` | Quantidade de entradas |
| `LearningRate` | Taxa de aprendizado |
| `Epochs` | Número de épocas |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Train` | Treina o mapa |
| `FindBestMatchingUnit` | Localiza neurônio mais próximo |
| `Reset` | Reinicia o mapa, se disponível |

## Exemplo

```pascal
SOMMap1.Width := 10;
SOMMap1.Height := 10;
SOMMap1.InputCount := 3;
SOMMap1.LearningRate := 0.05;
SOMMap1.Epochs := 500;
SOMMap1.Train;
```

## Limitações

* API em evolução.
* Validar com datasets pequenos antes de uso real.
