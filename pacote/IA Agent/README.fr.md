# 🤖 Documentation de l'onglet IA Agent

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **IA Agent**.

## Agents Intelligents Autonomes et Prise de Décision.
Framework d'orchestration cognitive qui planifie les actions et cartographie les sorties physiques via RTTI dynamique.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIAgent** | Cerveau de l'agent cognitif. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | Analyser la télémétrie et planifier des actions autonomes. |
| **TAIAgentResource** | Répertoire de matériels et dispositifs connectés. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | Associer les canaux physiques (e-mail, réseau, capteurs) à l'IA. |
| **TAIAgentOutput** | Déclencheur automatique de canaux physiques. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | Connecter la décision logique de l'IA à l'exécution matérielle. |

### 💻 Exemple de Code Lazarus (TAIAgent)

```pascal
var
  MyComponent: TAIAgent;
begin
  MyComponent := TAIAgent.Create(Self);
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
