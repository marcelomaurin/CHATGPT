# 📐 Documentation de l'onglet IA Math

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **IA Math**.

## Algèbre Vectorielle et Matricielle à Haute Vitesse.
Implémente des routines mathématiques de traitement de tenseurs similaires à NumPy en Python.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TNumPS** | Générateur et manipulateur de matrices et de vecteurs. | `ThreadSafe` | `Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random` | Effectuer des calculs statistiques lourds et de l'algèbre linéaire pour l'IA. |

### 💻 Exemple de Code Lazarus (TNumPS)

```pascal
var
  MyComponent: TNumPS;
begin
  MyComponent := TNumPS.Create(Self);
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
