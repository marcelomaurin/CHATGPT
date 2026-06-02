# 📂 مشاريع توضيحية (Samples)

> [!NOTE]
> يحتوي هذا المجلد على مجموعة كاملة من الأمثلة والمشاريع المطورة لتوضيح واختبار جميع مكونات الذكاء الاصطناعي، تعلم الآلة، معالجة الصور، معالجة الإشارات الرقمية (DSP)، أتمتة الأجهزة، وتوليد المستندات لحزمة **openai.lpk**.

## 🖥️ مشاريع توضيحية لواجهات المستخدم الرسومية (GUI)
الأمثلة التالية عبارة عن مشاريع مرئية جاهزة للتجميع والتشغيل التفاعلي عبر لازاروس:

| المشروع | ماذا يفعل | المكونات | كيف يعمل |
|---|---|---|---|
| **[visual_demo/](visual_demo/)** | مركز تحكم ذكاء اصطناعي موحد مع تبويبات. | `TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator` | Allows querying cloud LLMs, auditing Pascal code, exporting fine-tuning datasets, and training XOR networks. |
| **[voicesynthesizer_demo/](voicesynthesizer_demo/)** | مخلق الصوت والترجمة الصوتية (TTS). | `TAIVoiceSynthesizer` | Lists system narrator voices (SAPI on Windows, eSpeak on Linux) with volume, rate, and non-blocking thread support. |
| **[yolo_demo/](yolo_demo/)** | رصد واكتشاف الكائنات YOLOv8 عميق. | `TYOLO, TPythonConnector` | Installs pip dependencies automatically, executes local inference (yolov8n.pt), and renders bounding boxes in Pascal. |
| **[cnn_demo/](cnn_demo/)** | تصنيف الصور باستخدام شبكة MobileNetV2. | `TCNNClassifier, TPythonConnector` | Imports MobileNetV2 via TensorFlow in Python, classifies local files, and outputs top class with probability. |
| **[lstm_demo/](lstm_demo/)** | التنبؤ البياني بالسلاسل الزمنية LSTM. | `TLSTMPredictor, TPythonConnector` | Trains LSTM recurrent model locally on noisy sine wave data, plotting future predictions in real-time. |
| **[face_detection_demo/](face_detection_demo/)** | اكتشاف وتحديد الوجوه OpenCV. | `TFaceDetection, TPythonConnector` | Interfaces with OpenCV Haar Cascades in Python to highlight faces with bounding boxes. |
| **[python_demo/](python_demo/)** | بيئة عمل تفاعلية للغة بايثون. | `TPythonConnector` | Runs arbitrary scripts, accesses namespace variables, and evaluates math/logic expression strings. |
| **[neural_network_demo/](neural_network_demo/)** | تدريب XOR محلي للشبكات MLP. | `TNeuralNetwork` | Trains XOR network natively in Pascal, logging MSE loss and saving trained weight matrices. |
| **[perceptron_demo/](perceptron_demo/)** | تدريب البوابات المنطقية العصبية perceptron. | `TPerceptron` | Demonstrates delta rule updates to synapse weights and neuron bias in Pascal. |
| **[som_demo/](som_demo/)** | تجميع الألوان على شبكة Kohonen ذاتية التنظيم. | `TSOMMap` | Clusters 3D RGB color vectors into two-dimensional visual topological grids in real-time. |
| **[tokenizer_demo/](tokenizer_demo/)** | تقسيم وتحليل الكلمات للنصوص. | `TTokenList` | Splits text into frequency-sorted vocabularies, indexing words with JSON export support. |
| **[image_filters_demo/](image_filters_demo/)** | فلاتر معالجة الصور ومصفوفاتها. | `IA Image tab filters (TAIImageFilters)` | Applies Sobel, Gaussian, Canny, and Grayscale filters to LCL TBitmap canvases. |
| **[sound_filters_demo/](sound_filters_demo/)** | معالجة الإشارات الصوتية DSP وتعديلها. | `IA Filtros Sonoros tab filters (TAISoundFilters)` | Models LowPass/HighPass filters, FDM, TDM, CDM, and orthogonal OFDM multiplexing. |
| **[schedule_demo/](schedule_demo/)** | مجدول المهام الدورية والزمنية cron. | `TIASchedule` | Resolves task dependency trees using cron configurations and saves setups to JSON. |
| **[hardware_net_demo/](hardware_net_demo/)** | عرض متكامل لأتمتة الأجهزة، الشبكات، والتحكم الصناعي. | `TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture` | Captures video frames, reads MQTT broker topics, sends emails, bridges Profinet CLPs, and logs global events. |

## 💻 مشاريع توضيحية لسطر الأوامر (Console)
توضح هذه الأمثلة الاستدعاء المباشر للمكونات عبر سطر الأوامر لسيناريوهات تصحيح الأخطاء السريعة وأتمتة العمليات الدورية:

*   **aivoicesynthesizer_sample.lpr**: استدعاء مباشر لتخليق الأصوات عبر الكونسول بشكل متزامن وغير متزامن.
*   **chatgpt_sample.lpr**: إرسال سريع للأسئلة وفحص البيانات الخام المستلمة من OpenAI, Claude, Gemini.
*   **aicodeassistant_sample.lpr**: أتمتة تحسين وفحص كود باسكال عبر سطر الأوامر.
*   **aidatasetgenerator_sample.lpr**: إنشاء وتصدير مجموعات البيانات لتدريب النماذج بصيغة JSONL.
*   **neuralnetwork_sample.lpr**: محاكي تدريب XOR للشبكات العصبية متعددة الطبقات بلغة باسكال الخالصة.
