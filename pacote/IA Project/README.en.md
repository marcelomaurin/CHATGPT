# [IA] Documentation for IA Project Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **IA Project** tab.

## Advanced AI Project Coordination and Execution Pipelines.
Centralizes and automates the flow between various modules (Inputs, Neural Networks, Agents, and Document Exporters).

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIProject** | Global AI project coordinator and manager. | `ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode` | `Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt` | Centralize security keys, load JSON project setups, and execute routines under production or simulation modes. |
| **TAIPipeline** | Connects visual flows (Input -> Processing -> Output). | `Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax` | `Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor` | Automatically bridges raw telemetry data to Neural Network classifiers or document formatters. |
| **TAIPromptBuilder** | Constructs dynamic system prompts scanning available form tools. | `IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt` | `BuildFromOwner, BuildFromComponents, ExtractPrompt` | Scan the owner form and assemble unified descriptions (Prompt) of all available tool components for ChatGPT. |

### [Code] Lazarus Code Example (TAIProject)

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


### [Bridge] AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its API to guide AI Agents (`TAIAgent`) autonomously!
