# 🤖 Documentação da Aba AI Agent

Esta pasta contém os componentes de agentes da suíte CHATGPT para Lazarus/Free Pascal. Eles permitem classificar entradas, decidir ações, preparar chamadas estruturadas, executar tools sob política, manter memória e integrar agentes com RAG, projetos e recursos externos.

## Componentes principais

| Componente | Finalidade |
|---|---|
| `TAIAgent` | Orquestra LLM, tools, políticas, RAG e execução. |
| `TAIClassifierAgent` | Classifica entradas em categorias estruturadas. |
| `TAIDecisionAgent` | Transforma contexto em decisão. |
| `TAIActionBuilderAgent` | Converte decisão em ações preparadas. |
| `TAIActionExecutor` | Executa ações registradas sob controle da aplicação host. |
| `TAIAgentMemoryMap` | Mantém memória estruturada do fluxo do agente. |
| `TAIToolRegistry` | Registra tools, schemas e políticas de execução. |
| `TAIAgentGraph` | Modela fluxos com nós, condições, checkpoints e aprovação humana. |

## Integração Agent + RAG

`TAIAgent.RAG` aceita qualquer componente que implemente `IAIRAGProvider`. `TAIRAG` implementa esse contrato sem transferir ownership. O Agent usa `FreeNotification` para limpar a referência quando o provider é destruído.

O fluxo típico é:

```pascal
RAG.GraphMap := GraphMap;
RAG.ChatGPT := ChatGPT;
Agent.RAG := RAG;
Agent.ChatGPT := ChatGPT;
```

Consulte `pacote/AI RAG/README.md` e o sample `pacote/samples/AI Agent/agent_rag_demo/`.

## Tool calls seguras

O contrato de tools é baseado em ações estruturadas e políticas definidas pela aplicação. O LLM pode propor uma ação, mas a aplicação host continua responsável por decidir o que pode ser executado automaticamente e o que exige aprovação humana.

Consulte `TOOLS.md` e o sample `pacote/samples/AI Agent/tool_call_demo/`.

## Alteração segura de fontes

A unit `aiagent_sourceactions.pas` fornece ações específicas para agentes de desenvolvimento:

- leitura de arquivo;
- substituição exata de trecho;
- backup e rollback;
- build com executável configurado pelo host;
- verificação pós-escrita;
- confinamento obrigatório a `WorkspaceRoot`;
- bloqueio de traversal e symlink/reparse fora do workspace;
- preservação de BOM, encoding e CRLF/LF;
- redaction de padrões comuns de credenciais na saída de processos.

Essas ações foram projetadas para reutilizar `TAIActionExecutor` em IDEs e agentes de correção de fontes, sem permitir execução arbitrária escolhida pelo LLM.

Referência: `DOC/components/TAISourceActions/README.md`.

Sample: `pacote/samples/AI Agent/source_fix_agent_demo/`.

## Grafos, checkpoints e aprovação humana

`TAIAgentGraph` permite nós, arestas condicionais, prioridade, delegação, checkpoint/resume, dry-run e etapas que exigem aprovação humana. Consulte `AGENT_GRAPH.md` e `pacote/samples/AI Agent/agent_graph_demo/`.

## Guardrails, avaliação e observabilidade

Guardrails de entrada, saída e tools podem ser aplicados sem alterar o comportamento quando nenhuma regra é configurada. Consulte `GUARDRAILS.md`.

Para testes de qualidade, use o pacote `openai_evaluation`. Para traces, métricas e `TraceID`, use `openai_observability`.

## Estado de maturidade

A presença do componente na paleta ou a compilação de um sample não significa que integrações externas estejam automaticamente validadas em runtime. Hardware, APIs, DLLs, modelos locais e serviços externos precisam ser testados no ambiente final.

Os componentes devem continuar separados entre runtime e design-time. Units com `Register` pertencem ao lado de design-time e não devem ser adicionadas como dependência de runtime sem necessidade.
