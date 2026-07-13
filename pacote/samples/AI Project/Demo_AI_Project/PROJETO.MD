# Demo_AI_Project

## Planejador incremental de projetos com IA para Lazarus / Free Pascal

O `Demo_AI_Project` é um sample visual do pacote CHATGPT para demonstrar o uso do componente `TAIProject` como um **planejador incremental de projetos usando IA**.

O objetivo do sample é permitir que o usuário descreva o que deseja construir, configure um LLM, gere documentos de projeto, extraia tarefas, calcule dependências, estime esforço, monte cronograma, visualize Gantt, acompanhe timeline, crie revisões, salve o projeto e continue a análise em outro dia.

Este sample não é apenas um gerador de prompt. Ele é um **gestor visual de projeto com IA**.

---

## Local do sample

O sample deve ser criado em:

```text
pacote/samples/AI Project/Demo_AI_Project
```

Arquivos esperados:

```text
Demo_AI_Project.lpi
Demo_AI_Project.lpr
main.pas
main.lfm
README.md
```

---

## Propósito do sample

O `Demo_AI_Project` deve demonstrar este ciclo:

```text
1. Criar ou carregar um projeto.
2. Configurar o LLM.
3. Descrever o objetivo do projeto.
4. Gerar o plano inicial com IA.
5. Criar documentos ágeis.
6. Extrair tarefas.
7. Identificar dependências.
8. Estimar esforço por perfil técnico.
9. Calcular prazos.
10. Gerar Gantt.
11. Gerar timeline.
12. Criar agentes especializados.
13. Associar tarefas aos agentes.
14. Controlar ações das tarefas.
15. Aplicar correções incrementais.
16. Criar revisões.
17. Salvar o projeto.
18. Carregar o projeto em outro dia e continuar.
```

Resumo:

```text
AI Project = planejamento incremental de projeto com IA.
TAIProject = componente que transforma objetivos em documentos, tarefas, dependências, estimativas, revisões, Gantt, timeline e agentes.
Demo_AI_Project = sample visual que demonstra esse ciclo completo.
```

---

## O que este sample não deve ser

O sample não deve ser:

```text
um demo de console
um teste isolado de pipeline
um teste de rede neural
um gerador simples de documento
um sample baseado em SimulationMode
um exemplo que perde os dados ao fechar
```

O sample deve ser visual, persistente, incremental e revisionado.

---

## Componente principal

O componente principal é:

```pascal
TAIProject
```

Ele deve ser registrado na aba:

```pascal
RegisterComponents('AI Project', [TAIProject]);
```

Se o pacote usar português nas abas, pode ser usado:

```pascal
RegisterComponents('AI Projeto', [TAIProject]);
```

Usar apenas um padrão no pacote inteiro.

---

## Componentes usados no sample

O sample deve usar pelo menos:

```text
TAIProject
TCHATGPT
TAIPromptBuilder
```

Opcionalmente:

```text
TAIPipeline
TAIOutputDocs
```

O `TCHATGPT` será usado para chamada ao LLM.

O `TAIPromptBuilder` será usado para montar o mapa de componentes disponíveis no projeto.

O `TAIProject` será usado para armazenar, gerar, revisar, salvar, carregar e acompanhar o plano do projeto.

---

## Configuração do LLM

O sample deve possuir uma aba `Configuration` para configurar o modelo de IA.

Campos obrigatórios:

```text
Provider
Token
Model
Model version
Endpoint / Local URL
Temperature
Max tokens
Save token
Test LLM
Save Configuration
Load Configuration
```

Providers sugeridos:

```text
OpenAI
Ollama
OpenRouter
Custom
```

Valores padrão sugeridos:

```text
Provider: Ollama
Model: llama3.2
Endpoint: http://localhost:11434
Temperature: 0.2
Max tokens: 8000
Save token: false
```

Regra importante:

```text
O token não deve ser salvo por padrão.
O token só pode ser salvo se SaveToken=True.
```

Se a configuração estiver incompleta, o componente não deve simular resultado. Deve retornar erro real:

```text
LLM provider is not configured.
Token is required for this provider.
Local URL is required for local LLM provider.
```

---

## Estrutura de abas da interface

O formulário principal deve conter um `TPageControl` com as abas:

```text
Configuration
Project Description
Agile Documents
Agents
Tasks
Dependencies
Execution Plan
Gantt
Timeline
Revision
JSON
Log
```

---

# Aba Configuration

## Objetivo

Permitir configurar o LLM usado para gerar e revisar o projeto.

## Controles

```text
ComboBox cbProvider
Edit edtToken
ComboBox cbModel
Edit edtModelVersion
Edit edtEndpoint
Edit edtTemperature
Edit edtMaxTokens
CheckBox chkSaveToken
Button btnTestLLM
Button btnSaveConfig
Button btnLoadConfig
```

---

# Aba Project Description

## Objetivo

Permitir que o usuário descreva o projeto que deseja construir.

## Controles

```text
Edit edtProjectName
Memo memoProjectGoal
Memo memoProjectContext
Memo memoScope
Memo memoConstraints
Memo memoDeliverables
DateTimePicker dtProjectStart
DateTimePicker dtTargetEnd
Button btnGenerateInitialPlan
Button btnSaveProject
Button btnSaveProjectAs
Button btnLoadProject
```

## Campos esperados

```text
Project name
What do you want to build?
Context
Scope
Constraints
Expected deliverables
Project start date
Target end date
```

## Exemplo de entrada

```text
I want to create a Lazarus component that captures real audio from the microphone, saves it as WAV, validates the generated file and provides a visual demo without simulation mode.
```

---

# Aba Agile Documents

## Objetivo

Mostrar os documentos do projeto gerados pela IA.

## Documentos obrigatórios

```text
Business Vision
Functional Requirements
Non Functional Requirements
Stakeholders
Risk Map
Epics
User Stories
```

## Controles sugeridos

```text
PageControl pcAgileDocs
Memo memoBusinessVision
Memo memoFunctionalRequirements
Memo memoNonFunctionalRequirements
Memo memoStakeholders
Memo memoRiskMap
Memo memoEpics
Memo memoUserStories
Button btnExportAgileDocs
```

---

# Aba Agents

## Objetivo

Permitir criar agentes de projeto com perfis diferentes, associar esses agentes às tarefas e controlar o ciclo de vida das tarefas por ações.

## Perfis obrigatórios

```text
UI
DBA
DEV
Infra
Operador
Key User
Tester
Documentador
Gerente de Projeto
```

## Controles

```text
ListBox lstAgents
Edit edtAgentName
ComboBox cbAgentProfile
ComboBox cbAgentSkillLevel
Memo memoAgentDescription
Memo memoAgentResponsibilities
Memo memoAgentPrompt
CheckBox chkAgentActive
Button btnAddAgent
Button btnUpdateAgent
Button btnRemoveAgent
Button btnCreateDefaultAgents
Button btnAskAgentToAnalyzeTask
```

## Agentes padrão

O botão `Create Default Agents` deve criar:

```text
UI Agent
DBA Agent
DEV Agent
Infra Agent
Operator Agent
Key User Agent
Tester Agent
Documentation Agent
Project Manager Agent
```

---

## Perfis dos agentes

### UI

Responsável por:

```text
telas
fluxo visual
experiência do usuário
organização das abas
validação da interface
mensagens amigáveis
```

Prompt base:

```text
You are a UI specialist. Your responsibility is to analyze tasks related to screens, visual workflow, user interaction, usability and interface validation.
```

### DBA

Responsável por:

```text
banco de dados
estrutura de tabelas
índices
consultas
persistência
migração
integridade dos dados
```

Prompt base:

```text
You are a database specialist. Your responsibility is to analyze tasks related to data structure, persistence, SQL, indexes, migrations and data integrity.
```

### DEV

Responsável por:

```text
código-fonte
componentes
métodos
classes
eventos
integrações
refatoração
```

Prompt base:

```text
You are a software developer. Your responsibility is to analyze implementation tasks, component structure, source code, methods, events and integrations.
```

### Infra

Responsável por:

```text
ambiente
deploy
dependências
instalação
runtime
configuração de sistema
serviços externos
```

Prompt base:

```text
You are an infrastructure specialist. Your responsibility is to analyze environment, deployment, dependencies, runtime configuration and external services.
```

### Operador

Responsável por:

```text
uso do sistema
procedimentos operacionais
rotina do usuário
erros comuns
validação prática
```

Prompt base:

```text
You are an operational user. Your responsibility is to validate whether the project tasks are understandable and executable in a real usage routine.
```

### Key User

Responsável por:

```text
validar regra de negócio
confirmar se o fluxo atende o usuário final
aprovar requisitos
rejeitar funcionalidades inadequadas
sugerir ajustes
```

Prompt base:

```text
You are a key user. Your responsibility is to validate business rules, user needs, acceptance criteria and whether the delivered feature solves the real problem.
```

---

# Aba Tasks

## Objetivo

Listar, editar, controlar e acompanhar as tarefas do projeto.

## Colunas obrigatórias

```text
ID
Epic
Task
Description
Priority
Status
Dependency Type
Dependencies
Parallel
Intern Hours
Junior Hours
Mid Hours
Senior Hours
Suggested Level
Assigned Level
Assigned Agent
Responsible Profile
Review Agent
Duration Days
Planned Start
Planned End
Actual Start
Actual End
Progress %
Deliverable
Last Action
```

## Botões

```text
Add Task
Edit Task
Cancel Task
Recalculate Estimates
Apply Action
Ask Agent to Analyze Task
Export Tasks
```

## Regra

Remover uma tarefa não deve apagar a tarefa do histórico.

A tarefa deve ser marcada como:

```text
canceled
```

---

# Aba Task Actions

A aba `Task Actions` pode ser uma subaba ou painel dentro da aba `Tasks`.

## Objetivo

Permitir executar ações sobre tarefas.

## Ações obrigatórias

```text
Confirm Task
Reject Task
Start Task
Finish Task
```

## Ações recomendadas

```text
Cancel Task
Block Task
Unblock Task
Reopen Task
Comment Task
Request Revision
```

## Controles

```text
ComboBox cbSelectedTask
ComboBox cbSelectedAgent
ComboBox cbTaskAction
Memo memoActionComment
Edit edtActionDeliverable
Button btnApplyTaskAction
Memo memoTaskActionHistory
```

---

## Fluxo de status das tarefas

Status possíveis:

```text
draft
confirmed
rejected
pending
in_progress
blocked
in_review
done
canceled
reopened
```

Fluxo recomendado:

```text
draft -> confirmed -> pending -> in_progress -> in_review -> done
draft -> rejected
in_progress -> blocked
blocked -> in_progress
done -> reopened
any -> canceled
```

---

## Regras das ações

### Confirm Task

Efeito:

```text
status = confirmed
registrar agente que confirmou
registrar data/hora
registrar comentário opcional
```

Uso:

```text
O Key User ou Gerente confirma que a tarefa faz sentido e deve entrar no plano.
```

### Reject Task

Efeito:

```text
status = rejected
exigir motivo
não apagar a tarefa
registrar histórico
manter no projeto para auditoria
```

Uso:

```text
O Key User ou Gerente rejeita uma tarefa porque ela não faz parte do escopo ou está incorreta.
```

### Start Task

Efeito:

```text
status = in_progress
actual_start_date = now
progress_percent = 1
registrar agente responsável
```

Regra:

```text
Não permitir iniciar tarefa rejeitada, cancelada ou bloqueada.
Se houver dependência serial pendente, avisar o usuário.
```

### Finish Task

Efeito:

```text
status = done
actual_end_date = now
progress_percent = 100
registrar entregável
registrar comentário final
```

Regra:

```text
Não permitir finalizar sem informar entregável ou comentário de conclusão.
Se existir review_agent, enviar para in_review antes de done, se configurado.
```

---

## Permissões por perfil

### Key User

Pode:

```text
confirm_task
reject_task
request_revision
comment_task
```

### Gerente

Pode:

```text
confirm_task
reject_task
start_task
finish_task
cancel_task
block_task
unblock_task
reopen_task
request_revision
comment_task
```

### DEV

Pode:

```text
start_task
finish_task
block_task
comment_task
request_revision
```

### DBA

Pode:

```text
start_task
finish_task
block_task
comment_task
request_revision
```

### UI

Pode:

```text
start_task
finish_task
comment_task
request_revision
```

### Infra

Pode:

```text
start_task
finish_task
block_task
unblock_task
comment_task
request_revision
```

### Operador

Pode:

```text
comment_task
request_revision
confirm_task
reject_task
```

---

# Aba Dependencies

## Objetivo

Mostrar dependências seriais e tarefas paralelas.

## Controles

```text
ListBox lstSerialDependencies
ListBox lstParallelGroups
Memo memoDependencyExplanation
Button btnAnalyzeDependencies
Button btnExportDependencies
```

## Exemplo

```text
Serial:
T004 depends on T001
T005 depends on T004

Parallel:
Group P001: T002, T003, T006 can run in parallel after T001
```

A aba deve deixar claro:

```text
o que precisa ser feito em sequência
o que pode ser feito em paralelo
qual tarefa bloqueia outra
```

---

# Aba Execution Plan

## Objetivo

Mostrar a ordem sugerida de execução do projeto.

## Controles

```text
Memo memoExecutionPlan
Memo memoMilestones
Button btnRecalculateExecutionPlan
Button btnExportExecutionPlan
```

## Exemplo

```text
1. T001 - Create base component
2. T002 - Add Windows backend
3. T003 - Add Linux backend
4. T004 - Add WAV validation
5. T005 - Create visual demo
```

## Estimativas por perfil

Mostrar:

```text
Estimated duration with Senior: 3 days
Estimated duration with Mid-level: 5 days
Estimated duration with Junior: 8 days
Estimated duration with Intern: 14 days
```

---

# Aba Gantt

## Objetivo

Mostrar visualmente as tarefas no tempo.

## Controles

```text
ScrollBox sbGantt
PaintBox pbGantt
DateTimePicker dtGanttStart
DateTimePicker dtGanttEnd
ComboBox cbGanttScale
Button btnRecalculateSchedule
Button btnExportGantt
```

Escalas:

```text
Day
Week
Month
```

## O Gantt deve mostrar

```text
linha por tarefa
barra da data inicial até a data final
percentual de progresso
dependências entre tarefas
marcos/milestones
tarefas atrasadas
tarefas concluídas
tarefas bloqueadas
```

## Implementação inicial

Não precisa usar biblioteca externa.

Pode ser desenhado com:

```pascal
TPaintBox.Canvas
```

---

## Dados mínimos de Gantt

```json
{
  "task_id": "T001",
  "title": "",
  "start_date": "",
  "end_date": "",
  "progress_percent": 0,
  "status": "pending",
  "dependencies": [],
  "dependency_type": "serial"
}
```

---

# Aba Timeline

## Objetivo

Mostrar a história do projeto.

O Gantt mostra execução das tarefas no tempo.

A Timeline mostra a evolução do projeto:

```text
revisões
marcos
entregas
mudanças
ações de tarefa
riscos adicionados
alterações de prazo
```

## Controles

```text
PaintBox pbTimeline
ListBox lstTimelineEvents
Memo memoTimelineDetails
Button btnRefreshTimeline
Button btnExportTimeline
```

## Eventos esperados

```text
Revision 1 - Initial plan
Revision 2 - Added Linux support
Milestone M001 - Base component ready
Task T005 completed
Risk R002 added
Task T003 started by DEV Agent
Deadline changed
```

---

# Aba Revision

## Objetivo

Permitir aplicar correções incrementais ao projeto.

## Controles

```text
Memo memoCorrection
Button btnApplyCorrection
ListBox lstRevisions
Memo memoRevisionDetails
Button btnCompareRevisions
```

## Fluxo

```text
1. Usuário escreve uma correção.
2. Clica Apply Project Correction.
3. O componente envia o plano atual + correção para o LLM.
4. O LLM devolve JSON atualizado.
5. O componente cria nova revisão.
6. A tela atualiza documentos, tarefas, dependências, estimativas, Gantt e Timeline.
```

## Exemplo de correção

```text
Add support for Linux using arecord and add a task to validate if arecord is installed.
```

## Resultado esperado

```text
Revision 2 created.
2 new tasks added.
3 estimates updated.
1 dependency changed.
1 risk added.
Gantt recalculated.
Timeline updated.
```

---

# Aba JSON

## Objetivo

Mostrar o JSON atual do projeto.

## Controles

```text
Memo memoCurrentJSON
Button btnCopyJSON
Button btnSaveJSON
Button btnLoadJSON
```

O JSON deve sempre refletir o estado atual do projeto.

---

# Aba Log

## Objetivo

Mostrar eventos reais do sistema.

## Controles

```text
Memo memoLog
Button btnClearLog
```

## Logs esperados

```text
LLM configuration loaded.
Initial plan prompt generated.
Initial plan received.
JSON parsed successfully.
Revision 1 created.
Correction prompt generated.
Revision 2 created.
Tasks updated.
Dependencies recalculated.
Gantt recalculated.
Timeline updated.
Project saved.
Project loaded.
Agent created.
Task action applied.
```

---

# Persistência do projeto

## Extensão do arquivo

Usar:

```text
.aiproj.json
```

Exemplo:

```text
audio_capture_project.aiproj.json
```

## O projeto salvo deve preservar

```text
configuração do LLM
descrição do projeto
documentos ágeis
requisitos funcionais
requisitos não funcionais
visão de negócio
envolvidos
mapa de riscos
épicos
histórias
tarefas
dependências
estimativas
datas planejadas
datas reais
Gantt
Timeline
agentes
ações
histórico de ações
revisões
JSON atual
Markdown gerado
```

## Segurança

```text
O token só deve ser salvo se SaveToken=True.
Por padrão, SaveToken=False.
```

---

# Estrutura JSON do projeto

Estrutura mínima:

```json
{
  "file_version": "1.0",
  "saved_at": "",
  "project": {
    "name": "",
    "goal": "",
    "description": "",
    "context": "",
    "scope": "",
    "constraints": "",
    "expected_deliverables": "",
    "start_date": "",
    "target_end_date": "",
    "current_revision": 1
  },
  "llm_config": {
    "provider": "",
    "model": "",
    "model_version": "",
    "endpoint": "",
    "temperature": 0.2,
    "max_tokens": 8000,
    "save_token": false,
    "token": ""
  },
  "agile_documents": {
    "business_vision": "",
    "functional_requirements": [],
    "non_functional_requirements": [],
    "stakeholders": [],
    "risk_map": [],
    "epics": [],
    "user_stories": []
  },
  "agents": [],
  "planning": {
    "calendar": {
      "hours_per_day": 6,
      "working_days": ["mon", "tue", "wed", "thu", "fri"]
    },
    "team_profile": {
      "intern_count": 0,
      "junior_count": 1,
      "mid_level_count": 1,
      "senior_count": 1
    },
    "tasks": [],
    "dependencies": [],
    "execution_plan": [],
    "parallel_groups": [],
    "milestones": [],
    "gantt": [],
    "timeline": []
  },
  "task_actions": [],
  "agent_task_analysis": [],
  "revisions": [],
  "last_generated_json": "",
  "last_generated_markdown": ""
}
```

---

# Estrutura de tarefa

Cada tarefa deve conter:

```json
{
  "id": "T001",
  "epic_id": "E001",
  "title": "",
  "description": "",
  "acceptance_criteria": "",
  "priority": "high",
  "status": "pending",
  "dependency_type": "serial",
  "dependencies": [],
  "blocked_by": [],
  "can_run_in_parallel": false,
  "estimated_hours": {
    "intern": 0,
    "junior": 0,
    "mid_level": 0,
    "senior": 0
  },
  "suggested_skill_level": "mid_level",
  "assigned_skill_level": "mid_level",
  "assigned_to": "",
  "assigned_agent_id": "",
  "assigned_agent_name": "",
  "responsible_profile": "",
  "review_agent_id": "",
  "review_agent_name": "",
  "planned_start_date": "",
  "planned_end_date": "",
  "actual_start_date": "",
  "actual_end_date": "",
  "estimated_duration_days": 0,
  "progress_percent": 0,
  "deliverable": "",
  "risk": "",
  "notes": "",
  "revision_created": 1,
  "revision_updated": 1
}
```

---

# Estrutura de agente

```json
{
  "id": "AG001",
  "name": "DEV Agent",
  "profile": "DEV",
  "description": "Responsible for software development tasks.",
  "skill_level": "senior",
  "responsibilities": [],
  "allowed_actions": [
    "start_task",
    "finish_task",
    "block_task",
    "comment_task",
    "request_revision"
  ],
  "system_prompt": "",
  "active": true
}
```

---

# Estrutura de ação

```json
{
  "id": "ACT001",
  "task_id": "T001",
  "agent_id": "AG003",
  "agent_name": "DEV Agent",
  "action": "start_task",
  "date": "2026-06-20T15:30:00",
  "comment": "Started implementation.",
  "old_status": "confirmed",
  "new_status": "in_progress",
  "revision": 2
}
```

---

# Estrutura de evento da timeline

```json
{
  "id": "EV001",
  "date": "",
  "type": "revision",
  "title": "",
  "description": "",
  "related_id": "",
  "revision": 1
}
```

Tipos de evento:

```text
revision
milestone
task
task_action
risk
deadline
note
```

---

# Estrutura de milestone

```json
{
  "id": "M001",
  "title": "Base component completed",
  "description": "",
  "target_date": "",
  "status": "pending",
  "related_tasks": ["T001", "T002"]
}
```

---

# Métodos principais do TAIProject

Adicionar ao componente:

```pascal
function BuildInitialPlanningPrompt: string;
function BuildRevisionPrompt(const AUserCorrection: string): string;

function GenerateInitialPlan: Boolean;
function ApplyProjectCorrection(const ACorrection: string): Boolean;
function AnalyzeDependencies: Boolean;
function RecalculateEstimates: Boolean;
function RecalculateSchedule: Boolean;

function LoadPlanFromJSON(const AJSON: string): Boolean;
function ExportPlanToJSON: string;
function ExportPlanToMarkdown: string;

function SaveProjectToFile(const AFileName: string): Boolean;
function LoadProjectFromFile(const AFileName: string): Boolean;
function AutoSaveProject: Boolean;

function AddRevision(const ATitle, AInputText, AGeneratedJSON: string): Integer;
function GetRevisionMarkdown(ARevisionIndex: Integer): string;

function ApplyTaskAction(
  const ATaskID: string;
  const AAgentID: string;
  const AAction: TAIProjectTaskAction;
  const AComment: string;
  const ADeliverable: string
): Boolean;

function AskAgentToAnalyzeTask(
  const ATaskID: string;
  const AAgentID: string
): Boolean;
```

---

# Recalcular cronograma

Criar método:

```pascal
function RecalculateSchedule: Boolean;
```

O cálculo deve considerar:

```text
data inicial do projeto
horas por dia
nível de conhecimento atribuído
estimativa de horas da tarefa
dependências seriais
tarefas paralelas
dias úteis
status da tarefa
tarefas bloqueadas
```

Regra inicial:

```text
Se a tarefa não tem dependências, pode começar na data inicial do projeto.
Se depende de outra tarefa serial, começa depois da data final da dependência.
Se pode rodar em paralelo, começa junto com o grupo permitido.
Duração em dias = horas estimadas / horas por dia.
```

A estimativa deve usar o nível atribuído:

```text
intern
junior
mid_level
senior
```

Exemplo:

```text
Tarefa T001
Senior: 4h
Mid-level: 6h
Junior: 10h
Intern: 16h

Se assigned_skill_level = junior e hours_per_day = 6:
duration_days = 10 / 6 = 1.67 dias
```

---

# Prompt inicial de planejamento

Criar método:

```pascal
function BuildInitialPlanningPrompt: string;
```

Prompt base:

```text
You are an AI project planner.

Your job is to transform a project description into a complete agile project plan.

Return only valid JSON.

The JSON must contain:

{
  "project": {
    "name": "",
    "goal": "",
    "summary": "",
    "business_vision": "",
    "scope": "",
    "out_of_scope": []
  },
  "stakeholders": [
    {
      "name": "",
      "role": "",
      "responsibility": ""
    }
  ],
  "functional_requirements": [
    {
      "id": "RF001",
      "title": "",
      "description": "",
      "priority": "high|medium|low"
    }
  ],
  "non_functional_requirements": [
    {
      "id": "RNF001",
      "title": "",
      "description": "",
      "priority": "high|medium|low"
    }
  ],
  "risks": [
    {
      "id": "R001",
      "title": "",
      "description": "",
      "impact": "high|medium|low",
      "probability": "high|medium|low",
      "mitigation": ""
    }
  ],
  "epics": [
    {
      "id": "E001",
      "title": "",
      "description": ""
    }
  ],
  "tasks": [
    {
      "id": "T001",
      "epic_id": "E001",
      "title": "",
      "description": "",
      "acceptance_criteria": "",
      "priority": "high|medium|low",
      "status": "draft",
      "dependency_type": "serial|parallel",
      "dependencies": [],
      "can_run_in_parallel": true,
      "estimated_hours": {
        "intern": 0,
        "junior": 0,
        "mid_level": 0,
        "senior": 0
      },
      "suggested_skill_level": "intern|junior|mid_level|senior",
      "responsible_profile": "UI|DBA|DEV|Infra|Operador|Key User|Tester|Documentador|Gerente",
      "estimated_duration_days": 0,
      "deliverable": "",
      "notes": ""
    }
  ],
  "execution_plan": [],
  "parallel_groups": [],
  "milestones": [],
  "revision": {
    "number": 1,
    "title": "Initial project plan",
    "summary": ""
  }
}
```

---

# Prompt incremental de revisão

Criar método:

```pascal
function BuildRevisionPrompt(const AUserCorrection: string): string;
```

Prompt base:

```text
You are revising an existing agile project plan.

You will receive:

1. Current project JSON.
2. Revision history.
3. User correction.

Update the project plan incrementally.

Rules:

- Preserve task IDs when the task still represents the same work.
- Add new tasks only when needed.
- Mark removed tasks as canceled instead of deleting them.
- Update dependencies when requirements change.
- Recalculate estimates when task complexity changes.
- Update risks when new risks appear.
- Update Gantt data when dates or dependencies change.
- Update timeline events.
- Create a new revision entry.
- Return only valid JSON.
```

---

# Prompt de agente

Criar prompt para análise de tarefa por agente:

```text
You are the project agent below.

Agent profile:
{agent_profile}

Agent responsibilities:
{agent_responsibilities}

Project context:
{project_context}

Task:
{task_title}
{task_description}

Dependencies:
{task_dependencies}

Expected deliverable:
{task_deliverable}

Analyze this task from your profile perspective.

Return:

{
  "task_id": "",
  "agent_id": "",
  "analysis": "",
  "suggested_steps": [],
  "risks": [],
  "questions": [],
  "recommended_action": "confirm_task|reject_task|start_task|request_revision"
}
```

Regra:

```text
A IA pode sugerir uma ação.
A ação não deve ser aplicada automaticamente.
O usuário precisa confirmar clicando em Apply Action.
```

---

# Exportações

O sample deve permitir exportar:

```text
Project JSON
Project Markdown
Agile documents Markdown
Tasks CSV
Gantt CSV
Gantt Markdown
Timeline CSV
Timeline Markdown
Revision history Markdown
```

---

# Exportação do Gantt

CSV:

```csv
task_id,title,start_date,end_date,status,progress_percent,dependencies
T001,Create base component,2026-06-20,2026-06-21,pending,0,
```

Markdown:

```markdown
# Project Gantt

| Task | Start | End | Status | Progress | Dependencies |
|---|---|---|---|---|---|
| T001 | 2026-06-20 | 2026-06-21 | pending | 0% | |
```

---

# Exportação da Timeline

Markdown:

```markdown
# Project Timeline

## 2026-06-20

- Revision 1: Initial project plan
- Task T001 created
- Risk R001 added
```

---

# Tarefas pequenas para o bot

## Etapa 1

Criar a pasta:

```text
pacote/samples/AI Project/Demo_AI_Project
```

## Etapa 2

Criar arquivos:

```text
Demo_AI_Project.lpi
Demo_AI_Project.lpr
main.pas
main.lfm
README.md
```

## Etapa 3

Alterar registro do `TAIProject` para a aba `AI Project`.

## Etapa 4

Adicionar propriedades de planejamento ao `TAIProject`.

## Etapa 5

Adicionar estruturas de tarefas, agentes, revisões, timeline e Gantt.

## Etapa 6

Implementar `SaveProjectToFile`.

## Etapa 7

Implementar `LoadProjectFromFile`.

## Etapa 8

Implementar `BuildInitialPlanningPrompt`.

## Etapa 9

Implementar `BuildRevisionPrompt`.

## Etapa 10

Implementar `GenerateInitialPlan`.

## Etapa 11

Implementar `ApplyProjectCorrection`.

## Etapa 12

Implementar `RecalculateSchedule`.

## Etapa 13

Implementar `ApplyTaskAction`.

## Etapa 14

Implementar `AskAgentToAnalyzeTask`.

## Etapa 15

Criar formulário visual com abas.

## Etapa 16

Criar aba Configuration.

## Etapa 17

Criar aba Project Description.

## Etapa 18

Criar aba Agile Documents.

## Etapa 19

Criar aba Agents.

## Etapa 20

Criar aba Tasks.

## Etapa 21

Criar painel Task Actions.

## Etapa 22

Criar aba Dependencies.

## Etapa 23

Criar aba Execution Plan.

## Etapa 24

Criar aba Gantt.

## Etapa 25

Criar aba Timeline.

## Etapa 26

Criar aba Revision.

## Etapa 27

Criar aba JSON.

## Etapa 28

Criar aba Log.

## Etapa 29

Implementar exportação JSON, Markdown e CSV.

## Etapa 30

Atualizar README.md do sample.

---

# Checklist final

Antes de finalizar, verificar:

```text
[ ] Existe Demo_AI_Project como subpasta de AI Project.
[ ] O demo é visual.
[ ] Não usa WriteLn/ReadLn.
[ ] Existe aba Configuration.
[ ] É possível selecionar LLM provider.
[ ] É possível configurar token.
[ ] É possível configurar modelo e versão.
[ ] Existe aba Project Description.
[ ] Existe aba Agile Documents.
[ ] Gera visão de negócio.
[ ] Gera requisitos funcionais.
[ ] Gera requisitos não funcionais.
[ ] Gera envolvidos.
[ ] Gera mapa de riscos.
[ ] Gera épicos ou histórias.
[ ] Existe aba Agents.
[ ] É possível criar agentes manualmente.
[ ] É possível criar agentes padrão.
[ ] Existem perfis UI, DBA, DEV, Infra, Operador e Key User.
[ ] Cada agente tem prompt próprio.
[ ] Cada agente tem permissões.
[ ] Tarefas podem ser associadas a agentes.
[ ] Existe aba Tasks.
[ ] Cada tarefa tem dependências.
[ ] Cada tarefa indica serial ou paralela.
[ ] Cada tarefa estima esforço para Estagiário, Jr, Pleno e Sênior.
[ ] Cada tarefa estima prazo.
[ ] Existe painel Task Actions.
[ ] É possível confirmar tarefa.
[ ] É possível rejeitar tarefa.
[ ] É possível iniciar tarefa.
[ ] É possível finalizar tarefa.
[ ] Histórico de ações é salvo.
[ ] Timeline registra ações.
[ ] Gantt reflete status das tarefas.
[ ] Existe aba Dependencies.
[ ] Existe aba Execution Plan.
[ ] Existe aba Gantt.
[ ] O Gantt mostra tarefas no tempo.
[ ] O Gantt mostra dependências.
[ ] O Gantt mostra progresso.
[ ] Existe aba Timeline.
[ ] A Timeline mostra revisões.
[ ] A Timeline mostra marcos.
[ ] A Timeline mostra alterações importantes.
[ ] Existe aba Revision.
[ ] Correções criam novas revisões.
[ ] O histórico de revisão é preservado.
[ ] Existe aba JSON.
[ ] Existe exportação Markdown.
[ ] Existe exportação JSON.
[ ] Existe exportação CSV de tarefas.
[ ] O projeto pode ser salvo em .aiproj.json.
[ ] O projeto pode ser carregado depois.
[ ] As tarefas são preservadas ao carregar.
[ ] As dependências são preservadas ao carregar.
[ ] O histórico de revisões é preservado.
[ ] A configuração do LLM é preservada.
[ ] O token só é salvo se SaveToken=True.
[ ] README explica o propósito correto.
```

---

# Resultado esperado

O `Demo_AI_Project` deve permitir este fluxo completo:

```text
1. Criar projeto.
2. Configurar LLM.
3. Descrever objetivo.
4. Gerar plano inicial.
5. Ver documentos ágeis.
6. Ver tarefas.
7. Criar agentes.
8. Associar agentes às tarefas.
9. Controlar ações das tarefas.
10. Ver dependências.
11. Ver cronograma em Gantt.
12. Ver histórico na Timeline.
13. Salvar projeto.
14. Fechar aplicação.
15. Abrir outro dia.
16. Carregar projeto.
17. Continuar análise.
18. Aplicar correções.
19. Criar nova revisão.
20. Recalcular Gantt.
21. Atualizar Timeline.
22. Salvar novamente.
```

---

# Conclusão

O `Demo_AI_Project` deve demonstrar que o componente `TAIProject` pode ser usado como um **planejador incremental e persistente de projetos com IA**.

Ele deve unir:

```text
planejamento
documentação ágil
extração de tarefas
dependências
estimativas
agentes
ações
Gantt
Timeline
revisões
persistência
```

O resultado final não é apenas um prompt.

O resultado final é um projeto vivo, que pode ser salvo, carregado, revisado e acompanhado ao longo do tempo.


---

# Ajuste importante: este projeto é um DEMO de componentes

Este projeto **não deve ser tratado como uma aplicação final de gestão de projetos**.

Ele é um **demo visual do pacote CHATGPT**, criado para demonstrar o maior número possível de componentes relacionados a planejamento, documentação, execução e acompanhamento de projetos com IA.

A prioridade do `Demo_AI_Project` é mostrar como os componentes podem ser usados em Lazarus / Free Pascal.

Portanto, sempre que uma funcionalidade puder ser representada por um componente visual ou não visual reutilizável, deve ser criado um componente próprio.

O sample deve usar esses componentes na tela para demonstrar seu funcionamento.

---

## Regra central do demo

O `Demo_AI_Project` deve ser construído como uma vitrine de componentes.

Não concentrar toda a lógica no `main.pas`.

Evitar criar uma aplicação monolítica.

A estrutura correta é:

```text
componentes especializados
+
demo visual usando esses componentes
```

O formulário principal deve apenas integrar e demonstrar os componentes.

---

## Componentes que devem ser criados ou organizados

Criar componentes específicos para cada área do projeto.

### 1. Componente principal de projeto

```pascal
TAIProject
```

Responsabilidade:

```text
armazenar o projeto
controlar revisão
salvar projeto
carregar projeto
gerar plano inicial
aplicar correções incrementais
manter estado geral do projeto
```

---

### 2. Componente de configuração LLM

```pascal
TAIProjectLLMConfig
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
provider
token
modelo
versão do modelo
endpoint
temperatura
max tokens
save token
teste de conexão
```

Pode ser usado pela aba `Configuration`.

---

### 3. Componente visual de configuração LLM

```pascal
TAIProjectLLMConfigFrame
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TFrame
```

Responsabilidade:

```text
mostrar campos de configuração do LLM
validar configuração
atualizar TAIProjectLLMConfig
```

---

### 4. Componente de descrição do projeto

```pascal
TAIProjectDescription
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
nome do projeto
objetivo
contexto
escopo
restrições
entregáveis esperados
data inicial
data final desejada
```

---

### 5. Componente visual de descrição do projeto

```pascal
TAIProjectDescriptionFrame
```

Tipo:

```text
visual
```

Responsabilidade:

```text
permitir o preenchimento visual da descrição do projeto
atualizar o componente TAIProjectDescription
```

---

### 6. Componente de requisitos funcionais

```pascal
TAIFunctionalRequirements
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar requisitos funcionais
gerar requisitos via IA
editar requisitos
exportar requisitos
```

Item de requisito:

```text
id
título
descrição
prioridade
origem
status
revisão criada
revisão alterada
```

---

### 7. Componente visual de requisitos funcionais

```pascal
TAIFunctionalRequirementsGrid
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TStringGrid
```

Responsabilidade:

```text
exibir requisitos funcionais
permitir edição visual
destacar requisitos novos, alterados e cancelados
```

---

### 8. Componente de requisitos não funcionais

```pascal
TAINonFunctionalRequirements
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar requisitos de desempenho
segurança
usabilidade
compatibilidade
manutenibilidade
portabilidade
confiabilidade
```

---

### 9. Componente visual de requisitos não funcionais

```pascal
TAINonFunctionalRequirementsGrid
```

Tipo:

```text
visual
```

Responsabilidade:

```text
exibir e editar requisitos não funcionais
```

---

### 10. Componente de visão de negócio

```pascal
TAIBusinessVision
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar visão de negócio
problema
objetivo
valor entregue
benefícios esperados
público-alvo
indicadores de sucesso
```

---

### 11. Componente visual de visão de negócio

```pascal
TAIBusinessVisionEditor
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TFrame
```

Responsabilidade:

```text
editar e exibir a visão de negócio
```

---

### 12. Componente de envolvidos

```pascal
TAIStakeholders
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar envolvidos
papéis
responsabilidades
interesses
nível de influência
nível de impacto
```

---

### 13. Componente visual de envolvidos

```pascal
TAIStakeholderGrid
```

Tipo:

```text
visual
```

Responsabilidade:

```text
mostrar envolvidos em grade
permitir edição
permitir classificação por papel
```

---

### 14. Componente de mapa de riscos

```pascal
TAIRiskMap
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar riscos
impacto
probabilidade
mitigação
plano de contingência
status
```

---

### 15. Componente visual de mapa de riscos

```pascal
TAIRiskMapGrid
```

Tipo:

```text
visual
```

Responsabilidade:

```text
exibir riscos em grade
destacar riscos altos
permitir edição
```

---

### 16. Componente visual de matriz de riscos

```pascal
TAIRiskMatrix
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TPaintBox
```

Responsabilidade:

```text
desenhar matriz impacto x probabilidade
posicionar riscos na matriz
destacar criticidade
```

---

### 17. Componente de tarefas

```pascal
TAIProjectTasks
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar tarefas
subtarefas
status
dependências
estimativas
responsáveis
agentes
datas
progresso
```

---

### 18. Componente visual de tarefas

```pascal
TAIProjectTaskGrid
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TStringGrid
```

Responsabilidade:

```text
exibir tarefas
editar tarefas
mostrar status
mostrar estimativas por perfil
mostrar agentes responsáveis
mostrar dependências
```

---

### 19. Componente de dependências

```pascal
TAIProjectDependencies
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar dependências
classificar dependência serial ou paralela
validar ciclos
identificar tarefas bloqueadas
```

---

### 20. Componente visual de dependências

```pascal
TAIDependencyViewer
```

Tipo:

```text
visual
```

Responsabilidade:

```text
mostrar dependências seriais
mostrar grupos paralelos
mostrar bloqueios
explicar o motivo das dependências
```

---

### 21. Componente de Gantt

```pascal
TAIProjectGantt
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TCustomControl
```

Responsabilidade:

```text
desenhar gráfico de Gantt
mostrar tarefas no tempo
mostrar barras de progresso
mostrar dependências
mostrar tarefas bloqueadas
mostrar tarefas concluídas
mostrar marcos
```

Propriedades sugeridas:

```pascal
property Project: TAIProject;
property StartDate: TDateTime;
property EndDate: TDateTime;
property Scale: TAIProjectGanttScale;
property ShowDependencies: Boolean;
property ShowProgress: Boolean;
property ShowMilestones: Boolean;
```

---

### 22. Componente de Timeline

```pascal
TAIProjectTimeline
```

Tipo:

```text
visual
```

Herança sugerida:

```pascal
TCustomControl
```

Responsabilidade:

```text
desenhar linha do tempo do projeto
mostrar revisões
mostrar marcos
mostrar ações de tarefas
mostrar mudanças importantes
mostrar riscos adicionados
```

---

### 23. Componente de revisões

```pascal
TAIProjectRevisions
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar histórico de revisões
comparar revisões
manter motivo da revisão
manter entrada textual da correção
manter resumo das alterações
```

---

### 24. Componente visual de revisões

```pascal
TAIRevisionViewer
```

Tipo:

```text
visual
```

Responsabilidade:

```text
listar revisões
mostrar detalhes
comparar revisão anterior e atual
```

---

### 25. Componente de agentes

```pascal
TAIProjectAgents
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar agentes
perfis
permissões
prompts
ações permitidas
tarefas associadas
```

---

### 26. Componente visual de agentes

```pascal
TAIAgentManagerFrame
```

Tipo:

```text
visual
```

Responsabilidade:

```text
criar agentes
editar agentes
criar agentes padrão
mostrar permissões
mostrar prompt do agente
```

---

### 27. Componente de ações de tarefas

```pascal
TAITaskActions
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
aplicar ações em tarefas
validar permissões
alterar status
registrar histórico
criar eventos na timeline
```

---

### 28. Componente visual de ações de tarefas

```pascal
TAITaskActionPanel
```

Tipo:

```text
visual
```

Responsabilidade:

```text
selecionar tarefa
selecionar agente
selecionar ação
informar comentário
informar entregável
aplicar ação
mostrar histórico de ações
```

---

### 29. Componente de relatórios do projeto

```pascal
TAIProjectReports
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
gerar relatório do projeto
gerar relatório de tarefas
gerar relatório de riscos
gerar relatório de revisões
gerar relatório de Gantt
gerar relatório de agentes
exportar Markdown
exportar CSV
exportar JSON
```

---

### 30. Componente visual de relatórios

```pascal
TAIProjectReportViewer
```

Tipo:

```text
visual
```

Responsabilidade:

```text
visualizar relatórios
selecionar tipo de relatório
exportar relatório
copiar relatório
```

---

### 31. Componente de documentos ágeis

```pascal
TAIAgileDocuments
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
armazenar documentos ágeis
visão de negócio
requisitos funcionais
requisitos não funcionais
envolvidos
riscos
épicos
histórias de usuário
```

---

### 32. Componente visual de documentos ágeis

```pascal
TAIAgileDocumentsViewer
```

Tipo:

```text
visual
```

Responsabilidade:

```text
mostrar documentos ágeis em abas
permitir exportação
permitir edição
```

---

### 33. Componente de persistência

```pascal
TAIProjectStorage
```

Tipo:

```text
não visual
```

Responsabilidade:

```text
salvar .aiproj.json
carregar .aiproj.json
validar versão do arquivo
controlar autosave
controlar segurança do token
```

---

### 34. Componente visual de status do projeto

```pascal
TAIProjectStatusPanel
```

Tipo:

```text
visual
```

Responsabilidade:

```text
mostrar total de tarefas
tarefas concluídas
tarefas em andamento
tarefas bloqueadas
percentual de progresso
revisão atual
último salvamento
```

---

## Organização sugerida dos componentes

Criar pasta:

```text
pacote/AI Project
```

Dentro dela, organizar os componentes:

```text
aiproject.pas
aiproject_llmconfig.pas
aiproject_description.pas
aiproject_requirements.pas
aiproject_risks.pas
aiproject_stakeholders.pas
aiproject_tasks.pas
aiproject_dependencies.pas
aiproject_gantt.pas
aiproject_timeline.pas
aiproject_revisions.pas
aiproject_agents.pas
aiproject_actions.pas
aiproject_reports.pas
aiproject_storage.pas
aiproject_visualframes.pas
```

Ou, se preferir separar visual e não visual:

```text
pacote/AI Project/Core
pacote/AI Project/Visual
pacote/AI Project/Reports
pacote/AI Project/Storage
```

---

## Pacote Lazarus

Criar ou ajustar o pacote:

```text
openai_project.lpk
```

O pacote deve registrar os componentes visuais e não visuais na aba:

```text
AI Project
```

---

## Papel do Demo_AI_Project

O demo deve usar o maior número possível dos componentes acima.

O formulário principal deve funcionar como vitrine.

Exemplo:

```pascal
AIProject1: TAIProject;
AIProjectStorage1: TAIProjectStorage;
AIProjectLLMConfig1: TAIProjectLLMConfig;
AIAgileDocuments1: TAIAgileDocuments;
AIProjectTasks1: TAIProjectTasks;
AIProjectDependencies1: TAIProjectDependencies;
AIProjectAgents1: TAIProjectAgents;
AITaskActions1: TAITaskActions;
AIProjectReports1: TAIProjectReports;

AIProjectStatusPanel1: TAIProjectStatusPanel;
AIProjectTaskGrid1: TAIProjectTaskGrid;
AIProjectGantt1: TAIProjectGantt;
AIProjectTimeline1: TAIProjectTimeline;
TAIRiskMatrix1: TAIRiskMatrix;
TAIAgentManagerFrame1: TAIAgentManagerFrame;
TAITaskActionPanel1: TAITaskActionPanel;
```

O `main.pas` não deve conter toda a regra de negócio.

O `main.pas` deve apenas:

```text
ligar componentes
responder eventos
atualizar abas
chamar métodos dos componentes
```

---

## Regra para criação de novos componentes

Sempre que existir uma parte reutilizável do projeto, criar componente.

Exemplos:

```text
Se existe lista de tarefas, criar TAIProjectTaskGrid.
Se existe Gantt, criar TAIProjectGantt.
Se existe timeline, criar TAIProjectTimeline.
Se existe mapa de riscos, criar TAIRiskMatrix.
Se existe relatório, criar TAIProjectReports.
Se existe persistência, criar TAIProjectStorage.
Se existe agente, criar TAIProjectAgents.
Se existe ação de tarefa, criar TAITaskActions.
```

---

## Checklist adicional

Adicionar ao checklist final:

```text
[ ] O sample é claramente um demo de componentes, não uma aplicação final.
[ ] Existe pacote ou área AI Project.
[ ] O maior número possível de funcionalidades foi separado em componentes.
[ ] Existe componente para projeto.
[ ] Existe componente para configuração LLM.
[ ] Existe componente para descrição do projeto.
[ ] Existe componente para requisitos funcionais.
[ ] Existe componente para requisitos não funcionais.
[ ] Existe componente para visão de negócio.
[ ] Existe componente para envolvidos.
[ ] Existe componente para mapa de riscos.
[ ] Existe componente visual para matriz de riscos.
[ ] Existe componente para tarefas.
[ ] Existe componente visual de tarefas.
[ ] Existe componente para dependências.
[ ] Existe componente visual de dependências.
[ ] Existe componente visual de Gantt.
[ ] Existe componente visual de Timeline.
[ ] Existe componente para revisões.
[ ] Existe componente visual de revisões.
[ ] Existe componente para agentes.
[ ] Existe componente visual de agentes.
[ ] Existe componente para ações de tarefas.
[ ] Existe componente visual para ações de tarefas.
[ ] Existe componente para relatórios.
[ ] Existe componente visual para relatórios.
[ ] Existe componente de persistência.
[ ] Existe componente visual de status do projeto.
[ ] O Demo_AI_Project instancia e usa os componentes.
[ ] O main.pas não concentra toda a regra de negócio.
[ ] Os componentes podem ser reutilizados em outros projetos Lazarus.
```

---

## Resultado esperado deste ajuste

O `Demo_AI_Project` deve deixar claro que:

```text
não é uma aplicação final
é uma demonstração visual dos componentes AI Project
```

Ele deve demonstrar uma família de componentes para:

```text
planejamento
requisitos
tarefas
agentes
dependências
ações
Gantt
Timeline
relatórios
persistência
revisões
```

O objetivo é que o desenvolvedor veja o demo e entenda como usar esses componentes em suas próprias aplicações Lazarus.
