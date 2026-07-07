# AI Simulation Components - Lazarus AI Suite

Esta pasta contém a suíte de componentes voltada para a criação de **simulações computacionais de ambientes reais ou controlados**, baseadas em agentes, mapas celulares 2D, regras comportamentais, eventos dinâmicos, movimentação, evolução e renderização nativa de grade.

## Objetivo da área

A área **AI Simulation** fornece motores de simulação para criar cenários controlados onde uma IA possa ser treinada, testada ou validada antes de atuar em um ambiente real.

Ela deve ser usada quando o projeto precisar:

- representar um ambiente em grade 2D;
- controlar agentes, entidades, recursos, obstáculos e posições;
- testar movimentação, busca, fuga, rotas ou colisões lógicas;
- simular filas, fluxo de pessoas, logística, propagação ou ocupação de espaço;
- gerar métricas e históricos para análise ou treinamento de IA;
- repetir cenários com regras conhecidas para comparar estratégias.

---

## Componentes Disponíveis (Aba `AI Simulation`)

1. **`TAIGridWorld`**: Componente de grade celular 2D. Controla as coordenadas físicas, vizinhanças (Moore ou Von Neumann), limites de bordas (Wrap/Block) e alocação de entidades.
2. **`TAIGridCell`**: Classe auxiliar de representação de cada célula (bloqueio, custos de caminhada, tipo de terreno e metadados).
3. **`TAIGridBuffer`**: Classe auxiliar para processamento em duplo estado por ciclo, garantindo que atualizações cíclicas não interfiram com a iteração em andamento.
4. **`TAISimEntity`**: Classe/Componente base de agentes da simulação. Suporta posições, estado ativo/inativo, clone de propriedades e dicionário de metadados genéricos.
5. **`TAIEntityFactory`**: Componente de criação dinâmica de grupos e instâncias de agentes baseados em registros pré-definidos de tipos.
6. **`TAISimulationEngine`**: Motor de ciclo de simulação principal (Play, Pause, Step, Stop), controlado por ciclos manuais ou por Timer em tempo real.
7. **`TAIRuleEngine`**: Motor de regras condicionais prioritárias para comportamento distribuído dos agentes.
8. **`TAITriggerEngine`**: Centralizador e despachante de eventos da simulação (início/fim de ciclo, movimentação, criação/destruição de entidades e erros).
9. **`TAIMovementEngine`**: Motor de cálculo de deslocamento 2D nativo (movimentação aleatória, busca de alvos e fuga de ameaças).
10. **`TAIEvolutionEngine`**: Motor de herança genética, variabilidade e mutações comportamentais com seeds pseudo-aleatórias.
11. **`TAISimulationStats`**: Acumulador e monitor de métricas e histórico de ciclos da simulação.
12. **`TAIGridRenderer2D`**: Renderizador nativo em `TCanvas` para desenhar visualmente a grade do mundo e seus agentes.
13. **`TAIScenarioConfig`**: Utilitário de persistência (JSON) para salvar, carregar ou capturar layouts inteiros da grade e entidades em execução.
14. **`TAIScenarioGenerator`**: Conector com o componente `TCHATGPT` para geração rápida de cenários baseada em descrições em linguagem natural.
15. **`TAISimulationExporter`**: Utilitário para exportar relatórios, históricos e métricas em arquivos CSV, JSON ou TXT.

---

## Critério de uso

| Situação | Usar AI Simulation? |
|---|---|
| Treinar agente em ambiente controlado | Sim |
| Testar algoritmo de movimentação | Sim |
| Gerar dataset sintético a partir de regras conhecidas | Sim |
| Simular fluxo de pessoas, fila, logística ou contaminação | Sim |

---

## Como Começar

O pacote correspondente está localizado em `pacote/packages/openai_simulation.lpk`. Para utilizá-los:

1. Abra o Lazarus.
2. Menu: `Pacote` -> `Abrir arquivo de pacote (.lpk)` -> Selecione `openai_simulation.lpk`.
3. Clique em `Usar` -> `Instalar`.
4. O Lazarus recompilará e você verá a nova aba **`AI Simulation`** na paleta de componentes.
