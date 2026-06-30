# 🤖 Documentation for AI Agent Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Agent** tab.

## Autonomous Intelligent Agents and Decision Making.
Cognitive orchestration framework that plans actions and maps physical outputs using dynamic RTTI.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIAgent** | Brain of the cognitive Agent. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | Analyze telemetry and plan autonomous actions. |
| **TAIAgentResource** | Repository of connected hardware and devices. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | Map physical channels (email, network, sensors) to the AI. |
| **TAIAgentOutput** | Automated dispatcher for physical channels. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | Connect logical AI decision to hardware execution. |
| **TAIMapaDeMemoria** | Structured execution history and multi-agent context. | `SessionId, FlowName, Items, DetectInformationLoss` | `StartFlow, BeginAgentStep, EndAgentStep, BuildContextForAgent` | Preserve context and trace the cognitive path. |
| **TAIAgentOrchestrator** | Central orchestrator for multi-agent workflows. | `ChatGPT, MapaDeMemoria, Classifier, DecisionAgent, ActionBuilder, Executor` | `Run(const AInput: string): Boolean` | Coordinate cognitive stages (classify, decide, adjust, execute). |

### 🧠 Context Preservation with `TAIMapaDeMemoria`

The TAIMapaDeMemoria is the component responsible for preserving context between agents.

It records the analysis order, the request received, the agent type, the questions asked, the analysis performed, the explanation, the action taken, and the output generated.

With this, each agent can verify if any information was lost before continuing the workflow.

> The memory map is not the model's hidden internal thoughts. It is a structured operational record of the agent workflow.

### 💻 Lazarus Code Example (Orchestration Flow with Memory Map)

```pascal
var
  Orchestrator: TAIAgentOrchestrator;
begin
  Orchestrator := TAIAgentOrchestrator.Create(Self);
  try
    Orchestrator.ChatGPT := FChatGPT;
    
    // Configure agents connected to the workflow
    Orchestrator.Classifier := FClassifier;
    Orchestrator.DecisionAgent := FDecisionAgent;
    Orchestrator.ActionBuilder := FActionBuilder;
    Orchestrator.Executor := FExecutor;

    // Run complete flow with auto-created memory map
    Orchestrator.Run('O computador da recepção não liga e a unidade precisa de atendimento urgente.');
  finally
    Orchestrator.Free;
  end;
end;
```


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
