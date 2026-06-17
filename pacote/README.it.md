# 🧠 Pacchetto Componenti IA

> [!NOTE]
> Questa directory contiene l'implementazione del pacchetto ufficiale di componenti IA e automazione per Lazarus/Delphi. Integra Intelligenza Artificiale, Machine Learning, automazione hardware, reti, audio, elaborazione di immagini e documenti in modo nativo e multipiattaforma grazie a pacchetti modulari.

## Riferimento dei Componenti Principali

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TCHATGPT** | Connettore universale OpenAI e LLM cloud o server locali. | `APIKey, Provider, TipoChat, CustomModel, MaxTokens` | `SendQuestion(ASK): Boolean, TipoModelo: string` | Elaborare il linguaggio naturale e generare risposte cognitive. |
| **TNeuralNetwork** | Rete Neurale Perceptron Multistrato nativa in puro Pascal. | `LearningRate, ActivationType` | `Initialize, Predict, Train, TrainEpochs, SaveNetwork` | Addestrare modelli locali ed effettuare previsioni matematiche. |
| **TAICodeAssistant** | Assistente cognitivo per l'auditing e l'ottimizzazione del codice. | `ChatGPT` | `OptimizeCode, FindBugs, DocumentCode, ExplainCode` | Analizzare sorgenti Pascal e suggerire refactoring. |
| **TAIDatasetGenerator** | Compilatore ed esportatore di dataset tabulari (JSONL, CSV). | `DataRows` | `AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV` | Compilare database e suddividere i set di addestramento. |
| **TTokenizer** | Tokenizzatore di testo rapido e segmentatore di parole. | `LowerCase` | `Tokenize, GetVocabulary` | Pre-elaborare stringhe grezze in indici numerici (token). |
| **TAIGraphMap** | Classificatore di testo spiegabile basato su grafi di token pesati. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classificare testi brevi e categorizzare ticket localmente senza dipendenze esterne. |
| **TPythonConnector** | Ponte di collegamento ed esecuzione runtime del motore Python. | `DLLPath, Active, Version` | `ExecString, GetVar, SetVar, Eval` | Integrare modelli complessi dall'ecosistema Python (TensorFlow, ecc.). |
| **TPerceptron** | Neurone Perceptron classico binario a singolo strato in Pascal. | `LearningRate, Weights, Bias` | `Initialize, Predict, Train, TrainEpochs` | Classificare rapidamente stati logici binari lineari. |
| **TSOMMap** | Rete di Auto-Organizzazione di Kohonen per il clustering dei dati. | `GridWidth, GridHeight, InputDim` | `Initialize, FindBMU, TrainStep, Train` | Raggruppare dati complessi su griglie bidimensionali. |
| **TCNNClassifier** | Classificatore convoluzionale profondo MobileNetV2 per immagini. | `PythonConnector` | `InstallDependencies, ClassifyImage` | Analizzare ed etichettare immagini o fotogrammi video. |
| **TLSTMPredictor** | Previsore di serie temporali tramite rete ricorrente LSTM. | `PythonConnector` | `InstallDependencies, TrainLSTM, PredictNext` | Prevedere l'andamento futuro di dati sensoriali sequenziali. |
| **TAIVoiceSynthesizer** | Motore di sintesi vocale (TTS) nativo Windows e Linux. | `Volume, Rate, VoiceName, Asynchronous` | `Say, GetAvailableVoices` | Generare messaggi vocali e allarmi IA tramite altoparlanti. |
| **TAIDiskTreeScanner** | Scansionatore asincrono dell'albero dei file locali. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Scansionare directory locali e indicizzare file per dataset. |
| **TAI_DOCFILESMANAGER** | Gestore fisico di documenti e file. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organizzare i file di documentazione per RAG e addestramento. |

### 💻 Modello Generale di Istanziazione

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


### 📂 Directory degli Esempi (Samples)
La cartella `samples/` contiene demo grafiche e a riga di comando per sperimentare ogni funzionalità del pacchetto.

### ⚡ Connettività e Prompt degli Agenti
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API per guidare gli Agenti IA (`TAIAgent`) autonomamente.
