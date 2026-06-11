# 🧠 AI Component Suite Package

> [!NOTE]
> This directory contains the implementation of the official AI & Automation component suite for Lazarus/Delphi. This suite integrates Artificial Intelligence, Machine Learning, hardware automation, networking, audio, imaging, and document processing natively and cross-platform through modular packages.

## Core Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TCHATGPT** | Universal cloud LLM and local server OpenAI connector. | `APIKey, Provider, TipoChat, CustomModel, MaxTokens` | `SendQuestion(ASK): Boolean, TipoModelo: string` | Process natural language and generate cognitive responses. |
| **TNeuralNetwork** | Native Multilayer Perceptron Neural Network in pure Pascal. | `LearningRate, ActivationType` | `Initialize, Predict, Train, TrainEpochs, SaveNetwork` | Train local models and perform mathematical predictions. |
| **TAICodeAssistant** | Cognitive assistant for auditing and optimizing code. | `ChatGPT` | `OptimizeCode, FindBugs, DocumentCode, ExplainCode` | Analyze Pascal source code and suggest structural refactorings. |
| **TAIDatasetGenerator** | Tabular dataset compiler and exporter (JSONL, CSV). | `DataRows` | `AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV` | Assemble databases and split training sets. |
| **TTokenizer** | Fast text tokenizer and words segmenter. | `LowerCase` | `Tokenize, GetVocabulary` | Preprocess text strings into token index sequences. |
| **TAIGraphMap** | Explainable text classifier based on weighted token graphs. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classify short texts and categorize tickets locally without external dependencies. |
| **TPythonConnector** | Dynamic runtime Python binding and execution bridge. | `DLLPath, Active, Version` | `ExecString, GetVar, SetVar, Eval` | Integrate heavy modules from the Python ecosystem (TensorFlow, etc.). |
| **TPerceptron** | Single-layer classical binary Perceptron classifier in Pascal. | `LearningRate, Weights, Bias` | `Initialize, Predict, Train, TrainEpochs` | Classify linearly separable binary logic states quickly. |
| **TSOMMap** | Kohonen Self-Organizing Map for data clustering. | `GridWidth, GridHeight, InputDim` | `Initialize, FindBMU, TrainStep, Train` | Cluster complex data points on two-dimensional topological grids. |
| **TCNNClassifier** | MobileNetV2 deep convolutional image classifier. | `PythonConnector` | `InstallDependencies, ClassifyImage` | Analyze and tag images or real-time camera frames. |
| **TLSTMPredictor** | LSTM recurrent network for sequence and time-series forecasting. | `PythonConnector` | `InstallDependencies, TrainLSTM, PredictNext` | Predict future values from sequential sensor telemetry. |
| **TAIVoiceSynthesizer** | Cross-platform native Speech Synthesis engine (TTS). | `Volume, Rate, VoiceName, Asynchronous` | `Say, GetAvailableVoices` | Synthesize real-time audio speech alerts from AI outputs. |

### 💻 General Instantiation Template

```pascal
var
  ChatGPT: TCHATGPT;
begin
  ChatGPT := TCHATGPT.Create(Self);
  try
    ChatGPT.APIKey := 'sua-chave-api';
    ChatGPT.Provider := AIP_OPENAI;
    if ChatGPT.SendQuestion('Olá, como posso ajudar?') then
      ShowMessage(ChatGPT.Response);
  finally
    ChatGPT.Free;
  end;
end;
```


### 📂 Samples Directory
The `samples/` folder provides comprehensive visual and command-line console demonstration projects for each suite capability.

### ⚡ Agent Prompts and Connectivity
All components in this suite feature a published `Prompt` property. This transparently informs autonomous AI Agents (`TAIAgent`) about the device or document API, enabling dynamic property injection via RTTI reflection.
