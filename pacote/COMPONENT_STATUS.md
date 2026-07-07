# Component Status Matrix

Esta matriz registra o estado atual dos principais componentes da **Lazarus AI Suite**.

> [!WARNING]
> **Restrição de Arquitetura (64-bit Only)**: Componentes baseados em pontes nativas complexas de Machine Learning, como o `TAIHumanPoseDetector` (MediaPipe), rodam exclusivamente em plataformas de **64-bit**. Em compilações de 32-bit, estes componentes reportam indisponibilidade sem interromper a compilação do pacote.

Use esta classificação para documentação, README de abas, samples e planejamento de releases.

---

## Legenda

| Status | Significado |
|---|---|
| Stable | Base consolidada e de baixo risco |
| Beta | Funcional, mas ainda precisa validação ampla |
| Experimental | API ou comportamento ainda pode mudar |
| Placeholder | Estrutura existe, mas ainda não entrega função real completa |
| Deprecated | Mantido apenas por compatibilidade |

---

## Core

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIBaseComponent` | `aibase.pas` | `openai_core` | Stable | Base comum para componentes de IA |
| `TCHATGPT` | `chatgpt.pas` | `openai_core` | Beta | Cliente LLM multi-provider |
| `TTokenList` | `tokenizer.pas` | `openai_core` | Beta/Legacy | Tokenização simples |
| `TAICodeAssistant` | `aicodeassistant.pas` | `openai_core` | Beta | Assistente de código baseado em LLM |
| `TAIPromptBuilder` | `aipromptbuilder.pas` | `openai_core` | Beta | Construção padronizada de prompts |
| `TAIModelRegistry` | `aimodelregistry.pas` | `openai_core` | Experimental | Registro de modelos e provedores |

---

## Machine Learning / Math

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TNeuralNetwork` | `neuralnetwork.pas` | `openai_ml` | Beta | Rede neural didática/local |
| `TPerceptron` | `perceptron.pas` | `openai_ml` | Beta | Perceptron simples |
| `TSOMMap` | `sommap.pas` | `openai_ml` | Experimental | Mapa auto-organizável |
| `TAIDatasetGenerator` | `aidatasetgenerator.pas` | `openai_ml` | Beta | Geração/manipulação de datasets |
| `TAMatrizComponent` | `matrizcomponent.pas` | `openai_ml` | Beta | Operações com matrizes |
| `TNumPS` | `numps.pas` | `openai_ml` | Beta | Utilitário estilo NumPy simplificado em Pascal |

---

## Graph

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIGraphMap` | `aigraphmap.pas` | `openai_graph` | Beta | Classificação por grafo e tokens |
| `TAITrainingExporter` | `aitrainingexporter.pas` | `openai_graph` | Experimental | Exportação de dados de treinamento |
| `TAIDatasetAnalyzer` | `aidatasetanalyzer.pas` | `openai_graph` | Experimental | Análise de qualidade de dataset |
| `TAITrainingReport` | `aitrainingreport.pas` | `openai_graph` | Experimental | Relatórios técnicos de treinamento |
| `TAIGraphVisualizer` | `aigraphvisualizer.pas` | `openai_graph` | Experimental | Visualização/exportação de grafos |

---

## Python

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TPythonConnector` | `pythonconnector.pas` | `openai_python` | Experimental/Beta | Preferir modo processo; DLL Python é sensível |
| `TYoloDetect` | `yolodetect.pas` | `openai_python` | Experimental | Depende de Python/modelos externos |
| `TFaceDetection` | `facedetection.pas` | `openai_python` | Experimental | Depende de backend externo |
| `TCNNClassifier` | `cnnclassifier.pas` | `openai_python` | Experimental | Depende de Python/modelo externo |
| `TLSTMPredictor` | `lstmpredictor.pas` | `openai_python` | Experimental | Depende de Python/modelo externo |
| `aipythonruntime` | `aipythonruntime.pas` | `openai_python` | Beta | Helper de busca e inicialização para runtime do Python local |

---

## Vision

| Componente/Unit | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIOpenCV` | `aiopencv.pas` | `openai_vision` | Beta/Parcial | Funcional via worker Python; backend Native DLL localiza/carrega DLL/SO, mas processamento nativo real ainda é simulado |
| `aiopencvruntime` | `aiopencvruntime.pas` | `openai_vision` | Beta | Helper de busca inteligente para `opencv_world*.dll` e `libopencv_world.so*` por SO/arquitetura |
| `aicamera_backend` | `aicamera_backend.pas` | `openai_vision` | Stable | Interface base para backends de câmera nativa (usada por `TAICaptureSource`) |
| `aicamera_vfw` | `aicamera_vfw.pas` | `openai_vision` | Beta | Backend Windows VFW para câmera local (usado internamente por `TAICaptureSource`) |
| `aicamera_v4l2` | `aicamera_v4l2.pas` | `openai_vision` | Beta | Backend Linux V4L2 para câmera local (usado internamente por `TAICaptureSource`) |
| `TAIFrameProcessor` | `aiframeprocessor.pas` | `openai_vision` | Beta | Pré-processador nativo de imagens para Lazarus/FPC, capaz de redimensionar, converter para grayscale e manipular canais RGB |
| `TAIFaceTracker` | `aifacetracker.pas` | `openai_vision` | Experimental | Rastreamento por template matching (SAD) 100% nativo |
| `TAIMotionTracker` | `aimotiontracker.pas` | `openai_vision` | Experimental | Detecção de movimento por variação de luminância 100% nativa |
| `TAIImageInfo` | `aiimageinfo.pas` | `openai_vision` | Beta | Extração nativa de metadados e contagem de pixels de imagem |
| `TAIFrameBuffer` | `aiframebuffer.pas` | `openai_vision` | Experimental | Buffer de frames circular em memória para processamento de vídeo |
| `TAINativeImageFilter` | `ainativeimagefilter.pas` | `openai_vision` | Experimental | Filtros rápidos de pixel (Cinza, Limiar, Inverter, Resize, Blur) 100% nativos |
| `TAIFrameDiff` | `aiframediff.pas` | `openai_vision` | Experimental | Geração nativa de diferença absoluta de pixels entre frames |
| `TAIHumanPoseDetector` | `aihumanposedetector.pas` | `openai_vision` | Stable | Detector de pose real integrado (MediaPipe 0.10.35). Pipeline (Lazarus → DLL → Python Worker) completo e validado, com 33 landmarks reais, simulação e livre de vazamento de memória. Exclusivo 64-bit (indisponível em 32-bit). |

---

## Input

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAICaptureSource` | `aicapturesource.pas` | `openai_input` | Beta | Fonte de captura unificada: câmera local, IP snapshot, tela, arquivo; substitui os 4 componentes legados |
| `TAIInputData` | `aiinput.pas` | `openai_input` | Beta | Entrada e normalização de dados numéricos |
| `TAIWebAPIServer` | `aiwebserver.pas` | `openai_input` | Beta | Servidor REST/HTTP embutido |
| `TAISocketTCP` | `aisockets.pas` | `openai_input` | Beta | Cliente/servidor TCP |
| `TAISocketUDP` | `aisockets.pas` | `openai_input` | Beta | Cliente/servidor UDP |
| `TAISerialModem` | `aiserial.pas` | `openai_input` | Beta | Comunicação serial / modem |
| `TAIPOSPrinter` | `aiposprinter.pas` | `openai_industrial` | Beta | Impressora térmica EscPOS |
| `TAIModbusClient` | `aimodbus.pas` | `openai_industrial` | Beta | Cliente Modbus TCP/RTU |
| `TAIMQTTClient` | `aimqtt.pas` | `openai_industrial` | Beta | Cliente IoT MQTT |
| `TAIEmailClient` | `aiemail.pas` | `openai_input` | Beta | E-mail SMTP/POP3 |
| `TAIMessenger` | `aimessenger.pas` | `openai_input` | Beta | WhatsApp e SMS |
| `TAIIndustrialBridge` | `aiindustrial.pas` | `openai_industrial` | Beta | Ponte Profinet/Profibus para CLPs |
| `TAIChromiumBrowser` | `aichromiumbrowser.pas` | `openai_input` | Beta/Experimental | Navegador Chromium real baseado em CEF4Delphi `TChromiumWindow`; substitui a renderização anterior via `TIpHtmlPanel`. |
| `TAIKinectSensor` | `aikinectsensor.pas` | `openai_input` | Experimental | Conexão, tilt, LED e acelerômetro do Kinect v1 |
| `TAIKinectColorStream` | `aikinectcolor.pas` | `openai_input` | Experimental | Fluxo RGB/IR do Kinect, compatível com o pipeline de frames da suíte |
| `TAIKinectDepthStream` | `aikinectdepth.pas` | `openai_input` | Experimental | Profundidade em mm, mapa colorizado e nuvem de pontos (PLY) |
| `TAIKinectSkeleton` | `aikinectskeleton.pas` | `openai_input` | Placeholder | Esqueleto 20 juntas via Kinect SDK 1.8 (Windows) — fase 2 |
| `TAIKinectAudio` | `aikinectaudio.pas` | `openai_input` | Placeholder | Array de microfones + direção da fonte sonora — fase 2 |

---

## Files

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIDiskTreeScanner` | `aidisktreescanner.pas` | `openai_files` | Beta | Componente assíncrono para navegar, pesquisar e indexar arquivos e diretórios, com suporte a inventário de datasets para IA |
| `TAI_DOCFILESMANAGER` | `ai_docfilesmanager.pas` | `openai_files` | Beta | Gerenciador físico de arquivos e documentações locais |

---

## Image Filters

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TGrayscaleFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo para escala de cinza |
| `TNegativeFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo de inversão de cores |
| `TBrightnessContrastFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo para brilho e contraste |
| `TBinarizationFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo de binarização (limiarização) |
| `TBlurFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo de desfoque (blur) |
| `TSharpenFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo de nitidez |
| `TSobelFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtro nativo de detecção de bordas Sobel |
| `TErosionDilationFilter` | `imagefilters.pas` | `openai_image` | Stable | Filtros nativos morfológicos de erosão e dilatação |

---

## Output

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIOutputData` | `aioutput.pas` | `openai_output` | Beta | Saída estruturada |
| `TAIOutputDocs` | `aioutput_docs.pas` | `openai_output` | Beta | Documentos; revisar formatos reais gerados |
| `TAIPDFOutput` | `aioutput_docs.pas` | `openai_output` | Beta | PDF via FPC/fpPDF |
| `TAIWordOutput` | `aioutput_docs.pas` | `openai_output` | Beta/Compatível | Gera HTML compatível salvo como arquivo Word; não é DOCX nativo |
| `TAIExcelOutput` | `aioutput_docs.pas` | `openai_output` | Beta/Compatível | Gera HTML compatível salvo como arquivo Excel; não é XLSX nativo |
| `TAITXTOutput` | `aioutput_docs.pas` | `openai_output` | Stable/Beta | Saída texto simples |

---

## Agent

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIAgent` | `aiagent.pas` | `openai_agent` | Experimental | Agente com ações; exige segurança |
| `TAIAgentSafety` | `aiagentsafety.pas` | `openai_agent` | Beta | Bloqueios conservadores e modo simulação |
| `TAIAgentExecutor` | `aiagent_executors.pas` | `openai_agent` | Experimental | Executores devem ser validados por ação |
| `TAIPipeline` | `aipipeline.pas` | `openai_agent` | Beta | Orquestração de fluxos ML, LLM e Agentes (migrado para openai_agent) |
| `TAIWizardConfig` | `aiwizardconfig.pas` | `openai_agent` | Beta | Assistente visual de configurações iniciais (migrado para openai_agent) |

---

## Project

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIProject` | `aiproject.pas` | `openai_project` | Beta | Coordenação e armazenamento JSON do projeto |
| `TAIProjectSpecification` | `aiproject_specification.pas` | `openai_project` | Beta | Geração de especificação de projeto com IA |
| `TAIProjectTasks` | `aiproject_tasks.pas` | `openai_project` | Beta | Gerenciamento de tarefas do projeto |
| `TAIProjectStorage` | `aiproject_storage.pas` | `openai_project` | Beta | Gravação e leitura do projeto JSON |
| `TAIProjectLLMConfig` | `aiproject_llmconfig.pas` | `openai_project` | Beta | Configuração de LLM e Token para o projeto |

---

## Voice

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIVoiceSynthesizer` | `aivoicesynthesizer.pas` | `openai_voice` | Stable | Síntese real de voz (SAPI/local e OpenAI Speech API). Funcional e validado pelo demo `voice_synthesizer_complete_demo` |
| `TAIAudioInput` | `aiaudio.pas` | `openai_voice` | Beta | Captura de áudio via microfone |


---

## Graphic / 3D

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAI3DModelViewer` | `ai3dmodelviewer.pas` | `openai_graphic` | Beta/Experimental | Viewer 3D básico |
| `TAIModel3D` | `aimodel3d.pas` | `openai_graphic` | Beta/Experimental | Estrutura de modelo 3D |
| `TAITripo3DClient` | `aitripo3dclient.pas` | `openai_graphic` | Experimental | Depende de serviço externo/API |
| `TAIAvatar3D` | `aiavatar3d.pas` | `openai_graphic` | Experimental | Avatar/3D em evolução |
| `TAIScene3D` | `aiscene3d.pas` | `openai_graphic` | Experimental | Cena 3D em evolução |

---

## AI Simulation

> **Observação de escopo:** `AI Simulation` é uma área para simular ambientes reais ou controlados, como movimento de agentes, robôs, filas, logística, propagação, ocupação de espaços e cenários de treinamento/validação de IA. Não significa componente fake, mock ou retorno artificial de sucesso. Componentes incompletos fora desta área devem retornar erro/indisponibilidade clara, não simular funcionamento real.

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIGridWorld` | `aigridworld.pas` | `openai_simulation` | Experimental | Mundo 2D baseado em grade para simular ambientes, obstáculos, agentes e posições |
| `TAIGridCell` | `aigridcell.pas` | `openai_simulation` | Experimental | Tipo auxiliar de representação de célula, terreno, ocupação e custo de movimento |
| `TAIGridBuffer` | `aigridbuffer.pas` | `openai_simulation` | Experimental | Tipo auxiliar de duplo buffer para atualização controlada por ciclos |
| `TAISimEntity` | `aisimentity.pas` | `openai_simulation` | Experimental | Entidade/agente ativo da simulação, usado para modelar objetos, pessoas, robôs ou recursos |
| `TAIEntityFactory` | `aientityfactory.pas` | `openai_simulation` | Experimental | Fábrica de criação de agentes e entidades de cenário |
| `TAISimulationEngine` | `aisimulationengine.pas` | `openai_simulation` | Experimental | Motor de ciclo principal para executar, pausar, avançar e controlar a simulação |
| `TAIRuleEngine` | `airuleengine.pas` | `openai_simulation` | Experimental | Motor de regras comportamentais para agentes e ambientes simulados |
| `TAITriggerEngine` | `aitriggerengine.pas` | `openai_simulation` | Experimental | Motor de eventos da simulação, como início/fim de ciclo, movimento e colisões lógicas |
| `TAIMovementEngine` | `aimovementengine.pas` | `openai_simulation` | Experimental | Motor de movimento 2D para caminhada, busca, fuga, rotas e deslocamento de agentes |
| `TAIEvolutionEngine` | `aievolutionengine.pas` | `openai_simulation` | Experimental | Mecanismos de mutação, seleção e adaptação para treinamento/evolução de comportamentos |
| `TAISimulationStats` | `aisimulationstats.pas` | `openai_simulation` | Experimental | Coletor de métricas para avaliar ciclos, agentes, eventos e resultados da simulação |
| `TAIGridRenderer2D` | `aigridrenderer2d.pas` | `openai_simulation` | Experimental | Desenho nativo 2D da simulação em TCanvas |
| `TAIScenarioConfig` | `aiscenarioconfig.pas` | `openai_simulation` | Experimental | Salvar/carregar cenários, layouts, agentes e parâmetros em JSON |
| `TAIScenarioGenerator` | `aiscenariogenerator.pas` | `openai_simulation` | Experimental | Criador de cenários baseado em prompt com ChatGPT para testes e treinamento controlado |
| `TAISimulationExporter` | `aisimulationexporter.pas` | `openai_simulation` | Experimental | Exportador de relatórios, métricas e datasets da simulação em CSV, TXT e JSON |

---

## AI DBase

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAICustomDBDictionary` | `aidb_dictionary_base.pas` | `openai_aidbase` | Base | Classe base abstrata para dicionário de dados |
| `TAIPostgreSQLDictionary` | `aidb_postgresql_dictionary.pas` | `openai_aidbase` | Beta | Geração de dicionário de dados PostgreSQL via information_schema |
| `TAISQLiteDictionary` | `aidb_sqlite_dictionary.pas` | `openai_aidbase` | Beta | Geração de dicionário SQLite via sqlite_master e PRAGMA |
| `TAIMySQLDictionary` | `aidb_mysql_dictionary.pas` | `openai_aidbase` | Experimental | Estrutura preparada para MySQL |
| `TAIFirebirdDictionary` | `aidb_firebird_dictionary.pas` | `openai_aidbase` | Experimental | Estrutura preparada para Firebird |
| `TAISQLServerDictionary` | `aidb_sqlserver_dictionary.pas` | `openai_aidbase` | Experimental | Estrutura preparada para SQL Server |
| `TAIOracleDictionary` | `aidb_oracle_dictionary.pas` | `openai_aidbase` | Experimental | Estrutura preparada para Oracle |

---

## Legacy
