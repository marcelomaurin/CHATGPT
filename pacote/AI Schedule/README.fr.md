# 📅 Documentation de l'onglet AI Schedule

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Schedule**.

## Planification Automatique et Ligne Temporelle Neuronale.
Composants pour la gestion intelligente des tâches périodiques basées sur des expressions cron.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TIASchedule** | Planificateur de tâches. | `CronExpression, MaxIterations` | `ScheduleTask, CancelTask` | Gérer les déclencheurs temporels pour les activités de l'agent d'IA. |

### 💻 Exemple de Code Lazarus (TIASchedule)

```pascal
var
  MyComponent: TIASchedule;
begin
  MyComponent := TIASchedule.Create(Self);
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
