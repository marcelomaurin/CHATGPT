# 🤖 AI Agent Tab Documentation

This directory contains the complete suite of Lazarus components under the **AI Agent** tab, focusing on cognitive orchestration, autonomous AI decision making, and hardware/pipeline integrations.

---

## 📋 Component Index

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
- [TAIMapaDeMemoria](#taimapadememoria)
- [TAIAgentSafety](#taiagentsafety)
- [TAIPipeline](#taipipeline)
- [TAIWizardConfig](#taiwizardconfig)

---

## 🔍 Component Details

### TAIAgent

**Function:** The core brain of the cognitive agent. It coordinates conversations with LLMs to plan and trigger actions based on session memory.

- **Properties (Published):**
  - `ChatGPT: TCHATGPT` - Connection component to the LLM model.
  - `Options: TAIAgentOptions` - Structuring questions and operational context.
  - `Action: TAIAgentAction` - Allowed actions and parameter definitions.
  - `Resource: TAIAgentResource` - Digital/physical resources available (email, Modbus, files).
  - `Safety: TAIAgentSafety` - Safety firewall restricting arbitrary execution.
  - `SystemPrompt: string` - Customizable system prompt guiding the model's behavior.
  - `LastRationale: string` - Explanatory rationale behind the last decision (read-only).
  - `Memory: TStrings` - Local context memory list.
  - `MaxMemoryLimit: Integer` - Limit of memory context entries.
  - `MaxRetries: Integer` - Max retry attempts for correct JSON/schema formatting.
  - `LastDecision: TAIAgentDecision` - Structured details of the last decided action and parameters (read-only).
- **Methods (Public):**
  - `Execute(const AInputData: string): Boolean` - Processes user input, performs analysis, infers the best action, and triggers the output.
  - `ClearMemory` - Clears the agent's memory history.
- **Events:**
  - `OnActionTriggered: TAgentActionEvent` - Dispatched when the agent makes a decision and dispatches an action.

---

### TAIAgentOptions

**Function:** Holds structured checklist questions and support context to guide the main `TAIAgent` analysis.

- **Properties (Published):**
  - `Questions: TStrings` - Structured verification questions.
  - `Context: string` - Deep business rules context text.
  - `Action: TAIAgentAction` - Linked action component.

---

### TAIAgentAction

**Function:** Defines target actions and validates generated parameters against a pre-declared schema.

- **Properties (Published):**
  - `AllowedActions: TStrings` - List of allowed actions (e.g. `SEND_EMAIL`, `ACTIVATE_RELAY`).
  - `ParameterDefinitions: TStrings` - Expected parameters for each action (usually represented as JSON schemas).
  - `SelectedAction: string` - Last decided action name.
  - `SelectedParameters: TStrings` - Key=Value parameters generated for the active action.
- **Methods (Public):**
  - `ClearSelection` - Clears selected actions/parameters.
  - `GetParamValue(const AName: string): string` - Retrieves selected parameter values.
  - `TriggerAction(const AActionName: string; AParams: TStrings)` - Simulates or triggers a manual action dispatch.
- **Events:**
  - `OnExecuteAction: TAgentActionEvent` - Dispatched to trigger the actual code routine.

---

### TAIAgentResource

**Function:** Catalog of active physical connections and components (emails, networks, PLCs, DBs) available for agent interaction.

- **Properties (Published):**
  - `Resources: TAIAgentResourceCollection` - Configured collection items. Each resource item (`TAIAgentResourceItem`) defines properties like `Name`, `ResourceType` (artEmail, artFile, etc.), `Host`, `Port`, `Sender`, `Recipient`, `FilePath`, `APIUrl`, `Headers`, `Config`, and `Component` (direct connection to client classes like `TAIEmailClient` or `TAIMqttClient`).
- **Methods (Public):**
  - `FindResource(const AName: string): TAIAgentResourceItem` - Locates a configured resource by name.

---

### TAIAgentOutput

**Function:** Dispatch router mapping. Connects logical actions declared in `TAIAgentAction` to the handlers configured in `TAIAgentResource`.

- **Properties (Published):**
  - `Action: TAIAgentAction` - Source action dispatcher component.
  - `Resource: TAIAgentResource` - Source resources catalog.
  - `Mappings: TAIAgentOutputMappingCollection` - Map linking ActionNames to ResourceNames.
  - `LastExecutionLog: string` - Log details from the last execution.
- **Methods (Public):**
  - `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` - Dynamically dispatches execution commands to mapped resources.
- **Events:**
  - `OnOutputExecuted: TAIAgentOutputEvent` - Triggered post execution with success flags, runtime logs, and parameters.

---

### TAIAgentOrchestrator

**Function:** Cognitive coordinator of multi-agent workflows. Orchestrates sequential analysis steps through specialized agents.

- **Properties (Published):**
  - `ChatGPT: TCHATGPT` - Conector to the LLM model.
  - `MapaDeMemoria: TAIMapaDeMemoria` - Shared operational memory map.
  - `CriarMapaAutomaticamente: Boolean` - Automatically instances a local memory map if none is linked.
  - `Classifier: TAIClassifierAgent` - Linked classification specialist.
  - `DecisionAgent: TAIDecisionAgent` - Linked action plan planner.
  - `ActionBuilder: TAIActionBuilderAgent` - Linked parameter validator.
  - `Executor: TAIActionExecutor` - Linked dispatcher/simulation executor.
- **Methods (Public):**
  - `Run(const AInput: string): Boolean` - Runs the complete multi-agent pipeline (Classify -> Decide -> Build -> Execute).
- **Events:**
  - `OnBeforeFlowStart` / `OnAfterFlowStart` - Flow start and end hooks.
  - `OnBeforeClassifier` / `OnAfterClassifier` - Classification stage hooks.
  - `OnBeforeDecisionAgent` / `OnAfterDecisionAgent` - Decision stage hooks.
  - `OnBeforeActionBuilder` / `OnAfterActionBuilder` - Action building stage hooks.
  - `OnBeforeExecutor` / `OnAfterExecutor` - Action execution stage hooks.
  - `OnBeforeActionExecute` / `OnAfterActionExecute` - Physical dispatch hooks.
  - `OnInformationLossDetected` - Triggered when the memory map detects LLM forgot key data.
  - `OnFlowError` - Triggered on general flow failures.
  - `OnFlowCanceled` - Allows workflow abort.
  - `OnFlowFinished` - Flow successful completion hook.

---

### TAIClassifierAgent

**Function:** Triaging agent focusing on initial intent classification and routing.

- **Methods (Public):**
  - `Classify(const AInput: string; out AOutput: string): Boolean` - Formats intent to guide downstream steps.
- **Events:**
  - `OnBeforeClassify: TAIFluxoEtapaControlEvent`
  - `OnAfterClassify: TAIFluxoEtapaEvent`
  - `OnBeforeSelectTargetAgents: TAIFluxoEtapaControlEvent`
  - `OnAfterSelectTargetAgents: TAIFluxoEtapaEvent`
  - `OnClassificationLowConfidence: TAIFluxoEtapaEvent`

---

### TAIDecisionAgent

**Function:** Planning agent responsible for mapping input tasks to specific logical plans and pipelines.

- **Methods (Public):**
  - `Decide(const AInput: string; out AOutput: string): Boolean` - Computes the action plan.
- **Events:**
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

**Function:** Parameter refinement agent, responsible for sanitization, defaults injection, and format validations.

- **Methods (Public):**
  - `BuildActions(const AInput: string; out AOutput: string): Boolean` - Validates and details parameters for the chosen actions.
- **Events:**
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

**Function:** Safe plan dispatcher. Evaluates preconditions, handles simulation mode, and executes actions.

- **Properties (Published):**
  - `ChatGPT: TCHATGPT` - Linked ChatGPT component.
  - `MapaDeMemoria: TAIMapaDeMemoria` - Linked memory map.
  - `NomeAgente: string` - Agent identifier.
  - `ForcarSimulacaoGlobal: Boolean` - Forces mock/simulation mode globally (no physical changes will occur).
  - `AutoRegistrarNoMapa: Boolean` - Automatically registers logs in the memory map.
- **Methods (Public):**
  - `ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean` - Dispatches action items.
- **Events:**
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

### TAIMapaDeMemoria

**Function:** Context preservation ledger. Logs multi-agent steps and implements information loss protection algorithms.

- **Properties (Published):**
  - `SessionId: string` - Current session ID identifier.
  - `FlowName: string` - Flow stage identifier.
  - `Items: TAIMapaDeMemoriaItem` - List of steps taken (requests, rationale, outputs, confidence).
  - `DetectInformationLoss: Boolean` - Checks intermediate stages to detect if the LLM forgot key data (like email addresses or tokens) provided by the user originally.
- **Methods (Public):**
  - `StartFlow(const AFlowName: string; const AInput: string)` - Logs initial user input and workflow name.
  - `BeginAgentStep(const ANomeAgente: string; ATipo: TAITipoAgenteMapa; const AInput: string)` - Flags starting step for an agent.
  - `EndAgentStep(const ANomeAgente: string; const AOutput: string; const AExplanation: string; AConfidence: Double)` - Flags finished step for an agent.
  - `BuildContextForAgent(const ANomeAgente: string): string` - Builds structured XML context from history to feed the next LLM model efficiently.
- **Events:**
  - `OnInformationLossDetected: TAIFluxoEtapaEvent` - Dispatched when data loss is detected.

---

### TAIAgentSafety

**Function:** Operational AI firewall. Audits actions before executing file writes, network calls, or PLC writes.

- **Properties (Published):**
  - `Enabled: Boolean` - Toggles firewall auditing (default `True`).
  - `RequireConfirmation: Boolean` - Prompts for user confirmation (default `True`).
  - `ReadOnlyMode: Boolean` - Restricts write/post commands (default `True`).
  - `SimulationMode: Boolean` - Forces simulation outputs (default `True`).
  - `AllowFileWrite: Boolean` - Allows local file output.
  - `AllowNetwork: Boolean` - Allows HTTP requests.
  - `AllowIndustrialWrite: Boolean` - Allows changing registers in PLCs/Modbus.
  - `AllowEmailSend: Boolean` - Allows calling mail sending functions.
  - `SafeBasePath: string` - Root path limit for safe file writes.
  - `AllowedDomains: TStrings` - White-listed network domains.
  - `AllowedPorts: TStrings` - White-listed network ports.
  - `AllowedActions: TStrings` - White-listed actions.
- **Methods (Public):**
  - `ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean` - Validates actions.
  - `ValidateFilePath(const AFileName: string; out AError: string): Boolean` - Validates file path targets.
  - `ValidateURL(const AURL: string; out AError: string): Boolean` - Validates web target.
- **Events:**
  - `OnConfirmAction: TAIConfirmActionEvent` - Handshake event requesting human-in-the-loop validation.

---

### TAIPipeline

**Function:** Sequential pipeline coordinator. Chains inputs, LLM processing, neural network calculations, and document generation outputs.

- **Properties (Published):**
  - `Mode: TAIPipelineMode` - Workflow mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor, pmGraphMapClassification).
  - `ChatGPT: TCHATGPT` - Linked ChatGPT component.
  - `NeuralNetwork: TNeuralNetwork` - Linked local MLP Neural Network.
  - `Agent: TAIAgent` - Linked AI Agent.
  - `InputData: TAIInputData` - Linked data input.
  - `OutputData: TAIOutputData` - Linked data output.
  - `OutputDocs: TAIOutputDocs` - Linked document output.
  - `InputText: string` - Current textual input.
  - `OutputText: string` - Resulting textual output.
  - `BaseFileName: string` - Document path prefix.
  - `SavePDF` / `SaveWord` / `SaveExcel` / `SaveTXT` - Automated document exporters.
  - `GraphMap: TAIGraphMap` - Token graph classifier.
- **Methods (Public):**
  - `Run: Boolean` - Triggers the pipeline execution.
  - `RunText(const AText: string): string` - Text model processing.
  - `RunNumeric: Boolean` - Local MLP Neural Network calculation.
  - `RunAgent(const AInput: string): Boolean` - Runs AI Agent decisions.

---

### TAIWizardConfig

**Function:** Step-by-step setup wizard component. Links projects, prompt builders, and LLMs interactively.

- **Properties (Published):**
  - `Project: TAIProject` - Current project component.
  - `ChatGPT: TCHATGPT` - Linked LLM connector.
  - `Pipeline: TAIPipeline` - Linked pipeline runner.
  - `ModelRegistry: TAIModelRegistry` - Linked model registry.
  - `PromptBuilder: TAIPromptBuilder` - Linked prompt builder.
  - `ProjectType: string` - Project intent description.
  - `ProviderName: string` - LLM service provider name.
  - `ModelName: string` - Target model name.
  - `LocalURL: string` - Local endpoint URL.
  - `SafeMode: Boolean` - Safety rules toggle.
  - `SimulationMode: Boolean` - Interactive simulation helper.
- **Methods (Public):**
  - `ConfigureVisual` - Renders the visual wizard form (`TfrmAIWizardConfig`).
  - `Apply` - Binds configurations to all linked sub-components.
  - `TestConnection: Boolean` - Tests connection credentials.
  - `SaveToFile(const AFileName: string)` - Saves settings to JSON config.
  - `LoadFromFile(const AFileName: string)` - Loads settings from JSON config.
