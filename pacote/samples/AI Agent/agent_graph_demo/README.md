# Agent graph demo

Workflow sequencial `plan -> approve -> finish`. O sample pausa em
`NeedsApproval`, salva checkpoint JSON versionado, recria o grafo, carrega o
checkpoint e continua após `AcceptApproval`.

Para não executar efeitos, selecione `ExecutionMode = aemSimulation` ou
`aemDryRun`; nesses modos handlers/agents reais não são chamados.
