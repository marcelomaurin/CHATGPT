# TPerceptron

## Finalidade

`TPerceptron` implementa um perceptron simples em Pascal.

Use para estudos de classificação linear, exemplos didáticos e demonstrações de machine learning básico.

## Unit

```pascal
pacote/AI/perceptron.pas
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
| `InputCount` | Número de entradas |
| `LearningRate` | Taxa de aprendizado |
| `Epochs` | Número de épocas |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Train` | Treina o perceptron |
| `Predict` | Retorna a classe prevista |
| `Reset` | Reinicia pesos/estado, se disponível |

## Exemplo

```pascal
Perceptron1.InputCount := 2;
Perceptron1.LearningRate := 0.1;
Perceptron1.Epochs := 100;
// preencher dados de treino conforme API do componente
Perceptron1.Train;
```

## Limitações

* Resolve apenas problemas linearmente separáveis.
* Para problemas não lineares, usar `TNeuralNetwork` ou outro modelo.
