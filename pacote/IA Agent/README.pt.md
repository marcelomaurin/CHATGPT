# 🤖 Documentação da Aba IA Agent

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **IA Agent**.

## Agentes Inteligentes Autônomos e Tomada de Decisão.
Estrutura de orquestração cognitiva que planeja ações e mapeia saídas físicas usando RTTI dinâmico.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIAgent** | Cérebro do Agente cognitivo. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | Analisar telemetria e planejar ações autônomas. |
| **TAIAgentResource** | Repositório de dispositivos e hardware vinculado. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | Mapear canais físicos (e-mail, redes, sensores) para a IA. |
| **TAIAgentOutput** | Disparador automático de canais de saída. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | Conectar a decisão lógica da IA à execução em hardware. |

### 💻 Exemplo de Código Lazarus (TAIAgent)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
