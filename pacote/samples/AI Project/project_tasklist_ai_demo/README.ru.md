# Project TaskList AI Demo

Этот sample демонстрирует использование компонентов пакета **AI Project** из Lazarus AI Suite для создания простого процесса планирования проекта с поддержкой LLM.

Текущая цель этого sample — практически показать, как форма Lazarus может:

1. настроить провайдера/модель ИИ;
2. собрать базовые данные проекта;
3. запросить у LLM начальную спецификацию в JSON;
4. запросить у LLM генерацию технических задач;
5. сохранить состояние проекта в `ProjectData`;
6. отобразить задачи в grid, панели статуса и представлениях JSON/log;
7. сохранить и загрузить файл `.aiproj.json`.

> Важно: этот README описывает то, что sample делает **сейчас**. Он не описывает идеальную будущую версию demo.

---

## Реальная цель sample

`project_tasklist_ai_demo` — это proof of concept интеграции между:

- формой Lazarus;
- компонентом `TCHATGPT`;
- центральным компонентом `TAIProject`;
- вспомогательными компонентами пакета `AI Project`;
- JSON-структурой проекта, хранящейся в `AIProject1.ProjectData`.

Это еще не полноценный менеджер проектов. В этой версии это также не полностью чистая demo, построенная только на инкапсулированных компонентах. Значительная часть логики prompt, проверки и интеграции JSON всё еще реализована в `main.pas`.

---

## Текущий реализованный поток

### 1. Настройка ИИ

Во вкладке **Config IA** пользователь выбирает:

- провайдера;
- модель;
- token;
- endpoint/local URL;
- версию ИИ компонента `TCHATGPT`.

При нажатии **Aplicar Configuração** форма заполняет `AIProjectLLMConfig1`, применяет конфигурацию к `AIProject1`, а также напрямую обновляет компонент `ChatGPT1`.

Кнопка **Testar IA** отправляет простой вопрос в `ChatGPT1` и ожидает ответа от LLM.

### 2. Базовая регистрация проекта

Во вкладке **Projeto** пользователь вводит:

- название проекта;
- описание/цель;
- ограничения;
- ожидаемые результаты.

Эти данные копируются в свойства `AIProject1`, такие как `ProjectName`, `Goal`, `Constraints` и `ExpectedDeliverables`.

### 3. Генерация спецификации с ИИ

Кнопка **Gerar Descrição Elaborada (IA)** запускает поток генерации спецификации.

В текущей реализации prompt собирается непосредственно в `main.pas`, отправляется через `ChatGPT1.SendQuestion`, интерпретируется как JSON и интегрируется в `AIProject1.ProjectData`.

Ожидаемая структура:

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

Сгенерированная документация интегрируется в `ProjectData.project` и `ProjectData.agile_documents`.

### 4. Генерация задач с ИИ

Кнопка **Gerar Tarefas com IA** отправляет текущий JSON проекта в LLM и запрашивает список технических задач.

Ожидаемая структура:

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

После проверки ответа sample заменяет `ProjectData.planning.tasks` возвращенными задачами и вызывает `AIProjectTasks1.RecalculateEstimates`.

### 5. Отображение задач

Вкладка **Tarefas** использует:

- `TAIProjectStatusPanel` для сводки статуса;
- `TAIProjectTaskGrid` для списка задач;
- `MemoTaskDescription` для отображения длинного описания выбранной задачи.

При выборе строки в grid sample ищет задачу по ID и показывает `long_description` или `description` в memo.

### 6. JSON и log

Вкладка **JSON/Log** отображает:

- полный JSON из `AIProject1.ProjectData`;
- сообщения log выполненного потока;
- исходные ответы LLM при ошибках parsing или validation.

### 7. Сохранение и загрузка проекта

Кнопка **Salvar Projeto** использует `AIProjectStorage1.SaveProjectToFile` для сохранения файла:

```text
project_tasklist_demo.aiproj.json
```

Кнопка **Carregar Projeto** использует `AIProjectStorage1.LoadProjectFromFile` для загрузки того же файла.

В текущей версии сохранение и загрузка также используют вспомогательные вызовы LLM для validation/summary. Это текущее поведение sample, но оно не является обязательным для сохранения проекта.

---

## Компоненты, реально интегрированные в текущий поток

### `TCHATGPT` / `ChatGPT1`

Это компонент, фактически используемый для связи с LLM.

Sample напрямую вызывает:

```pascal
ChatGPT1.SendQuestion(APrompt)
```

Этот компонент используется для:

- теста соединения;
- генерации спецификации;
- генерации задач;
- генерации дополнительной задачи;
- генерации summary;
- генерации текстового отчета;
- validation/export JSON;
- validation перед сохранением;
- подтверждения очистки.

### `TAIProject` / `AIProject1`

Это центральный компонент sample.

Он хранит основную структуру в:

```pascal
AIProject1.ProjectData
```

Sample использует `AIProject1` для хранения:

- данных проекта;
- agile-документов в `agile_documents`;
- списка задач в `planning.tasks`;
- базовой конфигурации проекта;
- сериализуемого состояния `.aiproj.json`.

Также вызывается:

```pascal
AIProject1.EnsureProjectStructure;
```

чтобы гарантировать наличие минимальной JSON-структуры.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

Используется для получения данных из вкладки **Config IA** и применения конфигурации к `AIProject1` и `ChatGPT1`.

Sample использует:

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

Кроме того, форма всё еще напрямую обновляет некоторые свойства `ChatGPT1`, такие как модель, token, endpoint и тип чата.

### `TAIProjectStorage` / `AIProjectStorage1`

Используется для сохранения проекта.

Используемые методы:

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

Компонент реально интегрирован в поток сохранения и загрузки.

### `TAIProjectTasks` / `AIProjectTasks1`

Используется для работы с задачами, уже сохраненными в `ProjectData`.

В текущей версии он в основном используется для:

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

Генерация задач всё еще выполняется в `main.pas`, с ручным prompt, отправленным в `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

Компонент присутствует на форме и связан с `AIProject1`.

Однако в текущей версии sample генерация спецификации не вызывает напрямую публичный метод этого компонента. Поток спецификации выполняется в `main.pas`, с ручным prompt, ручным parsing и ручной интеграцией в `ProjectData`.

Поэтому этот компонент **присутствует и подключен**, но **не является главным исполнителем текущего потока**.

### `TAIProjectTaskGrid` / `TaskGrid1`

Реально интегрированный визуальный компонент.

Используется для отображения `ProjectData.planning.tasks` в виде grid.

Форма вызывает:

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

Реально интегрированный визуальный компонент.

Используется для обновления панели статуса на основе текущего проекта.

Форма вызывает:

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

Компонент присутствует на форме и связан с проектом.

В текущей версии он не является центральной частью демонстрируемого визуального потока. В этом sample нет полной вкладки или панели действий задач, показанной пользователю.

### `TAIProjectDescription` / `AIProjectDescription1`

Компонент присутствует и связан с проектом.

В текущей версии sample он не используется напрямую в основном потоке генерации спецификации или задач.

---

## Компоненты, присутствующие или упомянутые, но не полностью продемонстрированные

### Agents

Предыдущая документация говорила, что agents были удалены из sample. В текущем состоянии проекта это удаление еще не завершено.

В sample всё еще есть:

- вкладка `Agent`;
- `TAIAgentManagerFrame`;
- ссылки на agent units;
- кнопки и методы, связанные с генерацией agents;
- зависимость от пакета `openai_agent` в `.lpi`.

Поэтому agents **частично присутствуют**, но основной поток sample остается генерацией спецификации и задач.

### Gantt и Timeline

Предыдущий README описывал вкладки Gantt и Timeline как часть основного потока.

В текущей версии sample эти вкладки еще не полностью продемонстрированы в главном интерфейсе.

Компонент `TAIProjectGantt` объявлен в `main.pas`, но текущий экран не содержит полноценной вкладки Gantt, интегрированной в поток. Полноценной вкладки Timeline в текущей форме также нет.

### Отчеты

Sample содержит кнопки и методы для summary, отчета задач, отчета agents, Markdown export и JSON export.

В текущей версии эти отчеты генерируются через вызовы LLM в самой форме, а не через полноценный визуальный поток на базе `TAIProjectReports`.

---

## Генерируемый файл

Sample сохраняет проект в фиксированный файл:

```text
project_tasklist_demo.aiproj.json
```

Этот файл содержит полный JSON проекта, включая:

- `project`;
- `agile_documents`;
- `planning.tasks`;
- другие структуры, гарантированные `AIProject1.EnsureProjectStructure`.

---

## Как выполнить текущий поток

1. Откройте `project_tasklist_ai_demo.lpi` в Lazarus.
2. Скомпилируйте и запустите.
3. Перейдите во вкладку **Config IA**.
4. Выберите провайдера и модель.
5. Введите token или endpoint в зависимости от провайдера.
6. Нажмите **Aplicar Configuração**.
7. Нажмите **Testar IA**, чтобы проверить связь.
8. Перейдите во вкладку **Projeto**.
9. Заполните название, цель, ограничения и результаты.
10. Сгенерируйте спецификацию кнопкой **Gerar Descrição Elaborada (IA)**, которая сейчас находится во вкладке **Tarefas**.
11. Сгенерируйте задачи с помощью **Gerar Tarefas com IA**.
12. Проверьте результат во вкладке **Tarefas**.
13. Проверьте JSON и logs во вкладке **JSON/Log**.
14. Сохраните проект через **Salvar Projeto**.
15. Загрузите его снова через **Carregar Projeto**.

---

## Известные ограничения этой версии

- Форма всё еще концентрирует много логики prompt, parsing и JSON validation.
- `TAIProjectSpecification` подключен, но текущий поток спецификации всё еще вручную выполняется `main.pas`.
- `TAIProjectTasks` используется для пересчета и запроса задач, но генерация задач всё еще выполняется в форме.
- Agents всё еще частично присутствуют в sample, хотя они не являются главным фокусом demo.
- Gantt и Timeline еще не представлены как полноценные вкладки формы.
- Markdown export и JSON validation всё еще используют вызовы LLM вместо использования только компонентов отчетов/экспорта.
- Сохранение, загрузка и очистка всё еще имеют вспомогательные вызовы LLM, хотя эти операции могут быть локальными.
- Сохраняемый файл использует фиксированное имя `project_tasklist_demo.aiproj.json`.

---

## Реальная область этой версии

Этот sample следует понимать как практическую начальную демонстрацию интеграции между `TCHATGPT`, `TAIProject`, `TAIProjectLLMConfig`, `TAIProjectStorage`, `TAIProjectTasks`, `TAIProjectTaskGrid` и `TAIProjectStatusPanel`.

Его пока не следует считать финальным примером идеальной архитектуры пакета `AI Project`.
