# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌍 **Languages / Idiomas**

* [Português (PT-BR)](README.md)
* [English (EN)](README_EN.md)
* [Español (ES)](README_ES.md)
* [Français (FR)](README_FR.md)
* [Italiano (IT)](README_IT.md)
* [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow.svg)]()

---

## Visión General

**TCHATGPT** es una suite open source de componentes visuales y no visuales para **Lazarus / Free Pascal**, creada para facilitar la integración de recursos de Inteligencia Artificial en aplicaciones de escritorio, industriales, educativas y corporativas.

El proyecto ofrece componentes para conexión con proveedores de LLM, modelos locales, procesamiento de datos, aprendizaje automático, voz, imagen, agentes, grafos, entrada y salida de información, además de componentes experimentales para visión computacional y recursos gráficos 3D.

> Este proyecto debe entenderse como una **suite de componentes para integración de IA en aplicaciones Lazarus**, y no como una plataforma completa de IA destinada a reemplazar frameworks especializados de entrenamiento, plataformas MLOps o infraestructura de despliegue de modelos a gran escala.

---

## Objetivo del Proyecto

El objetivo principal es permitir que desarrolladores Lazarus / Free Pascal puedan incorporar recursos de IA en sus sistemas de forma simple, reutilizable y basada en componentes.

La suite busca atender escenarios como:

* creación de asistentes con IA generativa;
* integración con APIs de LLM;
* uso de modelos locales mediante servidores compatibles;
* generación y análisis de datasets;
* clasificación simple de textos;
* automatización con agentes;
* síntesis de voz;
* procesamiento básico de imágenes;
* filtros digitales de sonido;
* integración con dispositivos, sensores y canales externos;
* prototipado de aplicaciones con IA en Lazarus.

---

## Estado Actual del Proyecto

El proyecto está en desarrollo activo y posee componentes en diferentes niveles de madurez.

### Componentes más consolidados

* `TCHATGPT`
* `TAIBaseComponent`
* `TNeuralNetwork`
* `TTokenList`
* `TAICodeAssistant`
* `TAIDatasetGenerator`
* `TAIVoiceSynthesizer`
* filtros de imagen
* filtros de sonido
* componentes de grafo y dataset

### Componentes experimentales o en evolución

* integración con Python;
* componentes CNN, YOLO, LSTM y SOM;
* componentes de agentes autónomos;
* componentes avanzados de entrada y salida;
* componentes OpenCV;
* visualización 3D;
* integración con Tripo3D;
* componentes industriales, cámara, audio, navegador, MQTT, Modbus y CCTV.

---

## Pestañas de Componentes del Paquete

El paquete instala componentes en la paleta de Lazarus, organizados por área funcional.

---

## AI Core

Componentes principales de IA generativa, machine learning y soporte al proyecto.

### `TCHATGPT`

Conector principal para proveedores de IA generativa.

Permite enviar preguntas, configurar proveedores, seleccionar modelos y recibir respuestas estructuradas.

Proveedores previstos o soportados:

* OpenAI;
* Google Gemini;
* Anthropic Claude;
* OpenRouter;
* Cerebras;
* servidor local compatible con `/v1/chat/completions`;
* Ollama o servicios locales similares.

### `TNeuralNetwork`

Red neural multicapa simple implementada en Pascal.

Permite:

* crear redes locales;
* configurar entradas, capas ocultas y salidas;
* entrenar por épocas;
* calcular pérdida;
* guardar y cargar modelos.

### `TTokenList`

Componente utilitario para tokenización básica de texto.

Puede ser usado para:

* clasificación;
* análisis textual;
* preprocesamiento;
* grafos de decisión;
* preparación de datasets.

### `TAICodeAssistant`

Asistente de código basado en LLM.

Puede ser usado para:

* revisar código;
* sugerir mejoras;
* generar comentarios;
* explicar bloques de código;
* auxiliar en pruebas;
* convertir o documentar rutinas.

### `TAIDatasetGenerator`

Generador de datasets para entrenamiento, fine-tuning o clasificación local.

Soporta o está orientado a soportar estructuras como:

* CSV;
* JSON;
* JSONL;
* matrices de entrada y salida para entrenamiento local.

### `TAIModelRegistry`

Registro central de modelos, proveedores, endpoints y parámetros.

Permite organizar:

* nombre del modelo;
* proveedor;
* endpoint;
* temperatura;
* límite de tokens;
* parámetros predeterminados.

### `TAIWizardConfig`

Asistente de configuración para nuevos proyectos de IA.

Puede utilizarse para preparar proyectos como:

* chatbot;
* clasificador;
* pipeline;
* agente;
* asistente técnico.

---

## AI Sound Filters

Componentes para procesamiento digital de señales y filtros de sonido.

### `TLowPassFilter`

Filtro pasa-baja IIR de primer orden.

Usado para suavizar variaciones rápidas y reducir ruido de alta frecuencia.

### `THighPassFilter`

Filtro pasa-alta IIR de primer orden.

Usado para remover componentes de baja frecuencia, offset o ruido DC.

### `TAverageFilter`

Filtro de media móvil.

Usado para suavización simple de señales.

### `TFDMMultiplexer`

Multiplexador por división de frecuencia.

Permite simular canales en diferentes bandas de frecuencia.

### `TTDMMultiplexer`

Multiplexador por división de tiempo.

Permite intercalar canales por ranuras temporales.

### `TCDMMultiplexer`

Multiplexador CDM/CDMA.

Utiliza códigos ortogonales para separar señales.

### `TOFDMMultiplexer`

Multiplexador OFDM con uso de FFT/IFFT.

Indicado para estudios y simulaciones de telecomunicaciones.

---

## AI Image

Componentes para procesamiento básico de imágenes.

### `TGrayscaleFilter`

Convierte imágenes a escala de grises.

### `TNegativeFilter`

Aplica inversión de colores.

### `TBrightnessContrastFilter`

Ajusta brillo y contraste.

### `TBinarizationFilter`

Aplica umbralización para generar imágenes en blanco y negro.

### `TBlurFilter`

Aplica suavizado mediante convolución.

### `TSharpenFilter`

Realza nitidez utilizando un kernel de convolución.

### `TSobelFilter`

Detecta bordes mediante el operador Sobel.

### `TErosionDilationFilter`

Ejecuta operaciones morfológicas de erosión y dilatación.

---

## AI Schedule

Componentes para organización, persistencia y gestión de dependencias de tareas.

### `TJSONGroupStorage`

Componente para almacenamiento de datos agrupados en JSON.

Puede ser usado para:

* guardar configuraciones;
* persistir parámetros;
* almacenar textos;
* organizar datos por grupos.

### `TIASchedule`

Gestor de tareas con control de dependencias.

Permite modelar:

* tarea padre;
* tarea hija;
* dependencias;
* estado de preparación;
* control simple de ejecución.

---

## AI Voice

Componentes de síntesis de voz.

### `TAIVoiceSynthesizer`

Componente de Text-to-Speech.

En Windows, puede usar SAPI.
En Linux, puede usar eSpeak/eSpeak-NG.

Principales recursos:

* reproducir texto por voz;
* ajustar volumen;
* ajustar velocidad;
* listar voces disponibles;
* ejecución asíncrona;
* integración con aplicaciones de escritorio.

---

## AI Agent

Componentes para agentes inteligentes y toma de decisiones estructurada.

### `TAIAgent`

Componente orquestador del agente.

Permite enviar instrucciones a un LLM, interpretar respuestas estructuradas y coordinar acciones.

### `TAIAgentOptions`

Almacena contexto, preguntas, directrices y reglas de análisis.

### `TAIAgentAction`

Define acciones permitidas para el agente.

Permite configurar:

* acciones disponibles;
* parámetros esperados;
* callbacks de ejecución.

### `TAIAgentResource`

Representa recursos externos que pueden ser activados por el agente.

Ejemplos:

* archivos;
* correo electrónico;
* HTTP;
* SMS;
* WhatsApp;
* TCP/UDP;
* Web APIs.

### `TAIAgentOutput`

Capa de salida que conecta decisiones del agente con recursos reales del sistema.

---

## AI Graph

Componentes para estructuración de datos, grafos y datasets.

### `TAIGraphMap`

Grafo ponderado para clasificación y análisis basado en tokens.

Puede ser usado en:

* clasificación textual;
* agrupación de conceptos;
* relación entre términos;
* análisis simple de temas.

### `TAITrainingExporter`

Exportador de datos para entrenamiento.

Formatos previstos o soportados:

* CSV;
* JSON;
* JSONL;
* ARFF;
* vectores numéricos.

### `TAIDatasetAnalyzer`

Analizador de calidad de dataset.

Puede detectar:

* categorías vacías;
* duplicidad;
* desequilibrio de clases;
* textos muy cortos;
* textos muy largos.

### `TAITrainingReport`

Generador de informes técnicos de entrenamiento.

Puede registrar:

* precisión;
* error;
* pérdida;
* cantidad de tokens;
* confianza media;
* estadísticas del dataset.

### `TAIGraphVisualizer`

Exportador y visualizador de grafos.

Formatos previstos o soportados:

* DOT / GraphViz;
* Mermaid;
* JSON de visualización.

---

## AI Input

Componentes para entrada de datos e integración con fuentes externas.

Esta pestaña concentra componentes orientados a captura de información, comunicación e integración con dispositivos o sistemas.

Componentes previstos o en evolución:

* cámara;
* audio;
* servidor web;
* sockets;
* comunicación serial;
* impresora POS;
* CCTV/IP;
* Modbus;
* MQTT;
* correo electrónico;
* mensajería;
* captura del sistema operativo;
* navegador embebido;
* entradas industriales.

> Algunos componentes de esta pestaña pueden requerir bibliotecas externas, drivers, permisos del sistema operativo o servicios adicionales.

---

## AI Output

Componentes para salida de datos, generación de documentos e integración con destinos externos.

Recursos previstos o en evolución:

* generación de documentos;
* exportación de respuestas;
* salida estructurada;
* integración con canales externos;
* automatización de respuestas.

---

## AI Vision

Componentes para visión computacional.

Componentes previstos o en evolución:

* OpenCV;
* captura de cámara;
* procesamiento de frames;
* rastreo facial;
* rastreo de movimiento;
* clasificación de imágenes;
* detección de objetos.

> Esta área debe tratarse como experimental hasta que los componentes tengan demostraciones completas, dependencias documentadas y pruebas de integración.

---

## AI Graphic

Componentes gráficos y 3D relacionados con IA, simulación y visualización.

Componentes previstos o en evolución:

* escena 2D/3D;
* ambiente de entrenamiento;
* simulador físico;
* sensores virtuales;
* función de recompensa;
* visualización de modelos 3D;
* rig de esqueleto;
* controlador de avatar;
* biblioteca de poses;
* secuencia de animación;
* integración con generación de modelos 3D.

### `TAI3DModelViewer`

Visualizador de modelos 3D.

Objetivo:

* cargar modelos 3D;
* visualizar mallas;
* rotar;
* acercar;
* alejar;
* alternar entre modo sólido, alámbrico y puntos.

### `TAITripo3DClient`

Cliente para integración con un servicio externo de generación de modelos 3D.

Objetivo:

* generar modelo a partir de texto;
* generar modelo a partir de imagen;
* generar modelo a partir de múltiples imágenes;
* descargar el modelo 3D resultante.

> La integración con servicios externos debe validarse conforme a la documentación oficial de la API del proveedor utilizado.

---

## Instalación del Paquete en Lazarus

1. Abra Lazarus.
2. Acceda a **Package > Open Package File (.lpk)**.
3. Seleccione el archivo `pacote/packages/openai_core.lpk`.
4. Haga clic en **Compile**.
5. Luego haga clic en **Use > Install**.
6. Lazarus solicitará recompilar la IDE.
7. Después de reiniciar, los componentes aparecerán en la paleta de componentes.

---

## Proveedores de LLM

| Proveedor                   | Enum             | Tipo                    |
| --------------------------- | ---------------- | ----------------------- |
| OpenAI                      | `AIP_OPENAI`     | API externa             |
| OpenRouter                  | `AIP_OPENROUTER` | API externa / agregador |
| Cerebras                    | `AIP_CEREBRAS`   | API externa             |
| Google Gemini               | `AIP_GEMINI`     | API externa             |
| Anthropic Claude            | `AIP_CLAUDE`     | API externa             |
| Local / Ollama / compatible | `AIP_LOCAL`      | Servidor local          |

> Los nombres de modelos, límites, costos y disponibilidad pueden cambiar según cada proveedor. Siempre consulte la documentación oficial del servicio utilizado.

---

## Requisitos

### Ambiente principal

* Lazarus 3.x o superior;
* versión compatible de Free Pascal;
* Windows o Linux;
* paquete `openai_core.lpk`;
* conexión a internet para proveedores externos;
* servidor local configurado cuando se utilicen modelos offline.

### Windows

Para comunicación HTTPS, pueden requerirse DLLs OpenSSL compatibles con la arquitectura de la aplicación.

Verifique la carpeta `pacote/lib/`.

Se recomienda copiar las DLLs necesarias a la misma carpeta del ejecutable final.

### Linux

Dependiendo de los componentes utilizados, pueden ser necesarios paquetes adicionales, como:

* OpenSSL;
* eSpeak/eSpeak-NG;
* libpython;
* bibliotecas de cámara o audio;
* bibliotecas específicas para visión computacional.

Los requisitos pueden variar según el componente utilizado.

---

## Screenshots

> Las imágenes siguientes demuestran recursos ya probados o actualmente en desarrollo.
> Los componentes nuevos pueden no tener todavía demostraciones visuales completas.

### CNN Demo

![CNN Demo](screenshots/cnn_demo.jpg)

Demostración de clasificación de imágenes.

### Math Input / Output Demo

![Math Input Output Demo](screenshots/math_input_output_demo.jpg)

Demostración de componentes matemáticos.

### Python Connector Demo

![Python Demo](screenshots/python_demo.jpg)

Demostración de integración con Python.

### SOM Demo

![SOM Demo](screenshots/som_demo.jpg)

Demostración de mapa autoorganizado.

### Sound Filters Demo

![Sound Filters](screenshots/sound_filters.jpg)

Demostración de filtros de sonido.

### Voice Synthesizer Demo

![Voice Synthesizer](screenshots/voicesynthesizer.jpg)

Demostración de síntesis de voz.

### Disk Tree AI Dataset Demo

![Disk Tree AI Dataset Demo](screenshots/disk_tree_ai_dataset_demo.jpg)

Escaneo asíncrono del sistema de archivos y preparación del inventario del dataset de IA.

---

## Limitaciones Conocidas

El proyecto aún está en desarrollo y posee componentes en diferentes niveles de estabilidad.

Limitaciones actuales esperadas:

* algunos componentes pueden estar en fase experimental;
* no todos los componentes tienen demostraciones completas;
* las integraciones externas dependen de APIs de terceros;
* los componentes de visión computacional pueden requerir bibliotecas externas;
* los componentes Python dependen de versión y arquitectura compatibles;
* cada componente debe validarse antes de su uso en producción;
* las pruebas automatizadas y la integración continua aún deben ampliarse.

---

## Roadmap

### Corto plazo

* revisar la documentación de los componentes;
* estandarizar los nombres de las pestañas en inglés;
* separar componentes estables y experimentales;
* agregar demostraciones mínimas para cada componente;
* validar la compilación del paquete en Windows y Linux;
* corregir inconsistencias entre README y código fuente.

### Mediano plazo

* crear pruebas automatizadas;
* crear pipeline con `lazbuild`;
* crear releases versionadas;
* documentar dependencias externas;
* mejorar el tratamiento de errores;
* crear demostraciones reales usando LLM, voz, imagen y agentes.

### Largo plazo

* crear plantillas de proyectos;
* crear un asistente visual para configuración de IA;
* consolidar componentes OpenCV;
* consolidar componentes 3D;
* mejorar la integración con modelos locales;
* evolucionar agentes con control de seguridad;
* crear documentación completa para uso en producción.

---

## ¿Para quién es este proyecto?

Este proyecto es indicado para:

* desarrolladores Lazarus;
* desarrolladores Free Pascal;
* profesores y estudiantes;
* proyectos desktop con IA;
* automatización local;
* sistemas corporativos heredados;
* aplicaciones educativas;
* prototipos de IA;
* integración de IA con dispositivos;
* sistemas que necesitan IA sin migrar toda la base a Python o JavaScript.

---

## ¿Para quién todavía no es este proyecto?

En este momento, el proyecto aún no reemplaza:

* frameworks completos de machine learning;
* plataformas MLOps;
* pipelines corporativos de entrenamiento;
* servicios profesionales de despliegue de modelos;
* bibliotecas especializadas como PyTorch, TensorFlow, scikit-learn u OpenCV completo;
* infraestructura de IA a escala empresarial.

---

## Contribución

Las contribuciones son bienvenidas.

Áreas prioritarias para contribuir:

* corrección de bugs;
* demostraciones funcionales;
* documentación;
* pruebas automatizadas;
* compatibilidad Windows/Linux;
* íconos y screenshots;
* validación de componentes;
* mejoras en tratamiento de errores;
* integración con proveedores de IA;
* demos para cada pestaña de componentes de Lazarus.

---

## Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0**.

Consulte el archivo `LICENSE`.

---

## Aviso

Este proyecto utiliza o integra servicios externos de IA.
El uso de estos servicios puede implicar costos, límites de API, políticas propias del proveedor y transmisión de datos a terceros.

Antes de usarlo en producción:

* revise los términos del proveedor;
* proteja sus claves de API;
* no envíe datos sensibles sin autorización;
* valide seguridad, privacidad y conformidad;
* pruebe el comportamiento del componente en el ambiente real.

---

## Conclusión

**TCHATGPT** es una suite prometedora para llevar recursos de IA al ecosistema Lazarus / Free Pascal.

Su mayor valor está en ofrecer un puente práctico entre aplicaciones tradicionales y recursos modernos de IA, permitiendo que sistemas desktop, industriales, educativos y corporativos puedan incorporar LLMs, voz, imagen, grafos, automatización y modelos locales de forma componentizada.

El proyecto aún está en evolución, pero ya posee una base importante para convertirse en una referencia open source de componentes de IA para Lazarus.
