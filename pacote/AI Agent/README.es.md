# 🤖 Documentación de la pestaña AI Agent

Esta carpeta contiene la suite completa de componentes de Lazarus bajo la pestaña **AI Agent**, orientada a la orquestación cognitiva, toma de decisiones por agentes autónomos de IA e integraciones de hardware y flujos de trabajo (pipelines).

---

> **Compatibilidad:** los antiguos alias `TAIMapaDeMemoria`, `TAIMapaDeMemoriaItem`, `TAIMapaDeMemoriaCollection` y la propiedad `MapaDeMemoria` se han conservado temporalmente para no romper los proyectos existentes.

## 📋 Índice de Componentes

- [TAIAgent](#taiagent)
- [TAIAgentOptions](#taiagentoptions)
- [TAIAgentAction](#taiagentaction)
- [TAIAgentResource](#taiagentresource)
- [TAIAgentOutput](#taiagentoutput)
- [TAIAgentOrchestrator](#taiagentorchestrator)
- [TAIClassifierAgent](#taiclassifieragent)
- [TAIDecisionAgent](#taidecisionagent)
- [TAIActionBuilderAgent](#taiactionbuilderagent)
- [TAIActionExecutor](#taiactionexecutor)
- [TAIAgentMemoryMap](#taimapadememoria)
- [TAIAgentSafety](#taiagentsafety)
- [TAIPipeline](#taipipeline)
- [TAIWizardConfig](#taiwizardconfig)

---

## 🔍 Detalle de los Componentes

### TAIAgent

**Función:** Cerebro del agente cognitivo. Coordina la conversación con modelos de lenguaje (LLM) para planificar y ejecutar acciones basadas en el historial de sesión (memoria).

- **Propiedades (Published):**
  - `ChatGPT: TCHATGPT` - Conector de chat con el modelo de LLM.
  - `Options: TAIAgentOptions` - Preguntas y contexto operacional del agente.
  - `Action: TAIAgentAction` - Acciones permitidas y control de parámetros.
  - `Resource: TAIAgentResource` - Recursos físicos/digitales disponibles (correo electrónico, Modbus, etc.).
  - `Safety: TAIAgentSafety` - Filtro y políticas de seguridad para la ejecución de acciones.
  - `SystemPrompt: string` - Prompt de sistema personalizado que guía al agente.
  - `LastRationale: string` - Justificación de la última decisión generada por la IA (sólo lectura).
  - `Memory: TStrings` - Historial de la conversación en memoria de contexto.
  - `MaxMemoryLimit: Integer` - Límite de tamaño de memoria.
  - `MaxRetries: Integer` - Límite de intentos para un formato JSON válido.
  - `LastDecision: TAIAgentDecision` - Datos detallados de la última acción y parámetros calculados (sólo lectura).
- **Métodos (Public):**
  - `Execute(const AInputData: string): Boolean` - Envía la solicitud del usuario, ejecuta el análisis de IA, infiere la acción y llama a la ejecución correspondiente.
  - `ClearMemory` - Limpia el historial de memoria/conversaciones.
- **Eventos:**
  - `OnActionTriggered: TAgentActionEvent` - Disparado cuando el agente decide una acción y la despacha con parámetros.

---

### TAIAgentOptions

**Função:** Almacena preguntas estructuradas y el contexto básico de soporte que alimenta el análisis de `TAIAgent`.

- **Propiedades (Published):**
  - `Questions: TStrings` - Lista de preguntas estructuradas de verificación.
  - `Context: string` - Descripción textual detallada de las reglas de negocio.
  - `Action: TAIAgentAction` - Acción asociada a estas opciones.

---

### TAIAgentAction

**Función:** Define la lista de acciones que la IA puede decidir ejecutar y valida los parámetros generados contra un esquema.

- **Propiedades (Published):**
  - `AllowedActions: TStrings` - Lista de las acciones permitidas (ej: `ENVIAR_CORREO`, `ENCENDER_RELE`).
  - `ParameterDefinitions: TStrings` - Definiciones de los parámetros esperados para cada acción (usualmente en formato JSON).
  - `SelectedAction: string` - La acción elegida en la última ejecución de la IA.
  - `SelectedParameters: TStrings` - Clave=Valor de los parámetros generados para la acción actual.
- **Métodos (Public):**
  - `ClearSelection` - Limpia la acción y los parámetros seleccionados.
  - `GetParamValue(const AName: string): string` - Retorna el valor de un parámetro seleccionado.
  - `TriggerAction(const AActionName: string; AParams: TStrings)` - Fuerza el disparo manual o simulado de una acción.
- **Eventos:**
  - `OnExecuteAction: TAgentActionEvent` - Disparado para ejecutar la rutina física de la acción.

---

### TAIAgentResource

**Función:** Catálogo que registra las conexiones físicas y componentes externos (correo, redes, sensores, bases de datos) disponibles para la IA.

- **Propiedades (Published):**
  - `Resources: TAIAgentResourceCollection` - Colección de recursos configurados. Cada recurso (`TAIAgentResourceItem`) posee propiedades como `Name`, `ResourceType` (artEmail, artFile, etc.), `Host`, `Port`, `Sender`, `Recipient`, `FilePath`, `APIUrl`, `Headers`, `Config` y `Component` (conexión directa con componentes reales como `TAIEmailClient` o `TAIMqttClient`).
- **Métodos (Public):**
  - `FindResource(const AName: string): TAIAgentResourceItem` - Localiza un recurso por su nombre.

---

### TAIAgentOutput

**Función:** Componente de enlace automático. Conecta las decisiones lógicas de `TAIAgentAction` con los manejadores configurados en `TAIAgentResource`.

- **Propiedades (Published):**
  - `Action: TAIAgentAction` - Referencia para escuchar el disparo de decisiones.
  - `Resource: TAIAgentResource` - Catálogo de recursos configurados.
  - `Mappings: TAIAgentOutputMappingCollection` - Asociación que vincula ActionName con ResourceName.
  - `LastExecutionLog: string` - Registro de logs detallados del último despacho.
- **Métodos (Public):**
  - `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` - Despacha dinámicamente comandos llamando al recurso correspondiente.
- **Eventos:**
  - `OnOutputExecuted: TAIAgentOutputEvent` - Disparado post-ejecución indicando éxito, logs y parámetros.

---

### TAIAgentOrchestrator

**Función:** Coordinador cognitivo central. Coordina flujos de trabajo a través de múltiples agentes especializados y gestiona el ciclo cognitivo.

- **Propiedades (Published):**
  - `ChatGPT: TCHATGPT` - Conector con el modelo LLM.
  - `MemoryMap: TAIAgentMemoryMap` - Historial operativo compartido entre etapas.
  - `CriarMapaAutomaticamente: Boolean` - Instancia un mapa de memoria temporal si no se asocia ninguno.
  - `Classifier: TAIClassifierAgent` - Agente de clasificación inicial.
  - `DecisionAgent: TAIDecisionAgent` - Agente decisor de planes de acción.
  - `ActionBuilder: TAIActionBuilderAgent` - Agente de validación y ajuste de parámetros.
  - `Executor: TAIActionExecutor` - Agente encargado del simulacro o ejecución física.
- **Métodos (Public):**
  - `Run(const AInput: string): Boolean` - Inicia y ejecuta secuencialmente el ciclo multiagente completo (Clasificar -> Decidir -> Ajustar -> Ejecutar).
- **Eventos:**
  - `OnBeforeFlowStart` / `OnAfterFlowStart` - Eventos de inicio y fin del ciclo.
  - `OnBeforeClassifier` / `OnAfterClassifier` - Interceptores de clasificación.
  - `OnBeforeDecisionAgent` / `OnAfterDecisionAgent` - Interceptores de toma de decisión.
  - `OnBeforeActionBuilder` / `OnAfterActionBuilder` - Interceptores de parámetros.
  - `OnBeforeExecutor` / `OnAfterExecutor` - Interceptores de ejecución.
  - `OnBeforeActionExecute` / `OnAfterActionExecute` - Interceptores de despacho físico.
  - `OnInformationLossDetected` - Disparado si se detecta pérdida de información crítica.
  - `OnFlowError` - Disparado en caso de fallos generales.
  - `OnFlowCanceled` - Permite abortar la ejecución.
  - `OnFlowFinished` - Finalización global exitosa.

---

### TAIClassifierAgent

**Función:** Agente especialista en clasificación, priorización y triaje inicial de peticiones.

- **Métodos (Public):**
  - `Classify(const AInput: string; out AOutput: string): Boolean` - Clasifica y orienta la petición del usuario.
- **Eventos:**
  - `OnBeforeClassify: TAIFluxoEtapaControlEvent`
  - `OnAfterClassify: TAIFluxoEtapaEvent`
  - `OnBeforeSelectTargetAgents: TAIFluxoEtapaControlEvent`
  - `OnAfterSelectTargetAgents: TAIFluxoEtapaEvent`
  - `OnClassificationLowConfidence: TAIFluxoEtapaEvent`

---

### TAIDecisionAgent

**Función:** Agente planificador que mapea las tareas a flujos lógicos y planes de acción específicos.

- **Métodos (Public):**
  - `Decide(const AInput: string; out AOutput: string): Boolean` - Genera el plan de tareas detallado.
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

**Función:** Agente encargado de refinar y validar parámetros, inyectar valores predeterminados y asegurar entradas seguras.

- **Métodos (Public):**
  - `BuildActions(const AInput: string; out AOutput: string): Boolean` - Completa, sanea y detalla los parámetros de las acciones.
- **Eventos:**
  - `OnBeforeBuildAction: TAIFluxoEtapaControlEvent`
  - `OnAfterBuildAction: TAIFluxoEtapaEvent`
  - `OnBeforeValidateParameters: TAIFluxoEtapaControlEvent`
  - `OnAfterValidateParameters: TAIFluxoEtapaEvent`
  - `OnBeforeApplyDefaults: TAIFluxoEtapaControlEvent`
  - `OnAfterApplyDefaults: TAIFluxoEtapaEvent`
  - `OnMissingRequiredParameter: TAIFluxoEtapaEvent`
  - `OnUnsafeParameterDetected: TAIFluxoEtapaEvent`

---

### TAIActionExecutor

**Función:** Simulador y ejecutor de planes de acción. Integra y despacha las llamadas finales mediante `TAIAgentOutput`.

- **Propiedades (Published):**
  - `ChatGPT: TCHATGPT` - Conector de IA.
  - `MemoryMap: TAIAgentMemoryMap` - Auditoría de memoria.
  - `ForcarSimulacaoGlobal: Boolean` - Si está activo, no ejecuta cambios físicos (modo demo/simulado).
  - `AutoRegistrarNoMapa: Boolean` - Registra automáticamente pasos lógicos en el mapa.
- **Métodos (Public):**
  - `ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean` - Procesa y ejecuta el listado de tareas.
- **Eventos:**
  - `OnBeforeExecutePlan: TAIFluxoEtapaControlEvent`
  - `OnAfterExecutePlan: TAIFluxoEtapaEvent`
  - `OnBeforeRealExecution: TAIFluxoEtapaControlEvent`
  - `OnAfterRealExecution: TAIFluxoEtapaEvent`
  - `OnExecutionBlocked: TAIFluxoEtapaEvent`
  - `OnExecutionFailed: TAIFluxoEtapaEvent`

---

### TAIAgentMemoryMap

**Función:** Registro estructurado que conserva y audita las etapas y datos del flujo cognitivo multiagente, con algoritmos contra pérdida de contexto.

- **Propiedades (Published):**
  - `SessionId: string` - Identificador de sesión.
  - `FlowName: string` - Nombre identificador del flujo.
  - `Items: TAIAgentMemoryMapItem` - Lista ordenada de pasos y análisis de los agentes.
  - `DetectInformationLoss: Boolean` - Si está activo, analiza el flujo para verificar si algún agente omitió datos críticos introducidos originalmente por el usuario.
- **Métodos (Public):**
  - `StartFlow(const AFlowName: string; const AInput: string)` - Inicia el log del flujo.
  - `BuildContextForAgent(const ANomeAgente: string): string` - Consolida el historial en un formato XML optimizado para guiar al siguiente LLM.
- **Eventos:**
  - `OnInformationLossDetected: TAIFluxoEtapaEvent` - Disparado si se detecta la omisión de algún parámetro crítico original.

---

### TAIAgentSafety

**Función:** Firewall de seguridad operacional de IA. Intercepta llamadas contra políticas locales antes de permitir operaciones físicas.

- **Propiedades (Published):**
  - `Enabled: Boolean` - Activa la seguridad (por defecto `True`).
  - `RequireConfirmation: Boolean` - Exige consentimiento humano antes de actuar (por defecto `True`).
  - `ReadOnlyMode: Boolean` - Bloquea la edición física (por defecto `True`).
  - `AllowFileWrite: Boolean` - Permite escritura en disco local.
  - `AllowNetwork: Boolean` - Permite peticiones de red remota.
  - `SafeBasePath: string` - Directorio seguro fuera del cual toda escritura se bloquea.
- **Métodos (Public):**
  - `ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean` - Valida la acción lógica.
  - `ValidateFilePath(const AFileName: string; out AError: string): Boolean` - Valida los directorios de archivos.
- **Eventos:**
  - `OnConfirmAction: TAIConfirmActionEvent` - Intercepta el flujo para solicitar confirmación manual visual.

---

### TAIPipeline

**Función:** Conector lineal de datos. Encadena flujos de texto, redes neuronales locales, ejecuciones de agentes y exportaciones documentales.

- **Propiedades (Published):**
  - `Mode: TAIPipelineMode` - Modo de ejecución.
  - `ChatGPT: TCHATGPT` - Conector ChatGPT.
  - `NeuralNetwork: TNeuralNetwork` - Red neuronal multicapa (MLP).
  - `Agent: TAIAgent` - Agente de IA.
  - `OutputDocs: TAIOutputDocs` - Generador de archivos y reportes.
  - `SavePDF` / `SaveWord` / `SaveExcel` / `SaveTXT` - Booleans de exportación automática.
- **Métodos (Public):**
  - `Run: Boolean` - Ejecuta la lógica del pipeline.
  - `RunNumeric: Boolean` - Ejecución matemática/neuronal local.

---

### TAIWizardConfig

**Función:** Asistente interactivo paso a paso. Configura y vincula proyectos de IA, proveedores de LLM y pipelines en Lazarus.

- **Propiedades (Published):**
  - `Project: TAIProject` - Proyecto a configurar.
  - `ChatGPT: TCHATGPT` - Instancia ChatGPT.
  - `SafeMode: Boolean` - Habilita políticas de seguridad globales.
- **Métodos (Public):**
  - `ConfigureVisual` - Renders interactivos paso a paso en pantalla (`TfrmAIWizardConfig`).
  - `Apply` - Propaga los ajustes a los componentes asociados.
  - `SaveToFile(const AFileName: string)` - Guarda ajustes en formato JSON.
