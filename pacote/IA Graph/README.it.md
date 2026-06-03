# 📊 Documentazione della Scheda IA Graph

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **IA Graph**.

## Classificazione del Testo tramite Mappe di Grafi Pesati.
Componente di classificazione spiegabile di testi brevi basato su mappe di grafi di token locais.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIGraphMap** | Classificatore testuale per grafo pesato. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classificare testi brevi localmente senza dipendenze di rete. |

### 💻 Esempio di Codice Lazarus (TAIGraphMap)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
