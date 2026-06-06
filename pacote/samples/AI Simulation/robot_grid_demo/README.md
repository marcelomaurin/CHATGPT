# Robot Grid Simulation Demo - Lazarus AI Suite

Este demonstrativo apresenta uma simulação visual 2D na qual robôs móveis buscam estações de recarga de forma autônoma utilizando a suíte de componentes **AI Simulation**.

---

## Cenário da Simulação

* O ambiente consiste em uma grade celular 2D (15x15).
* Há uma parede central de obstáculos bloqueando a movimentação direta.
* Duas estações de recarga (`charging_station`, cor verde) estão localizadas nas extremidades.
* Cinco robôs (`robot`, cor azul) são gerados em locais aleatórios.
* Cada robô possui uma propriedade de `'energy'` inicializada em 100.0.
* A cada ciclo da simulação:
  * O robô perde energia de forma progressiva.
  * Se a energia for superior a 30.0, o robô se desloca de forma aleatória (`MoveRandomly`) e seu estado passa para `moving`.
  * Se a energia ficar abaixo de 30.0, o robô muda o comportamento buscando a estação de recarga mais próxima (`MoveTowardsTarget`) e seu estado passa para `seeking_charge`.
  * Ao alcançar uma célula adjacente à estação, o robô é recarregado para 100.0 de energia e o estado passa para `charging`.
  * Se a energia zerar antes de recarregar, o robô fica inativo (estado `inactive`, desenhado na cor vermelha).
  * Se um robô não tiver movimentos válidos disponíveis, seu estado passa a ser `blocked`.

---

## Componentes Utilizados

* `TAIGridWorld`: Gerencia a grade 2D e posicionamento.
* `TAISimEntity`: Agentes móveis e estáticos.
* `TAIMovementEngine`: Algoritmos de movimento em grade.
* `TAIRuleEngine`: Regras de negócio desacopladas (DeathCheck, Recharge, LowEnergyMove, NormalMove).
* `TAITriggerEngine`: Emissor de eventos do ciclo e estados dos robôs (`robot_moved`, `robot_blocked`, `robot_low_energy`, `robot_charging`, `robot_recharged`, `robot_inactive`).
* `TAISimulationEngine`: Controlador do ciclo principal.
* `TAISimulationStats`: Rastreamento de métricas.
* `TAIGridRenderer2D`: Visualização gráfica em canvas.

---

## Como Executar

Este projeto foi projetado para instanciar os componentes dinamicamente no carregamento do formulário (`FormCreate`). Portanto, **não é necessário instalar o pacote no Lazarus IDE para compilar o exemplo**.

1. Abra o Lazarus.
2. Abra o projeto `robot_grid_demo.lpi` localizado nesta pasta.
3. Clique em **Executar (F9)**.
4. Utilize os botões do painel lateral para controlar o fluxo da simulação.

---

## Bugs Conhecidos

* O `robot_grid_demo` não realiza movimento.
