# 📊 Documentation de l'onglet IA Graph

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **IA Graph**.

## Classification de Texte par Cartes de Graphes Pondérés.
Composant de classification explicable de textes courts basé sur des cartes de graphes de jetons locaux.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIGraphMap** | Classificateur de texte par graphe pondéré. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classifier des textes courts localement sans dépendance réseau. |

### 💻 Exemple de Code Lazarus (TAIGraphMap)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
