# Aba AI Graph

> Esta pasta contem os componentes Lazarus da aba **AI Graph**.

## Classificacao de texto e grafos estruturais

### Referencia detalhada dos componentes

| Componente | Descricao | Propriedades Importantes | Metodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIGraphMap** | Classificador textual por grafo ponderado. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classificar textos curtos localmente sem dependencias de rede. |
| **TAIDependencyGraph** | Grafo factual com evidencia obrigatoria e arestas inferidas separadas. | `NodeCount, EdgeCount, Validated, LastError` | `AddNode, AddEdge, AddInferredEdge, FindNode, Clear, Validate, CountNodesOfType, CountEdgesOfType, SaveToJSON, LoadFromJSON, SaveToDOT, SaveToMermaid` | Registrar fatos estruturais do repositorio sem misturar hipotese e evidencia. |
| **TAIGraphStructuralAdapter** | Projecao estrutural para o visualizer atual. | `DependencyGraph, GraphMap` | `Refresh, AttachToVisualizer` | Reutilizar o visualizador sem quebrar os samples existentes. |

### Exemplo de codigo Lazarus

```pascal
var
  Graph: TAIDependencyGraph;
  Adapter: TAIGraphStructuralAdapter;
begin
  Graph := TAIDependencyGraph.Create(Self);
  Adapter := TAIGraphStructuralAdapter.Create(Self);
  try
    Adapter.DependencyGraph := Graph;
    Adapter.Refresh;
    // Visualizer.GraphMap := Adapter.GraphMap;
  finally
    Adapter.Free;
    Graph.Free;
  end;
end;
```

### Observacoes

Cada componente desta pasta expõe uma propriedade published `Prompt` que documenta sua API interna para `TAIAgent`.
