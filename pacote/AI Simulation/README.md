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

### 1. `TAIGridWorld` — mundo 2D da simulação

**Arquivo:** `aigridworld.pas`

**Função:** representa o ambiente principal da simulação. É uma grade 2D onde células, agentes e obstáculos são posicionados. Serve como base para simulações de movimento, ocupação de espaço, rotas, filas, armazéns, robôs, pessoas ou recursos.

**Campo de atuação:** modelagem espacial discreta. Use quando for necessário controlar posição, vizinhança, limites da grade e entidades dentro de um mapa.

**Propriedades principais:**

- `Width`: largura da grade.
- `Height`: altura da grade.
- `NeighborhoodMode`: define o tipo de vizinhança usada na busca de células próximas.
  - `nmMoore`: considera as 8 direções ao redor da célula.
  - `nmVonNeumann`: considera apenas as direções ortogonais.
- `BoundaryMode`: define o comportamento nas bordas.
  - `bmBlock`: impede sair dos limites.
  - `bmWrap`: faz a entidade reaparecer do lado oposto da grade.
- `Cells[X, Y]`: acesso direto à célula da posição.
- `Entities`: lista de entidades presentes no mundo.

**Métodos relevantes:**

- `SetupWorld(AWidth, AHeight)`: cria ou recria a grade.
- `ClearWorld`: limpa entidades e estado das células.
- `IsInBounds(X, Y)`: verifica se uma posição está dentro da grade.
- `IsFree(X, Y)`: verifica se uma posição está livre.
- `AddEntity(AEntity, X, Y)`: posiciona uma entidade na grade.
- `RemoveEntity(AEntity)`: remove uma entidade do mundo.
- `MoveEntity(AEntity, NewX, NewY)`: move uma entidade respeitando limite e ocupação.
- `GetNeighbors(X, Y, ARadius, AOutList)`: retorna células vizinhas conforme o modo de vizinhança.
- `GetFreePositions(X, Y, ARadius, AOutList)`: retorna posições livres próximas.
- `CountEntitiesByType(AType)`: conta entidades por tipo.
- `FindEntitiesByType(AType, AOutList)`: localiza entidades por tipo.

---

### 2. `TAIGridCell` — célula da grade

**Arquivo:** `aigridcell.pas`

**Função:** representa uma posição individual do `TAIGridWorld`. Cada célula pode estar livre, bloqueada, conter uma entidade, possuir custo de passagem, tipo de terreno e metadados.

**Campo de atuação:** modelagem do terreno. Use para representar parede, corredor, área livre, ponto de carga, área perigosa, custo de deslocamento ou qualquer característica local do ambiente.

**Propriedades principais:**

- `X`, `Y`: coordenadas da célula.
- `Entity`: entidade ocupando a célula.
- `Blocked`: indica se a célula está bloqueada.
- `Cost`: custo de passagem.
- `Energy`: valor numérico auxiliar para simulações de energia, calor, intensidade ou recurso local.
- `TerrainType`: tipo de terreno, por exemplo `default`, `wall`, `road`, `queue_area`.
- `Weight`: peso auxiliar para algoritmos de decisão ou movimentação.
- `Tag`: identificador inteiro livre.
- `Metadata`: lista de metadados adicionais.
- `IsEmpty`: indica se não há entidade e se a célula não está bloqueada.

**Métodos relevantes:**

- `Clear`: limpa a célula e restaura seus valores padrão.

---

### 3. `TAIGridBuffer` — buffer de atualização por ciclo

**Arquivo:** `aigridbuffer.pas`

**Função:** mantém dois estados da grade: estado atual e próximo estado. Isso permite calcular mudanças de um ciclo sem alterar imediatamente o mundo principal.

**Campo de atuação:** simulações por ciclos discretos. Use quando a atualização de várias células precisa ser aplicada de forma controlada no fim do ciclo.

**Métodos relevantes:**

- `PrepareCycle`: captura o estado atual da grade e prepara o próximo estado.
- `SetNextBlocked(X, Y, ABlocked)`: altera bloqueio no próximo estado.
- `SetNextTerrain(X, Y, ATerrain)`: altera terreno no próximo estado.
- `SetNextCost(X, Y, ACost)`: altera custo no próximo estado.
- `SetNextEnergy(X, Y, AEnergy)`: altera energia no próximo estado.
- `CommitCycle`: aplica o próximo estado ao mundo.
- `RollbackCycle`: descarta alterações planejadas.

---

### 4. `TAISimEntity` — entidade/agente da simulação

**Arquivo:** `aisimentity.pas`

**Função:** representa qualquer objeto ativo da simulação: robô, pessoa, veículo, recurso, obstáculo dinâmico, ponto de atendimento, sensor lógico ou agente de IA.

**Campo de atuação:** modelagem de agentes. Use quando uma entidade precisa ter identidade, tipo, posição, estado ativo e propriedades customizadas.

**Propriedades principais:**

- `Id`: identificador único gerado por GUID.
- `EntityType`: tipo da entidade, por exemplo `robot`, `person`, `service`, `resource`.
- `EntityName`: nome amigável da entidade.
- `Active`: indica se a entidade participa dos ciclos.
- `X`, `Y`: posição atual na grade.
- `Properties`: objeto JSON com propriedades dinâmicas.
- `OnStep`: evento chamado a cada ciclo da entidade.

**Métodos relevantes:**

- `Clone(AOwner)`: cria cópia da entidade com novo identificador.
- `Step`: executa o evento `OnStep`, caso a entidade esteja ativa.
- `SetPropertyDouble`, `GetPropertyDouble`: grava/lê propriedade numérica real.
- `SetPropertyInteger`, `GetPropertyInteger`: grava/lê propriedade inteira.
- `SetPropertyString`, `GetPropertyString`: grava/lê propriedade texto.
- `SetPropertyBoolean`, `GetPropertyBoolean`: grava/lê propriedade booleana.

**Exemplos de propriedades dinâmicas:**

- `energy`;
- `speed`;
- `priority`;
- `capacity`;
- `state`;
- `target`.

---

### 5. `TAIEntityFactory` — fábrica de entidades

**Arquivo:** `aientityfactory.pas`

**Função:** registra tipos de entidades e cria instâncias padronizadas com nome e propriedades iniciais em JSON.

**Campo de atuação:** criação rápida de populações. Use quando o cenário precisa criar muitos agentes do mesmo tipo ou quando deseja padronizar entidades de simulação.

**Propriedades principais:**

- `Registry`: coleção de tipos registrados.

**Estrutura de cada item do registro:**

- `TypeName`: tipo da entidade.
- `DefaultName`: nome padrão.
- `PropertiesJSON`: propriedades iniciais em JSON.

**Métodos relevantes:**

- `RegisterType(ATypeName, ADefaultName, APropertiesJSON)`: registra ou atualiza um tipo de entidade.
- `CreateEntity(ATypeName, AOwner)`: cria uma entidade do tipo informado.
- `CreateBatch(ATypeName, ACount, AOwner, AOutList)`: cria várias entidades de uma vez.

**Exemplo de uso:** criar 50 pessoas, 10 robôs, 3 atendentes, 1 estação de carga ou múltiplos recursos com propriedades padrão.

---

### 6. `TAISimulationEngine` — motor principal da simulação

**Arquivo:** `aisimulationengine.pas`

**Função:** controla o ciclo principal da simulação. Integra mundo, movimento, regras, eventos, evolução e estatísticas.

**Campo de atuação:** execução da simulação. Use quando o cenário precisa rodar automaticamente por timer ou passo a passo.

**Propriedades principais:**

- `GridWorld`: mundo 2D usado pela simulação.
- `RuleEngine`: motor de regras aplicado às entidades.
- `TriggerEngine`: motor de eventos da simulação.
- `MovementEngine`: motor de movimentação.
- `EvolutionEngine`: motor de evolução/mutação.
- `Stats`: coletor de estatísticas.
- `CycleIntervalMs`: intervalo entre ciclos em milissegundos.
- `CycleLimit`: limite máximo de ciclos; `0` indica sem limite.
- `Running`: indica se a simulação está em execução.
- `Paused`: indica se a simulação está pausada.
- `OnCycle`: evento chamado ao final de cada ciclo.

**Métodos relevantes:**

- `StartSimulation`: inicia a simulação.
- `PauseSimulation`: alterna pausa/continuação.
- `StopSimulation`: encerra a execução.
- `StepCycle`: executa um ciclo manualmente.

**Fluxo interno do ciclo:**

1. dispara evento de início de ciclo;
2. processa movimentação das entidades ativas;
3. aplica regras do `TAIRuleEngine`;
4. executa `Step` de cada entidade ativa;
5. registra duração e estatísticas;
6. dispara evento de fim de ciclo;
7. verifica limite de ciclos.

---

### 7. `TAIRuleEngine` — motor de regras comportamentais

**Arquivo:** `airuleengine.pas`

**Função:** executa regras do tipo condição/ação sobre entidades da simulação.

**Campo de atuação:** comportamento dos agentes. Use para definir decisões como procurar recurso, parar, consumir energia, mudar estado, remover entidade, alterar prioridade ou executar ação quando uma condição for verdadeira.

**Propriedades principais:**

- `Rules`: coleção de regras cadastradas.

**Estrutura de cada regra:**

- `RuleName`: nome da regra.
- `Priority`: prioridade de execução.
- `Active`: ativa ou desativa a regra.
- `OnCondition`: função que decide se a regra deve ser aplicada.
- `OnAction`: procedimento executado quando a condição é verdadeira.

**Métodos relevantes:**

- `RegisterRule(AName, APriority, ACondition, AAction)`: registra uma nova regra.
- `ClearRules`: remove todas as regras.
- `EvaluateAndExecute(AEntity, AWorld)`: avalia regras para uma entidade.
- `EvaluateWorldRules(AWorld)`: avalia regras para todas as entidades ativas do mundo.

**Observação técnica:** as regras são ordenadas por prioridade e a primeira regra válida pode interromper a avaliação da entidade.

---

### 8. `TAITriggerEngine` — eventos da simulação

**Arquivo:** `aitriggerengine.pas`

**Função:** centraliza eventos do ciclo de simulação e eventos das entidades.

**Campo de atuação:** integração com interface, logs, painéis, depuração e automações externas. Use quando quiser reagir a movimentos, ciclos, criação/remoção de entidades ou erros.

**Eventos principais:**

- `OnCycleStart`: início de ciclo.
- `OnCycleEnd`: fim de ciclo.
- `OnEntityCreated`: entidade criada.
- `OnEntityRemoved`: entidade removida.
- `OnEntityMoved`: entidade movida, com posição anterior e nova posição.
- `OnRuleApplied`: regra aplicada.
- `OnTriggerError`: erro gerado pelo motor de eventos.

**Métodos relevantes:**

- `TriggerCycleStart(CycleNum)`;
- `TriggerCycleEnd(CycleNum)`;
- `TriggerEntityCreated(AEntity)`;
- `TriggerEntityRemoved(AEntity)`;
- `TriggerEntityMoved(AEntity, FromX, FromY, ToX, ToY)`;
- `TriggerRuleApplied(RuleName, AEntity)`;
- `TriggerError(AError)`.

---

### 9. `TAIMovementEngine` — motor de movimentação

**Arquivo:** `aimovementengine.pas`

**Função:** calcula deslocamentos de entidades na grade.

**Campo de atuação:** simulação de deslocamento. Use para testar movimento aleatório, perseguição de alvos, fuga de ameaças, aproximação de recursos ou deslocamento de agentes em ambientes 2D.

**Propriedades principais:**

- `GridWorld`: mundo onde o movimento será aplicado.
- `Strategy`: estratégia de movimento.
  - `msStop`: não move.
  - `msRandom`: move para uma posição livre próxima.
  - `msTarget`: move em direção ao tipo definido em `TargetType`.
  - `msFlee`: afasta-se do tipo definido em `ThreatType`.
- `TargetType`: tipo de entidade a perseguir.
- `ThreatType`: tipo de entidade da qual fugir.
- `MoveLimitPerCycle`: limite de movimento por ciclo, preparado para controle de deslocamento.

**Métodos relevantes:**

- `MoveRandomly(AEntity)`: movimentação aleatória para célula livre vizinha.
- `MoveTowardsTarget(AEntity, ATargetType)`: aproxima a entidade do alvo mais próximo do tipo indicado.
- `FleeFromThreat(AEntity, AThreatType)`: afasta a entidade da ameaça mais próxima do tipo indicado.
- `StepEntityMovement(AEntity)`: executa a estratégia configurada.

---

### 10. `TAIEvolutionEngine` — evolução e mutação de entidades

**Arquivo:** `aievolutionengine.pas`

**Função:** aplica mutações em propriedades de entidades e cria entidades derivadas.

**Campo de atuação:** treinamento, experimentos evolutivos, variação de parâmetros e geração de versões modificadas de agentes.

**Propriedades principais:**

- `MutationRate`: probabilidade de mutação.
- `Seed`: semente usada em modo determinístico.
- `Deterministic`: permite repetir resultados usando a mesma semente.
- `Factory`: fábrica de entidades associada.

**Métodos relevantes:**

- `ApplyMutation(AEntity, APropertyName, MinVal, MaxVal)`: altera uma propriedade numérica da entidade dentro de uma faixa.
- `CreateDerivedEntity(AEntity, AOwner)`: cria uma entidade derivada por clone.

---

### 11. `TAISimulationStats` — estatísticas da simulação

**Arquivo:** `aisimulationstats.pas`

**Função:** coleta métricas da execução da simulação.

**Campo de atuação:** análise de desempenho, auditoria de ciclos, geração de datasets e acompanhamento de resultados.

**Propriedades principais:**

- `CycleCount`: quantidade de ciclos executados.
- `CreatedCount`: total de entidades criadas.
- `RemovedCount`: total de entidades removidas.
- `HistoryLimit`: limite de histórico de duração de ciclos.

**Métodos relevantes:**

- `ClearStats`: limpa as estatísticas.
- `RecordCycle(ADurationMs)`: registra duração de um ciclo.
- `RecordEntityCreated(AType)`: registra criação por tipo.
- `RecordEntityRemoved(AType)`: registra remoção por tipo.
- `GetStatsJSON`: retorna estatísticas em JSON.
- `GetSummaryText`: retorna resumo textual.

**Métricas exportadas:**

- ciclos executados;
- total criado;
- total removido;
- entidades ativas;
- estatísticas por tipo;
- tempos de ciclo.

---

### 12. `TAIGridRenderer2D` — renderização visual da grade

**Arquivo:** `aigridrenderer2d.pas`

**Função:** desenha o `TAIGridWorld` em um `TCanvas` e permite exportar a visualização para bitmap.

**Campo de atuação:** visualização de simulação em formulários Lazarus, painéis de depuração, demos didáticos e exportação de frames.

**Propriedades principais:**

- `GridWorld`: mundo a ser renderizado.
- `EmptyColor`: cor das células vazias.
- `BlockedColor`: cor das células bloqueadas.
- `GridLineColor`: cor das linhas da grade.
- `ShowGridLines`: exibe ou oculta linhas.
- `CellSize`: tamanho da célula em pixels.
- `TypeColors`: mapa de cores por `EntityType`.

**Métodos relevantes:**

- `RenderToCanvas(ACanvas, ARect)`: desenha a grade e as entidades no canvas informado.
- `ExportToBitmap`: gera um `TBitmap` com a visualização atual.

**Representação visual atual:** entidades são desenhadas como círculos com a primeira letra do tipo.

---

### 13. `TAIScenarioConfig` — persistência e aplicação de cenários

**Arquivo:** `aiscenarioconfig.pas`

**Função:** salva, carrega, captura e aplica cenários de simulação em JSON.

**Campo de atuação:** reprodutibilidade. Use para salvar um cenário de teste, carregar layouts pré-definidos, restaurar uma simulação ou gerar datasets com cenários padronizados.

**Propriedades principais:**

- `ScenarioName`: nome do cenário.
- `WorldWidth`: largura do mundo.
- `WorldHeight`: altura do mundo.
- `ConfigData`: objeto JSON completo do cenário.

**Métodos relevantes:**

- `ClearConfig`: limpa a configuração.
- `LoadFromJSONFile(AFileName)`: carrega cenário de arquivo JSON.
- `SaveToJSONFile(AFileName)`: salva cenário em arquivo JSON.
- `ApplyToWorld(AWorld, AFactory)`: aplica o cenário em um `TAIGridWorld` usando uma fábrica de entidades.
- `CaptureFromWorld(AWorld)`: captura o estado atual do mundo para JSON.

**Estrutura suportada:**

- `name`;
- `width`;
- `height`;
- `cells`: células com `x`, `y`, `blocked`, `cost`, `terrain`;
- `entities`: entidades com `type`, `name`, `x`, `y`, `properties`.

---

### 14. `TAIScenarioGenerator` — geração de cenários por descrição

**Arquivo:** `aiscenariogenerator.pas`

**Função:** gera uma estrutura de cenário a partir de uma descrição em linguagem natural, usando `TCHATGPT` quando configurado.

**Campo de atuação:** prototipação rápida de cenários. Use quando o usuário quiser descrever um ambiente e converter essa descrição para JSON de simulação.

**Propriedades principais:**

- `ChatGPT`: componente `TCHATGPT` usado para gerar o JSON.
- `ScenarioConfig`: componente `TAIScenarioConfig` que receberá o cenário gerado.

**Métodos relevantes:**

- `GenerateScenario(ADescription)`: gera o cenário e preenche o `ScenarioConfig`.

**Formato esperado do JSON gerado:**

- `name`;
- `width`;
- `height`;
- `cells`;
- `entities`.

**Observação técnica:** o componente limpa blocos Markdown quando o LLM retorna JSON entre crases e valida o retorno com parser JSON antes de aplicar no `ScenarioConfig`.

---

### 15. `TAISimulationExporter` — exportação de resultados

**Arquivo:** `aisimulationexporter.pas`

**Função:** exporta estatísticas e configurações da simulação.

**Campo de atuação:** relatórios, análise posterior, criação de datasets e registro de experimentos.

**Métodos relevantes:**

- `ExportToCSV(AFileName, AStats)`: exporta métricas da simulação para CSV.
- `ExportToJSON(AFileName, AConfig)`: exporta a configuração/cenário para JSON.
- `ExportToTXT(AFileName, AStats)`: exporta resumo textual das estatísticas.

**Dados exportados em CSV:**

- ciclos executados;
- total de entidades criadas;
- total de entidades removidas;
- entidades ativas;
- população por tipo.

---

## Critério de uso

| Situação | Usar AI Simulation? |
|---|---|
| Treinar agente em ambiente controlado | Sim |
| Testar algoritmo de movimentação | Sim |
| Gerar dataset sintético a partir de regras conhecidas | Sim |
| Simular fluxo de pessoas, fila, logística ou ocupação de espaço | Sim |
| Visualizar agentes em grade 2D | Sim |
| Salvar, carregar e repetir cenários de teste | Sim |
| Exportar métricas de simulação | Sim |

---

## Como Começar

O pacote correspondente está localizado em `pacote/packages/openai_simulation.lpk`. Para utilizá-los:

1. Abra o Lazarus.
2. Menu: `Pacote` -> `Abrir arquivo de pacote (.lpk)` -> Selecione `openai_simulation.lpk`.
3. Clique em `Usar` -> `Instalar`.
4. O Lazarus recompilará e você verá a nova aba **`AI Simulation`** na paleta de componentes.
