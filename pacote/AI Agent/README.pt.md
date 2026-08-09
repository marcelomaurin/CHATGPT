# 🤖 Documentação da Aba AI Agent

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Agent**.

## Agentes Inteligentes Autônomos e Tomada de Decisão.
Estrutura de orquestração cognitiva que planeja ações e mapeia saídas físicas usando RTTI dinâmico.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIAgent** | Cérebro do Agente cognitivo. | `ChatGPT, Options, Action, ToolRegistry, Safety, SystemPrompt` | `Execute`, `ExecuteToolCall`, `ExecuteToolJSON` | Analisar telemetria, planejar ações e executar tools sob política. |
| **TAIToolRegistry** | Catálogo e executor controlado de ferramentas. | `UpdatePolicy, DeletePolicy, ExecutePolicy, EmailPolicy, FilesystemPolicy` | `RegisterTool`, `FindTool`, `Execute`, `ToolsJSON` | Validar schemas, aplicar confirmação e produzir resultados estruturados. |
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

### Integração Agent + RAG

`TAIAgent.RAG` aceita qualquer `TComponent` que implemente
`IAIRAGProvider`. `TAIRAG` implementa esse contrato e preserva ownership por
componentes com `FreeNotification`. O Agent copia o contexto e as fontes antes
de montar o prompt enviado ao LLM.

O sample [`agent_rag_demo`](../samples/AI%20Agent/agent_rag_demo/) demonstra o
fluxo `TAIAgent -> TAIRAG -> TAIGraphMap -> TCHATGPT`, incluindo configuração
de provider e mensagens visíveis de erro.

### Tool calls seguras

O contrato `TAIToolCall -> TAIToolResult`, registro, schemas e políticas de
confirmação estão documentados em [`TOOLS.md`](TOOLS.md). O sample
[`tool_call_demo`](../samples/AI%20Agent/tool_call_demo/) executa uma tool segura
e uma tool sensível com rejeição/aprovação explícita.

### Grafos, checkpoints e aprovação humana

`TAIAgentGraph` modela nós, arestas condicionais, prioridade, delegação,
checkpoint/resume, aprovação humana e dry-run sem efeitos colaterais. Consulte
[`AGENT_GRAPH.md`](AGENT_GRAPH.md) e o sample
[`agent_graph_demo`](../samples/AI%20Agent/agent_graph_demo/).

### Guardrails, avaliação e traces

Guardrails de entrada, saída e tools são aplicados pelo Agent sem alterar o
comportamento quando nenhuma regra está configurada. Consulte
[`GUARDRAILS.md`](GUARDRAILS.md), o pacote `openai_evaluation` para datasets e
regressões e `openai_observability` para propagação de `TraceID` e spans.
