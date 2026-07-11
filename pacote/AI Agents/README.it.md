# 🤖 Documentazione della scheda AI Agent

Questa cartella contiene la suite completa dei componenti Lazarus sotto la scheda **AI Agent**, orientata all'orchestrazione cognitiva, al processo decisionale tramite agenti IA autonomi e alle integrazioni di hardware e flussi di lavoro (pipeline).

---

> **Compatibilità:** i vecchi alias `TAIMapaDeMemoria`, `TAIMapaDeMemoriaItem`, `TAIMapaDeMemoriaCollection` e la proprietà `MapaDeMemoria` sono stati temporaneamente mantenuti per non interrompere i progetti esistenti.

## 📋 Indice dei Componenti

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

## 🔍 Dettagli dei Componenti

### TAIAgent

**Funzione:** Cervello dell'agente cognitivo. Coordina le conversazioni con i modelli LLM per pianificare ed eseguire azioni basate sulla cronologia di sessione (memoria).

- **Proprietà (Published):**
  - `ChatGPT: TCHATGPT` - Connettore di comunicazione con il modello LLM.
  - `Options: TAIAgentOptions` - Domande e contesto operativo dell'agente.
  - `Action: TAIAgentAction` - Azioni consentite e controllo dei parametri.
  - `Resource: TAIAgentResource` - Risorse fisiche/digitali disponibili (e-mail, Modbus, ecc.).
  - `Safety: TAIAgentSafety` - Filtro e politiche di sicurezza per l'esecuzione di azioni.
  - `SystemPrompt: string` - Prompt di sistema personalizzato che guida l'agente.
  - `LastRationale: string` - Giustificazione dell'ultima decisione generata dall'IA (sola lettura).
  - `Memory: TStrings` - Cronologia delle conversazioni in memoria di contesto.
  - `MaxMemoryLimit: Integer` - Limite di dimensione della memoria.
  - `MaxRetries: Integer` - Limite di tentativi per ottenere un formato JSON valido.
  - `LastDecision: TAIAgentDecision` - Informazioni dettagliate sull'ultima azione e parametri calcolati (sola lettura).
- **Metodi (Public):**
  - `Execute(const AInputData: string): Boolean` - Invia la richiesta dell'utente, analizza tramite IA, deduce l'azione e chiama la corrispondente esecuzione fisica.
  - `ClearMemory` - Pulisce la cronologia di sessione.
- **Eventi:**
  - `OnActionTriggered: TAgentActionEvent` - Generato quando l'agente decide un'azione e la distribuisce con parametri.

---

### TAIAgentOptions

**Funzione:** Contiene domande strutturate e il contesto di base di supporto che alimenta l'analisi del `TAIAgent`.

- **Proprietà (Published):**
  - `Questions: TStrings` - Lista di domande strutturate di verifica.
  - `Context: string` - Descrizione testuale dettagliata delle regole aziendali.
  - `Action: TAIAgentAction` - Azione associata a queste opzioni.

---

### TAIAgentAction

**Funzione:** Definisce la lista delle azioni che l'IA può decidere di eseguire e valida i parametri generati rispetto a uno schema.

- **Proprietà (Published):**
  - `AllowedActions: TStrings` - Lista delle azioni consentite (es: `SEND_EMAIL`, `ACTIVATE_RELAY`).
  - `ParameterDefinitions: TStrings` - Schema dei parametri attesi per ogni azione (di solito in formato JSON).
  - `SelectedAction: string` - L'ultima azione decisa dall'IA.
  - `SelectedParameters: TStrings` - Coppie Chiave=Valore dei parametri generati per l'azione corrente.
- **Metodi (Public):**
  - `ClearSelection` - Reimposta l'azione e i parametri selezionati.
  - `GetParamValue(const AName: string): string` - Recupera il valore di un parametro selezionato.
  - `TriggerAction(const AActionName: string; AParams: TStrings)` - Forza l'esecuzione manuale o simulata di un'azione.
- **Eventi:**
  - `OnExecuteAction: TAgentActionEvent` - Generato per eseguire la routine fisica associata all'azione.

---

### TAIAgentResource

**Funzione:** Catalogo che mappa le connessioni fisiche e i componenti esterni (e-mail, reti, sensori, database) disponibili per l'IA.

- **Proprietà (Published):**
  - `Resources: TAIAgentResourceCollection` - Collezione di risorse configurate. Ogni elemento (`TAIAgentResourceItem`) definisce proprietà come `Name`, `ResourceType` (artEmail, artFile, ecc.), `Host`, `Port`, `Sender`, `Recipient`, `FilePath`, `APIUrl`, `Headers`, `Config` e `Component` (collegamento diretto a componenti reali come `TAIEmailClient` o `TAIMqttClient`).
- **Metodi (Public):**
  - `FindResource(const AName: string): TAIAgentResourceItem` - Ricerca una risorsa configurata tramite nome.

---

### TAIAgentOutput

**Funzione:** Gestore di instradamento dell'esecuzione. Associa le decisioni logiche di `TAIAgentAction` ai gestori configurati in `TAIAgentResource`.

- **Proprietà (Published):**
  - `Action: TAIAgentAction` - Componente di azioni sorgente da ascoltare.
  - `Resource: TAIAgentResource` - Catalogo di risorse sorgente.
  - `Mappings: TAIAgentOutputMappingCollection` - Map che collega ActionName a ResourceName.
  - `LastExecutionLog: string` - Dettaglio dei log dell'ultimo invio.
- **Metodi (Public):**
  - `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` - Invia dinamicamente l'ordine di esecuzione alla risorsa mappata.
- **Eventi:**
  - `OnOutputExecuted: TAIAgentOutputEvent` - Generato dopo l'esecuzione indicando successo, log di runtime e parametri.

---

### TAIAgentOrchestrator

**Funzione:** Coordinatore cognitivo centrale. Coordina flussi di elaborazione complessi attraverso più agenti specializzati e gestisce il ciclo cognitivo globale.

- **Proprietà (Published):**
  - `ChatGPT: TCHATGPT` - Connettore LLM.
  - `MemoryMap: TAIAgentMemoryMap` - Memoria operativa condivisa.
  - `CriarMapaAutomaticamente: Boolean` - Crea automaticamente una memoria temporanea se nessuna è collegata.
  - `Classifier: TAIClassifierAgent` - Agente di classificazione iniziale.
  - `DecisionAgent: TAIDecisionAgent` - Agente decisore del piano d'azione.
  - `ActionBuilder: TAIActionBuilderAgent` - Agente di convalida e regolazione dei parametri.
  - `Executor: TAIActionExecutor` - Agente incaricato della simulazione o dell'esecuzione fisica.
- **Metodi (Public):**
  - `Run(const AInput: string): Boolean` - Avvia ed esegue sequenzialmente l'intero ciclo multi-agente (Classifica -> Decidi -> Regola -> Esegui).
- **Eventi:**
  - `OnBeforeFlowStart` / `OnAfterFlowStart` - Eventi di inizio e fine ciclo.
  - `OnBeforeClassifier` / `OnAfterClassifier` - Fase di classificazione.
  - `OnBeforeDecisionAgent` / `OnAfterDecisionAgent` - Fase di decisione.
  - `OnBeforeActionBuilder` / `OnAfterActionBuilder` - Fase di elaborazione dei parametri.
  - `OnBeforeExecutor` / `OnAfterExecutor` - Fase di esecuzione.
  - `OnBeforeActionExecute` / `OnAfterActionExecute` - Fase di invio fisico.
  - `OnInformationLossDetected` - Generato se vengono rilevati dati dimenticati dall'LLM tra una fase e l'altra.
  - `OnFlowError` - Generato su errore globale.
  - `OnFlowFinished` - Generato sul completamento corretto del flusso.

---

### TAIClassifierAgent

**Funzione:** Agente specializzato nel filtraggio iniziale e nella classificazione dell'intenzione.

- **Metodi (Public):**
  - `Classify(const AInput: string; out AOutput: string): Boolean` - Classifica e orienta la richiesta.
- **Eventi:**
  - `OnBeforeClassify: TAIFluxoEtapaControlEvent`
  - `OnAfterClassify: TAIFluxoEtapaEvent`
  - `OnClassificationLowConfidence: TAIFluxoEtapaEvent`

---

### TAIDecisionAgent

**Funzione:** Agente di pianificazione responsabile della definizione del piano di compiti logico necessario per la richiesta.

- **Metodi (Public):**
  - `Decide(const AInput: string; out AOutput: string): Boolean` - Calcola il piano di compiti.
- **Eventi:**
  - `OnBeforeDecision: TAIFluxoEtapaControlEvent`
  - `OnAfterDecision: TAIFluxoEtapaEvent`
  - `OnInvalidActionSelected: TAIFluxoEtapaEvent`
  - `OnDecisionLowConfidence: TAIFluxoEtapaEvent`

---

### TAIActionBuilderAgent

**Funzione:** Agente di regolazione incaricato di convalidare i parametri, iniettare valori predefiniti e igienizzare gli input.

- **Metodi (Public):**
  - `BuildActions(const AInput: string; out AOutput: string): Boolean` - Igienizza e dettaglia i parametri delle azioni pianificate.
- **Eventi:**
  - `OnBeforeBuildAction: TAIFluxoEtapaControlEvent`
  - `OnAfterBuildAction: TAIFluxoEtapaEvent`
  - `OnMissingRequiredParameter: TAIFluxoEtapaEvent`
  - `OnUnsafeParameterDetected: TAIFluxoEtapaEvent`

---

### TAIActionExecutor

**Funzione:** Simulatore ed esecutore fisico di piani d'azione. Integra l'invio finale dei comandi tramite `TAIAgentOutput`.

- **Proprietà (Published):**
  - `ChatGPT: TCHATGPT` - Connettore ChatGPT.
  - `MemoryMap: TAIAgentMemoryMap` - Memoria di audit.
  - `ForcarSimulacaoGlobal: Boolean` - Se attivo, blocca qualsiasi modifica fisica (modalità demo/simulazione).
  - `AutoRegistrarNoMapa: Boolean` - Registra automaticamente i passi logici nel mapa.
- **Metodi (Public):**
  - `ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean` - Elabora ed invia i compiti del piano.
- **Eventi:**
  - `OnBeforeExecutePlan: TAIFluxoEtapaControlEvent`
  - `OnAfterExecutePlan: TAIFluxoEtapaEvent`
  - `OnExecutionBlocked: TAIFluxoEtapaEvent`

---

### TAIAgentMemoryMap

**Funzione:** Registro persistente che conserva e controlla la cronologia del ciclo cognitivo, con rilevamento automatico di perdite di dati contestuali.

- **Proprietà (Published):**
  - `SessionId: string` - ID univoco di sessione.
  - `FlowName: string` - Nome del flusso corrente.
  - `Items: TAIAgentMemoryMapItem` - Lista dei passi logici già completati.
  - `DetectInformationLoss: Boolean` - Se vero, verifica se l'LLM ha dimenticato parametri indispensabili forniti originariamente dall'utente.
- **Metodi (Public):**
  - `StartFlow(const AFlowName: string; const AInput: string)` - Registra l'input utente iniziale.
  - `BuildContextForAgent(const ANomeAgente: string): string` - Esporta la cronologia in formato XML ottimizzato per il modello LLM successivo.
- **Eventos:**
  - `OnInformationLossDetected: TAIFluxoEtapaEvent` - Generato se una chiave critica di input viene dimenticata da un agente.

---

### TAIAgentSafety

**Funzione:** Firewall di sicurezza operativa per l'IA. Intercetta chiamate a file, reti o periferiche prima che arrechino danni.

- **Proprietà (Published):**
  - `Enabled: Boolean` - Abilita la sicurezza (di default `True`).
  - `RequireConfirmation: Boolean` - Richiede il consenso dell'utente (di default `True`).
  - `ReadOnlyMode: Boolean` - Blocca la scrittura fisica (di default `True`).
  - `AllowFileWrite: Boolean` - Consente la scrittura di file locali.
  - `SafeBasePath: string` - Directory sicura al di fuori della quale qualsiasi scrittura viene bloccata.
- **Metodi (Public):**
  - `ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean` - Convalida l'azione.
- **Eventi:**
  - `OnConfirmAction: TAIConfirmActionEvent` - Intercetta l'azione per visualizzare una richiesta di conferma manuale all'utente.

---

### TAIPipeline

**Funzione:** Connettore lineare di dati. Incatena flussi di testo, elaborazione neurale locale, esecuzione di agenti e produzione documentale.

- **Proprietà (Published):**
  - `Mode: TAIPipelineMode` - Modalità operativa.
  - `ChatGPT: TCHATGPT` - Istanza ChatGPT.
  - `NeuralNetwork: TNeuralNetwork` - Rete neurale MLP locale.
  - `OutputDocs: TAIOutputDocs` - Generatore di report e file.
- **Metodi (Public):**
  - `Run: Boolean` - Esegue la logica definita dal modo.
  - `RunNumeric: Boolean` - Calcolo locale neurale.

---

### TAIWizardConfig

**Funzione:** Configurazione guidata passo-passo. Collega progetti IA, connettori e modelli all'interno di Lazarus.

- **Proprietà (Published):**
  - `Project: TAIProject` - Progetto associato.
  - `ChatGPT: TCHATGPT` - Componente ChatGPT.
- **Metodi (Public):**
  - `ConfigureVisual` - Rende visiva la maschera passo-passo (`TfrmAIWizardConfig`).
  - `Apply` - Applica le impostazioni configurate.
