# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌍 **Languages / Idiomas**

[Português](README.md) · [English](README_EN.md) · [Español](README_ES.md) · [Français](README_FR.md) · [Italiano](README_IT.md) · [العربية](README_AR.md) · [中文](README_CH.md) · [Русский](README_RU.md) · [日本語](README_JP.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Samples](https://img.shields.io/badge/samples-91%20PASS%20%2F%204%20FAIL-yellow.svg)]()

## Visão geral

**TCHATGPT** é uma suíte open source de componentes visuais e não visuais para **Lazarus / Free Pascal**. O projeto integra LLMs, modelos locais, Python, visão computacional, voz, grafos, arquivos, bancos de dados, documentos, agentes, sensores e automação industrial.

A suíte é uma camada de integração para aplicações Pascal. Ela não substitui frameworks especializados de treinamento, MLOps ou implantação de modelos em larga escala.

> [!WARNING]
> Um sample com `PASS` comprova compilação pelo `lazbuild`. Isso não comprova automaticamente execução de hardware, APIs, modelos externos, DLLs ou comportamento completo em runtime. O backend real de `TAIHumanPoseDetector` exige plataforma 64-bit.

## Situação factual da compilação

Resultado produzido pelo **AI Framework Graph Explorer**:

```text
Ambiente: Windows Win32 / i386
Free Pascal: 3.2.2
Samples encontrados: 95
PASS: 91
FAIL: 4
Taxa de sucesso: 95,8%
Grafo factual: 534 nós e 2.209 arestas
```

A matriz técnica complementar está em:

```text
pacote/COMPONENT_STATUS.md
```

## Regra de maturidade baseada nos samples

| Status | Regra |
|---|---|
| **Stable / Beta** | O componente possui ao menos um sample associado que compilou com `exit code 0`. |
| **Experimental** | O sample associado falhou e o componente ainda não possui evidência independente de compilação. |
| **Placeholder** | A estrutura existe, mas ainda não entrega a funcionalidade real completa. |
| **Deprecated** | Mantido somente por compatibilidade. |

Quando um componente aparece em um sample composto que falhou, mas também possui sample dedicado com `PASS`, prevalece a evidência dedicada. A integração composta continua Experimental.

## Pacotes modulares

Os pacotes ficam em:

```text
pacote/packages/
```

| Pacote | Finalidade | Status atual |
|---|---|---|
| `openai_core.lpk` | LLM, base, tokenização, prompts, registro de modelos e agenda | Stable / Beta |
| `openai_python.lpk` | Python, CNN, LSTM, YOLO, face detection e runtime | Stable / Beta |
| `openai_ml.lpk` | Machine learning e matemática em Pascal | Stable / Beta |
| `openai_graph.lpk` | Grafos, análise, visualização, exportação e relatórios | Stable / Beta |
| `openai_files.lpk` | Inventário, varredura e gestão de arquivos | Stable / Beta |
| `openai_output.lpk` | Texto, JSON, PDF, Word/OpenXML, Excel e visualização | Stable / Beta |
| `openai_input.lpk` | Captura, Chromium, USB, Kinect, serial, sockets, web e e-mail | Stable / Beta; integração `hardware_net_demo` Experimental |
| `openai_vision.lpk` | Visão nativa, OpenCV, câmera e MediaPipe | Stable / Beta |
| `openai_image.lpk` | Filtros de imagem nativos | Stable / Beta |
| `openai_voice.lpk` | Áudio, filtros, reconhecimento e síntese de voz | Stable / Beta |
| `openai_simulation.lpk` | Simulação 2D, entidades, regras e movimento | Stable / Beta por compilação |
| `openai_industrial.lpk` | Modbus, MQTT, pinmap, bridge e POS | Stable / Beta |
| `openai_graphic.lpk` | 3D, avatares, física, cenas, poses e Tripo3D | Stable / Beta |
| `openai_agent.lpk` | Agentes, memória, ações, segurança e pipeline | Stable / Beta; `TAIPipeline` e `TAIWizardConfig` Experimental |
| `openai_project.lpk` | Projetos, tarefas, armazenamento e especificações | Stable / Beta; integração de pipeline Experimental |
| `openai_aidbase.lpk` | Dicionários e metadados de bancos de dados | Stable / Beta |

> O pacote monolítico legado `openai.lpk` foi removido. Use somente os pacotes modulares.

## Associação completa entre samples e componentes

A tabela foi construída relacionando cada projeto encontrado pelo Graph Explorer com os componentes que ele instancia ou demonstra.

| Pacote/área | Status | Componentes com evidência PASS | Samples PASS | Samples FAIL |
|---|---|---|---|---|
| openai_agent | Stable / Beta + Experimental | `TAIActionBuilderAgent`<br>`TAIAgent`<br>`TAIAgentMemoryMap`<br>`TAIAgentSerial`<br>`TAIClassifierAgent`, `TAIDecisionAgent`, `TAIActionBuilderAgent`, `TAIAgentMemoryMap`, `TAIActionExecutor` | `action_builder_recovery_test`, `agent_demo`, `agent_memorymap_demo`, `agent_serial_demo`, `agent_task_memory_action_demo` | `pipeline_full_demo`, `wizard_config_demo` |
| openai_aidbase | Stable / Beta | `TAISQLiteDictionary`, `TCHATGPT`<br>`TAIPostgreSQLDictionary`, `TAISQLiteDictionary` | `ai_sqlite_query_assistant_demo`, `db_dictionary_demo` | — |
| openai_core | Stable / Beta | `TAICodeAssistant`, `TCHATGPT`<br>`TAIModelRegistry`<br>`TAIPromptBuilder`<br>`IASchedule`<br>`TTokenList` | `codeassistant_demo`, `modelregistry_demo`, `promptbuilder_demo`, `schedule_demo`, `tokenizer_demo` | — |
| openai_core + openai_ml | Stable / Beta | playground visual multi-componente | `visual_demo` | — |
| openai_files | Stable / Beta | `TAIDiskTreeScanner`<br>`TAI_DOCFILESMANAGER` | `disk_tree_ai_dataset_demo`, `docfilesmanager_demo` | — |
| openai_graph | Stable / Beta | `TAIDatasetAnalyzer`<br>`TAIGraphVisualizer`<br>`TAIGraphMap`<br>`TAITrainingExporter`<br>`TAITrainingReport` | `dataset_analyzer_demo`, `graph_visualizer_demo`, `graphmap_basic`, `training_exporter_demo`, `training_report_demo`, `graphmap_demo` | — |
| openai_graphic | Stable / Beta | `TAIAvatar3D`, `TAIAvatarController`<br>`TAI3DModelViewer`, `TAIModel3D`<br>componentes gráficos OpenGL<br>`TAIPhysicsSimulator`, `TAITrainingEnvironment`<br>`TAIPoseLibrary`, `TAIAnimationSequence`<br>`TAIScene3D`<br>`TAISkeletonRig`<br>`TAITripo3DClient` | `avatar_demo`, `model3d_viewer_demo`, `opengl_graphic_demo`, `physics_training_demo`, `pose_animation_demo`, `scene3d_demo`, `skeleton_rig_demo`, `tripo3d_demo` | — |
| openai_image | Stable / Beta | `TGrayscaleFilter`, `TNegativeFilter`, `TBrightnessContrastFilter`, `TBinarizationFilter`, `TBlurFilter`, `TSharpenFilter`, `TSobelFilter`, `TErosionDilationFilter` | `image_filters_demo` | — |
| openai_industrial | Stable / Beta | `TAIModbusClient`, mapa de pinos e mapa de comandos<br>`TAIIndustrialBridge`<br>`TAIModbusClient`<br>`TAIMQTTClient`<br>`TAIPOSPrinter` | `arduino_modbus_pinmap_demo`, `industrial_bridge_demo`, `modbus_demo`, `mqtt_demo`, `posprinter_demo` | — |
| openai_input | Stable / Beta + Experimental | gerenciador de hardware da suíte<br>`TAIUSB`<br>`TAICaptureSource`<br>`TAIChromiumBrowser`<br>`TAIEmailClient` e classificação de mensagens<br>`TAIKinectSensor`, `TAIKinectColorStream`, `TAIKinectDepthStream`<br>`TAIKinectColorStream`<br>bridge direto da Kinect SDK 1.0<br>`TAIKinectSkeleton`<br>`TAISerialModem` e enumeração de portas<br>`TAISocketTCP`, `TAISocketUDP`<br>`TAIWebAPIServer` | `hardware_system_manager_demo`, `aiusb_devices_demo`, `capture_source_demo`, `chromium_capture_demo`, `email_classifier_demo`, `kinect_capture_demo`, `kinect_frame_capture_test`, `kinect_sdk10_direct_frame_test`, `kinect_skeleton_demo`, `serial_demo`, `socket_server_client_demo`, `webserver_demo` | `hardware_net_demo` |
| openai_input + openai_output | Stable / Beta | `TAIInputData`, `TAIOutputData` | `math_input_output_demo` | — |
| openai_ml | Stable / Beta | `TAIDatasetGenerator`<br>`TAMatrizComponent`<br>`TNumPS`<br>`TNeuralNetwork`<br>`TPerceptron`<br>`TSOMMap` | `dataset_generator_visual_demo`, `matrix_component_demo`, `numps_demo`, `neural_network_demo`, `perceptron_demo`, `som_demo` | — |
| openai_output | Stable / Beta | `TAIOutputDocs`<br>`TAIOutputData`<br>`TAIPDFOutput`, `TAIWordOutput`, `TAIExcelOutput`<br>componentes OpenXML de documento Word<br>`TAIWordViewer` | `output_docs_demo`, `output_text_json_demo`, `pdf_word_excel_demo`, `word_object_demo`, `word_viewer_demo` | — |
| openai_project | Stable / Beta | `TAIProject`, `TAIProjectTasks`, `TAIProjectStorage`, `TAIProjectSpecification`<br>`TAIProjectTasks`, `TAIProjectStorage`, `TAIProjectSpecification` | `Demo_AI_Project`, `project_tasklist_ai_demo` | — |
| openai_project + openai_agent | Stable / Beta + Experimental |  |  | `pipeline_project_demo` |
| openai_project + openai_graph + openai_files | Stable / Beta | `TCHATGPT`, `TAIDiskTreeScanner`, `TAIDependencyGraph`, `TAIGraphStructuralAdapter` | `framework_graph_explorer` | — |
| openai_python | Stable / Beta | `TCNNClassifier`<br>`TLSTMPredictor`<br>`TAIPythonRuntime`<br>`TYoloDetect`<br>`TFaceDetection`<br>`TPythonConnector` | `cnn_classifier_complete_demo`, `lstm_timeseries_demo`, `python_runtime_check_demo`, `yolo_detection_complete_demo`, `cnn_demo`, `face_detection_demo`, `lstm_demo`, `python_demo`, `yolo_demo` | — |
| openai_simulation | Stable / Beta | `TAISimulationEngine`, `TAIRuleEngine`, `TAITriggerEngine`, `TAISimulationStats`<br>`TAIGridWorld`, `TAIMovementEngine`, `TAIRuleEngine`<br>`TAIGridWorld`, `TAISimEntity`, `TAISimulationEngine`, `TAISimulationStats`<br>`TAIGridWorld`, `TAIEntityFactory`, `TAIMovementEngine` | `contamination_demo`, `robot_grid_demo`, `service_queue_demo`, `warehouse_agents_demo` | — |
| openai_vision | Stable / Beta | `TAIHumanPoseDetector`<br>`TAIMotionTracker`<br>`TAINativeImageFilter`<br>`TAIFrameProcessor`<br>backend `aicamera_vfw`<br>`TAIFrameDiff`<br>`TAIImageInfo`<br>`TAIOpenCV`<br>`TAIOpenCV`, `aiopencvruntime`<br>`TAIOpenCV`, recursos de câmera e rastreamento | `human_pose_detector_demo`, `motion_tracker_demo`, `native_image_filter_demo`, `aiframeprocessor_demo`, `camera_capture_windows_demo`, `frame_diff_demo`, `image_info_demo`, `opencv_filter_demo`, `opencv_image_real_demo`, `opencv_vision_demo` | — |
| openai_voice | Stable / Beta | `SoundFilters`<br>`TAIAudioInput`<br>`TAISpeechRecognizer`<br>`TAIVoiceSynthesizer` | `sound_filters_demo`, `audio_capture_demo`, `sound_filters_visual_demo`, `speech_recognizer_demo`, `voice_synthesizer_complete_demo`, `voicesynthesizer_demo` | — |

## Falhas que mantêm componentes ou integrações como Experimental

| Sample | Classificação | Componentes/integração | Falha observada |
|---|---|---|---|
| `pipeline_full_demo` | Experimental | `TAIPipeline`, integração com `TCHATGPT`, `TAIOutputData` e `TAIOutputDocs` | `uCEFChromiumWindow` não encontrado; também existem PPUs e units duplicadas nos caminhos. |
| `wizard_config_demo` | Experimental | `TAIWizardConfig`, `TAIPipeline`, `TAIProject`, `TCHATGPT` | `uCEFChromiumWindow` não encontrado. |
| `hardware_net_demo` | Experimental como integração | Chromium, captura, MQTT, e-mail, Modbus, bridge industrial e áudio | `uCEFChromiumWindow` não encontrado. Os componentes com samples dedicados permanecem Stable/Beta. |
| `pipeline_project_demo` | Experimental como integração | `TAIProject`, `TAIPipeline`, LLM, ML, input e output | Dependência quebrada do pacote legado `openai`. |

### Componentes reclassificados por evidência de compilação

A relação abaixo é a classificação completa obtida pelo cruzamento entre os samples e os componentes diretamente utilizados por eles. Um componente só entra nesta relação quando existe evidência direta no sample; dependências carregadas apenas de forma transitiva não são usadas para promover o status.

#### Stable / Beta — componentes com pelo menos um sample `PASS`

| Pacote/área | Componentes reclassificados como Stable / Beta |
|---|---|
| **AI Hardware** | `TAICPU`, `TAIMemory`, `TAIGPU`, `TAIDisk`, `TAIOS`, `TAITasks` |
| **openai_core** | `TCHATGPT`, `TTokenList`, `TAICodeAssistant`, `TAIPromptBuilder`, `TAIModelRegistry`, `IASchedule` |
| **openai_agent** | `TAIActionBuilderAgent`, `TAIAgent`, `TAIAgentMemoryMap`, `TAIAgentSerial`, `TAIClassifierAgent`, `TAIDecisionAgent`, `TAIActionExecutor` |
| **openai_aidbase** | `TAIPostgreSQLDictionary`, `TAISQLiteDictionary` |
| **openai_files** | `TAIDiskTreeScanner`, `TAI_DOCFILESMANAGER` |
| **openai_graph** | `TAIGraphMap`, `TAIDependencyGraph`, `TAIGraphStructuralAdapter`, `TAIDatasetAnalyzer`, `TAIGraphVisualizer`, `TAITrainingExporter`, `TAITrainingReport` |
| **openai_graphic** | `TAIAvatar3D`, `TAIAvatarController`, `TAI3DModelViewer`, `TAIModel3D`, `TAIPhysicsSimulator`, `TAITrainingEnvironment`, `TAIPoseLibrary`, `TAIAnimationSequence`, `TAIScene3D`, `TAISkeletonRig`, `TAITripo3DClient` |
| **openai_image** | `TGrayscaleFilter`, `TNegativeFilter`, `TBrightnessContrastFilter`, `TBinarizationFilter`, `TBlurFilter`, `TSharpenFilter`, `TSobelFilter`, `TErosionDilationFilter` |
| **openai_industrial** | `TAIArduinoModbusPinMap`, `TAIModbusCommandMap`, `TAIModbusClient`, `TAIIndustrialBridge`, `TAIMQTTClient`, `TAIPOSPrinter` |
| **openai_input** | `TAIUSB`, `TAICaptureSource`, `TAIChromiumBrowser`, `TAIEmailClient`, `TAIKinectSensor`, `TAIKinectColorStream`, `TAIKinectDepthStream`, `TAIKinectSkeleton`, `TAISerialModem`, `TAISocketTCP`, `TAISocketUDP`, `TAIWebAPIServer` |
| **openai_input / openai_output** | `TAIInputData`, `TAIOutputData` |
| **openai_ml** | `TAIDatasetGenerator`, `TAMatrizComponent`, `TNumPS`, `TNeuralNetwork`, `TPerceptron`, `TSOMMap` |
| **openai_output** | `TAIOutputDocs`, `TAIOutputData`, `TAIPDFOutput`, `TAIWordOutput`, `TAIExcelOutput`, `TAIWordDocument`, `TAIWordViewer` |
| **openai_project** | `TAIProject`, `TAIProjectTasks`, `TAIProjectStorage`, `TAIProjectSpecification` |
| **openai_python** | `TPythonConnector`, `TAIPythonRuntime`, `TCNNClassifier`, `TFaceDetection`, `TLSTMPredictor`, `TYoloDetect` |
| **openai_simulation** | `TAIGridWorld`, `TAISimEntity`, `TAIEntityFactory`, `TAISimulationEngine`, `TAIRuleEngine`, `TAITriggerEngine`, `TAIMovementEngine`, `TAISimulationStats` |
| **openai_vision** | `TAIHumanPoseDetector`, `TAIMotionTracker`, `TAINativeImageFilter`, `TAIFrameProcessor`, `TAIFrameDiff`, `TAIImageInfo`, `TAIOpenCV` |
| **openai_voice** | `SoundFilters`, `TAIAudioInput`, `TAISpeechRecognizer`, `TAIVoiceSynthesizer` |

#### Experimental — componentes sem evidência independente de `PASS`

| Componente | Samples associados | Motivo |
|---|---|---|
| `TAIPipeline` | `pipeline_full_demo`, `pipeline_project_demo` | Os dois samples que validam diretamente o pipeline falharam. |
| `TAIWizardConfig` | `wizard_config_demo` | O sample dedicado falhou durante a compilação. |

#### Integrações compostas que permanecem Experimental

| Integração | Sample | Observação |
|---|---|---|
| Pipeline completo com LLM e documentos | `pipeline_full_demo` | Falhou por dependência do Chromium/CEF e por caminhos contendo units/PPUs duplicadas. |
| Assistente visual de configuração | `wizard_config_demo` | Falhou ao resolver `uCEFChromiumWindow`. |
| Hardware, rede e automação reunidos | `hardware_net_demo` | A integração falhou, mas seus componentes individuais permanecem Stable/Beta porque possuem samples dedicados com `PASS`. |
| Projeto integrado ao pipeline | `pipeline_project_demo` | Falhou por dependência do pacote monolítico legado `openai`. |

#### Componentes presentes em samples que falharam, mas mantidos como Stable / Beta

`TAIChromiumBrowser`, `TAICaptureSource`, `TAIMQTTClient`, `TAIEmailClient`, `TAIModbusClient`, `TAIIndustrialBridge`, `TAIAudioInput`, `TAIProject`, `TCHATGPT`, `TNeuralNetwork`, `TAIInputData`, `TAIOutputData`, `TAIOutputDocs` e `TAIPromptBuilder` possuem evidência independente em outros samples com `PASS`.

> Componentes sem sample diretamente associado não são reclassificados por este relatório. Eles conservam o status registrado em `pacote/COMPONENT_STATUS.md` até receberem um sample verificável.

## Principais componentes

### Core e agentes

`TAIBaseComponent`, `TCHATGPT`, `TTokenList`, `TAICodeAssistant`, `TAIPromptBuilder`, `TAIModelRegistry`, `IASchedule`, `TAIAgent`, `TAIAgentMemoryMap`, `TAIAgentSerial`, `TAIActionBuilderAgent`, `TAIDecisionAgent`, `TAIActionExecutor`, `TAIAgentSafety`, `TAIPipeline` e `TAIWizardConfig`.

> `TAIPipeline` e `TAIWizardConfig` pertencem ao pacote `openai_agent.lpk` e permanecem Experimental.

### Projeto, arquivos e grafos

`TAIProject`, `TAIProjectSpecification`, `TAIProjectTasks`, `TAIProjectStorage`, `TAIProjectLLMConfig`, `TAIDiskTreeScanner`, `TAI_DOCFILESMANAGER`, `TAIGraphMap`, `TAIDependencyGraph`, `TAIGraphStructuralAdapter`, `TAIDatasetAnalyzer`, `TAITrainingExporter`, `TAITrainingReport` e `TAIGraphVisualizer`.

### Input e industrial

`TAICaptureSource`, `TAIChromiumBrowser`, `TAIUSB`, `TAISerialModem`, `TAISocketTCP`, `TAISocketUDP`, `TAIWebAPIServer`, `TAIEmailClient`, `TAIKinectSensor`, `TAIKinectColorStream`, `TAIKinectDepthStream`, `TAIKinectSkeleton`, `TAIModbusClient`, `TAIMQTTClient`, `TAIIndustrialBridge` e `TAIPOSPrinter`.

### Visão, imagem e voz

`TAIFrameProcessor`, `TAINativeImageFilter`, `TAIImageInfo`, `TAIFrameBuffer`, `TAIMotionTracker`, `TAIFrameDiff`, `TAIFaceTracker`, `TAIOpenCV`, `TAIHumanPoseDetector`, `TAIAudioInput`, `TAISpeechRecognizer`, `TAIVoiceSynthesizer` e `SoundFilters`.

### ML, Python, 3D e simulação

`TNeuralNetwork`, `TPerceptron`, `TSOMMap`, `TAIDatasetGenerator`, `TAMatrizComponent`, `TNumPS`, `TPythonConnector`, `TAIPythonRuntime`, `TCNNClassifier`, `TFaceDetection`, `TLSTMPredictor`, `TYoloDetect`, `TAI3DModelViewer`, `TAIModel3D`, `TAIAvatar3D`, `TAIScene3D`, `TAITripo3DClient`, `TAIPhysicsSimulator`, `TAIGridWorld`, `TAISimulationEngine`, `TAIRuleEngine`, `TAITriggerEngine`, `TAIMovementEngine` e `TAISimulationStats`.

## Instalação

### Dependências externas principais

1. **ZeosLib** — necessária para os componentes de banco de dados (`zcomponent.lpk`).
2. **CEF4Delphi** — necessária para `TAIChromiumBrowser` (`cef4delphi_lazarus.lpk`).
3. **Python e bibliotecas opcionais** — necessários para Python, OpenCV, CNN, LSTM, YOLO e backends equivalentes.

### Ordem recomendada

```text
1.  openai_core.lpk
2.  openai_python.lpk
3.  openai_ml.lpk
4.  openai_files.lpk
5.  openai_output.lpk
6.  openai_input.lpk
7.  openai_industrial.lpk
8.  openai_vision.lpk
9.  openai_voice.lpk
10. openai_graphic.lpk
11. openai_simulation.lpk
12. openai_agent.lpk
13. openai_project.lpk
14. openai_graph.lpk
15. openai_aidbase.lpk
```

A ordem final deve respeitar as dependências registradas nos próprios arquivos `.lpk`.

## AI Framework Graph Explorer

O sample `pacote/samples/AI Project/framework_graph_explorer/` analisa o próprio repositório e produz:

* inventário de arquivos;
* pacotes, units e dependências;
* componentes registrados;
* associação componente/sample;
* compilação real por `lazbuild`;
* histórico e regressões;
* relatórios JSON, TXT, DOT e Mermaid;
* análise opcional por IA separada dos fatos determinísticos.

A IA não decide se um componente existe ou compilou. Essas informações vêm dos parsers e do código de saída do compilador.

## Provedores de LLM

| Provedor | Enum | Tipo |
|---|---|---|
| OpenAI | `AIP_OPENAI` | API externa |
| OpenRouter | `AIP_OPENROUTER` | Agregador |
| Cerebras | `AIP_CEREBRAS` | API externa |
| Google Gemini | `AIP_GEMINI` | API externa |
| Anthropic Claude | `AIP_CLAUDE` | API externa |
| Ollama/local/compatível | `AIP_LOCAL` | Servidor local |

## Screenshots

[Agent Serial Demo](pacote/samples/AI%20Agent/agent_serial_demo/README.md)

![Agent Serial Demo](screenshots/agent_serial_demo.JPG)

![AI Project Demo](screenshots/project_tasklist_ai.jpg)

![CNN Demo](screenshots/cnn_demo.jpg)

![Python Demo](screenshots/python_demo.jpg)

![Sound Filters](screenshots/sound_filters.jpg)

![Voice Synthesizer](screenshots/voicesynthesizer_demo.jpg)

![Disk Tree AI Dataset Demo](screenshots/disk_tree_ai_dataset_demo.jpg)

![DB Dictionary Demo](screenshots/db_dicitionary_demo.jpg)

![AI SQLite Query Assistant Demo](screenshots/ai_sqlite_query_assistant_demo.jpg)

## Limitações conhecidas

* `PASS` de compilação não substitui teste funcional.
* A execução atual foi Win32/i386; componentes 64-bit precisam de validação separada.
* Integrações externas dependem de APIs, runtimes, DLLs, modelos e permissões.
* PPUs antigas e caminhos duplicados podem gerar dependências incorretas.
* Os quatro samples com falha precisam ser corrigidos antes de uma release totalmente verde.

## Roadmap imediato

* corrigir os quatro samples com falha;
* remover referências ao pacote legado `openai`;
* eliminar PPUs órfãs e units duplicadas;
* executar a matriz em Windows 64-bit e Linux 64-bit;
* gerar automaticamente esta classificação pelo Graph Explorer;
* publicar releases versionadas com relatório factual anexado.

## Contribuindo

Contribuições são bem-vindas em correções, samples, testes, documentação, compatibilidade Windows/Linux, segurança de agentes e integração com provedores.

## Licença

GNU General Public License v3.0. Consulte `LICENSE`.

## Aviso

Serviços externos podem envolver custos, limites de API e envio de dados para terceiros. Proteja suas chaves, não envie dados sensíveis sem autorização e valide segurança, privacidade e conformidade antes do uso em produção.
