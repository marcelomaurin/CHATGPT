# 🤖 Documentação da Aba AI Agent

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Agent**.

## Agentes Inteligentes Autônomos e Tomada de Decisão.
Estrutura de orquestração cognitiva que planeja ações e mapeia saídas físicas usando RTTI dinâmico.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIAgent** | Cérebro do Agente cognitivo. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | Analisar telemetria e planejar ações autônomas. |
| **TAIAgentResource** | Repositório de dispositivos e hardware vinculado. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | Mapear canais físicos (e-mail, redes, sensores) para a IA. |
| **TAIAgentOutput** | Disparador automático de canais de saída. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | Conectar a decisão lógica da IA à execução em hardware. |
| **TAIMapaDeMemoria** | Histórico estruturado de execução e contexto multiagente. | `SessionId, FlowName, Items, DetectInformationLoss` | `StartFlow, BeginAgentStep, EndAgentStep, BuildContextForAgent` | Preservar contexto e rastrear o caminho percorrido. |
| **TAIAgentOrchestrator** | Orquestrador central de fluxos multiagente. | `ChatGPT, MapaDeMemoria, Classifier, DecisionAgent, ActionBuilder, Executor` | `Run(const AInput: string): Boolean` | Coordenar as etapas cognitivas (classificar, decidir, ajustar, executar). |

### 🧠 Preservação de Contexto com `TAIMapaDeMemoria`

O TAIMapaDeMemoria é o componente responsável por preservar o contexto entre agentes.

Ele registra a ordem da análise, o pedido recebido, o tipo do agente, as perguntas realizadas, a análise, a explicação, a ação tomada e a saída gerada.

Com isso, cada agente consegue verificar se alguma informação se perdeu antes de continuar o fluxo.

> O mapa de memória não é pensamento interno oculto do modelo. Ele é um registro operacional estruturado do fluxo de agentes.

### 💻 Exemplo de Código Lazarus (Fluxo de Orquestração com Mapa de Memória)

```pascal
var
  Orchestrator: TAIAgentOrchestrator;
begin
  Orchestrator := TAIAgentOrchestrator.Create(Self);
  try
    Orchestrator.ChatGPT := FChatGPT;
    
    // Configura agentes vinculados ao fluxo
    Orchestrator.Classifier := FClassifier;
    Orchestrator.DecisionAgent := FDecisionAgent;
    Orchestrator.ActionBuilder := FActionBuilder;
    Orchestrator.Executor := FExecutor;

    // Executa fluxo completo com mapa de memória gerado automaticamente
    Orchestrator.Run('O computador da recepção não liga e a unidade precisa de atendimento urgente.');
  finally
    Orchestrator.Free;
  end;
end;
```


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
