# Índice de Componentes

Este índice lista os componentes documentados individualmente.

---

## Core

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TAIBaseComponent` | [`TAIBaseComponent`](TAIBaseComponent/) | `aibase.pas` | `openai_core` | Stable |
| `TCHATGPT` | [`TCHATGPT`](TCHATGPT/) | `chatgpt.pas` | `openai_core` | Beta |
| `TTokenList` | [`TTokenList`](TTokenList/) | `tokenizer.pas` | `openai_core` | Beta/Legacy |
| `TAICodeAssistant` | [`TAICodeAssistant`](TAICodeAssistant/) | `aicodeassistant.pas` | `openai_core` | Beta |
| `TAIPromptBuilder` | [`TAIPromptBuilder`](TAIPromptBuilder/) | `aipromptbuilder.pas` | `openai_core` | Beta |
| `TAIModelRegistry` | [`TAIModelRegistry`](TAIModelRegistry/) | `aimodelregistry.pas` | `openai_core` | Experimental |
| `TAIWizardConfig` | [`TAIWizardConfig`](TAIWizardConfig/) | `aiwizardconfig.pas` | `openai_core` | Experimental |
| `TAIProject` | [`TAIProject`](TAIProject/) | `aiproject.pas` | `openai_core` | Experimental |
| `TAIPipeline` | [`TAIPipeline`](TAIPipeline/) | `aipipeline.pas` | `openai_core` | Experimental |

---

## ML / Math

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TNeuralNetwork` | [`TNeuralNetwork`](TNeuralNetwork/) | `neuralnetwork.pas` | `openai_ml` | Beta |
| `TPerceptron` | [`TPerceptron`](TPerceptron/) | `perceptron.pas` | `openai_ml` | Beta |
| `TSOMMap` | [`TSOMMap`](TSOMMap/) | `sommap.pas` | `openai_ml` | Experimental |
| `TAIDatasetGenerator` | [`TAIDatasetGenerator`](TAIDatasetGenerator/) | `aidatasetgenerator.pas` | `openai_ml` | Beta |
| `TAMatrizComponent` | [`TAMatrizComponent`](TAMatrizComponent/) | `matrizcomponent.pas` | `openai_ml` | Beta |
| `TNumPS` | [`TNumPS`](TNumPS/) | `numps.pas` | `openai_ml` | Beta |

---

## Graph

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TAIGraphMap` | [`TAIGraphMap`](TAIGraphMap/) | `aigraphmap.pas` | `openai_graph` | Beta |
| `TAITrainingExporter` | [`TAITrainingExporter`](TAITrainingExporter/) | `aitrainingexporter.pas` | `openai_graph` | Experimental |
| `TAIDatasetAnalyzer` | [`TAIDatasetAnalyzer`](TAIDatasetAnalyzer/) | `aidatasetanalyzer.pas` | `openai_graph` | Experimental |
| `TAITrainingReport` | [`TAITrainingReport`](TAITrainingReport/) | `aitrainingreport.pas` | `openai_graph` | Experimental |
| `TAIGraphVisualizer` | [`TAIGraphVisualizer`](TAIGraphVisualizer/) | `aigraphvisualizer.pas` | `openai_graph` | Experimental |

---

## Python

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TPythonConnector` | [`TPythonConnector`](TPythonConnector/) | `pythonconnector.pas` | `openai_core` | Experimental/Beta |
| `TYoloDetect` | [`TYoloDetect`](TYoloDetect/) | `yolodetect.pas` | `openai_core` | Experimental |
| `TFaceDetection` | [`TFaceDetection`](TFaceDetection/) | `facedetection.pas` | `openai_core` | Experimental |
| `TCNNClassifier` | [`TCNNClassifier`](TCNNClassifier/) | `cnnclassifier.pas` | `openai_core` | Experimental |
| `TLSTMPredictor` | [`TLSTMPredictor`](TLSTMPredictor/) | `lstmpredictor.pas` | `openai_core` | Experimental |

---

## Vision

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TAIOpenCV` | [`TAIOpenCV`](TAIOpenCV/) | `aiopencv.pas` | `openai_vision` | Beta |
| `TAIFrameProcessor` | [`TAIFrameProcessor`](TAIFrameProcessor/) | `aiframeprocessor.pas` | `openai_vision` | Experimental |
| `TAIFaceTracker` | [`TAIFaceTracker`](TAIFaceTracker/) | `aifacetracker.pas` | `openai_vision` | Placeholder |
| `TAIMotionTracker` | [`TAIMotionTracker`](TAIMotionTracker/) | `aimotiontracker.pas` | `openai_vision` | Placeholder |
| `TAIHumanPoseDetector` | [`TAIHumanPoseDetector`](TAIHumanPoseDetector/) | `aihumanposedetector.pas` | `openai_vision` | Beta |

---

## Output

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TAIOutputData` | [`TAIOutputData`](TAIOutputData/) | `aioutput.pas` | `openai_output` | Beta |
| `TAIOutputDocs` | [`TAIOutputDocs`](TAIOutputDocs/) | `aioutput_docs.pas` | `openai_output` | Beta |
| `TAIPDFOutput` | [`TAIPDFOutput`](TAIPDFOutput/) | `aioutput_docs.pas` | `openai_output` | Beta |
| `TAIWordOutput` | [`TAIWordOutput`](TAIWordOutput/) | `aioutput_docs.pas` | `openai_output` | Beta/Compatível |
| `TAIExcelOutput` | [`TAIExcelOutput`](TAIExcelOutput/) | `aioutput_docs.pas` | `openai_output` | Beta/Compatível |
| `TAITXTOutput` | [`TAITXTOutput`](TAITXTOutput/) | `aioutput_docs.pas` | `openai_output` | Stable/Beta |

---

## Agent

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TAIAgent` | [`TAIAgent`](TAIAgent/) | `aiagent.pas` | `openai_agent` | Experimental |
| `TAIAgentSafety` | [`TAIAgentSafety`](TAIAgentSafety/) | `aiagentsafety.pas` | `openai_agent` | Beta |
| `TAIAgentExecutor` | [`TAIAgentExecutor`](TAIAgentExecutor/) | `aiagent_executors.pas` | `openai_agent` | Experimental |

---

## Graphic / 3D

| Componente | Documentação | Unit | Pacote | Status |
|---|---|---|---|---|
| `TAI3DModelViewer` | [`TAI3DModelViewer`](TAI3DModelViewer/) | `ai3dmodelviewer.pas` | `openai_graphic` | Beta/Experimental |
| `TAIModel3D` | [`TAIModel3D`](TAIModel3D/) | `aimodel3d.pas` | `openai_graphic` | Beta/Experimental |
| `TAITripo3DClient` | [`TAITripo3DClient`](TAITripo3DClient/) | `aitripo3dclient.pas` | `openai_graphic` | Experimental |
| `TAIAvatar3D` | [`TAIAvatar3D`](TAIAvatar3D/) | `aiavatar3d.pas` | `openai_graphic` | Experimental |
| `TAIScene3D` | [`TAIScene3D`](TAIScene3D/) | `aiscene3d.pas` | `openai_graphic` | Experimental |