# Service Queue Simulation Demo - Lazarus AI Suite

Este demonstrativo apresenta uma simulação visual de uma fila de atendimento (administração, comercial ou hospitalar) utilizando a suíte de componentes **AI Simulation**.

---

## Cenário da Simulação

* O ambiente consiste em uma grade celular 2D (15x15) representando uma sala de recepção.
* Há paredes e barreiras (cinza escuro) organizando um canal de fila em serpentina.
* Uma recepção/entrada localiza-se no ponto inferior esquerdo `(0, 14)`.
* Três guichês de atendimento (`Desk_A`, `Desk_B`, `Desk_C`, cor cinza claro quando livres, cor vermelha quando ocupados) localizam-se no topo.
* Um ponto de saída localiza-se no topo direito `(14, 0)`.
* Pessoas (`person_waiting`, cor amarela) entram periodicamente pela entrada de acordo com a taxa configurada (ex: a cada 5 ciclos).
* A dinâmica de atendimento é:
  1. A pessoa entra na simulação na cor amarela (`person_waiting`).
  2. Ao identificar um guichê livre, ela se dirige a ele e muda a cor para azul (`person_moving`).
  3. Ao alcançar o guichê, o status muda para `being_served` (cor laranja) e o guichê passa para `busy` (cor vermelha).
  4. O atendimento consome tempo (ciclos de atendimento).
  5. Após concluído o tempo, a pessoa é liberada e seu estado passa para verde (`person_served`), caminhando até a saída para ser removida da simulação.

---

## Componentes Utilizados

* `TAIGridWorld`: Gerencia o mundo e a posição dos elementos.
* `TAISimEntity`: Agentes representando as pessoas e guichês.
* `TAIRuleEngine`: Regras de negócio do atendimento (Spawn, SearchDesk, StartService, FinishService, Move, Exit).
* `TAITriggerEngine`: Disparo e exibição de eventos (`pessoa_criada`, `atendimento_iniciado`, `atendimento_finalizado`, `pessoa_saiu`, `guiche_ocupado`, `guiche_livre`).
* `TAISimulationEngine`: Controlador do tempo do ciclo.
* `TAISimulationStats`: Histórico e contagem de entidades.
* `TAIGridRenderer2D`: Visualização gráfica.
* `TAISimulationExporter`: Permite exportar o resumo da simulação para CSV/TXT.

---

## Como Executar

Não é necessário instalar componentes no Lazarus IDE para rodar o projeto, pois são instanciados dinamicamente em runtime.

1. Abra o Lazarus.
2. Abra o arquivo `service_queue_demo.lpi`.
3. Pressione **F9** para compilar e rodar.
4. Ajuste as taxas de chegada e tempo de atendimento nos campos de configuração e clique em **Iniciar Simulação**.
