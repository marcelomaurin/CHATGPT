# Project TaskList AI Demo

Cet exemple montre l’utilisation des composants du package **AI Project** de Lazarus AI Suite pour créer un flux simple de planification de projet assisté par un LLM.

L’objectif actuel de cet exemple est de montrer, de manière pratique, comment un formulaire Lazarus peut :

1. configurer un fournisseur/modèle d’IA ;
2. collecter les données de base d’un projet ;
3. demander au LLM une spécification initiale en JSON ;
4. demander au LLM de générer des tâches techniques ;
5. stocker l’état du projet dans `ProjectData` ;
6. afficher les tâches dans une grille, un panneau d’état et des vues JSON/log ;
7. enregistrer et charger le fichier `.aiproj.json`.

> Remarque importante : ce README décrit ce que l’exemple fait **aujourd’hui**. Il ne décrit pas une version idéale future de la démo.

---

## Objectif réel de l’exemple

`project_tasklist_ai_demo` est une preuve de concept d’intégration entre :

- un formulaire Lazarus ;
- le composant `TCHATGPT` ;
- le composant central `TAIProject` ;
- des composants auxiliaires du package `AI Project` ;
- une structure JSON de projet maintenue dans `AIProject1.ProjectData`.

Ce n’est pas encore un gestionnaire de projet complet. Dans cette version, ce n’est pas non plus une démo propre basée uniquement sur des composants encapsulés. Une partie importante de la logique de prompt, de validation et d’intégration JSON est encore implémentée dans `main.pas`.

---

## Flux actuellement implémenté

### 1. Configuration de l’IA

Dans l’onglet **Config IA**, l’utilisateur sélectionne :

- fournisseur ;
- modèle ;
- token ;
- endpoint/URL locale ;
- version IA du composant `TCHATGPT`.

En cliquant sur **Aplicar Configuração**, le formulaire remplit `AIProjectLLMConfig1`, applique la configuration à `AIProject1` et met également à jour directement le composant `ChatGPT1`.

Le bouton **Testar IA** envoie une question simple à `ChatGPT1` et attend une réponse du LLM.

### 2. Saisie de base du projet

Dans l’onglet **Projeto**, l’utilisateur renseigne :

- nom du projet ;
- description/objectif ;
- contraintes ;
- livrables attendus.

Ces informations sont copiées dans les propriétés de `AIProject1`, comme `ProjectName`, `Goal`, `Constraints` et `ExpectedDeliverables`.

### 3. Génération de spécification avec IA

Le bouton **Gerar Descrição Elaborada (IA)** exécute le flux de spécification.

Dans l’implémentation actuelle, le prompt est assemblé dans `main.pas`, envoyé via `ChatGPT1.SendQuestion`, interprété comme JSON et intégré dans `AIProject1.ProjectData`.

Structure attendue :

```json
{
  "project": {
    "name": "...",
    "description": "...",
    "goal": "...",
    "context": "...",
    "scope": "...",
    "constraints": "...",
    "expected_deliverables": "..."
  },
  "agile_documents": {
    "business_vision": "...",
    "functional_requirements": [],
    "non_functional_requirements": [],
    "stakeholders": [],
    "risk_map": [],
    "epics": [],
    "user_stories": []
  }
}
```

La documentation générée est intégrée dans `ProjectData.project` et `ProjectData.agile_documents`.

### 4. Génération de tâches avec IA

Le bouton **Gerar Tarefas com IA** envoie le JSON actuel du projet au LLM et demande une liste de tâches techniques.

Structure attendue :

```json
{
  "planning": {
    "tasks": [
      {
        "id": "T001",
        "epic_id": "E001",
        "title": "...",
        "description": "...",
        "long_description": "...",
        "acceptance_criteria": "...",
        "priority": "alta",
        "status": "draft",
        "dependency_type": "serial",
        "dependencies": [],
        "can_run_in_parallel": false,
        "estimated_hours": {
          "intern": 8,
          "junior": 6,
          "mid_level": 4,
          "senior": 2
        },
        "suggested_skill_level": "mid_level",
        "assigned_skill_level": "mid_level",
        "assigned_to": "DEV",
        "responsible_profile": "DEV",
        "planned_start_date": "2026-06-26",
        "planned_end_date": "2026-06-27",
        "estimated_duration_days": 1,
        "progress_percent": 0,
        "deliverable": "...",
        "notes": "...",
        "revision_created": 1,
        "revision_updated": 1
      }
    ]
  }
}
```

Après validation de la réponse, l’exemple remplace `ProjectData.planning.tasks` par les tâches retournées et appelle `AIProjectTasks1.RecalculateEstimates`.

### 5. Affichage des tâches

L’onglet **Tarefas** utilise :

- `TAIProjectStatusPanel` pour le résumé d’état ;
- `TAIProjectTaskGrid` pour lister les tâches ;
- `MemoTaskDescription` pour afficher la description longue de la tâche sélectionnée.

Lorsqu’une ligne est sélectionnée dans la grille, l’exemple recherche la tâche par ID et affiche `long_description` ou `description` dans le mémo.

### 6. JSON et log

L’onglet **JSON/Log** affiche :

- le JSON complet de `AIProject1.ProjectData` ;
- les messages de log du flux exécuté ;
- les réponses originales du LLM en cas d’erreur de parsing ou de validation.

### 7. Enregistrer et charger le projet

Le bouton **Salvar Projeto** utilise `AIProjectStorage1.SaveProjectToFile` pour enregistrer le fichier :

```text
project_tasklist_demo.aiproj.json
```

Le bouton **Carregar Projeto** utilise `AIProjectStorage1.LoadProjectFromFile` pour charger ce même fichier.

Dans la version actuelle, l’enregistrement et le chargement utilisent aussi des appels auxiliaires au LLM pour validation/résumé. C’est le comportement actuel de l’exemple, mais ce n’est pas requis pour la persistance du projet.

---

## Composants réellement intégrés dans le flux actuel

### `TCHATGPT` / `ChatGPT1`

C’est le composant effectivement utilisé pour la communication avec le LLM.

L’exemple appelle directement :

```pascal
ChatGPT1.SendQuestion(APrompt)
```

Ce composant est utilisé pour :

- test de connexion ;
- génération de spécification ;
- génération de tâches ;
- génération de tâche additionnelle ;
- génération de résumé ;
- génération de rapport textuel ;
- validation/export JSON ;
- validation avant enregistrement ;
- confirmation de nettoyage.

### `TAIProject` / `AIProject1`

C’est le composant central de l’exemple.

Il maintient la structure principale dans :

```pascal
AIProject1.ProjectData
```

L’exemple utilise `AIProject1` pour stocker :

- les données du projet ;
- les documents agiles dans `agile_documents` ;
- la liste des tâches dans `planning.tasks` ;
- la configuration de base du projet ;
- l’état sérialisable du `.aiproj.json`.

Il appelle aussi :

```pascal
AIProject1.EnsureProjectStructure;
```

pour garantir l’existence de la structure JSON minimale.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

Utilisé pour recevoir les données de l’onglet **Config IA** et appliquer la configuration à `AIProject1` et `ChatGPT1`.

L’exemple utilise :

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

De plus, le formulaire met encore directement à jour certaines propriétés de `ChatGPT1`, comme le modèle, le token, l’endpoint et le type de chat.

### `TAIProjectStorage` / `AIProjectStorage1`

Utilisé pour la persistance du projet.

Méthodes utilisées :

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

Le composant est réellement intégré au flux d’enregistrement et de chargement.

### `TAIProjectTasks` / `AIProjectTasks1`

Utilisé pour travailler avec les tâches déjà stockées dans `ProjectData`.

Dans la version actuelle, il est principalement utilisé pour :

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

La génération des tâches est encore effectuée par `main.pas`, avec un prompt manuel envoyé à `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

Le composant est présent dans le formulaire et lié à `AIProject1`.

Cependant, dans la version actuelle de l’exemple, la génération de spécification n’appelle pas directement une méthode publique de ce composant. Le flux de spécification est effectué dans `main.pas`, avec prompt manuel, parsing manuel et intégration manuelle dans `ProjectData`.

Ce composant est donc **présent et connecté**, mais **il n’est pas l’exécuteur principal du flux actuel**.

### `TAIProjectTaskGrid` / `TaskGrid1`

Composant visuel réellement intégré.

Utilisé pour afficher `ProjectData.planning.tasks` sous forme de grille.

Le formulaire appelle :

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

Composant visuel réellement intégré.

Utilisé pour mettre à jour le panneau d’état à partir du projet courant.

Le formulaire appelle :

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

Le composant est présent dans le formulaire et lié au projet.

Dans la version actuelle, il n’est pas une partie centrale du flux visuel démontré. Aucun onglet ou panneau complet d’actions de tâche n’est exposé à l’utilisateur dans cet exemple.

### `TAIProjectDescription` / `AIProjectDescription1`

Le composant est présent et lié au projet.

Dans la version actuelle de l’exemple, il n’est pas utilisé directement par le flux principal de génération de spécification ou de tâches.

---

## Composants présents ou cités, mais pas entièrement démontrés

### Agents

La documentation précédente indiquait que les agents avaient été retirés de l’exemple. Dans l’état actuel du projet, cette suppression n’est pas encore complète.

L’exemple contient encore :

- l’onglet `Agent` ;
- `TAIAgentManagerFrame` ;
- des références aux units d’agents ;
- des boutons et méthodes liés à la génération d’agents ;
- une dépendance au package `openai_agent` dans le `.lpi`.

Les agents sont donc **partiellement présents**, mais le flux principal reste la génération de spécification et de tâches.

### Gantt et Timeline

Le README précédent décrivait les onglets Gantt et Timeline comme faisant partie du flux principal.

Dans la version actuelle, ces onglets ne sont pas encore démontrés complètement dans l’interface principale.

Le composant `TAIProjectGantt` apparaît déclaré dans `main.pas`, mais l’écran actuel ne présente pas d’onglet Gantt complet intégré au flux. Il n’existe pas non plus d’onglet Timeline complet dans le formulaire actuel.

### Rapports

L’exemple possède des boutons et méthodes pour résumé, rapport de tâches, rapport d’agents, export Markdown et export JSON.

Dans la version actuelle, ces rapports sont générés par des appels au LLM dans le formulaire lui-même, et non par un flux visuel complet basé sur `TAIProjectReports`.

---

## Fichier généré

L’exemple enregistre le projet dans le fichier fixe :

```text
project_tasklist_demo.aiproj.json
```

Ce fichier contient le JSON complet du projet, y compris :

- `project` ;
- `agile_documents` ;
- `planning.tasks` ;
- les autres structures garanties par `AIProject1.EnsureProjectStructure`.

---

## Comment exécuter le flux actuel

1. Ouvrez `project_tasklist_ai_demo.lpi` dans Lazarus.
2. Compilez et exécutez.
3. Accédez à l’onglet **Config IA**.
4. Sélectionnez le fournisseur et le modèle.
5. Saisissez le token ou l’endpoint selon le fournisseur.
6. Cliquez sur **Aplicar Configuração**.
7. Cliquez sur **Testar IA** pour valider la communication.
8. Allez dans l’onglet **Projeto**.
9. Renseignez nom, objectif, contraintes et livrables.
10. Générez la spécification avec **Gerar Descrição Elaborada (IA)**, actuellement disponible dans l’onglet **Tarefas**.
11. Générez les tâches avec **Gerar Tarefas com IA**.
12. Consultez le résultat dans l’onglet **Tarefas**.
13. Consultez le JSON et les logs dans l’onglet **JSON/Log**.
14. Enregistrez le projet avec **Salvar Projeto**.
15. Rechargez-le avec **Carregar Projeto**.

---

## Limites connues de cette version

- Le formulaire concentre encore beaucoup de logique de prompt, parsing et validation JSON.
- `TAIProjectSpecification` est connecté, mais le flux actuel de spécification est encore exécuté manuellement par `main.pas`.
- `TAIProjectTasks` est utilisé pour recalculer et consulter les tâches, mais la génération des tâches se fait encore dans le formulaire.
- Les agents apparaissent encore partiellement dans l’exemple, bien qu’ils ne soient pas le focus principal.
- Gantt et Timeline ne sont pas encore exposés comme onglets complets dans le formulaire.
- L’export Markdown et la validation JSON utilisent encore des appels au LLM au lieu de s’appuyer uniquement sur les composants de rapport/export.
- Enregistrer, charger et nettoyer utilisent encore des appels auxiliaires au LLM, bien que ces opérations puissent être locales.
- Le fichier enregistré utilise le nom fixe `project_tasklist_demo.aiproj.json`.

---

## Portée réelle de cette version

Cet exemple doit être compris comme une démonstration pratique d’intégration initiale entre `TCHATGPT`, `TAIProject`, `TAIProjectLLMConfig`, `TAIProjectStorage`, `TAIProjectTasks`, `TAIProjectTaskGrid` et `TAIProjectStatusPanel`.

Il ne doit pas encore être considéré comme l’exemple final de l’architecture idéale du package `AI Project`.
