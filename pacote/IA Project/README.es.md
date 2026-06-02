# [IA] Documentación de la Pestaña IA Project

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **IA Project**.

## Coordinación Avanzada de Proyectos de IA y Pipelines de Ejecución.
Centraliza y automatiza la conexión entre los diversos módulos del projeto (Inputs, Redes Neuronales, Agentes y Documentos).

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIProject** | Coordinador global de proyectos de IA. | `ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode` | `Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt` | Centralizar credenciales, cargar configuraciones JSON y ejecutar simulaciones o en producción. |
| **TAIPipeline** | Conector de flujos (Entrada -> Procesamiento -> Salida) estruturados. | `Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax` | `Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor` | Automatizar la transferencia de telemetrê hacia las Redes Neuronales y exportación de reportes. |
| **TAIPromptBuilder** | Constructor de prompts dinámicos escaneando componentes del formulario. | `IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt` | `BuildFromOwner, BuildFromComponents, ExtractPrompt` | Escanear el formulario y agrupar las descripciones (Prompt) de todas las herramientas para enviar a ChatGPT. |

### [Code] Ejemplo de Código Lazarus (TAIProject)

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


### [Bridge] Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
