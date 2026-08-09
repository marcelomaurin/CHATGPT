# Agent Graph

`aiagentgraph.pas` fornece um grafo de execução determinístico para agentes.

- `TAIAgentNode`: nó identificado, executável por evento e capaz de delegar a
  outro `TAIAgent`.
- `TAIAgentEdge`: origem, destino, prioridade e condição de transição.
- `TAIAgentGraph`: valida, inicia, avança, executa, salva checkpoint e retoma.
- `TAIAgentCheckpoint`: nó atual, estado serializado e histórico mínimo.

As condições aceitam callback ou expressão simples sobre o estado. Arestas são
avaliadas por prioridade. Um nó marcado para aprovação humana muda o grafo para
o estado de espera e só prossegue após `Approve` ou termina com `Reject`.

`DryRun=True` percorre e registra o plano sem chamar handlers nem agentes
delegados. Checkpoints são JSON e podem ser persistidos pelo aplicativo host.
Veja `samples/AI Agent/agent_graph_demo` e `tests/agent_graph_test`.
