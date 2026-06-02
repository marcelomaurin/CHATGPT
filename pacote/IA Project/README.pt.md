# [IA] Documentação da Aba IA Project

> [!NOTE]
> Esta pasta contém a paleta de componentes do Lazarus sob a aba **IA Project**.

## Coordenação Avançada de Projetos de IA e Pipelines de Execução.
Centraliza e automatiza a conexão entre os diversos módulos do projeto (Inputs, Redes Neurais, Agentes e Outputs de Documentos).

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIProject** | Coordenador e cérebro global do projeto de IA. | `ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode` | `Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt` | Centralizar chaves de segurança, carregar configurações de arquivos JSON e disparar execuções de forma simulada ou em ambiente de produção. |
| **TAIPipeline** | Conector de fluxos (Entrada -> Processamento -> Saída) estruturados. | `Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax` | `Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor` | Automatizar a ponte de dados ligando sensores (Input) à predição de Redes Neurais e formatação de relatórios unificados (Output). |
| **TAIPromptBuilder** | Construtor de prompts dinâmicos a partir dos componentes do formulário. | `IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt` | `BuildFromOwner, BuildFromComponents, ExtractPrompt` | Varrer o formulário e agrupar dinamicamente as descrições (Prompt) de todas as ferramentas disponíveis para enviar ao ChatGPT. |

### [Code] Exemplo de Código Lazarus (TAIProject)

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


### [Bridge] Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
