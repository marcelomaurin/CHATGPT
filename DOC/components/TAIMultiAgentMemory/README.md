# Multi-Agent Deterministic Memory

Arquitetura Lazarus/FPC para roteamento de múltiplas IAs por capacidade demonstrada em cada tipo de questão.

## Princípios

- Cada agente/especialista possui um mapa JSON determinístico próprio.
- A IA forte/supervisora possui um mapa global separado com evidências de todos os agentes.
- O score não é reputação geral: é calculado para o fingerprint da questão atual.
- O fingerprint inclui domínio, subdomínio, tipo de tarefa, linguagem, framework, escopo, capacidades requeridas, complexidade e risco.
- Build, testes, retries, correções e nota do supervisor são fatos persistidos.
- O especialista não atribui sua própria nota final; `TAIStrongSupervisor` registra a revisão.
- Questões acima da capacidade declarada são penalizadas e podem escalar para modelo maior.

## Units

- `aiagent_deterministicmemory.pas`: fingerprint, mapas individuais/globais e evidências.
- `aiagent_capabilityrouter.pas`: perfil de capacidade e score específico por questão.
- `aiagent_supervisor.pas`: registro da avaliação do modelo forte e seleção do próximo agente.

## Fluxo

1. Qualifique a questão em `TAITaskQualification`.
2. Registre especialistas no `TAIAgentCapabilityRouter`.
3. `TAIStrongSupervisor.ChooseAgent` seleciona o agente com melhor combinação de adequação e histórico similar.
4. Execute o especialista.
5. O modelo forte revisa a resposta e produz `TAISupervisorReview`.
6. `RecordReviewedExecution` grava a evidência no mapa individual e no mapa global.
7. A próxima questão semelhante usa esse histórico; uma questão diferente recebe score diferente.

Os mapas são persistidos em arquivos separados (`<agent>.json` e `global-supervisor.json`) para impedir compartilhamento implícito de memória entre especialistas.
