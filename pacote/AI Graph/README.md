# AI Graph Tab

> This folder contains the Lazarus components under the **AI Graph** tab.

## Text Classification and Structural Graphs

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIGraphMap** | Weighted graph text classifier. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classify short texts locally without network dependencies. |
| **TAIDependencyGraph** | Factual graph with mandatory evidence and separate inferred edges. | `NodeCount, EdgeCount, Validated, LastError` | `AddNode, AddEdge, AddInferredEdge, FindNode, Clear, Validate, CountNodesOfType, CountEdgesOfType, SaveToJSON, LoadFromJSON, SaveToDOT, SaveToMermaid` | Record structural repository facts without mixing hypothesis and evidence. |
| **TAIGraphStructuralAdapter** | Structural projection for the current visualizer. | `DependencyGraph, GraphMap` | `Refresh, AttachToVisualizer` | Reuse the existing visualizer without breaking existing samples. |

### Lazarus Code Example

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

### Notes

Each component in this folder exposes a published `Prompt` property that documents its internal API for `TAIAgent`.
