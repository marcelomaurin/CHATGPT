# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌐 **Idiomas / Languages**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 1. Objetivo do Projeto

O **TCHATGPT** (desenvolvido por [Maurinsoft](https://maurinsoft.com.br)) é uma suíte modular de componentes visuais e não visuais em **Object Pascal (Free Pascal / Lazarus)** para integração direta e nativa de Inteligência Artificial moderna, Visão Computacional, Processamento de Voz, Agentes Autônomos, Automação Industrial, Hardware e Gerenciamento de Projetos.

O foco central da suíte é permitir que desenvolvedores desktop e embarcados integrem capacidades avançadas de IA diretamente em código nativo, com:
1. **Controle Total e Baixa Latência:** Sem depender de servidores web intermediários ou frameworks pesados de frontend.
2. **Conectividade Híbrida:** Suporte tanto a LLMs em nuvem (OpenAI, Claude, Gemini, Ollama) quanto a inferência local e 100% offline via [`llama.cpp`](pacote/AI%20LlamaCpp/).
3. **Agentes Autônomos e Ferramentas:** Arquitetura de agentes capazes de executar código, interagir com bancos de dados, consultar arquivos, controlar robôs e comunicar-se entre si via protocolos [A2A](pacote/AI%20A2A/) e [MCP](pacote/AI%20MCP/).
4. **Interação com o Mundo Físico:** Dispositivos USB, portas seriais, sensores Kinect, joysticks, CLPs Modbus, brokers MQTT e emulação de firmware Marlin CNC/impressora 3D.

---

## 📦 2. Catálogo de Pacotes: Finalidade e Status

Abaixo é apresentada a **finalidade conceitual** de cada pacote (o que ele manipula, processa ou controla) e seu respectivo status de maturidade:

| Pacote Lazarus | Pasta Fonte | Finalidade (O que manipula / faz) | Status Atual |
|---|---|---|---|
| [**`openai_core.lpk`**](pacote/packages/openai_core.lpk) | [`pacote/AI/`](pacote/AI/) | Conecta a APIs de LLMs (OpenAI, Claude, Gemini, Ollama), gerencia tokens, prompts, modelos e fornece as classes base da suíte. | **Stable / Beta** |
| [**`openai_agent.lpk`**](pacote/packages/openai_agent.lpk) | [`pacote/AI Agent/`](pacote/AI%20Agent/) | Orquestra agentes autônomos, chamadas a ferramentas (tool calling), memória factual e guardrails de segurança. | **Stable / Beta**; pipelines compostos *Experimental* |
| [**`openai_a2a.lpk`**](pacote/packages/openai_a2a.lpk) | [`pacote/AI A2A/`](pacote/AI%20A2A/) | Padroniza a comunicação e troca de mensagens estruturadas diretamente entre diferentes agentes inteligentes em rede (Agent-to-Agent). | **Stable / Beta** |
| [**`openai_mcp.lpk`**](pacote/packages/openai_mcp.lpk) | [`pacote/AI MCP/`](pacote/AI%20MCP/) | Implementa o padrão aberto Model Context Protocol (Anthropic/OpenAI) como cliente e servidor JSON-RPC para exposição de ferramentas. | **Stable / Beta** |
| [**`openai_input.lpk`**](pacote/packages/openai_input.lpk) | [`pacote/AI Input/`](pacote/AI%20Input/) | Captura dados do mundo exterior: joysticks XInput/WinMM, assinaturas de voz, câmeras, sensores Kinect, portas seriais, sockets TCP/UDP, servidores web e documentos locais. | **Stable / Beta**; integração hardware_net_demo *Experimental* |
| [**`openai_output.lpk`**](pacote/packages/openai_output.lpk) | [`pacote/AI Output/`](pacote/AI%20Output/) | Gera documentos formatados Word (DOCX/OpenXML), planilhas Excel (XLSX), PDFs, texto puro, JSON estruturado e impressões térmicas de cupons POS. | **Stable / Beta** |
| [**`openai_vision.lpk`**](pacote/packages/openai_vision.lpk) | [`pacote/AI Vision/`](pacote/AI%20Vision/) | Processa fluxos de vídeo e imagens via OpenCV ou métodos nativos: detecta rostos, rastreia movimento e identifica poses humanas. | **Stable / Beta** |
| [**`openai_image.lpk`**](pacote/packages/openai_image.lpk) | [`pacote/AI Image/`](pacote/AI%20Image/) | Aplica filtros e manipulações gráficas em imagens diretamente em Pascal nativo, sem exigir DLLs ou bibliotecas externas. | **Stable / Beta** |
| [**`openai_voice.lpk`**](pacote/packages/openai_voice.lpk) | [`pacote/AI Voice/`](pacote/AI%20Voice/) | Processa áudio falado: converte texto em fala audível (TTS), transcreve voz em texto (STT) e aplica filtros acústicos. | **Stable / Beta** |
| [**`openai_project.lpk`**](pacote/packages/openai_project.lpk) | [`pacote/AI Project/`](pacote/AI%20Project/) | Renderiza interfaces visuais de gerenciamento: Diagramas de Gantt interativos, diagramas de rede PERT/CPM, quadros Kanban e histogramas de equipe. | **Stable / Beta** |
| [**`openai_project_core.lpk`**](pacote/packages/openai_project_core.lpk) | [`pacote/AI Project Core/`](pacote/AI%20Project%20Core/) | Executa cálculos matemáticos de cronograma: calcula caminho crítico (CPM), valida grafos de dependência sem ciclos e gerencia calendários úteis. | **Stable / Beta** |
| [**`openai_industrial.lpk`**](pacote/packages/openai_industrial.lpk) | [`pacote/AI Industrial/`](pacote/AI%20Industrial/) | Comunica com equipamentos industriais de fábrica via Modbus TCP/RTU, broker MQTT, pinmap Arduino e controle de braços robóticos. | **Stable / Beta** |
| [**`openai_marlin.lpk`**](pacote/packages/openai_marlin.lpk) | [`pacote/AI Simulation/AIMarlin/`](pacote/AI%20Simulation/AIMarlin/) | Emula o firmware de impressoras 3D e máquinas CNC Marlin, interpretando comandos G-Code e fornecendo portas seriais virtuais. | **Stable / Beta** |
| [**`openai_simulation.lpk`**](pacote/packages/openai_simulation.lpk) | [`pacote/AI Simulation/`](pacote/AI%20Simulation/) | Executa simulações computacionais 2D baseadas em regras celulares, filas de atendimento e deslocamento de robôs móveis. | **Stable / Beta** |
| [**`openai_graphic.lpk`**](pacote/packages/openai_graphic.lpk) | [`pacote/AI Graphic/`](pacote/AI%20Graphic/) | Manipula objetos gráficos tridimensionais (3D OpenGL), avatares virtuais com animação labial, esqueletos e cenas físicas. | **Stable / Beta** |
| [**`openai_hardware.lpk`**](pacote/packages/openai_hardware.lpk) | [`pacote/AI Hardware/`](pacote/AI%20Hardware/) | Coleta telemetria e métricas do sistema operacional e hardware físico: consumo de CPU, memória RAM, discos, GPUs e processos. | **Stable / Beta** |
| [**`openai_graph.lpk`**](pacote/packages/openai_graph.lpk) | [`pacote/AI Graph/`](pacote/AI%20Graph/) | Constrói, analisa e visualiza grafos de dependências lógicas, redes de conhecimento e mapas viários GeoJSON. | **Stable / Beta** |
| [**`openai_llamacpp.lpk`**](pacote/packages/openai_llamacpp.lpk) | [`pacote/AI LlamaCpp/`](pacote/AI%20LlamaCpp/) | Executa modelos de linguagem (LLMs) localmente no computador via biblioteca `llama.cpp` x64 em formato GGUF sem depender de internet. | **Stable / Beta** |
| [**`openai_ml.lpk`**](pacote/packages/openai_ml.lpk) | [`pacote/AI Math/`](pacote/AI%20Math/) | Executa algoritmos clássicos de aprendizado de máquina (redes neurais, perceptrons, mapas SOM) e operações matriciais (NUMPS) em Pascal puro. | **Stable / Beta** |
| [**`openai_python.lpk`**](pacote/packages/openai_python.lpk) | [`pacote/python/`](pacote/python/) | Integra runtimes externos Python para executar modelos de deep learning (YOLOv8, CNNs e LSTMs) acoplados ao Lazarus. | **Stable / Beta** |
| [**`openai_rag.lpk`**](pacote/packages/openai_rag.lpk) | [`pacote/AI RAG/`](pacote/AI%20RAG/) | Realiza busca semântica e recuperação aumentada (RAG), indexando acervos de documentos para alimentar o contexto das LLMs. | **Stable / Beta** |
| [**`openai_dbase.lpk`**](pacote/packages/openai_dbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Conecta a bancos de dados relacionais para salvar histórico de conversas, logs de auditoria e memória de longo prazo da IA. | **Stable / Beta** |
| [**`openai_aidbase.lpk`**](pacote/packages/openai_aidbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Extrai dicionários de dados e metadados de tabelas SQL para que modelos de IA compreendam a estrutura do banco. | **Stable / Beta** |
| [**`openai_files.lpk`**](pacote/packages/openai_files.lpk) | [`pacote/AI Files/`](pacote/AI%20Files/) | Faz varredura e indexação de diretórios de arquivos no disco, gerando conjuntos de dados estruturados para treinamento. | **Stable / Beta** |
| [**`openai_observability.lpk`**](pacote/packages/openai_observability.lpk) | [`pacote/AI Observability/`](pacote/AI%20Observability/) | Monitora o comportamento das IAs: rastreia chamadas (spans/traces), calcula latência, registra custos de tokens e alerta falhas. | **Stable / Beta** |
| [**`openai_evaluation.lpk`**](pacote/packages/openai_evaluation.lpk) | [`pacote/AI Evaluation/`](pacote/AI%20Evaluation/) | Avalia a acurácia de respostas geradas por IA utilizando juízes automatizados (LLM-as-a-judge) e relatórios de regressão. | **Stable / Beta** |
| [**`openai_integration.lpk`**](pacote/packages/openai_integration.lpk) | [`pacote/AI/`](pacote/AI/) | Conecta múltiplos componentes em pipelines de processamento unificados e executores encadeados. | **Stable / Beta** |
| [**`openai_webrtc.lpk`**](pacote/packages/openai_webrtc.lpk) | [`pacote/AI Communication/`](pacote/AI%20Communication/) | Estabelece canais de dados ponto-a-ponto de baixa latência (WebRTC DataChannel) usando a biblioteca libdatachannel. | **Stable / Beta** |

---

## 📂 3. Organização das Pastas do Repositório

Abaixo é apresentado o propósito de cada pasta do projeto, o que existe dentro dela e sua finalidade prática:

| Pasta | Propósito do Diretório | O que existe dentro | Para que serve (Finalidade Prática) |
|---|---|---|---|
| [**`pacote/AI/`**](pacote/AI/) | Base e infraestrutura central | Classes fundamentais ([`aibase.pas`](pacote/AI/aibase.pas), [`aiconfig.pas`](pacote/AI/aiconfig.pas)), clientes de LLMs ([`chatgpt.pas`](pacote/AI/chatgpt.pas), [`aiclaude.pas`](pacote/AI/aiclaude.pas), [`aigemini.pas`](pacote/AI/aigemini.pas), [`aiollama.pas`](pacote/AI/aiollama.pas)), tokenizers e roteadores. | Centraliza a comunicação HTTP/REST com provedores de IA e fornece a arquitetura base compartilhada por todos os componentes. |
| [**`pacote/AI Agent/`**](pacote/AI%20Agent/) | Orquestração de Agentes Autônomos | Módulos de agentes ([`aiagent.pas`](pacote/AI%20Agent/aiagent.pas)), memória determinística, mapas mentais, guardrails de segurança e automação de correção de fontes. | Permite criar agentes que resolvem objetivos em múltiplos passos, decidindo quando chamar funções Pascal ou consultar dados. |
| [**`pacote/AI A2A/`**](pacote/AI%20A2A/) | Protocolo Agent-to-Agent | Protocolo de comunicação e mensageria entre agentes de IA ([`aia2a_client.pas`](pacote/AI%20A2A/aia2a_client.pas)). | Permite que múltiplos agentes colaborem, deleguem tarefas e troquem contexto estruturado em rede. |
| [**`pacote/AI MCP/`**](pacote/AI%20MCP/) | Model Context Protocol | Implementação de cliente e servidor MCP sobre JSON-RPC ([`aimcp_client.pas`](pacote/AI%20MCP/aimcp_client.pas), [`aimcp_server.pas`](pacote/AI%20MCP/aimcp_server.pas)). | Permite que LLMs interajam diretamente com os dados e ferramentas do sistema através da especificação aberta MCP. |
| [**`pacote/AI Input/`**](pacote/AI%20Input/) | Dispositivos e Fontes de Entrada | Joysticks ([`aijoystick.pas`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), áudio ([`aispeakersignature.pas`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Kinect ([`aikinectsensor.pas`](pacote/AI%20Input/AIKinect/aikinectsensor.pas)), USB, Serial, Sockets, Servidor Web e leitores de documentos (PDF, DOCX, XLSX). | Captura e normaliza entradas do mundo exterior (sensores, rede, teclado/joystick, arquivos) para alimentar os fluxos de IA. |
| [**`pacote/AI Output/`**](pacote/AI%20Output/) | Geração de Saídas Estruturadas | Geradores de relatórios e documentos Word ([`aiworddocument.pas`](pacote/AI%20Output/aiworddocument.pas)), Excel ([`aixlsxwriter.pas`](pacote/AI%20Output/aixlsxwriter.pas)), impressoras térmicas POS ([`aiposprinter.pas`](pacote/AI%20Output/aiposprinter.pas)) e formatadores JSON. | Produz saídas físicas (impressoras fiscais/não fiscais) ou arquivos digitais formatados com as respostas da IA. |
| [**`pacote/AI Vision/`**](pacote/AI%20Vision/) | Visão Computacional | Conector OpenCV ([`aiopencv.pas`](pacote/AI%20Vision/aiopencv.pas)), rastreador facial ([`aifacetracker.pas`](pacote/AI%20Vision/aifacetracker.pas)), detector de movimento ([`aimotiontracker.pas`](pacote/AI%20Vision/aimotiontracker.pas)), estimativa de pose humana ([`aihumanposedetector.pas`](pacote/AI%20Vision/aihumanposedetector.pas)) e processamento de frames. | Analisa fluxos de vídeo de webcams e arquivos para reconhecimento visual e detecção de objetos/pessoas. |
| [**`pacote/AI Voice/`**](pacote/AI%20Voice/) | Voz, Reconhecimento e Síntese | Sintetizador de voz TTS ([`aivoicesynthesizer.pas`](pacote/AI%20Voice/aivoicesynthesizer.pas)), reconhecimento STT ([`aispeechrecognizer.pas`](pacote/AI%20Voice/aispeechrecognizer.pas)), assistente de voz e clones vocais. | Permite que a aplicação fale audivelmente com o usuário e entenda comandos falados via microfone. |
| [**`pacote/AI Project Core/`**](pacote/AI%20Project%20Core/) | Motor Matemático de Projetos | Escalonador CPM ([`aicpmscheduler.pas`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), grafo acíclico de tarefas ([`aitaskgraph.pas`](pacote/AI%20Project%20Core/aitaskgraph.pas)), calendário de trabalho ([`aiworkcalendar.pas`](pacote/AI%20Project%20Core/aiworkcalendar.pas)) e nivelamento de recursos. | Calcula cronogramas, folgas e caminho crítico de forma pura, servindo tanto para o Lazarus quanto para serviços de console/servidor. |
| [**`pacote/AI Project/`**](pacote/AI%20Project/) | Visualizações de Projetos LCL | Vistas visuais: Diagrama de Gantt ([`aiganttview.pas`](pacote/AI%20Project/aiganttview.pas)), Rede PERT ([`ainetworkview.pas`](pacote/AI%20Project/ainetworkview.pas)), Quadro Kanban ([`aiboardview.pas`](pacote/AI%20Project/aiboardview.pas)) e Histograma de Recursos ([`airesourceview.pas`](pacote/AI%20Project/airesourceview.pas)). | Renderiza controles gráficos de interface com o usuário para planejamento de tarefas e projetos. |
| [**`pacote/AI Industrial/`**](pacote/AI%20Industrial/) | Automação e Redes Industriais | Cliente Modbus TCP/RTU ([`aimodbus.pas`](pacote/AI%20Industrial/aimodbus.pas)), cliente MQTT ([`aimqtt.pas`](pacote/AI%20Industrial/aimqtt.pas)), controle de braço robótico ([`aiarm_robot.pas`](pacote/AI%20Industrial/aiarm_robot.pas)) e mapeamento de pinos Arduino. | Integra aplicações Lazarus ao chão de fábrica, lendo registradores de CLPs e controlando atuadores físicos. |
| [**`pacote/AI Simulation/`**](pacote/AI%20Simulation/) | Simulação 2D e Emulação Marlin | Motor de simulação celular em grade ([`aisimulationengine.pas`](pacote/AI%20Simulation/aisimulationengine.pas)), filas de atendimento, emulador de firmware Marlin G-code ([`aimarlinsimulator.pas`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas)). | Simula cenários logísticos e valida códigos de máquinas CNC antes da execução em maquinário real. |
| [**`pacote/AI Graphic/`**](pacote/AI%20Graphic/) | Gráficos 3D e Avatares | Visualizador 3D OpenGL ([`ai3dmodelviewer.pas`](pacote/AI%20Graphic/ai3dmodelviewer.pas)), avatares com sincronização labial ([`aiavatar_lipsync.pas`](pacote/AI%20Graphic/aiavatar_lipsync.pas)), esqueleto rig e cliente Tripo3D API. | Manipula e renderiza modelos 3D, personagens virtuais e animações na interface. |
| [**`pacote/AI Hardware/`**](pacote/AI%20Hardware/) | Telemetria de Hardware | Leitores de CPU ([`aicpu.pas`](pacote/AI%20Hardware/aicpu.pas)), Memória RAM ([`aimemory.pas`](pacote/AI%20Hardware/aimemory.pas)), Disco ([`aidisk.pas`](pacote/AI%20Hardware/aidisk.pas)), GPU ([`aigpu.pas`](pacote/AI%20Hardware/aigpu.pas)) e SO ([`aiso.pas`](pacote/AI%20Hardware/aiso.pas)). | Fornece métricas de uso de hardware para diagnóstico e balanceamento dinâmico de recursos. |
| [**`pacote/AI Graph/`**](pacote/AI%20Graph/) | Grafos e Rotas Geográficas | Grafo de dependências ([`aidependencygraph.pas`](pacote/AI%20Graph/aidependencygraph.pas)), visualizador de grafos ([`aigraphvisualizer.pas`](pacote/AI%20Graph/aigraphvisualizer.pas)), cálculo de rotas GeoJSON ([`airoutecalculator.pas`](pacote/AI%20Graph/airoutecalculator.pas)). | Constrói e desenha redes nodais, fluxos de dependência e trajetos em malhas viárias. |
| [**`pacote/AI LlamaCpp/`**](pacote/AI%20LlamaCpp/) | Inferência LLM Local | Conector de API e runtime para `llama.cpp` x64 ([`aillamacppruntime.pas`](pacote/AI%20LlamaCpp/aillamacppruntime.pas)), quantização e LoRA. | Permite que a aplicação execute modelos de IA de forma totalmente privada e offline no computador do usuário. |
| [**`pacote/AI Math/`**](pacote/AI%20Math/) | Matemática e Machine Learning | Biblioteca de álgebra linear NUMPS ([`numps.pas`](pacote/AI%20Math/numps.pas)), redes neurais perceptron e mapas auto-organizáveis (SOM). | Executa cálculos matemáticos de vetores/matrizes e treinamento de redes neurais sem bibliotecas externas. |
| [**`pacote/AI RAG/`**](pacote/AI%20RAG/) | Busca Semântica e RAG | Recuperação aumentada por geração ([`airag.pas`](pacote/AI%20RAG/airag.pas)), extratores de texto e indexação em lote. | Localiza passagens relevantes em grandes volumes de documentos para responder perguntas com precisão. |
| [**`pacote/AI DBase/`**](pacote/AI%20DBase/) | Bancos de Dados e Metadados | Dicionários de esquemas relacionais ([`aidbdictionary.pas`](pacote/AI%20DBase/aidbdictionary.pas)), persistência de histórico ZeosLib. | Mapeia tabelas de bancos de dados para que os agentes de IA possam formular consultas SQL com exatidão. |
| [**`pacote/AI Observability/`**](pacote/AI%20Observability/) | Observabilidade de IA | Coletor de traces e métricas ([`aitrace.pas`](pacote/AI%20Observability/aitrace.pas)). | Registra auditoria de chamadas, contagem de tokens gastos e tempo de processamento de cada requisição de IA. |
| [**`pacote/AI Evaluation/`**](pacote/AI%20Evaluation/) | Avaliação e Benchmarking | Juiz de avaliação com LLMs ([`aieval_judge.pas`](pacote/AI%20Evaluation/aieval_judge.pas)). | Testa e pontua automaticamente a assertividade das respostas de prompts contra critérios objetivos. |
| [**`pacote/packages/`**](pacote/packages/) | Pacotes de Instalação Lazarus | 28 arquivos `.lpk` configurados. | Permite instalar os componentes na paleta do Lazarus conforme a área de interesse do projeto. |
| [**`pacote/samples/`**](pacote/samples/) | Projetos de Demonstração | Mais de 95 exemplos completos com formulários e código-fonte ([`pacote/samples/README.md`](pacote/samples/README.md)). | Serve como guia prático e documentação funcional de uso para cada componente da suíte. |
| [**`tests/`**](tests/) | Testes Automatizados | Projetos console `.lpr` executáveis via Free Pascal. | Garante a integridade e regressão zero dos algoritmos matemáticos e componentes da biblioteca. |

---

## 🧩 4. Guia Detalhado de Componentes (O que faz e manipula cada um)

Abaixo está a relação funcional dos principais componentes da suíte, explicando **o que o componente manipula e qual o seu objetivo**:

### 📦 Pacote [`openai_core.lpk`](pacote/packages/openai_core.lpk)
* [`TAIBaseComponent`](pacote/AI/aibase.pas): Classe base ancestral. Manipula metadados de componentes, log de depuração e ciclo de vida comum.
* [`TCHATGPT`](pacote/AI/chatgpt.pas): Cliente OpenAI. Manipula requisições HTTP para os modelos GPT-4o, GPT-4o-mini e gerenciamento de chave de API.
* [`TAIClaude`](pacote/AI/aiclaude.pas): Cliente Anthropic. Manipula conexões diretas com a API dos modelos Claude 3.5 Sonnet e Haiku.
* [`TAIGemini`](pacote/AI/aigemini.pas): Cliente Google. Manipula chamadas REST aos modelos Gemini 1.5 Pro e Gemini Flash.
* [`TAIOllama`](pacote/AI/aiollama.pas): Cliente Ollama. Comunica com o serviço local Ollama na porta 11434 para rodar modelos locais open-source (Llama 3, Mistral, etc.).
* [`TAITokenizer`](pacote/AI/aitokenizer.pas): Manipula strings de texto para calcular a contagem exata de tokens BPE antes do envio, evitando estouro de cota.

### 📦 Pacote [`openai_input.lpk`](pacote/packages/openai_input.lpk)
* [`TAIJoystick`](pacote/AI%20Input/AIJoystick/aijoystick.pas): Manipula controles de videogame e gamepads USB. Lê botões analógicos e gatilhos de Xbox 360/One (XInput) e joysticks comuns (WinMM), normalizando os eixos de -1.0 a 1.0 com hotplug.
* [`TAISpeakerSession`](pacote/AI%20Input/AIAudio/aispeakersignature.pas): Manipula vetores de embeddings vocais. Compara a similaridade de cosseno de falas para autorizar ou recusar comandos conforme a voz do locutor cadastrado.
* [`TAIKinectSensor`](pacote/AI%20Input/AIKinect/aikinectsensor.pas): Controla o hardware do Microsoft Kinect v1, gerencia inicialização de câmeras e ajuste de ângulo do motor.
* [`TAIKinectSkeleton`](pacote/AI%20Input/AIKinect/aikinectskeleton.pas): Manipula a malha de esqueleto humano em tempo real, fornecendo as coordenadas 3D de 20 articulações corporais.
* [`TAISerial`](pacote/AI%20Input/AISerial/aiserial.pas): Manipula portas seriais físicas (COM1, /dev/ttyUSB0), enviando e recebendo fluxos de bytes com dispositivos embarcados.
* [`TAISocketTCP`](pacote/AI%20Input/AISockets/aisockets.pas) e [`TAISocketUDP`](pacote/AI%20Input/AISockets/aisockets.pas): Manipulam conexões de rede em baixo nível, permitindo criar servidores e clientes de soquete rápidos.
* [`TAIWebServer`](pacote/AI%20Input/AIWebServer/aiwebserver.pas): Manipula requisições HTTP de entrada em uma porta local, permitindo que a aplicação Lazarus funcione como um microsserviço REST.
* [`TAIDocumentReader`](pacote/AI%20Input/AIInput/aidocumentreader.pas): Manipula arquivos binários de documentos (PDF, DOCX e XLSX), extraindo o conteúdo textual bruto para análise.

### 📦 Pacote [`openai_project.lpk`](pacote/packages/openai_project.lpk) & [`openai_project_core.lpk`](pacote/packages/openai_project_core.lpk)
* [`TAICPMScheduler`](pacote/AI%20Project%20Core/aicpmscheduler.pas): Motor matemático do Método do Caminho Crítico (CPM). Manipula grafos de tarefas calculando datas limites, folgas e destacando as atividades críticas sem folga.
* [`TAITaskGraph`](pacote/AI%20Project%20Core/aitaskgraph.pas): Manipula o grafo acíclico de dependências (DAG), garantindo que não existam ciclos/loops inválidos entre tarefas predecessoras e sucessoras.
* [`TAIWorkCalendar`](pacote/AI%20Project%20Core/aiworkcalendar.pas): Manipula calendários de trabalho, convertendo horas e dias úteis e descontando feriados e finais de semana.
* [`TAIGanttView`](pacote/AI%20Project/aiganttview.pas): Manipula e renderiza o Diagrama de Gantt interativo na tela, com barras horizontais no tempo, conexões de dependência e rolagem.
* [`TAINetworkView`](pacote/AI%20Project/ainetworkview.pas): Renderiza na tela o diagrama de rede de atividades (PERT/CPM) em caixas conectadas.
* [`TAIBoardView`](pacote/AI%20Project/aiboardview.pas): Renderiza um quadro visual estilo Kanban, organizando cartões de tarefas em colunas conforme seu status de execução.
* [`TAIResourceView`](pacote/AI%20Project/airesourceview.pas): Renderiza um gráfico de histograma de alocação de equipe, alertando visualmente quando um colaborador tem mais tarefas do que sua capacidade em horas.

### 📦 Pacote [`openai_vision.lpk`](pacote/packages/openai_vision.lpk)
* [`TAIOpenCV`](pacote/AI%20Vision/aiopencv.pas): Manipula a inicialização e chamadas C-API da biblioteca OpenCV no Windows/Linux.
* [`TAIFaceTracker`](pacote/AI%20Vision/aifacetracker.pas): Analisa quadros de vídeo e retorna as coordenadas (retângulo) onde rostos estão presentes na imagem.
* [`TAIFaceRecognition`](pacote/AI%20Vision/aifacerecognition.pas): Manipula vetores de biometria facial, comparando rostos detectados com perfis conhecidos no banco de dados.
* [`TAIMotionTracker`](pacote/AI%20Vision/aimotiontracker.pas): Manipula vetores de fluxo óptico para rastrear a trajetória de pessoas ou objetos em movimento.
* [`TAIFrameDiff`](pacote/AI%20Vision/aiframediff.pas): Manipula buffers de imagem em código nativo, calculando a diferença absoluta entre quadros sucessivos para detecção de movimento sem dependências externas.
* [`TAIHumanPoseDetector`](pacote/AI%20Vision/aihumanposedetector.pas): Manipula coordenadas de marcos anatômicos corporais (ombros, braços, joelhos) para rastreamento de poses.

### 📦 Pacote [`openai_agent.lpk`](pacote/packages/openai_agent.lpk)
* [`TAIAgent`](pacote/AI%20Agent/aiagent.pas): Manipula o loop de raciocínio de agentes inteligentes (ReAct), coordenando o envio de mensagens, interpretação de respostas e execução de etapas.
* [`TAIAgentMemoryMap`](pacote/AI%20Agent/aiagent_memorymap.pas): Manipula a memória determinística do agente, guardando variáveis e fatos aprendidos durante a sessão.
* [`TAIAgentGuardrail`](pacote/AI%20Agent/aiagent_guardrail.pas): Manipula regras e filtros de segurança, inspecionando prompts e respostas para evitar vazamento de dados ou comportamentos indevidos.
* [`TAIToolCall`](pacote/AI%20Agent/aiagent_toolcall.pas): Manipula a ponte de execução de métodos Pascal registrados para permitir que a IA execute código da aplicação.

### 📦 Pacote [`openai_voice.lpk`](pacote/packages/openai_voice.lpk)
* [`TAIVoiceSynthesizer`](pacote/AI%20Voice/aivoicesynthesizer.pas): Manipula a geração de áudio falado a partir de textos digitados, usando SAPI (Windows), SpeechDispatcher (Linux) ou APIs de voz OpenAI.
* [`TAISpeechRecognizer`](pacote/AI%20Voice/aispeechrecognizer.pas): Captura áudio do microfone e manipula a conversão da fala para texto em tempo real via modelos Whisper.
* [`TAIVoiceClone`](pacote/AI%20Voice/aivoiceclone.pas): Manipula parâmetros acústicos para síntese com clonagem de timbre vocal a partir de pequenas amostras de áudio.

### 📦 Pacote [`openai_industrial.lpk`](pacote/packages/openai_industrial.lpk) & [`openai_marlin.lpk`](pacote/packages/openai_marlin.lpk)
* [`TAIModbus`](pacote/AI%20Industrial/aimodbus.pas): Manipula quadros de comunicação industrial Modbus (leitura e escrita de Coils, Discretes, Holding Registers e Input Registers) via rede Ethernet ou serial RS-485.
* [`TAIMQTT`](pacote/AI%20Industrial/aimqtt.pas): Manipula mensagens de telemetria IoT, publicando e assinando tópicos em brokers MQTT.
* [`TAIArmRobot`](pacote/AI%20Industrial/aiarm_robot.pas): Manipula cálculos de cinemática direta e inversa para controle de braços robóticos articulados de 3 a 6 eixos.
* [`TAIMarlinSimulator`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas): Emula o firmware Marlin de impressoras 3D/CNC, interpretando código G-code (G0, G1, G28, M104) e simulando a movimentação de eixos X/Y/Z/E.

### 📦 Pacote [`openai_output.lpk`](pacote/packages/openai_output.lpk)
* [`TAIWordDocument`](pacote/AI%20Output/aiworddocument.pas): Manipula e monta nativamente a árvore XML do formato OpenXML (`.docx`), criando relatórios Microsoft Word com estilos, tabelas e cabeçalhos.
* [`TAIXlsxWriter`](pacote/AI%20Output/aixlsxwriter.pas): Manipula e gera pastas de trabalho do Microsoft Excel (`.xlsx`) com células formatadas, números e fórmulas.
* [`TAIPosPrinter`](pacote/AI%20Output/aiposprinter.pas): Manipula comandos de impressão térmica ESC/POS para emissão de comprovantes e cupons em impressoras de bobina (Elgin, Epson, Bematech).

---

## 🧭 5. Como Navegar na Documentação e Exemplos

Para explorar a fundo cada subsistema:
1. Consulte o [**Guia Geral de Samples**](pacote/samples/README.md) para ver a lista de todos os 95+ exemplos práticos com fotos e explicações funcionais.
2. Acesse a pasta do módulo que deseja explorar (ex.: [**`pacote/AI Input/`**](pacote/AI%20Input/)) para entender os componentes contidos nele e suas unidades `.pas`.
3. Para cada sample, consulte o manual de instruções com as **Propriedades**, **Métodos** e **Eventos** detalhados em seu respectivo `README.md` (por exemplo: [Manual do Sample de Joystick](pacote/samples/AI%20Input/joystick_demo_README.md) e [Manual da Demonstração de Projetos](pacote/samples/AI%20Project/Demo_AI_Project/README.md)).

---

## 🛠️ 6. Requisitos e Instalação

- **Compilador:** [Free Pascal (FPC)](https://www.freepascal.org/) versão 3.2.2 ou superior.
- **IDE:** [Lazarus](https://www.lazarus-ide.org/) versão 3.0 ou superior (32-bit ou 64-bit).
- **Instalação dos Pacotes:**
  1. No Lazarus, acesse o menu `Package` -> `Open Package File (.lpk)...`.
  2. Navegue até a pasta [`pacote/packages/`](pacote/packages/).
  3. Comece abrindo e compilando o pacote base [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Clique em `Compile` e, se desejar os componentes na paleta da IDE, clique em `Use` -> `Install`.
  5. Instale os demais pacotes conforme a necessidade da sua aplicação.

---

## 📄 7. Licença

Este projeto é distribuído sob os termos da licença **GPL v3**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.