# 🧠 Package de Suite de Composants d'IA

> [!NOTE]
> Ce dossier contient l'implémentation de la suite officielle de composants d'IA et d'automatisation pour Lazarus/Delphi. Ce package intègre l'Intelligence Artificielle, l'Apprentissage Automatique, l'automatisation matérielle, les réseaux, l'audio, l'imagerie et le traitement de documents de façon native et multiplateforme via des packages modulaires.

## Référence des Composants Principaux

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TCHATGPT** | Connecteur OpenAI et LLM universel dans le cloud ou serveurs locaux. | `APIKey, Provider, TipoChat, CustomModel, MaxTokens` | `SendQuestion(ASK): Boolean, TipoModelo: string` | Traiter le langage naturel et générer des réponses cognitives. |
| **TNeuralNetwork** | Réseau de neurones Perceptron Multicouche natif en pur Pascal. | `LearningRate, ActivationType` | `Initialize, Predict, Train, TrainEpochs, SaveNetwork` | Entraîner des modèles locaux et effectuer des prédictions. |
| **TAICodeAssistant** | Assistant cognitif pour auditer et optimiser le code. | `ChatGPT` | `OptimizeCode, FindBugs, DocumentCode, ExplainCode` | Analyser les blocs de code pascal et suggérer des refactorisations. |
| **TAIDatasetGenerator** | Compilateur et exportateur de jeux de données (JSONL, CSV). | `DataRows` | `AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV` | Compiler des bases de données et diviser les lots d'entraînement. |
| **TTokenizer** | Tokeniseur de texte et segmentateur de mots rapide. | `LowerCase` | `Tokenize, GetVocabulary` | Prétraiter des chaînes en séquences d'indices de jetons. |
| **TAIGraphMap** | Classificateur de texte explicable basé sur des graphes de jetons pondérés. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | Classifier des textes courts et catégoriser des tickets localement sans dépendance externe. |
| **TPythonConnector** | Pont d'exécution dynamique de scripts Python en runtime. | `DLLPath, Active, Version` | `ExecString, GetVar, SetVar, Eval` | Intégrer des modèles lourds du monde Python (TensorFlow, etc.). |
| **TPerceptron** | Neurone Perceptron classique binaire à couche unique en Pascal. | `LearningRate, Weights, Bias` | `Initialize, Predict, Train, TrainEpochs` | Classifier rapidement des états logiques binaires simples. |
| **TSOMMap** | Réseau d'Auto-Organisation de Kohonen pour le clustering. | `GridWidth, GridHeight, InputDim` | `Initialize, FindBMU, TrainStep, Train` | Regrouper des données complexes sur des grilles topologiques. |
| **TCNNClassifier** | Classifieur convolutif profond MobileNetV2 pour les images. | `PythonConnector` | `InstallDependencies, ClassifyImage` | Analyser et étiqueter des images ou flux caméras. |
| **TLSTMPredictor** | Prédiction de séries temporelles par réseau récurrent LSTM. | `PythonConnector` | `InstallDependencies, TrainLSTM, PredictNext` | Prédire les valeurs futures issues de télémétries séquentielles. |
| **TAIVoiceSynthesizer** | Moteur de synthèse vocale (TTS) natif et multiplateforme. | `Volume, Rate, VoiceName, Asynchronous` | `Say, GetAvailableVoices` | Synthétiser des alertes vocales générées par l'IA. |
| **TAIDiskTreeScanner** | Scanneur asynchrone d'arborescence de fichiers locaux. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Scanner des répertoires locaux et indexer des fichiers pour datasets. |
| **TAI_DOCFILESMANAGER** | Gestionnaire physique de documents et fichiers. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organiser les fichiers de documentation pour le RAG et l'entraînement. |

### 💻 Modèle Général d'Instanciation

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


### 📂 Répertoire d'Exemples (Samples)
Le dossier `samples/` propose des projets de démonstration visuels et console pour chaque composant.

### ⚡ Prompts d'Agents et Connectivité
Chaque composant intègre une propriedade published `Prompt` décrivant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
