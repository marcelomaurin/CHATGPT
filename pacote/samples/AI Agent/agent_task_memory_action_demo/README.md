# Sample: agent_task_memory_action_demo

Este sample demonstra um fluxo multiagente orientado por tarefas.

O prompt inicial é transformado em tarefas. Cada tarefa pode ser selecionada e processada por agentes especializados. O mapa de memória registra o caminho completo da análise, incluindo perguntas, explicações, ações tomadas e possíveis perdas de informação.

Por segurança, a criação de Word e o envio de e-mail são simulados por padrão.

## Visão Geral das Abas
1. **Prompt**: Onde você insere o prompt detalhado e configura suas chaves/provedor de IA (OpenAI, Gemini, Claude, Local).
2. **Tarefas**: O grid contendo a lista de tarefas planejadas (T001 a T007). O usuário pode selecionar tarefas e executá-las individualmente ou em lote.
3. **Agente**: Painel detalhado de auditoria que mostra a entrada do agente de IA atual, as perguntas internas respondidas, justificativa de análise e saída lógica.
4. **Mapa de Memória**: O histórico operacional estruturado contendo o caminho percorrido por todo o fluxo de agentes cognitivos.
5. **Resultado**: Onde o texto final gerado do currículo, as configurações de e-mail e os caminhos de arquivos salvos são exibidos.
6. **Log**: O log cronológico detalhado de toda a execução em tempo real.

## Limitações do Envio de E-mail
O envio real de e-mail através do `TAIEmailClient` não suporta anexos reais nesta fase, de modo que o caminho do arquivo Word é adicionado diretamente ao corpo do e-mail nas execuções reais.

## Modo Simulado e Execuções Reais
* Por padrão, a simulação está ativada.
* Para habilitar a escrita real do arquivo Word, desmarque "Modo Simulado" e marque "Permitir Gerar Word Real".
* Para habilitar o envio real do e-mail, desmarque "Modo Simulado" e marque "Permitir Envio de E-mail Real". Execuções reais de e-mail sempre exigem confirmação interativa do usuário por meio de caixa de diálogo.

## Transformação Cognitiva em Ações Operacionais

Durante o fluxo, a resposta estruturada das tarefas é repassada ao `TAIActionBuilderAgent`. A chamada utiliza o método `BuildActionsWithRecovery` para preencher, higienizar e estruturar os parâmetros das ações planejadas. Essa abordagem garante que, caso o LLM retorne um layout inválido ou fora do formato esperado, o próprio componente faça a recuperação automática da intenção lógica com base no mapa de memória.

## Automação Real de Browser (Chromium Integration)

Este sample implementa um fluxo real de navegação e extração de dados usando o `AIChromiumBrowser` integrado e o novo `TAIActionExecutor` com registro dinâmico de ações:
- **Fluxo do Pipeline**:
  `Prompt` ➔ `TAIDecisionAgent (Planner)` ➔ `TAIActionBuilderAgent` ➔ `TAIActionExecutor` ➔ `AIChromiumBrowser (DOM Automation)`
- **Ações Reais Executadas**:
  O executor real dispara ações de navegação (`BROWSER_NAVIGATE`), mapeamento do DOM (`BROWSER_READ_PAGE`), inserção de valores (`BROWSER_SET_VALUE`), pressionamento de teclas (`BROWSER_PRESS_ENTER`) e captura final de resultados (`BROWSER_CAPTURE_TEXT`) de forma assíncrona/bloqueante com tratamento seguro de seletores CSS.
- **Botão Cenário Pesquisa Browser**:
  Adicionado na aba **Prompt**, permite carregar de forma rápida o cenário de busca dinâmica no Google, servindo de base para validação dos seletores e inputs sob o pipeline de orquestração cognitiva.

