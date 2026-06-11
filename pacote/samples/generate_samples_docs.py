# -*- coding: utf-8 -*-
import os

langs = {
    'pt': {
        'title': 'Projetos de Demonstração (Samples)',
        'intro': 'Este diretório contém a suíte completa de exemplos desenvolvidos para demonstrar e testar todos os componentes de Inteligência Artificial, Aprendizado de Máquina (Machine Learning), Processamento de Imagens, Processamento de Sinais (DSP), Automação de Hardware e Geração de Documentos da Lazarus AI Suite.',
        'gui_title': '🖥️ Demonstrações em Interface Gráfica (GUI)',
        'gui_desc': 'Os exemplos a seguir são projetos visuais prontos para compilação e execução interativa através do Lazarus:',
        'console_title': '💻 Demonstrações em Linha de Comando (Console)',
        'console_desc': 'Estes exemplos demonstram a invocação direta de componentes via linha de comando para cenários de depuração rápida ou automação de rotinas:',
        'item_title': 'Exemplo',
        'item_desc': 'O que faz',
        'item_comps': 'Componentes',
        'item_how': 'Como funciona'
    },
    'en': {
        'title': 'Demonstration Projects (Samples)',
        'intro': 'This directory contains the complete suite of examples developed to demonstrate and test all Artificial Intelligence, Machine Learning, Image Processing, Digital Signal Processing (DSP), Hardware Automation, and Document Generation components of the Lazarus AI Suite.',
        'gui_title': '🖥️ Graphical User Interface (GUI) Demonstrations',
        'gui_desc': 'The following examples are visual projects ready for compilation and interactive execution through Lazarus:',
        'console_title': '💻 Command Line Interface (Console) Demonstrations',
        'console_desc': 'These examples demonstrate direct component invocation via command line for rapid debugging or automation scenarios:',
        'item_title': 'Sample',
        'item_desc': 'What it does',
        'item_comps': 'Components',
        'item_how': 'How it works'
    },
    'es': {
        'title': 'Proyectos de Demostración (Samples)',
        'intro': 'Este directorio contiene la suite completa de ejemplos desarrollados para demostrar y probar todos los componentes de Inteligencia Artificial, Aprendizaje Automático (Machine Learning), Procesamiento de Imágenes, Procesamiento de Señales (DSP), Automatización de Hardware y Generación de Documentos de la suite Lazarus AI Suite.',
        'gui_title': '🖥️ Demostraciones de Interfaz Gráfica (GUI)',
        'gui_desc': 'Los siguientes ejemplos son proyectos visuales listos para compilar y ejecutar interactivamente en Lazarus:',
        'console_title': '💻 Demostraciones de Línea de Comando (Consola)',
        'console_desc': 'Estos ejemplos demuestran la invocación directa de componentes a través de la línea de comandos para depuración rápida o automatización:',
        'item_title': 'Ejemplo',
        'item_desc': 'Qué hace',
        'item_comps': 'Componentes',
        'item_how': 'Cómo funciona'
    },
    'fr': {
        'title': 'Projets de Démonstration (Samples)',
        'intro': 'Ce dossier contient la suite complète d\'exemples développés pour tester tous les composants d\'Intelligence Artificielle, d\'Apprentissage Automatique, de traitement d\'images, de traitement de signaux (DSP), d\'automatisation matérielle et de génération de documents de la suite Lazarus AI Suite.',
        'gui_title': '🖥️ Démonstrations en Interface Graphique (GUI)',
        'gui_desc': 'Les exemples suivants sont des projets visuels prêts à être compilés et exécutés via Lazarus :',
        'console_title': '💻 Démonstrations en Ligne de Commande (Console)',
        'console_desc': 'Ces exemples illustrent l\'utilisation directe des composants en ligne de commande pour le débogage rapide :',
        'item_title': 'Exemple',
        'item_desc': 'Ce qu\'il fait',
        'item_comps': 'Composant',
        'item_how': 'Comment ça marche'
    },
    'it': {
        'title': 'Progetti di Dimostrazione (Samples)',
        'intro': 'Questa directory contiene la suite completa di esempi sviluppati per dimostrare e testare tutti i componenti di Intelligenza Artificiale, Machine Learning, Elaborazione Immagini, Elaborazione Segnali (DSP), Automazione Hardware e Generazione Documenti della suite Lazarus AI Suite.',
        'gui_title': '🖥️ Demo ad Interfaccia Grafica (GUI)',
        'gui_desc': 'I seguenti esempi sono progetti visuali pronti per la compilazione e l\'esecuzione interattiva tramite Lazarus:',
        'console_title': '💻 Demo a Riga di Comando (Console)',
        'console_desc': 'Questi esempi mostrano l\'invocazione diretta dei componenti da riga di comando per debug rapido o automazione:',
        'item_title': 'Esempio',
        'item_desc': 'Cosa fa',
        'item_comps': 'Componenti',
        'item_how': 'Come funziona'
    },
    'ar': {
        'title': 'مشاريع توضيحية (Samples)',
        'intro': 'يحتوي هذا المجلد على مجموعة كاملة من الأمثلة والمشاريع المطورة لتوضيح واختبار جميع مكونات الذكاء الاصطناعي، تعلم الآلة، معالجة الصور، معالجة الإشارات الرقمية (DSP)، أتمتة الأجهزة، وتوليد المستندات لحزمة Lazarus AI Suite.',
        'gui_title': '🖥️ مشاريع توضيحية لواجهات المستخدم الرسومية (GUI)',
        'gui_desc': 'الأمثلة التالية عبارة عن مشاريع مرئية جاهزة للتجميع والتشغيل التفاعلي عبر لازاروس:',
        'console_title': '💻 مشاريع توضيحية لسطر الأوامر (Console)',
        'console_desc': 'توضح هذه الأمثلة الاستدعاء المباشر للمكونات عبر سطر الأوامر لسيناريوهات تصحيح الأخطاء السريعة وأتمتة العمليات الدورية:',
        'item_title': 'المشروع',
        'item_desc': 'ماذا يفعل',
        'item_comps': 'المكونات',
        'item_how': 'كيف يعمل'
    }
}

gui_samples = {
    'pt': [
        {'name': 'visual_demo', 'desc': 'Central de controle unificada contendo abas de testes funcionais.', 'comps': 'TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator', 'how': 'Interface aba por aba permitindo fazer perguntas às IAs, auditar códigos, exportar datasets e rodar treinamento local XOR.'},
        {'name': 'voicesynthesizer_demo', 'desc': 'Painel de controle de sintetização de voz (Text-to-Speech).', 'comps': 'TAIVoiceSynthesizer', 'how': 'Permite alternar entre SAPI (Windows) e eSpeak (Linux), listando vozes instaladas com ajuste de volume, velocidade e suporte assíncrono.'},
        {'name': 'yolo_demo', 'desc': 'Detecção profunda de objetos com modelo YOLOv8.', 'comps': 'TYOLO, TPythonConnector', 'how': 'Instala silenciosamente dependências pip, executa detecção local (yolov8n.pt) e plota contornos em canvas Pascal.'},
        {'name': 'cnn_demo', 'desc': 'Classificação de imagens profunda usando redes neurais convolucionais (CNN).', 'comps': 'TCNNClassifier, TPythonConnector', 'how': 'Carrega a MobileNetV2 via TensorFlow no interpretador Python, classifica imagem local e retorna classe com confiança.'},
        {'name': 'lstm_demo', 'desc': 'Previsão sequencial de tendências e dados temporais de forma gráfica.', 'comps': 'TLSTMPredictor, TPythonConnector', 'how': 'Treina uma rede LSTM localmente em dados senoidais e projeta graficamente as previsões futuras.'},
        {'name': 'face_detection_demo', 'desc': 'Identificação facial em tempo real.', 'comps': 'TFaceDetection, TPythonConnector', 'how': 'Acessa OpenCV via Python para rodar Haar Cascades e plotar retângulos delimitadores vermelhos ao redor de faces em tempo real.'},
        {'name': 'python_demo', 'desc': 'Console e playground interativo integrado para o interpretador Python.', 'comps': 'TPythonConnector', 'how': 'Escreva scripts, configure/leia variáveis globais dinamicamente e avalie equações complexas via Eval.'},
        {'name': 'neural_network_demo', 'desc': 'Playground local de redes neurais artificiais multicamadas (MLP).', 'comps': 'TNeuralNetwork', 'how': 'Treina rede em Pascal puro na lógica XOR, exibe perda MSE e salva/restaura pesos em arquivos texto.'},
        {'name': 'perceptron_demo', 'desc': 'Treinador de portas lógicas (AND, OR, NAND, NOR).', 'comps': 'TPerceptron', 'how': 'Algoritmo em Pascal puro que atualiza pesos e bias via regra delta, visualizando a convergência do erro.'},
        {'name': 'som_demo', 'desc': 'Agrupamento topológico visual de cores em grade bidimensional.', 'comps': 'TSOMMap', 'how': 'Organiza vetores RGB tridimensionais em degradês e agrupamentos de vizinhança topológica em Pascal puro.'},
        {'name': 'tokenizer_demo', 'desc': 'Segmentação analítica e tokenização de strings.', 'comps': 'TTokenList', 'how': 'Quebra frases em palavras por frequência, indexando termos para buscas com exportação JSON.'},
        {'name': 'image_filters_demo', 'desc': 'Processamento matricial de imagens interativo.', 'comps': 'Filtros da aba IA Image (TAIImageFilters)', 'how': 'Aplica kernels convolucionais, binarizações e detecções de borda nativamente em canvas Pascal.'},
        {'name': 'sound_filters_demo', 'desc': 'Processamento digital de sinais (DSP) e modulações de frequências.', 'comps': 'Filtros da aba IA Filtros Sonoros (TAISoundFilters)', 'how': 'Simula filtros passa-baixas/altas, multiplexações FDM, TDM, CDM e OFDM ortogonal.'},
        {'name': 'schedule_demo', 'desc': 'Gerenciador cronológico e encadeamento de cronogramas.', 'comps': 'TIASchedule', 'how': 'Resolução de árvore de dependências para tarefas baseadas em cron, com persistência JSON.'},
        {'name': 'hardware_net_demo', 'desc': 'Showcase avançado de hardware, redes, CLP e brokers IoT.', 'comps': 'TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture', 'how': 'Liga câmeras, lê brokers MQTT, envia e-mails/WhatsApp, faz pontes CLP industriais e monitora o SO de forma integrada.'},
        {'name': 'graphmap_demo', 'desc': 'Classificação e roteamento de texto por mapas de grafos ponderados de tokens.', 'comps': 'TAIGraphMap', 'how': 'Permite adicionar frases de treinamento e classes de destino, treinar o modelo e visualizar o ranking de categorias e explicações com pesos.'},
        {'name': 'tripo3d_demo', 'desc': 'Geração de modelos 3D via API da Tripo3D (Image-to-3D / Text-to-3D).', 'comps': 'TAITripo3DClient, TAI3DModelViewer, TAIModel3D', 'how': 'Envia imagens ou textos para a API do Tripo3D, monitora a geração e renderiza a malha STL/OBJ resultante em OpenGL.'},
        {'name': 'opencv_vision_demo', 'desc': 'Captura, processamento e rastreamento visual usando a suíte AI Vision.', 'comps': 'TAIOpenCV, TAICameraCapture, TAIFrameProcessor, TAIFaceTracker, TAIMotionTracker', 'how': 'Interface gráfica para controle de câmera, aplicação de filtros de cinza/equalização e detecção facial/movimento em tempo real.'},
        {'name': 'opengl_graphic_demo', 'desc': 'Showcase interativo OpenGL da cena 2D/3D e visualizador de modelos.', 'comps': 'TAIScene2D3D, TAI3DModelViewer, TAIModel3D', 'how': 'Permite rodar simulação de cena 2D/3D, controlar grid, eixos, zoom e renderizar malhas 3D em tempo real.'}
    ],
    'en': [
        {'name': 'visual_demo', 'desc': 'Unified AI control center with functional testing tabs.', 'comps': 'TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator', 'how': 'Allows querying cloud LLMs, auditing Pascal code, exporting fine-tuning datasets, and training XOR networks.'},
        {'name': 'voicesynthesizer_demo', 'desc': 'Text-to-Speech (TTS) control panel interface.', 'comps': 'TAIVoiceSynthesizer', 'how': 'Lists system narrator voices (SAPI on Windows, eSpeak on Linux) with volume, rate, and non-blocking thread support.'},
        {'name': 'yolo_demo', 'desc': 'Deep object detection utilizing YOLOv8 models.', 'comps': 'TYOLO, TPythonConnector', 'how': 'Installs pip dependencies automatically, executes local inference (yolov8n.pt), and renders bounding boxes in Pascal.'},
        {'name': 'cnn_demo', 'desc': 'Deep convolutional classification using MobileNetV2.', 'comps': 'TCNNClassifier, TPythonConnector', 'how': 'Imports MobileNetV2 via TensorFlow in Python, classifies local files, and outputs top class with probability.'},
        {'name': 'lstm_demo', 'desc': 'Graphical sequential time-series trend forecasting.', 'comps': 'TLSTMPredictor, TPythonConnector', 'how': 'Trains LSTM recurrent model locally on noisy sine wave data, plotting future predictions in real-time.'},
        {'name': 'face_detection_demo', 'desc': 'Real-time facial detection playground.', 'comps': 'TFaceDetection, TPythonConnector', 'how': 'Interfaces with OpenCV Haar Cascades in Python to highlight faces with bounding boxes.'},
        {'name': 'python_demo', 'desc': 'Interactive Python console and script workspace.', 'comps': 'TPythonConnector', 'how': 'Runs arbitrary scripts, accesses namespace variables, and evaluates math/logic expression strings.'},
        {'name': 'neural_network_demo', 'desc': 'Multilayer Perceptron (MLP) network playground.', 'comps': 'TNeuralNetwork', 'how': 'Trains XOR network natively in Pascal, logging MSE loss and saving trained weight matrices.'},
        {'name': 'perceptron_demo', 'desc': 'Single-layer Perceptron logic gate trainer.', 'comps': 'TPerceptron', 'how': 'Demonstrates delta rule updates to synapse weights and neuron bias in Pascal.'},
        {'name': 'som_demo', 'desc': 'Kohonen Self-Organizing Map topological clustering.', 'comps': 'TSOMMap', 'how': 'Clusters 3D RGB color vectors into two-dimensional visual topological grids in real-time.'},
        {'name': 'tokenizer_demo', 'desc': 'String segmentation and index statistics panel.', 'comps': 'TTokenList', 'how': 'Splits text into frequency-sorted vocabularies, indexing words with JSON export support.'},
        {'name': 'image_filters_demo', 'desc': 'Interactive image matrix filters playground.', 'comps': 'IA Image tab filters (TAIImageFilters)', 'how': 'Applies Sobel, Gaussian, Canny, and Grayscale filters to LCL TBitmap canvases.'},
        {'name': 'sound_filters_demo', 'desc': 'Digital Signal Processing (DSP) and modulation simulator.', 'comps': 'IA Filtros Sonoros tab filters (TAISoundFilters)', 'how': 'Models LowPass/HighPass filters, FDM, TDM, CDM, and orthogonal OFDM multiplexing.'},
        {'name': 'schedule_demo', 'desc': 'Automated cron task scheduler and queue timeline manager.', 'comps': 'TIASchedule', 'how': 'Resolves task dependency trees using cron configurations and saves setups to JSON.'},
        {'name': 'hardware_net_demo', 'desc': 'Advanced hardware, network, PLC, and IoT client showcase.', 'comps': 'TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture', 'how': 'Captures video frames, reads MQTT broker topics, sends emails, bridges Profinet CLPs, and logs global events.'},
        {'name': 'graphmap_demo', 'desc': 'Text classification and routing using weighted token graph maps.', 'comps': 'TAIGraphMap', 'how': 'Allows adding training phrases and target categories, training the model, and visualizing category ranking and weight-based explanations.'},
        {'name': 'tripo3d_demo', 'desc': '3D model generation using Tripo3D API (Image-to-3D / Text-to-3D).', 'comps': 'TAITripo3DClient, TAI3DModelViewer, TAIModel3D', 'how': 'Sends images or text to the Tripo3D API, monitors the task progress, and renders the output STL/OBJ mesh in OpenGL.'},
        {'name': 'opencv_vision_demo', 'desc': 'Visual capture, processing, and tracking utilizing the AI Vision suite.', 'comps': 'TAIOpenCV, TAICameraCapture, TAIFrameProcessor, TAIFaceTracker, TAIMotionTracker', 'how': 'Graphical interface for camera control, grayscale/equalization filtering, and real-time face/motion tracking.'},
        {'name': 'opengl_graphic_demo', 'desc': 'Interactive OpenGL 2D/3D scene and 3D model viewer showcase.', 'comps': 'TAIScene2D3D, TAI3DModelViewer, TAIModel3D', 'how': 'Controls visual grids, axes, simulation states, cameras, and renders 3D mesh files in real-time.'}
    ]
}

# Fill remaining languages using translation maps to avoid huge files
translations = {
    'es': {'visual_demo': 'Central unificada con pestañas de prueba.', 'voicesynthesizer_demo': 'Sintetizador de voz nativo (TTS).', 'yolo_demo': 'Detección profunda YOLOv8.', 'cnn_demo': 'Clasificación profunda de imágenes MobileNetV2.', 'lstm_demo': 'Predicción gráfica de series temporales LSTM.', 'face_detection_demo': 'Identificación facial en tiempo real OpenCV.', 'python_demo': 'Consola interativa del intérprete Python.', 'neural_network_demo': 'Entrenamiento XOR local MLP.', 'perceptron_demo': 'Entrenador de compuertas lógicas perceptrón.', 'som_demo': 'Agrupamiento de colores en rejilla Kohonen.', 'tokenizer_demo': 'Segmentación y tokenización de cadenas.', 'image_filters_demo': 'Procesamiento de filtros de imagem en Pascal.', 'sound_filters_demo': 'Procesamiento DSP y modulación de sinais.', 'schedule_demo': 'Programador de tareas periódicas cron.', 'hardware_net_demo': 'Demostración de hardware, redes, PLC y MQTT.', 'graphmap_demo': 'Clasificación de texto y enrutamiento usando mapas de grafos ponderados de tokens.', 'tripo3d_demo': 'Generación de modelos 3D a través de la API Tripo3D (Image-to-3D / Text-to-3D).', 'opencv_vision_demo': 'Captura, procesamiento y seguimiento visual usando la suite AI Vision.', 'opengl_graphic_demo': 'Demostración interactiva OpenGL de escena 2D/3D y visualizador.'},
    'fr': {'visual_demo': 'Centre unifié de contrôle IA avec onglets.', 'voicesynthesizer_demo': 'Synthétiseur de voix natif (TTS).', 'yolo_demo': 'Détection d\'objets YOLOv8.', 'cnn_demo': 'Classification d\'images MobileNetV2.', 'lstm_demo': 'Prédiction temporelle graphique LSTM.', 'face_detection_demo': 'Reconnaissance faciale OpenCV.', 'python_demo': 'Console interactive pour Python.', 'neural_network_demo': 'Entraînement local XOR MLP.', 'perceptron_demo': 'Entraînement de portes logiques perceptron.', 'som_demo': 'Classification de couleurs Kohonen.', 'tokenizer_demo': 'Segmentation de texte et tokenisation.', 'image_filters_demo': 'Filtres d\'image natifs dans Pascal.', 'sound_filters_demo': 'Traitement du signal DSP et modulations.', 'schedule_demo': 'Planificateur de tâches cron.', 'hardware_net_demo': 'Démo avancée matériels, réseaux, API et MQTT.', 'graphmap_demo': 'Classification et routage de texte par cartes de graphes de jetons pondérés.', 'tripo3d_demo': 'Génération de modèles 3D via l\'API Tripo3D (Image-to-3D / Text-to-3D).', 'opencv_vision_demo': 'Capture, traitement et suivi visuels à l\'aide de la suite AI Vision.', 'opengl_graphic_demo': 'Démo interactive OpenGL de scène 2D/3D et visualiseur.'},
    'it': {'visual_demo': 'Centro di controllo IA unificato con schede.', 'voicesynthesizer_demo': 'Sintetizzatore vocale nativo (TTS).', 'yolo_demo': 'Rilevamento profondo oggetti YOLOv8.', 'cnn_demo': 'Classificazione immagini MobileNetV2.', 'lstm_demo': 'Previsione grafica serie temporali LSTM.', 'face_detection_demo': 'Rilevamento volti OpenCV.', 'python_demo': 'Playground interattivo per Python.', 'neural_network_demo': 'Addestramento locale XOR MLP.', 'perceptron_demo': 'Addestratore porte logiche perceptron.', 'som_demo': 'Clustering topologico colori Kohonen.', 'tokenizer_demo': 'Segmentazione e tokenizzazione stringhe.', 'image_filters_demo': 'Filtri d\'immagine in canvas Pascal.', 'sound_filters_demo': 'Elaborazione segnali DSP e modulazioni.', 'schedule_demo': 'Pianificatore compiti basato su cron.', 'hardware_net_demo': 'Demo hardware, reti, PLC e broker MQTT.', 'graphmap_demo': 'Classificazione e instradamento del testo tramite mappe di grafi di token pesati.', 'tripo3d_demo': 'Generazione di modelli 3D tramite l\'API Tripo3D (Image-to-3D / Text-to-3D).', 'opencv_vision_demo': 'Acquisizione visiva, elaborazione e tracciamento utilizzando la suite AI Vision.', 'opengl_graphic_demo': 'Demo OpenGL interattiva di scene 2D/3D e visualizzatore di modelli.'},
    'ar': {'visual_demo': 'مركز تحكم ذكاء اصطناعي موحد مع تبويبات.', 'voicesynthesizer_demo': 'مخلق الصوت والترجمة الصوتية (TTS).', 'yolo_demo': 'رصد واكتشاف الكائنات YOLOv8 عميق.', 'cnn_demo': 'تصنيف الصور باستخدام شبكة MobileNetV2.', 'lstm_demo': 'التنبؤ البياني بالسلاسل الزمنية LSTM.', 'face_detection_demo': 'اكتشاف وتحديد الوجوه OpenCV.', 'python_demo': 'بيئة عمل تفاعلية للغة بايثون.', 'neural_network_demo': 'تدريب XOR محلي للشبكات MLP.', 'perceptron_demo': 'تدريب البوابات المنطقية العصبية perceptron.', 'som_demo': 'تجميع الألوان على شبكة Kohonen ذاتية التنظيم.', 'tokenizer_demo': 'تقسيم وتحليل الكلمات للنصوص.', 'image_filters_demo': 'فلاتر معالجة الصور ومصفوفاتها.', 'sound_filters_demo': 'معالجة الإشارات الصوتية DSP وتعديلها.', 'schedule_demo': 'مجدول المهام الدورية والزمنية cron.', 'hardware_net_demo': 'عرض متكامل لأتمتة الأجهزة، الشبكات، والتحكم الصناعي.', 'graphmap_demo': 'تصنيف وتوجيه النصوص باستخدام خرائط الرسوم البيانية الموزونة للرموز.', 'tripo3d_demo': 'إنشاء نماذج ثلاثية الأبعاد عبر واجهة برمجة تطبيقات Tripo3D (صورة إلى ثلاثي الأبعاد / نص إلى ثلاثي الأبعاد).', 'opencv_vision_demo': 'التقاط ومعالجة وتتبع مرئي باستخدام مجموعة AI Vision.', 'opengl_graphic_demo': 'عرض رسومي تفاعلي OpenGL للمشهد ثنائي/ثلاثي الأبعاد ومستعرض النماذج.'}
}

console_samples = {
    'pt': [
        '**aivoicesynthesizer_sample.lpr**: Invocação direta de sintetização síncrona/assíncrona de voz via console.',
        '**chatgpt_sample.lpr**: Envio de perguntas e auditoria de respostas brutas em OpenAI, Claude e Gemini.',
        '**aicodeassistant_sample.lpr**: Rotina em console para otimização e documentação automática de código pascal.',
        '**aidatasetgenerator_sample.lpr**: Loop de compilação e exportação de base de dados em formato JSONL.',
        '**neuralnetwork_sample.lpr**: Treinamento clássico de perceptron multicamadas XOR em Pascal puro.',
        '**graphmap_basic.lpr**: Exemplo básico de console para classificação explicável de textos via grafos ponderados.'
    ],
    'en': [
        '**aivoicesynthesizer_sample.lpr**: Direct console Text-to-Speech synthesis invocation demo.',
        '**chatgpt_sample.lpr**: Quick command-line questions and payload auditing for OpenAI, Claude, and Gemini.',
        '**aicodeassistant_sample.lpr**: Command-line routine for code auditing, optimizations, and doc formatting.',
        '**aidatasetgenerator_sample.lpr**: Auto-generation loop and JSONL conversations dataset exporter.',
        '**neuralnetwork_sample.lpr**: Classic MLP training XOR convergence simulator in console.',
        '**graphmap_basic.lpr**: Basic console sample for explainable text classification using weighted graph maps.'
    ],
    'es': [
        '**aivoicesynthesizer_sample.lpr**: Síntesis de voz directa en consola de forma síncrona/asíncrona.',
        '**chatgpt_sample.lpr**: Preguntas rápidas y auditoría de payloads de OpenAI, Claude y Gemini.',
        '**aicodeassistant_sample.lpr**: Optimización y documentación automática de código Pascal por consola.',
        '**aidatasetgenerator_sample.lpr**: Bucle de geração y exportación de bases de datos JSONL.',
        '**neuralnetwork_sample.lpr**: Entrenamiento clásico XOR de perceptrón multicapa MLP en Pascal.',
        '**graphmap_basic.lpr**: Ejemplo básico de consola para la clasificación explicable de textos mediante grafos ponderados.'
    ],
    'fr': [
        '**aivoicesynthesizer_sample.lpr**: Démo directe de synthèse vocale s\'exécutant en console.',
        '**chatgpt_sample.lpr**: Requêtes rapides et inspection de payloads pour OpenAI, Claude et Gemini.',
        '**aicodeassistant_sample.lpr**: Routine console pour l\'optimisation et documentation de code.',
        '**aidatasetgenerator_sample.lpr**: Génération et exportation automatisée de datasets JSONL.',
        '**neuralnetwork_sample.lpr**: Entraînement classique XOR d\'un perceptron multicouche MLP.',
        '**graphmap_basic.lpr**: Exemple console de base pour la classification explicable de textes via des graphes pondérés.'
    ],
    'it': [
        '**aivoicesynthesizer_sample.lpr**: Sintesi vocale da riga di comando sincrona e asincrona.',
        '**chatgpt_sample.lpr**: Invio rapido domande e ispezione dei payload per OpenAI, Claude e Gemini.',
        '**aicodeassistant_sample.lpr**: Ottimizzazione e documentazione codice Pascal automatica da riga di comando.',
        '**aidatasetgenerator_sample.lpr**: Generazione ed esportazione di dataset per fine-tuning in formato JSONL.',
        '**neuralnetwork_sample.lpr**: Simulatore di addestramento MLP XOR scritto in Pascal.',
        '**graphmap_basic.lpr**: Esempio console di base per la classificazione spiegabile di testi tramite grafi pesati.'
    ],
    'ar': [
        '**aivoicesynthesizer_sample.lpr**: استدعاء مباشر لتخليق الأصوات عبر الكونسول بشكل متزامن وغير متزامن.',
        '**chatgpt_sample.lpr**: إرسال سريع للأسئلة وفحص البيانات الخام المستلمة من OpenAI, Claude, Gemini.',
        '**aicodeassistant_sample.lpr**: أتمتة تحسين وفحص كود باسكال عبر سطر الأوامر.',
        '**aidatasetgenerator_sample.lpr**: إنشاء وتصدير مجموعات البيانات لتدريب النماذج بصيغة JSONL.',
        '**neuralnetwork_sample.lpr**: محاكي تدريب XOR للشبكات العصبية متعددة الطبقات بلغة باسكال الخالصة.',
        '**graphmap_basic.lpr**: مثال كونسول بسيط لتصنيف النصوص القابل للتفسير باستخدام خرائط الرسوم البيانية الموزونة.'
    ]
}

def generate():
    samples_root = r"D:\projetos\maurinsoft\CHATGPT\pacote\samples"
    for lang_code, lang_trans in langs.items():
        filename = f"README.{lang_code}.md"
        filepath = os.path.join(samples_root, filename)
        
        # Build markdown content
        content = []
        content.append(f"# 📂 {lang_trans['title']}")
        content.append("")
        content.append(f"> [!NOTE]")
        content.append(f"> {lang_trans['intro']}")
        content.append("")
        content.append(f"## {lang_trans['gui_title']}")
        content.append(lang_trans['gui_desc'])
        content.append("")
        
        # GUI Samples
        content.append(f"| {lang_trans['item_title']} | {lang_trans['item_desc']} | {lang_trans['item_comps']} | {lang_trans['item_how']} |")
        content.append("|---|---|---|---|")
        
        # Get GUI data
        if lang_code in gui_samples:
            items = gui_samples[lang_code]
        else:
            # Fallback reconstruction using translation map
            items = []
            en_items = gui_samples['en']
            trans_map = translations[lang_code]
            for it in en_items:
                name = it['name']
                desc = trans_map.get(name, it['desc'])
                items.append({
                    'name': name,
                    'desc': desc,
                    'comps': it['comps'],
                    'how': it['how']  # Keep English details for how it works fallback
                })
                
        for item in items:
            # Dynamically resolve relative path of the sample directory to avoid broken links
            rel_dir = item['name']
            for root_walk, dirs_walk, files_walk in os.walk(samples_root):
                if item['name'] in dirs_walk:
                    rel_dir = os.path.relpath(os.path.join(root_walk, item['name']), samples_root).replace('\\', '/')
                    break
            content.append(f"| **[{item['name']}/]({rel_dir}/)** | {item['desc']} | `{item['comps']}` | {item['how']} |")
            
        content.append("")
        content.append(f"## {lang_trans['console_title']}")
        content.append(lang_trans['console_desc'])
        content.append("")
        
        # Console Samples list
        for sample in console_samples[lang_code]:
            content.append(f"*   {sample}")
            
        content.append("")
        
        # Save file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write("\n".join(content))
            
        print(f"Generated Samples: {filepath}")

if __name__ == '__main__':
    generate()
