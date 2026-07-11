# Sample : agent_task_memory_action_demo

## Traductions disponibles

- [Português](README.md)
- [English](README.en.md)
- [Français](README.fr.md)
- [日本語](README.ja.md)
- [Deutsch](README.de.md)
- [Русский](README.ru.md)
- [中文](README.zh.md)
- [Español](README.es.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

---

Ce sample démontre un flux multi-agent orienté tâches avec mémoire d’exécution, planification par LLM, traitement cognitif, automatisation réelle du navigateur Chromium, préparation d’actions et envoi d’e-mail.

L’idée centrale est de transformer un prompt libre de l’utilisateur en une séquence de tâches auditable. Chaque tâche possède un ID, un ordre, un type, une description, un agent responsable, une action suggérée, une dépendance, des paramètres, un statut et un résultat.

---

## Objectif du sample

L’objectif principal est de montrer comment les composants du package **AI Agent** travaillent ensemble pour résoudre une demande composée :

1. ouvrir un site réel dans Chromium ;
2. capturer le texte de la page ;
3. créer des tâches intermédiaires avec un LLM ;
4. traiter cognitivement le contenu capturé ;
5. générer un résumé professionnel ;
6. copier le résultat dans l’interface ;
7. préparer le corps de l’e-mail ;
8. envoyer l’e-mail avec `TAIEmailClient`, après confirmation de l’utilisateur ;
9. enregistrer tout le chemin dans la carte mémoire.

Ce sample est une démonstration pratique d’orchestration entre agents, actions réelles, mémoire d’exécution et automatisation web.

---

## Prompt du scénario par défaut

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

Le bouton de scénario navigateur charge une variante équivalente :

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

La règle importante est que **le résumé doit être copié directement dans le corps de l’e-mail**, sans créer de fichier TXT, DOCX, Word ni pièce jointe.

---

## Fonctionnement du flux

### 1. Entrée utilisateur

Dans l’onglet **Prompt**, l’utilisateur définit le fournisseur IA, le modèle, le token, l’URL de base et le prompt principal. Le sample prend en charge OpenAI et les endpoints locaux compatibles avec `/v1/chat/completions`.

### 2. Détection d’URL

`ExtractURLFromPrompt` trouve la première URL du prompt. Si une URL est trouvée, Chromium est initialisé et la page réelle est ouverte.

### 3. Capture initiale

Après la navigation, `TAIChromiumBrowser` capture le texte du sélecteur `body`. Le texte est stocké dans `FCapturedWebText` et dans le contexte d’exécution : `browser.last_text` et `browser.last_result_text`.

### 4. Classification

`TAIClassifierAgent` reçoit le prompt et le contenu capturé, classe la demande et enregistre l’étape dans `TAIAgentMemoryMap`.

### 5. Planification des tâches

`FTaskPlannerAgent`, basé sur `TAIDecisionAgent`, transforme la demande en liste JSON de tâches. `LoadTasksFromPlannerJSON` lit ce JSON, normalise les dépendances et remplit la grille.

Structure attendue :

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Naviguer vers la page demandée",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": {
        "url": "https://example.com"
      }
    }
  ]
}
```

### 6. Normalisation

Le sample normalise les IDs, ordonne les tâches, reconstruit les dépendances, garantit le destinataire e-mail, crée une capture après soumission si nécessaire, refuse les actions inconnues et convertit les actions de résumé en tâches cognitives.

### 7. Exécution

Avant l’exécution, le sample vérifie le statut, les dépendances et les paramètres obligatoires. Les tâches `BROWSER_*` sont exécutées directement par `TAIActionExecutor`. Les tâches cognitives sont traitées par `FTaskProcessorAgent`.

### 8. Actions

Les actions opérationnelles sont préparées en JSON. Les actions directes comme `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT` et `REGISTER_RESULT` peuvent être générées de manière déterministe par `BuildSingleActionJSON`. Si nécessaire, `TAIActionBuilderAgent.BuildActionsWithRecovery` convertit la sortie cognitive en paramètres valides.

### 9. Résultat final

Le résumé généré doit apparaître dans `memConteudoCurriculo`, `memCorpoEmail`, `last_summary_text` et `last_text_content`. L’e-mail ne doit jamais être envoyé avec des marqueurs comme `<resumo_gerado>`, `[EMAIL]` ou un texte générique.

---

## Composants utilisés

- `TCHATGPT` : connecteur LLM partagé par les agents.
- `TAIAgentMemoryMap` : enregistre le chemin complet d’exécution.
- `TAIClassifierAgent` : classe le prompt initial.
- `TAIDecisionAgent` comme `FTaskPlannerAgent` : génère la liste des tâches.
- `TAIDecisionAgent` comme `FTaskProcessorAgent` : traite une tâche et génère le contenu cognitif.
- `TAIActionBuilderAgent` : transforme les résultats cognitifs en actions opérationnelles.
- `TAIActionExecutor` : exécute les actions et maintient `ExecutionContext`.
- `TAIEmailClient` : envoie l’e-mail réel via SMTP après confirmation.
- `TAIChromiumBrowser` et `TChromiumWindow` : automatisation et rendu Chromium.

Actions navigateur enregistrées : `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`.

---

## Onglets de l’interface

- **Prompt** : saisie principale et configuration du fournisseur.
- **Tâches** : liste des tâches générées par le LLM.
- **Agent** : audit de l’agent courant.
- **Carte mémoire** : historique structuré du flux.
- **Résultat** : texte généré et champs d’e-mail.
- **Log** : trace chronologique.
- **Navigateur Chromium** : navigateur réel utilisé pour ouvrir les pages.

---

## Contexte d’exécution

`FActionExecutor.ExecutionContext` est la mémoire opérationnelle partagée. Clés importantes : `browser.last_dom_kind`, `browser.last_dom_selector`, `browser.last_dom_json`, `browser.last_text`, `browser.last_result_text`, `last_text_content`, `last_summary_text`, `last_text_filename`.

---

## Pipeline résumé

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Grille de tâches
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery si nécessaire
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Navigateur / E-mail / Résultat
  -> MemoryMap / Log
```

---

## Sécurité et validations

Le sample bloque les destinataires vides ou placeholders, les corps d’e-mail vides, les corps avec placeholders, les actions inconnues et les paramètres obligatoires absents. L’envoi réel exige toujours une confirmation manuelle.

---

## Résultat attendu

Le scénario correct affiche les tâches générées, la navigation réelle dans Chromium, le contenu capturé, un résumé professionnel dans **Résultat**, le même résumé dans le corps de l’e-mail, un log détaillé et la carte mémoire des agents.
