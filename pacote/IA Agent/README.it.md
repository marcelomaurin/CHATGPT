# 🤖 Documentazione della Scheda IA Agent

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **IA Agent**.

## Agenti Intelligenti Autonomi e Presa di Decisione.
Framework di orchestrazione cognitiva che pianifica azioni e mappa le uscite fisiche utilizzando RTTI dinamico.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIAgent** | Cervello dell'Agente cognitivo. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | Analizzare la telemetria e pianificare azioni autonome. |
| **TAIAgentResource** | Repository di dispositivi e hardware collegati. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | Mappare canali fisici (e-mail, reti, sensori) per l'IA. |
| **TAIAgentOutput** | Disparatore automatico di canali fisici. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | Collegare la decisione logica dell'IA all'esecuzione hardware. |

### 💻 Esempio di Codice Lazarus (TAIAgent)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
