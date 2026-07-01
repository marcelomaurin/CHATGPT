# 🤖 Documentação da Aba AI Agent

Esta pasta contém os componentes do Lazarus sob a aba **AI Agent**, voltados à criação de agentes de IA, orquestração multiagente, tomada de decisão, auditoria de contexto, mapa de memória, controle de segurança e integração com ações externas controladas.

> **Nota de maturidade:** Os componentes de agentes e orquestração estão em evolução. Alguns recursos são voltados à auditoria, simulação, estruturação de decisões e integração controlada com ações externas. Antes de uso em produção, valide permissões, segurança, persistência, logs e integração com provedores LLM.

---

> **Compatibilidade:** os aliases antigos `TAIMapaDeMemoria`, `TAIMapaDeMemoriaItem`, `TAIMapaDeMemoriaCollection` e a propriedade `MapaDeMemoria` foram mantidos temporariamente para não quebrar projetos existentes.

## 📋 Índice dos Componentes

- [TAIAgent](#taiagent)
- [TAIAgentOptions](#taiagentoptions)
- [TAIAgentAction](#taiagentaction)
- [TAIAgentResource](#taiagentresource)
- [TAIAgentOutput](#taiagentoutput)
- [TAIAgentOrchestrator](#taiagentorchestrator)
- [TAICustomAgent](#taicustomagent)
- [TAIClassifierAgent](#taiclassifieragent)
- [TAIDecisionAgent](#taidecisionagent)
- [TAIActionBuilderAgent](#taiactionbuilderagent)
- [TAIActionExecutor](#taiactionexecutor)
- [TAIAgentMemoryMap](#taimapadememoria)
- [TAIAgentSafety](#taiagentsafety)
- [TAIPipeline](#taipipeline)
- [TAIWizardConfig](#taiwizardconfig)

---

## 🔍 Detalhamento dos Componentes

### TAIAgent

**Função:** Cérebro do agente de IA com execução controlada. Coordena a conversação com modelos de IA para planejar e executar ações com base em um histórico (memória).

- **Propriedades (Published):**
  - `ChatGPT: TCHATGPT` - Conector de chat com o modelo de LLM.
  - `Options: TAIAgentOptions` - Perguntas e contexto operacional do agente.
  - `Action: TAIAgentAction` - Ações permitidas e controle de parâmetros.
  - `Resource: TAIAgentResource` - Recursos físicos/digitais disponíveis (e-mail, Modbus, etc.).
  - `Safety: TAIAgentSafety` - Filtro e políticas de segurança para execução de ações.
  - `SystemPrompt: string` - Prompt de sistema personalizado que guia o agente.
  - `LastRationale: string` - Justificativa da última decisão gerada pela IA (somente leitura).
  - `Memory: TStrings` - Histórico da conversa em memória de contexto.
  - `MaxMemoryLimit: Integer` - Limite de tamanho de memória.
  - `MaxRetries: Integer` - Limite de tentativas para formatação válida de JSON/resposta.
  - `LastDecision: TAIAgentDecision` - Dados detalhados da última ação e parâmetros calculados (somente leitura).
- **Métodos (Public):**
  - `Execute(const AInputData: string): Boolean` - Envia a requisição do usuário, executa a análise de IA, infere a ação e chama a execução correspondente.
  - `ClearMemory` - Limpa o histórico de memória/conversas.
- **Eventos:**
  - `OnActionTriggered: TAgentActionEvent` - Disparado quando o agente decide por uma ação e a despacha com parâmetros.

---

### TAIAgentOptions

**Função:** Armazena perguntas e o contexto básico de suporte que alimentam a análise do `TAIAgent`.

- **Propriedades (Published):**
  - `Questions: TStrings` - Lista de perguntas/requisitos estruturados de verificação.
  - `Context: string` - Descrição textual detalhada do contexto e regras de negócio.
  - `Action: TAIAgentAction` - Ação a ser associada a estas opções.

---

### TAIAgentAction

**Função:** Define a lista de ações que a IA pode decidir executar e faz a validação dos parâmetros gerados.

- **Propriedades (Published):**
  - `AllowedActions: TStrings` - Lista das ações permitidas (ex: `ENVIAR_EMAIL`, `LIGAR_RELE`).
  - `ParameterDefinitions: TStrings` - Definições dos parâmetros esperados para cada ação (usualmente em JSON).
  - `SelectedAction: string` - A ação decidida na última execução da IA.
  - `SelectedParameters: TStrings` - Chave=Valor dos parâmetros gerados para a ação atual.
- **Métodos (Public):**
  - `ClearSelection` - Limpa a ação e os parâmetros selecionados.
  - `GetParamValue(const AName: string): string` - Retorna o valor de um parâmetro selecionado.
  - `TriggerAction(const AActionName: string; AParams: TStrings)` - Força o disparo manual/simulado de uma ação.
- **Eventos:**
  - `OnExecuteAction: TAgentActionEvent` - Disparado para executar a rotina correspondente à ação.

---

### TAIAgentResource

**Função:** Repositório que cataloga as conexões físicas e componentes lógicos externos (e-mail, redes, sensores, bancos de dados) disponíveis para a IA.

- **Propriedades (Published):**
  - `Resources: TAIAgentResourceCollection` - Coleção de itens de recurso configurados. Cada item de recurso (`TAIAgentResourceItem`) possui propriedades como `Name`, `ResourceType` (artEmail, artFile, etc.), `Host`, `Port`, `Sender`, `Recipient`, `FilePath`, `APIUrl`, `Headers`, `Config` e `Component` (ligação direta com componentes reais como `TAIEmailClient` ou `TAIMqttClient`).
- **Métodos (Public):**
  - `FindResource(const AName: string): TAIAgentResourceItem` - Localiza um recurso cadastrado pelo nome.

---

### TAIAgentOutput

**Função:** Componente de ligação automática. Conecta as decisões lógicas geradas pelo `TAIAgentAction` aos dispositivos descritos no `TAIAgentResource`.

- **Propriedades (Published):**
  - `Action: TAIAgentAction` - Referência para escutar o disparo de decisões.
  - `Resource: TAIAgentResource` - Catálogo de recursos configurados.
  - `Mappings: TAIAgentOutputMappingCollection` - Associação de qual Ação (`ActionName`) dispara qual Recurso (`ResourceName`).
  - `LastExecutionLog: string` - Logs detalhados do último despacho.
- **Métodos (Public):**
  - `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` - Despacha dinamicamente uma ação chamando o método `Execute` do recurso correspondente.
- **Eventos:**
  - `OnOutputExecuted: TAIAgentOutputEvent` - Disparado quando uma ação de saída é executada indicando sucesso, log de runtime e parâmetros de despacho.

---

### TAIAgentOrchestrator

**Função:** Orquestrador central do fluxo multiagente. Coordena a execução sequencial de classificação, decisão, ajuste de ações e execução, compartilhando o mapa de memória entre as etapas quando configurado.

- **Propriedades (Published):**
  - `ChatGPT: TCHATGPT` - Conector de chat com LLM.
  - `MemoryMap: TAIAgentMemoryMap` - Histórico operacional compartilhado entre etapas.
  - `CriarMapaAutomaticamente: Boolean` - Indica se deve instanciar um mapa temporário caso nenhum seja associado.
  - `RepassarMapaParaAgentes: Boolean` - Quando verdadeiro, repassa automaticamente o `MemoryMap` para `Classifier`, `DecisionAgent`, `ActionBuilder` e `Executor`.
  - `Classifier: TAIClassifierAgent` - Agente responsável pela classificação inicial.
  - `DecisionAgent: TAIDecisionAgent` - Agente decisor do plano de ações.
  - `ActionBuilder: TAIActionBuilderAgent` - Agente de ajuste e preenchimento de parâmetros.
  - `Executor: TAIActionExecutor` - Agente encarregado da execução simulada ou real.
- **Métodos (Public):**
  - `Run(const AInput: string): Boolean` - Inicia e executa sequencialmente o ciclo multiagente completo (Classificar -> Decidir -> Ajustar -> Executar).
- **Eventos:**
  - `OnBeforeFlowStart` / `OnAfterFlowStart` - Disparados no início e fim do ciclo.
  - `OnBeforeClassifier` / `OnAfterClassifier` - Interceptam a etapa de classificação.
  - `OnBeforeDecisionAgent` / `OnAfterDecisionAgent` - Interceptam a tomada de decisão.
  - `OnBeforeActionBuilder` / `OnAfterActionBuilder` - Interceptam a montagem de parâmetros.
  - `OnBeforeExecutor` / `OnAfterExecutor` - Interceptam a fase de execução.
  - `OnBeforeActionExecute` / `OnAfterActionExecute` - Interceptam a execução física de cada comando.
  - `OnInformationLossDetected` - Disparado se dados fundamentais forem perdidos entre transições do LLM.
  - `OnFlowError` - Disparado no caso de falhas em qualquer agente.
  - `OnFlowCanceled` - Permite abortar o fluxo no meio da execução.
  - `OnFlowFinished` - Finalização global com êxito.

---

### TAICustomAgent

**Função:** Classe base para agentes especializados do pacote AI Agent. Centraliza integração com `TCHATGPT`, prompt de sistema, mapa de memória, auditoria de etapas, confiança mínima e eventos comuns do ciclo de execução.

É a base usada por agentes como `TAIClassifierAgent`, `TAIDecisionAgent` e `TAIActionBuilderAgent`.

- **Propriedades (Published):**
  - `ChatGPT: TCHATGPT` - Conector LLM usado pelo agente.
  - `SystemPrompt: string` - Prompt de sistema específico do agente.
  - `MemoryMap: TAIAgentMemoryMap` - Mapa de memória usado para auditoria e contexto.
  - `AutoRegistrarNoMapa: Boolean` - Define se o agente registra automaticamente suas etapas no mapa.
  - `NomeAgente: string` - Nome lógico do agente.
  - `TipoAgenteMapa: TAITipoAgenteMapa` - Tipo do agente no mapa de memória.
  - `OrdemAtualMapa: Integer` - Ordem atual da etapa registrada no mapa.
  - `MaxPerguntasAnalise: Integer` - Limite de perguntas internas de análise.
  - `MinConfidence: Double` - Confiança mínima esperada.
  - `VerificarPerdaInformacao: Boolean` - Indica se o agente deve considerar verificação de perda de informação.

- **Métodos (Public):**
  - `BeginMemoryStep(const AInput: string): TAIAgentMemoryMapItem` - Inicia uma etapa no mapa de memória.
  - `EndMemoryStep(AItem: TAIAgentMemoryMapItem; const AAnalise: string; const AExplicacao: string; const AAcaoTomada: string; const ASaidaGerada: string)` - Finaliza uma etapa no mapa.
  - `AddMemoryQuestion(AItem: TAIAgentMemoryMapItem; const APergunta: string; const AResposta: string; const AAnalise: string; const AOrigem: string = 'LLM'; const AConfianca: Double = 0)` - Adiciona uma pergunta interna de análise.

- **Eventos:**
  - `OnBeforeMemoryStep: TAIAgentMemoryStepEvent`
  - `OnAfterMemoryStep: TAIAgentMemoryStepEvent`
  - `OnAgentQuestion: TAIAgentQuestionEvent`
  - `OnBeforeAgentExecute: TAIFluxoEtapaControlEvent`
  - `OnAfterAgentExecute: TAIFluxoEtapaEvent`
  - `OnBeforeBuildPrompt: TAIFluxoEtapaControlEvent`
  - `OnAfterBuildPrompt: TAIFluxoEtapaEvent`
  - `OnBeforeLLMCall: TAIFluxoEtapaControlEvent`
  - `OnAfterLLMCall: TAIFluxoEtapaEvent`
  - `OnBeforeParseResponse: TAIFluxoEtapaControlEvent`
  - `OnAfterParseResponse: TAIFluxoEtapaEvent`
  - `OnBeforeMemoryWrite: TAIFluxoEtapaControlEvent`
  - `OnAfterMemoryWrite: TAIFluxoEtapaEvent`
  - `OnAgentError: TAIFluxoEtapaEvent`

---

### TAIClassifierAgent

**Função:** Agente especialista em triagem, priorização e classificação textual.

> Herda de `TAICustomAgent`, portanto também possui `ChatGPT`, `SystemPrompt`, `MemoryMap`, `AutoRegistrarNoMapa`, `NomeAgente`, `TipoAgenteMapa`, `MinConfidence` e eventos comuns de ciclo/memória.

- **Métodos (Public):**
  - `Classify(const AInput: string; out AOutput: string): Boolean` - Classifica e formata a intenção inicial em uma estrutura para processamento posterior.
- **Eventos:**
  - `OnBeforeClassify: TAIFluxoEtapaControlEvent`
  - `OnAfterClassify: TAIFluxoEtapaEvent`
  - `OnBeforeSelectTargetAgents: TAIFluxoEtapaControlEvent`
  - `OnAfterSelectTargetAgents: TAIFluxoEtapaEvent`
  - `OnClassificationLowConfidence: TAIFluxoEtapaEvent`

---

### TAIDecisionAgent

**Função:** Agente decisor responsável por criar planos lógicos de tarefas e caminhos operacionais de ações.

> Herda de `TAICustomAgent`, portanto também possui integração com `TCHATGPT`, `SystemPrompt`, `MemoryMap`, auditoria automática e eventos comuns de execução.

- **Métodos (Public):**
  - `Decide(const AInput: string; out AOutput: string): Boolean` - Gera o plan de ação detalhado.
- **Eventos:**
  - `OnBeforeDecision: TAIFluxoEtapaControlEvent`
  - `OnAfterDecision: TAIFluxoEtapaEvent`
  - `OnBeforeActionPlanCreate: TAIFluxoEtapaControlEvent`
  - `OnAfterActionPlanCreate: TAIFluxoEtapaEvent`
  - `OnBeforeAddActionToPlan: TAIFluxoEtapaControlEvent`
  - `OnAfterAddActionToPlan: TAIFluxoEtapaEvent`
  - `OnInvalidActionSelected: TAIFluxoEtapaEvent`
  - `OnDecisionLowConfidence: TAIFluxoEtapaEvent`

---

### TAIActionBuilderAgent

**Função:** Agente ajustador responsável por validar parâmetros, injetar valores padrão e higienizar inputs inseguros.

> Herda de `TAICustomAgent`, usando o mapa de memória e o contexto acumulado para ajustar parâmetros, aplicar padrões e preparar ações planejadas.

- **Métodos (Public):**
  - `BuildActions(const AInput: string; out AOutput: string): Boolean` - Preenche, higieniza e detalha os parâmetros das ações planejadas.
  - `BuildActionsStrict(const AInput: string; out AOutput: string): Boolean` - Executa a montagem de ações de forma rígida, desabilitando a recuperação automática temporariamente.
  - `BuildActionsWithRecovery(const AInput: string; out AOutput: string): Boolean` - Executa a montagem de ações com recuperação automática ativada.
- **Propriedades (Published):**
  - `AutoRecoverInvalidInput: Boolean` - Se verdadeiro, o agente tentará recuperar automaticamente saídas inválidas do LLM fora do schema esperado. Padrão: `True`.
  - `MaxRecoverAttempts: Integer` - Quantidade máxima de tentativas de recuperação antes de retornar erro. Padrão: `1`.
  - `LastRawOutput: string` - Guarda a última resposta JSON bruta do LLM (útil para depuração).
  - `LastRecoveredOutput: string` - Guarda o último JSON recuperado com sucesso.
  - `LastValidationError: string` - Guarda o último erro de validação encontrado antes de iniciar a recuperação.
- **Eventos:**
  - `OnBeforeBuildAction: TAIFluxoEtapaControlEvent`
  - `OnAfterBuildAction: TAIFluxoEtapaEvent`
  - `OnBeforeValidateParameters: TAIFluxoEtapaControlEvent`
  - `OnAfterValidateParameters: TAIFluxoEtapaEvent`
  - `OnBeforeApplyDefaults: TAIFluxoEtapaControlEvent`
  - `OnAfterApplyDefaults: TAIFluxoEtapaEvent`
  - `OnMissingRequiredParameter: TAIFluxoEtapaEvent`
  - `OnUnsafeParameterDetected: TAIFluxoEtapaEvent`

### Recuperação automática no ActionBuilder

O `TAIActionBuilderAgent` valida automaticamente se a saída gerada pelo LLM está no formato correto e se contém o array de ações (`actions`). 
Caso a saída seja inválida ou esteja fora do layout obrigatório:
1. Ele intercepta o erro e armazena os detalhes no `LastValidationError`.
2. Se `AutoRecoverInvalidInput` estiver ativo, o componente efetua uma nova chamada ao ChatGPT enviando o contexto acumulado do mapa de memória, o input original enviado ao Builder, a saída inválida anterior e o erro de validação encontrado.
3. Solicita a reconstrução da intenção no formato obrigatório correto.
4. Caso a recuperação obtenha sucesso, o JSON recuperado é armazenado em `LastRecoveredOutput` e repassado para o fluxo; caso contrário, gera um erro de validação completo detalhando a falha.


---

### TAIActionExecutor

**Função:** Executor de planos de ação. Pode operar em modo simulado ou real (usando o registro de ações reais do tipo `TAICustomAgentAction`), registra a execução detalhada no mapa de memória, compartilha um contexto de execução dinâmico (`ExecutionContext`) e dispara eventos de ciclo de vida antes/depois da execução das ações reais preparadas.

- **Propriedades (Published/Public):**
  - `ChatGPT: TCHATGPT` - Conector ChatGPT.
  - `MemoryMap: TAIAgentMemoryMap` - Mapa de memória de auditoria.
  - `NomeAgente: string` - Identificador de auditoria do executor.
  - `TipoAgenteMapa: TAITipoAgenteMapa` - Tipo usado para registrar o executor no mapa de memória.
  - `ForcarSimulacaoGlobal: Boolean` - Se verdadeiro, nenhuma ação de hardware real será despachada, operando apenas de forma simulada.
  - `AutoRegistrarNoMapa: Boolean` - Loga automaticamente as etapas de execução no mapa.
  - `ExecutionContext: TStringList` - Contexto compartilhado para troca de dados entre ações subsequentes (ex: `browser.last_text` ou `last_text_content`).
- **Métodos (Public):**
  - `RegisterAction(AAction: TAICustomAgentAction)` - Registra uma ação concreta para execução real (ex: ações de e-mail, criação de arquivos ou automação do Chromium).
  - `ClearExecutionContext` - Limpa os parâmetros do contexto de execução acumulados.
  - `ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean` - Simula ou processa textualmente o plano de ações via LLM.
  - `ExecutePreparedActionsReal(const APreparedActionsJSON: string; out AOutput: string): Boolean` - Analisa o JSON de ações (array ou objeto) e executa de verdade cada uma delas se estiverem registradas, disparando os eventos de ciclo correspondentes.
- **Eventos:**
  - `OnBeforePreparedAction: TAIExecutorBeforePreparedActionEvent` - Disparado antes de rodar cada ação real. Permite modificar parâmetros de forma dinâmica ou cancelar a execução.
  - `OnAfterPreparedAction: TAIExecutorAfterPreparedActionEvent` - Disparado após o sucesso de cada ação. Permite colher retornos das ações e salvá-los no `ExecutionContext`.
  - `OnBeforeExecutePlan: TAIFluxoEtapaControlEvent`
  - `OnAfterExecutePlan: TAIFluxoEtapaEvent`
  - `OnBeforeExecutePlanItem: TAIFluxoEtapaControlEvent`
  - `OnAfterExecutePlanItem: TAIFluxoEtapaEvent`
  - `OnBeforeRealExecution: TAIFluxoEtapaControlEvent`
  - `OnAfterRealExecution: TAIFluxoEtapaEvent`
  - `OnBeforeSimulation: TAIFluxoEtapaControlEvent`
  - `OnAfterSimulation: TAIFluxoEtapaEvent`
  - `OnExecutionBlocked: TAIFluxoEtapaEvent`
  - `OnExecutionFailed: TAIFluxoEtapaEvent`

---

### TAIAgentMemoryMap

**Função:** Componente de auditoria e rastreamento de fluxo multiagente. Registra a solicitação original, cada etapa executada por agentes, análises, explicações, ações tomadas, parâmetros, saídas geradas, perguntas internas, alertas e possíveis perdas de informação.

Este componente não executa IA diretamente. Ele funciona como memória operacional, trilha de auditoria e fonte de contexto para os agentes especializados.

- **Propriedades (Published):**
  - `SessionId: string` - Identificador da sessão de execução.
  - `FlowName: string` - Nome do fluxo atual.
  - `SolicitacaoOriginal: string` - Pedido original recebido pelo fluxo.
  - `Usuario: string` - Identificação opcional do usuário associado ao fluxo.
  - `Origem: string` - Origem opcional da solicitação.
  - `AutoIncrementOrder: Boolean` - Controla incremento automático da ordem das etapas.
  - `CurrentOrder: Integer` - Ordem corrente usada no mapa.
  - `MaxItems: Integer` - Limite máximo de etapas mantidas em memória.
  - `StoreRawJSON: Boolean` - Indica se respostas JSON brutas podem ser preservadas.
  - `StoreFullPrompt: Boolean` - Flag reservada para controle de armazenamento de prompt completo.
  - `StoreFullResponse: Boolean` - Flag reservada para controle de armazenamento de resposta completa.
  - `DetectInformationLoss: Boolean` - Ativa a verificação heurística de possível perda de informação entre entrada e saída.
  - `RedactSensitiveData: Boolean` - Ativa mascaramento de dados sensíveis antes do armazenamento.
  - `Items: TAIAgentMemoryMapCollection` - Coleção de etapas registradas.
  - `LastItem: TAIAgentMemoryMapItem` - Última etapa registrada.
  - `LastWarning: string` - Último alerta gerado pelo mapa.

- **Métodos (Public):**
  - `StartFlow(const ASolicitacaoOriginal: string; const AFlowName: string = ''; const AUsuario: string = ''; const AOrigem: string = '')` - Inicializa um novo fluxo e registra a solicitação original.
  - `BeginAgentStep(const ANomeAgente: string; ATipoAgente: TAITipoAgenteMapa; const APedidoRecebido: string; const AContextoRecebido: string = ''; AOrdemPai: Integer = 0): TAIAgentMemoryMapItem` - Abre uma nova etapa no mapa para um agente.
  - `EndAgentStep(AItem: TAIAgentMemoryMapItem; const AAnalise: string; const AExplicacao: string; const AAcaoTomada: string; const ASaidaGerada: string; const AResumoParaProximoAgente: string = '')` - Finaliza uma etapa do mapa registrando análise, explicação, ação, saída e resumo.
  - `AddQuestion(AItem: TAIAgentMemoryMapItem; const APergunta: string; const AResposta: string; const AAnalise: string; const AOrigem: string = 'LLM'; const AConfianca: Double = 0)` - Adiciona pergunta interna de análise à etapa.
  - `AddActionParam(AItem: TAIAgentMemoryMapItem; const AName: string; const AValue: string)` - Adiciona parâmetro de ação à etapa.
  - `CheckInformationLoss(AItem: TAIAgentMemoryMapItem; out ALostInfo: string): Boolean` - Executa verificação heurística de possível perda de informação.
  - `BuildContextForAgent(const ANomeAgente: string; ATipoAgente: TAITipoAgenteMapa; const AMaxSteps: Integer = 10): string` - Gera contexto textual estruturado com o caminho percorrido até o momento.
  - `AsText: string` - Exporta o mapa em formato textual.
  - `AsJSON: string` - Exporta o mapa em JSON.
  - `SaveToFile(const AFileName: string)` - Salva o mapa em arquivo JSON.
  - `LoadFromFile(const AFileName: string)` - Carrega o mapa a partir de arquivo JSON.

- **Eventos:**
  - `OnBeforeCreateStep: TAIMapaBeforeCreateStepEvent` - Permite bloquear ou autorizar a criação de uma etapa.
  - `OnAfterCreateStep: TAIMapaStepEvent` - Disparado após criar uma etapa.
  - `OnBeforeCloseStep: TAIMapaStepEvent` - Disparado antes de finalizar uma etapa.
  - `OnAfterCloseStep: TAIMapaStepEvent` - Disparado após finalizar uma etapa.
  - `OnInformationLossDetected: TAIMapaInformationLossEvent` - Disparado quando possível perda de informação é detectada.
  - `OnMemoryMapLog: TAIMapaLogEvent` - Evento de log do mapa de memória.

#### Exemplo básico

```pascal
var
  Mapa: TAIAgentMemoryMap;
  Item: TAIAgentMemoryMapItem;
begin
  Mapa := TAIAgentMemoryMap.Create(nil);
  try
    Mapa.StartFlow(
      'Usuário solicitou manutenção urgente no equipamento.',
      'Fluxo de Atendimento',
      'usuario_teste',
      'demo'
    );

    Item := Mapa.BeginAgentStep(
      'ClassifierAgent',
      tamClassificador,
      'Classificar solicitação recebida'
    );

    Mapa.AddQuestion(
      Item,
      'Qual é a intenção principal?',
      'Solicitação de manutenção',
      'O texto indica falha operacional e urgência.',
      'LLM',
      0.95
    );

    Mapa.EndAgentStep(
      Item,
      'Solicitação classificada como manutenção.',
      'A prioridade foi considerada alta.',
      'CLASSIFIED_AND_ROUTED',
      'category=maintenance; priority=high',
      'Encaminhar para agente decisor.'
    );

    WriteLn(Mapa.AsText);
  finally
    Mapa.Free;
  end;
end;
```

---

### TAIAgentSafety

**Função:** Firewall operacional de IA. Intercepta requisições de agentes contra regras estritas antes de acessar arquivos locais, rede ou periféricos.

- **Propriedades (Published):**
  - `Enabled: Boolean` - Ativa ou desativa a auditoria de segurança (padrão `True`).
  - `RequireConfirmation: Boolean` - Requer intervenção ou aviso manual para confirmar ações (padrão `True`).
  - `ReadOnlyMode: Boolean` - Restringe operações de gravação e envio em hardware e arquivos (padrão `True`).
  - `SimulationMode: Boolean` - Força a execução simulada (padrão `True`).
  - `AllowFileWrite: Boolean` - Permite escrita no sistema de arquivos local.
  - `AllowNetwork: Boolean` - Permite requisições web e conexões remotas.
  - `AllowIndustrialWrite: Boolean` - Permite alterar registradores via Modbus/CLP.
  - `AllowEmailSend: Boolean` - Permite enviar e-mails de forma autônoma.
  - `SafeBasePath: string` - Diretório seguro fora do qual qualquer escrita é estritamente bloqueada.
  - `AllowedDomains: TStrings` - Domínios confiáveis permitidos na rede.
  - `AllowedPorts: TStrings` - Portas permitidas para sockets/redes.
  - `AllowedActions: TStrings` - Ações específicas cuja execução é liberada.
- **Métodos (Public):**
  - `ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean` - Valida se a ação atende aos critérios do firewall.
  - `ValidateFilePath(const AFileName: string; out AError: string): Boolean` - Valida se o arquivo de destino está no diretório seguro.
  - `ValidateURL(const AURL: string; out AError: string): Boolean` - Valida o domínio/URL requisitado.
- **Eventos:**
  - `OnConfirmAction: TAIConfirmActionEvent` - Permite interceptar via interface gráfica a confirmação humana para autorizar ações críticas.

---

### TAIPipeline

**Função:** Conector de dados linear para fluxos sequenciais. Encadeia operações textuais, redes neurais numéricas, despachos de agentes e saídas documentais.

- **Propriedades (Published):**
  - `Mode: TAIPipelineMode` - Modo de operação (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor, pmGraphMapClassification).
  - `ChatGPT: TCHATGPT` - Conector de chat associado.
  - `NeuralNetwork: TNeuralNetwork` - Rede neural numérica integrada.
  - `Agent: TAIAgent` - Agente de tomada de decisão associado.
  - `InputData: TAIInputData` - Canal de entrada de dados.
  - `OutputData: TAIOutputData` - Canal de saída de dados estruturados.
  - `OutputDocs: TAIOutputDocs` - Gerador de documentos de saída.
  - `InputText: string` - Entrada textual corrente.
  - `OutputText: string` - Saída textual resultante.
  - `BaseFileName: string` - Nome base para geração de relatórios físicos.
  - `SavePDF` / `SaveWord` / `SaveExcel` / `SaveTXT` - Booleans de exportação documental automática.
  - `GraphMap: TAIGraphMap` - Componente de grafos de classificação linguística.
- **Métodos (Public):**
  - `Run: Boolean` - Executa a lógica de pipeline definida pelo `Mode`.
  - `RunText(const AText: string): string` - Processamento simples de LLM.
  - `RunNumeric: Boolean` - Execução numérica via rede multicamadas local.
  - `RunAgent(const AInput: string): Boolean` - Dispara ciclo do agente e saídas mapeadas.

---

### TAIWizardConfig

**Função:** Assistente visual e construtor interativo passo-a-passo. Configura e vincula projetos, conexões LLM e pipelines de IA no Lazarus.

- **Propriedades (Published):**
  - `Project: TAIProject` - Projeto a ser configurado.
  - `ChatGPT: TCHATGPT` - Conector ChatGPT.
  - `Pipeline: TAIPipeline` - Pipeline de encadeamento.
  - `ModelRegistry: TAIModelRegistry` - Registro de modelos.
  - `PromptBuilder: TAIPromptBuilder` - Construtor de Prompts.
  - `ProjectType: string` - Tipo do projeto de IA (ex: "Chatbot", "Classificador").
  - `ProviderName: string` - Provedor de LLM configurado (OpenAI, Gemini, Local, etc.).
  - `ModelName: string` - Nome do modelo de linguagem.
  - `LocalURL: string` - Endpoint local de API (caso Ollama/Local).
  - `SafeMode: Boolean` - Habilita restrições globais de segurança.
  - `SimulationMode: Boolean` - Força o modo simulação do assistente.
- **Métodos (Public):**
  - `ConfigureVisual` - Abre o formulário visual interativo passo-a-passo (`TfrmAIWizardConfig`).
  - `Apply` - Aplica e injeta as configurações configuradas nos componentes vinculados.
  - `TestConnection: Boolean` - Testa a conexão HTTP e chaves contra o provedor de IA selecionado.
  - `SaveToFile(const AFileName: string)` - Serializa as configurações em arquivo JSON local.
  - `LoadFromFile(const AFileName: string)` - Restaura configurações salvas em disco.
