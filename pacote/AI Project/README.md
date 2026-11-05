# 📊 AI Project — Visualizações de Cronogramas, Gantt, Redes e Recursos

A pasta **`pacote/AI Project/`** reúne os componentes visuais avançados para interface com o usuário (LCL) que renderizam grafos, diagramas de Gantt, painéis Kanban/Board e histogramas de recursos. Estes componentes compõem o pacote Lazarus [**`openai_project.lpk`**](../packages/openai_project.lpk).

---

## 🎯 Propósito do Módulo

Permitir que sistemas Lazarus desktop exibam e manipulem projetos complexos com renderização suave e direta em Canvas:
- **Diagrama de Gantt Interativo:** Visualização de barras de tarefas, progresso percentual, caminho crítico em destaque e vínculos de dependência com setas direcionais.
- **Diagrama de Rede (PERT / CPM):** Nodos de atividades em blocos contendo datas mais cedo/tarde, folga e identificação de rotas críticas.
- **Quadro de Tarefas (Kanban / Board):** Colunas categorizadas por status (A Fazer, Em Andamento, Concluído) com cartões arrastáveis e rolagem horizontal.
- **Visão de Recursos e Planejador de Equipe:** Histograma de alocação de equipe por período com alertas visuais de sobrecarga de horas.

---

## 📂 Componentes Visuais Implementados

| Arquivo | Componente Visual | Descrição e Recursos Visuais |
|---|---|---|
| [`aiganttview.pas`](aiganttview.pas) | [`TAIGanttView`](aiganttview.pas) | Gráfico de Gantt completo em LCL. Suporta zoom diário/semanal/mensal, rolagem horizontal/vertical, pintura de vínculos FS/SS/FF/SF e realce de caminho crítico. |
| [`ainetworkview.pas`](ainetworkview.pas) | [`TAINetworkView`](ainetworkview.pas) | Diagrama de rede de atividades (Activity-on-Node). Renderiza caixas informativas e conectores com layout legível. |
| [`aiboardview.pas`](aiboardview.pas) | [`TAIBoardView`](aiboardview.pas) | Quadro visual estilo Kanban com colunas de status, contadores de cartões, rolagem e cartões com etiquetas no topo. |
| [`airesourceview.pas`](airesourceview.pas) | [`TAIResourceView`](airesourceview.pas) | Planejador de equipe e histograma de carga de recursos com identificação de superalocação. |
| [`aiproject.pas`](aiproject.pas) | [`TAIProject`](aiproject.pas) | Componente integrador de projeto de IA com suporte a tarefas, riscos, agentes e armazenamento. |

---

## 🎮 Exemplos e Demonstrações Práticas

- [**`Demo_AI_Project`**](../samples/AI%20Project/Demo_AI_Project/): Exemplo visual integrando todas as vistas (`TAIGanttView`, `TAINetworkView`, `TAIBoardView` e `TAIResourceView`) sincronizadas com um projeto central.
- [**`framework_graph_explorer`**](../samples/AI%20Project/framework_graph_explorer/): Aplicação visual de diagnóstico para inspecionar o grafo factual de dependências dos componentes do CHATGPT.
- [**`pipeline_project_demo`**](../samples/AI%20Project/pipeline_project_demo/): Integração de projeto com pipelines de agentes executores.

---

## 🧪 Testes de Interface

- [**`tests/test_aiprojectviews.lpr`**](../../tests/test_aiprojectviews.lpr): Teste automatizado com 68 verificações de renderização, corte de texto, dimensões de colunas e comportamento de pintura das vistas.