# 🎵 Documentation de l'onglet AI Filtros Sonoros

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Filtros Sonoros**.

## Traitement des Signaux Audio et Filtres Numériques.
Module pour la transformation des fréquences sonores et l'application de filtres linéaires rapides.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAISoundFilters** | Processeur numérique de signaux sonores. | `FilterType (LowPass, HighPass, BandPass), CutoffFrequency` | `ApplyFilter(const AInputWav, AOutputWav: string): Boolean` | Nettoyer les bruits de fond et ajuster les fréquences des enregistrements micro. |

### 💻 Exemple de Code Lazarus (TAISoundFilters)

```pascal
var
  MyComponent: TAISoundFilters;
begin
  MyComponent := TAISoundFilters.Create(Self);
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
