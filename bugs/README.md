# Registro de Bugs e Limitações

Este diretório contém o registro de problemas e limitações identificados nos exemplos e demonstrativos do projeto.

---

## 1. Graph Visualizer Demo (`graph_visualizer_demo`)
* **Problema**: O projeto `graph_visualizer_demo` não apresenta o gráfico de forma visual.
* **Detalhes**: A interface gráfica do exemplo exibe apenas os logs textuais e o código Mermaid gerado em um controle `TMemo`, sem renderizar a estrutura visual do grafo na tela.

---

## 2. Robot Grid Demo (`robot_grid_demo`)
* **Problema**: O `robot_grid_demo` não realiza movimento.
* **Detalhes**: Relatado que os robôs na simulação não realizam movimentação pela grade.

---

## 3. Service Queue Demo (`service_queue_demo`)
* **Problema**: O movimento não está acontecendo e não estão sendo geradas filas de atendimento no ciclo.
* **Detalhes**: Relatado que a movimentação dos agentes em direção aos guichês não ocorre e que as filas de atendimento correspondentes não são geradas durante a execução dos ciclos.

---

## 4. Warehouse Agents Demo (`warehouse_agents_demo`)
* **Problema**: Erro ao executar e pacotes não estão sendo armazenados.
* **Detalhes**: Relatado que ocorre um erro em tempo de execução e que os pacotes não estão sendo devidamente armazenados ou entregues na zona correspondente.

---

## 5. Contamination Demo (`contamination_demo`)
* **Problema**: Erro ao iniciar, não gera contaminações por proximidade, suspeita de erro na rotina de movimentação.
* **Detalhes**: Relatado que além de um erro na inicialização, a simulação não propaga a contaminação (movimento) entre agentes vizinhos, provavelmente por falhas na rotina de movimentação.
