# 📊 Documentación de la Pestaña AI Graph

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Graph**.

## Clasificación de Texto por Mapas de Grafos Ponderados.
Componente de clasificación explicable de textos cortos basado en mapas de grafos de tokens locales.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIGraphMap** | Clasificador textual por grafo ponderado. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Clasificar textos cortos localmente sin dependencias de red. |

### 💻 Ejemplo de Código Lazarus (TAIGraphMap)

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


### ⚡ Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
