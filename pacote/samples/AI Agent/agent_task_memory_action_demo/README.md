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
