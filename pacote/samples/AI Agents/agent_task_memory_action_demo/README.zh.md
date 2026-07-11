# Sample: agent_task_memory_action_demo

## 可用翻译

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

此示例演示一个面向任务的多智能体工作流，包含执行记忆、基于 LLM 的规划、认知处理、真实 Chromium 浏览器自动化、动作准备和电子邮件发送。

核心思想是把用户的自由文本 prompt 转换为可审计的任务序列。每个任务包含 ID、顺序、类型、描述、负责智能体、建议动作、依赖关系、参数、状态和结果。

---

## 示例目标

主要目标是展示 **AI Agent** 包中的组件如何协同完成一个复合请求：

1. 在 Chromium 中打开真实网站；
2. 捕获页面文本；
3. 使用 LLM 创建中间任务；
4. 对捕获内容进行认知处理；
5. 生成专业摘要；
6. 将结果复制到窗体结果区域；
7. 准备电子邮件正文；
8. 在用户确认后通过 `TAIEmailClient` 发送邮件；
9. 将完整流程记录到记忆地图中。

这不仅是测试界面，而是智能体、真实动作、执行记忆和 Web UI 自动化之间协同编排的实际示例。

---

## 默认场景 prompt

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

浏览器场景按钮会加载一个等价变体：

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

关键规则是：**生成的摘要必须直接复制到电子邮件正文中**，不能生成 TXT、DOCX、Word 文件或附件。

---

## 工作流如何运行

### 1. 用户输入

在 **Prompt** 选项卡中，用户配置 AI 提供商、模型、token、Base URL 和主 prompt。示例支持 OpenAI，也支持兼容 `/v1/chat/completions` 的本地端点。

### 2. URL 检测

`ExtractURLFromPrompt` 会找到 prompt 中的第一个 URL。找到 URL 后，示例会初始化 Chromium 并导航到真实页面。

### 3. 页面初始捕获

导航完成后，`TAIChromiumBrowser` 捕获 `body` 选择器的文本。文本被保存到 `FCapturedWebText`、`browser.last_text` 和 `browser.last_result_text`。

### 4. 请求分类

`TAIClassifierAgent` 接收原始 prompt 和已捕获内容，对请求进行分类，并在 `TAIAgentMemoryMap` 中记录该步骤。

### 5. 任务规划

基于 `TAIDecisionAgent` 的 `FTaskPlannerAgent` 将请求转换为 JSON 任务列表。`LoadTasksFromPlannerJSON` 加载 JSON、规范化依赖关系并填充任务表格。

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
      "parameters": { "url": "https://example.com" }
    }
  ]
}
```

### 6. 计划规范化

示例会规范化 ID、排序任务、重建依赖关系、确保邮件收件人、必要时在提交后添加捕获步骤、拒绝未知动作，并把摘要动作转换为认知任务。

### 7. 执行任务

执行前会检查状态、依赖关系和必需参数。`BROWSER_*` 任务由 `TAIActionExecutor` 直接执行，避免 LLM 错误更改动作。认知任务由 `FTaskProcessorAgent` 处理。

### 8. 动作准备

操作动作会以 JSON 准备。`SEND_EMAIL`、`CREATE_TEXT_DOCUMENT` 和 `REGISTER_RESULT` 等直接动作可由 `BuildSingleActionJSON` 确定性生成。需要时，`TAIActionBuilderAgent.BuildActionsWithRecovery` 会将认知输出转换为有效参数。

### 9. 最终结果

生成的摘要必须出现在 `memConteudoCurriculo`、`memCorpoEmail`、`last_summary_text` 和 `last_text_content` 中。邮件不能用 `<resumo_gerado>`、`[EMAIL]` 或通用占位文本发送。

---

## 使用的组件

- `TCHATGPT`: 共享 LLM 连接组件。
- `TAIAgentMemoryMap`: 记录完整执行路径。
- `TAIClassifierAgent`: 对初始 prompt 分类。
- `TAIDecisionAgent` 作为 `FTaskPlannerAgent`: 生成任务列表。
- `TAIDecisionAgent` 作为 `FTaskProcessorAgent`: 处理任务并生成认知结果。
- `TAIActionBuilderAgent`: 将认知结果转换为操作参数。
- `TAIActionExecutor`: 执行注册动作并维护 `ExecutionContext`。
- `TAIEmailClient`: 用户确认后通过 SMTP 发送邮件。
- `TAIChromiumBrowser` 和 `TChromiumWindow`: 真实 Chromium 自动化。

注册的浏览器动作：`BROWSER_NAVIGATE`、`BROWSER_WAIT_SELECTOR`、`BROWSER_READ_PAGE`、`BROWSER_DOM_LIST`、`BROWSER_CAPTURE_TEXT`、`BROWSER_SET_VALUE`、`BROWSER_FOCUS`、`BROWSER_CLICK`、`BROWSER_PRESS_ENTER`、`BROWSER_SUBMIT_FORM`、`BROWSER_SCREENSHOT`。

---

## 界面选项卡

- **Prompt**: 主输入和提供商配置。
- **Tarefas**: LLM 生成的任务列表。
- **Agente**: 当前智能体审计信息。
- **Mapa de Memória**: 工作流结构化历史。
- **Resultado**: 生成文本和邮件字段。
- **Log**: 按时间记录的执行日志。
- **Navegador Chromium**: 用于打开页面的真实浏览器。

---

## 执行上下文

`FActionExecutor.ExecutionContext` 是动作之间共享的操作记忆。重要键包括 `browser.last_dom_kind`、`browser.last_dom_selector`、`browser.last_dom_json`、`browser.last_text`、`browser.last_result_text`、`last_text_content`、`last_summary_text`、`last_text_filename`。

---

## 管道摘要

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

## 安全与验证

示例会阻止空收件人、占位收件人、空邮件正文、含占位符的正文、未知动作和缺少必需参数。真实邮件发送始终需要手动确认。

---

## 预期结果

正确运行后，用户应看到生成的任务、真实 Chromium 导航、捕获的页面内容、显示在结果区的专业摘要、邮件正文中的同一摘要、详细日志以及智能体记忆地图。
