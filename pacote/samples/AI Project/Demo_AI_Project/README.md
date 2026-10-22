# 📊 Demo_AI_Project — Manual do Usuário e Demonstração

O projeto de exemplo **`Demo_AI_Project`** demonstra o uso integrado das visualizações de gerenciamento de projetos ([`TAIGanttView`](../../../AI%20Project/aiganttview.pas), [`TAINetworkView`](../../../AI%20Project/ainetworkview.pas), [`TAIBoardView`](../../../AI%20Project/aiboardview.pas) e [`TAIResourceView`](../../../AI%20Project/airesourceview.pas)) em conjunto com o motor de caminho crítico ([`TAICPMScheduler`](../../../AI%20Project%20Core/aicpmscheduler.pas)) do pacote [**`openai_project.lpk`**](../../../packages/openai_project.lpk).

---

## 📋 O que faz o Sample

1. **Carregamento de Projeto Completo:** Cria ou carrega da memória uma estrutura de tarefas com dependências, durações, datas e alocação de recursos.
2. **Cálculo de Caminho Crítico:** Executa o algoritmo CPM em tempo real, calculando datas limites e destacando em vermelho as tarefas sem folga.
3. **Múltiplas Vistas Sincronizadas:**
   - **Gantt:** Mostra as barras no tempo com grade de calendário e setas de dependência.
   - **Rede PERT/CPM:** Mostra o fluxo de caixas de atividades conectadas.
   - **Quadro Kanban:** Agrupa as tarefas em colunas conforme o status atual.
   - **Recursos:** Exibe a alocação de cada colaborador ao longo do cronograma.

---

## 🚀 Como Utilizar (Passo a Passo)

### 1. Configurando os Componentes no Formulário

```pascal
uses
  aiganttview, ainetworkview, aiboardview, airesourceview, aicpmscheduler, aitaskgraph;

var
  Gantt: TAIGanttView;
  Network: TAINetworkView;
  Board: TAIBoardView;
  Resources: TAIResourceView;
  Scheduler: TAICPMScheduler;
```

### 2. Vinculando Dados às Vistas

```pascal
procedure TFormProject.FormCreate(Sender: TObject);
begin
  // Instancia a vista de Gantt
  Gantt := TAIGanttView.Create(Self);
  Gantt.Parent := TabSheetGantt;
  Gantt.Align := alClient;
  Gantt.ShowCriticalPath := True; // Realça caminho crítico com cor destacada
  Gantt.ZoomLevel := gzDays;      // Zoom diário

  // Instancia a vista Kanban
  Board := TAIBoardView.Create(Self);
  Board.Parent := TabSheetBoard;
  Board.Align := alClient;

  // Carrega e atualiza
  CarregarDadosDoProjeto;
  Gantt.Invalidate;
  Board.Invalidate;
end;
```

---

## 🔍 Referência dos Componentes em Foco

### 1. `TAIGanttView` ([`aiganttview.pas`](../../../AI%20Project/aiganttview.pas))

#### Propriedades Principais
| Propriedade | Tipo | Descrição |
|---|---|---|
| `ShowCriticalPath` | `Boolean` | Quando `True`, pinta com borda/cor destacada as barras das tarefas críticas calculadas pelo CPM. |
| `ZoomLevel` | `TAIGanttZoomLevel` | Nível de detalhe do cabeçalho temporal (`gzDays`, `gzWeeks`, `gzMonths`). |
| `RowHeight` | `Integer` | Altura em pixels de cada linha de tarefa na grade. |
| `SelectedTaskID` | `string` | Identificador da tarefa atualmente selecionada pelo clique do usuário. |

#### Métodos Principais
| Método | Assinatura | Descrição |
|---|---|---|
| `ScrollToDate` | `procedure ScrollToDate(ADate: TDateTime);` | Desloca a rolagem horizontal da visão para centralizar a data informada. |
| `Invalidate` | `procedure Invalidate; override;` | Força a repintura imediata do Canvas com todas as tarefas e setas. |

---

### 2. `TAIBoardView` ([`aiboardview.pas`](../../../AI%20Project/aiboardview.pas))

#### Propriedades Principais
| Propriedade | Tipo | Descrição |
|---|---|---|
| `ColumnWidth` | `Integer` | Largura em pixels de cada coluna de status Kanban. |
| `CardHeight` | `Integer` | Altura padrão dos cartões de tarefas dentro das colunas. |

#### Eventos
| Evento | Assinatura | Descrição |
|---|---|---|
| `OnCardClick` | `procedure(Sender: TObject; const TaskID: string) of object;` | Disparado quando o usuário clica em um cartão de tarefa no quadro. |

---

### 3. `TAICPMScheduler` ([`aicpmscheduler.pas`](../../../AI%20Project%20Core/aicpmscheduler.pas))

#### Métodos Principais
| Método | Assinatura | Descrição |
|---|---|---|
| `CalculateSchedule` | `function CalculateSchedule(Graph: TAITaskGraph): Boolean;` | Executa a varredura para frente (Forward Pass) e para trás (Backward Pass), determinando datas de início/fim mais cedo/tarde e folgas. |
| `IsCritical` | `function IsCritical(const TaskID: string): Boolean;` | Retorna `True` se a tarefa não possui folga total (Total Float <= 0). |