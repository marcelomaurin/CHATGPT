# Component Status Matrix

Esta matriz registra o estado atual dos principais componentes da **Lazarus AI Suite**.

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
| `TAIWizardConfig` | `aiwizardconfig.pas` | `openai_core` | Experimental | Assistente de configuração |
| `TAIProject` | `aiproject.pas` | `openai_core` | Experimental | Estrutura de projeto IA |
| `TAIPipeline` | `aipipeline.pas` | `openai_core` | Experimental | Orquestra vários módulos e ainda deve ser desacoplado |

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

---

## Vision

| Componente/Unit | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIOpenCV` | `aiopencv.pas` | `openai_vision` | Beta/Parcial | Funcional via worker Python; backend Native DLL localiza/carrega DLL/SO, mas processamento nativo real ainda é simulado |
| `aiopencvruntime` | `aiopencvruntime.pas` | `openai_vision` | Beta | Helper de busca inteligente para `opencv_world*.dll` e `libopencv_world.so*` por SO/arquitetura |
| `TAICameraCapture` | `aicameracapture.pas` | `openai_vision` | Experimental | Captura nativa via Windows VFW e backend Linux V4L2; precisa validação ampla por plataforma |
| `TAIFrameProcessor` | `aiframeprocessor.pas` | `openai_vision` | Experimental | Processamento de frames em evolução |
| `TAIFaceTracker` | `aifacetracker.pas` | `openai_vision` | Experimental | Rastreamento por template matching (SAD) 100% nativo |
| `TAIMotionTracker` | `aimotiontracker.pas` | `openai_vision` | Experimental | Detecção de movimento por variação de luminância 100% nativa |
| `TAIImageInfo` | `aiimageinfo.pas` | `openai_vision` | Experimental | Extração nativa de metadados e contagem de pixels de imagem |
| `TAIFrameBuffer` | `aiframebuffer.pas` | `openai_vision` | Experimental | Buffer de frames circular em memória para processamento de vídeo |
| `TAINativeImageFilter` | `ainativeimagefilter.pas` | `openai_vision` | Experimental | Filtros rápidos de pixel (Cinza, Limiar, Inverter, Resize, Blur) 100% nativos |
| `TAIFrameDiff` | `aiframediff.pas` | `openai_vision` | Experimental | Geração nativa de diferença absoluta de pixels entre frames |

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

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIGridWorld` | `aigridworld.pas` | `openai_simulation` | Experimental | Mundo 2D baseado em grade |
| `TAIGridCell` | `aigridcell.pas` | `openai_simulation` | Experimental | Tipo auxiliar de representação de célula |
| `TAIGridBuffer` | `aigridbuffer.pas` | `openai_simulation` | Experimental | Tipo auxiliar de duplo buffer |
| `TAISimEntity` | `aisimentity.pas` | `openai_simulation` | Experimental | Entidade ativa base de simulação |
| `TAIEntityFactory` | `aientityfactory.pas` | `openai_simulation` | Experimental | Fábrica de criação de agentes |
| `TAISimulationEngine` | `aisimulationengine.pas` | `openai_simulation` | Experimental | Motor de ciclo principal da simulação |
| `TAIRuleEngine` | `airuleengine.pas` | `openai_simulation` | Experimental | Motor de gerenciamento de regras comportamentais |
| `TAITriggerEngine` | `aitriggerengine.pas` | `openai_simulation` | Experimental | Motor de eventos e loggers |
| `TAIMovementEngine` | `aimovementengine.pas` | `openai_simulation` | Experimental | Motor de caminhada e busca 2D |
| `TAIEvolutionEngine` | `aievolutionengine.pas` | `openai_simulation` | Experimental | Mecanismos de mutação e adaptação genética |
| `TAISimulationStats` | `aisimulationstats.pas` | `openai_simulation` | Experimental | Coletor de métricas e ciclo de execução |
| `TAIGridRenderer2D` | `aigridrenderer2d.pas` | `openai_simulation` | Experimental | Desenho nativo 2D da simulação em TCanvas |
| `TAIScenarioConfig` | `aiscenarioconfig.pas` | `openai_simulation` | Experimental | Salvar/carregar layouts em JSON |
| `TAIScenarioGenerator` | `aiscenariogenerator.pas` | `openai_simulation` | Experimental | Criador de cenários baseado em prompt com ChatGPT |
| `TAISimulationExporter` | `aisimulationexporter.pas` | `openai_simulation` | Experimental | Exportador de relatórios (CSV, TXT, JSON) |

---

## Legacy

| Componente/Pacote | Caminho | Status | Observação |
|---|---|---|---|
| `openai.lpk` | `pacote/openai.lpk` | Deprecated | Wrapper legado para compatibilidade; preferir pacotes em `pacote/packages/` |
