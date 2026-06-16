# 📅 Documentazione della Scheda AI Schedule

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Schedule**.

## Pianificazione Automatica e Linea Temporale Neurale.
Componenti per la gestione intelligente delle attività periodiche basate su espressioni cron.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TIASchedule** | Pianificatore di compiti e cronoprogrammi. | `CronExpression, MaxIterations` | `ScheduleTask, CancelTask` | Gestire attivatori temporali per le attività del cervello dell'IA. |

### 💻 Esempio di Codice Lazarus (TIASchedule)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
