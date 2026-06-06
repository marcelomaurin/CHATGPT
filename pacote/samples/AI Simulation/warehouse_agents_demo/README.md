# Warehouse Logistics Simulation Demo - Lazarus AI Suite

Este demonstrativo apresenta uma simulação visual de logística interna de armazém utilizando a suíte de componentes **AI Simulation**.

---

## Cenário da Simulação

* O ambiente consiste em uma grade celular 2D (15x15) representando a planta baixa de um armazém.
* Várias fileiras de prateleiras (shelves, cinza escuro) estão alinhadas no mapa como barreiras.
* Uma zona de entrega (`delivery_zone`, cor verde) localiza-se na extremidade inferior direita `(14, 14)`.
* Agentes autônomos (`worker_agent`, cor azul claro quando livres) iniciam no canto inferior esquerdo.
* Vários pacotes (`package`, cor amarela) são gerados em posições aleatórias no armazém.
* Dinâmica comportamental:
  1. **Busca e Reserva**: Um agente livre (`worker_agent_idle`, azul claro) localiza o pacote mais próximo que está aguardando (`package_waiting`, amarelo). O agente reserva o pacote, que muda seu estado para roxo (`package_reserved`), garantindo que nenhum outro agente tente coletar o mesmo pacote.
  2. **Coleta**: O agente muda para azul escuro (`worker_agent_moving`) e desloca-se até o pacote. Ao alcançá-lo, o pacote é coletado (removido do chão) e o agente passa para laranja (`worker_agent_carrying`), carregando o pacote.
  3. **Entrega**: O agente carrega o pacote até a zona de entrega (verde, no ponto `14, 14`). Ao chegar lá, ele descarrega o pacote, incrementa a quantidade de entregas, calcula os tempos médios de transporte e retorna ao estado livre (`worker_agent_idle`) para buscar o próximo pacote.

---

## Componentes Utilizados

* `TAIGridWorld`: Gerencia a grade física do armazém e obstáculos.
* `TAISimEntity`: Agentes trabalhadores, pacotes e pontos de entrega.
* `TAIRuleEngine`: Regras operacionais desacopladas (DeliverPackage, CollectPackage, SearchPackage, MoveWorker).
* `TAITriggerEngine`: Registro de eventos (`pacote_reservado`, `pacote_coletado`, `pacote_entregue`, `todos_pacotes_entregues`).
* `TAISimulationEngine`: Motor do tempo do ciclo principal.
* `TAISimulationStats`: Métricas operacionais.
* `TAIGridRenderer2D`: Visualização gráfica.
* `TAISimulationExporter`: Permite exportar histórico e dados finais para CSV/TXT.

---

## Como Executar

O projeto pode ser executado diretamente em runtime:

1. Abra o Lazarus.
2. Abra o arquivo `warehouse_agents_demo.lpi`.
3. Pressione **F9** para rodar.
4. Ajuste as quantidades e clique em **Iniciar Simulação**.

---

## Bugs Conhecidos

* Está gerando erro ao executar e os pacotes não estão sendo armazenados.
