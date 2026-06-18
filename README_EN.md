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

## Overview

**TCHATGPT** is an open source suite of visual and non-visual components for **Lazarus / Free Pascal**, designed to make it easier to integrate Artificial Intelligence resources into desktop, industrial, educational, and business applications.

The project provides components for connecting to LLM providers, local models, data processing, machine learning, voice synthesis, image processing, agents, graphs, input and output channels, as well as experimental components for computer vision and 3D graphical resources.

> This project should be understood as an **AI integration component suite for Lazarus applications**, not as a complete AI platform intended to replace specialized training frameworks, MLOps platforms, or large-scale model deployment infrastructure.

---

## Project Goal

The main goal is to allow Lazarus / Free Pascal developers to add AI capabilities to their systems in a simple, reusable, and component-based way.

The suite aims to support scenarios such as:

* generative AI assistants;
* LLM API integration;
* local model integration through compatible servers;
* dataset generation and analysis;
* simple text classification;
* agent-based automation;
* text-to-speech synthesis;
* basic image processing;
* digital sound filters;
* integration with devices, sensors, and external channels;
* AI prototyping in Lazarus applications.

---

## Current Project Status

The project is under active development and contains components at different maturity levels.

### More consolidated components

* `TCHATGPT`
* `TAIBaseComponent`
* `TNeuralNetwork`
* `TTokenList`
* `TAICodeAssistant`
* `TAIDatasetGenerator`
* `TAIVoiceSynthesizer`
* image filters
* sound filters
* graph and dataset components

### Experimental or evolving components

* Python integration;
* CNN, YOLO, LSTM, and SOM components;
* autonomous agent components;
* advanced input and output components;
* OpenCV components;
* 3D visualization;
* Tripo3D integration;
* industrial, camera, audio, browser, MQTT, Modbus, and CCTV components.

---

## Component Palette Tabs

The package installs components into the Lazarus component palette, organized by functional area.

---

## AI Core

Main components for generative AI, machine learning, and project support.

### `TCHATGPT`

Main connector for generative AI providers.

It allows applications to send prompts, configure providers, select models, and receive structured responses.

Planned or supported providers:

* OpenAI;
* Google Gemini;
* Anthropic Claude;
* OpenRouter;
* Cerebras;
* local server compatible with `/v1/chat/completions`;
* Ollama or similar local services.

### `TNeuralNetwork`

Simple multilayer neural network implemented in Pascal.

It can be used to:

* create local networks;
* configure inputs, hidden layers, and outputs;
* train by epochs;
* calculate loss;
* save and load models.

### `TTokenList`

Utility component for basic text tokenization.

It can be used for:

* classification;
* text analysis;
* preprocessing;
* decision graphs;
* dataset preparation.

### `TAICodeAssistant`

LLM-based code assistant.

It can be used to:

* review code;
* suggest improvements;
* generate comments;
* explain code blocks;
* assist with tests;
* convert or document routines.

### `TAIDatasetGenerator`

Dataset generator for training, fine-tuning, or local classification workflows.

It supports or is intended to support structures such as:

* CSV;
* JSON;
* JSONL;
* input and output matrices for local training.

### `TAIModelRegistry`

Central registry for models, providers, endpoints, and parameters.

It helps organize:

* model name;
* provider;
* endpoint;
* temperature;
* token limit;
* default parameters.

### `TAIWizardConfig`

Configuration assistant for new AI projects.

It can be used to prepare projects such as:

* chatbot;
* classifier;
* pipeline;
* agent;
* technical assistant.

---

## AI Sound Filters

Components for digital signal processing and sound filtering.

### `TLowPassFilter`

First-order IIR low-pass filter.

Used to smooth fast variations and reduce high-frequency noise.

### `THighPassFilter`

First-order IIR high-pass filter.

Used to remove low-frequency components, offset, or DC noise.

### `TAverageFilter`

Moving average filter.

Used for simple signal smoothing.

### `TFDMMultiplexer`

Frequency Division Multiplexing component.

Allows simulation of channels in different frequency bands.

### `TTDMMultiplexer`

Time Division Multiplexing component.

Allows channels to be interleaved by time slots.

### `TCDMMultiplexer`

CDM/CDMA multiplexer.

Uses orthogonal codes to separate signals.

### `TOFDMMultiplexer`

OFDM multiplexer using FFT/IFFT.

Useful for telecommunications studies and simulations.

---

## AI Image

Components for basic image processing.

### `TGrayscaleFilter`

Converts images to grayscale.

### `TNegativeFilter`

Applies color inversion.

### `TBrightnessContrastFilter`

Adjusts brightness and contrast.

### `TBinarizationFilter`

Applies thresholding to generate black-and-white images.

### `TBlurFilter`

Applies smoothing through convolution.

### `TSharpenFilter`

Enhances sharpness using a convolution kernel.

### `TSobelFilter`

Detects edges using the Sobel operator.

### `TErosionDilationFilter`

Performs morphological erosion and dilation operations.

---

## AI Schedule

Components for organization, persistence, and task dependency management.

### `TJSONGroupStorage`

Component for grouped JSON data storage.

It can be used to:

* save settings;
* persist parameters;
* store texts;
* organize data by groups.

### `TIASchedule`

Task manager with dependency control.

It allows modeling:

* parent tasks;
* child tasks;
* dependencies;
* readiness state;
* simple execution control.

---

## AI Voice

Components for text-to-speech synthesis.

### `TAIVoiceSynthesizer`

Text-to-Speech component.

On Windows, it may use SAPI.
On Linux, it may use eSpeak/eSpeak-NG.

Main features:

* speak text;
* adjust volume;
* adjust speech rate;
* list available voices;
* asynchronous execution;
* integration with desktop applications.

---

## AI Agent

Components for intelligent agents and structured decision-making.

### `TAIAgent`

Agent orchestrator component.

It allows applications to send instructions to an LLM, interpret structured responses, and coordinate actions.

### `TAIAgentOptions`

Stores context, questions, guidelines, and analysis rules.

### `TAIAgentAction`

Defines actions allowed for the agent.

It allows configuration of:

* available actions;
* expected parameters;
* execution callbacks.

### `TAIAgentResource`

Represents external resources that can be triggered by the agent.

Examples:

* files;
* email;
* HTTP;
* SMS;
* WhatsApp;
* TCP/UDP;
* Web APIs.

### `TAIAgentOutput`

Output layer that connects agent decisions to real system resources.

---

## AI Graph

Components for data structuring, graphs, and datasets.

### `TAIGraphMap`

Weighted graph for token-based classification and analysis.

It can be used for:

* text classification;
* concept grouping;
* term relationships;
* simple topic analysis.

### `TAITrainingExporter`

Training data exporter.

Planned or supported formats:

* CSV;
* JSON;
* JSONL;
* ARFF;
* numeric vectors.

### `TAIDatasetAnalyzer`

Dataset quality analyzer.

It can detect:

* empty categories;
* duplicate examples;
* class imbalance;
* very short texts;
* very long texts.

### `TAITrainingReport`

Technical training report generator.

It can record:

* accuracy;
* error;
* loss;
* token count;
* average confidence;
* dataset statistics.

### `TAIGraphVisualizer`

Graph exporter and visualizer.

Planned or supported formats:

* DOT / GraphViz;
* Mermaid;
* visualization JSON.

---

## AI Input

Components for data input and integration with external sources.

This tab concentrates components focused on information capture, communication, and integration with devices or systems.

Planned or evolving components:

* camera;
* audio;
* web server;
* sockets;
* serial communication;
* POS printer;
* CCTV/IP;
* Modbus;
* MQTT;
* email;
* messaging;
* operating system capture;
* embedded browser;
* industrial inputs.

> Some components in this tab may require external libraries, drivers, operating system permissions, or additional services.

---

## AI Output

Components for data output, document generation, and integration with external destinations.

Planned or evolving resources:

* document generation;
* response export;
* structured output;
* external channel integration;
* response automation.

---

## AI Vision

Components for computer vision.

Planned or evolving components:

* OpenCV;
* camera capture;
* frame processing;
* face tracking;
* motion tracking;
* image classification;
* object detection.

> This area should be treated as experimental until components have complete demonstrations, documented dependencies, and integration tests.

---

## AI Graphic

Graphical and 3D components related to AI, simulation, and visualization.

Planned or evolving components:

* 2D/3D scene;
* training environment;
* physics simulator;
* virtual sensors;
* reward function;
* 3D model visualization;
* skeleton rig;
* avatar controller;
* pose library;
* animation sequence;
* 3D model generation integration.

### `TAI3DModelViewer`

3D model viewer.

Goal:

* load 3D models;
* display meshes;
* rotate;
* zoom in;
* zoom out;
* switch between solid, wireframe, and point modes.

### `TAITripo3DClient`

Client for integration with an external 3D model generation service.

Goal:

* generate model from text;
* generate model from image;
* generate model from multiple images;
* download the resulting 3D model.

> Integration with external services must be validated according to the official API documentation of the provider being used.

---

## Package Installation in Lazarus

The suite is organized in modular packages:

| Package | Purpose | Installation | Status |
|---|---|---|---|
| `openai_core.lpk` | Core components, LLM connection, prompt builder, model registry, project and pipeline | First | **Essential** |
| `openai_python.lpk` | Python connectors and external models runtimes (TPythonConnector, TYoloDetect, TFaceDetection, TCNNClassifier, TLSTMPredictor, TAIPythonRuntime) | Optional | **Optional** |
| `openai_ml.lpk` | Simple machine learning and mathematics in Pascal (Neural Network, Perceptron, SOM) | Optional | **Optional** |
| `openai_graph.lpk` | Graphs, token-based classification, export and reports | Optional | **Optional** |
| `openai_files.lpk` | Directory scanning, Disk Tree Scanner and physical file management | Optional | **Optional** |
| `openai_output.lpk` | Outputs, reports, PDF, TXT, Excel/Word compatible files generation | Optional | **Optional** |
| `openai_input.lpk` | Inputs, unified capture (TAICaptureSource), email, sockets, serial, MQTT, Modbus, Profinet | Optional | **Optional** |
| `openai_vision.lpk` | OpenCV, camera native backends (VFW/V4L2), face and motion tracker, pose detector (MediaPipe 64-bit) | Optional | **Optional** |
| `openai_image.lpk` | Fast 100% native pixel filters (Grayscale, Negative, Blur, Sobel, etc.) | Optional | **Optional** |
| `openai_voice.lpk` | Voice, audio, text-to-speech synthesis and sound filters | Optional | **Optional** |
| `openai_simulation.lpk` | 2D grid simulations, rule engine, behavior and movement | Optional | **Optional** |
| `openai_industrial.lpk` | Modbus, MQTT and industrial PLC bridges | Experimental | **Experimental** |
| `openai_graphic.lpk` | 3D rendering, STL/OBJ, avatar and Tripo3D integration | Experimental | **Experimental** |
| `openai_agent.lpk` | Autonomous agents, strict safety rules and action executors | Experimental | **Experimental** |

> **Legacy Package Note**: The old monolithic `openai.lpk` package is fully deprecated and removed. Please use the modular packages listed above.

### Recommended Installation Order

1. Open Lazarus.
2. Go to **Package > Open Package File (.lpk)**.
3. Select the file `pacote/packages/openai_core.lpk` and click **Compile**, then **Use > Install**.
4. If you want to use Python scripts, open and install `pacote/packages/openai_python.lpk`.
5. Install any other optional or experimental package as needed by your project.
6. Rebuild the IDE when prompted.

```text
1.  pacote/packages/openai_core.lpk       (Essential)
2.  pacote/packages/openai_python.lpk     (Optional - Python Connectors)
3.  pacote/packages/openai_ml.lpk         (Optional)
4.  pacote/packages/openai_graph.lpk      (Optional)
5.  pacote/packages/openai_files.lpk      (Optional)
6.  pacote/packages/openai_output.lpk     (Optional)
7.  pacote/packages/openai_input.lpk      (Optional)
8.  pacote/packages/openai_vision.lpk     (Optional)
9.  pacote/packages/openai_image.lpk      (Optional)
10. pacote/packages/openai_voice.lpk      (Optional)
11. pacote/packages/openai_simulation.lpk (Optional)
12. pacote/packages/openai_industrial.lpk (Experimental)
13. pacote/packages/openai_graphic.lpk    (Experimental)
14. pacote/packages/openai_agent.lpk       (Experimental)
```

---

## LLM Providers

| Provider                    | Enum             | Type                      |
| --------------------------- | ---------------- | ------------------------- |
| OpenAI                      | `AIP_OPENAI`     | External API              |
| OpenRouter                  | `AIP_OPENROUTER` | External API / aggregator |
| Cerebras                    | `AIP_CEREBRAS`   | External API              |
| Google Gemini               | `AIP_GEMINI`     | External API              |
| Anthropic Claude            | `AIP_CLAUDE`     | External API              |
| Local / Ollama / compatible | `AIP_LOCAL`      | Local server              |

> Model names, limits, prices, and availability may change depending on each provider. Always check the official documentation of the service being used.

---

## Requirements

### Main environment

* Lazarus 3.x or higher;
* compatible Free Pascal version;
* Windows or Linux;
* `openai_core.lpk` package;
* internet connection for external providers;
* local model server configured when offline models are used.

### Windows

For HTTPS communication, compatible OpenSSL DLLs may be required according to the application architecture.

Check the folder `pacote/lib/`.

It is recommended to copy the required DLLs to the same folder as the final executable.

### Linux

Depending on the components used, additional packages may be required, such as:

* OpenSSL;
* eSpeak/eSpeak-NG;
* libpython;
* camera or audio libraries;
* specific libraries for computer vision.

Requirements may vary depending on the component being used.

---

## Screenshots

> The images below demonstrate features already tested or currently in development.
> New components may not yet have complete visual demonstrations.

### CNN Demo

![CNN Demo](screenshots/cnn_demo.jpg)

Image classification demonstration.

### Math Input / Output Demo

![Math Input Output Demo](screenshots/math_input_output_demo.jpg)

Mathematical components demonstration.

### Python Connector Demo

![Python Demo](screenshots/python_demo.jpg)

Python integration demonstration.

### SOM Demo

![SOM Demo](screenshots/som_demo.jpg)

Self-organizing map demonstration.

### Sound Filters Demo

![Sound Filters](screenshots/sound_filters.jpg)

Sound filter demonstration.

### Voice Synthesizer Demo

![Voice Synthesizer](screenshots/voicesynthesizer.jpg)

Text-to-speech synthesis demonstration.

### Disk Tree AI Dataset Demo

![Disk Tree AI Dataset Demo](screenshots/disk_tree_ai_dataset_demo.jpg)

Asynchronous filesystem scanning and AI dataset inventory preparation.

---

## Known Limitations

The project is still under development and contains components at different stability levels.

Current expected limitations:

* some components may still be experimental;
* not all components have complete demonstrations;
* external integrations depend on third-party APIs;
* computer vision components may require external libraries;
* Python components depend on compatible version and architecture;
* each component should be validated before production use;
* automated tests and continuous integration still need to be expanded.

---

## Roadmap

### Short term

* review component documentation;
* standardize component palette tab names in English;
* separate stable and experimental components;
* add minimal demonstrations for each component;
* validate package compilation on Windows and Linux;
* fix inconsistencies between README and source code.

### Medium term

* create automated tests;
* create a pipeline with `lazbuild`;
* create versioned releases;
* document external dependencies;
* improve error handling;
* create real demonstrations using LLM, voice, image, and agents.

### Long term

* create project templates;
* create a visual assistant for AI configuration;
* consolidate OpenCV components;
* consolidate 3D components;
* improve local model integration;
* evolve agents with safety control;
* create complete documentation for production use.

---

## Who is this project for?

This project is suitable for:

* Lazarus developers;
* Free Pascal developers;
* teachers and students;
* desktop AI projects;
* local automation;
* legacy business systems;
* educational applications;
* AI prototypes;
* AI integration with devices;
* systems that need AI without migrating the entire codebase to Python or JavaScript.

---

## Who is this project not yet for?

At this stage, the project does not replace:

* complete machine learning frameworks;
* MLOps platforms;
* enterprise training pipelines;
* professional model deployment services;
* specialized libraries such as PyTorch, TensorFlow, scikit-learn, or full OpenCV;
* enterprise-scale AI infrastructure.

---

## Contributing

Contributions are welcome.

Priority contribution areas:

* bug fixes;
* functional demonstrations;
* documentation;
* automated tests;
* Windows/Linux compatibility;
* icons and screenshots;
* component validation;
* error handling improvements;
* integration with AI providers;
* demos for each Lazarus component tab.

---

## License

This project is licensed under the **GNU General Public License v3.0**.

See the `LICENSE` file.

---

## Notice

This project uses or integrates external AI services.
Using these services may involve costs, API limits, provider-specific policies, and data transmission to third parties.

Before using it in production:

* review the provider terms;
* protect your API keys;
* do not send sensitive data without authorization;
* validate security, privacy, and compliance;
* test the component behavior in the real environment.

---

## Conclusion

**TCHATGPT** is a promising suite for bringing AI resources into the Lazarus / Free Pascal ecosystem.

Its greatest value is offering a practical bridge between traditional applications and modern AI resources, allowing desktop, industrial, educational, and business systems to incorporate LLMs, voice, image, graphs, automation, and local models in a component-based way.

The project is still evolving, but it already has an important foundation to become an open source reference for AI components in Lazarus.
