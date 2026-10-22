# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌐 **Idiomas / Languages**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 1. Objetivo do Projeto

O **TCHATGPT** (desenvolvido por [Maurinsoft](https://maurinsoft.com.br)) é uma suíte abrangente e modular de componentes visuais e não visuais em **Object Pascal (Free Pascal / Lazarus)** para integração de Inteligência Artificial moderna, Visão Computacional, Processamento de Voz, Agentes Autônomos, Automação Industrial, Hardware e Gerenciamento de Projetos.

O foco central da suíte é permitir que desenvolvedores desktop e embarcados integrem capacidades avançadas de IA diretamente em código nativo, com:
1. **Controle Total e Baixa Latência:** Sem depender de servidores web intermediários ou frameworks pesados de frontend.
2. **Conectividade Híbrida:** Suporte tanto a LLMs em nuvem (OpenAI, Claude, Gemini, Ollama) quanto a inferência local e 100% offline via [`llama.cpp`](pacote/AI%20LlamaCpp/).
3. **Agentes Autônomos e Ferramentas:** Arquitetura de agentes capazes de executar código, interagir com bancos de dados, consultar arquivos, controlar robôs e comunicar-se entre si via protocolos [A2A](pacote/AI%20A2A/) e [MCP](pacote/AI%20MCP/).
4. **Interação com o Mundo Físico:** Dispositivos USB, portas seriais, sensores Kinect, joysticks, CLPs Modbus, brokers MQTT e emulação de firmware Marlin CNC/impressora 3D.

---

## 📂 2. Organização das Pastas do Projeto

Abaixo é apresentado o propósito de cada pasta do repositório, o que existe dentro dela e para que serve:

| Pasta | Propósito do Diretório | O que existe dentro | Para que serve |
|---|---|---|---|
| [**`pacote/AI/`**](pacote/AI/) | Base e infraestrutura central | Classes fundamentais ([`aibase.pas`](pacote/AI/aibase.pas), [`aiconfig.pas`](pacote/AI/aiconfig.pas)), clientes de LLMs ([`chatgpt.pas`](pacote/AI/chatgpt.pas), [`aiclaude.pas`](pacote/AI/aiclaude.pas), [`aigemini.pas`](pacote/AI/aigemini.pas), [`aiollama.pas`](pacote/AI/aiollama.pas)), tokenizers e roteadores. | Fornece os blocos de construção base para todos os demais componentes e comunicação com APIs de IA. |
| [**`pacote/AI Agent/`**](pacote/AI%20Agent/) | Orquestração de Agentes Autônomos | Módulos de agentes ([`aiagent.pas`](pacote/AI%20Agent/aiagent.pas)), memória determinística, mapas mentais, guardrails de segurança e automação de correção de fontes. | Permite criar agentes de IA capazes de planejar, chamar ferramentas (tool calling) e resolver problemas complexos com memória de curto e longo prazo. |
| [**`pacote/AI A2A/`**](pacote/AI%20A2A/) | Protocolo Agent-to-Agent | Protocolo de comunicação e mensageria entre agentes de IA ([`aia2a_client.pas`](pacote/AI%20A2A/aia2a_client.pas)). | Permite que múltiplos agentes colaborem, deleguem tarefas e troquem contexto estruturado em rede. |
| [**`pacote/AI MCP/`**](pacote/AI%20MCP/) | Model Context Protocol | Implementação de cliente e servidor MCP sobre JSON-RPC ([`aimcp_client.pas`](pacote/AI%20MCP/aimcp_client.pas), [`aimcp_server.pas`](pacote/AI%20MCP/aimcp_server.pas)). | Expõe ferramentas e recursos do Lazarus para LLMs compatíveis com o padrão aberto Model Context Protocol (Anthropic/OpenAI). |
| [**`pacote/AI Input/`**](pacote/AI%20Input/) | Dispositivos e Fontes de Entrada | Joysticks ([`aijoystick.pas`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), áudio ([`aispeakersignature.pas`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Kinect ([`aikinectsensor.pas`](pacote/AI%20Input/AIKinect/aikinectsensor.pas)), USB, Serial, Sockets, Servidor Web e leitores de documentos (PDF, DOCX, XLSX). | Captura dados do ambiente, sensores e arquivos para alimentar os motores de IA. |
| [**`pacote/AI Output/`**](pacote/AI%20Output/) | Geração de Saídas Estruturadas | Geradores de relatórios e documentos Word ([`aiworddocument.pas`](pacote/AI%20Output/aiworddocument.pas)), Excel ([`aixlsxwriter.pas`](pacote/AI%20Output/aixlsxwriter.pas)), impressoras térmicas POS ([`aiposprinter.pas`](pacote/AI%20Output/aiposprinter.pas)) e formatadores JSON. | Produz saídas físicas ou digitais a partir dos resultados gerados pelas IAs e agentes. |
| [**`pacote/AI Vision/`**](pacote/AI%20Vision/) | Visão Computacional | Conector OpenCV ([`aiopencv.pas`](pacote/AI%20Vision/aiopencv.pas)), rastreador facial ([`aifacetracker.pas`](pacote/AI%20Vision/aifacetracker.pas)), detector de movimento ([`aimotiontracker.pas`](pacote/AI%20Vision/aimotiontracker.pas)), estimativa de pose humana ([`aihumanposedetector.pas`](pacote/AI%20Vision/aihumanposedetector.pas)) e processamento de frames. | Analisa fluxos de vídeo de webcams e arquivos para reconhecimento visual e detecção de objetos/pessoas. |
| [**`pacote/AI Voice/`**](pacote/AI%20Voice/) | Voz, Reconhecimento e Síntese | Sintetizador de voz TTS ([`aivoicesynthesizer.pas`](pacote/AI%20Voice/aivoicesynthesizer.pas)), reconhecimento STT ([`aispeechrecognizer.pas`](pacote/AI%20Voice/aispeechrecognizer.pas)), assistente de voz e clones vocais. | Permite que a aplicação fale e escute comandos de voz nativamente com baixa latência. |
| [**`pacote/AI Project Core/`**](pacote/AI%20Project%20Core/) | Motor Matemático de Projetos | Escalonador CPM ([`aicpmscheduler.pas`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), grafo acíclico de tarefas ([`aitaskgraph.pas`](pacote/AI%20Project%20Core/aitaskgraph.pas)), calendário de trabalho ([`aiworkcalendar.pas`](pacote/AI%20Project%20Core/aiworkcalendar.pas)) e nivelamento de recursos. | Calcula o caminho crítico, datas limites, folgas e dependências de projetos sem depender de interface gráfica. |
| [**`pacote/AI Project/`**](pacote/AI%20Project/) | Visualizações de Projetos LCL | Vistas visuais: Diagrama de Gantt ([`aiganttview.pas`](pacote/AI%20Project/aiganttview.pas)), Rede PERT ([`ainetworkview.pas`](pacote/AI%20Project/ainetworkview.pas)), Quadro Kanban ([`aiboardview.pas`](pacote/AI%20Project/aiboardview.pas)) e Histograma de Recursos ([`airesourceview.pas`](pacote/AI%20Project/airesourceview.pas)). | Renderiza na tela diagramas interativos de cronogramas e projetos com desenho direto em Canvas. |
| [**`pacote/AI Industrial/`**](pacote/AI%20Industrial/) | Automação e Redes Industriais | Cliente Modbus TCP/RTU ([`aimodbus.pas`](pacote/AI%20Industrial/aimodbus.pas)), cliente MQTT ([`aimqtt.pas`](pacote/AI%20Industrial/aimqtt.pas)), controle de braço robótico ([`aiarm_robot.pas`](pacote/AI%20Industrial/aiarm_robot.pas)) e mapeamento de pinos Arduino. | Conecta a IA a CLPs de chão de fábrica, sensores IoT e manipuladores robóticos. |
| [**`pacote/AI Simulation/`**](pacote/AI%20Simulation/) | Simulação 2D e Emulação Marlin | Motor de simulação celular em grade ([`aisimulationengine.pas`](pacote/AI%20Simulation/aisimulationengine.pas)), filas de atendimento, emulador de firmware Marlin G-code ([`aimarlinsimulator.pas`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas)). | Simula comportamentos logísticos, robôs móveis em armazém e validação de comandos CNC antes do envio ao maquinário real. |
| [**`pacote/AI Hardware/`**](pacote/AI%20Hardware/) | Telemetria de Hardware | Leitores de CPU ([`aicpu.pas`](pacote/AI%20Hardware/aicpu.pas)), Memória RAM ([`aimemory.pas`](pacote/AI%20Hardware/aimemory.pas)), Disco ([`aidisk.pas`](pacote/AI%20Hardware/aidisk.pas)), GPU ([`aigpu.pas`](pacote/AI%20Hardware/aigpu.pas)) e SO ([`aiso.pas`](pacote/AI%20Hardware/aiso.pas)). | Monitora o consumo de recursos e saúde do sistema para autoajuste de cargas de IA. |
| [**`pacote/AI Graph/`**](pacote/AI%20Graph/) | Grafos e Rotas Geográficas | Grafo de dependências ([`aidependencygraph.pas`](pacote/AI%20Graph/aidependencygraph.pas)), visualizador de grafos ([`aigraphvisualizer.pas`](pacote/AI%20Graph/aigraphvisualizer.pas)), cálculo de rotas GeoJSON ([`airoutecalculator.pas`](pacote/AI%20Graph/airoutecalculator.pas)). | Processa redes de relacionamentos, caminhos ótimos e dados cartográficos. |
| [**`pacote/AI Graphic/`**](pacote/AI%20Graphic/) | Gráficos 3D e Avatares | Visualizador 3D OpenGL ([`ai3dmodelviewer.pas`](pacote/AI%20Graphic/ai3dmodelviewer.pas)), avatares com sincronização labial ([`aiavatar_lipsync.pas`](pacote/AI%20Graphic/aiavatar_lipsync.pas)), esqueleto rig e cliente Tripo3D API. | Renderiza personagens 3D virtuais que interagem com o usuário em tempo real sincronizados com voz e IA. |
| [**`pacote/AI LlamaCpp/`**](pacote/AI%20LlamaCpp/) | Inferência LLM Local | Conector de API e runtime para `llama.cpp` x64 ([`aillamacppruntime.pas`](pacote/AI%20LlamaCpp/aillamacppruntime.pas)), quantização e LoRA. | Permite carregar e rodar modelos GGUF locais no computador do usuário sem enviar dados para a nuvem. |
| [**`pacote/AI Math/`**](pacote/AI%20Math/) | Matemática e Machine Learning | Biblioteca de álgebra linear NUMPS ([`numps.pas`](pacote/AI%20Math/numps.pas)), redes neurais perceptron e mapas auto-organizáveis (SOM). | Executa operações matriciais e treinamentos leves de redes neurais em Pascal puro. |
| [**`pacote/AI RAG/`**](pacote/AI%20RAG/) | Busca Semântica e RAG | Recuperação aumentada por geração ([`airag.pas`](pacote/AI%20RAG/airag.pas)), extratores de texto e indexação em lote. | Encontra trechos relevantes em bases documentais e injeta no contexto dos modelos de linguagem. |
| [**`pacote/AI DBase/`**](pacote/AI%20DBase/) | Bancos de Dados e Metadados | Dicionários de esquemas relacionais ([`aidbdictionary.pas`](pacote/AI%20DBase/aidbdictionary.pas)), persistência de histórico ZeosLib. | Mapeia estruturas de tabelas SQL para que os agentes de IA possam consultar dados de forma segura. |
| [**`pacote/AI Observability/`**](pacote/AI%20Observability/) | Observabilidade de IA | Coletor de traces e métricas ([`aitrace.pas`](pacote/AI%20Observability/aitrace.pas)). | Rastreia chamadas a LLMs, tempo de resposta, custos de tokens e alertas de erro. |
| [**`pacote/AI Evaluation/`**](pacote/AI%20Evaluation/) | Avaliação e Benchmarking | Juiz de avaliação com LLMs ([`aieval_judge.pas`](pacote/AI%20Evaluation/aieval_judge.pas)). | Mede a qualidade e assertividade de respostas de prompts de forma reproduzível. |
| [**`pacote/packages/`**](pacote/packages/) | Pacotes de Instalação Lazarus | 28 arquivos `.lpk` configurados. | Permite instalar seletivamente as paletas de componentes na IDE Lazarus. |
| [**`pacote/samples/`**](pacote/samples/) | Projetos de Demonstração | Mais de 95 exemplos completos com formulários e código-fonte ([`pacote/samples/README.md`](pacote/samples/README.md)). | Serve como guia prático e documentação funcional de uso para cada componente da suíte. |
| [**`tests/`**](tests/) | Testes Automatizados | Projetos console `.lpr` executáveis via Free Pascal. | Garante que os algoritmos (CPM, grafos, biometria vocal, normalização de joysticks) continuem funcionando. |

---

## 🧩 3. Guia Detalhado de Componentes: Para que serve cada um?

Abaixo está a relação funcional dos principais componentes da suíte, agrupados por pacote, explicando o **propósito exato de cada componente**:

### 📦 Pacote [`openai_core.lpk`](pacote/packages/openai_core.lpk)
* [`TAIBaseComponent`](pacote/AI/aibase.pas): Classe ancestral de todos os componentes da suíte. Fornece propriedades comuns de categoria, versionamento, logging e gerenciamento de estado.
* [`TCHATGPT`](pacote/AI/chatgpt.pas): Conector cliente de alto nível para a API da OpenAI (GPT-4o, GPT-4o-mini, embeddings e chat completions).
* [`TAIClaude`](pacote/AI/aiclaude.pas): Conector cliente nativo para os modelos da família Anthropic Claude (Claude 3.5 Sonnet, Haiku).
* [`TAIGemini`](pacote/AI/aigemini.pas): Conector cliente para os modelos Google Gemini (Gemini 1.5 Pro, Flash).
* [`TAIOllama`](pacote/AI/aiollama.pas): Conector para servidores locais Ollama rodando localmente na porta 11434.
* [`TAITokenizer`](pacote/AI/aitokenizer.pas): Componente para contagem e estimativa de tokens de texto antes do envio às APIs.

### 📦 Pacote [`openai_input.lpk`](pacote/packages/openai_input.lpk)
* [`TAIJoystick`](pacote/AI%20Input/AIJoystick/aijoystick.pas): Lê gamepads e controles USB. Gerencia prioridade XInput (Xbox 360/One) e WinMM genérico com hotplug e normalização de eixos (-1.0 a 1.0).
* [`TAISpeakerSession`](pacote/AI%20Input/AIAudio/aispeakersignature.pas): Gerencia a identificação biométrica de locutor, validando se uma nova fala pertence à mesma pessoa através da similaridade de cosseno de embeddings de voz.
* [`TAIKinectSensor`](pacote/AI%20Input/AIKinect/aikinectsensor.pas): Inicializa o sensor Microsoft Kinect v1 e gerencia os fluxos de cor, profundidade infravermelha e motor de inclinação.
* [`TAIKinectSkeleton`](pacote/AI%20Input/AIKinect/aikinectskeleton.pas): Rastreia em tempo real as coordenadas tridimensionais (X, Y, Z) das 20 articulações corporais humanas capturadas pelo Kinect.
* [`TAISerial`](pacote/AI%20Input/AISerial/aiserial.pas): Comunicação serial com placas Arduino, balanças e sensores industriais via RS-232/USB-Serial.
* [`TAISocketTCP`](pacote/AI%20Input/AISockets/aisockets.pas) e [`TAISocketUDP`](pacote/AI%20Input/AISockets/aisockets.pas): Clientes e servidores de socket para troca rápida de pacotes de rede brutos.
* [`TAIWebServer`](pacote/AI%20Input/AIWebServer/aiwebserver.pas): Servidor HTTP embutido que permite que a aplicação Lazarus receba requisições REST e webhooks externos.
* [`TAIDocumentReader`](pacote/AI%20Input/AIInput/aidocumentreader.pas): Extrai texto puro de arquivos PDF, DOCX e planilhas Excel para alimentar prompts e RAG.

### 📦 Pacote [`openai_project.lpk`](pacote/packages/openai_project.lpk) & [`openai_project_core.lpk`](pacote/packages/openai_project_core.lpk)
* [`TAICPMScheduler`](pacote/AI%20Project%20Core/aicpmscheduler.pas): Motor matemático do Método do Caminho Crítico (CPM). Calcula datas mais cedo, mais tarde, folgas totais e livres e identifica o caminho crítico do projeto.
* [`TAITaskGraph`](pacote/AI%20Project%20Core/aitaskgraph.pas): Grafo direcionado acíclico (DAG) que valida consistência de dependências entre tarefas e detecta loops/ciclos inválidos.
* [`TAIWorkCalendar`](pacote/AI%20Project%20Core/aiworkcalendar.pas): Calendário de trabalho que desconta finais de semana e feriados nacionais nos cálculos de prazos e durações.
* [`TAIGanttView`](pacote/AI%20Project/aiganttview.pas): Componente visual de diagrama de Gantt interativo com barras temporais, zoom em dias/semanas/meses e setas de dependência.
* [`TAINetworkView`](pacote/AI%20Project/ainetworkview.pas): Componente visual de diagrama de rede PERT/CPM (Activity-on-Node) com caixas de atividades e conectores.
* [`TAIBoardView`](pacote/AI%20Project/aiboardview.pas): Painel visual estilo Kanban com colunas de status (A Fazer, Em Execução, Concluído) e cartões de tarefas.
* [`TAIResourceView`](pacote/AI%20Project/airesourceview.pas): Histograma e planejador de equipe que alerta sobre superalocação de horas de colaboradores no período.

### 📦 Pacote [`openai_vision.lpk`](pacote/packages/openai_vision.lpk)
* [`TAIOpenCV`](pacote/AI%20Vision/aiopencv.pas): Camada de integração com as DLLs/bibliotecas do OpenCV.
* [`TAIFaceTracker`](pacote/AI%20Vision/aifacetracker.pas): Detecta e desenha a bounding box de rostos presentes na captura de vídeo.
* [`TAIFaceRecognition`](pacote/AI%20Vision/aifacerecognition.pas): Compara perfis de faces capturados contra uma base de pessoas cadastradas para controle de acesso biométrico.
* [`TAIMotionTracker`](pacote/AI%20Vision/aimotiontracker.pas): Rastreia objetos em movimento através da análise temporal de fluxo óptico.
* [`TAIFrameDiff`](pacote/AI%20Vision/aiframediff.pas): Subtrai frames consecutivos em código nativo sem dependências externas para detectar intrusões e movimento.
* [`TAIHumanPoseDetector`](pacote/AI%20Vision/aihumanposedetector.pas): Identifica pontos anatômicos corporais (ombros, cotovelos, joelhos) para análise ergonômica ou gestual.

### 📦 Pacote [`openai_agent.lpk`](pacote/packages/openai_agent.lpk)
* [`TAIAgent`](pacote/AI%20Agent/aiagent.pas): Componente principal do agente inteligente. Gerencia ciclo de raciocínio, execução de etapas, prompt do sistema e histórico.
* [`TAIAgentMemoryMap`](pacote/AI%20Agent/aiagent_memorymap.pas): Memória estruturada em pares chave-valor e contexto factual persistente para o agente.
* [`TAIAgentGuardrail`](pacote/AI%20Agent/aiagent_guardrail.pas): Filtro de segurança e validação de regras de conduta para bloquear saídas indesejadas de modelos de linguagem.
* [`TAIToolCall`](pacote/AI%20Agent/aiagent_toolcall.pas): Conector que permite ao agente invocar funções Pascal da aplicação (ex: consultar saldo, ligar relé).

### 📦 Pacote [`openai_voice.lpk`](pacote/packages/openai_voice.lpk)
* [`TAIVoiceSynthesizer`](pacote/AI%20Voice/aivoicesynthesizer.pas): Síntese de fala Text-to-Speech (TTS) nativa via APIs do sistema operacional ou serviços de áudio em nuvem.
* [`TAISpeechRecognizer`](pacote/AI%20Voice/aispeechrecognizer.pas): Reconhecedor de fala Speech-to-Text (STT) com suporte a microfones locais e Whisper.
* [`TAIVoiceClone`](pacote/AI%20Voice/aivoiceclone.pas): Módulo experimental para clonagem e reprodução de voz com timbres customizados.

### 📦 Pacote [`openai_industrial.lpk`](pacote/packages/openai_industrial.lpk) & [`openai_marlin.lpk`](pacote/packages/openai_marlin.lpk)
* [`TAIModbus`](pacote/AI%20Industrial/aimodbus.pas): Cliente de comunicação com CLPs industriais via Modbus TCP (Ethernet) e Modbus RTU (porta serial).
* [`TAIMQTT`](pacote/AI%20Industrial/aimqtt.pas): Conector com brokers MQTT para telemetria e envio de mensagens para dispositivos IoT.
* [`TAIArmRobot`](pacote/AI%20Industrial/aiarm_robot.pas): Modelo cinemático e de controle de juntas para braços robóticos industriais articulados.
* [`TAIMarlinSimulator`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas): Emula o comportamento de uma impressora 3D ou roteadora CNC Marlin, interpretando comandos G-Code e respondendo via porta serial virtual.

### 📦 Pacote [`openai_output.lpk`](pacote/packages/openai_output.lpk)
* [`TAIWordDocument`](pacote/AI%20Output/aiworddocument.pas): Gera nativamente arquivos `.docx` do Microsoft Word com tabelas, títulos, cabeçalhos e formatação a partir de relatórios da IA.
* [`TAIXlsxWriter`](pacote/AI%20Output/aixlsxwriter.pas): Gera planilhas Excel `.xlsx` formatadas com dados tabulares gerados por agentes.
* [`TAIPosPrinter`](pacote/AI%20Output/aiposprinter.pas): Comunica-se com impressoras térmicas de cupom (ESC/POS) como Elgin, Epson e Bematech.

---

## 🧭 4. Como Navegar na Documentação e Exemplos

Para explorar a fundo cada subsistema:
1. Consulte o [**Guia Geral de Samples**](pacote/samples/README.md) para ver a lista de todos os 95+ exemplos práticos com fotos e explicações funcionais.
2. Acesse a pasta do módulo que deseja explorar (ex.: [**`pacote/AI Input/`**](pacote/AI%20Input/)) para entender os componentes contidos nele e suas unidades `.pas`.
3. Para cada sample, consulte o manual de instruções com as **Propriedades**, **Métodos** e **Eventos** detalhados em seu respectivo `README.md` (por exemplo: [Manual do Sample de Joystick](pacote/samples/AI%20Input/joystick_demo_README.md) e [Manual da Demonstração de Projetos](pacote/samples/AI%20Project/Demo_AI_Project/README.md)).

---

## 🛠️ 5. Requisitos e Instalação

- **Compilador:** [Free Pascal (FPC)](https://www.freepascal.org/) versão 3.2.2 ou superior.
- **IDE:** [Lazarus](https://www.lazarus-ide.org/) versão 3.0 ou superior (32-bit ou 64-bit).
- **Instalação dos Pacotes:**
  1. No Lazarus, acesse o menu `Package` -> `Open Package File (.lpk)...`.
  2. Navegue até a pasta [`pacote/packages/`](pacote/packages/).
  3. Comece abrindo e compilando o pacote base [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Clique em `Compile` e, se desejar os componentes na paleta da IDE, clique em `Use` -> `Install`.
  5. Instale os demais pacotes conforme a necessidade da sua aplicação.

---

## 📄 6. Licença

Este projeto é distribuído sob os termos da licença **GPL v3**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.