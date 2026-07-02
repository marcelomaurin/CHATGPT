# Sample: agent_task_memory_action_demo

## Available translations

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

This sample demonstrates a task-oriented multi-agent workflow with execution memory, LLM-based planning, cognitive processing, real Chromium browser automation, action preparation, and e-mail delivery.

The central idea is to transform a free-form user prompt into an auditable sequence of tasks. Each task has an ID, order, type, description, responsible agent, suggested action, dependency, parameters, status, and result. The user may execute tasks one by one or run the whole plan.

---

## Sample objective

The main goal is to show how the **AI Agent** package components can work together to solve a compound request:

1. Open a real website in Chromium.
2. Capture the page text.
3. Create intermediate tasks with an LLM.
4. Cognitively process the captured content.
5. Generate a professional summary.
6. Copy the result to the form result area.
7. Prepare the e-mail body.
8. Send the e-mail through `TAIEmailClient`, after user confirmation.
9. Record the complete path in the memory map.

This is not only a test screen. It is a practical demonstration of orchestration between agents, real actions, execution memory, and web UI automation.

---

## Default scenario prompt

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

The browser scenario button loads a similar prompt:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

The important rule is: **the generated summary must be copied directly into the e-mail body**, without creating TXT, DOCX, Word files, or attachments.

---

## How the workflow works

### 1. User input

On the **Prompt** tab, the user sets the AI provider, model, token, base URL, and main prompt. The sample supports OpenAI and local endpoints compatible with `/v1/chat/completions`.

### 2. URL detection

`ExtractURLFromPrompt` finds the first URL in the prompt. When a URL is found, the sample initializes Chromium and navigates to the real page.

### 3. Initial page capture

After navigation, `TAIChromiumBrowser` captures the text from the `body` selector. The captured text is stored in `FCapturedWebText` and in execution context keys such as `browser.last_text` and `browser.last_result_text`.

### 4. Request classification

`TAIClassifierAgent` receives the original prompt and captured content, classifies the request, and records the step in `TAIAgentMemoryMap`.

### 5. Task planning

`FTaskPlannerAgent`, based on `TAIDecisionAgent`, transforms the request into a JSON task list. `LoadTasksFromPlannerJSON` loads the JSON, normalizes dependencies, and fills the task grid.

Expected JSON structure:

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navigate to the requested page",
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

### 6. Plan normalization

The sample normalizes IDs, orders tasks, rebuilds dependencies, ensures the e-mail recipient, creates capture steps after submit actions when needed, rejects unknown actions, and converts summary actions into cognitive tasks.

### 7. Task execution

Before running a task, the sample verifies its status, dependencies, and required parameters. `BROWSER_*` tasks are executed directly by `TAIActionExecutor` to avoid undesired LLM action changes. Cognitive tasks are processed by `FTaskProcessorAgent`.

### 8. Action preparation and execution

Operational actions are prepared as JSON. Direct actions such as `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT`, and `REGISTER_RESULT` can be generated deterministically by `BuildSingleActionJSON`. When needed, `TAIActionBuilderAgent.BuildActionsWithRecovery` converts cognitive output into valid operational parameters.

### 9. Final result

The generated summary must appear in:

- `memConteudoCurriculo`;
- `memCorpoEmail`;
- `last_summary_text`;
- `last_text_content`.

The e-mail must not be sent with placeholder tags such as `<resumo_gerado>`, `[EMAIL]`, or generic body text.

---

## Components used

- `TCHATGPT`: shared LLM connector used by the agents.
- `TAIAgentMemoryMap`: records the full execution path, analysis, explanation, action, questions, output, and information loss.
- `TAIClassifierAgent`: classifies the original prompt.
- `TAIDecisionAgent` as `FTaskPlannerAgent`: converts the prompt into a task list.
- `TAIDecisionAgent` as `FTaskProcessorAgent`: processes a selected task and generates cognitive results.
- `TAIActionBuilderAgent`: converts cognitive results into operational action parameters.
- `TAIActionExecutor`: executes registered actions and maintains `ExecutionContext`.
- `TAICustomAgentAction`: base class for sample actions.
- `TAIEmailClient`: sends real SMTP e-mail after confirmation.
- `TAIChromiumBrowser`: performs real Chromium automation.
- `TChromiumWindow`: renders the Chromium browser window.

### Browser actions registered

- `BROWSER_NAVIGATE`
- `BROWSER_WAIT_SELECTOR`
- `BROWSER_READ_PAGE`
- `BROWSER_DOM_LIST`
- `BROWSER_CAPTURE_TEXT`
- `BROWSER_SET_VALUE`
- `BROWSER_FOCUS`
- `BROWSER_CLICK`
- `BROWSER_PRESS_ENTER`
- `BROWSER_SUBMIT_FORM`
- `BROWSER_SCREENSHOT`

---

## Interface tabs

- **Prompt**: main input and provider configuration.
- **Tasks**: task list generated by the LLM.
- **Agent**: current agent audit panel.
- **Memory Map**: structured history of the workflow.
- **Result**: generated text and e-mail fields.
- **Log**: chronological execution trace.
- **Chromium Browser**: real browser used to open pages and capture content.

---

## Execution context

`FActionExecutor.ExecutionContext` is the shared operational memory between actions. Important keys include:

- `browser.last_dom_kind`
- `browser.last_dom_selector`
- `browser.last_dom_json`
- `browser.last_text`
- `browser.last_result_text`
- `last_text_content`
- `last_summary_text`
- `last_text_filename`

This context allows later tasks to use results produced by earlier tasks.

---

## Expected plan example

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navigate to the curriculum page",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": { "url": "https://maurinsoft.com.br/wp/sobre-nos/" }
    },
    {
      "id": "T002",
      "order": 2,
      "type": "browser",
      "description": "Capture the page text",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_READ_PAGE",
      "depends_on": "T001",
      "parameters": { "selector": "body" }
    },
    {
      "id": "T003",
      "order": 3,
      "type": "content",
      "description": "Generate a professional summary from the captured curriculum",
      "agent": "task_processor_agent",
      "suggested_action": "",
      "depends_on": "T002",
      "parameters": { "instruction": "Generate a professional summary from the captured content." }
    },
    {
      "id": "T004",
      "order": 4,
      "type": "action",
      "description": "Send the summary by e-mail",
      "agent": "email_agent",
      "suggested_action": "SEND_EMAIL",
      "depends_on": "T003",
      "parameters": {
        "to": "marcelomaurinmartins@gmail.com",
        "subject": "Resumo do Currículo",
        "body": "<resumo_gerado>"
      }
    }
  ]
}
```

The loader must replace placeholders such as `<resumo_gerado>` with the real summary published in the execution context.

---

## Pipeline summary

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Task grid
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery, when needed
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-mail / Result
  -> MemoryMap / Log
```

---

## Safety and validation

The sample blocks empty or placeholder recipients, empty e-mail bodies, placeholder bodies, unknown actions, and missing required parameters. Real e-mail delivery always requires manual confirmation. Browser automation validates URLs, selectors, input values, page loading, and asynchronous DOM responses.

---

## Expected result

When the default scenario runs correctly, the user should see generated tasks, real Chromium navigation, captured page content, a professional summary in **Result Text**, the same summary in the e-mail body, a detailed log, and a memory map with the full agent trace.

The key point is that the e-mail must receive the **real generated summary**, not a marker such as `<resumo_gerado>` or generic placeholder text.
