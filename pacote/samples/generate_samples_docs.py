# -*- coding: utf-8 -*-
import os
import re
import xml.etree.ElementTree as ET

# Configuration of languages and translations for headers
langs = {
    'pt': {
        'title': 'Projetos de Demonstração (Samples)',
        'intro': 'Este diretório contém a suíte completa de exemplos desenvolvidos para demonstrar e testar todos os componentes de Inteligência Artificial, Aprendizado de Máquina (Machine Learning), Processamento de Imagens, Processamento de Sinais (DSP), Automação de Hardware e Geração de Documentos da Lazarus AI Suite.',
        'gui_title': '🖥️ Demonstrações em Interface Gráfica (GUI)',
        'gui_desc': 'Os exemplos a seguir são projetos visuais prontos para compilação e execução interativa através do Lazarus:',
        'console_title': '💻 Demonstrações em Linha de Comando (Console)',
        'console_desc': 'Estes exemplos demonstram a invocação direta de componentes via linha de comando para cenários de depuração rápida ou automação de rotinas:',
        'col_sample': 'Exemplo',
        'col_path': 'Caminho',
        'col_desc': 'Descrição',
        'no_desc': 'Nenhuma descrição disponível.',
        'category': 'Categoria'
    },
    'en': {
        'title': 'Demonstration Projects (Samples)',
        'intro': 'This directory contains the complete suite of examples developed to demonstrate and test all Artificial Intelligence, Machine Learning, Image Processing, Digital Signal Processing (DSP), Hardware Automation, and Document Generation components of the Lazarus AI Suite.',
        'gui_title': '🖥️ Graphical User Interface (GUI) Demonstrations',
        'gui_desc': 'The following examples are visual projects ready for compilation and interactive execution through Lazarus:',
        'console_title': '💻 Command Line Interface (Console) Demonstrations',
        'console_desc': 'These examples demonstrate direct component invocation via command line for rapid debugging or automation scenarios:',
        'col_sample': 'Sample',
        'col_path': 'Path',
        'col_desc': 'Description',
        'no_desc': 'No description available.',
        'category': 'Category'
    },
    'es': {
        'title': 'Proyectos de Demostración (Samples)',
        'intro': 'Este directorio contiene la suite completa de ejemplos desarrollados para demostrar y probar todos los componentes de Inteligencia Artificial, Aprendizaje Automático (Machine Learning), Procesamiento de Imágenes, Procesamiento de Señales (DSP), Automatización de Hardware y Generación de Documentos de la suite Lazarus AI Suite.',
        'gui_title': '🖥️ Demostraciones de Interfaz Gráfica (GUI)',
        'gui_desc': 'Los siguientes ejemplos son proyectos visuales listos para compilar y ejecutar interactivamente en Lazarus:',
        'console_title': '💻 Demostraciones de Línea de Comando (Consola)',
        'console_desc': 'Estos ejemplos demuestran la invocación directa de componentes a través de la línea de comandos para depuración rápida o automatización:',
        'col_sample': 'Ejemplo',
        'col_path': 'Ruta',
        'col_desc': 'Descripción',
        'no_desc': 'Sin descripción disponible.',
        'category': 'Categoría'
    },
    'fr': {
        'title': 'Projets de Démonstration (Samples)',
        'intro': 'Ce dossier contient la suite complète d\'exemples développés pour tester tous les composants d\'Intelligence Artificielle, d\'Apprentissage Automatique, de traitement d\'images, de traitement de signaux (DSP), d\'automatisation matérielle et de génération de documents de la suite Lazarus AI Suite.',
        'gui_title': '🖥️ Démonstrations en Interface Graphique (GUI)',
        'gui_desc': 'Les exemples suivants sont des projets visuels prêts à être compilés et exécutés via Lazarus :',
        'console_title': '💻 Démonstrations en Ligne de Commande (Console)',
        'console_desc': 'Ces exemples illustrent l\'utilisation directe des composants en ligne de commande pour le débogage rapide :',
        'col_sample': 'Exemple',
        'col_path': 'Chemin',
        'col_desc': 'Description',
        'no_desc': 'Aucune description disponible.',
        'category': 'Catégorie'
    },
    'it': {
        'title': 'Progetti di Dimostrazione (Samples)',
        'intro': 'Questa directory contiene la suite completa di esempi sviluppati per dimostrare e testare tutti i componenti di Intelligenza Artificiale, Machine Learning, Elaborazione Immagini, Elaborazione Segnali (DSP), Automazione Hardware e Geração Documenti della suite Lazarus AI Suite.',
        'gui_title': '🖥️ Demo ad Interfaccia Grafica (GUI)',
        'gui_desc': 'I seguenti esempi sono progetti visuali pronti per la compilazione e l\'esecuzione interattiva tramite Lazarus:',
        'console_title': '💻 Demo a Riga di Comando (Console)',
        'console_desc': 'Questi esempi mostrano l\'invocazione diretta dei componentes da riga di comando per debug rapido o automazione:',
        'col_sample': 'Esempio',
        'col_path': 'Percorso',
        'col_desc': 'Descrizione',
        'no_desc': 'Nessuna descrizione disponível.',
        'category': 'Categoria'
    },
    'ar': {
        'title': 'مشاريع توضيحية (Samples)',
        'intro': 'يحتوي هذا المجلد على مجموعة كاملة من الأمثلة والمشاريع المطورة لتوضيح واختبار جميع مكونات الذكاء الاصطناعي، تعلم الآلة، معالجة الصور، معالجة الإشارات الرقمية (DSP)، أتمتة الأجهزة، وتوليد المستندات لحزمة Lazarus AI Suite.',
        'gui_title': '🖥️ مشاريع توضيحية لواجهات المستخدم الرسومية (GUI)',
        'gui_desc': 'الأمثلة التالية عبارة عن مشاريع مرئية جاهزة للتجميع والتشغيل التفاعلي عبر لازاروس:',
        'console_title': '💻 مشاريع توضيحية لسطر الأوامر (Console)',
        'console_desc': 'توضح هذه الأمثلة الاستدعاء المباشر للمكونات عبر سطر الأوامر لسيناريوهات تصحيح الأخطاء السريعة وأتمتة العمليات الدورية:',
        'col_sample': 'المشروع',
        'col_path': 'المسار',
        'col_desc': 'الوصف',
        'no_desc': 'لا يوجد وصف متاح.',
        'category': 'الفئة'
    }
}

# Explicit localized translations for all samples on disk
SAMPLE_DESCRIPTIONS = {
    'visual_demo': {
        'pt': 'Playground unificado reunindo várias demonstrações visuais e abas de teste.',
        'en': 'Unified control playground combining multiple visual demos and testing tabs.',
        'es': 'Área de juegos unificada que reúne varias demostraciones visuales y pestañas de prueba.',
        'fr': 'Espace d\'essai unifié regroupant plusieurs démos visuelles et onglets de test.',
        'it': 'Playground unificato che unisce varie demo visive e schede di test.',
        'ar': 'منطقة تجريبية موحدة تجمع بين عروض مرئية متعددة وتبويبات اختبار.'
    },
    'voicesynthesizer_demo': {
        'pt': 'Demonstração de sintetização de voz (Text-to-Speech) nativa e multiplataforma.',
        'en': 'Text-to-Speech synthesis demonstration, native and cross-platform.',
        'es': 'Demostración de síntesis de voz (Text-to-Speech) nativa y multiplataforma.',
        'fr': 'Démonstration de synthèse vocale (Text-to-Speech) native et multiplateforme.',
        'it': 'Dimostrazione di sintesi vocale (Text-to-Speech) nativa e multipiattaforma.',
        'ar': 'عرض توضيحي لتوليد الكلام (Text-to-Speech) بشكل أصلي ومتعدد المنصات.'
    },
    'voice_synthesizer_complete_demo': {
        'pt': 'Demonstração completa de sintetização de voz com controles adicionais de áudio.',
        'en': 'Complete Text-to-Speech voice synthesis demonstration with additional audio controls.',
        'es': 'Demostración completa de síntesis de voz con controles de audio adicionales.',
        'fr': 'Démonstration complète de synthèse vocale avec contrôles audio supplémentaires.',
        'it': 'Dimostrazione completa di sintesi vocale con controlli audio aggiuntivi.',
        'ar': 'عرض توضيحي كامل لتوليد الكلام مع عناصر تحكم إضافية في الصوت.'
    },
    'yolo_demo': {
        'pt': 'Detecção profunda de objetos com YOLOv8 via integração Python.',
        'en': 'Deep object detection using YOLOv8 via Python integration.',
        'es': 'Detección profunda de objetos con YOLOv8 a través de la integración de Python.',
        'fr': 'Détection d\'objets approfondie avec YOLOv8 via l\'intégration Python.',
        'it': 'Rilevamento profondo degli oggetti con YOLOv8 tramite integrazione Python.',
        'ar': 'الكشف العميق عن الكائنات باستخدام YOLOv8 عبر تكامل بايثون.'
    },
    'cnn_demo': {
        'pt': 'Classificação de imagens usando redes convolucionais com TensorFlow e Python.',
        'en': 'Image classification using convolutional neural networks with TensorFlow and Python.',
        'es': 'Clasificación de imágenes mediante redes convolucionales con TensorFlow y Python.',
        'fr': 'Classification d\'images par réseaux convolutifs avec TensorFlow et Python.',
        'it': 'Classificazione delle immagini tramite reti convoluzionali con TensorFlow e Python.',
        'ar': 'تصنيف الصور باستخدام الشبكات التلافيفية مع TensorFlow وبايثون.'
    },
    'lstm_demo': {
        'pt': 'Previsão gráfica de séries temporais com modelo LSTM via Python.',
        'en': 'Graphical time-series trend forecasting with LSTM models via Python.',
        'es': 'Predicción gráfica de tendencias de series temporales con modelos LSTM a través de Python.',
        'fr': 'Prévision graphique des tendances de séries temporelles avec des modèles LSTM via Python.',
        'it': 'Previsione grafica delle tendenze delle serie temporali con modelli LSTM tramite Python.',
        'ar': 'التنبؤ البياني باتجاهات السلاسل الزمنية باستخدام نماذج LSTM عبر بايثون.'
    },
    'face_detection_demo': {
        'pt': 'Detecção e rastreamento facial em tempo real com OpenCV.',
        'en': 'Real-time face detection and tracking using OpenCV.',
        'es': 'Detección y seguimiento facial en tiempo real con OpenCV.',
        'fr': 'Détection et suivi facial en temps réel avec OpenCV.',
        'it': 'Rilevamento e tracciamento facciale in tempo real con OpenCV.',
        'ar': 'رصد وتتبع الوجه في الوقت الفعلي باستخدام OpenCV.'
    },
    'python_demo': {
        'pt': 'Playground interativo para testes e execução de scripts Python.',
        'en': 'Interactive workspace for running and testing Python scripts.',
        'es': 'Consola interactiva para ejecutar y probar scripts de Python.',
        'fr': 'Espace de travail interactif pour exécuter et tester des scripts Python.',
        'it': 'Console interattiva per l\'esecuzione e il test di script Python.',
        'ar': 'مساحة trabalho تفاعلية لتشغيل واxtبار نصوص بايثون.'
    },
    'neural_network_demo': {
        'pt': 'Treinamento e visualização local de redes neurais multicamadas (MLP).',
        'en': 'Local training and visualization of multilayer perceptron (MLP) neural networks.',
        'es': 'Entrenamiento y visualización local de redes neuronales perceptrón multicapa (MLP).',
        'fr': 'Entraînement local et visualisation de réseaux de neurones perceptron multicouche (MLP).',
        'it': 'Addestramento locale e visualizzazione di reti neurali a perceptrone multistrato (MLP).',
        'ar': 'التدريب المحلي والعرض المرئي للشبكات العصبية متعددة الطبقات (MLP).'
    },
    'perceptron_demo': {
        'pt': 'Visualizador interativo do treinamento de um perceptron simples de camada única.',
        'en': 'Interactive visualizer for single-layer perceptron training on logic gates.',
        'es': 'Visualizador interactivo del entrenamiento de un perceptrón simple de una sola capa.',
        'fr': 'Visualisateur interactif de l\'entraînement d\'un perceptron simple à couche unique.',
        'it': 'Visualizzatore interattivo dell\'addestramento di un perceptrone a singolo strato.',
        'ar': 'مستعرض تفاعلي لتدريب البيرسبترون أحادي الطبقة على البوابات المنطقية.'
    },
    'som_demo': {
        'pt': 'Agrupamento topológico visual de cores usando redes Self-Organizing Maps.',
        'en': 'Visual topological clustering of colors using Self-Organizing Maps.',
        'es': 'Agrupación topológica visual de colores utilizando mapas autoorganizados (SOM).',
        'fr': 'Classification topologique visuelle des couleurs à l\'aide de cartes auto-organisées (SOM).',
        'it': 'Clustering topologico visivo dei colori tramite mappe auto-organizzanti (SOM).',
        'ar': 'التجميع الطوبولوجي المرئي للألوان باستخدام الخرائط ذاتية التنظيم (SOM).'
    },
    'tokenizer_demo': {
        'pt': 'Demonstração de processamento, segmentação e tokenização de textos.',
        'en': 'Text processing, segmentation, and tokenization utility demo.',
        'es': 'Demostración de utilidades de procesamiento, segmentación y tokenización de textos.',
        'fr': 'Démonstration d\'utilitaires de traitement, segmentation et tokenisation de texte.',
        'it': 'Dimostrazione di elaborazione, segmentazione e tokenizzazione di testi.',
        'ar': 'عرض توضيحي لأدوات معالجة النصوص وتقسيمها وتحليل الكلمات.'
    },
    'image_filters_demo': {
        'pt': 'Processamento matricial de filtros de imagem nativos em canvas Pascal.',
        'en': 'Matrix processing of native image filters on Pascal canvas.',
        'es': 'Procesamiento matricial de filtros de imagem nativos en canvas de Pascal.',
        'fr': 'Traitement matriciel de filtres d\'image natifs sur canvas Pascal.',
        'it': 'Elaborazione matriciale di filtri d\'immagine nativi su canvas Pascal.',
        'ar': 'المعالجة المصفوفية لفلاتر الصور الأصلية على لوحة رسم باسكال.'
    },
    'sound_filters_visual_demo': {
        'pt': 'Demonstração visual de processamento e filtragem de sinais de áudio em tempo real (Low-pass, High-pass, Moving average).',
        'en': 'Visual demonstration of real-time audio signal processing and filtering (Low-pass, High-pass, Moving average).',
        'es': 'Demostración visual del procesamiento y filtración de señales de audio en tiempo real.',
        'fr': 'Démonstration visuelle du traitement et filtrage de signaux audio en temps réel.',
        'it': 'Dimostrazione visiva dell\'elaborazione e filtraggio di segnali audio in tempo reale.',
        'ar': 'عرض مرئي لمعالجة وتصفية إشارات الصوت في الوقت الفعلي.'
    },
    'schedule_demo': {
        'pt': 'Gerenciamento estruturado de cronogramas e fila de tarefas baseadas em cron.',
        'en': 'Structured cron-based task scheduling and queue timeline management.',
        'es': 'Gestión estructurada de cronogramas y tareas basadas en cron.',
        'fr': 'Gestion structurée de tâches planifiées basées sur cron.',
        'it': 'Gestione strutturata di pianificazioni e attività basate su cron.',
        'ar': 'إدارة هيكلية لجدولة المهام والخطوط الزمنية المستندة إلى cron.'
    },
    'hardware_net_demo': {
        'pt': 'Demonstração de integração com câmeras, brokers MQTT, e-mails e pontes CLP.',
        'en': 'Showcase integrating cameras, MQTT brokers, emails, and PLC bridges.',
        'es': 'Integración de cámaras, brokers MQTT, correos electrónicos y puentes PLC.',
        'fr': 'Intégration de caméras, brokers MQTT, e-mails et passerelles API.',
        'it': 'Integrazione di telecamere, broker MQTT, e-mail e bridge PLC.',
        'ar': 'عرض متكامل يجمع الكاميرات، ووسطاء MQTT، والبريد الإلكتروني، وجسور PLC.'
    },
    'graphmap_demo': {
        'pt': 'Classificação e mapeamento de texto usando grafos de tokens ponderados.',
        'en': 'Text classification and routing using weighted token graph maps.',
        'es': 'Clasificación de texto y enrutamiento usando mapas de grafos de tokens ponderados.',
        'fr': 'Classification et routage de texte à l\'aide de cartes de graphes de jetons pondérés.',
        'it': 'Classificazione e instradamento del testo tramite mappe di grafi di token pesati.',
        'ar': 'تصنيف النصوص وتوجيهها باستخدام خرائط الرسوم البيانية الموزونة للرموز.'
    },
    'tripo3d_demo': {
        'pt': 'Geração de malhas 3D a partir de texto ou imagens usando a API Tripo3D.',
        'en': '3D mesh generation from text or images using the Tripo3D API.',
        'es': 'Generación de malla 3D a partir de texto o imágenes mediante la API Tripo3D.',
        'fr': 'Génération de maillages 3D à partir de texte ou d\'images via l\'API Tripo3D.',
        'it': 'Generazione di mesh 3D da testo o immagini utilizzando l\'API Tripo3D.',
        'ar': 'إنشاء مجسمات ثلاثية الأبعاد من النصوص أو الصور باستخدام واجهة برمجة تطبيقات Tripo3D.'
    },
    'opencv_vision_demo': {
        'pt': 'Playground visual completo de controle de câmera, filtros e face tracking OpenCV.',
        'en': 'Visual playground for camera control, filters, and OpenCV face tracking.',
        'es': 'Panel visual de control de cámara, filtros y seguimiento facial OpenCV.',
        'fr': 'Espace d\'essai visuel pour le contrôle de caméra, filtres et suivi facial OpenCV.',
        'it': 'Playground visivo per controllo telecamera, filtri e face tracking OpenCV.',
        'ar': 'بيئة تجريبية مرئية للتحكم في الكاميرا، والفلاتر، وتتبع الوجه باستخدام OpenCV.'
    },
    'opengl_graphic_demo': {
        'pt': 'Renderização gráfica interactiva 3D com grids, luzes e OpenGL nativo.',
        'en': 'Interactive 3D graphic rendering with grids, lighting, and native OpenGL.',
        'es': 'Renderizado gráfico interactivo 3D con rejillas, luces y OpenGL nativo.',
        'fr': 'Rendu graphique 3D interactif avec grilles, lumières et OpenGL natif.',
        'it': 'Rendering grafico 3D interattivo con griglie, luci e OpenGL nativo.',
        'ar': 'عرض رسومي تفاعلي ثلاثي الأبعاد مع الشبكات والإضاءة والـ OpenGL الأصلي.'
    },
    'db_dictionary_demo': {
        'pt': 'Extrator visual de dicionário de dados e metadados de bancos SQLite/PostgreSQL.',
        'en': 'Visual data dictionary and metadata extractor for SQLite/PostgreSQL databases.',
        'es': 'Extractor visual de diccionarios de datos y metadatos para SQLite/PostgreSQL.',
        'fr': 'Extracteur visuel de dictionnaire de données et métadonnées SQLite/PostgreSQL.',
        'it': 'Estrattore visuale di dizionari dati e metadati per database SQLite/PostgreSQL.',
        'ar': 'مستخرج مرئي لقاموس البيانات والبيانات التعريفية لقواعد بيانات SQLite/PostgreSQL.'
    },
    'ai_sqlite_query_assistant_demo': {
        'pt': 'Assistente de consulta SQL em linguagem natural usando ChatGPT e SQLite.',
        'en': 'Natural language SQL query assistant powered by ChatGPT and SQLite.',
        'es': 'Asistente de consultas SQL en lenguaje natural con ChatGPT y SQLite.',
        'fr': 'Assistant de requêtes SQL en langage naturel alimenté par ChatGPT et SQLite.',
        'it': 'Assistente alle query SQL in linguaggio naturale alimentato da ChatGPT e SQLite.',
        'ar': 'مساعد استعلام SQL باللغة الطبيعية مدعوم من ChatGPT و SQLite.'
    },
    'agent_demo': {
        'pt': 'Simulação de agentes inteligentes autônomos para tomada de decisão e disparo de saídas.',
        'en': 'Simulation of intelligent autonomous agents for decision making and action execution.',
        'es': 'Simulación de agentes autónomos inteligentes para la toma de decisiones.',
        'fr': 'Simulation d\'agents intelligents autonomes pour la prise de décision.',
        'it': 'Simulazione di agenti intelligenti autonomi per il processo decisionale.',
        'ar': 'محاكاة الوكلاء الأذكياء المستقلين لاتخاذ القرارات وتنفيذ الإجراءات.'
    },
    'codeassistant_demo': {
        'pt': 'Assistente interativo de código para refatoração e documentação automática em Pascal.',
        'en': 'Interactive code assistant for automatic refactoring and documentation in Pascal.',
        'es': 'Asistente de código interactivo para refactorización y documentación automática en Pascal.',
        'fr': 'Assistant de code interactif pour la refactorisation et documentation automatique en Pascal.',
        'it': 'Assistente di codice interattivo per refactoring e documentazione automatica in Pascal.',
        'ar': 'مساعد برمجيات تفاعلي لإعادة هيكلة وتوثيق التعليمات البرمجية تلقائيًا في باسكال.'
    },
    'modelregistry_demo': {
        'pt': 'Gerenciamento e registro centralizado de modelos de linguagem inteligência artificial.',
        'en': 'Centralized management and registry for AI language models.',
        'es': 'Gestión y registro centralizado de modelos de lenguaje de IA.',
        'fr': 'Gestion et registre centralisé des modèles de langage IA.',
        'it': 'Gestione e registro centralizzato dei modelli di linguaggio IA.',
        'ar': 'إدارة وسجل مركزي لنماذج الذكاء الاصطناعي اللغوية.'
    },
    'pipeline_full_demo': {
        'pt': 'Criação e execução de pipelines complexos de processamento sequencial de texto.',
        'en': 'Creation and execution of complex pipelines for sequential text processing.',
        'es': 'Creación y ejecución de pipelines complejos para el procesamiento secuencial de texto.',
        'fr': 'Création et exécution de pipelines complexes pour le traitement séquentiel de texte.',
        'it': 'Creazione ed esecuzione di pipeline complesse per l\'elaborazione sequenziale del testo.',
        'ar': 'إنشاء وتشغيل خطوط معالجة معقدة لمعالجة النصوص التسلسلية.'
    },
    'promptbuilder_demo': {
        'pt': 'Ferramenta visual de construção, modelagem e otimização de prompts de IA.',
        'en': 'Visual tool for building, modeling, and optimizing AI prompts.',
        'es': 'Herramienta visual para construir, modelar y optimizar prompts de IA.',
        'fr': 'Outil visuel pour construire, modéliser et optimiser les prompts IA.',
        'it': 'Strumento visuale per la costruzione, modellazione e ottimizzazione dei prompt IA.',
        'ar': 'أداة مرئية لبناء وصياغة وتحسين نصوص التوجيه (prompts) للذكاء الاصطناعي.'
    },
    'wizard_config_demo': {
        'pt': 'Assistente interativo passo-a-passo para configuração inicial de projetos de IA.',
        'en': 'Step-by-step interactive wizard for initial setup of AI projects.',
        'es': 'Asistente interactivo paso a paso para la configuración inicial de proyectos de IA.',
        'fr': 'Assistant interactif étape par étape pour la configuration initiale de projets IA.',
        'it': 'Configurazione guidata interattiva passo-passo per l\'avvio di projetos IA.',
        'ar': 'معالج تفاعلي خطوة بخطوة للإعداد الأولي لمشاريع الذكاء الاصطناعي.'
    },
    'disk_tree_ai_dataset_demo': {
        'pt': 'Varredura e pesquisa de pastas em disco para montagem de bases de dados de IA.',
        'en': 'Disk folder scanning and querying to assemble custom AI training datasets.',
        'es': 'Escaneo de carpetas en disco para compilar conjuntos de datos de entrenamiento.',
        'fr': 'Analyse de dossiers sur disque pour assembler des ensembles de données d\'entraînement.',
        'it': 'Scansione di cartelle su disco per assemblare dataset di addestramento personalizzati.',
        'ar': 'فحص مجلدات القرص وجمع البيانات لتركيب مجموعات بيانات التدريب للذكاء الاصطناعي.'
    },
    'docfilesmanager_demo': {
        'pt': 'Gerenciador estruturado de arquivos de documentação do projeto.',
        'en': 'Structured manager for project documentation and text files.',
        'es': 'Gestor estructurado para la documentación y archivos de texto del proyecto.',
        'fr': 'Gestionnaire structuré pour la documentation et les fichiers texte du projet.',
        'it': 'Gestore strutturato per la documentazione e i file di testo del progetto.',
        'ar': 'مدير منظم لملفات الوثائق والنصوص الخاصة بالمشروع.'
    },
    'dataset_analyzer_demo': {
        'pt': 'Ferramenta gráfica de análise estatística de bases de treinamento.',
        'en': 'Graphical statistical analysis tool for training datasets.',
        'es': 'Herramienta gráfica de análisis estadístico de conjuntos de datos de entrenamiento.',
        'fr': 'Outil graphique d\'analyse statistique d\'ensembles de données d\'entraînement.',
        'it': 'Strumento grafico di analisi statistica dei dataset di addestramento.',
        'ar': 'أداة تحليل إحصائي رسومي لمجموعات بيانات التدريب.'
    },
    'graph_visualizer_demo': {
        'pt': 'Visualizador interativo de grafos e nós relacionais de termos.',
        'en': 'Interactive visualizer for relational node graphs of terms.',
        'es': 'Visualizador interactivo para grafos y nodos relacionales de términos.',
        'fr': 'Visualisateur interactif pour graphes et nœuds relationnels de termes.',
        'it': 'Visualizzatore interattivo per grafi e nodi relazionali di termini.',
        'ar': 'مستعرض تفاعلي لرسوم بيانية وربط العقد بين المصطلحات.'
    },
    'graphmap_basic': {
        'pt': 'Versão básica em linha de comando de classificação por mapa de grafos.',
        'en': 'Basic command-line version of text classification using graph maps.',
        'es': 'Versión básica de línea de comandos para la clasificación mediante mapas de grafos.',
        'fr': 'Version console de base pour la classification par cartes de graphes.',
        'it': 'Versione base da riga di comando per la classificazione tramite mappe di grafi.',
        'ar': 'نسخة سطر أوامر أساسية لتصنيف النصوص باستخدام خرائط الرسوم البيانية.'
    },
    'training_exporter_demo': {
        'pt': 'Exportador estruturado de dados de treinamento em mapas de relações.',
        'en': 'Structured exporter for training relation map data.',
        'es': 'Exportador estructurado para datos de entrenamiento en mapas de relaciones.',
        'fr': 'Exportateur structuré pour les données d\'entraînement en cartes de relations.',
        'it': 'Esportatore strutturato per dati di addestramento in mappe di relazioni.',
        'ar': 'مصدّر منظم لبيانات التدريب في خرائط العلاقات.'
    },
    'training_report_demo': {
        'pt': 'Gerador de relatórios visuais sobre o status do aprendizado em grafos.',
        'en': 'Visual report generator on the status of graph learning.',
        'es': 'Generador de informes visuales sobre el estado del aprendizaje en grafos.',
        'fr': 'Générateur de rapports visuels sur l\'état de l\'apprentissage par graphes.',
        'it': 'Generatore di report visivi sullo stato dell\'apprendimento nei grafi.',
        'ar': 'مولد تقارير مرئية حول حالة التعلم في الرسوم البيانية.'
    },
    'avatar_demo': {
        'pt': 'Playground visual de avatares com controle de esqueleto e malhas deformáveis.',
        'en': 'Visual avatar playground with skeleton control and deformable meshes.',
        'es': 'Panel visual de avatares con control de esqueleto y mallas deformables.',
        'fr': 'Espace d\'avatar visuel avec contrôle de squelette et maillages déformables.',
        'it': 'Playground visivo per avatar con controllo scheletrico e mesh deformabili.',
        'ar': 'منطقة تجريبية مرئية للصور الرمزية (avatars) مع التحكم في الهيكل العظمي والمجسمات.'
    },
    'model3d_viewer_demo': {
        'pt': 'Visualizador interativo de modelos tridimensionais e controle de câmera.',
        'en': 'Interactive 3D model viewer with camera control.',
        'es': 'Visualizador interactivo de modelos 3D con control de cámara.',
        'fr': 'Visualisateur interactif de modèles 3D avec contrôle de caméra.',
        'it': 'Visualizzatore interattivo di modelli 3D con controllo telecamera.',
        'ar': 'مستعرض تفاعلي للمجسمات ثلاثية الأبعاد مع التحكم في الكاميرا.'
    },
    'physics_training_demo': {
        'pt': 'Simulação física básica para treinamento de comportamento em tempo real.',
        'en': 'Basic physical simulation for real-time behavior training.',
        'es': 'Simulación física básica para el entrenamiento del comportamiento en tiempo real.',
        'fr': 'Simulation physique de base pour l\'entraînement du comportamento en temps réel.',
        'it': 'Simulazione fisica di base per l\'addestramento del comportamento in tempo reale.',
        'ar': 'محاكاة فيزيائية أساسية لتدريب السلوك في الوقت الفعلي.'
    },
    'pose_animation_demo': {
        'pt': 'Biblioteca e sequenciador interativo de poses corporais em modelos 3D.',
        'en': 'Body pose library and interactive sequencer for 3D models.',
        'es': 'Biblioteca de poses corporales y secuenciador interactivo para modelos 3D.',
        'fr': 'Bibliothèque de poses corporelles et séquenceur interactif pour modèles 3D.',
        'it': 'Libreria di pose corporee e sequenziatore interattivo per modelli 3D.',
        'ar': 'مكتبة وضعيات الجسم وجدولة حركية تفاعلية للمجسمات ثلاثية الأبعاد.'
    },
    'scene3d_demo': {
        'pt': 'Visualizador de cena 3D e controle de múltiplas câmeras em OpenGL.',
        'en': '3D scene viewer and multi-camera control using OpenGL.',
        'es': 'Visualizador de escenas 3D y control de múltiples cámaras con OpenGL.',
        'fr': 'Visualisateur de scènes 3D et contrôle multi-caméras avec OpenGL.',
        'it': 'Visualizzatore di scene 3D e controllo multi-camera con OpenGL.',
        'ar': 'مستعرض مشاهد ثلاثية الأبعاد والتحكم في كاميرات متعددة باستخدام OpenGL.'
    },
    'skeleton_rig_demo': {
        'pt': 'Controle de esqueleto em malhas e deformação de vértices gráficos 3D.',
        'en': 'Skeleton rig control and vertex deformation in 3D meshes.',
        'es': 'Control de esqueleto en mallas y deformación de vértices en gráficos 3D.',
        'fr': 'Contrôle de squelette et déformation de sommets dans les maillages 3D.',
        'it': 'Controllo scheletrico e deformazione dei vertici nelle mesh 3D.',
        'ar': 'التحكم في الهيكل العظمي وتشوه نقاط المجسمات ثلاثية الأبعاد.'
    },
    'industrial_bridge_demo': {
        'pt': 'Ponte de comunicação industrial ligando brokers IoT e CLPs.',
        'en': 'Industrial communication bridge linking IoT brokers and PLCs.',
        'es': 'Puente de comunicación industrial que conecta brokers de IoT y PLC.',
        'fr': 'Passerelle de communication industrielle reliant brokers IoT et API.',
        'it': 'Bridge di comunicazione industriale che collega broker IoT e PLC.',
        'ar': 'جسر اتصالات صناعي يربط بين وسطاء إنترنت الأشياء (IoT) وأجهزة الـ PLC.'
    },
    'modbus_demo': {
        'pt': 'Demonstração de leitura/escrita física no protocolo industrial Modbus.',
        'en': 'Read/write physical simulation on industrial Modbus protocol.',
        'es': 'Lectura y escritura en el protocolo industrial Modbus.',
        'fr': 'Simulation de lecture/écriture sur protocole industriel Modbus.',
        'it': 'Lettura e scrittura sul protocollo industriale Modbus.',
        'ar': 'محاكاة القراءة والكتابة في بروتوكول Modbus الصناعي.'
    },
    'mqtt_demo': {
        'pt': 'Conexão e publicação de eventos em brokers MQTT.',
        'en': 'Event publishing and connection handling for MQTT brokers.',
        'es': 'Conexión y publicación de eventos en brokers MQTT.',
        'fr': 'Connexion et publication d\'événements sur brokers MQTT.',
        'it': 'Connessione e pubblicazione di eventi su broker MQTT.',
        'ar': 'الاتصال ونشر الأحداث in وسطاء MQTT.'
    },
    'capture_source_demo': {
        'pt': 'Demonstração de captura física de frames a partir de múltiplas fontes.',
        'en': 'Frame capture from multiple physical signal and camera sources.',
        'es': 'Captura de fotogramas desde múltiples fuentes físicas y cámaras.',
        'fr': 'Capture de trames à partir de multiples sources physiques et caméras.',
        'it': 'Acquisizione di frame da più sorgenti fisiche e telecamere.',
        'ar': 'التقاط الإطارات من مصادر إشارات وكاميرات متعددة.'
    },
    'chromium_capture_demo': {
        'pt': 'Captura visual programada de telas de navegadores embarcados (CEF).',
        'en': 'Scheduled screenshot capture for embedded Chromium browsers (CEF).',
        'es': 'Captura visual programada de navegadores Chromium integrados (CEF).',
        'fr': 'Capture d\'écran programmée pour les navigateurs Chromium intégrés (CEF).',
        'it': 'Acquisizione programmata di screenshot per browser Chromium incorporati (CEF).',
        'ar': 'التقاط لقطات شاشة مجدولة لمتصفحات Chromium المضمنة (CEF).'
    },
    'email_classifier_demo': {
        'pt': 'Classificação inteligente e triagem automatizada de caixas de entrada de e-mails.',
        'en': 'Intelligent classification and automated triaging of email inboxes.',
        'es': 'Clasificación inteligente y filtrado automático de correos electrónicos.',
        'fr': 'Classification intelligente et tri automatique de boîtes de réception.',
        'it': 'Classificazione intelligente e smistamento automatico delle e-mail.',
        'ar': 'التصنيف الذكي والفرز التلقائي لرسائل البريد الإلكتروني الواردة.'
    },
    'serial_demo': {
        'pt': 'Comunicação direta bidirecional com portas seriais e Arduino.',
        'en': 'Direct two-way communication with serial ports and Arduino boards.',
        'es': 'Comunicación directa bidireccional con puertos serie y placas Arduino.',
        'fr': 'Communication bidirectionnelle directe avec les ports série et cartes Arduino.',
        'it': 'Comunicazione bidirezionale diretta con porte seriali e schede Arduino.',
        'ar': 'اتصال ثنائي الاتجاه مباشر مع المنافذ التسلسلية ولوحات Arduino.'
    },
    'socket_server_client_demo': {
        'pt': 'Servidor e cliente TCP/UDP nativo para troca rápida de pacotes de dados.',
        'en': 'Native server and client TCP/UDP utility for rapid data exchange.',
        'es': 'Servidor y cliente nativo TCP/UDP para el intercambio rápido de datos.',
        'fr': 'Utilitaire réseau natif serveur/client TCP/UDP pour échange rapide.',
        'it': 'Server e client nativo TCP/UDP per il rapido scambio di pacchetti dati.',
        'ar': 'أداة خادم وعميل TCP/UDP أصلية لتبادل البيانات السريع.'
    },
    'webserver_demo': {
        'pt': 'Servidor HTTP leve nativo para disponibilizar serviços locais.',
        'en': 'Lightweight native HTTP server to expose local microservices.',
        'es': 'Servidor HTTP ligero nativo para exponer microservicios locales.',
        'fr': 'Serveur HTTP léger natif pour exposer des microservices locaux.',
        'it': 'Server HTTP leggero nativo per esporre microservizi locali.',
        'ar': 'خادم HTTP محلي خفيف الوزن لتقديم الخدمات المحلية.'
    },
    'dataset_generator_visual_demo': {
        'pt': 'Interface visual Lazarus para criação e exportação estruturada de datasets.',
        'en': 'Lazarus visual interface for building and exporting structured training datasets.',
        'es': 'Interfaz visual de Lazarus para construir y exportar conjuntos de datos.',
        'fr': 'Interface visuelle Lazarus pour construire et exporter des ensembles de données.',
        'it': 'Interfaccia visuale Lazarus per la criação e l\'esportazione di dataset.',
        'ar': 'واجهة مرئية في لازاروس لبناء وتصدير مجموعات بيانات التدريب المنظمة.'
    },
    'matrix_component_demo': {
        'pt': 'Showcase de operações avançadas com matrizes matemáticas em Pascal puro.',
        'en': 'Mathematical matrix operations showcase implemented in pure Pascal.',
        'es': 'Operaciones avanzadas con matrices matemáticas escritas en Pascal puro.',
        'fr': 'Opérations avancées sur les matrices mathématiques en pur Pascal.',
        'it': 'Operazioni avanzate con matrici matematiche in puro Pascal.',
        'ar': 'عرض للعمليات Mtaqadema ala al-masfufat al-riyadiyah bi-lughat Pascal al-khalisah.'
    },
    'numps_demo': {
        'pt': 'Integração visual Pascal para computação científica com o NUMPS.',
        'en': 'Lazarus visual integration for scientific computing with NUMPS.',
        'es': 'Integración visual de Lazarus para computación científica con NUMPS.',
        'fr': 'Intégration visuelle Lazarus pour le calcul scientifique avec NUMPS.',
        'it': 'Integrazione visuale Lazarus per il calcolo scientifico con NUMPS.',
        'ar': 'تكامل مرئي في لازاروس للحوسبة العلمية مع مكتبة NUMPS.'
    },
    'math_input_output_demo': {
        'pt': 'Visualizador e processador de dados matemáticos de entrada e saída.',
        'en': 'Visualizer and processor for math input and output variables.',
        'es': 'Visualizador y procesador de variables de entrada y salida matemáticas.',
        'fr': 'Visualisateur et processeur de variables d\'entrée/sortie mathématiques.',
        'it': 'Visualizzatore e processore di variabili matematiche di input e output.',
        'ar': 'مستعرض ومعالج لمتغيرات المدخلات والمخرجات الرياضية.'
    },
    'pose_detector_demo': {
        'pt': 'Rastreamento corporal de articulações em tempo real com MediaPipe.',
        'en': 'Real-time human body pose tracking and rig mapping with MediaPipe.',
        'es': 'Seguimiento de poses corporales y articulaciones en tiempo real con MediaPipe.',
        'fr': 'Suivi des poses corporelles et articulations en temps réel avec MediaPipe.',
        'it': 'Tracciamento delle pose corporee e delle articolazioni in tempo reale con MediaPipe.',
        'ar': 'تتبع وضعيات الجسم البشري والمفاصل في الوقت الفعلي باستخدام MediaPipe.'
    },
    'motion_tracker_demo': {
        'pt': 'Identificação e rastreamento óptico de movimentos em tempo real.',
        'en': 'Real-time optical motion tracking and movement identification.',
        'es': 'Identificación y seguimiento óptico del movimiento en tiempo real.',
        'fr': 'Identification et suivi optique du mouvement en temps réel.',
        'it': 'Identificazione e tracciamento ottico del movimento in tempo reale.',
        'ar': 'تتبع الحركة الضوئية في الوقت الفعلي وتحديد التحركات.'
    },
    'native_image_filter_demo': {
        'pt': 'Filtros gráficos nativos de alto desempenho baseados em CPU.',
        'en': 'High-performance native CPU-based image filtering.',
        'es': 'Filtros gráficos nativos de alto rendimiento basados en CPU.',
        'fr': 'Filtres graphiques natifs haute performance basés sur le processeur.',
        'it': 'Filtri grafici nativi ad alte prestazioni basati su CPU.',
        'ar': 'فلاتر صور أصلية عالية الأداء تعتمد على المعالج (CPU).'
    },
    'output_docs_demo': {
        'pt': 'Motor de exportação estruturada para múltiplos formatos documentais.',
        'en': 'Structured document exporting engine for multiple file formats.',
        'es': 'Motor de exportación estructurada para múltiples formatos de archivo.',
        'fr': 'Moteur d\'exportation structurée pour de multiples formats de fichier.',
        'it': 'Motore di esportazione strutturata per molteplici formati di file.',
        'ar': 'محرك تصدير مستندات منظم لعدة صيغ للملفات.'
    },
    'output_text_json_demo': {
        'pt': 'Geração de strings formatadas em texto estruturado e JSON.',
        'en': 'Formatted generation of text strings and JSON objects.',
        'es': 'Generación de cadenas de texto formateadas y objetos JSON.',
        'fr': 'Génération de chaînes de texte formatées et d\'objets JSON.',
        'it': 'Generazione di stringhe di testo formattate e oggetti JSON.',
        'ar': 'إنشاء نصوص منسقة وكائنات JSON.'
    },
    'pdf_word_excel_demo': {
        'pt': 'Exportação nativa Pascal para PDF, planilhas Excel e arquivos Word.',
        'en': 'Native Pascal exporting to PDF, Excel spreadsheets, and Word files.',
        'es': 'Exportación nativa en Pascal a PDF, hojas Excel y archivos de Word.',
        'fr': 'Exportation native Pascal vers PDF, feuilles Excel et fichiers Word.',
        'it': 'Esportazione nativa in Pascal in PDF, fogli Excel e file Word.',
        'ar': 'تصدير أصلي في باسكال إلى ملفات PDF وجداول Excel ومستندات Word.'
    },
    'posprinter_demo': {
        'pt': 'Utilitário de formatação física de comandos ESC/POS para impressoras térmicas.',
        'en': 'ESC/POS formatting utility for receipt and thermal printers.',
        'es': 'Utilidad de formateo ESC/POS para impresoras térmicas de recibos.',
        'fr': 'Utilitaire de formatage ESC/POS pour imprimantes thermiques.',
        'it': 'Utilità di formattazione ESC/POS per stampanti termiche.',
        'ar': 'أداة تنسيق ESC/POS لطباعة الإيصالات والطابعات الحرارية.'
    },
    'word_object_demo': {
        'pt': 'Manipulação real e edição estruturada de arquivos DOCX via OpenXML.',
        'en': 'Structured manipulation and editing of DOCX files using OpenXML.',
        'es': 'Edición y manipulación estructurada de archivos DOCX con OpenXML.',
        'fr': 'Édition et manipulation structurée de fichiers DOCX avec OpenXML.',
        'it': 'Modifica e manipolazione strutturata di file DOCX tramite OpenXML.',
        'ar': 'تعديل ومعالجة ملفات DOCX المنظمة باستخدام OpenXML.'
    },
    'word_viewer_demo': {
        'pt': 'Visualizador nativo e renderizador de documentos DOCX dentro de formulários Lazarus.',
        'en': 'Native viewer and renderer for DOCX documents within Lazarus forms.',
        'es': 'Visualizador y renderizador nativo de documentos DOCX en formularios Lazarus.',
        'fr': 'Visualisateur et moteur de rendu natif de documents DOCX dans les formulaires.',
        'it': 'Visualizzatore e renderer nativo di documenti DOCX nei moduli Lazarus.',
        'ar': 'مستعرض وعارض أصلي لمستندات DOCX داخل نماذج لازاروس.'
    },
    'cnn_classifier_complete_demo': {
        'pt': 'Demo completo de classificação visual por redes neurais convolucionais (CNN).',
        'en': 'Complete visual classification demo utilizing Convolutional Neural Networks (CNN).',
        'es': 'Demostración de clasificación visual con redes neuronales convolucionales (CNN).',
        'fr': 'Démonstration complète de classification visuelle par réseaux convolutifs (CNN).',
        'it': 'Demo completa di classificazione visiva con reti neurali convoluzionali (CNN).',
        'ar': 'عرض توضيحي كامل للتصنيف المرئي باستخدام الشبكات التلافيفية (CNN).'
    },
    'lstm_timeseries_demo': {
        'pt': 'Predição e análise estatística de séries temporais usando modelos LSTM.',
        'en': 'Time-series forecasting and statistical analysis utilizing LSTM models.',
        'es': 'Predicción de tendencias de series temporales utilizando modelos LSTM.',
        'fr': 'Prévision et analyse statistique de séries temporelles avec des modèles LSTM.',
        'it': 'Previsione e analisi statistica di serie temporali tramite modelli LSTM.',
        'ar': 'التنبؤ بالسلاسل الزمنية والتحليل الإحصائي باستخدام نماذج LSTM.'
    },
    'python_runtime_check_demo': {
        'pt': 'Utilitário de verificação e diagnóstico de runtimes Python instalados.',
        'en': 'Diagnostics and testing utility for installed local Python runtimes.',
        'es': 'Utilidad de diagnóstico y prueba para los runtimes de Python instalados.',
        'fr': 'Outil de diagnostic et de test pour les environnements Python installés.',
        'it': 'Utilità di diagnostica e test per i runtime Python locali installati.',
        'ar': 'أداة تشخيص واختبار لبيئات تشغيل بايثون المحلية المثبتة.'
    },
    'yolo_detection_complete_demo': {
        'pt': 'Demo visual completo de detecção de objetos YOLOv8.',
        'en': 'Complete visual object detection demonstration utilizing YOLOv8.',
        'es': 'Demostración visual completa de detección de objetos con YOLOv8.',
        'fr': 'Démonstration visuelle complète de détection d\'objets avec YOLOv8.',
        'it': 'Demo visiva completa di rilevamento oggetti tramite YOLOv8.',
        'ar': 'عرض توضيحي مرئي كامل لرصد الكائنات باستخدام YOLOv8.'
    },
    'contamination_demo': {
        'pt': 'Simulação didática de proximidade e propagação de contaminação gráfica 2D.',
        'en': 'Visual simulation of proximity states propagation on a 2D canvas.',
        'es': 'Simulación visual de la propagación de estados de proximidad en 2D.',
        'fr': 'Simulation visuelle de la propagation d\'états de proximité en 2D.',
        'it': 'Simulazione visiva della propagazione degli stati di prossimità in 2D.',
        'ar': 'محاكاة مرئية لانتشار حالات التقارب على لوحة ثنائية الأبعاد.'
    },
    'robot_grid_demo': {
        'pt': 'Simulação interativa de robôs buscando estações de carga de forma autônoma.',
        'en': 'Interactive grid simulation of autonomous mobile robots seeking charging docks.',
        'es': 'Simulación interactiva de robots móviles autónomos buscando recargas.',
        'fr': 'Simulation interactive de robots mobiles autonomes cherchant des bornes.',
        'it': 'Simulazione interattiva di robot mobili autonomi alla ricerca di ricariche.',
        'ar': 'محاكاة تفاعلية لشبكة من الروبوتات المتنقلة المستقلة التي تبحث عن محطات الشحن.'
    },
    'service_queue_demo': {
        'pt': 'Simulação visual de fila de atendimento dinâmico (hospitalar, comercial, bancário).',
        'en': 'Visual queue simulation modeling customer and hospital services.',
        'es': 'Simulación visual de colas de servicio dinámicas para clientes y hospitales.',
        'fr': 'Simulation visuelle de files d\'attente dynamiques (clients et hôpitaux).',
        'it': 'Simulazione visiva di code di servizio dinamiche per ospedali e clienti.',
        'ar': 'محاكاة مرئية لنمذجة طوابير خدمة العملاء والخدمات الطبية.'
    },
    'warehouse_agents_demo': {
        'pt': 'Simulação logística e movimentação autônoma de empilhadeiras em armazém.',
        'en': 'Warehouse internal logistics simulation utilizing autonomous agents.',
        'es': 'Simulación de logística interna de almacenes utilizando agentes autónomos.',
        'fr': 'Simulation de logistique d\'entrepôt utilisant des agents autonomes.',
        'it': 'Simulazione di logistica interna di magazzino tramite agenti autonomi.',
        'ar': 'محاكاة الخدمات اللوجستية الداخلية للمستودعات باستخدام الوكلاء المستقلين.'
    },
    'aiframeprocessor_demo': {
        'pt': 'Processador genérico de frames e pixels nativo sem dependências OpenCV.',
        'en': 'Native frame and pixel buffer processor without external OpenCV dependencies.',
        'es': 'Procesador nativo de fotogramas y búferes de píxeles sin OpenCV.',
        'fr': 'Processeur de trames et pixels natif sans dépendances externes OpenCV.',
        'it': 'Processore di frame e pixel nativo senza dipendenze esterne OpenCV.',
        'ar': 'معالج إطارات وبكسلات أصلي بدون متطلبات تشغيل OpenCV خارجية.'
    },
    'camera_capture_windows_demo': {
        'pt': 'Utilitário de captura de vídeo de dispositivos USB no Windows.',
        'en': 'Windows camera video capturing utility for USB devices.',
        'es': 'Utilidad de captura de video de cámara en Windows para USB.',
        'fr': 'Utilitaire de capture vidéo sous Windows pour périphériques USB.',
        'it': 'Utilità di acquisizione video da telecamera Windows per dispositivi USB.',
        'ar': 'أداة التقاط فيديو الكاميرا في نظام ويندوز للأجهزة المتصلة بـ USB.'
    },
    'frame_diff_demo': {
        'pt': 'Detecção simplificada de movimento por diferença acumulada de frames consecutivas.',
        'en': 'Movement detection using consecutive frame differences.',
        'es': 'Detección de movimiento mediante diferencias entre fotogramas consecutivos.',
        'fr': 'Détection de mouvement par différence entre trames consécutives.',
        'it': 'Rilevamento del movimento tramite differenze tra frame consecutivi.',
        'ar': 'رصد الحركة باستخدام الفروقات بين الإطارات المتتالية.'
    },
    'image_info_demo': {
        'pt': 'Exibição e leitura rápida de cabeçalhos e metadados de arquivos de imagem.',
        'en': 'Reading and displaying image metadata and file headers.',
        'es': 'Lectura y visualización de metadatos de archivos e imágenes.',
        'fr': 'Lecture et affichage des métadonnées et en-têtes d\'images.',
        'it': 'Lettura e visualizzazione dei metadati e delle intestazioni delle immagini.',
        'ar': 'قراءة وعرض البيانات التعريفية ورؤوس ملفات الصور.'
    },
    'opencv_filter_demo': {
        'pt': 'Filtros de imagem básicos em OpenCV usando LCL e formulários.',
        'en': 'Basic OpenCV image filtering using LCL forms.',
        'es': 'Filtros de imagen básicos en OpenCV usando formularios LCL.',
        'fr': 'Filtres d\'image basiques avec OpenCV dans des formulaires LCL.',
        'it': 'Filtri d\'immagine di base in OpenCV utilizzando moduli LCL.',
        'ar': 'فلاتر صور أساسية باستخدام OpenCV ونماذج LCL.'
    },
    'opencv_image_real_demo': {
        'pt': 'Demonstração de integração OpenCV e LCL em tempo real.',
        'en': 'Real-time OpenCV and LCL camera integration demonstration.',
        'es': 'Demostración de la integración en tiempo real de OpenCV y LCL.',
        'fr': 'Démonstration d\'intégration en temps réel OpenCV et LCL.',
        'it': 'Dimostrazione dell\'integrazione in tempo reale di OpenCV e LCL.',
        'ar': 'عرض توضيحي لتكامل OpenCV و LCL في الوقت الفعلي للكاميرا.'
    },
    'audio_capture_demo': {
        'pt': 'Demo gráfico para captura real de áudio do microfone, salvando em WAV, sem modo simulado.',
        'en': 'GUI demo for real microphone audio capture, saving to WAV, with no simulation mode.',
        'es': 'Demostración gráfica para captura real de audio del micrófono, guardando en WAV, sin modo simulado.',
        'fr': 'Démo graphique pour la capture audio réelle du microphone, sauvegarde en WAV, sans modo de simulation.',
        'it': 'Demo grafica per l\'acquisizione reale dell\'audio dal microfono, salvataggio in WAV, senza modalità simulata.',
        'ar': 'عرض رسومي لالتقاط الصوت الحقيقي من الميكروفون وحفظه بصيغة WAV، بدون وضع المحاكاة.'
    },
    'sound_filters_visual_demo': {
        'pt': 'Equalizador e painel visual de filtros sonoros aplicados em tempo real.',
        'en': 'Visual sound filters control board and real-time audio equalizer.',
        'es': 'Ecualizador y panel visual de filtros de sonido en tiempo real.',
        'fr': 'Égaliseur et panneau de contrôle des filtres audio en temps réel.',
        'it': 'Equalizzatore e pannello di controllo dei filtri audio in tempo reale.',
        'ar': 'لوحة تحكم فلاتر الصوت المرئية وموازن الصوت في الوقت الفعلي.'
    },
    'voice_synthesizer_complete_demo': {
        'pt': 'Demo gráfico completo para síntese real de voz usando vozes locais do sistema ou a API de voz da OpenAI.',
        'en': 'Complete GUI demo for real text-to-speech synthesis using local system voices or the OpenAI Voice API.',
        'es': 'Muestra completa de síntesis de voz con narración síncrona y asíncrona.',
        'fr': 'Démonstration complète de synthèse vocale synchrone et asynchrone.',
        'it': 'Vetrina completa di sintesi vocale sincrona e asincrona.',
        'ar': 'عرض توضيحي كامل لتوليد الكلام يدعم القراءة المتزامنة وغير المتزامنة.'
    },
    'aiinput_sample.lpr': {
        'pt': 'Demonstração em linha de comando de envio/recebimento de dados usando componentes da aba AI Input.',
        'en': 'Command-line demonstration of data input/output handling using AI Input components.',
        'es': 'Demostración de línea de comandos de entrada y salida de datos con los componentes de AI Input.',
        'fr': 'Démonstration en ligne de commande de la gestion des entrées/sorties avec les composants AI Input.',
        'it': 'Dimostrazione da riga di comando della gestione degli input/output di dati con i componenti AI Input.',
        'ar': 'عرض توضيحي عبر سطر الأوامر لإدخال وإخراج البيانات باستخدام مكونات AI Input.'
    },
    'numps_sample.lpr': {
        'pt': 'Demonstração simples de console para operações matemáticas de matrizes e vetores com o NUMPS.',
        'en': 'Simple console application performing vector and matrix mathematical operations using NUMPS.',
        'es': 'Aplicación de consola para realizar operaciones matemáticas de matrices y vectores con NUMPS.',
        'fr': 'Application console simple effectuant des opérations mathématiques sur vecteurs et matrices avec NUMPS.',
        'it': 'Semplice applicazione console per eseguire operazioni matematiche di vettori e matrici con NUMPS.',
        'ar': 'تطبيق كونسول بسيط لإجراء العمليات الرياضية على المصفوفات المتجهية باستخدام NUMPS.'
    },
    'aioutput_sample.lpr': {
        'pt': 'Demonstração de console do componente de saída de dados estruturados em JSON ou texto puro.',
        'en': 'Console test for structured JSON and plaintext output generation components.',
        'es': 'Prueba de consola para componentes de generación de salida en JSON estructurado y texto plano.',
        'fr': 'Test console des composants de génération de sortie JSON structurée et texte brut.',
        'it': 'Test console per componenti di generazione di output in JSON strutturato e testo semplice.',
        'ar': 'اختبار كونسول لمكونات إنشاء المخرجات بصيغة JSON المنسقة أو النصوص البسيطة.'
    },
    'math_output_docs_demo.lpr': {
        'pt': 'Geração simplificada de documentos e planilhas matemáticas via linha de comando.',
        'en': 'Simplified mathematical document and spreadsheet generator via command line.',
        'es': 'Generador simplificado de hojas de cálculo y documentos matemáticos por línea de comandos.',
        'fr': 'Générateur simplifié de feuilles de calcul et documents mathématiques en ligne de commande.',
        'it': 'Generatore semplificato di fogli di calcolo e documenti matematici da riga di comando.',
        'ar': 'مولد مستندات وجداول رياضية مبسطة عبر سطر الأوامر.'
    },
    'aivoicesynthesizer_sample.lpr': {
        'pt': 'Invocação direta de sintetização síncrona/assíncrona de voz via console.',
        'en': 'Direct console invocation of synchronous/asynchronous voice synthesis (TTS).',
        'es': 'Invocación directa en consola de la síntesis de voz síncrona y asíncrona (TTS).',
        'fr': 'Appel direct en console de la synthèse vocale synchrone et asynchrone (TTS).',
        'it': 'Invocazione diretta da riga di comando della sintesi vocale sincrona e asincrona (TTS).',
        'ar': 'استدعاء مباشر لتخليق الصوت المتزامن وغير المتزامن (TTS) عبر الكونسول.'
    },
    'aicodeassistant_sample.lpr': {
        'pt': 'Rotina em console para otimização e documentação automática de código pascal.',
        'en': 'Console-based assistant to optimize and automatically document Delphi/Pascal code.',
        'es': 'Asistente de consola para optimizar y documentar automáticamente código Pascal.',
        'fr': 'Assistant en ligne de commande pour optimiser et documenter automatiquement le code Pascal.',
        'it': 'Assistant da riga di comando per ottimizzare e documentare automaticamente il codice Pascal.',
        'ar': 'مساعد عبر سطر الأوامر لتحسين وتوثيق كود باسكal تلقائيًا.'
    },
    'aidatasetgenerator_sample.lpr': {
        'pt': 'Loop de compilação e exportação de base de dados em formato JSONL.',
        'en': 'Automated dataset generation loop exporting data to JSONL format.',
        'es': 'Bucle automatizado de generación de conjuntos de datos exportados a JSONL.',
        'fr': 'Boucle automatisée de génération de jeux de données exportés au format JSONL.',
        'it': 'Ciclo automatizzato di generazione di dataset esportato in formato JSONL.',
        'ar': 'حلقة توليد مجموعات البيانات التلقائية وتصديرها بصيغة JSONL.'
    },
    'chatgpt_sample.lpr': {
        'pt': 'Envio de perguntas e auditoria de respostas brutas em OpenAI, Claude e Gemini.',
        'en': 'Query invocation and raw JSON payload audit for OpenAI, Claude, and Gemini.',
        'es': 'Consultas y auditoría de respuestas en OpenAI, Claude y Gemini.',
        'fr': 'Requêtes et audit des réponses brutes pour OpenAI, Claude et Gemini.',
        'it': 'Query e controllo delle risposte grezze per OpenAI, Claude e Gemini.',
        'ar': 'إرسال الاستعلامات وفحص البيانات الخام المستلمة من OpenAI و Claude و Gemini.'
    },
    'neuralnetwork_sample.lpr': {
        'pt': 'Treinamento clássico de perceptron multicamadas XOR em Pascal puro.',
        'en': 'Classic Multilayer Perceptron training simulator for XOR logic gates.',
        'es': 'Simulador de entrenamiento de perceptrón multicapa clásico para puertas lógicas XOR.',
        'fr': 'Simulateur d\'entraînement classique de perceptron multicouche pour portes XOR.',
        'it': 'Simulatore classico di addestramento MLP per porte logiche XOR in puro Pascal.',
        'ar': 'محاكي تدريب البيرسبترون متعدد الطبقات الكلاسيكي للبوابات المنطقية XOR.'
    }
}

SCREENSHOT_MAPPING = {
    'aiframeprocessor_demo': 'TAIFrameProcessor Demo.jpg',
    'ai_sqlite_query_assistant_demo': 'ai_sqlite_query_assistant_demo.jpg',
    'cnn_classifier_complete_demo': 'cnn_classifier_complete_demo.jpg',
    'cnn_demo': 'cnn_demo.jpg',
    'db_dictionary_demo': 'db_dicitionary_demo.jpg',
    'disk_tree_ai_dataset_demo': 'disk_tree_ai_dataset_demo.jpg',
    'docfilesmanager_demo': 'docfilesmanager_demo.jpg',
    'image_info_demo': 'image_info_demo.jpg',
    'math_input_output_demo': 'math_input_output_demo.jpg',
    'pose_detector_demo': 'pose_detector_demo.jpg',
    'python_demo': 'python_demo.jpg',
    'python_runtime_check_demo': 'python_runtime_check_demo.jpg',
    'som_demo': 'som_demo.jpg',
    'sound_filters_visual_demo': 'sound_filters_visual_demo.jpg',
    'voice_synthesizer_complete_demo': 'voice_synthesizer_complete_demo.jpg',
    'voicesynthesizer_demo': 'voicesynthesizer_demo.jpg'
}

def scan_samples(samples_root, lang_code, trans):
    gui_samples = {}
    console_samples = {}
    
    gui_dir_set = set()
    
    for root, dirs, files in os.walk(samples_root):
        if any(x in root.lower() for x in ['backup', 'lib', '__pycache__']):
            continue
        lpi_files = [f for f in files if f.endswith('.lpi')]
        if lpi_files:
            gui_dir_set.add(root)
            lpi_file = lpi_files[0]
            
            rel_path = os.path.relpath(root, samples_root)
            parts = rel_path.split(os.sep)
            category = parts[0] if parts else "General"
            if category == ".":
                category = "General"
                
            folder_name = os.path.basename(root)
            proj_name = lpi_file[:-4]
            
            # Resolve description in the exact language
            desc = trans['no_desc']
            for name_key in [proj_name, folder_name]:
                if name_key in SAMPLE_DESCRIPTIONS and lang_code in SAMPLE_DESCRIPTIONS[name_key]:
                    desc = SAMPLE_DESCRIPTIONS[name_key][lang_code]
                    break
            
            if category not in gui_samples:
                gui_samples[category] = []
                
            gui_samples[category].append({
                'name': proj_name,
                'rel_path': rel_path.replace('\\', '/'),
                'title': folder_name,
                'desc': desc
            })
            
    for root, dirs, files in os.walk(samples_root):
        if any(x in root.lower() for x in ['backup', 'lib', '__pycache__']):
            continue
        if root in gui_dir_set:
            continue
            
        lpr_files = [f for f in files if f.endswith('.lpr')]
        for lpr in lpr_files:
            rel_path = os.path.relpath(root, samples_root)
            parts = rel_path.split(os.sep)
            category = parts[0] if parts else "General"
            if category == ".":
                category = "General"
                
            desc = trans['no_desc']
            if lpr in SAMPLE_DESCRIPTIONS and lang_code in SAMPLE_DESCRIPTIONS[lpr]:
                desc = SAMPLE_DESCRIPTIONS[lpr][lang_code]
            
            if category not in console_samples:
                console_samples[category] = []
                
            console_samples[category].append({
                'name': lpr,
                'rel_path': os.path.join(rel_path, lpr).replace('\\', '/'),
                'desc': desc
            })
            
    return gui_samples, console_samples

def generate():
    samples_root = r"D:\projetos\maurinsoft\CHATGPT\pacote\samples"
    
    for lang_code, trans in langs.items():
        gui, console = scan_samples(samples_root, lang_code, trans)
        
        if lang_code == 'pt':
            filenames = ["README.pt.md", "README.md"]
        else:
            filenames = [f"README.{lang_code}.md"]
            
        for filename in filenames:
            filepath = os.path.join(samples_root, filename)
            
            content = []
            content.append(f"# 📂 {trans['title']}")
            content.append("")
            content.append(f"> [!NOTE]")
            content.append(f"> {trans['intro']}")
            content.append("")
            
            content.append(f"## {trans['gui_title']}")
            content.append(trans['gui_desc'])
            content.append("")
            
            for category in sorted(gui.keys()):
                content.append(f"### 📦 {category}")
                content.append("")
                content.append(f"| {trans['col_sample']} | {trans['col_path']} | {trans['col_desc']} |")
                content.append("|---|---|---|")
                
                for item in sorted(gui[category], key=lambda x: x['title']):
                    repo_path = f"pacote/samples/{item['rel_path']}"
                    
                    # Check if there is a screenshot mapping
                    proj_name = item['name']
                    folder_name = item['rel_path'].split('/')[-1]
                    screenshot_file = None
                    for key, sc_file in SCREENSHOT_MAPPING.items():
                        if key == proj_name or key == folder_name:
                            screenshot_file = sc_file
                            break
                            
                    image_str = ""
                    if screenshot_file:
                        image_str = f"<br><br>![{item['title']}](../../screenshots/{screenshot_file})"
                        
                    content.append(f"| **[{item['title']}]({item['rel_path']}/)**{image_str} | `{repo_path}` | {item['desc']} |")
                content.append("")
                
            if console:
                content.append(f"## {trans['console_title']}")
                content.append(trans['console_desc'])
                content.append("")
                
                for category in sorted(console.keys()):
                    content.append(f"### ⌨️ {category}")
                    content.append("")
                    content.append(f"| {trans['col_sample']} | {trans['col_path']} | {trans['col_desc']} |")
                    content.append("|---|---|---|")
                    
                    for item in sorted(console[category], key=lambda x: x['name']):
                        repo_path = f"pacote/samples/{item['rel_path']}"
                        content.append(f"| **[{item['name']}]({item['rel_path']})** | `{repo_path}` | {item['desc']} |")
                    content.append("")
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write("\n".join(content))
                
            print(f"Generated: {filepath}")

if __name__ == '__main__':
    generate()