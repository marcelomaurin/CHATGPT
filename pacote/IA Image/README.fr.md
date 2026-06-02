# 🖼️ Documentation de l'onglet IA Image

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **IA Image**.

## Vision par Ordinateur et Filtres d'Image Numériques.
Filtres matriciels avancés de préparation d'image pour le traitement de la vision neuronale.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIImageFilters** | Filtre matriciel numérique d'image. | `FilterType (Sobel, Canny, Gaussian, Grayscale)` | `ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean` | Prétraiter les images et les flux caméras pour améliorer la reconnaissance. |

### 💻 Exemple de Code Lazarus (TAIImageFilters)

```pascal
var
  MyComponent: TAIImageFilters;
begin
  MyComponent := TAIImageFilters.Create(Self);
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
