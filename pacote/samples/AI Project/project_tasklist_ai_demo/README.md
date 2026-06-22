# Project TaskList AI Demo

Este é um exemplo conciso para demonstrar como utilizar as principais ferramentas do **Lazarus AI Suite (AI Project)** para gerenciar um projeto através de LLMs (como OpenAI ou Ollama).

## Objetivo
O objetivo deste projeto não é ser um gerenciador de tarefas completo, mas sim uma **Prova de Conceito (PoC)** mostrando como:
1. Configurar as credenciais da IA.
2. Escrever um briefing (objetivo, restrições e entregáveis).
3. Acionar a IA para quebrar o briefing em tarefas.
4. Mostrar e controlar essas tarefas em um Kanban/Grid, incluindo painel de Status, Gantt e Timeline.
5. Exportar Relatórios Markdown/JSON e persistir em disco (.aiproj.json).

## Como Executar
1. Abra `project_tasklist_ai_demo.lpi` no Lazarus.
2. Compile e execute.
3. Na aba **Config IA**, configure seu endpoint (se não for OpenAI, mude para Ollama e coloque `http://localhost:11434` no endpoint) e informe o Token (se aplicável). **Clique em Aplicar Configuração**.
4. Na aba **Projeto**, modifique o texto do seu projeto, se desejar.
5. Clique em **Criar Agentes Padrão** e depois em **Gerar Tarefas com IA**.
6. Aguarde (verifique os logs na aba JSON/Log).
7. Alterne para as demais abas (Tarefas, Execução, Relatório) para interagir com o resultado.

## Principais Componentes Utilizados
- `TAIProject`: Coração da inteligência de projeto.
- `TAIProjectLLMConfig`: Frame pronto para lidar com a injeção do modelo de LLM.
- `TAIProjectTasks`: Engine criador de tarefas e manipulador da arvore JSON.
- `TAIProjectAgents`: Engine de perfis de trabalhadores do projeto.
- `TAITaskActions`: Engine histórico de transições de status das tasks.
- `TAIProjectTaskGrid` e `TAITaskActionPanel`: Interface de visualização em grid e formulário de apontamento.
- `TAIProjectStatusPanel`, `TAIProjectGantt`, `TAIProjectTimeline`: Componentes visuais gráficos atrelados ao estado do projeto.
- `TAIProjectStorage` e `TAIProjectReports`: Persistência de disco e extração Markdown/JSON.
