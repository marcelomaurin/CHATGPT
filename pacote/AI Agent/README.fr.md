# 🤖 Documentation de l'onglet AI Agent

Ce dossier contient la suite complète des composants de Lazarus sous l'onglet **AI Agent**, dédiée à l'orchestration cognitive, la prise de décision par des agents d'IA autonomes et l'intégration de matériel et de flux de travail (pipelines).

---

## 📋 Table des Composants

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

## 🔍 Description des Composants

### TAIAgent

**Fonction :** Cerveau de l'agent cognitif. Coordonne les conversations avec les modèles LLM afin de planifier et d'exécuter des actions basées sur l'historique de session (mémoire).

- **Propriétés (Published) :**
  - `ChatGPT: TCHATGPT` - Connecteur de communication avec le modèle LLM.
  - `Options: TAIAgentOptions` - Questions et contexte opérationnel de l'agent.
  - `Action: TAIAgentAction` - Actions autorisées et contrôle des paramètres.
  - `Resource: TAIAgentResource` - Ressources physiques/numériques disponibles (e-mail, Modbus, etc.).
  - `Safety: TAIAgentSafety` - Filtres et règles de sécurité pour l'exécution d'actions.
  - `SystemPrompt: string` - Prompt système personnalisé qui oriente l'agent.
  - `LastRationale: string` - Rationale/justification de la dernière décision prise par l'IA (lecture seule).
  - `Memory: TStrings` - Historique de conversation en mémoire de contexte.
  - `MaxMemoryLimit: Integer` - Limite de la taille mémoire.
  - `MaxRetries: Integer` - Limite des essais pour obtenir un format JSON valide.
  - `LastDecision: TAIAgentDecision` - Informations détaillées sur la dernière action et paramètres (lecture seule).
- **Méthodes (Public) :**
  - `Execute(const AInputData: string): Boolean` - Envoie la demande de l'utilisateur, analyse avec l'IA, déduit l'action et appelle l'exécution correspondante.
  - `ClearMemory` - Efface l'historique de conversation.
- **Événements :**
  - `OnActionTriggered: TAgentActionEvent` - Déclenché lorsque l'agent décide d'une action et la distribue avec ses paramètres.

---

### TAIAgentOptions

**Fonction :** Contient des questions structurées et le contexte de base guidant l'analyse de `TAIAgent`.

- **Propriétés (Published) :**
  - `Questions: TStrings` - Liste de questions structurées de vérification.
  - `Context: string` - Description textuelle détaillée des règles métier.
  - `Action: TAIAgentAction` - Action associée à ces options.

---

### TAIAgentAction

**Fonction :** Définit la liste d'actions possibles que l'IA peut décider d'exécuter et valide les paramètres générés.

- **Propriétés (Published) :**
  - `AllowedActions: TStrings` - Liste des actions autorisées (ex: `SEND_EMAIL`, `ACTIVATE_RELAY`).
  - `ParameterDefinitions: TStrings` - Schéma des paramètres attendus par action (habituellement en format JSON).
  - `SelectedAction: string` - La dernière action sélectionnée par l'IA.
  - `SelectedParameters: TStrings` - Paires Clé=Valeur des paramètres de l'action courante.
- **Méthodes (Public) :**
  - `ClearSelection` - Réinitialise l'action et les paramètres sélectionnés.
  - `GetParamValue(const AName: string): string` - Récupère la valeur d'un paramètre.
  - `TriggerAction(const AActionName: string; AParams: TStrings)` - Force l'exécution manuelle ou simulée d'une action.
- **Événements :**
  - `OnExecuteAction: TAgentActionEvent` - Déclenché pour exécuter la routine physique associée à l'action.

---

### TAIAgentResource

**Fonction :** Catalogue enregistrant les connexions physiques et les composants externes (e-mails, réseaux, automates, bases de données) disponibles pour l'IA.

- **Propriétés (Published) :**
  - `Resources: TAIAgentResourceCollection` - Liste des ressources configurées. Chaque ressource (`TAIAgentResourceItem`) définit des propriétés telles que `Name`, `ResourceType` (artEmail, artFile, etc.), `Host`, `Port`, `Sender`, `Recipient`, `FilePath`, `APIUrl`, `Headers`, `Config` et `Component` (liaison directe avec des composants physiques comme `TAIEmailClient` ou `TAIMqttClient`).
- **Méthodes (Public) :**
  - `FindResource(const AName: string): TAIAgentResourceItem` - Recherche une ressource configurée par son nom.

---

### TAIAgentOutput

**Fonction :** Routeur d'exécution. Associe les décisions logiques de `TAIAgentAction` aux gestionnaires configurés dans `TAIAgentResource`.

- **Propriétés (Published) :**
  - `Action: TAIAgentAction` - Composant d'actions source à écouter.
  - `Resource: TAIAgentResource` - Catalogue de ressources source.
  - `Mappings: TAIAgentOutputMappingCollection` - Map reliant ActionName à ResourceName.
  - `LastExecutionLog: string` - Historique des logs du dernier envoi.
- **Méthodes (Public) :**
  - `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` - Envoie dynamiquement l'ordre d'exécution vers la ressource mappée.
- **Événements :**
  - `OnOutputExecuted: TAIAgentOutputEvent` - Déclenché après exécution avec flags de succès, logs et paramètres.

---

### TAIAgentOrchestrator

**Fonction :** Coordinateur cognitif central. Orchestre les flux de traitement à travers plusieurs agents spécialisés et gère le cycle cognitif global.

- **Propriétés (Published) :**
  - `ChatGPT: TCHATGPT` - Connecteur LLM.
  - `MapaDeMemoria: TAIMapaDeMemoria` - Mémoire opérationnelle partagée.
  - `CriarMapaAutomaticamente: Boolean` - Crée automatiquement une mémoire temporaire si aucune n'est liée.
  - `Classifier: TAIClassifierAgent` - Agent de classification.
  - `DecisionAgent: TAIDecisionAgent` - Agent de décision (générateur de plan).
  - `ActionBuilder: TAIActionBuilderAgent` - Agent d'ajustement des paramètres.
  - `Executor: TAIActionExecutor` - Agent d'exécution (simulation ou réel).
- **Méthodes (Public) :**
  - `Run(const AInput: string): Boolean` - Lance et exécute séquentiellement le cycle multi-agent (Classer -> Décider -> Ajuster -> Exécuter).
- **Événements :**
  - `OnBeforeFlowStart` / `OnAfterFlowStart` - Début et fin du cycle.
  - `OnBeforeClassifier` / `OnAfterClassifier` - Étape de classification.
  - `OnBeforeDecisionAgent` / `OnAfterDecisionAgent` - Étape de décision.
  - `OnBeforeActionBuilder` / `OnAfterActionBuilder` - Étape de traitement des paramètres.
  - `OnBeforeExecutor` / `OnAfterExecutor` - Étape d'exécution.
  - `OnBeforeActionExecute` / `OnAfterActionExecute` - Étape d'envoi physique.
  - `OnInformationLossDetected` - Déclenché si le système détecte des données perdues par l'LLM d'une étape à l'autre.
  - `OnFlowError` - Déclenché sur échec général.
  - `OnFlowFinished` - Déclenché sur fin de flux réussie.

---

### TAIClassifierAgent

**Fonction :** Agent spécialisé dans le tri initial et la classification d'intention.

- **Méthodes (Public) :**
  - `Classify(const AInput: string; out AOutput: string): Boolean` - Classifie et oriente la requête.
- **Événements :**
  - `OnBeforeClassify: TAIFluxoEtapaControlEvent`
  - `OnAfterClassify: TAIFluxoEtapaEvent`
  - `OnClassificationLowConfidence: TAIFluxoEtapaEvent`

---

### TAIDecisionAgent

**Fonction :** Agent de planification qui définit le plan de tâches logique requis pour la demande.

- **Méthodes (Public) :**
  - `Decide(const AInput: string; out AOutput: string): Boolean` - Calcule le plan de tâches.
- **Événements :**
  - `OnBeforeDecision: TAIFluxoEtapaControlEvent`
  - `OnAfterDecision: TAIFluxoEtapaEvent`
  - `OnInvalidActionSelected: TAIFluxoEtapaEvent`
  - `OnDecisionLowConfidence: TAIFluxoEtapaEvent`

---

### TAIActionBuilderAgent

**Fonction :** Agent d'ajustement chargé de valider les paramètres, d'injecter les valeurs par défaut et d'assainir les entrées.

- **Méthodes (Public) :**
  - `BuildActions(const AInput: string; out AOutput: string): Boolean` - Assainit et détaille les paramètres des actions planifiées.
- **Événements :**
  - `OnBeforeBuildAction: TAIFluxoEtapaControlEvent`
  - `OnAfterBuildAction: TAIFluxoEtapaEvent`
  - `OnMissingRequiredParameter: TAIFluxoEtapaEvent`
  - `OnUnsafeParameterDetected: TAIFluxoEtapaEvent`

---

### TAIActionExecutor

**Fonction :** Lanceur et simulateur physique de plans d'action. Intègre l'envoi de commandes via `TAIAgentOutput`.

- **Propriétés (Published) :**
  - `ChatGPT: TCHATGPT` - Connecteur ChatGPT.
  - `MapaDeMemoria: TAIMapaDeMemoria` - Mémoire de journalisation.
  - `ForcarSimulacaoGlobal: Boolean` - Si actif, aucun envoi matériel n'a lieu (mode demo/simulation).
  - `AutoRegistrarNoMapa: Boolean` - Log automatiquement les étapes dans le mapa.
- **Méthodes (Public) :**
  - `ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean` - Envoie les tâches du plan.
- **Événements :**
  - `OnBeforeExecutePlan: TAIFluxoEtapaControlEvent`
  - `OnAfterExecutePlan: TAIFluxoEtapaEvent`
  - `OnExecutionBlocked: TAIFluxoEtapaEvent`

---

### TAIMapaDeMemoria

**Fonction :** Journal de bord persistant conservant l'historique du cycle cognitif, avec détection automatique de pertes de données contextuelles.

- **Propriétés (Published) :**
  - `SessionId: string` - ID unique de session.
  - `FlowName: string` - Nom du flux en cours.
  - `Items: TAIMapaDeMemoriaItem` - Liste des étapes franchies.
  - `DetectInformationLoss: Boolean` - Si vrai, vérifie si l'LLM a omis des paramètres indispensables fournis au départ par l'utilisateur.
- **Méthodes (Public) :**
  - `StartFlow(const AFlowName: string; const AInput: string)` - Enregistre l'entrée de l'utilisateur.
  - `BuildContextForAgent(const ANomeAgente: string): string` - Exporte l'historique au format XML optimisé pour le prochain agent.
- **Événements :**
  - `OnInformationLossDetected: TAIFluxoEtapaEvent` - Déclenché si une donnée indispensable d'origine a été oubliée.

---

### TAIAgentSafety

**Fonction :** Pare-feu opérationnel d'IA. Intercepte les appels vers le disque, le réseau ou les automates afin d'éviter tout dommage.

- **Propriétés (Published) :**
  - `Enabled: Boolean` - Activer la sécurité (par défaut `True`).
  - `RequireConfirmation: Boolean` - Confirmation utilisateur requise (par défaut `True`).
  - `ReadOnlyMode: Boolean` - Bloquer toute écriture physique (par défaut `True`).
  - `AllowFileWrite: Boolean` - Autoriser l'écriture de fichiers en local.
  - `SafeBasePath: string` - Dossier sécurisé restreignant les chemins autorisés.
- **Méthodes (Public) :**
  - `ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean` - Valide les commandes logiques.
- **Événements :**
  - `OnConfirmAction: TAIConfirmActionEvent` - Intercepte l'appel pour demander un accord visuel manuel de l'utilisateur.

---

### TAIPipeline

**Fonction :** Connecteur de données linéaire. Enchaîne le traitement de texte, les calculs de réseaux neuronaux locaux et les exports de documents.

- **Propriétés (Published) :**
  - `Mode: TAIPipelineMode` - Mode opératoire.
  - `ChatGPT: TCHATGPT` - Connecteur ChatGPT.
  - `NeuralNetwork: TNeuralNetwork` - Réseau neuronal multicouche (MLP).
  - `OutputDocs: TAIOutputDocs` - Générateur de rapports documentaires.
- **Méthodes (Public) :**
  - `Run: Boolean` - Lance l'exécution définie par le mode.
  - `RunNumeric: Boolean` - Exécution locale de calculs neuronaux.

---

### TAIWizardConfig

**Fonction :** Assistant de configuration pas à pas. Lie et configure projets d'IA, pipelines et modèles dans Lazarus.

- **Propriétés (Published) :**
  - `Project: TAIProject` - Projet lié.
  - `ChatGPT: TCHATGPT` - Conecteur ChatGPT.
- **Méthodes (Public) :**
  - `ConfigureVisual` - Ouvre l'interface de configuration pas à pas (`TfrmAIWizardConfig`).
  - `Apply` - Applique les paramètres configurés.
