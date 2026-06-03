# 📂 Demonstration Projects (Samples)

> [!NOTE]
> This directory contains the complete suite of examples developed to demonstrate and test all Artificial Intelligence, Machine Learning, Image Processing, Digital Signal Processing (DSP), Hardware Automation, and Document Generation components of the **openai.lpk** package.

## 🖥️ Graphical User Interface (GUI) Demonstrations
The following examples are visual projects ready for compilation and interactive execution through Lazarus:

| Sample | What it does | Components | How it works |
|---|---|---|---|
| **[visual_demo/](IA/visual_demo/)** | Unified AI control center with functional testing tabs. | `TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator` | Allows querying cloud LLMs, auditing Pascal code, exporting fine-tuning datasets, and training XOR networks. |
| **[voicesynthesizer_demo/](IA Voice/voicesynthesizer_demo/)** | Text-to-Speech (TTS) control panel interface. | `TAIVoiceSynthesizer` | Lists system narrator voices (SAPI on Windows, eSpeak on Linux) with volume, rate, and non-blocking thread support. |
| **[yolo_demo/](IA/yolo_demo/)** | Deep object detection utilizing YOLOv8 models. | `TYOLO, TPythonConnector` | Installs pip dependencies automatically, executes local inference (yolov8n.pt), and renders bounding boxes in Pascal. |
| **[cnn_demo/](IA/cnn_demo/)** | Deep convolutional classification using MobileNetV2. | `TCNNClassifier, TPythonConnector` | Imports MobileNetV2 via TensorFlow in Python, classifies local files, and outputs top class with probability. |
| **[lstm_demo/](IA/lstm_demo/)** | Graphical sequential time-series trend forecasting. | `TLSTMPredictor, TPythonConnector` | Trains LSTM recurrent model locally on noisy sine wave data, plotting future predictions in real-time. |
| **[face_detection_demo/](IA/face_detection_demo/)** | Real-time facial detection playground. | `TFaceDetection, TPythonConnector` | Interfaces with OpenCV Haar Cascades in Python to highlight faces with bounding boxes. |
| **[python_demo/](IA/python_demo/)** | Interactive Python console and script workspace. | `TPythonConnector` | Runs arbitrary scripts, accesses namespace variables, and evaluates math/logic expression strings. |
| **[neural_network_demo/](IA/neural_network_demo/)** | Multilayer Perceptron (MLP) network playground. | `TNeuralNetwork` | Trains XOR network natively in Pascal, logging MSE loss and saving trained weight matrices. |
| **[perceptron_demo/](IA/perceptron_demo/)** | Single-layer Perceptron logic gate trainer. | `TPerceptron` | Demonstrates delta rule updates to synapse weights and neuron bias in Pascal. |
| **[som_demo/](IA/som_demo/)** | Kohonen Self-Organizing Map topological clustering. | `TSOMMap` | Clusters 3D RGB color vectors into two-dimensional visual topological grids in real-time. |
| **[tokenizer_demo/](IA/tokenizer_demo/)** | String segmentation and index statistics panel. | `TTokenList` | Splits text into frequency-sorted vocabularies, indexing words with JSON export support. |
| **[image_filters_demo/](IA Image/image_filters_demo/)** | Interactive image matrix filters playground. | `IA Image tab filters (TAIImageFilters)` | Applies Sobel, Gaussian, Canny, and Grayscale filters to LCL TBitmap canvases. |
| **[sound_filters_demo/](IA Filtros Sonoros/sound_filters_demo/)** | Digital Signal Processing (DSP) and modulation simulator. | `IA Filtros Sonoros tab filters (TAISoundFilters)` | Models LowPass/HighPass filters, FDM, TDM, CDM, and orthogonal OFDM multiplexing. |
| **[schedule_demo/](IA Schedulle/schedule_demo/)** | Automated cron task scheduler and queue timeline manager. | `TIASchedule` | Resolves task dependency trees using cron configurations and saves setups to JSON. |
| **[hardware_net_demo/](IA Input/hardware_net_demo/)** | Advanced hardware, network, PLC, and IoT client showcase. | `TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture` | Captures video frames, reads MQTT broker topics, sends emails, bridges Profinet CLPs, and logs global events. |
| **[graphmap_demo/](IA/graphmap_demo/)** | Text classification and routing using weighted token graph maps. | `TAIGraphMap` | Allows adding training phrases and target categories, training the model, and visualizing category ranking and weight-based explanations. |
| **[tripo3d_demo/](AI Graphic/tripo3d_demo/)** | 3D model generation using Tripo3D API (Image-to-3D / Text-to-3D). | `TAITripo3DClient, TAI3DModelViewer, TAIModel3D` | Sends images or text to the Tripo3D API, monitors the task progress, and renders the output STL/OBJ mesh in OpenGL. |
| **[opencv_vision_demo/](AI Vision/opencv_vision_demo/)** | Visual capture, processing, and tracking utilizing the AI Vision suite. | `TAIOpenCV, TAICameraCapture, TAIFrameProcessor, TAIFaceTracker, TAIMotionTracker` | Graphical interface for camera control, grayscale/equalization filtering, and real-time face/motion tracking. |
| **[opengl_graphic_demo/](AI Graphic/opengl_graphic_demo/)** | Interactive OpenGL 2D/3D scene and 3D model viewer showcase. | `TAIScene2D3D, TAI3DModelViewer, TAIModel3D` | Controls visual grids, axes, simulation states, cameras, and renders 3D mesh files in real-time. |

## 💻 Command Line Interface (Console) Demonstrations
These examples demonstrate direct component invocation via command line for rapid debugging or automation scenarios:

*   **aivoicesynthesizer_sample.lpr**: Direct console Text-to-Speech synthesis invocation demo.
*   **chatgpt_sample.lpr**: Quick command-line questions and payload auditing for OpenAI, Claude, and Gemini.
*   **aicodeassistant_sample.lpr**: Command-line routine for code auditing, optimizations, and doc formatting.
*   **aidatasetgenerator_sample.lpr**: Auto-generation loop and JSONL conversations dataset exporter.
*   **neuralnetwork_sample.lpr**: Classic MLP training XOR convergence simulator in console.
*   **graphmap_basic.lpr**: Basic console sample for explainable text classification using weighted graph maps.
