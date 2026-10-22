# TCHATGPT — AI Component Suite para Lazarus / Free Pascal

🌐 **Idiomas / Languages**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md) • [العربية](README_AR.md) • [中文](README_CH.md) • [Русский](README_RU.md) • [日本語](README_JP.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 1. Objetivo del Proyecto

**TCHATGPT** (desarrollado por [Maurinsoft](https://maurinsoft.com.br)) es una suite modular de componentes visuales y no visuales en **Object Pascal (Free Pascal / Lazarus)** para la integración directa y nativa de Inteligencia Artificial moderna, Visión por Computadora, Procesamiento de Voz, Agentes Autónomos, Automatización Industrial, Hardware y Gestión de Proyectos.

El objetivo central de la suite es permitir que los desarrolladores de escritorio y embebidos integren capacidades avanzadas de IA directamente en código nativo, con:
1. **Control Total y Baja Latencia:** Sin depender de servidores web intermediarios ni frameworks pesados de frontend.
2. **Conectividad Híbrida:** Soporte para LLMs en la nube (OpenAI, Claude, Gemini, Ollama) y para inferencia local 100% offline mediante [`llama.cpp`](pacote/AI%20LlamaCpp/).
3. **Agentes Autónomos y Herramientas:** Arquitectura de agentes capaces de ejecutar código, consultar bases de datos, inspeccionar archivos, controlar robots y comunicarse mediante los protocolos [A2A](pacote/AI%20A2A/) y [MCP](pacote/AI%20MCP/).
4. **Interacción con el Mundo Físico:** Dispositivos USB, puertos serie, sensores Kinect, joysticks, PLCs Modbus, brokers MQTT y emulación de firmware Marlin CNC/impresora 3D.

---

## 📦 2. Catálogo de Paquetes: Finalidad y Estado

A continuación se presenta la **finalidad conceptual** de cada paquete (lo que manipula, procesa o controla) y su estado actual de madurez:

| Paquete Lazarus | Carpeta Fuente | Finalidad (Qué manipula / hace) | Estado Actual |
|---|---|---|---|
| [**`openai_core.lpk`**](pacote/packages/openai_core.lpk) | [`pacote/AI/`](pacote/AI/) | Conecta con APIs de LLMs (OpenAI, Claude, Gemini, Ollama), gestiona tokens, prompts, modelos y provee las clases base. | **Stable / Beta** |
| [**`openai_agent.lpk`**](pacote/packages/openai_agent.lpk) | [`pacote/AI Agent/`](pacote/AI%20Agent/) | Orquesta agentes autónomos, llamadas a herramientas (tool calling), memoria factual y guardrails de seguridad. | **Stable / Beta**; pipelines compuestos *Experimental* |
| [**`openai_a2a.lpk`**](pacote/packages/openai_a2a.lpk) | [`pacote/AI A2A/`](pacote/AI%20A2A/) | Estandariza la comunicación e intercambio de mensajes estructurados directamente entre diferentes agentes inteligentes en red (Agent-to-Agent). | **Stable / Beta** |
| [**`openai_mcp.lpk`**](pacote/packages/openai_mcp.lpk) | [`pacote/AI MCP/`](pacote/AI%20MCP/) | Implementa el estándar abierto Model Context Protocol (Anthropic/OpenAI) como cliente y servidor JSON-RPC para exponer herramientas. | **Stable / Beta** |
| [**`openai_input.lpk`**](pacote/packages/openai_input.lpk) | [`pacote/AI Input/`](pacote/AI%20Input/) | Captura datos del mundo exterior: joysticks XInput/WinMM, firmas de voz, cámaras, sensores Kinect, puertos serie, sockets TCP/UDP, servidores web y documentos locales. | **Stable / Beta**; integración hardware_net_demo *Experimental* |
| [**`openai_output.lpk`**](pacote/packages/openai_output.lpk) | [`pacote/AI Output/`](pacote/AI%20Output/) | Genera documentos formateados Word (DOCX/OpenXML), hojas Excel (XLSX), PDFs, texto plano, JSON estructurado e impresiones térmicas POS. | **Stable / Beta** |
| [**`openai_vision.lpk`**](pacote/packages/openai_vision.lpk) | [`pacote/AI Vision/`](pacote/AI%20Vision/) | Procesa flujos de video e imágenes mediante OpenCV o métodos nativos: detecta rostros, rastrea movimiento e identifica posturas humanas. | **Stable / Beta** |
| [**`openai_image.lpk`**](pacote/packages/openai_image.lpk) | [`pacote/AI Image/`](pacote/AI%20Image/) | Aplica filtros y manipulaciones gráficas en imágenes directamente en Pascal nativo, sin exigir DLLs ni librerías externas. | **Stable / Beta** |
| [**`openai_voice.lpk`**](pacote/packages/openai_voice.lpk) | [`pacote/AI Voice/`](pacote/AI%20Voice/) | Procesa audio hablado: convierte texto a voz audible (TTS), transcribe voz a texto (STT) y aplica filtros acústicos. | **Stable / Beta** |
| [**`openai_project.lpk`**](pacote/packages/openai_project.lpk) | [`pacote/AI Project/`](pacote/AI%20Project/) | Renderiza interfaces visuales de gestión: diagramas de Gantt interactivos, redes PERT/CPM, tableros Kanban e histogramas de equipo. | **Stable / Beta** |
| [**`openai_project_core.lpk`**](pacote/packages/openai_project_core.lpk) | [`pacote/AI Project Core/`](pacote/AI%20Project%20Core/) | Ejecuta cálculos matemáticos de cronograma: calcula camino crítico (CPM), valida grafos acíclicos y gestiona calendarios laborales. | **Stable / Beta** |
| [**`openai_industrial.lpk`**](pacote/packages/openai_industrial.lpk) | [`pacote/AI Industrial/`](pacote/AI%20Industrial/) | Comunica con equipamiento industrial de fábrica vía Modbus TCP/RTU, broker MQTT, pinmap Arduino y control de brazos robóticos. | **Stable / Beta** |
| [**`openai_marlin.lpk`**](pacote/packages/openai_marlin.lpk) | [`pacote/AI Simulation/AIMarlin/`](pacote/AI%20Simulation/AIMarlin/) | Emula el firmware de impresoras 3D y máquinas CNC Marlin, interpretando comandos G-Code y proveyendo puertos serie virtuales. | **Stable / Beta** |
| [**`openai_simulation.lpk`**](pacote/packages/openai_simulation.lpk) | [`pacote/AI Simulation/`](pacote/AI%20Simulation/) | Ejecuta simulaciones computacionales 2D basadas en reglas celulares, colas de atención y desplazamiento de robots móviles. | **Stable / Beta** |
| [**`openai_graphic.lpk`**](pacote/packages/openai_graphic.lpk) | [`pacote/AI Graphic/`](pacote/AI%20Graphic/) | Manipula gráficos 3D OpenGL, avatares virtuales con animación labial, esqueletos y escenas físicas. | **Stable / Beta** |
| [**`openai_hardware.lpk`**](pacote/packages/openai_hardware.lpk) | [`pacote/AI Hardware/`](pacote/AI%20Hardware/) | Recolecta telemetría y métricas del sistema operativo y hardware: consumo de CPU, memoria RAM, discos, GPUs y procesos activos. | **Stable / Beta** |
| [**`openai_graph.lpk`**](pacote/packages/openai_graph.lpk) | [`pacote/AI Graph/`](pacote/AI%20Graph/) | Construye, analiza y visualiza grafos de dependencias lógicas, redes de conocimiento y rutas viales GeoJSON. | **Stable / Beta** |
| [**`openai_llamacpp.lpk`**](pacote/packages/openai_llamacpp.lpk) | [`pacote/AI LlamaCpp/`](pacote/AI%20LlamaCpp/) | Ejecuta modelos de lenguaje (LLMs) localmente en la computadora mediante la biblioteca `llama.cpp` x64 en formato GGUF sin internet. | **Stable / Beta** |
| [**`openai_ml.lpk`**](pacote/packages/openai_ml.lpk) | [`pacote/AI Math/`](pacote/AI%20Math/) | Ejecuta algoritmos clásicos de aprendizaje automático (redes neuronales, perceptrones, mapas SOM) y operaciones matriciales (NUMPS) en Pascal puro. | **Stable / Beta** |
| [**`openai_python.lpk`**](pacote/packages/openai_python.lpk) | [`pacote/python/`](pacote/python/) | Integra runtimes externos de Python para ejecutar modelos de deep learning (YOLOv8, CNNs y LSTMs) acoplados a Lazarus. | **Stable / Beta** |
| [**`openai_rag.lpk`**](pacote/packages/openai_rag.lpk) | [`pacote/AI RAG/`](pacote/AI%20RAG/) | Realiza búsqueda semántica y generación aumentada por recuperación (RAG), indexando documentos para alimentar el contexto de los LLMs. | **Stable / Beta** |
| [**`openai_dbase.lpk`**](pacote/packages/openai_dbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Conecta con bases de datos relacionales para guardar historial de chat, logs de auditoría y memoria de largo plazo con ZeosLib. | **Stable / Beta** |
| [**`openai_aidbase.lpk`**](pacote/packages/openai_aidbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Extrae diccionarios de datos y esquemas de tablas SQL para que los modelos formulen consultas precisas. | **Stable / Beta** |
| [**`openai_files.lpk`**](pacote/packages/openai_files.lpk) | [`pacote/AI Files/`](pacote/AI%20Files/) | Escanea e indexa árboles de directorios en disco, generando datasets estructurados para entrenamiento y análisis. | **Stable / Beta** |
| [**`openai_observability.lpk`**](pacote/packages/openai_observability.lpk) | [`pacote/AI Observability/`](pacote/AI%20Observability/) | Monitorea operaciones de IA: registra trazas/spans, mide latencia, audita consumo de tokens y detecta anomalías. | **Stable / Beta** |
| [**`openai_evaluation.lpk`**](pacote/packages/openai_evaluation.lpk) | [`pacote/AI Evaluation/`](pacote/AI%20Evaluation/) | Evalúa la precisión de respuestas generadas utilizando jueces automatizados (LLM-as-a-judge) e informes de regresión. | **Stable / Beta** |
| [**`openai_integration.lpk`**](pacote/packages/openai_integration.lpk) | [`pacote/AI/`](pacote/AI/) | Conecta múltiples componentes en tuberías de procesamiento unificadas y ejecutores encadenados. | **Stable / Beta** |
| [**`openai_webrtc.lpk`**](pacote/packages/openai_webrtc.lpk) | [`pacote/AI Communication/`](pacote/AI%20Communication/) | Establece canales de datos punto a punto de baja latencia (WebRTC DataChannel) mediante libdatachannel. | **Stable / Beta** |

---

## 📂 3. Organización de las Carpetas del Repositorio

A continuación se describe el propósito de cada carpeta del proyecto, su contenido y utilidad práctica:

| Carpeta | Propósito del Directorio | Qué contiene | Para qué sirve (Utilidad Práctica) |
|---|---|---|---|
| [**`pacote/AI/`**](pacote/AI/) | Base e infraestructura central | Clases fundamentales ([`aibase.pas`](pacote/AI/aibase.pas), [`aiconfig.pas`](pacote/AI/aiconfig.pas)), clientes LLM ([`chatgpt.pas`](pacote/AI/chatgpt.pas), [`aiclaude.pas`](pacote/AI/aiclaude.pas), [`aigemini.pas`](pacote/AI/aigemini.pas), [`aiollama.pas`](pacote/AI/aiollama.pas)), tokenizers y enrutadores. | Centraliza la comunicación HTTP/REST con proveedores de IA y ofrece la arquitectura base compartida. |
| [**`pacote/AI Agent/`**](pacote/AI%20Agent/) | Orquestación de Agentes Autónomos | Módulos de agentes ([`aiagent.pas`](pacote/AI%20Agent/aiagent.pas)), memoria determinista, mapas conceptuales, guardrails de seguridad y autocorrección de código. | Permite crear agentes que resuelven objetivos en múltiples pasos, decidiendo cuándo invocar código Pascal o consultar datos. |
| [**`pacote/AI A2A/`**](pacote/AI%20A2A/) | Protocolo Agent-to-Agent | Protocolo de comunicación y mensajería entre agentes de IA ([`aia2a_client.pas`](pacote/AI%20A2A/aia2a_client.pas)). | Permite que múltiples agentes colaboren, deleguen subtareas y compartan contexto estructurado en red. |
| [**`pacote/AI MCP/`**](pacote/AI%20MCP/) | Model Context Protocol | Implementación de cliente y servidor MCP sobre JSON-RPC ([`aimcp_client.pas`](pacote/AI%20MCP/aimcp_client.pas), [`aimcp_server.pas`](pacote/AI%20MCP/aimcp_server.pas)). | Permite que los LLMs interactúen directamente con las herramientas y datos del sistema mediante el estándar abierto MCP. |
| [**`pacote/AI Input/`**](pacote/AI%20Input/) | Dispositivos y Fuentes de Entrada | Joysticks ([`aijoystick.pas`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), audio ([`aispeakersignature.pas`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Kinect ([`aikinectsensor.pas`](pacote/AI%20Input/AIKinect/aikinectsensor.pas)), USB, Serie, Sockets, Servidor Web y lectores de documentos (PDF, DOCX, XLSX). | Captura y normaliza datos del mundo exterior (sensores, red, mandos, archivos) para alimentar los flujos de IA. |
| [**`pacote/AI Output/`**](pacote/AI%20Output/) | Generación de Salidas Estructuradas | Generadores de informes Word ([`aiworddocument.pas`](pacote/AI%20Output/aiworddocument.pas)), hojas Excel ([`aixlsxwriter.pas`](pacote/AI%20Output/aixlsxwriter.pas)), impresoras térmicas POS ([`aiposprinter.pas`](pacote/AI%20Output/aiposprinter.pas)) y formateadores JSON. | Produce salidas físicas (tickets) o archivos digitales con las respuestas generadas por la IA. |
| [**`pacote/AI Vision/`**](pacote/AI%20Vision/) | Visión por Computadora | Conector OpenCV ([`aiopencv.pas`](pacote/AI%20Vision/aiopencv.pas)), rastreador facial ([`aifacetracker.pas`](pacote/AI%20Vision/aifacetracker.pas)), detector de movimiento ([`aimotiontracker.pas`](pacote/AI%20Vision/aimotiontracker.pas)), estimador de posturas ([`aihumanposedetector.pas`](pacote/AI%20Vision/aihumanposedetector.pas)) y procesadores de cuadros. | Analiza secuencias de video de cámaras web y archivos para reconocimiento visual y seguimiento de personas/objetos. |
| [**`pacote/AI Voice/`**](pacote/AI%20Voice/) | Voz, Reconocimiento y Síntesis | Sintetizador de voz TTS ([`aivoicesynthesizer.pas`](pacote/AI%20Voice/aivoicesynthesizer.pas)), reconocedor STT ([`aispeechrecognizer.pas`](pacote/AI%20Voice/aispeechrecognizer.pas)), asistentes de voz y clones vocales. | Permite que la aplicación hable audiblemente con el usuario y reconozca comandos hablados desde el micrófono. |
| [**`pacote/AI Project Core/`**](pacote/AI%20Project%20Core/) | Núcleo Matemático de Proyectos | Escalonador CPM ([`aicpmscheduler.pas`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), grafo acíclico de tareas ([`aitaskgraph.pas`](pacote/AI%20Project%20Core/aitaskgraph.pas)), calendario laboral ([`aiworkcalendar.pas`](pacote/AI%20Project%20Core/aiworkcalendar.pas)) y nivelación de recursos. | Calcula cronogramas, holguras y camino crítico de manera desacoplada de la interfaz gráfica. |
| [**`pacote/AI Project/`**](pacote/AI%20Project/) | Vistas Visuales de Proyectos (LCL) | Vistas interactivas: Diagrama de Gantt ([`aiganttview.pas`](pacote/AI%20Project/aiganttview.pas)), Red PERT ([`ainetworkview.pas`](pacote/AI%20Project/ainetworkview.pas)), Tablero Kanban ([`aiboardview.pas`](pacote/AI%20Project/aiboardview.pas)) e Histograma de Recursos ([`airesourceview.pas`](pacote/AI%20Project/airesourceview.pas)). | Renderiza controles gráficos de usuario para planificación interactiva de tareas y proyectos. |
| [**`pacote/AI Industrial/`**](pacote/AI%20Industrial/) | Automatización y Redes Industriales | Cliente Modbus TCP/RTU ([`aimodbus.pas`](pacote/AI%20Industrial/aimodbus.pas)), cliente MQTT ([`aimqtt.pas`](pacote/AI%20Industrial/aimqtt.pas)), cinemática de brazo robótico ([`aiarm_robot.pas`](pacote/AI%20Industrial/aiarm_robot.pas)) y mapa de pines Arduino. | Integra aplicaciones Lazarus a la fábrica, leyendo registros de PLCs y controlando actuadores físicos. |
| [**`pacote/AI Simulation/`**](pacote/AI%20Simulation/) | Simulación 2D y Emulación Marlin | Motor de simulación celular en cuadrícula ([`aisimulationengine.pas`](pacote/AI%20Simulation/aisimulationengine.pas)), colas de atención y emulador de firmware Marlin G-code ([`aimarlinsimulator.pas`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas)). | Simula escenarios logísticos y valida trayectorias de máquinas CNC antes de ejecutarlas en maquinaria real. |
| [**`pacote/AI Graphic/`**](pacote/AI%20Graphic/) | Gráficos 3D y Avatares | Visor 3D OpenGL ([`ai3dmodelviewer.pas`](pacote/AI%20Graphic/ai3dmodelviewer.pas)), avatares con sincronización labial ([`aiavatar_lipsync.pas`](pacote/AI%20Graphic/aiavatar_lipsync.pas)), esqueletos y cliente API Tripo3D. | Manipula y renderiza modelos 3D, personajes virtuales y animaciones en la interfaz. |
| [**`pacote/AI Hardware/`**](pacote/AI%20Hardware/) | Telemetría de Hardware | Lectores de CPU ([`aicpu.pas`](pacote/AI%20Hardware/aicpu.pas)), RAM ([`aimemory.pas`](pacote/AI%20Hardware/aimemory.pas)), Disco ([`aidisk.pas`](pacote/AI%20Hardware/aidisk.pas)), GPU ([`aigpu.pas`](pacote/AI%20Hardware/aigpu.pas)) y SO ([`aiso.pas`](pacote/AI%20Hardware/aiso.pas)). | Provee métricas de consumo de hardware para diagnósticos y balanceo dinámico de cargas de IA. |
| [**`pacote/AI Graph/`**](pacote/AI%20Graph/) | Grafos y Rutas Geográficas | Grafo de dependencias ([`aidependencygraph.pas`](pacote/AI%20Graph/aidependencygraph.pas)), visualizador de grafos ([`aigraphvisualizer.pas`](pacote/AI%20Graph/aigraphvisualizer.pas)), cálculo de rutas GeoJSON ([`airoutecalculator.pas`](pacote/AI%20Graph/airoutecalculator.pas)). | Construye y visualiza redes nodales, flujos de relaciones y perfiles de rutas sobre mapas. |
| [**`pacote/AI LlamaCpp/`**](pacote/AI%20LlamaCpp/) | Inferencia LLM Local | Conector de API y runtime para `llama.cpp` x64 ([`aillamacppruntime.pas`](pacote/AI%20LlamaCpp/aillamacppruntime.pas)), cuantización y LoRA. | Permite ejecutar modelos de IA de forma totalmente privada y sin conexión en la máquina del usuario. |
| [**`pacote/AI Math/`**](pacote/AI%20Math/) | Matemática y Machine Learning | Librería de álgebra lineal NUMPS ([`numps.pas`](pacote/AI%20Math/numps.pas)), redes perceptrón y mapas autoorganizados (SOM). | Realiza cálculos de matrices/vectores y entrenamiento de redes neuronales directamente en Pascal nativo. |
| [**`pacote/AI RAG/`**](pacote/AI%20RAG/) | Búsqueda Semántica y RAG | Recuperación aumentada por generación ([`airag.pas`](pacote/AI%20RAG/airag.pas)), extractores de texto e indexación por lotes. | Encuentra fragmentos relevantes en grandes volúmenes de documentos para fundamentar las respuestas de los LLMs. |
| [**`pacote/AI DBase/`**](pacote/AI%20DBase/) | Bases de Datos y Metadatos | Diccionarios de esquemas relacionales ([`aidbdictionary.pas`](pacote/AI%20DBase/aidbdictionary.pas)), persistencia de historial ZeosLib. | Mapea tablas de bases de datos para que los agentes de IA formulen consultas SQL con precisión. |
| [**`pacote/AI Observability/`**](pacote/AI%20Observability/) | Observabilidad de IA | Colector de trazas y métricas ([`aitrace.pas`](pacote/AI%20Observability/aitrace.pas)). | Registra auditoría de llamadas, consumo de tokens y tiempos de respuesta de cada consulta. |
| [**`pacote/AI Evaluation/`**](pacote/AI%20Evaluation/) | Evaluación y Benchmarking | Juez de evaluación con LLMs ([`aieval_judge.pas`](pacote/AI%20Evaluation/aieval_judge.pas)). | Evalúa y califica automáticamente la precisión de respuestas generadas contra rúbricas objetivas. |
| [**`pacote/packages/`**](pacote/packages/) | Paquetes de Instalación Lazarus | 28 archivos `.lpk` configurados. | Permite instalar los componentes en la paleta de Lazarus según las necesidades del proyecto. |
| [**`pacote/samples/`**](pacote/samples/) | Proyectos de Demostración | Más de 95 ejemplos ejecutables completos con código ([`pacote/samples/README.md`](pacote/samples/README.md)). | Sirve como guía práctica y manual de usuario para cada componente de la suite. |
| [**`tests/`**](tests/) | Pruebas Automatizadas | Proyectos de consola `.lpr` ejecutables mediante Free Pascal. | Asegura la integridad y ausencia de regresiones en los algoritmos y componentes. |

---

## 🧭 4. Cómo Navegar la Documentación y Ejemplos

Para explorar cada subsistema:
1. Revise la [**Guía General de Samples**](pacote/samples/README.md) para ver los 95+ ejemplos prácticos con explicaciones y capturas.
2. Acceda a la carpeta del módulo deseado (ej.: [**`pacote/AI Input/`**](pacote/AI%20Input/)) para conocer las unidades y componentes.
3. Para cada sample, consulte el manual con **Propiedades**, **Métodos** y **Eventos** en su `README.md` (por ejemplo: [Manual del Sample de Joystick](pacote/samples/AI%20Input/joystick_demo_README.md) y [Manual de Demostración de Proyectos](pacote/samples/AI%20Project/Demo_AI_Project/README.md)).

---

## 🛠️ 5. Requisitos e Instalación

- **Compilador:** [Free Pascal (FPC)](https://www.freepascal.org/) versión 3.2.2 o superior.
- **IDE:** [Lazarus](https://www.lazarus-ide.org/) versión 3.0 o superior (32-bit o 64-bit).
- **Instalación de Paquetes:**
  1. En Lazarus, vaya al menú `Package` -> `Open Package File (.lpk)...`.
  2. Navegue hasta [`pacote/packages/`](pacote/packages/).
  3. Abra y compile el paquete base [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Haga clic en `Compile` y, si desea los componentes en la paleta, en `Use` -> `Install`.
  5. Instale el resto de los paquetes según los requerimientos de su aplicación.

---

## 📄 6. Licencia

Este proyecto se distribuye bajo los términos de la licencia **GPL v3**. Consulte el archivo [LICENSE](LICENSE) para más detalles.