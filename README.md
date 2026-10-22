# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌐 **Idiomas / Languages**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 Objetivo do Projeto

O **TCHATGPT** (desenvolvido por [Maurinsoft](https://maurinsoft.com.br)) é uma suíte abrangente e modular de componentes visuais e não visuais em **Object Pascal (Free Pascal / Lazarus)** para integração de Inteligência Artificial moderna, Visão Computacional, Processamento de Voz, Agentes Autônomos, Automação Industrial e Hardware.

O foco central é permitir que desenvolvedores desktop e embarcados integrem capacidades de IA de ponta com controle total em código nativo, oferecendo:
- Suporte a LLMs em nuvem (OpenAI ChatGPT, Anthropic Claude, Google Gemini, Ollama) e inferência local offline ([llama.cpp](pacote/AI%20LlamaCpp/));
- Agentes autônomos com memória determinística, protocolos Agent-to-Agent ([A2A](pacote/AI%20A2A/)) e Model Context Protocol ([MCP](pacote/AI%20MCP/));
- Visão computacional nativa e OpenCV ([AI Vision](pacote/AI%20Vision/)), detecção de poses e captura por câmeras/sensores ([Kinect](pacote/AI%20Input/AIKinect/));
- Reconhecimento e síntese de voz, filtros sonoros e assinatura biométrica vocal ([AI Voice](pacote/AI%20Voice/) / [AI Audio](pacote/AI%20Input/AIAudio/));
- Conectividade industrial e robótica via Modbus, MQTT, PLC Bridge e emulador de firmware ([Marlin G-Code](pacote/AI%20Simulation/AIMarlin/));
- Gerenciamento de projetos, caminho crítico (CPM), grafos de dependência e cronogramas visuais em Gantt/Kanban ([AI Project](pacote/AI%20Project/)).

---

## 📂 Estrutura e Organização do Repositório

O repositório é estritamente organizado para facilitar navegação direta:

```text
CHATGPT/
├── docs/             # Documentações de arquitetura, pendências e especificações
├── pacote/           # Código-fonte principal da suíte Lazarus
│   ├── packages/     # Pacotes de instalação do Lazarus (.lpk)
│   ├── samples/      # Aplicações e projetos de demonstração
│   ├── AI */         # Pastas modulares com o código-fonte de cada subsistema
│   └── COMPONENT_STATUS.md # Matriz factual de status e validação
├── tests/            # Testes unitários automatizados em Free Pascal (.lpr)
└── tools/            # Scripts e utilitários auxiliares
```

- [**`pacote/`**](pacote/): Diretório raiz do código dos componentes Pascal.
- [**`pacote/packages/`**](pacote/packages/): Contém os 28 pacotes `.lpk` prontos para instalação no Lazarus.
- [**`pacote/samples/`**](pacote/samples/): Exemplos práticos organizados por categoria de uso e com manuais dedicados.
- [**`tests/`**](tests/): Suíte de testes unitários compiláveis via FPC.
- [**`docs/`**](docs/): Documentações complementares e planos de validação (ex: [docs/PENDENCIAS_ASSINATURA_VOCAL.md](docs/PENDENCIAS_ASSINATURA_VOCAL.md)).

---

## 📦 Catálogo Geral de Pacotes (`.lpk`)

Abaixo estão listados todos os 28 pacotes disponíveis em [`pacote/packages/`](pacote/packages/), com suas descrições e links diretos para seus códigos-fonte e diretórios:

| Pacote Lazarus | Pasta de Implementação | Propósito e Componentes Principais |
|---|---|---|
| [**`openai_core.lpk`**](pacote/packages/openai_core.lpk) | [`pacote/AI/`](pacote/AI/) | Base essencial da suíte: [`TAIBaseComponent`](pacote/AI/aibase.pas), roteamento e conectores universais de LLMs. |
| [**`openai_agent.lpk`**](pacote/packages/openai_agent.lpk) | [`pacote/AI Agent/`](pacote/AI%20Agent/) | Orquestração de agentes autônomos, memória determinística e guardrails. |
| [**`openai_a2a.lpk`**](pacote/packages/openai_a2a.lpk) | [`pacote/AI A2A/`](pacote/AI%20A2A/) | Protocolo de comunicação Agent-to-Agent para colaboração entre múltiplos agentes. |
| [**`openai_mcp.lpk`**](pacote/packages/openai_mcp.lpk) | [`pacote/AI MCP/`](pacote/AI%20MCP/) | Suporte completo a cliente e servidor Model Context Protocol (MCP) via JSON-RPC. |
| [**`openai_input.lpk`**](pacote/packages/openai_input.lpk) | [`pacote/AI Input/`](pacote/AI%20Input/) | Dispositivos de entrada: Joysticks ([`TAIJoystick`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), Áudio ([`TAISpeakerSession`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Câmeras, WebServers, Sockets e Kinect. |
| [**`openai_output.lpk`**](pacote/packages/openai_output.lpk) | [`pacote/AI Output/`](pacote/AI%20Output/) | Geração estruturada de documentos (PDF, DOCX, XLSX), impressão térmica POS e exportação JSON. |
| [**`openai_vision.lpk`**](pacote/packages/openai_vision.lpk) | [`pacote/AI Vision/`](pacote/AI%20Vision/) | Visão computacional com OpenCV: rastreamento de faces, detecção de movimento e processamento de frames. |
| [**`openai_voice.lpk`**](pacote/packages/openai_voice.lpk) | [`pacote/AI Voice/`](pacote/AI%20Voice/) | Síntese de voz (TTS), reconhecimento de fala (STT) e módulos de áudio. |
| [**`openai_project.lpk`**](pacote/packages/openai_project.lpk) | [`pacote/AI Project/`](pacote/AI%20Project/) | Visualizações de projetos: [`TAIGanttView`](pacote/AI%20Project/aiganttview.pas), [`TAINetworkView`](pacote/AI%20Project/ainetworkview.pas), [`TAIBoardView`](pacote/AI%20Project/aiboardview.pas) e [`TAIResourceView`](pacote/AI%20Project/airesourceview.pas). |
| [**`openai_project_core.lpk`**](pacote/packages/openai_project_core.lpk) | [`pacote/AI Project Core/`](pacote/AI%20Project%20Core/) | Núcleo de cálculo: Escalonamento CPM ([`TAICPMScheduler`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), grafos de tarefas ([`TAITaskGraph`](pacote/AI%20Project%20Core/aitaskgraph.pas)) e calendários ([`TAIWorkCalendar`](pacote/AI%20Project%20Core/aiworkcalendar.pas)). |
| [**`openai_industrial.lpk`**](pacote/packages/openai_industrial.lpk) | [`pacote/AI Industrial/`](pacote/AI%20Industrial/) | Protocolos industriais Modbus TCP/RTU, broker MQTT e pontes de CLP. |
| [**`openai_hardware.lpk`**](pacote/packages/openai_hardware.lpk) | [`pacote/AI Hardware/`](pacote/AI%20Hardware/) | Monitoramento e telemetria de CPU, Memória RAM, Discos, GPUs e Sistema Operacional. |
| [**`openai_graph.lpk`**](pacote/packages/openai_graph.lpk) | [`pacote/AI Graph/`](pacote/AI%20Graph/) | Grafos de conhecimento, dependências, rotas geográficas GeoJSON e visualizadores. |
| [**`openai_graphic.lpk`**](pacote/packages/openai_graphic.lpk) | [`pacote/AI Graphic/`](pacote/AI%20Graphic/) | Modelagem 3D OpenGL, esqueletos, avatares dinâmicos, física e integração Tripo3D API. |
| [**`openai_llamacpp.lpk`**](pacote/packages/openai_llamacpp.lpk) | [`pacote/AI LlamaCpp/`](pacote/AI%20LlamaCpp/) | Execução local e offline de modelos GGUF com llama.cpp x64. |
| [**`openai_ml.lpk`**](pacote/packages/openai_ml.lpk) | [`pacote/AI Math/`](pacote/AI%20Math/) | Redes Neurais multicamadas, mapas SOM, Perceptron e biblioteca de matrizes NUMPS em Pascal puro. |
| [**`openai_python.lpk`**](pacote/packages/openai_python.lpk) | [`pacote/python/`](pacote/python/) | Runtimes e conectores para scripts Python, YOLOv8, CNNs e LSTMs. |
| [**`openai_rag.lpk`**](pacote/packages/openai_rag.lpk) | [`pacote/AI RAG/`](pacote/AI%20RAG/) | Recuperação Aumentada por Geração (RAG), indexação de arquivos e busca híbrida. |
| [**`openai_simulation.lpk`**](pacote/packages/openai_simulation.lpk) | [`pacote/AI Simulation/`](pacote/AI%20Simulation/) | Simulação celular 2D, filas de atendimento, robótica de piso e logística. |
| [**`openai_marlin.lpk`**](pacote/packages/openai_marlin.lpk) | [`pacote/AI Simulation/AIMarlin/`](pacote/AI%20Simulation/AIMarlin/) | Emulador determinístico de impressora 3D/CNC Marlin, interpretador G-code e portas seriais virtuais. |
| [**`openai_dbase.lpk`**](pacote/packages/openai_dbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Conexões a bancos relacionais, persistência de memória de IA e logging ZeosLib. |
| [**`openai_aidbase.lpk`**](pacote/packages/openai_aidbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Dicionários de metadados e esquemas para modelos de IA. |
| [**`openai_files.lpk`**](pacote/packages/openai_files.lpk) | [`pacote/AI Files/`](pacote/AI%20Files/) | Varredor de árvore de arquivos, catalogador e gerador de datasets para treinamento. |
| [**`openai_image.lpk`**](pacote/packages/openai_image.lpk) | [`pacote/AI Image/`](pacote/AI%20Image/) | Filtros de imagem e manipulações visuais em Pascal puro, sem dependências externas. |
| [**`openai_observability.lpk`**](pacote/packages/openai_observability.lpk) | [`pacote/AI Observability/`](pacote/AI%20Observability/) | Spans, Traces, métricas de consumo de tokens e observabilidade com privacidade. |
| [**`openai_evaluation.lpk`**](pacote/packages/openai_evaluation.lpk) | [`pacote/AI Evaluation/`](pacote/AI%20Evaluation/) | Avaliação automatizada de prompts, LLM-as-a-judge e relatórios de regressão. |
| [**`openai_integration.lpk`**](pacote/packages/openai_integration.lpk) | [`pacote/AI/`](pacote/AI/) | Pipelines de alto nível e executores combinados. |
| [**`openai_webrtc.lpk`**](pacote/packages/openai_webrtc.lpk) | [`pacote/AI Communication/`](pacote/AI%20Communication/) | Conexões WebRTC PeerConnection e DataChannel usando libdatachannel. |

---

## 🧭 Como Navegar na Documentação e Exemplos

Para explorar a fundo cada subsistema:
1. Consulte o [**Guia Geral de Samples**](pacote/samples/README.md) para ver a lista de todos os 95+ exemplos práticos com fotos e explicações funcionais.
2. Acesse a pasta do módulo que deseja explorar (ex.: [**`pacote/AI Input/`**](pacote/AI%20Input/)) para entender os componentes contidos nele e suas unidades `.pas`.
3. Para cada sample, consulte o manual de instruções com as **Propriedades**, **Métodos** e **Eventos** detalhados em seu respectivo `README.md` (por exemplo: [Sample de Assinatura Vocal](pacote/samples/AI%20Audio/speaker_signature_demo/README.md)).

---

## 🛠️ Requisitos e Instalação

- **Compilador:** [Free Pascal (FPC)](https://www.freepascal.org/) versão 3.2.2 ou superior.
- **IDE:** [Lazarus](https://www.lazarus-ide.org/) versão 3.0 ou superior (32-bit ou 64-bit).
- **Instalação dos Pacotes:**
  1. No Lazarus, acesse o menu `Package` -> `Open Package File (.lpk)...`.
  2. Navegue até a pasta [`pacote/packages/`](pacote/packages/).
  3. Comece abrindo e compilando o pacote base [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Clique em `Compile` e, se desejar os componentes na paleta de componentes da IDE, clique em `Use` -> `Install`.
  5. Instale os demais pacotes conforme a necessidade do seu projeto.

---

## 📄 Licença

Este projeto é distribuído sob os termos da licença **GPL v3**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.