# Project TaskList AI Demo

Este sample demuestra el uso de componentes del paquete **AI Project** de Lazarus AI Suite para crear un flujo simple de planificación de proyectos con apoyo de un LLM.

El objetivo actual de este sample es mostrar, de forma práctica, cómo un formulario Lazarus puede:

1. configurar un proveedor/modelo de IA;
2. recopilar datos básicos de un proyecto;
3. solicitar al LLM una especificación inicial en JSON;
4. solicitar al LLM la generación de tareas técnicas;
5. almacenar el estado del proyecto en `ProjectData`;
6. mostrar tareas en una grilla, panel de estado y vistas JSON/log;
7. guardar y cargar el archivo `.aiproj.json`.

> Nota importante: este README describe lo que el sample hace **hoy**. No describe una versión ideal futura de la demo.

---

## Objetivo real del sample

`project_tasklist_ai_demo` es una prueba de concepto de integración entre:

- un formulario Lazarus;
- el componente `TCHATGPT`;
- el componente central `TAIProject`;
- componentes auxiliares del paquete `AI Project`;
- una estructura JSON de proyecto mantenida en `AIProject1.ProjectData`.

Todavía no es un gestor completo de proyectos. En esta versión, tampoco es una demo limpia basada únicamente en componentes encapsulados. Una parte importante de la lógica de prompt, validación e integración de JSON todavía está implementada en `main.pas`.

---

## Flujo implementado actualmente

### 1. Configuración de la IA

En la pestaña **Config IA**, el usuario selecciona:

- proveedor;
- modelo;
- token;
- endpoint/URL local;
- versión de IA del componente `TCHATGPT`.

Al hacer clic en **Aplicar Configuração**, el formulario rellena `AIProjectLLMConfig1`, aplica la configuración en `AIProject1` y también actualiza directamente el componente `ChatGPT1`.

El botón **Testar IA** envía una pregunta simple a `ChatGPT1` y espera una respuesta del LLM.

### 2. Registro básico del proyecto

En la pestaña **Projeto**, el usuario informa:

- nombre del proyecto;
- descripción/objetivo;
- restricciones;
- entregables esperados.

Esta información se copia a propiedades de `AIProject1`, como `ProjectName`, `Goal`, `Constraints` y `ExpectedDeliverables`.

### 3. Generación de especificación con IA

El botón **Gerar Descrição Elaborada (IA)** ejecuta el flujo de especificación.

En la implementación actual, el prompt se arma en el propio `main.pas`, se envía mediante `ChatGPT1.SendQuestion`, se interpreta como JSON y se integra en `AIProject1.ProjectData`.

La estructura esperada es:

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

La documentación generada se integra en `ProjectData.project` y `ProjectData.agile_documents`.

### 4. Generación de tareas con IA

El botón **Gerar Tarefas com IA** envía al LLM el JSON actual del proyecto y solicita una lista de tareas técnicas.

La estructura esperada es:

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

Después de validar la respuesta, el sample reemplaza `ProjectData.planning.tasks` por las tareas devueltas y llama a `AIProjectTasks1.RecalculateEstimates`.

### 5. Visualización de tareas

La pestaña **Tarefas** usa:

- `TAIProjectStatusPanel` para el resumen de estado;
- `TAIProjectTaskGrid` para listar las tareas;
- `MemoTaskDescription` para mostrar la descripción larga de la tarea seleccionada.

Al seleccionar una fila en la grilla, el sample busca la tarea por ID y muestra `long_description` o `description` en el memo.

### 6. JSON y log

La pestaña **JSON/Log** muestra:

- el JSON completo de `AIProject1.ProjectData`;
- mensajes de log del flujo ejecutado;
- respuestas originales del LLM en caso de error de parsing o validación.

### 7. Guardar y cargar proyecto

El botón **Salvar Projeto** usa `AIProjectStorage1.SaveProjectToFile` para guardar el archivo:

```text
project_tasklist_demo.aiproj.json
```

El botón **Carregar Projeto** usa `AIProjectStorage1.LoadProjectFromFile` para cargar el mismo archivo.

En la versión actual, guardar y cargar también usan llamadas auxiliares al LLM para validación/resumen. Este es el comportamiento actual del sample, pero no es obligatorio para la persistencia del proyecto.

---

## Componentes realmente integrados en el flujo actual

### `TCHATGPT` / `ChatGPT1`

Es el componente efectivamente usado para la comunicación con el LLM.

El sample llama directamente:

```pascal
ChatGPT1.SendQuestion(APrompt)
```

Este componente se usa en:

- prueba de conexión;
- generación de especificación;
- generación de tareas;
- generación de tarea adicional;
- generación de resumen;
- generación de informe textual;
- validación/exportación JSON;
- validación antes de guardar;
- confirmación de limpieza.

### `TAIProject` / `AIProject1`

Es el componente central del sample.

Mantiene la estructura principal en:

```pascal
AIProject1.ProjectData
```

El sample usa `AIProject1` para almacenar:

- datos del proyecto;
- documentos ágiles en `agile_documents`;
- lista de tareas en `planning.tasks`;
- configuración básica del proyecto;
- estado serializable del `.aiproj.json`.

También se llama:

```pascal
AIProject1.EnsureProjectStructure;
```

para garantizar que exista la estructura JSON mínima.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

Usado para recibir los datos de la pestaña **Config IA** y aplicar la configuración en `AIProject1` y `ChatGPT1`.

El sample usa:

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

Además, el formulario todavía actualiza directamente algunas propiedades de `ChatGPT1`, como modelo, token, endpoint y tipo de chat.

### `TAIProjectStorage` / `AIProjectStorage1`

Usado para la persistencia del proyecto.

Métodos usados:

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

El componente está realmente integrado al flujo de guardar y cargar.

### `TAIProjectTasks` / `AIProjectTasks1`

Usado para trabajar con las tareas ya almacenadas en `ProjectData`.

En la versión actual, se usa principalmente para:

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

La generación de tareas todavía la realiza `main.pas`, con un prompt manual enviado a `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

El componente está presente en el formulario y vinculado a `AIProject1`.

Sin embargo, en la versión actual del sample, la generación de especificación no llama directamente a un método público del componente. El flujo de especificación se realiza en `main.pas`, usando prompt manual, parsing manual e integración manual en `ProjectData`.

Por lo tanto, este componente está **presente y conectado**, pero **no es el ejecutor principal del flujo actual**.

### `TAIProjectTaskGrid` / `TaskGrid1`

Componente visual realmente integrado.

Usado para mostrar `ProjectData.planning.tasks` en formato de grilla.

El formulario llama:

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

Componente visual realmente integrado.

Usado para actualizar el panel de estado basado en el proyecto actual.

El formulario llama:

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

El componente está presente en el formulario y vinculado al proyecto.

En la versión actual, no es una parte central del flujo visual demostrado. No hay una pestaña o panel completo de acciones de tarea expuesto al usuario en este sample.

### `TAIProjectDescription` / `AIProjectDescription1`

El componente está presente y vinculado al proyecto.

En la versión actual del sample, no se usa directamente en el flujo principal de generación de especificación o tareas.

---

## Componentes presentes o citados, pero no demostrados completamente

### Agentes

La documentación anterior decía que los agentes habían sido eliminados del sample. En el estado actual del proyecto, esa eliminación aún no está completa.

Todavía existen en el sample:

- pestaña `Agent`;
- `TAIAgentManagerFrame`;
- referencias a units de agentes;
- botones y métodos relacionados con la generación de agentes;
- dependencia del paquete `openai_agent` en el `.lpi`.

Por lo tanto, los agentes están **parcialmente presentes**, pero el flujo principal del sample sigue siendo la generación de especificación y tareas.

### Gantt y Timeline

El README anterior describía las pestañas Gantt y Timeline como parte del flujo principal.

En la versión actual del sample, esas pestañas aún no se demuestran de forma completa en la interfaz principal.

El componente `TAIProjectGantt` aparece declarado en `main.pas`, pero la pantalla actual no presenta una pestaña Gantt completa integrada al flujo. Tampoco hay una pestaña Timeline completa en el formulario actual.

### Informes

El sample posee botones y métodos para resumen, informe de tareas, informe de agentes, exportación Markdown y exportación JSON.

En la versión actual, estos informes se generan mediante llamadas al LLM en el propio formulario, y no mediante un flujo visual completo basado en `TAIProjectReports`.

---

## Archivo generado

El sample guarda el proyecto en el archivo fijo:

```text
project_tasklist_demo.aiproj.json
```

Este archivo contiene el JSON completo del proyecto, incluyendo:

- `project`;
- `agile_documents`;
- `planning.tasks`;
- demás estructuras garantizadas por `AIProject1.EnsureProjectStructure`.

---

## Cómo ejecutar el flujo actual

1. Abra `project_tasklist_ai_demo.lpi` en Lazarus.
2. Compile y ejecute.
3. Acceda a la pestaña **Config IA**.
4. Seleccione el proveedor y el modelo.
5. Informe token o endpoint, según el proveedor.
6. Haga clic en **Aplicar Configuração**.
7. Haga clic en **Testar IA** para validar la comunicación.
8. Vaya a la pestaña **Projeto**.
9. Complete nombre, objetivo, restricciones y entregables.
10. Genere la especificación usando **Gerar Descrição Elaborada (IA)**, disponible actualmente en la pestaña **Tarefas**.
11. Genere las tareas usando **Gerar Tarefas com IA**.
12. Revise el resultado en la pestaña **Tarefas**.
13. Revise el JSON y los logs en la pestaña **JSON/Log**.
14. Guarde el proyecto con **Salvar Projeto**.
15. Cárguelo nuevamente con **Carregar Projeto**.

---

## Limitaciones conocidas de esta versión

- El formulario todavía concentra mucha lógica de prompt, parsing y validación JSON.
- `TAIProjectSpecification` está conectado, pero el flujo actual de especificación aún se ejecuta manualmente desde `main.pas`.
- `TAIProjectTasks` se usa para recalcular y consultar tareas, pero la generación de tareas aún se realiza en el formulario.
- Los agentes todavía aparecen parcialmente en el sample, aunque no son el foco principal de la demo.
- Gantt y Timeline todavía no están expuestos como pestañas completas en el formulario.
- La exportación Markdown y la validación JSON todavía usan llamadas al LLM, en lugar de usar exclusivamente componentes de informe/exportación.
- Guardar, cargar y limpiar todavía tienen llamadas auxiliares al LLM, aunque esas operaciones pueden ser locales.
- El archivo guardado usa el nombre fijo `project_tasklist_demo.aiproj.json`.

---

## Alcance real de esta versión

Este sample debe entenderse como una demostración práctica de integración inicial entre `TCHATGPT`, `TAIProject`, `TAIProjectLLMConfig`, `TAIProjectStorage`, `TAIProjectTasks`, `TAIProjectTaskGrid` y `TAIProjectStatusPanel`.

Todavía no debe tratarse como el ejemplo final de la arquitectura ideal del paquete `AI Project`.
