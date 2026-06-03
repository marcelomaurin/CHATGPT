# 📂 Proyectos de Demostración (Samples)

> [!NOTE]
> Este directorio contiene la suite completa de ejemplos desarrollados para demostrar y probar todos los componentes de Inteligencia Artificial, Aprendizaje Automático (Machine Learning), Procesamiento de Imágenes, Procesamiento de Señales (DSP), Automatización de Hardware y Generación de Documentos del paquete **openai.lpk**.

## 🖥️ Demostraciones de Interfaz Gráfica (GUI)
Los siguientes ejemplos son proyectos visuales listos para compilar y ejecutar interactivamente en Lazarus:

| Ejemplo | Qué hace | Componentes | Cómo funciona |
|---|---|---|---|
| **[visual_demo/](IA/visual_demo/)** | Central unificada con pestañas de prueba. | `TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator` | Allows querying cloud LLMs, auditing Pascal code, exporting fine-tuning datasets, and training XOR networks. |
| **[voicesynthesizer_demo/](IA Voice/voicesynthesizer_demo/)** | Sintetizador de voz nativo (TTS). | `TAIVoiceSynthesizer` | Lists system narrator voices (SAPI on Windows, eSpeak on Linux) with volume, rate, and non-blocking thread support. |
| **[yolo_demo/](IA/yolo_demo/)** | Detección profunda YOLOv8. | `TYOLO, TPythonConnector` | Installs pip dependencies automatically, executes local inference (yolov8n.pt), and renders bounding boxes in Pascal. |
| **[cnn_demo/](IA/cnn_demo/)** | Clasificación profunda de imágenes MobileNetV2. | `TCNNClassifier, TPythonConnector` | Imports MobileNetV2 via TensorFlow in Python, classifies local files, and outputs top class with probability. |
| **[lstm_demo/](IA/lstm_demo/)** | Predicción gráfica de series temporales LSTM. | `TLSTMPredictor, TPythonConnector` | Trains LSTM recurrent model locally on noisy sine wave data, plotting future predictions in real-time. |
| **[face_detection_demo/](IA/face_detection_demo/)** | Identificación facial en tiempo real OpenCV. | `TFaceDetection, TPythonConnector` | Interfaces with OpenCV Haar Cascades in Python to highlight faces with bounding boxes. |
| **[python_demo/](IA/python_demo/)** | Consola interativa del intérprete Python. | `TPythonConnector` | Runs arbitrary scripts, accesses namespace variables, and evaluates math/logic expression strings. |
| **[neural_network_demo/](IA/neural_network_demo/)** | Entrenamiento XOR local MLP. | `TNeuralNetwork` | Trains XOR network natively in Pascal, logging MSE loss and saving trained weight matrices. |
| **[perceptron_demo/](IA/perceptron_demo/)** | Entrenador de compuertas lógicas perceptrón. | `TPerceptron` | Demonstrates delta rule updates to synapse weights and neuron bias in Pascal. |
| **[som_demo/](IA/som_demo/)** | Agrupamiento de colores en rejilla Kohonen. | `TSOMMap` | Clusters 3D RGB color vectors into two-dimensional visual topological grids in real-time. |
| **[tokenizer_demo/](IA/tokenizer_demo/)** | Segmentación y tokenización de cadenas. | `TTokenList` | Splits text into frequency-sorted vocabularies, indexing words with JSON export support. |
| **[image_filters_demo/](IA Image/image_filters_demo/)** | Procesamiento de filtros de imagem en Pascal. | `IA Image tab filters (TAIImageFilters)` | Applies Sobel, Gaussian, Canny, and Grayscale filters to LCL TBitmap canvases. |
| **[sound_filters_demo/](IA Filtros Sonoros/sound_filters_demo/)** | Procesamiento DSP y modulación de sinais. | `IA Filtros Sonoros tab filters (TAISoundFilters)` | Models LowPass/HighPass filters, FDM, TDM, CDM, and orthogonal OFDM multiplexing. |
| **[schedule_demo/](IA Schedulle/schedule_demo/)** | Programador de tareas periódicas cron. | `TIASchedule` | Resolves task dependency trees using cron configurations and saves setups to JSON. |
| **[hardware_net_demo/](IA Input/hardware_net_demo/)** | Demostración de hardware, redes, PLC y MQTT. | `TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture` | Captures video frames, reads MQTT broker topics, sends emails, bridges Profinet CLPs, and logs global events. |
| **[graphmap_demo/](IA/graphmap_demo/)** | Clasificación de texto y enrutamiento usando mapas de grafos ponderados de tokens. | `TAIGraphMap` | Allows adding training phrases and target categories, training the model, and visualizing category ranking and weight-based explanations. |
| **[tripo3d_demo/](AI Graphic/tripo3d_demo/)** | Generación de modelos 3D a través de la API Tripo3D (Image-to-3D / Text-to-3D). | `TAITripo3DClient, TAI3DModelViewer, TAIModel3D` | Sends images or text to the Tripo3D API, monitors the task progress, and renders the output STL/OBJ mesh in OpenGL. |
| **[opencv_vision_demo/](AI Vision/opencv_vision_demo/)** | Captura, procesamiento y seguimiento visual usando la suite AI Vision. | `TAIOpenCV, TAICameraCapture, TAIFrameProcessor, TAIFaceTracker, TAIMotionTracker` | Graphical interface for camera control, grayscale/equalization filtering, and real-time face/motion tracking. |
| **[opengl_graphic_demo/](AI Graphic/opengl_graphic_demo/)** | Demostración interactiva OpenGL de escena 2D/3D y visualizador. | `TAIScene2D3D, TAI3DModelViewer, TAIModel3D` | Controls visual grids, axes, simulation states, cameras, and renders 3D mesh files in real-time. |

## 💻 Demostraciones de Línea de Comando (Consola)
Estos ejemplos demuestran la invocación directa de componentes a través de la línea de comandos para depuración rápida o automatización:

*   **aivoicesynthesizer_sample.lpr**: Síntesis de voz directa en consola de forma síncrona/asíncrona.
*   **chatgpt_sample.lpr**: Preguntas rápidas y auditoría de payloads de OpenAI, Claude y Gemini.
*   **aicodeassistant_sample.lpr**: Optimización y documentación automática de código Pascal por consola.
*   **aidatasetgenerator_sample.lpr**: Bucle de geração y exportación de bases de datos JSONL.
*   **neuralnetwork_sample.lpr**: Entrenamiento clásico XOR de perceptrón multicapa MLP en Pascal.
*   **graphmap_basic.lpr**: Ejemplo básico de consola para la clasificación explicable de textos mediante grafos ponderados.
