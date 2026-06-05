# TAIGraphMap

## Finalidade

`TAIGraphMap` é um componente para classificação simples baseada em grafo de tokens.

Ele pode ser usado em aplicações Lazarus quando o programador precisa de uma classificação local, explicável e leve.

## Unit

```pascal
pacote/IA Graph/aigraphmap.pas
```

## Pacote

```text
openai_graph.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Descrição do componente |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `AddTrainingText` | Adiciona texto de treinamento associado a uma classe |
| `Train` | Processa os dados de treinamento |
| `Predict` | Classifica uma nova entrada |
| `PredictRanking` | Retorna ranking de classes |
| `ExplainPrediction` | Explica a decisão |
| `ExportDOT` | Exporta o grafo em formato DOT |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIGraphMap1.AddTrainingText('texto sobre vendas', 'vendas');
  AIGraphMap1.AddTrainingText('texto sobre atendimento', 'atendimento');
  AIGraphMap1.Train;

  ShowMessage(AIGraphMap1.Predict('preciso falar com atendimento'));
end;
```

## Limitações

* Não substitui modelos modernos de NLP.
* É indicado para classificação local simples.
* Precisa de dados de treinamento representativos.
