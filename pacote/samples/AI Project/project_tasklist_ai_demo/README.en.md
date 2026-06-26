# Project TaskList AI Demo

This sample demonstrates the use of components from the **AI Project** package of the Lazarus AI Suite to create a simple project planning flow supported by an LLM.

The current goal of this sample is to show, in practical terms, how a Lazarus form can:

1. configure an AI provider/model;
2. collect basic project data;
3. ask the LLM for an initial JSON specification;
4. ask the LLM to generate technical tasks;
5. store the project state in `ProjectData`;
6. display tasks in a grid, status panel, and JSON/log views;
7. save and load the `.aiproj.json` file.

> Important note: this README describes what the sample does **today**. It does not describe an ideal future version of the demo.

---

## Real objective of the sample

`project_tasklist_ai_demo` is a proof of concept for integration between:

- a Lazarus form;
- the `TCHATGPT` component;
- the central `TAIProject` component;
- auxiliary components from the `AI Project` package;
- a project JSON structure maintained in `AIProject1.ProjectData`.

It is not yet a complete project manager. In this version, it is also not a clean demo based only on encapsulated components. An important part of the prompt, validation, and JSON integration logic is still implemented in `main.pas`.

---

## Flow currently implemented

### 1. AI configuration

In the **Config IA** tab, the user selects:

- provider;
- model;
- token;
- endpoint/local URL;
- AI version from the `TCHATGPT` component.

When clicking **Aplicar Configuração**, the form fills `AIProjectLLMConfig1`, applies the configuration to `AIProject1`, and also directly updates the `ChatGPT1` component.

The **Testar IA** button sends a simple question to `ChatGPT1` and waits for a response from the LLM.

### 2. Basic project registration

In the **Projeto** tab, the user enters:

- project name;
- description/objective;
- constraints;
- expected deliverables.

This information is copied to `AIProject1` properties, such as `ProjectName`, `Goal`, `Constraints`, and `ExpectedDeliverables`.

### 3. AI specification generation

The **Gerar Descrição Elaborada (IA)** button runs the specification flow.

In the current implementation, the prompt is assembled directly in `main.pas`, sent through `ChatGPT1.SendQuestion`, parsed as JSON, and integrated into `AIProject1.ProjectData`.

The expected structure is:

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

The generated documentation is integrated into `ProjectData.project` and `ProjectData.agile_documents`.

### 4. AI task generation

The **Gerar Tarefas com IA** button sends the current project JSON to the LLM and requests a list of technical tasks.

The expected structure is:

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

After validating the response, the sample replaces `ProjectData.planning.tasks` with the returned tasks and calls `AIProjectTasks1.RecalculateEstimates`.

### 5. Task display

The **Tarefas** tab uses:

- `TAIProjectStatusPanel` for the status summary;
- `TAIProjectTaskGrid` to list the tasks;
- `MemoTaskDescription` to show the long description of the selected task.

When selecting a row in the grid, the sample looks up the task by ID and displays `long_description` or `description` in the memo.

### 6. JSON and log

The **JSON/Log** tab displays:

- the complete JSON from `AIProject1.ProjectData`;
- log messages from the executed flow;
- original LLM responses when parsing or validation errors occur.

### 7. Save and load project

The **Salvar Projeto** button uses `AIProjectStorage1.SaveProjectToFile` to save the file:

```text
project_tasklist_demo.aiproj.json
```

The **Carregar Projeto** button uses `AIProjectStorage1.LoadProjectFromFile` to load the same file.

In the current version, saving and loading also use auxiliary LLM calls for validation/summary. This is current sample behavior, but it is not required for project persistence.

---

## Components actually integrated in the current flow

### `TCHATGPT` / `ChatGPT1`

This is the component effectively used for LLM communication.

The sample calls directly:

```pascal
ChatGPT1.SendQuestion(APrompt)
```

This component is used for:

- connection testing;
- specification generation;
- task generation;
- additional task generation;
- summary generation;
- textual report generation;
- JSON validation/export;
- validation before saving;
- clear confirmation.

### `TAIProject` / `AIProject1`

This is the central component of the sample.

It maintains the main structure in:

```pascal
AIProject1.ProjectData
```

The sample uses `AIProject1` to store:

- project data;
- agile documents in `agile_documents`;
- task list in `planning.tasks`;
- basic project configuration;
- serializable `.aiproj.json` state.

It also calls:

```pascal
AIProject1.EnsureProjectStructure;
```

to ensure that the minimum JSON structure exists.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

Used to receive data from the **Config IA** tab and apply configuration to `AIProject1` and `ChatGPT1`.

The sample uses:

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

In addition, the form still directly updates some `ChatGPT1` properties, such as model, token, endpoint, and chat type.

### `TAIProjectStorage` / `AIProjectStorage1`

Used for project persistence.

Methods used:

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

The component is truly integrated into the save and load flow.

### `TAIProjectTasks` / `AIProjectTasks1`

Used to work with tasks already stored in `ProjectData`.

In the current version, it is mainly used for:

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

Task generation is still performed by `main.pas`, with a manual prompt sent to `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

The component is present on the form and linked to `AIProject1`.

However, in the current version of the sample, specification generation does not directly call a public method of this component. The specification flow is performed in `main.pas`, using manual prompt assembly, manual parsing, and manual integration into `ProjectData`.

Therefore, this component is **present and connected**, but **it is not the main executor of the current flow**.

### `TAIProjectTaskGrid` / `TaskGrid1`

A truly integrated visual component.

Used to display `ProjectData.planning.tasks` as a grid.

The form calls:

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

A truly integrated visual component.

Used to update the status panel based on the current project.

The form calls:

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

The component is present on the form and linked to the project.

In the current version, it is not a central part of the visual flow demonstrated. There is no complete task action tab or panel exposed to the user in this sample.

### `TAIProjectDescription` / `AIProjectDescription1`

The component is present and linked to the project.

In the current version of the sample, it is not directly used by the main specification or task generation flow.

---

## Components present or mentioned, but not fully demonstrated

### Agents

Previous documentation said that agents had been removed from the sample. In the current state of the project, the removal is not yet complete.

The sample still contains:

- `Agent` tab;
- `TAIAgentManagerFrame`;
- references to agent units;
- buttons and methods related to agent generation;
- dependency on the `openai_agent` package in the `.lpi`.

Therefore, agents are **partially present**, but the main sample flow remains specification and task generation.

### Gantt and Timeline

The previous README described Gantt and Timeline tabs as part of the main flow.

In the current version of the sample, these tabs are not yet fully demonstrated in the main interface.

The `TAIProjectGantt` component appears declared in `main.pas`, but the current screen does not show a complete Gantt tab integrated into the flow. There is also no complete Timeline tab in the current form.

### Reports

The sample has buttons and methods for summary, task report, agent report, Markdown export, and JSON export.

In the current version, these reports are generated through LLM calls in the form itself, not through a complete visual flow based on `TAIProjectReports`.

---

## Generated file

The sample saves the project to the fixed file:

```text
project_tasklist_demo.aiproj.json
```

This file contains the complete project JSON, including:

- `project`;
- `agile_documents`;
- `planning.tasks`;
- other structures guaranteed by `AIProject1.EnsureProjectStructure`.

---

## How to run the current flow

1. Open `project_tasklist_ai_demo.lpi` in Lazarus.
2. Compile and run.
3. Go to the **Config IA** tab.
4. Select provider and model.
5. Enter token or endpoint, depending on the provider.
6. Click **Aplicar Configuração**.
7. Click **Testar IA** to validate communication.
8. Go to the **Projeto** tab.
9. Fill in name, objective, constraints, and deliverables.
10. Generate the specification using **Gerar Descrição Elaborada (IA)**, currently available in the **Tarefas** tab.
11. Generate tasks using **Gerar Tarefas com IA**.
12. Check the result in the **Tarefas** tab.
13. Check JSON and logs in the **JSON/Log** tab.
14. Save the project with **Salvar Projeto**.
15. Load it again with **Carregar Projeto**.

---

## Known limitations of this version

- The form still concentrates a lot of prompt, parsing, and JSON validation logic.
- `TAIProjectSpecification` is connected, but the current specification flow is still executed manually by `main.pas`.
- `TAIProjectTasks` is used to recalculate and query tasks, but task generation is still performed in the form.
- Agents still appear partially in the sample, although they are not the main focus of the demo.
- Gantt and Timeline are not yet exposed as complete tabs in the form.
- Markdown export and JSON validation still use LLM calls, instead of relying exclusively on report/export components.
- Save, load, and clear still have auxiliary LLM calls, although these operations can be local.
- The saved file uses the fixed name `project_tasklist_demo.aiproj.json`.

---

## Real scope of this version

This sample should be understood as a practical initial integration demo between `TCHATGPT`, `TAIProject`, `TAIProjectLLMConfig`, `TAIProjectStorage`, `TAIProjectTasks`, `TAIProjectTaskGrid`, and `TAIProjectStatusPanel`.

It should not yet be treated as the final example of the ideal architecture for the `AI Project` package.
