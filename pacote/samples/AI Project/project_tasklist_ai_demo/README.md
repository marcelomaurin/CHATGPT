# Project TaskList AI Demo

Este projeto demonstra o uso da suíte **Lazarus AI Suite (AI Project)** para o planejamento e gerenciamento estruturado de projetos utilizando Inteligência Artificial (modelos LLM como OpenAI, Ollama, etc.).

## 🎯 Objetivo

O objetivo deste projeto não é ser um gerenciador de tarefas completo para o usuário final, mas sim uma **Prova de Conceito (PoC)** robusta e arquitetural. Ele ilustra como separar adequadamente as responsabilidades na interface visual (View) da lógica de orquestração de IA (Controller/Model) usando nossa arquitetura de componentes.

O fluxo de planejamento provado neste demo segue os preceitos de uma engenharia de projeto guiada por IA:
1. **Configuração de LLM:** Configurar chaves e modelos de IA.
2. **Especificação de Escopo:** Coletar um escopo básico (ideia/briefing) e utilizar a IA para redigir uma documentação ágil completa (Visão, Requisitos, Riscos).
3. **Quebra de Tarefas:** Utilizar a especificação enriquecida para quebrar o projeto em tarefas técnicas encadeadas.
4. **Gerenciamento e Visualização:** Monitorar as tarefas em um ambiente Kanban/Grid, incluindo painéis de Status, gráficos de Gantt e Timeline.
5. **Persistência e Relatórios:** Exportar relatórios em formato Markdown, JSON e salvar o estado completo (.aiproj.json).

---

## ⚙️ Arquitetura Orientada a Componentes (Deep Dive)

O principal pilar da arquitetura do pacote **AI Project** é a descentralização. Em vez de centralizar prompts, tratamentos JSON e conexões HTTP em um `Form` monstruoso, o **Lazarus AI Suite** encapsula lógicas complexas de domínio em componentes especialistas. 

Todos os componentes interagem com uma fonte de verdade única: a propriedade `ProjectData`, um objeto JSON persistido em memória que representa o estado completo do projeto.

### 1. Motor e Comunicação Base
- **`TCHATGPT` (do pacote openai_core):** É o motor universal de comunicação LLM. Ele não entende o que é um projeto, apenas processa prompts e devolve respostas. Todos os componentes inteligentes do *AI Project* precisam estar linkados a um objeto `TCHATGPT` para funcionar.
- **`TAIProjectLLMConfig`:** Facilita a configuração do motor. No demo, este componente é responsável por ler os dados da aba "Config IA" (Provedor, Modelo, Endpoint, Token) e repassar essas credenciais dinamicamente para o `TCHATGPT`, sem que o desenvolvedor precise codificar integrações manuais.

### 2. Ciclo de Vida do Projeto
- **`TAIProject`:** É o coração estrutural do projeto. Ele hospeda a instância base do `ProjectData`. Os componentes visuais (Grids, Timelines, Gráficos) se vinculam a este componente para refletir mudanças no estado do JSON de forma reativa.

### 3. Orquestração e Geração de Conteúdo (Inteligência)
- **`TAIProjectSpecification`:** *O Engenheiro de Requisitos*. 
  Sua responsabilidade é ler os campos básicos descritos pelo usuário (Nome, Objetivo, Restrições, Entregáveis) e acionar o `TCHATGPT` com um prompt específico de engenharia de software ágil. Ele traduz uma ideia de 2 linhas em um documento contendo:
  - Visão de Negócio
  - Requisitos Funcionais e Não Funcionais
  - Riscos do Projeto
  - Épicos e Histórias de Usuário
  O resultado é embutido na chave `specification` do `ProjectData`.
  
- **`TAIProjectTasks`:** *O Gerente de Projetos*.
  Este componente consome a `specification` gerada no passo anterior. Ele instrui o `TCHATGPT` a ler a especificação rica e quebrar o projeto em tarefas (Tasks). O motor cuida de solicitar um retorno em formato JSON estrito, faz o parsing da resposta do LLM e popula a árvore de tarefas com dependências, prioridades, estimativas de horas e datas.

### 4. Interface Gráfica e Apresentação Visuais
- **`TAIProjectTaskGrid` e `TAITaskActionPanel`:** Estes controles se atrelam ao `TAIProject` e fazem o *bind* bidirecional da árvore de tarefas. O Grid lista as tarefas; o painel permite realizar "apontamentos" e ações, mudando o estado da tarefa (ex: TODO -> DOING).
- **`TAIProjectStatusPanel`:** Lê as horas estimadas vs reais e os percentuais de completude para mostrar um sumário executivo em tempo real.
- **`TAIProjectGantt` e `TAIProjectTimeline`:** Renderizam o plano de projeto. O Gantt foca no encadeamento lógico e dependências; a Timeline foca no histórico de eventos contínuos.

### 5. Persistência e Exportação
- **`TAIProjectStorage`:** Responsável exclusivo pelas operações de disco. Serializa o `ProjectData` em arquivos `.aiproj.json` e o recupera, restaurando todo o contexto do projeto instantaneamente, sem perder as dependências encadeadas.
- **`TAIProjectReports`:** Um extrator que lê o JSON estruturado e compila arquivos `.md` elegantes contendo toda a documentação, escopo e relação de tarefas para entrega final.

> **Nota de Design:** Anteriormente, o componente `TAIProjectAgents` (O RH de Inteligência) estava incluído neste demo. Ele foi intencionalmente removido para manter o escopo deste sample restrito apenas à mecânica fundamental de **Escopo -> Tarefas**. Para orquestração multi-agentes e auto-associação de tarefas a perfis sintéticos de IA, consulte as documentações avançadas de Agentes do pacote `openai_agent`.

---

## 🚀 Como Executar o Fluxo

1. **Abra o Projeto:** No Lazarus, abra `project_tasklist_ai_demo.lpi`. Compile e execute.
2. **Configuração de LLM:** 
   - Na aba **Config IA**, selecione o provedor (ex: `OpenAI`).
   - Informe seu Token de acesso (API Key).
   - Clique em **Aplicar Configuração** (isso aciona o `TAIProjectLLMConfig`).
3. **Escopo:**
   - Na aba **Projeto**, digite um cenário simples.
   - Clique no botão **"1. Gerar Especificação com IA"** e aguarde. O `TAIProjectSpecification` fará o trabalho pesado. O resultado detalhado aparecerá nos campos de memo abaixo.
4. **Tarefas:**
   - Estando satisfeito com o escopo criado, clique no botão **"2. Gerar Tarefas com IA"**.
   - O `TAIProjectTasks` assumirá. Acompanhe a aba `JSON/Log` para ver o tráfego gerado pela IA.
5. **Acompanhamento Visual:**
   - Navegue para as abas **Tarefas**, **Execução**, **Gantt**, **Timeline** e **Relatório**. Note como todos os componentes gráficos desenharam e interpretaram as informações sem que uma única linha de código extra fosse necessária no seu formulário `main.pas`.
