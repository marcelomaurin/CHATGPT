# [IA] Documentazione della Scheda IA Project

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **IA Project**.

## Coordinamento Avanzato di Progetti IA e Pipeline di Esecuzione.
Centralizza e automatizza il flusso di lavoro tra i vari moduli (Input, Reti Neurali, Agenti e Documenti).

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIProject** | Coordinatore globale di progetti di IA. | `ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode` | `Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt` | Centralizzare le credenziali API, salvare configurazioni JSON ed effettuare test in modalità simulata. |
| **TAIPipeline** | Connettore di flussi strutturati (Input -> Elaborazione -> Output). | `Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax` | `Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor` | Inviare automaticamente dati normalizzati alle Reti Neurali e formattare i report. |
| **TAIPromptBuilder** | Costruttore di prompt dinamici scansionando i componenti del form. | `IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt` | `BuildFromOwner, BuildFromComponents, ExtractPrompt` | Scansionare il form e raggruppare le descrizioni (Prompt) di tutti gli strumenti disponibili per ChatGPT. |

### [Code] Esempio di Codice Lazarus (TAIProject)

```pascal
var
  MyProject: TAIProject;
  MyPipeline: TAIPipeline;
begin
  MyProject := TAIProject.Create(Self);
  MyPipeline := TAIPipeline.Create(Self);
  try
    MyProject.ProjectName := 'Smart Factory AI';
    MyProject.ChatGPT := ChatGPT1;
    MyProject.Pipeline := MyPipeline;
    
    MyPipeline.Mode := pmTextLLM;
    MyPipeline.ChatGPT := ChatGPT1;
    MyPipeline.InputText := 'Como otimizar código em FPC?';
    
    if MyProject.Execute then
      ShowMessage(MyProject.LastResult)
    else
      ShowMessage(MyProject.LastError);
  finally
    MyPipeline.Free;
    MyProject.Free;
  end;
end;
```


### [Bridge] Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` que documenta in modo trasparente le proprie API per orientare gli Agenti IA (`TAIAgent`) autonomamente.
