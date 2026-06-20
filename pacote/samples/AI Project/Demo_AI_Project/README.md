# Demo_AI_Project

## ⚠️ Este é um DEMO de componentes, não uma aplicação final

Este sample é um **demo visual de componentes AI Project** para Lazarus.  
O objetivo é demonstrar componentes reutilizáveis, **não** criar uma aplicação de gestão de projetos pronta para produção.

---

## Componentes demonstrados

### Não-visuais (AI Project palette)
| Componente | Descrição |
|------------|-----------|
| `TAIProject` | Componente principal — gerencia dados, AI e persistência |
| `TAIProjectLLMConfig` | Configuração de provedor LLM |
| `TAIProjectStorage` | Persistência em `.aiproj.json` (SaveToken=False por padrão) |
| `TAIAgileDocuments` | Visão de negócio, requisitos, épicos, histórias |
| `TAIProjectTasks` | Gerenciamento de tarefas com AddTask/CancelTask |
| `TAIProjectDependencies` | Dependências seriais e paralelas |
| `TAIProjectAgents` | 9 perfis de agentes (UI, DBA, DEV, Infra, etc.) |
| `TAITaskActions` | Ações de ciclo de vida de tarefas |
| `TAIProjectReports` | Geração de relatórios em Markdown/JSON |
| `TAIProjectRevisions` | Histórico de revisões e eventos de timeline |

### Visuais (AI Project palette)
| Componente | Descrição |
|------------|-----------|
| `TAIProjectGantt` | Gráfico de Gantt desenhado com Canvas |
| `TAIProjectTimeline` | Timeline de eventos do projeto |
| `TAIRiskMatrix` | Matriz de riscos 5×5 |
| `TAIProjectTaskGrid` | Grade de tarefas com coloração por status |
| `TAIProjectStatusPanel` | Painel de contagem de tasks por status |
| `TAIAgentManagerFrame` | Frame de gestão de agentes (lista + edição) |
| `TAITaskActionPanel` | Painel de ações em tasks |
| `TAIProjectReportViewer` | Viewer de relatórios com exportação |

---

## Abas do demo

```
Configuration         — Provedor LLM, token, modelo, endpoint
Project Description   — Nome, objetivo, contexto, datas
Agile Documents       — Visão, requisitos, stakeholders, riscos, épicos, histórias
Agents                — Lista e gestão dos 9 perfis de agentes
Tasks                 — Grid de tarefas com status colorido
Task Actions          — Aplicar ações (Confirm/Start/Finish/Block/etc.)
Dependencies          — Dependências seriais e paralelas
Execution Plan        — Plano de execução e marcos
Gantt                 — Gráfico de Gantt visual
Timeline              — Linha do tempo de eventos
Revision              — Histórico de revisões e correções com IA
Reports               — Relatórios geráveis e exportáveis
JSON                  — Visualização do JSON completo do projeto
Log                   — Log de eventos e erros
```

---

## Como usar

1. **Aba Configuration** — configure o provedor LLM (Ollama local, OpenAI, etc.)
2. **Aba Project Description** — descreva o projeto e clique **Generate Plan with AI**
3. O demo preencherá todas as abas com os dados retornados pela IA
4. Navegue pelas abas para ver os componentes em ação
5. **Salvar:** Arquivo → Save Project → `.aiproj.json`
6. **Carregar:** Load Project → `.aiproj.json`

---

## Segurança do token

> O token de API **não é salvo por padrão**.  
> Marque "Save API Token to file" apenas se tiver certeza do risco.

---

## Dependências

- Pacote `openai_project` (`pacote/packages/openai_project.lpk`)
- Pacote `openai_agent` (`pacote/packages/openai_agent.lpk`)
- Lazarus LCL

---

## Build

```bash
lazbuild "pacote/packages/openai_project.lpk"
lazbuild "pacote/samples/AI Project/Demo_AI_Project/Demo_AI_Project.lpi"
```
