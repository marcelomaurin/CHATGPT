# Project TaskList AI Demo

此示例演示如何使用 Lazarus AI Suite 中 **AI Project** 包的组件，创建一个由 LLM 辅助的简单项目规划流程。

当前版本的目标是实际展示一个 Lazarus 表单如何：

1. 配置 AI 提供商/模型；
2. 收集项目基本数据；
3. 请求 LLM 生成初始 JSON 规格说明；
4. 请求 LLM 生成技术任务；
5. 将项目状态存储到 `ProjectData`；
6. 在表格、状态面板以及 JSON/log 视图中显示任务；
7. 保存并加载 `.aiproj.json` 文件。

> 重要说明：本 README 描述的是示例 **当前实际实现的内容**，并不是未来理想版本的说明。

---

## 示例的真实目标

`project_tasklist_ai_demo` 是一个概念验证，用于演示以下内容之间的集成：

- Lazarus 表单；
- `TCHATGPT` 组件；
- 核心组件 `TAIProject`；
- `AI Project` 包中的辅助组件；
- 保存在 `AIProject1.ProjectData` 中的项目 JSON 结构。

它还不是一个完整的项目管理器。在当前版本中，它也不是一个完全由封装组件构成的干净示例。提示词、验证以及 JSON 集成逻辑的重要部分仍然实现于 `main.pas`。

---

## 当前实现的流程

### 1. AI 配置

在 **Config IA** 标签页中，用户选择：

- 提供商；
- 模型；
- token；
- endpoint/本地 URL；
- `TCHATGPT` 组件的 AI 版本。

点击 **Aplicar Configuração** 后，表单会填写 `AIProjectLLMConfig1`，将配置应用到 `AIProject1`，并直接更新 `ChatGPT1` 组件。

**Testar IA** 按钮会向 `ChatGPT1` 发送一个简单问题，并等待 LLM 的响应。

### 2. 项目基本信息

在 **Projeto** 标签页中，用户输入：

- 项目名称；
- 描述/目标；
- 约束；
- 预期交付物。

这些信息会被复制到 `AIProject1` 的属性中，例如 `ProjectName`、`Goal`、`Constraints` 和 `ExpectedDeliverables`。

### 3. 使用 AI 生成规格说明

**Gerar Descrição Elaborada (IA)** 按钮会执行规格说明生成流程。

在当前实现中，提示词在 `main.pas` 中组装，通过 `ChatGPT1.SendQuestion` 发送，解析为 JSON，然后集成到 `AIProject1.ProjectData`。

预期结构如下：

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

生成的文档会集成到 `ProjectData.project` 和 `ProjectData.agile_documents`。

### 4. 使用 AI 生成任务

**Gerar Tarefas com IA** 按钮会将当前项目 JSON 发送给 LLM，并请求生成技术任务列表。

预期结构如下：

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

验证响应后，示例会使用返回的任务替换 `ProjectData.planning.tasks`，并调用 `AIProjectTasks1.RecalculateEstimates`。

### 5. 任务显示

**Tarefas** 标签页使用：

- `TAIProjectStatusPanel` 显示状态摘要；
- `TAIProjectTaskGrid` 显示任务列表；
- `MemoTaskDescription` 显示所选任务的长描述。

当在表格中选择一行时，示例会根据 ID 查找任务，并在 memo 中显示 `long_description` 或 `description`。

### 6. JSON 和日志

**JSON/Log** 标签页显示：

- `AIProject1.ProjectData` 的完整 JSON；
- 已执行流程的日志消息；
- 在解析或验证出错时显示 LLM 的原始响应。

### 7. 保存和加载项目

**Salvar Projeto** 按钮使用 `AIProjectStorage1.SaveProjectToFile` 保存文件：

```text
project_tasklist_demo.aiproj.json
```

**Carregar Projeto** 按钮使用 `AIProjectStorage1.LoadProjectFromFile` 加载同一文件。

在当前版本中，保存和加载还会使用辅助 LLM 调用进行验证/摘要。这是当前示例的行为，但并不是项目持久化所必需的。

---

## 当前流程中真正集成的组件

### `TCHATGPT` / `ChatGPT1`

这是实际用于 LLM 通信的组件。

示例直接调用：

```pascal
ChatGPT1.SendQuestion(APrompt)
```

该组件用于：

- 连接测试；
- 规格说明生成；
- 任务生成；
- 附加任务生成；
- 摘要生成；
- 文本报告生成；
- JSON 验证/导出；
- 保存前验证；
- 清空确认。

### `TAIProject` / `AIProject1`

这是示例的核心组件。

主结构保存在：

```pascal
AIProject1.ProjectData
```

示例使用 `AIProject1` 保存：

- 项目数据；
- `agile_documents` 中的敏捷文档；
- `planning.tasks` 中的任务列表；
- 基本项目配置；
- 可序列化为 `.aiproj.json` 的状态。

也会调用：

```pascal
AIProject1.EnsureProjectStructure;
```

以保证最小 JSON 结构存在。

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

用于接收 **Config IA** 标签页中的数据，并将配置应用到 `AIProject1` 和 `ChatGPT1`。

示例使用：

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

此外，表单仍然会直接更新 `ChatGPT1` 的某些属性，例如模型、token、endpoint 和聊天类型。

### `TAIProjectStorage` / `AIProjectStorage1`

用于项目持久化。

使用的方法：

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

该组件确实集成在保存和加载流程中。

### `TAIProjectTasks` / `AIProjectTasks1`

用于处理已经存储在 `ProjectData` 中的任务。

当前版本主要使用：

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

任务生成仍由 `main.pas` 执行，并通过手动提示词发送给 `ChatGPT1`。

### `TAIProjectSpecification` / `AIProjectSpecification1`

该组件存在于表单中，并连接到 `AIProject1`。

但是在当前示例中，规格说明生成并没有直接调用该组件的公共方法。规格说明流程在 `main.pas` 中执行，使用手动提示词、手动解析以及手动集成到 `ProjectData`。

因此，该组件 **存在并已连接**，但 **不是当前流程的主要执行者**。

### `TAIProjectTaskGrid` / `TaskGrid1`

真正集成的可视组件。

用于以表格形式显示 `ProjectData.planning.tasks`。

表单调用：

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

真正集成的可视组件。

用于根据当前项目更新状态面板。

表单调用：

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

该组件存在于表单中，并连接到项目。

在当前版本中，它不是所演示可视流程的核心部分。本示例没有向用户暴露完整的任务操作标签页或面板。

### `TAIProjectDescription` / `AIProjectDescription1`

该组件存在并连接到项目。

在当前示例中，它没有直接用于规格说明或任务生成的主流程。

---

## 存在或被提及但尚未完整演示的组件

### Agents

之前的文档说明 agents 已从示例中移除。当前项目状态下，移除尚未完成。

示例中仍然存在：

- `Agent` 标签页；
- `TAIAgentManagerFrame`；
- 对 agent units 的引用；
- 与 agent 生成相关的按钮和方法；
- `.lpi` 中对 `openai_agent` 包的依赖。

因此，agents **仍然部分存在**，但示例主流程仍然是规格说明和任务生成。

### Gantt 和 Timeline

之前的 README 将 Gantt 和 Timeline 标签页描述为主流程的一部分。

在当前版本中，这些标签页尚未在主界面中完整演示。

`TAIProjectGantt` 组件在 `main.pas` 中有声明，但当前界面没有展示完整集成到流程中的 Gantt 标签页。当前表单中也没有完整的 Timeline 标签页。

### 报告

示例包含摘要、任务报告、agent 报告、Markdown 导出和 JSON 导出的按钮和方法。

在当前版本中，这些报告通过表单自身的 LLM 调用生成，而不是通过基于 `TAIProjectReports` 的完整可视流程生成。

---

## 生成的文件

示例将项目保存到固定文件：

```text
project_tasklist_demo.aiproj.json
```

该文件包含完整项目 JSON，包括：

- `project`；
- `agile_documents`；
- `planning.tasks`；
- 由 `AIProject1.EnsureProjectStructure` 保证的其他结构。

---

## 如何运行当前流程

1. 在 Lazarus 中打开 `project_tasklist_ai_demo.lpi`。
2. 编译并运行。
3. 进入 **Config IA** 标签页。
4. 选择提供商和模型。
5. 根据提供商输入 token 或 endpoint。
6. 点击 **Aplicar Configuração**。
7. 点击 **Testar IA** 验证通信。
8. 进入 **Projeto** 标签页。
9. 填写名称、目标、约束和交付物。
10. 使用当前位于 **Tarefas** 标签页中的 **Gerar Descrição Elaborada (IA)** 生成规格说明。
11. 使用 **Gerar Tarefas com IA** 生成任务。
12. 在 **Tarefas** 标签页查看结果。
13. 在 **JSON/Log** 标签页查看 JSON 和日志。
14. 使用 **Salvar Projeto** 保存项目。
15. 使用 **Carregar Projeto** 再次加载。

---

## 当前版本的已知限制

- 表单仍然集中处理大量提示词、解析和 JSON 验证逻辑。
- `TAIProjectSpecification` 已连接，但当前规格说明流程仍由 `main.pas` 手动执行。
- `TAIProjectTasks` 用于重新计算和查询任务，但任务生成仍在表单中完成。
- agents 仍然部分出现在示例中，尽管它们不是演示的主要焦点。
- Gantt 和 Timeline 尚未作为完整标签页暴露在表单中。
- Markdown 导出和 JSON 验证仍使用 LLM 调用，而不是仅使用报告/导出组件。
- 保存、加载和清空仍有辅助 LLM 调用，尽管这些操作可以本地完成。
- 保存文件使用固定名称 `project_tasklist_demo.aiproj.json`。

---

## 当前版本的真实范围

本示例应被理解为 `TCHATGPT`、`TAIProject`、`TAIProjectLLMConfig`、`TAIProjectStorage`、`TAIProjectTasks`、`TAIProjectTaskGrid` 和 `TAIProjectStatusPanel` 之间的初始实际集成演示。

它还不应被视为 `AI Project` 包理想架构的最终示例。
