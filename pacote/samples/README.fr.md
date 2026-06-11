# 📂 Projets de Démonstration (Samples)

> [!NOTE]
> Ce dossier contient la suite complète d'exemples développés pour tester tous les composants d'Intelligence Artificielle, d'Apprentissage Automatique, de traitement d'images, de traitement de signaux (DSP), d'automatisation matérielle et de génération de documents de la suite Lazarus AI Suite.

## 🖥️ Démonstrations en Interface Graphique (GUI)
Les exemples suivants sont des projets visuels prêts à être compilés et exécutés via Lazarus :

| Exemple | Ce qu'il fait | Composant | Comment ça marche |
|---|---|---|---|
| **[visual_demo/](IA/visual_demo/)** | Centre unifié de contrôle IA avec onglets. | `TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator` | Allows querying cloud LLMs, auditing Pascal code, exporting fine-tuning datasets, and training XOR networks. |
| **[voicesynthesizer_demo/](IA Voice/voicesynthesizer_demo/)** | Synthétiseur de voix natif (TTS). | `TAIVoiceSynthesizer` | Lists system narrator voices (SAPI on Windows, eSpeak on Linux) with volume, rate, and non-blocking thread support. |
| **[yolo_demo/](IA/yolo_demo/)** | Détection d'objets YOLOv8. | `TYOLO, TPythonConnector` | Installs pip dependencies automatically, executes local inference (yolov8n.pt), and renders bounding boxes in Pascal. |
| **[cnn_demo/](IA/cnn_demo/)** | Classification d'images MobileNetV2. | `TCNNClassifier, TPythonConnector` | Imports MobileNetV2 via TensorFlow in Python, classifies local files, and outputs top class with probability. |
| **[lstm_demo/](IA/lstm_demo/)** | Prédiction temporelle graphique LSTM. | `TLSTMPredictor, TPythonConnector` | Trains LSTM recurrent model locally on noisy sine wave data, plotting future predictions in real-time. |
| **[face_detection_demo/](IA/face_detection_demo/)** | Reconnaissance faciale OpenCV. | `TFaceDetection, TPythonConnector` | Interfaces with OpenCV Haar Cascades in Python to highlight faces with bounding boxes. |
| **[python_demo/](IA/python_demo/)** | Console interactive pour Python. | `TPythonConnector` | Runs arbitrary scripts, accesses namespace variables, and evaluates math/logic expression strings. |
| **[neural_network_demo/](IA/neural_network_demo/)** | Entraînement local XOR MLP. | `TNeuralNetwork` | Trains XOR network natively in Pascal, logging MSE loss and saving trained weight matrices. |
| **[perceptron_demo/](IA/perceptron_demo/)** | Entraînement de portes logiques perceptron. | `TPerceptron` | Demonstrates delta rule updates to synapse weights and neuron bias in Pascal. |
| **[som_demo/](IA/som_demo/)** | Classification de couleurs Kohonen. | `TSOMMap` | Clusters 3D RGB color vectors into two-dimensional visual topological grids in real-time. |
| **[tokenizer_demo/](IA/tokenizer_demo/)** | Segmentation de texte et tokenisation. | `TTokenList` | Splits text into frequency-sorted vocabularies, indexing words with JSON export support. |
| **[image_filters_demo/](IA Image/image_filters_demo/)** | Filtres d'image natifs dans Pascal. | `IA Image tab filters (TAIImageFilters)` | Applies Sobel, Gaussian, Canny, and Grayscale filters to LCL TBitmap canvases. |
| **[sound_filters_demo/](IA Filtros Sonoros/sound_filters_demo/)** | Traitement du signal DSP et modulations. | `IA Filtros Sonoros tab filters (TAISoundFilters)` | Models LowPass/HighPass filters, FDM, TDM, CDM, and orthogonal OFDM multiplexing. |
| **[schedule_demo/](IA Schedulle/schedule_demo/)** | Planificateur de tâches cron. | `TIASchedule` | Resolves task dependency trees using cron configurations and saves setups to JSON. |
| **[hardware_net_demo/](IA Input/hardware_net_demo/)** | Démo avancée matériels, réseaux, API et MQTT. | `TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture` | Captures video frames, reads MQTT broker topics, sends emails, bridges Profinet CLPs, and logs global events. |
| **[graphmap_demo/](IA/graphmap_demo/)** | Classification et routage de texte par cartes de graphes de jetons pondérés. | `TAIGraphMap` | Allows adding training phrases and target categories, training the model, and visualizing category ranking and weight-based explanations. |
| **[tripo3d_demo/](AI Graphic/tripo3d_demo/)** | Génération de modèles 3D via l'API Tripo3D (Image-to-3D / Text-to-3D). | `TAITripo3DClient, TAI3DModelViewer, TAIModel3D` | Sends images or text to the Tripo3D API, monitors the task progress, and renders the output STL/OBJ mesh in OpenGL. |
| **[opencv_vision_demo/](AI Vision/opencv_vision_demo/)** | Capture, traitement et suivi visuels à l'aide de la suite AI Vision. | `TAIOpenCV TAIFrameProcessor, TAIFaceTracker, TAIMotionTracker` | Graphical interface for camera control, grayscale/equalization filtering, and real-time face/motion tracking. |
| **[opengl_graphic_demo/](AI Graphic/opengl_graphic_demo/)** | Démo interactive OpenGL de scène 2D/3D et visualiseur. | `TAIScene2D3D, TAI3DModelViewer, TAIModel3D` | Controls visual grids, axes, simulation states, cameras, and renders 3D mesh files in real-time. |

## 💻 Démonstrations en Ligne de Commande (Console)
Ces exemples illustrent l'utilisation directe des composants en ligne de commande pour le débogage rapide :

*   **aivoicesynthesizer_sample.lpr**: Démo directe de synthèse vocale s'exécutant en console.
*   **chatgpt_sample.lpr**: Requêtes rapides et inspection de payloads pour OpenAI, Claude et Gemini.
*   **aicodeassistant_sample.lpr**: Routine console pour l'optimisation et documentation de code.
*   **aidatasetgenerator_sample.lpr**: Génération et exportation automatisée de datasets JSONL.
*   **neuralnetwork_sample.lpr**: Entraînement classique XOR d'un perceptron multicouche MLP.
*   **graphmap_basic.lpr**: Exemple console de base pour la classification explicable de textes via des graphes pondérés.