# Sample: agent_task_memory_action_demo

## Доступные переводы

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

Этот пример демонстрирует ориентированный на задачи многоагентный workflow с памятью выполнения, планированием через LLM, когнитивной обработкой, реальной автоматизацией Chromium, подготовкой действий и отправкой e-mail.

Основная идея — преобразовать свободный пользовательский prompt в проверяемую последовательность задач. Каждая задача имеет ID, порядок, тип, описание, ответственного агента, предложенное действие, зависимость, параметры, статус и результат.

---

## Цель примера

Главная цель — показать, как компоненты пакета **AI Agent** совместно решают составной запрос:

1. открыть реальный сайт в Chromium;
2. получить текст страницы;
3. создать промежуточные задачи с помощью LLM;
4. когнитивно обработать полученный контент;
5. сгенерировать профессиональное резюме/краткое описание;
6. скопировать результат в область результата формы;
7. подготовить тело e-mail;
8. отправить e-mail через `TAIEmailClient` после подтверждения пользователя;
9. записать весь путь выполнения в карту памяти.

Это не просто тестовый экран, а практическая демонстрация оркестрации агентов, реальных действий, памяти выполнения и автоматизации web-интерфейса.

---

## Prompt стандартного сценария

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

Кнопка сценария браузера загружает похожий prompt:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

Главное правило: **сгенерированное резюме должно быть скопировано прямо в тело e-mail**, без создания TXT, DOCX, Word или вложений.

---

## Как работает поток

### 1. Ввод пользователя

На вкладке **Prompt** пользователь задает AI-провайдера, модель, token, Base URL и основной prompt. Поддерживаются OpenAI и локальные endpoints, совместимые с `/v1/chat/completions`.

### 2. Определение URL

`ExtractURLFromPrompt` находит первый URL в prompt. Когда URL найден, пример инициализирует Chromium и открывает реальную страницу.

### 3. Первичный захват страницы

После навигации `TAIChromiumBrowser` получает текст селектора `body`. Текст сохраняется в `FCapturedWebText`, `browser.last_text` и `browser.last_result_text`.

### 4. Классификация

`TAIClassifierAgent` получает исходный prompt и захваченный контент, классифицирует запрос и записывает этап в `TAIAgentMemoryMap`.

### 5. Планирование задач

`FTaskPlannerAgent`, основанный на `TAIDecisionAgent`, преобразует запрос в JSON-список задач. `LoadTasksFromPlannerJSON` загружает JSON, нормализует зависимости и заполняет таблицу задач.

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

### 6. Нормализация плана

Пример нормализует ID, сортирует задачи, восстанавливает зависимости, гарантирует адрес получателя, добавляет захват после submit при необходимости, отклоняет неизвестные действия и преобразует действия резюмирования в когнитивные задачи.

### 7. Выполнение

Перед запуском проверяются статус, зависимости и обязательные параметры. Задачи `BROWSER_*` выполняются напрямую через `TAIActionExecutor`, чтобы LLM не изменял действие. Когнитивные задачи выполняются через `FTaskProcessorAgent`.

### 8. Подготовка действий

Операционные действия подготавливаются в JSON. Прямые действия `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT`, `REGISTER_RESULT` могут создаваться детерминированно через `BuildSingleActionJSON`. При необходимости `TAIActionBuilderAgent.BuildActionsWithRecovery` преобразует когнитивный результат в валидные параметры.

### 9. Итоговый результат

Сгенерированное резюме должно появиться в `memConteudoCurriculo`, `memCorpoEmail`, `last_summary_text` и `last_text_content`. E-mail не должен отправляться с маркерами вроде `<resumo_gerado>`, `[EMAIL]` или общим текстом-заглушкой.

---

## Используемые компоненты

- `TCHATGPT`: общий LLM-коннектор.
- `TAIAgentMemoryMap`: записывает полный путь выполнения.
- `TAIClassifierAgent`: классифицирует исходный prompt.
- `TAIDecisionAgent` как `FTaskPlannerAgent`: создает список задач.
- `TAIDecisionAgent` как `FTaskProcessorAgent`: обрабатывает задачу и генерирует когнитивный результат.
- `TAIActionBuilderAgent`: преобразует результат в операционные параметры.
- `TAIActionExecutor`: выполняет зарегистрированные действия и хранит `ExecutionContext`.
- `TAIEmailClient`: отправляет SMTP e-mail после подтверждения.
- `TAIChromiumBrowser` и `TChromiumWindow`: реальная автоматизация Chromium.

Зарегистрированные действия браузера: `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`.

---

## Вкладки интерфейса

- **Prompt**: основной ввод и настройка провайдера.
- **Tarefas**: список задач, созданный LLM.
- **Agente**: аудит текущего агента.
- **Mapa de Memória**: структурированная история потока.
- **Resultado**: созданный текст и поля e-mail.
- **Log**: хронологический журнал выполнения.
- **Navegador Chromium**: реальный браузер.

---

## Контекст выполнения

`FActionExecutor.ExecutionContext` — общая операционная память между действиями. Важные ключи: `browser.last_dom_kind`, `browser.last_dom_selector`, `browser.last_dom_json`, `browser.last_text`, `browser.last_result_text`, `last_text_content`, `last_summary_text`, `last_text_filename`.

---

## Краткий pipeline

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

## Безопасность и проверки

Пример блокирует пустых получателей, placeholders, пустое тело письма, тело с placeholder, неизвестные действия и отсутствие обязательных параметров. Реальная отправка e-mail всегда требует ручного подтверждения.

---

## Ожидаемый результат

При правильном выполнении пользователь видит созданные задачи, реальную навигацию Chromium, захваченный контент, профессиональное резюме в области результата, тот же текст в теле e-mail, подробный журнал и карту памяти агентов.
