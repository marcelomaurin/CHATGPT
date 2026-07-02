# Sample: agent_task_memory_action_demo

## Traducciones disponibles

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

Este sample demuestra un flujo multiagente orientado por tareas, con memoria de ejecución, planificación mediante LLM, procesamiento cognitivo, automatización real del navegador Chromium, preparación de acciones y envío de e-mail.

La idea central es transformar un prompt libre del usuario en una secuencia auditable de tareas. Cada tarea posee ID, orden, tipo, descripción, agente responsable, acción sugerida, dependencia, parámetros, estado y resultado.

---

## Objetivo del sample

El objetivo principal es mostrar cómo los componentes del paquete **AI Agent** pueden trabajar juntos para resolver una solicitud compuesta:

1. abrir un sitio real en Chromium;
2. capturar el texto de la página;
3. crear tareas intermedias usando un LLM;
4. procesar cognitivamente el contenido capturado;
5. generar un resumen profesional;
6. copiar el resultado al área de resultado del formulario;
7. preparar el cuerpo del e-mail;
8. enviar el e-mail usando `TAIEmailClient`, con confirmación del usuario;
9. registrar todo el recorrido en el mapa de memoria.

Este sample no es solo una pantalla de prueba. Es una demostración práctica de orquestación entre agentes, acciones reales, memoria de ejecución y automatización web.

---

## Prompt del escenario predeterminado

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

El botón de escenario del navegador carga una variante equivalente:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

La regla importante es: **el resumen generado debe copiarse directamente en el cuerpo del e-mail**, sin crear archivos TXT, DOCX, Word ni adjuntos.

---

## Cómo funciona el flujo

### 1. Entrada del usuario

En la pestaña **Prompt**, el usuario define proveedor de IA, modelo, token, Base URL y prompt principal. El sample soporta OpenAI y endpoints locales compatibles con `/v1/chat/completions`.

### 2. Detección de URL

`ExtractURLFromPrompt` localiza la primera URL del prompt. Cuando encuentra una URL, el sample inicializa Chromium y navega hacia la página real.

### 3. Captura inicial de la página

Después de la navegación, `TAIChromiumBrowser` captura el texto del selector `body`. El texto se almacena en `FCapturedWebText`, `browser.last_text` y `browser.last_result_text`.

### 4. Clasificación

`TAIClassifierAgent` recibe el prompt original y el contenido capturado, clasifica la solicitud y registra la etapa en `TAIAgentMemoryMap`.

### 5. Planificación de tareas

`FTaskPlannerAgent`, basado en `TAIDecisionAgent`, transforma la solicitud en una lista JSON de tareas. `LoadTasksFromPlannerJSON` interpreta ese JSON, normaliza dependencias y llena el grid de tareas.

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navegar a la página solicitada",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": { "url": "https://example.com" }
    }
  ]
}
```

### 6. Normalización del plan

El sample normaliza IDs, ordena tareas, reconstruye dependencias, garantiza el destinatario del e-mail, crea capturas después de formularios cuando hace falta, rechaza acciones desconocidas y convierte acciones de resumen en tareas cognitivas.

### 7. Ejecución

Antes de ejecutar una tarea, el sample valida estado, dependencias y parámetros mínimos. Las tareas `BROWSER_*` son ejecutadas directamente por `TAIActionExecutor` para evitar que el LLM cambie la acción. Las tareas cognitivas son procesadas por `FTaskProcessorAgent`.

### 8. Preparación de acciones

Las acciones operativas se preparan como JSON. Acciones directas como `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT` y `REGISTER_RESULT` pueden generarse de forma determinística con `BuildSingleActionJSON`. Cuando hace falta, `TAIActionBuilderAgent.BuildActionsWithRecovery` convierte la salida cognitiva en parámetros válidos.

### 9. Resultado final

El resumen generado debe aparecer en `memConteudoCurriculo`, `memCorpoEmail`, `last_summary_text` y `last_text_content`. El e-mail no debe enviarse con marcadores como `<resumo_gerado>`, `[EMAIL]` o texto genérico.

---

## Componentes utilizados

- `TCHATGPT`: conector LLM compartido por los agentes.
- `TAIAgentMemoryMap`: registra todo el camino de ejecución.
- `TAIClassifierAgent`: clasifica el prompt inicial.
- `TAIDecisionAgent` como `FTaskPlannerAgent`: genera la lista de tareas.
- `TAIDecisionAgent` como `FTaskProcessorAgent`: procesa tareas y genera resultados cognitivos.
- `TAIActionBuilderAgent`: transforma resultados cognitivos en parámetros operativos.
- `TAIActionExecutor`: ejecuta acciones registradas y mantiene `ExecutionContext`.
- `TAIEmailClient`: envía e-mail SMTP después de confirmación.
- `TAIChromiumBrowser` y `TChromiumWindow`: automatización real de Chromium.

Acciones de navegador registradas: `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`.

---

## Pestañas de la interfaz

- **Prompt**: entrada principal y configuración del proveedor.
- **Tarefas**: lista de tareas generada por el LLM.
- **Agente**: auditoría del agente actual.
- **Mapa de Memória**: historial estructurado del flujo.
- **Resultado**: texto generado y campos del e-mail.
- **Log**: seguimiento cronológico.
- **Navegador Chromium**: navegador real usado para abrir páginas.

---

## Contexto de ejecución

`FActionExecutor.ExecutionContext` es la memoria operativa compartida. Claves importantes: `browser.last_dom_kind`, `browser.last_dom_selector`, `browser.last_dom_json`, `browser.last_text`, `browser.last_result_text`, `last_text_content`, `last_summary_text`, `last_text_filename`.

---

## Pipeline resumido

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Grid de tareas
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery si es necesario
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-mail / Resultado
  -> MemoryMap / Log
```

---

## Seguridad y validaciones

El sample bloquea destinatarios vacíos o placeholders, cuerpos de e-mail vacíos, cuerpos con placeholders, acciones desconocidas y parámetros obligatorios faltantes. El envío real siempre requiere confirmación manual.

---

## Resultado esperado

Al ejecutar correctamente el escenario, el usuario debe ver tareas generadas, navegación real en Chromium, contenido capturado, un resumen profesional en **Resultado**, el mismo resumen en el cuerpo del e-mail, log detallado y mapa de memoria de los agentes.
