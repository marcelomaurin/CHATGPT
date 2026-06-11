# 📂 Progetti di Dimostrazione (Samples)

> [!NOTE]
> Questa directory contiene la suite completa di esempi sviluppati per dimostrare e testare tutti i componenti di Intelligenza Artificiale, Machine Learning, Elaborazione Immagini, Elaborazione Segnali (DSP), Automazione Hardware e Generazione Documenti della suite Lazarus AI Suite.

## 🖥️ Demo ad Interfaccia Grafica (GUI)
I seguenti esempi sono progetti visuali pronti per la compilazione e l'esecuzione interattiva tramite Lazarus:

| Esempio | Cosa fa | Componenti | Come funziona |
|---|---|---|---|
| **[visual_demo/](IA/visual_demo/)** | Centro di controllo IA unificato con schede. | `TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator` | Allows querying cloud LLMs, auditing Pascal code, exporting fine-tuning datasets, and training XOR networks. |
| **[voicesynthesizer_demo/](IA Voice/voicesynthesizer_demo/)** | Sintetizzatore vocale nativo (TTS). | `TAIVoiceSynthesizer` | Lists system narrator voices (SAPI on Windows, eSpeak on Linux) with volume, rate, and non-blocking thread support. |
| **[yolo_demo/](IA/yolo_demo/)** | Rilevamento profondo oggetti YOLOv8. | `TYOLO, TPythonConnector` | Installs pip dependencies automatically, executes local inference (yolov8n.pt), and renders bounding boxes in Pascal. |
| **[cnn_demo/](IA/cnn_demo/)** | Classificazione immagini MobileNetV2. | `TCNNClassifier, TPythonConnector` | Imports MobileNetV2 via TensorFlow in Python, classifies local files, and outputs top class with probability. |
| **[lstm_demo/](IA/lstm_demo/)** | Previsione grafica serie temporali LSTM. | `TLSTMPredictor, TPythonConnector` | Trains LSTM recurrent model locally on noisy sine wave data, plotting future predictions in real-time. |
| **[face_detection_demo/](IA/face_detection_demo/)** | Rilevamento volti OpenCV. | `TFaceDetection, TPythonConnector` | Interfaces with OpenCV Haar Cascades in Python to highlight faces with bounding boxes. |
| **[python_demo/](IA/python_demo/)** | Playground interattivo per Python. | `TPythonConnector` | Runs arbitrary scripts, accesses namespace variables, and evaluates math/logic expression strings. |
| **[neural_network_demo/](IA/neural_network_demo/)** | Addestramento locale XOR MLP. | `TNeuralNetwork` | Trains XOR network natively in Pascal, logging MSE loss and saving trained weight matrices. |
| **[perceptron_demo/](IA/perceptron_demo/)** | Addestratore porte logiche perceptron. | `TPerceptron` | Demonstrates delta rule updates to synapse weights and neuron bias in Pascal. |
| **[som_demo/](IA/som_demo/)** | Clustering topologico colori Kohonen. | `TSOMMap` | Clusters 3D RGB color vectors into two-dimensional visual topological grids in real-time. |
| **[tokenizer_demo/](IA/tokenizer_demo/)** | Segmentazione e tokenizzazione stringhe. | `TTokenList` | Splits text into frequency-sorted vocabularies, indexing words with JSON export support. |
| **[image_filters_demo/](IA Image/image_filters_demo/)** | Filtri d'immagine in canvas Pascal. | `IA Image tab filters (TAIImageFilters)` | Applies Sobel, Gaussian, Canny, and Grayscale filters to LCL TBitmap canvases. |
| **[sound_filters_demo/](IA Filtros Sonoros/sound_filters_demo/)** | Elaborazione segnali DSP e modulazioni. | `IA Filtros Sonoros tab filters (TAISoundFilters)` | Models LowPass/HighPass filters, FDM, TDM, CDM, and orthogonal OFDM multiplexing. |
| **[schedule_demo/](IA Schedulle/schedule_demo/)** | Pianificatore compiti basato su cron. | `TIASchedule` | Resolves task dependency trees using cron configurations and saves setups to JSON. |
| **[hardware_net_demo/](IA Input/hardware_net_demo/)** | Demo hardware, reti, PLC e broker MQTT. | `TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture` | Captures video frames, reads MQTT broker topics, sends emails, bridges Profinet CLPs, and logs global events. |
| **[graphmap_demo/](IA/graphmap_demo/)** | Classificazione e instradamento del testo tramite mappe di grafi di token pesati. | `TAIGraphMap` | Allows adding training phrases and target categories, training the model, and visualizing category ranking and weight-based explanations. |
| **[tripo3d_demo/](AI Graphic/tripo3d_demo/)** | Generazione di modelli 3D tramite l'API Tripo3D (Image-to-3D / Text-to-3D). | `TAITripo3DClient, TAI3DModelViewer, TAIModel3D` | Sends images or text to the Tripo3D API, monitors the task progress, and renders the output STL/OBJ mesh in OpenGL. |
| **[opencv_vision_demo/](AI Vision/opencv_vision_demo/)** | Acquisizione visiva, elaborazione e tracciamento utilizzando la suite AI Vision. | `TAIOpenCV, TAICameraCapture, TAIFrameProcessor, TAIFaceTracker, TAIMotionTracker` | Graphical interface for camera control, grayscale/equalization filtering, and real-time face/motion tracking. |
| **[opengl_graphic_demo/](AI Graphic/opengl_graphic_demo/)** | Demo OpenGL interattiva di scene 2D/3D e visualizzatore di modelli. | `TAIScene2D3D, TAI3DModelViewer, TAIModel3D` | Controls visual grids, axes, simulation states, cameras, and renders 3D mesh files in real-time. |

## 💻 Demo a Riga di Comando (Console)
Questi esempi mostrano l'invocazione diretta dei componenti da riga di comando per debug rapido o automazione:

*   **aivoicesynthesizer_sample.lpr**: Sintesi vocale da riga di comando sincrona e asincrona.
*   **chatgpt_sample.lpr**: Invio rapido domande e ispezione dei payload per OpenAI, Claude e Gemini.
*   **aicodeassistant_sample.lpr**: Ottimizzazione e documentazione codice Pascal automatica da riga di comando.
*   **aidatasetgenerator_sample.lpr**: Generazione ed esportazione di dataset per fine-tuning in formato JSONL.
*   **neuralnetwork_sample.lpr**: Simulatore di addestramento MLP XOR scritto in Pascal.
*   **graphmap_basic.lpr**: Esempio console di base per la classificazione spiegabile di testi tramite grafi pesati.
