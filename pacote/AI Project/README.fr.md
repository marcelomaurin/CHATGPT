# [IA] Documentation de l'onglet AI Project

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Project**.

## Coordination Avancée de Projets d'IA et Pipelines de Traitement.
Centralise et automatise les flux d'exécution entre les modules (Entrée, Modèles Neuronaux, Agents, Sortie de Documents).

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIProject** | Coordonnateur global de projets d'IA. | `ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode` | `Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt` | Centraliser les configurations de sécurité, charger les projets JSON et simuler des tests. |
| **TAIPipeline** | Connecteur de flux de données (Entrée -> Calcul -> Sortie). | `Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax` | `Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor` | Automatiser le flux reliant les capteurs aux prédictions de réseaux de neurones et aux PDF/Word. |
| **TAIPromptBuilder** | Générateur de prompts dynamiques à partir des composants du formulaire. | `IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt` | `BuildFromOwner, BuildFromComponents, ExtractPrompt` | Parcourir le formulaire et regrouper les descriptions (Prompt) de tous les outils disponibles pour ChatGPT. |

### [Code] Exemple de Code Lazarus (TAIProject)

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


### [Bridge] Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API pour guider les agents d'IA (`TAIAgent`) de façon autonome.
