# TNeuralNetwork

## Finalidade

`TNeuralNetwork` implementa uma rede neural simples em Pascal para estudos, classificação didática e pequenos experimentos locais.

## Unit

```pascal
pacote/IA/neuralnetwork.pas
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
| `InputCount` | Quantidade de entradas |
| `HiddenCount` | Quantidade de neurônios ocultos |
| `OutputCount` | Quantidade de saídas |
| `LearningRate` | Taxa de aprendizado |
| `Epochs` | Número de épocas de treinamento |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `InitializeNetwork` | Inicializa pesos e estrutura |
| `Train` | Executa treinamento |
| `Predict` | Calcula saída para uma entrada |
| `SaveToFile` | Salva modelo |
| `LoadFromFile` | Carrega modelo |

## Exemplo

```pascal
NeuralNetwork1.InputCount := 2;
NeuralNetwork1.HiddenCount := 4;
NeuralNetwork1.OutputCount := 1;
NeuralNetwork1.LearningRate := 0.1;
NeuralNetwork1.InitializeNetwork;
```

## Limitações

* Não substitui TensorFlow, PyTorch ou scikit-learn.
* Indicado para aprendizado, protótipos e redes pequenas.
