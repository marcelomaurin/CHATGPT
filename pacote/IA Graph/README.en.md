# 📊 Documentation for IA Graph Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **IA Graph** tab.

## Text Classification by Weighted Graph Maps.
Explainable short text and ticket classification component based on local token graph maps.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIGraphMap** | Weighted graph text classifier. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classify short texts locally without network dependencies. |

### 💻 Lazarus Code Example (TAIGraphMap)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
