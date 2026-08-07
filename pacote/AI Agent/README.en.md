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

### 💻 Lazarus Code Example (TAIAgent)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
