# Contamination Simulation Demo - Lazarus AI Suite

Este demonstrativo apresenta uma simulação didática de proximidade e propagação de estados entre entidades em movimento, simulando uma contaminação e posterior recuperação, utilizando a suíte **AI Simulation**.

> [!IMPORTANT]
> Este projeto possui apenas fins didáticos de engenharia de software e simulação de agentes autônomos. Ele não constitui um modelo epidemiológico real ou médico.

---

## Cenário da Simulação

* O ambiente consiste em uma grade celular 2D (15x15) com barreiras físicas centrais (cinza escuro).
* Entidades representam pessoas que circulam pela sala de forma aleatória (`MoveRandomly`).
* Os estados possíveis e suas respectivas cores são:
  * `person_healthy` (Saudável, cor azul).
  * `person_infected` (Infectado, cor vermelha).
  * `person_recovered` (Recuperado, cor verde).
* Regras comportamentais por ciclo:
  1. **Movimentação**: As pessoas andam um passo aleatório para células livres vizinhas.
  2. **Contaminação por Proximidade**: Se uma pessoa saudável estiver adjacente a uma pessoa infectada, há uma chance configurável (ex: 30%) de ela se contaminar e mudar seu estado para infectado (cor vermelha).
  3. **Recuperação**: Pessoas infectadas acumulam ciclos de infecção. Ao atingir o tempo configurado (ex: 15 ciclos), elas se recuperam, mudando de estado para recuperadas (cor verde) e tornam-se imunes (não transmitem nem voltam a se infectar).
  4. **Estabilização**: A simulação registra o número de ciclos necessários até que a quantidade de infectados chegue a zero.

---

## Componentes Utilizados

* `TAIGridWorld`: Gerencia a grade celular.
* `TAISimEntity`: Representação dos agentes em movimento.
* `TAIMovementEngine`: Movimento aleatório dos agentes.
* `TAIRuleEngine`: Regras de contágio, recuperação e movimentação.
* `TAITriggerEngine`: Registro de eventos (`pessoa_contaminada`, `pessoa_recuperada`, `estabilizacao_simulacao`).
* `TAISimulationEngine`: Controlador do tempo do ciclo.
* `TAISimulationStats`: Histórico e contadores por estado.
* `TAIGridRenderer2D`: Visualização gráfica em canvas.
* `TAISimulationExporter`: Permite exportar histórico em formato CSV/TXT.

---

## Como Executar

O projeto instancia todos os componentes dinamicamente no runtime:

1. Abra o Lazarus.
2. Abra o arquivo `contamination_demo.lpi`.
3. Pressione **F9** para compilar e rodar.
4. Ajuste as quantidades iniciais, chance de infecção e ciclos para cura e clique em **Iniciar Simulação**.
