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

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIOpenCV` | `aiopencv.pas` | `openai_vision` | Beta | Funcional via worker Python; sample disponível |
| `TAICameraCapture` | `aicameracapture.pas` | `openai_vision` | Experimental | Funcional via worker Python; captura real implementada |
| `TAIFrameProcessor` | `aiframeprocessor.pas` | `openai_vision` | Experimental | Processamento de frames em evolução |
| `TAIFaceTracker` | `aifacetracker.pas` | `openai_vision` | Placeholder | Rastreamento real ainda precisa implementação/validação |
| `TAIMotionTracker` | `aimotiontracker.pas` | `openai_vision` | Placeholder | Detecção real ainda precisa implementação/validação |

---

## Output

| Componente | Unit | Pacote | Status | Observação |
|---|---|---|---|---|
| `TAIOutputData` | `aioutput.pas` | `openai_output` | Beta | Saída estruturada |
| `TAIOutputDocs` | `aioutput_docs.pas` | `openai_output` | Beta | Documentos; revisar formatos reais gerados |
| `TAIPDFOutput` | `aioutput_docs.pas` | `openai_output` | Beta | PDF via FPC/fpPDF |
| `TAIWordOutput` | `aioutput_docs.pas` | `openai_output` | Beta/Compatível | Verificar se gera DOCX real ou HTML compatível |
| `TAIExcelOutput` | `aioutput_docs.pas` | `openai_output` | Beta/Compatível | Verificar se gera XLSX real ou HTML compatível |
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

## Legacy

| Componente/Pacote | Caminho | Status | Observação |
|---|---|---|---|
| `openai.lpk` | `pacote/openai.lpk` | Deprecated | Wrapper legado para compatibilidade; preferir pacotes em `pacote/packages/` |
