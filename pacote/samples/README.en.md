# 📂 Demonstration Projects (Samples)

> [!NOTE]
> This directory contains the complete suite of examples developed to demonstrate and test all Artificial Intelligence, Machine Learning, Image Processing, Digital Signal Processing (DSP), Hardware Automation, and Document Generation components of the Lazarus AI Suite.

## 🖥️ Graphical User Interface (GUI) Demonstrations
The following examples are visual projects ready for compilation and interactive execution through Lazarus:

### 📦 AI

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[CNN Image Classification Demo (cnn_demo)](AI/cnn_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/cnn_demo.jpg)</sub> | Este exemplo demonstra o uso do componente **`TCNNClassifier`** integrado ao conector Python para realizar classificação de imagens profunda em tempo real com o modelo **MobileNetV2** (pré-treinado no ImageNet). | `openai`, `ImagesForLazarus` | `TCNNClassifier`, `TPythonConnector` |
| **[Kohonen Self-Organizing Maps RGB Demo (som_demo)](AI/som_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/som_demo.jpg)</sub> | Este exemplo demonstra o uso do componente **`TSOMMap`**, uma Rede de Auto-Organização de Kohonen (Self-Organizing Map) escrita em **Pascal puro**, para mapear e agrupar vetores tridimensionais de cores RGB em uma grade bidimensional interativa de neurônios. | `openai` | `TSOMMap` |
| **[LSTM Trend Prediction Demo (lstm_demo)](AI/lstm_demo/)** | Este exemplo demonstra o uso do componente recorrente **`TLSTMPredictor`** integrado ao conector Python para prever tendências futuras em séries temporais (Rolling Forecast) usando redes neurais recorrentes do tipo **LSTM (Long Short-Term Memory)**. | `openai`, `ImagesForLazarus` | `TLSTMPredictor`, `TPythonConnector` |
| **[Neural Network XOR Playground (neural_network_demo)](AI/neural_network_demo/)** | Este exemplo demonstra o uso do componente **`TNeuralNetwork`**, uma rede neural artificial multicamadas (MLP - Multilayer Perceptron) escrita em **Pascal puro**, para aprender a lógica XOR (Ou Exclusivo) de forma totalmente local e offline. | `openai` | `TNeuralNetwork` |
| **[OpenCV Face Detection Demo (face_detection_demo)](AI/face_detection_demo/)** | Este exemplo demonstra o uso do componente **`TFaceDetection`** integrado ao conector Python para realizar detecção facial em tempo real com **OpenCV** e desenhar retângulos delimitadores vermelhos ao redor de faces humanas. | `openai`, `ImagesForLazarus` | `TFaceDetection`, `TPythonConnector` |
| **[Perceptron Logic Gates Playground (perceptron_demo)](AI/perceptron_demo/)** | Este exemplo demonstra o uso do componente **`TPerceptron`**, uma rede neural artificial clássica de camada única escrita em **Pascal puro**, para aprender portas lógicas linearmente separáveis (como AND, OR, NAND, NOR) de forma totalmente offline. | `openai` | `TPerceptron` |
| **[Python Connector Demo (python_demo)](AI/python_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/python_demo.jpg)</sub> | Este exemplo demonstra como utilizar o componente **`TPythonConnector`** para carregar interpretadores Python dinamicamente e executar códigos, avaliar expressões matemáticas e interagir com variáveis globais diretamente de aplicações Lazarus/Delphi de forma multiplataforma. | `openai` | `TPythonConnector` |
| **[String Tokenizer Utility Demo (tokenizer_demo)](AI/tokenizer_demo/)** | Este exemplo demonstra o uso do componente **`TTokenList`**, um utilitário escrito em **Pascal puro** projetado para segmentação (tokenização), contagem e indexação estruturada de termos e palavras em strings de texto. | `openai` | `TTokenList` |
| **[TAIGraphMap Demo — Classificação Textual por Grafo Ponderado](AI/graphmap_demo/)** | Este projeto demonstra visualmente o funcionamento do componente `TAIGraphMap`. | `openai` | `TAIGraphMap` |
| **[Unified AI Components Playground (visual_demo)](AI/visual_demo/)** | Este é o showcase unificado e a central de testes em interface gráfica para as quatro ferramentas fundamentais da suíte de IA: **`TCHATGPT`**, **`TNeuralNetwork`**, **`TAICodeAssistant`** e **`TAIDatasetGenerator`**. | `openai` | `TCHATGPT`, `TNeuralNetwork` |
| **[YOLOv8 Object Detection Demo (yolo_demo)](AI/yolo_demo/)** | Este exemplo demonstra o uso do componente **`TYOLO`** integrado ao conector Python para realizar detecção de objetos profunda em tempo real com o modelo **YOLOv8** (You Only Look Once) e desenhar retângulos delimitadores diretamente em imagens na tela do Lazarus. | `openai`, `ImagesForLazarus` | `TPythonConnector`, `TYOLO` |

### 📦 AI Agent

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Playground de Agente Autônomo e Tomada de Decisão (TAIAgent)](AI Agent/agent_demo/)** | Este projeto demonstra a utilização prática do novo conjunto de componentes autônomos sob a aba **AI Agent** do Lazarus IDE. A aplicação exemplifica como configurar agentes inteligentes capazes de receber instruções, analisar contextos do mundo real e escolher a melhor ação a ser executada externamente por meio de recursos físicos com retorno estruturado via JSON nativo. | `openai` | `TAIAgent`, `TAIAgentAction`, `TAIAgentOptions`, `TAIAgentOutput`, `TAIAgentResource`, `TCHATGPT` |

### 📦 AI Core

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Codeassistant Demo (aicodeassistant)](AI Core/codeassistant_demo/)** | This sample project demonstrates the usage of component `aicodeassistant` from the `openai_core` package. | `openai_core` | - |
| **[Modelregistry Demo (aimodelregistry)](AI Core/modelregistry_demo/)** | This sample project demonstrates the usage of component `aimodelregistry, chatgpt` from the `openai_core` package. | `openai_core` | `TCHATGPT` |
| **[Pipeline Full Demo (aipipeline)](AI Core/pipeline_full_demo/)** | This sample project demonstrates the usage of component `aipipeline, chatgpt, aioutput, aioutput_docs` from the `openai_core` package. | `openai_core` | `TCHATGPT` |
| **[Promptbuilder Demo (aipromptbuilder)](AI Core/promptbuilder_demo/)** | This sample project demonstrates the usage of component `aipromptbuilder` from the `openai_core` package. | `openai_core` | - |
| **[Wizard Config Demo (aiwizardconfig)](AI Core/wizard_config_demo/)** | This sample project demonstrates the usage of component `aiwizardconfig, aiproject, chatgpt, aipipeline` from the `openai_core` package. | `openai_core` | `TCHATGPT` |

### 📦 AI DBase

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[AI SQLite Query Assistant Demo](AI DBase/ai_sqlite_query_assistant_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/ai_sqlite_query_assistant_demo.jpg)</sub> | This demo shows how to combine ChatGPT with the AI DBase Dictionary component to generate SQLite SELECT queries from natural language. | `openai_aidbase`, `openai_core`, `zcomponent` | `TAISQLiteDictionary`, `TCHATGPT` |
| **[db_dictionary_demo](AI DBase/db_dictionary_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/db_dicitionary_demo.jpg)</sub> | No description available. | `zcomponent`, `openai_core`, `openai_aidbase` | `TAIPostgreSQLDictionary`, `TAISQLiteDictionary` |

### 📦 AI Files

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[AI_DOCFILESMANAGER Demo](AI Files/docfilesmanager_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/docfilesmanager_demo.jpg)</sub> | ![AI_DOCFILESMANAGER Demo Screenshot](../../../../screenshots/docfilesmanager_demo.jpg) | `openai_files` | - |
| **[Disk Tree AI Dataset Demo](AI Files/disk_tree_ai_dataset_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/disk_tree_ai_dataset_demo.jpg)</sub> | Este demo demonstra o uso do componente `TAIDiskTreeScanner` para navegação, varredura, pesquisa e preparação de datasets para inteligência artificial de forma assíncrona. | `openai_files` | - |

### 📦 AI Filtros Sonoros

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Audio Sound Filters Demo (sound_filters_demo)](AI Filtros Sonoros/sound_filters_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/sound_filters.jpg)</sub> | Este exemplo demonstra o uso dos filtros de processamento de sinais analógicos e multiplexadores de RF incluídos na aba **`AI Filtros Sonoros`** da paleta de componentes do Lazarus, implementados em **Pascal puro** de alta performance. | `openai` | - |

### 📦 AI Graph

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Dataset Analyzer Demo (aidatasetanalyzer)](AI Graph/dataset_analyzer_demo/)** | This sample project demonstrates the usage of component `aidatasetanalyzer` from the `openai_graph` package. | `openai_graph` | - |
| **[Graph Visualizer Demo (aigraphvisualizer)](AI Graph/graph_visualizer_demo/)** | This sample project demonstrates the usage of component `aigraphvisualizer, aigraphmap` from the `openai_graph` package. | `openai_graph` | `TAIGraphMap` |
| **[Training Exporter Demo (aitrainingexporter)](AI Graph/training_exporter_demo/)** | This sample project demonstrates the usage of component `aitrainingexporter, aigraphmap` from the `openai_graph` package. | `openai_graph` | `TAIGraphMap` |
| **[Training Report Demo (aitrainingreport)](AI Graph/training_report_demo/)** | This sample project demonstrates the usage of component `aitrainingreport, aigraphmap` from the `openai_graph` package. | `openai_graph` | `TAIGraphMap` |
| **[graphmap_basic](AI Graph/graphmap_basic/)** | No description available. | `openai` | `TAIGraphMap` |

### 📦 AI Graphic

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Avatar 3D Animation Demo - Lazarus AI Suite](AI Graphic/avatar_demo/)** | Este demonstrativo apresenta a exibição e animação de avatares 3D utilizando esqueletos e malhas deformáveis. | `openai` | - |
| **[Model3D Viewer Demo (ai3dmodelviewer)](AI Graphic/model3d_viewer_demo/)** | This sample project demonstrates the usage of component `ai3dmodelviewer, aimodel3d` from the `openai_graphic` package. | `openai_graphic` | `TAI3DModelViewer`, `TAIModel3D` |
| **[Physics Training Demo (aiphysicssimulator)](AI Graphic/physics_training_demo/)** | This sample project demonstrates the usage of component `aiphysicssimulator, aitrainingenvironment` from the `openai_graphic` package. | `openai_graphic` | - |
| **[Pose Animation Demo (aiposelibrary)](AI Graphic/pose_animation_demo/)** | This sample project demonstrates the usage of component `aiposelibrary, aianimationsequence, aiskeletonrig` from the `openai_graphic` package. | `openai_graphic` | - |
| **[Scene3D Demo (aiscene2d3d)](AI Graphic/scene3d_demo/)** | This sample project demonstrates the usage of component `aiscene2d3d` from the `openai_graphic` package. | `openai_graphic` | `TAIScene2D3D` |
| **[Skeleton Rig Demo (aiskeletonrig)](AI Graphic/skeleton_rig_demo/)** | This sample project demonstrates the usage of component `aiskeletonrig` from the `openai_graphic` package. | `openai_graphic` | - |
| **[Tripo3D Demo (aitripo3dclient)](AI Graphic/tripo3d_demo/)** | This sample project demonstrates the usage of component `aitripo3dclient` from the `openai_graphic` package. | `openai_graphic` | `TAITripo3dClient` |
| **[opengl_graphic_demo](AI Graphic/opengl_graphic_demo/)** | No description available. | `openai` | `TAI3DModelViewer`, `TAIModel3D`, `TAIScene2D3D` |

### 📦 AI Image

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[LCL Image Filters Demo (image_filters_demo)](AI Image/image_filters_demo/)** | Este exemplo demonstra o uso dos filtros de processamento de imagens matriciais inclusos na aba **`AI Image`** da paleta de componentes do Lazarus, implementados em **Pascal puro** de alta performance. | `openai` | - |

### 📦 AI Industrial

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Industrial Bridge Demo (aiindustrial)](AI Industrial/industrial_bridge_demo/)** | This sample project demonstrates the usage of component `aiindustrial` from the `openai_industrial` package. | `openai_industrial` | `TAIIndustrialBridge` |
| **[Modbus Demo (aimodbus)](AI Industrial/modbus_demo/)** | This sample project demonstrates the usage of component `aimodbus` from the `openai_industrial` package. | `openai_industrial` | - |
| **[Mqtt Demo (aimqtt)](AI Industrial/mqtt_demo/)** | This sample project demonstrates the usage of component `aimqtt` from the `openai_industrial` package. | `openai_industrial` | `TAIMQTTClient` |

### 📦 AI Input

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Chromium Capture Demo (aichromiumbrowser)](AI Input/chromium_capture_demo/)** | This sample project demonstrates the usage of component `aichromiumbrowser` from the `openai_input` package. | `openai_input` | `TAIChromiumBrowser` |
| **[Email Classifier Demo (aiemail)](AI Input/email_classifier_demo/)** | This sample project demonstrates the usage of component `aiemail` from the `openai_input` package. | `openai_input` | `TAIEmailClient` |
| **[Serial Demo (aiserial)](AI Input/serial_demo/)** | This sample project demonstrates the usage of component `aiserial` from the `openai_input` package. | `openai_input` | - |
| **[Socket Server Client Demo (aisockets)](AI Input/socket_server_client_demo/)** | This sample project demonstrates the usage of component `aisockets` from the `openai_input` package. | `openai_input` | - |
| **[Webserver Demo (aiwebserver)](AI Input/webserver_demo/)** | This sample project demonstrates the usage of component `aiwebserver` from the `openai_input` package. | `openai_input` | - |
| **[capture_source_demo](AI Input/capture_source_demo/)** | Sample demonstrating **TAICaptureSource** — the unified capture component of the Lazarus AI Suite. | `openai_input`, `openai_vision` | - |
| **[hardware_net_demo](AI Input/hardware_net_demo/)** | No description available. | `openai` | `TAIChromiumBrowser`, `TAIEmailClient`, `TAIIndustrialBridge`, `TAIMQTTClient`, `TAIMessenger` |

### 📦 AI ML

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Dataset Generator Visual Demo (aidatasetgenerator)](AI ML/dataset_generator_visual_demo/)** | This sample project demonstrates the usage of component `aidatasetgenerator` from the `openai_ml` package. | `openai_ml` | - |
| **[Matrix Component Demo (matrizcomponent)](AI ML/matrix_component_demo/)** | This sample project demonstrates the usage of component `matrizcomponent` from the `openai_ml` package. | `openai_ml` | - |
| **[Numps Demo (numps)](AI ML/numps_demo/)** | This sample project demonstrates the usage of component `numps` from the `openai_ml` package. | `openai_ml` | - |

### 📦 AI Math

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Demonstração Visual: AI Math, AI Input e AI Output](AI Math/math_input_output_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/math_input_output_demo.jpg)</sub> | Este exemplo é uma demonstração visual unificada criada para ilustrar o uso dos três novos componentes da suíte de componentes de IA para Lazarus: | `openai` | - |

### 📦 AI MediaPipe Vision

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Pose Detector Demo — TAIHumanPoseDetector](AI MediaPipe Vision/pose_detector_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/pose_detector_demo.jpg)</sub> | Demo GUI que demonstra o componente `TAIHumanPoseDetector` com a bridge SIM (e opcionalmente REAL). | `ImagesForLazarus`, `openai_vision` | - |

### 📦 AI Native Vision

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[motion_tracker_demo](AI Native Vision/motion_tracker_demo/)** | No description available. | `openai_vision` | `TAIMotionTracker` |
| **[native_image_filter_demo](AI Native Vision/native_image_filter_demo/)** | No description available. | `openai_vision` | - |

### 📦 AI Output

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Output Docs Demo (aioutput_docs)](AI Output/output_docs_demo/)** | This sample project demonstrates the usage of component `aioutput_docs` from the `openai_output` package. | `openai_output` | - |
| **[Output Text Json Demo (aioutput)](AI Output/output_text_json_demo/)** | This sample project demonstrates the usage of component `aioutput, aiinput` from the `openai_output` package. | `openai_output` | - |
| **[Pdf Word Excel Demo (aioutput_docs)](AI Output/pdf_word_excel_demo/)** | This sample project demonstrates the usage of component `aioutput_docs` from the `openai_output` package. | `openai_output` | - |
| **[Posprinter Demo (aiposprinter)](AI Output/posprinter_demo/)** | This sample project demonstrates the usage of component `aiposprinter` from the `openai_output` package. | `openai_output` | - |
| **[TAIWordDocument Demo — Manipulação Real de DOCX via OpenXML](AI Output/word_object_demo/)** | Este sample demonstra a geração, carregamento, edição e salvamento real de arquivos `.docx` usando a especificação OpenXML / WordprocessingML. | `openai_output` | - |
| **[TAIWordViewer Demo — Visualização de DOCX em TPanel](AI Output/word_viewer_demo/)** | Este sample demonstra a visualização e renderização nativa de arquivos `.docx` reais dentro de um painel `TPanel` da LCL (Lazarus). | `openai_output` | - |

### 📦 AI Project

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[pipeline_project_demo](AI Project/)** | No description available. | `openai` | `TCHATGPT`, `TNeuralNetwork` |

### 📦 AI Python

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Cnn Classifier Complete Demo (cnnclassifier)](AI Python/cnn_classifier_complete_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/cnn_classifier_complete_demo.jpg)</sub> | Este projeto é um **demo completo de classificação de imagem com CNN no Lazarus**, usando um componente visual `TCNNClassifier` ligado a um `TPythonConnector`. A ideia principal é permitir que uma aplicação Lazarus carregue uma imagem, inicialize um runtime Python por DLL/SO, carregue um modelo TensorFlow e devolva o rótulo identificado com a classificação. A tela principal já nasce com os dois componentes conectados: `CNNClassifier1.PythonConnector := PythonConnector1`, com preferência por execução direta via DLL/SO, sem chamar `python.exe` externo. | `openai_core` | `TCNNClassifier`, `TPythonConnector` |
| **[Lstm Timeseries Demo (lstmpredictor)](AI Python/lstm_timeseries_demo/)** | This sample project demonstrates the usage of component `lstmpredictor` from the `openai_core` package. | `openai_core` | `TLSTMPredictor` |
| **[Python Runtime Check Demo (aipythonruntime)](AI Python/python_runtime_check_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/python_runtime_check_demo.jpg)</sub> | This sample project demonstrates the usage of component `aipythonruntime, pythonconnector` from the `openai_core` package. | `openai_core` | `TPythonConnector` |
| **[Yolo Detection Complete Demo (yolodetect)](AI Python/yolo_detection_complete_demo/)** | This sample project demonstrates the usage of component `yolodetect` from the `openai_core` package. | `openai_core` | `TPythonConnector`, `TYOLO` |

### 📦 AI Schedule

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[IA Tasks Schedule Demo (schedule_demo)](AI Schedule/schedule_demo/)** | Este exemplo demonstra o uso dos componentes **`TIASchedule`** e **`TJSONGroupStorage`**, projetados para gerenciamento persistente, hierarquia de tarefas encadeadas e resolução inteligente de dependências em tempo real. | `openai` | `TIASchedule` |

### 📦 AI Simulation

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Contamination Simulation Demo - Lazarus AI Suite](AI Simulation/contamination_demo/)** | Este demonstrativo apresenta uma simulação didática de proximidade e propagação de estados entre entidades em movimento, simulando uma contaminação e posterior recuperação, utilizando a suíte **AI Simulation**. | `openai_core`, `openai_simulation` | - |
| **[Robot Grid Simulation Demo - Lazarus AI Suite](AI Simulation/robot_grid_demo/)** | Este demonstrativo apresenta uma simulação visual 2D na qual robôs móveis buscam estações de recarga de forma autônoma utilizando a suíte de componentes **AI Simulation**. | `openai_core`, `openai_simulation` | - |
| **[Service Queue Simulation Demo - Lazarus AI Suite](AI Simulation/service_queue_demo/)** | Este demonstrativo apresenta uma simulação visual de uma fila de atendimento (administração, comercial ou hospitalar) utilizando a suíte de componentes **AI Simulation**. | `openai_core`, `openai_simulation` | - |
| **[Warehouse Logistics Simulation Demo - Lazarus AI Suite](AI Simulation/warehouse_agents_demo/)** | Este demonstrativo apresenta uma simulação visual de logística interna de armazém utilizando a suíte de componentes **AI Simulation**. | `openai_core`, `openai_simulation` | - |

### 📦 AI Vision

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Camera Capture Windows Demo (aicameracapture)](AI Vision/camera_capture_windows_demo/)** | This sample project demonstrates the usage of component `aicameracapture` from the `openai_vision` package. | `openai_vision` | - |
| **[Frame Diff Demo (aiframediff)](AI Vision/frame_diff_demo/)** | This sample project demonstrates the usage of component `aiframediff, aimotiontracker` from the `openai_vision` package. | `openai_vision` | `TAIMotionTracker` |
| **[OpenCV Vision Demo](AI Vision/opencv_vision_demo/)** | This sample demonstrates the combined usage of visual tracking and processing components (`TAIOpenCV` `TAIFrameProcessor`, `TAIFaceTracker`, and `TAIMotionTracker`) from the `openai_vision` package. | `openai` | `TAIFaceTracker`, `TAIFrameProcessor`, `TAIMotionTracker`, `TAIOpenCV` |
| **[Opencv Image Real Demo (aiopencv)](AI Vision/opencv_image_real_demo/)** | This sample project demonstrates the usage of component `aiopencv, aiframeprocessor` from the `openai_vision` package. | `openai_vision` | `TAIFrameProcessor`, `TAIOpenCV` |
| **[TAIFrameProcessor Demo (Native Lazarus)](AI Vision/aiframeprocessor_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/TAIFrameProcessor Demo.jpg)</sub> | This sample project demonstrates the usage of component `TAIFrameProcessor` from the `openai_vision` package without OpenCV or Python dependencies. | `openai_vision` | `TAIFrameProcessor` |
| **[TAIImageInfo Demo](AI Vision/image_info_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/image_info_demo.jpg)</sub> | This demo reads basic image information and metadata from image files natively in Lazarus/FPC. | `openai_vision`, `ImagesForLazarus` | - |
| **[TAIOpenCV Filter Demo](AI Vision/opencv_filter_demo/)** | This sample demonstrates how to use the `TAIOpenCV` component in a Lazarus graphical application. | `openai` | `TAIOpenCV` |

### 📦 AI Voice

| Sample / Path | Description | Required Package | Used Components |
|---|---|---|---|
| **[Audio Capture Demo (aiaudio)](AI Voice/audio_capture_demo/)** | This sample project demonstrates the usage of component `aiaudio` from the `openai_voice` package. | `openai_voice` | - |
| **[Sound Filters Visual Demo (soundfilters)](AI Voice/sound_filters_visual_demo/)** | This sample project demonstrates the usage of component `soundfilters` from the `openai_voice` package. | `openai_voice` | - |
| **[Voice Synthesizer Complete Demo (aivoicesynthesizer)](AI Voice/voice_synthesizer_complete_demo/)** | This sample project demonstrates the usage of component `aivoicesynthesizer` from the `openai_voice` package. | `openai_voice` | `TAIVoiceSynthesizer` |
| **[Voice Synthesizer Demo (voicesynthesizer_demo)](AI Voice/voicesynthesizer_demo/)** <br> <sub>[📷 Screenshot](../../screenshots/voicesynthesizer.jpg)</sub> | Este exemplo demonstra o uso do componente **`TAIVoiceSynthesizer`**, um sintetizador de voz nativo, puro e multiplataforma de alta performance para Lazarus/Delphi. | `openai` | `TAIVoiceSynthesizer` |

## 💻 Command Line Interface (Console) Demonstrations
These examples demonstrate direct component invocation via command line for rapid debugging or automation scenarios:

### ⌨️ AI

| Sample / Path | Description | Used Components |
|---|---|---|
| **[aicodeassistant_sample.lpr](AI/aicodeassistant_sample.lpr)** | Console-based assistant to optimize and automatically document Delphi/Pascal code. | `TCHATGPT` |
| **[aidatasetgenerator_sample.lpr](AI/aidatasetgenerator_sample.lpr)** | Automated dataset generation loop exporting data to JSONL format. | - |
| **[chatgpt_sample.lpr](AI/chatgpt_sample.lpr)** | Query invocation and raw JSON payload audit for OpenAI, Claude, and Gemini. | `TCHATGPT` |
| **[neuralnetwork_sample.lpr](AI/neuralnetwork_sample.lpr)** | Classic Multilayer Perceptron training simulator for XOR logic gates. | `TNeuralNetwork` |

### ⌨️ AI Input

| Sample / Path | Description | Used Components |
|---|---|---|
| **[aiinput_sample.lpr](AI Input/aiinput_sample.lpr)** | Command-line demonstration of data input/output handling using AI Input components. | - |

### ⌨️ AI Math

| Sample / Path | Description | Used Components |
|---|---|---|
| **[numps_sample.lpr](AI Math/numps_sample.lpr)** | Simple console application performing vector and matrix mathematical operations using NUMPS. | - |

### ⌨️ AI Output

| Sample / Path | Description | Used Components |
|---|---|---|
| **[aioutput_sample.lpr](AI Output/aioutput_sample.lpr)** | Console test for structured JSON and plaintext output generation components. | - |
| **[math_output_docs_demo.lpr](AI Output/math_output_docs_demo.lpr)** | Simplified mathematical document and spreadsheet generator via command line. | - |

### ⌨️ AI Voice

| Sample / Path | Description | Used Components |
|---|---|---|
| **[aivoicesynthesizer_sample.lpr](AI Voice/aivoicesynthesizer_sample.lpr)** | Direct console invocation of synchronous/asynchronous voice synthesis (TTS). | `TAIVoiceSynthesizer` |

## 🖼️ Screenshots Gallery

<p align="center">
  <img src="../../screenshots/ai_sqlite_query_assistant_demo.jpg" width="45%" alt="AI SQLite Query Assistant Demo" title="AI SQLite Query Assistant Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/cnn_classifier_complete_demo.jpg" width="45%" alt="CNN Classifier Complete Demo" title="CNN Classifier Complete Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/cnn_demo.jpg" width="45%" alt="CNN Demo" title="CNN Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/db_dicitionary_demo.jpg" width="45%" alt="Database Dictionary Demo" title="Database Dictionary Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/disk_tree_ai_dataset_demo.jpg" width="45%" alt="Disk Tree AI Dataset Demo" title="Disk Tree AI Dataset Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/docfilesmanager_demo.jpg" width="45%" alt="Doc Files Manager Demo" title="Doc Files Manager Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/image_info_demo.jpg" width="45%" alt="Image Info Demo" title="Image Info Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/math_input_output_demo.jpg" width="45%" alt="Math Input Output Demo" title="Math Input Output Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/pose_detector_demo.jpg" width="45%" alt="Pose Detector Demo" title="Pose Detector Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/python_demo.jpg" width="45%" alt="Python Playground Demo" title="Python Playground Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/python_runtime_check_demo.jpg" width="45%" alt="Python Runtime Check Demo" title="Python Runtime Check Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/som_demo.jpg" width="45%" alt="SOM Map Demo" title="SOM Map Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/sound_filters.jpg" width="45%" alt="Sound Filters Demo" title="Sound Filters Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/TAIFrameProcessor Demo.jpg" width="45%" alt="TAIFrameProcessor Demo" title="TAIFrameProcessor Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
  <img src="../../screenshots/voicesynthesizer.jpg" width="45%" alt="Voice Synthesizer Demo" title="Voice Synthesizer Demo" style="margin: 5px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" />
</p>
