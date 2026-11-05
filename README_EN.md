# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌐 **Languages / Idiomas**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md) • [العربية](README_AR.md) • [中文](README_CH.md) • [Русский](README_RU.md) • [日本語](README_JP.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 1. Project Objective

**TCHATGPT** (developed by [Maurinsoft](https://maurinsoft.com.br)) is a comprehensive and modular component suite in **Object Pascal (Free Pascal / Lazarus)** for direct and native integration of modern Artificial Intelligence, Computer Vision, Voice Processing, Autonomous Agents, Industrial Automation, Hardware Telemetry, and Project Management.

The core focus of the suite is to enable desktop and embedded developers to integrate cutting-edge AI capabilities directly into native code with:
1. **Total Control and Low Latency:** Without relying on intermediate web servers or heavy frontend frameworks.
2. **Hybrid Connectivity:** Support for cloud LLMs (OpenAI, Claude, Gemini, Ollama) as well as 100% offline local inference via [`llama.cpp`](pacote/AI%20LlamaCpp/).
3. **Autonomous Agents and Tools:** Agent architecture capable of executing code, interacting with databases, querying files, controlling robots, and collaborating over [A2A](pacote/AI%20A2A/) and [MCP](pacote/AI%20MCP/) protocols.
4. **Physical World Interaction:** USB devices, serial ports, Kinect sensors, joysticks, Modbus PLCs, MQTT brokers, and Marlin CNC/3D printer firmware emulation.

---

## 📦 2. Package Catalog: Purpose and Status

Below is the **functional purpose** of each package (what it manipulates, processes, or controls) and its current maturity status:

| Lazarus Package | Source Folder | Purpose (What it manipulates / does) | Current Status |
|---|---|---|---|
| [**`openai_core.lpk`**](pacote/packages/openai_core.lpk) | [`pacote/AI/`](pacote/AI/) | Connects to LLM APIs (OpenAI, Claude, Gemini, Ollama), manages tokens, prompts, models, and provides base suite classes. | **Stable / Beta** |
| [**`openai_agent.lpk`**](pacote/packages/openai_agent.lpk) | [`pacote/AI Agent/`](pacote/AI%20Agent/) | Orchestrates autonomous agents, tool calling, factual memory, and safety guardrails. | **Stable / Beta**; composite pipelines *Experimental* |
| [**`openai_a2a.lpk`**](pacote/packages/openai_a2a.lpk) | [`pacote/AI A2A/`](pacote/AI%20A2A/) | Standardizes structured communication and message exchange directly between different intelligent network agents (Agent-to-Agent). | **Stable / Beta** |
| [**`openai_mcp.lpk`**](pacote/packages/openai_mcp.lpk) | [`pacote/AI MCP/`](pacote/AI%20MCP/) | Implements the open Model Context Protocol (Anthropic/OpenAI) as JSON-RPC client and server for tool exposure. | **Stable / Beta** |
| [**`openai_input.lpk`**](pacote/packages/openai_input.lpk) | [`pacote/AI Input/`](pacote/AI%20Input/) | Captures external data: XInput/WinMM joysticks, voice signatures, cameras, Kinect sensors, serial ports, TCP/UDP sockets, web servers, and local documents. | **Stable / Beta**; hardware_net_demo *Experimental* |
| [**`openai_output.lpk`**](pacote/packages/openai_output.lpk) | [`pacote/AI Output/`](pacote/AI%20Output/) | Generates formatted Word (DOCX/OpenXML), Excel spreadsheets (XLSX), PDFs, plain text, structured JSON, and POS thermal receipts. | **Stable / Beta** |
| [**`openai_vision.lpk`**](pacote/packages/openai_vision.lpk) | [`pacote/AI Vision/`](pacote/AI%20Vision/) | Processes video streams and images via OpenCV or native methods: detects faces, tracks motion, and identifies human poses. | **Stable / Beta** |
| [**`openai_image.lpk`**](pacote/packages/openai_image.lpk) | [`pacote/AI Image/`](pacote/AI%20Image/) | Applies image filters and visual manipulations directly in native Pascal without external DLLs or libraries. | **Stable / Beta** |
| [**`openai_voice.lpk`**](pacote/packages/openai_voice.lpk) | [`pacote/AI Voice/`](pacote/AI%20Voice/) | Processes spoken audio: converts text to speech (TTS), transcribes speech to text (STT), and applies acoustic filters. | **Stable / Beta** |
| [**`openai_project.lpk`**](pacote/packages/openai_project.lpk) | [`pacote/AI Project/`](pacote/AI%20Project/) | Renders visual project management interfaces: interactive Gantt charts, PERT/CPM network diagrams, Kanban boards, and team resource histograms. | **Stable / Beta** |
| [**`openai_project_core.lpk`**](pacote/packages/openai_project_core.lpk) | [`pacote/AI Project Core/`](pacote/AI%20Project%20Core/) | Performs mathematical scheduling: calculates critical path method (CPM), validates acyclic dependency graphs, and manages work calendars. | **Stable / Beta** |
| [**`openai_industrial.lpk`**](pacote/packages/openai_industrial.lpk) | [`pacote/AI Industrial/`](pacote/AI%20Industrial/) | Communicates with industrial plant equipment via Modbus TCP/RTU, MQTT brokers, Arduino pinmaps, and robotic arm controllers. | **Stable / Beta** |
| [**`openai_marlin.lpk`**](pacote/packages/openai_marlin.lpk) | [`pacote/AI Simulation/AIMarlin/`](pacote/AI%20Simulation/AIMarlin/) | Emulates Marlin 3D printer and CNC router firmware, parsing G-Code commands and providing virtual serial ports. | **Stable / Beta** |
| [**`openai_simulation.lpk`**](pacote/packages/openai_simulation.lpk) | [`pacote/AI Simulation/`](pacote/AI%20Simulation/) | Executes 2D simulations based on cellular automata rules, service queues, and autonomous mobile robot pathfinding. | **Stable / Beta** |
| [**`openai_graphic.lpk`**](pacote/packages/openai_graphic.lpk) | [`pacote/AI Graphic/`](pacote/AI%20Graphic/) | Manipulates 3D OpenGL graphics, virtual avatars with lip-sync animations, skeletal rigs, and physical environments. | **Stable / Beta** |
| [**`openai_hardware.lpk`**](pacote/packages/openai_hardware.lpk) | [`pacote/AI Hardware/`](pacote/AI%20Hardware/) | Collects OS and physical hardware telemetry: CPU, RAM, disk, GPU usage, and active system processes. | **Stable / Beta** |
| [**`openai_graph.lpk`**](pacote/packages/openai_graph.lpk) | [`pacote/AI Graph/`](pacote/AI%20Graph/) | Builds, analyzes, and visualizes logical dependency graphs, knowledge networks, and GeoJSON route networks. | **Stable / Beta** |
| [**`openai_llamacpp.lpk`**](pacote/packages/openai_llamacpp.lpk) | [`pacote/AI LlamaCpp/`](pacote/AI%20LlamaCpp/) | Runs GGUF LLMs locally and privately using the `llama.cpp` x64 runtime without internet access. | **Stable / Beta** |
| [**`openai_ml.lpk`**](pacote/packages/openai_ml.lpk) | [`pacote/AI Math/`](pacote/AI%20Math/) | Executes classic machine learning algorithms (neural networks, perceptrons, SOM maps) and matrix operations (NUMPS) in pure Pascal. | **Stable / Beta** |
| [**`openai_python.lpk`**](pacote/packages/openai_python.lpk) | [`pacote/python/`](pacote/python/) | Integrates external Python runtimes to execute deep learning models (YOLOv8, CNNs, LSTMs) connected to Lazarus. | **Stable / Beta** |
| [**`openai_rag.lpk`**](pacote/packages/openai_rag.lpk) | [`pacote/AI RAG/`](pacote/AI%20RAG/) | Performs semantic search and retrieval-augmented generation (RAG), indexing document stores to feed LLM context. | **Stable / Beta** |
| [**`openai_dbase.lpk`**](pacote/packages/openai_dbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Connects to relational databases to persist chat history, audit logs, and long-term AI memory using ZeosLib. | **Stable / Beta** |
| [**`openai_aidbase.lpk`**](pacote/packages/openai_aidbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Extracts schema metadata and data dictionaries from SQL tables for precise LLM querying. | **Stable / Beta** |
| [**`openai_files.lpk`**](pacote/packages/openai_files.lpk) | [`pacote/AI Files/`](pacote/AI%20Files/) | Scans and indexes disk directory trees, creating structured datasets for AI training and document retrieval. | **Stable / Beta** |
| [**`openai_observability.lpk`**](pacote/packages/openai_observability.lpk) | [`pacote/AI Observability/`](pacote/AI%20Observability/) | Monitors AI operations: tracks spans/traces, measures latency, records token consumption, and detects anomalies. | **Stable / Beta** |
| [**`openai_evaluation.lpk`**](pacote/packages/openai_evaluation.lpk) | [`pacote/AI Evaluation/`](pacote/AI%20Evaluation/) | Evaluates prompt accuracy and model outputs using automated LLM-as-a-judge evaluators and regression reports. | **Stable / Beta** |
| [**`openai_integration.lpk`**](pacote/packages/openai_integration.lpk) | [`pacote/AI/`](pacote/AI/) | Connects multiple components into unified processing pipelines and chained executors. | **Stable / Beta** |
| [**`openai_webrtc.lpk`**](pacote/packages/openai_webrtc.lpk) | [`pacote/AI Communication/`](pacote/AI%20Communication/) | Establishes low-latency peer-to-peer data channels (WebRTC DataChannel) using libdatachannel. | **Stable / Beta** |

---

## 📂 3. Repository Directory Structure

Below is the purpose of each directory in the repository, its contents, and practical utility:

| Directory | Directory Purpose | What is inside | Practical Utility (Why use it) |
|---|---|---|---|
| [**`pacote/AI/`**](pacote/AI/) | Core suite infrastructure | Base classes ([`aibase.pas`](pacote/AI/aibase.pas), [`aiconfig.pas`](pacote/AI/aiconfig.pas)), LLM clients ([`chatgpt.pas`](pacote/AI/chatgpt.pas), [`aiclaude.pas`](pacote/AI/aiclaude.pas), [`aigemini.pas`](pacote/AI/aigemini.pas), [`aiollama.pas`](pacote/AI/aiollama.pas)), tokenizers, and routers. | Centralizes HTTP/REST communication with AI providers and offers the foundational architecture shared across all components. |
| [**`pacote/AI Agent/`**](pacote/AI%20Agent/) | Autonomous Agent Orchestration | Agent modules ([`aiagent.pas`](pacote/AI%20Agent/aiagent.pas)), deterministic memory, mind maps, safety guardrails, and source code self-healing. | Enables multi-step reasoning agents that decide when to call Pascal routines or query databases. |
| [**`pacote/AI A2A/`**](pacote/AI%20A2A/) | Agent-to-Agent Protocol | Communication protocol and messaging for AI agents ([`aia2a_client.pas`](pacote/AI%20A2A/aia2a_client.pas)). | Allows multiple distributed agents to collaborate, delegate sub-tasks, and share structured context over networks. |
| [**`pacote/AI MCP/`**](pacote/AI%20MCP/) | Model Context Protocol | JSON-RPC client and server implementation of MCP ([`aimcp_client.pas`](pacote/AI%20MCP/aimcp_client.pas), [`aimcp_server.pas`](pacote/AI%20MCP/aimcp_server.pas)). | Allows LLMs to directly interact with application tools and data through the open standard MCP specification. |
| [**`pacote/AI Input/`**](pacote/AI%20Input/) | Input Devices and Captures | Joysticks ([`aijoystick.pas`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), audio ([`aispeakersignature.pas`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Kinect ([`aikinectsensor.pas`](pacote/AI%20Input/AIKinect/aikinectsensor.pas)), USB, Serial, Sockets, Web Server, and document readers (PDF, DOCX, XLSX). | Captures and normalizes data from the physical world (sensors, network, gamepads, files) to feed AI pipelines. |
| [**`pacote/AI Output/`**](pacote/AI%20Output/) | Structured Output Generation | Word document generators ([`aiworddocument.pas`](pacote/AI%20Output/aiworddocument.pas)), Excel writers ([`aixlsxwriter.pas`](pacote/AI%20Output/aixlsxwriter.pas)), POS thermal receipt printers ([`aiposprinter.pas`](pacote/AI%20Output/aiposprinter.pas)), and JSON formatters. | Produces physical outputs (receipts) or formatted digital files from AI responses. |
| [**`pacote/AI Vision/`**](pacote/AI%20Vision/) | Computer Vision | OpenCV connector ([`aiopencv.pas`](pacote/AI%20Vision/aiopencv.pas)), face tracker ([`aifacetracker.pas`](pacote/AI%20Vision/aifacetracker.pas)), motion tracker ([`aimotiontracker.pas`](pacote/AI%20Vision/aimotiontracker.pas)), pose estimator ([`aihumanposedetector.pas`](pacote/AI%20Vision/aihumanposedetector.pas)), and frame processors. | Analyzes video streams from webcams and files for real-time visual recognition and object/human tracking. |
| [**`pacote/AI Voice/`**](pacote/AI%20Voice/) | Voice Recognition & Synthesis | TTS voice synthesizer ([`aivoicesynthesizer.pas`](pacote/AI%20Voice/aivoicesynthesizer.pas)), STT speech recognizer ([`aispeechrecognizer.pas`](pacote/AI%20Voice/aispeechrecognizer.pas)), voice assistants, and voice cloning. | Allows applications to speak audibly and understand spoken commands via microphone input. |
| [**`pacote/AI Project Core/`**](pacote/AI%20Project%20Core/) | Mathematical Project Core | CPM scheduler ([`aicpmscheduler.pas`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), acyclic task graph ([`aitaskgraph.pas`](pacote/AI%20Project%20Core/aitaskgraph.pas)), work calendar ([`aiworkcalendar.pas`](pacote/AI%20Project%20Core/aiworkcalendar.pas)), and resource load leveling. | Computes schedules, floats, and critical paths purely in memory, supporting both GUI apps and headless daemons/services. |
| [**`pacote/AI Project/`**](pacote/AI%20Project/) | Visual Project Views (LCL) | Interactive views: Gantt chart ([`aiganttview.pas`](pacote/AI%20Project/aiganttview.pas)), PERT network ([`ainetworkview.pas`](pacote/AI%20Project/ainetworkview.pas)), Kanban board ([`aiboardview.pas`](pacote/AI%20Project/aiboardview.pas)), and Resource histogram ([`airesourceview.pas`](pacote/AI%20Project/airesourceview.pas)). | Renders interactive GUI controls on screen for visual planning and scheduling. |
| [**`pacote/AI Industrial/`**](pacote/AI%20Industrial/) | Industrial Networks & Automation | Modbus TCP/RTU client ([`aimodbus.pas`](pacote/AI%20Industrial/aimodbus.pas)), MQTT client ([`aimqtt.pas`](pacote/AI%20Industrial/aimqtt.pas)), robot arm kinematics ([`aiarm_robot.pas`](pacote/AI%20Industrial/aiarm_robot.pas)), and Arduino pinmap. | Integrates Lazarus applications to factory floors, reading PLC registers and controlling physical actuators. |
| [**`pacote/AI Simulation/`**](pacote/AI%20Simulation/) | 2D Simulation & Marlin Emulation | Grid-based cellular simulation engine ([`aisimulationengine.pas`](pacote/AI%20Simulation/aisimulationengine.pas)), service queues, and Marlin G-code emulator ([`aimarlinsimulator.pas`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas)). | Simulates logistics scenarios and validates CNC machine toolpaths before physical execution. |
| [**`pacote/AI Graphic/`**](pacote/AI%20Graphic/) | 3D Graphics & Avatars | 3D OpenGL viewer ([`ai3dmodelviewer.pas`](pacote/AI%20Graphic/ai3dmodelviewer.pas)), lip-synced avatars ([`aiavatar_lipsync.pas`](pacote/AI%20Graphic/aiavatar_lipsync.pas)), skeletal rigs, and Tripo3D API client. | Manipulates and renders 3D models, virtual characters, and animations on user interfaces. |
| [**`pacote/AI Hardware/`**](pacote/AI%20Hardware/) | Hardware Telemetry | Telemetry readers for CPU ([`aicpu.pas`](pacote/AI%20Hardware/aicpu.pas)), RAM ([`aimemory.pas`](pacote/AI%20Hardware/aimemory.pas)), Disks ([`aidisk.pas`](pacote/AI%20Hardware/aidisk.pas)), GPUs ([`aigpu.pas`](pacote/AI%20Hardware/aigpu.pas)), and OS ([`aiso.pas`](pacote/AI%20Hardware/aiso.pas)). | Provides real-time hardware consumption metrics for diagnostics and dynamic workload balancing. |
| [**`pacote/AI Graph/`**](pacote/AI%20Graph/) | Graphs & Geographic Routes | Dependency graph ([`aidependencygraph.pas`](pacote/AI%20Graph/aidependencygraph.pas)), graph visualizer ([`aigraphvisualizer.pas`](pacote/AI%20Graph/aigraphvisualizer.pas)), and GeoJSON route calculator ([`airoutecalculator.pas`](pacote/AI%20Graph/airoutecalculator.pas)). | Constructs and renders node networks, logical flows, and route profiles on road networks. |
| [**`pacote/AI LlamaCpp/`**](pacote/AI%20LlamaCpp/) | Local LLM Inference | API connector and x64 runtime for `llama.cpp` ([`aillamacppruntime.pas`](pacote/AI%20LlamaCpp/aillamacppruntime.pas)), quantization, and LoRA. | Allows applications to run AI models 100% privately and offline on the user machine without cloud dependencies. |
| [**`pacote/AI Math/`**](pacote/AI%20Math/) | Mathematics & Machine Learning | NUMPS linear algebra library ([`numps.pas`](pacote/AI%20Math/numps.pas)), perceptron networks, and Self-Organizing Maps (SOM). | Performs matrix calculations and lightweight neural network training directly in native Pascal. |
| [**`pacote/AI RAG/`**](pacote/AI%20RAG/) | Semantic Search & RAG | Retrieval-augmented generation ([`airag.pas`](pacote/AI%20RAG/airag.pas)), text extractors, and batch indexing. | Finds relevant passages across large document corpora to ground LLM answers with precision. |
| [**`pacote/AI DBase/`**](pacote/AI%20DBase/) | Databases & Metadata | Relational schema dictionaries ([`aidbdictionary.pas`](pacote/AI%20DBase/aidbdictionary.pas)), ZeosLib persistent chat history. | Maps database tables so AI agents can formulate accurate and safe SQL queries. |
| [**`pacote/AI Observability/`**](pacote/AI%20Observability/) | AI Observability | Trace collector and metric recorder ([`aitrace.pas`](pacote/AI%20Observability/aitrace.pas)). | Audits model calls, token expenses, response latencies, and system warnings. |
| [**`pacote/AI Evaluation/`**](pacote/AI%20Evaluation/) | Evaluation & Benchmarking | LLM-based evaluation judge ([`aieval_judge.pas`](pacote/AI%20Evaluation/aieval_judge.pas)). | Automatically tests and scores prompt answer quality against objective rubrics. |
| [**`pacote/packages/`**](pacote/packages/) | Lazarus Package Files | 28 configured `.lpk` files. | Allows selective component palette installation into the Lazarus IDE. |
| [**`pacote/samples/`**](pacote/samples/) | Demo Applications | Over 95 complete sample projects with forms and source code ([`pacote/samples/README.md`](pacote/samples/README.md)). | Provides ready-to-run practical guides and user manuals for each suite component. |
| [**`tests/`**](tests/) | Automated Test Suite | Executable console `.lpr` projects tested with Free Pascal. | Guarantees zero regression and continuous verification of algorithms and components. |

---

## 🧭 4. How to Navigate Documentation and Samples

To explore each module in depth:
1. Review the [**Samples Master Guide**](pacote/samples/README.md) to inspect all 95+ practical examples with descriptions and UI screenshots.
2. Visit the module folder you wish to explore (e.g., [**`pacote/AI Input/`**](pacote/AI%20Input/)) to inspect its source units and components.
3. For specific samples, consult their user manual detailing **Properties**, **Methods**, and **Events** in their dedicated `README.md` (e.g., [Joystick Sample Manual](pacote/samples/AI%20Input/joystick_demo_README.md) and [AI Project Demo Manual](pacote/samples/AI%20Project/Demo_AI_Project/README.md)).

---

## 🛠️ 5. Requirements and Installation

- **Compiler:** [Free Pascal (FPC)](https://www.freepascal.org/) version 3.2.2 or higher.
- **IDE:** [Lazarus](https://www.lazarus-ide.org/) version 3.0 or higher (32-bit or 64-bit).
- **Package Installation:**
  1. In Lazarus, go to menu `Package` -> `Open Package File (.lpk)...`.
  2. Navigate to [`pacote/packages/`](pacote/packages/).
  3. Open and compile the core package [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Click `Compile` and, if you want components on the IDE palette, click `Use` -> `Install`.
  5. Install other packages as required by your application.

---

## 📄 6. License

This project is distributed under the terms of the **GPL v3** license. See the [LICENSE](LICENSE) file for details.