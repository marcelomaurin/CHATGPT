# 📊 Documentação da Aba AI Graph

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Graph**.

## Classificação de Texto por Mapas de Grafos Ponderados.
Componente de classificação explicável de textos curtos e chamados baseado em mapas de grafos de tokens locais.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIGraphMap** | Classificador textual por grafo ponderado. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classificar textos curtos localmente sem dependências de rede. |

### 💻 Exemplo de Código Lazarus (TAIGraphMap)

```pascal
var
  MyComponent: TAIGraphMap;
begin
  MyComponent := TAIGraphMap.Create(Self);
  try
    // Configuration properties
    // MyComponent.Property := Value;
    
    // Execute call
    // MyComponent.ExecuteMethod;
  finally
    MyComponent.Free;
  end;
end;
```


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
