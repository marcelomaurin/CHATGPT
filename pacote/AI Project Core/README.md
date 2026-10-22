# ⚙️ AI Project Core — Núcleo de Modelagem, Grafos e Cronogramas

A pasta **`pacote/AI Project Core/`** contém o motor matemático e as estruturas de dados fundamentais para planejamento de projetos, gerenciamento de dependências e cálculo de caminho crítico (CPM). Estes componentes compõem o pacote Lazarus [**`openai_project_core.lpk`**](../packages/openai_project_core.lpk).

---

## 🎯 Propósito do Módulo

Fornecer uma camada agnóstica de UI (sem dependência de formulários LCL) capaz de ser executada tanto no Lazarus desktop quanto em serviços console, servidores ou daemons em segundo plano:
- **Cálculo de Caminho Crítico (CPM):** Determinação de folgas livres/totais, datas de início mais cedo/tarde e identificação exata das tarefas críticas.
- **Grafo de Dependências com Detecção de Ciclos:** Validação de vínculos término-a-início (FS), início-a-início (SS), término-a-término (FF) e início-a-término (SF) com latências (lead/lag).
- **Calendário de Trabalho e Feriados:** Contabilização de dias úteis, jornadas de trabalho e feriados móveis/fixos nacionais.
- **Histórico de Desfazer/Refazer (Undo/Redo):** Gerenciamento determinístico de alterações de projeto em memória.
- **Serialização JSON:** Carga e salvamento com preservação de integridade em formato leve e interoperável.

---

## 📂 Arquivos Fontes e Componentes

| Arquivo | Componente / Classe | Descrição |
|---|---|---|
| [`aicpmscheduler.pas`](aicpmscheduler.pas) | [`TAICPMScheduler`](aicpmscheduler.pas) | Algoritmo do Caminho Crítico (Critical Path Method). Calcula Early Start, Early Finish, Late Start, Late Finish, Total Float e Free Float. |
| [`aitaskgraph.pas`](aitaskgraph.pas) | [`TAITaskGraph`](aitaskgraph.pas) | Grafo direcionado de dependências entre tarefas, com ordenação topológica e validação de ciclos acíclicos (DAG). |
| [`aiworkcalendar.pas`](aiworkcalendar.pas) | [`TAIWorkCalendar`](aiworkcalendar.pas) | Calendário operacional: calcula datas úteis, horas úteis por dia, finais de semana e feriados nacionais. |
| [`aiprojectduration.pas`](aiprojectduration.pas) | [`TAIProjectDuration`](aiprojectduration.pas) | Modelagem de durações em horas, dias, semanas ou meses úteis com conversão precisa. |
| [`airesourceload.pas`](airesourceload.pas) | [`TAIResourceLoad`](airesourceload.pas) | Análise de capacidade e alocação de recursos humanos/máquinas, detectando superalocação e nivelamento. |
| [`aiundohistory.pas`](aiundohistory.pas) | [`TAIUndoHistory`](aiundohistory.pas) | Pilha transacional de desfazer/refazer para edições de projetos e tarefas. |
| [`aijsonutils.pas`](aijsonutils.pas) | [`TAIJsonUtils`](aijsonutils.pas) | Helpers para serialização de documentos de projetos, cronogramas e grafos em JSON. |
| [`aiproject_core.pas`](aiproject_core.pas) | `openai_project_core` | Unit de registro do pacote. |

---

## 🧪 Testes Automatizados Disponíveis

- [**`tests/test_aicpmscheduler.lpr`**](../../tests/test_aicpmscheduler.lpr): Validação do algoritmo CPM com 12+ cenários de teste de folgas e caminho crítico.
- [**`tests/test_aitaskgraph.lpr`**](../../tests/test_aitaskgraph.lpr): Validação com 61 verificações de ciclos, vínculos e ordenação topológica.
- [**`tests/test_aiworkcalendar.lpr`**](../../tests/test_aiworkcalendar.lpr): Teste de dias úteis e feriados nacionais.
- [**`tests/test_airesourceload.lpr`**](../../tests/test_airesourceload.lpr): Teste de nivelamento e histograma de carga de recursos.