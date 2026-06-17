# -*- coding: utf-8 -*-
import os

langs = {
    'pt': {
        'title': 'Pacote de Componentes de IA',
        'intro': 'Este diretório contém a implementação da suíte oficial de componentes de IA e Automação para Lazarus/Delphi. Esta suíte integra Inteligência Artificial, Aprendizado de Máquina, processamento de hardware, redes, áudio, imagem e documentos de forma nativa e multiplataforma através de pacotes modulares.',
        'details': 'Referência dos Componentes Principais',
        'comp': 'Componente',
        'desc': 'Descrição',
        'props': 'Propriedades Importantes',
        'methods': 'Métodos Principais',
        'role': 'Papel do Agente de IA',
        'example': 'Estrutura Geral de Instanciação',
        'samples_title': '📂 Diretório de Exemplos (Samples)',
        'samples_desc': 'A pasta `samples/` contém demonstrações completas de uso visual e console para cada um dos recursos do pacote.',
        'unified': 'Conectividade e Prompts de Agentes',
        'unified_text': 'Todos os componentes deste pacote possuem a propriedade published `Prompt` predefinida. Ela fornece as diretivas necessárias para que Agentes de IA autônomos (`TAIAgent`) compreendam a finalidade do hardware ou documento e injetem parâmetros dinamicamente via reflexão RTTI.'
    },
    'en': {
        'title': 'AI Component Suite Package',
        'intro': 'This directory contains the implementation of the official AI & Automation component suite for Lazarus/Delphi. This suite integrates Artificial Intelligence, Machine Learning, hardware automation, networking, audio, imaging, and document processing natively and cross-platform through modular packages.',
        'details': 'Core Component Reference',
        'comp': 'Component',
        'desc': 'Description',
        'props': 'Important Properties',
        'methods': 'Main Methods',
        'role': 'AI Agent Role',
        'example': 'General Instantiation Template',
        'samples_title': '📂 Samples Directory',
        'samples_desc': 'The `samples/` folder provides comprehensive visual and command-line console demonstration projects for each suite capability.',
        'unified': 'Agent Prompts and Connectivity',
        'unified_text': 'All components in this suite feature a published `Prompt` property. This transparently informs autonomous AI Agents (`TAIAgent`) about the device or document API, enabling dynamic property injection via RTTI reflection.'
    },
    'es': {
        'title': 'Paquete de Componentes de IA',
        'intro': 'Este directorio contiene la implementación de la suite oficial de componentes de IA y automatización para Lazarus/Delphi. Este paquete integra Inteligencia Artificial, Aprendizaje Automático, automatización de hardware, redes, audio, procesamiento de imágenes y documentos de forma nativa y multiplataforma mediante paquetes modulares.',
        'details': 'Referencia de Componentes Principales',
        'comp': 'Componente',
        'desc': 'Descripción',
        'props': 'Propiedades Importantes',
        'methods': 'Métodos Principales',
        'role': 'Rol del Agente de IA',
        'example': 'Ejemplo General de Instanciación',
        'samples_title': '📂 Directorio de Ejemplos (Samples)',
        'samples_desc': 'La carpeta `samples/` contiene demostraciones visuales y de consola listas para usar para cada una de las funciones del paquete.',
        'unified': 'Conectividad y Prompts de Agentes',
        'unified_text': 'Todos los componentes del paquete cuentan con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.'
    },
    'fr': {
        'title': 'Package de Suite de Composants d\'IA',
        'intro': 'Ce dossier contient l\'implémentation de la suite officielle de composants d\'IA et d\'automatisation pour Lazarus/Delphi. Ce package intègre l\'Intelligence Artificielle, l\'Apprentissage Automatique, l\'automatisation matérielle, les réseaux, l\'audio, l\'imagerie et le traitement de documents de façon native et multiplateforme via des packages modulaires.',
        'details': 'Référence des Composants Principaux',
        'comp': 'Composant',
        'desc': 'Description',
        'props': 'Propriétés Importantes',
        'methods': 'Méthodes Principales',
        'role': 'Rôle de l\'Agent d\'IA',
        'example': 'Modèle Général d\'Instanciation',
        'samples_title': '📂 Répertoire d\'Exemples (Samples)',
        'samples_desc': 'Le dossier `samples/` propose des projets de démonstration visuels et console pour chaque composant.',
        'unified': 'Prompts d\'Agents et Connectivité',
        'unified_text': 'Chaque composant intègre une propriedade published `Prompt` décrivant de manière transparente son API interne pour guider les agents d\'IA (`TAIAgent`) de façon autonome.'
    },
    'it': {
        'title': 'Pacchetto Componenti IA',
        'intro': 'Questa directory contiene l\'implementazione del pacchetto ufficiale di componenti IA e automazione per Lazarus/Delphi. Integra Intelligenza Artificiale, Machine Learning, automazione hardware, reti, audio, elaborazione di immagini e documenti in modo nativo e multipiattaforma grazie a pacchetti modulari.',
        'details': 'Riferimento dei Componenti Principali',
        'comp': 'Componente',
        'desc': 'Descrizione',
        'props': 'Proprietà Importanti',
        'methods': 'Metodi Principali',
        'role': 'Ruolo dell\'Agente di IA',
        'example': 'Modello Generale di Istanziazione',
        'samples_title': '📂 Directory degli Esempi (Samples)',
        'samples_desc': 'La cartella `samples/` contiene demo grafiche e a riga di comando per sperimentare ogni funzionalità del pacchetto.',
        'unified': 'Connettività e Prompt degli Agenti',
        'unified_text': 'Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API per guidare gli Agenti IA (`TAIAgent`) autonomamente.'
    },
    'ar': {
        'title': 'حزمة مكونات الذكاء الاصطناعي',
        'intro': 'يحتوي هذا المجلد على حزمة المكونات الرسمية للذكاء الاصطناعي والأتمتة في لازاروس ودلفي. تدمج هذه الحزمة الذكاء الاصطناعي، تعلم الآلة، أتمتة الأجهزة، الشبكات، معالجة الصوت والصور والمستندات بشكل أصلي ومتعدد المنصات عبر حزم برمجية مجزأة.',
        'details': 'مرجع المكونات الأساسية',
        'comp': 'المكون',
        'desc': 'الوصف',
        'props': 'الخصائص الهامة',
        'methods': 'الأساليب الرئيسية',
        'role': 'دور وكيل الذكاء الاصطناعي',
        'example': 'نموذج عام لإنشاء وتجهيز المكون',
        'samples_title': '📂 مجلد أمثلة الاستخدام (Samples)',
        'samples_desc': 'يحتوي المجلد `samples/` على مشاريع توضيحية مرئية وبسيطة لكل ميزة من ميزات الحزمة.',
        'unified': 'جسر الاتصال وتوجيه الوكلاء',
        'unified_text': 'تتميز جميع المكونات بخاصية نشر `Prompt` والتي توثق بشكل شفاف واجهتها البرمجية لتوجيه وكلاء الذكاء الاصطناعي (`TAIAgent`) ذاتياً وتلقائياً.'
    }
}

comps_info = {
    'pt': [
        {'name': 'TCHATGPT', 'desc': 'Conector universal OpenAI e LLMs na nuvem ou servidores locais.', 'props': 'APIKey, Provider, TipoChat, CustomModel, MaxTokens', 'methods': 'SendQuestion(ASK): Boolean, TipoModelo: string', 'role': 'Processar linguagem natural e gerar respostas cognitivas.'},
        {'name': 'TNeuralNetwork', 'desc': 'Rede Neural Perceptron Multicamadas nativa em Pascal puro.', 'props': 'LearningRate, ActivationType', 'methods': 'Initialize, Predict, Train, TrainEpochs, SaveNetwork', 'role': 'Treinar modelos locais e realizar previsões matemáticas.'},
        {'name': 'TAICodeAssistant', 'desc': 'Assistente cognitivo de auditoria e otimização de código.', 'props': 'ChatGPT', 'methods': 'OptimizeCode, FindBugs, DocumentCode, ExplainCode', 'role': 'Analisar blocos de código pascal e sugerir refatorações.'},
        {'name': 'TAIDatasetGenerator', 'desc': 'Gerador e exportador de dados tabulares (JSONL, CSV).', 'props': 'DataRows', 'methods': 'AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV', 'role': 'Compilar bases de dados e dividir conjuntos de treinamento.'},
        {'name': 'TTokenizer', 'desc': 'Tokenizador e segmentador de texto rápido.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Converter strings brutas em sequências numéricas (tokens).'},
        {'name': 'TAIGraphMap', 'desc': 'Classificador de texto explicável baseado em mapas de grafos ponderados.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile', 'role': 'Classificar textos curtos e categorizar chamados localmente sem dependências externas.'},
        {'name': 'TPythonConnector', 'desc': 'Ponte de execução e bindings do interpretador Python em tempo de execução.', 'props': 'DLLPath, Active, Version', 'methods': 'ExecString, GetVar, SetVar, Eval', 'role': 'Integrar modelos avançados do ecossistema Python (TensorFlow, etc.).'},
        {'name': 'TPerceptron', 'desc': 'Neurônio Perceptron clássico binário de camada única em Pascal.', 'props': 'LearningRate, Weights, Bias', 'methods': 'Initialize, Predict, Train, TrainEpochs', 'role': 'Classificar padrões binários linearmente separáveis de forma rápida.'},
        {'name': 'TSOMMap', 'desc': 'Rede de Auto-Organização de Kohonen para agrupamento de dados.', 'props': 'GridWidth, GridHeight, InputDim', 'methods': 'Initialize, FindBMU, TrainStep, Train', 'role': 'Agrupar dados complexos em grades bidimensionais.'},
        {'name': 'TCNNClassifier', 'desc': 'Classificador convolucional profundo MobileNetV2 para imagens.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, ClassifyImage', 'role': 'Classificar fotos e frames obtidos de câmeras de segurança.'},
        {'name': 'TLSTMPredictor', 'desc': 'Previsor de séries temporais usando redes recorrentes LSTM.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, TrainLSTM, PredictNext', 'role': 'Prever tendências futuras em dados de sensores sequenciais.'},
        {'name': 'TAIVoiceSynthesizer', 'desc': 'Motor de síntese de voz (TTS) nativo Windows e Linux.', 'props': 'Volume, Rate, VoiceName, Asynchronous', 'methods': 'Say, GetAvailableVoices', 'role': 'Falar relatórios ou alertas gerados pela IA via hardware de áudio.'},
        {'name': 'TAIDiskTreeScanner', 'desc': 'Escaneador de árvore de arquivos local assíncrono.', 'props': 'TargetFolder, ShowProgress, IncludeSubfolders', 'methods': 'Scan, StopScan', 'role': 'Varrer diretórios locais e indexar arquivos para datasets.'},
        {'name': 'TAI_DOCFILESMANAGER', 'desc': 'Gerenciador físico de arquivos e documentações.', 'props': 'StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength', 'methods': 'Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument', 'role': 'Organizar arquivos de documentação para uso com RAG e treinamento.'}
    ],
    'en': [
        {'name': 'TCHATGPT', 'desc': 'Universal cloud LLM and local server OpenAI connector.', 'props': 'APIKey, Provider, TipoChat, CustomModel, MaxTokens', 'methods': 'SendQuestion(ASK): Boolean, TipoModelo: string', 'role': 'Process natural language and generate cognitive responses.'},
        {'name': 'TNeuralNetwork', 'desc': 'Native Multilayer Perceptron Neural Network in pure Pascal.', 'props': 'LearningRate, ActivationType', 'methods': 'Initialize, Predict, Train, TrainEpochs, SaveNetwork', 'role': 'Train local models and perform mathematical predictions.'},
        {'name': 'TAICodeAssistant', 'desc': 'Cognitive assistant for auditing and optimizing code.', 'props': 'ChatGPT', 'methods': 'OptimizeCode, FindBugs, DocumentCode, ExplainCode', 'role': 'Analyze Pascal source code and suggest structural refactorings.'},
        {'name': 'TAIDatasetGenerator', 'desc': 'Tabular dataset compiler and exporter (JSONL, CSV).', 'props': 'DataRows', 'methods': 'AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV', 'role': 'Assemble databases and split training sets.'},
        {'name': 'TTokenizer', 'desc': 'Fast text tokenizer and words segmenter.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Preprocess text strings into token index sequences.'},
        {'name': 'TAIGraphMap', 'desc': 'Explainable text classifier based on weighted token graphs.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile', 'role': 'Classify short texts and categorize tickets locally without external dependencies.'},
        {'name': 'TPythonConnector', 'desc': 'Dynamic runtime Python binding and execution bridge.', 'props': 'DLLPath, Active, Version', 'methods': 'ExecString, GetVar, SetVar, Eval', 'role': 'Integrate heavy modules from the Python ecosystem (TensorFlow, etc.).'},
        {'name': 'TPerceptron', 'desc': 'Single-layer classical binary Perceptron classifier in Pascal.', 'props': 'LearningRate, Weights, Bias', 'methods': 'Initialize, Predict, Train, TrainEpochs', 'role': 'Classify linearly separable binary logic states quickly.'},
        {'name': 'TSOMMap', 'desc': 'Kohonen Self-Organizing Map for data clustering.', 'props': 'GridWidth, GridHeight, InputDim', 'methods': 'Initialize, FindBMU, TrainStep, Train', 'role': 'Cluster complex data points on two-dimensional topological grids.'},
        {'name': 'TCNNClassifier', 'desc': 'MobileNetV2 deep convolutional image classifier.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, ClassifyImage', 'role': 'Analyze and tag images or real-time camera frames.'},
        {'name': 'TLSTMPredictor', 'desc': 'LSTM recurrent network for sequence and time-series forecasting.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, TrainLSTM, PredictNext', 'role': 'Predict future values from sequential sensor telemetry.'},
        {'name': 'TAIVoiceSynthesizer', 'desc': 'Cross-platform native Speech Synthesis engine (TTS).', 'props': 'Volume, Rate, VoiceName, Asynchronous', 'methods': 'Say, GetAvailableVoices', 'role': 'Synthesize real-time audio speech alerts from AI outputs.'},
        {'name': 'TAIDiskTreeScanner', 'desc': 'Asynchronous local file tree scanner.', 'props': 'TargetFolder, ShowProgress, IncludeSubfolders', 'methods': 'Scan, StopScan', 'role': 'Scan local directories and index files to prepare datasets.'},
        {'name': 'TAI_DOCFILESMANAGER', 'desc': 'Physical document and file manager.', 'props': 'StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength', 'methods': 'Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument', 'role': 'Organize documentation files for RAG and model training.'}
    ],
    'es': [
        {'name': 'TCHATGPT', 'desc': 'Conector universal de OpenAI y LLMs en la nube o servidores locales.', 'props': 'APIKey, Provider, TipoChat, CustomModel, MaxTokens', 'methods': 'SendQuestion(ASK): Boolean, TipoModelo: string', 'role': 'Procesar lenguaje natural y generar respuestas cognitivas.'},
        {'name': 'TNeuralNetwork', 'desc': 'Red Neuronal Perceptron Multicapa nativa en Pascal puro.', 'props': 'LearningRate, ActivationType', 'methods': 'Initialize, Predict, Train, TrainEpochs, SaveNetwork', 'role': 'Entrenar modelos locales y realizar predicciones matemáticas.'},
        {'name': 'TAICodeAssistant', 'desc': 'Asistente cognitivo para auditar y optimizar código fuente.', 'props': 'ChatGPT', 'methods': 'OptimizeCode, FindBugs, DocumentCode, ExplainCode', 'role': 'Analizar bloques de código Pascal y sugerir refactorizaciones.'},
        {'name': 'TAIDatasetGenerator', 'desc': 'Generador y exportador de conjuntos de datos (JSONL, CSV).', 'props': 'DataRows', 'methods': 'AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV', 'role': 'Compilar bases de datos y dividir conjuntos de entrenamiento.'},
        {'name': 'TTokenizer', 'desc': 'Tokenizador de texto y segmentador de palabras rápido.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Preprocesar cadenas en secuencias numéricas (tokens).'},
        {'name': 'TAIGraphMap', 'desc': 'Clasificador de texto explicable basado en mapas de grafos ponderados.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile', 'role': 'Clasificar textos cortos y categorizar solicitudes localmente sin dependencias externas.'},
        {'name': 'TPythonConnector', 'desc': 'Puente de ejecución y bindings dinámicos de Python en tiempo de ejecución.', 'props': 'DLLPath, Active, Version', 'methods': 'ExecString, GetVar, SetVar, Eval', 'role': 'Integrar modelos avanzados del ecosistema Python (TensorFlow, etc.).'},
        {'name': 'TPerceptron', 'desc': 'Neurona Perceptron clásico binario de capa única en Pascal.', 'props': 'LearningRate, Weights, Bias', 'methods': 'Initialize, Predict, Train, TrainEpochs', 'role': 'Clasificar estados lógicos binarios de forma rápida.'},
        {'name': 'TSOMMap', 'desc': 'Red de Auto-Organización de Kohonen para agrupamiento de datos.', 'props': 'GridWidth, GridHeight, InputDim', 'methods': 'Initialize, FindBMU, TrainStep, Train', 'role': 'Agrupar datos complejos en rejillas bidimensionales.'},
        {'name': 'TCNNClassifier', 'desc': 'Clasificador convolucional profundo MobileNetV2 para imágenes.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, ClassifyImage', 'role': 'Analizar e identificar fotos u fotogramas de cámaras.'},
        {'name': 'TLSTMPredictor', 'desc': 'Previsor de series temporales usando redes recurrentes LSTM.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, TrainLSTM, PredictNext', 'role': 'Predecir tendencias futuras a partir de datos secuenciales.'},
        {'name': 'TAIVoiceSynthesizer', 'desc': 'Motor de síntesis de voz (TTS) nativo Windows e Linux.', 'props': 'Volume, Rate, VoiceName, Asynchronous', 'methods': 'Say, GetAvailableVoices', 'role': 'Hablar reportes o alertas generadas por la IA a través do hardware.'},
        {'name': 'TAIDiskTreeScanner', 'desc': 'Escaneador asíncrono de árbol de arquivos local.', 'props': 'TargetFolder, ShowProgress, IncludeSubfolders', 'methods': 'Scan, StopScan', 'role': 'Escanear directorios locales e indexar archivos para datasets.'},
        {'name': 'TAI_DOCFILESMANAGER', 'desc': 'Gestor físico de documentos y archivos.', 'props': 'StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength', 'methods': 'Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument', 'role': 'Organizar archivos de documentación para uso com RAG e entrenamiento.'}
    ],
    'fr': [
        {'name': 'TCHATGPT', 'desc': 'Connecteur OpenAI et LLM universel dans le cloud ou serveurs locaux.', 'props': 'APIKey, Provider, TipoChat, CustomModel, MaxTokens', 'methods': 'SendQuestion(ASK): Boolean, TipoModelo: string', 'role': 'Traiter le langage naturel et générer des réponses cognitives.'},
        {'name': 'TNeuralNetwork', 'desc': 'Réseau de neurones Perceptron Multicouche natif en pur Pascal.', 'props': 'LearningRate, ActivationType', 'methods': 'Initialize, Predict, Train, TrainEpochs, SaveNetwork', 'role': 'Entraîner des modèles locaux et effectuer des prédictions.'},
        {'name': 'TAICodeAssistant', 'desc': 'Assistant cognitif pour auditer et optimiser le code.', 'props': 'ChatGPT', 'methods': 'OptimizeCode, FindBugs, DocumentCode, ExplainCode', 'role': 'Analyser les blocs de code pascal et suggérer des refactorisations.'},
        {'name': 'TAIDatasetGenerator', 'desc': 'Compilateur et exportateur de jeux de données (JSONL, CSV).', 'props': 'DataRows', 'methods': 'AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV', 'role': 'Compiler des bases de données et diviser les lots d\'entraînement.'},
        {'name': 'TTokenizer', 'desc': 'Tokeniseur de texte et segmentateur de mots rapide.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Prétraiter des chaînes en séquences d\'indices de jetons.'},
        {'name': 'TAIGraphMap', 'desc': 'Classificateur de texte explicable basé sur des graphes de jetons pondérés.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile', 'role': 'Classifier des textes courts et catégoriser des tickets localement sans dépendance externe.'},
        {'name': 'TPythonConnector', 'desc': 'Pont d\'exécution dynamique de scripts Python en runtime.', 'props': 'DLLPath, Active, Version', 'methods': 'ExecString, GetVar, SetVar, Eval', 'role': 'Intégrer des modèles lourds du monde Python (TensorFlow, etc.).'},
        {'name': 'TPerceptron', 'desc': 'Neurone Perceptron classique binaire à couche unique en Pascal.', 'props': 'LearningRate, Weights, Bias', 'methods': 'Initialize, Predict, Train, TrainEpochs', 'role': 'Classifier rapidement des états logiques binaires simples.'},
        {'name': 'TSOMMap', 'desc': 'Réseau d\'Auto-Organisation de Kohonen pour le clustering.', 'props': 'GridWidth, GridHeight, InputDim', 'methods': 'Initialize, FindBMU, TrainStep, Train', 'role': 'Regrouper des données complexes sur des grilles topologiques.'},
        {'name': 'TCNNClassifier', 'desc': 'Classifieur convolutif profond MobileNetV2 pour les images.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, ClassifyImage', 'role': 'Analyser et étiqueter des images ou flux caméras.'},
        {'name': 'TLSTMPredictor', 'desc': 'Prédiction de séries temporelles par réseau récurrent LSTM.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, TrainLSTM, PredictNext', 'role': 'Prédire les valeurs futures issues de télémétries séquentielles.'},
        {'name': 'TAIVoiceSynthesizer', 'desc': 'Moteur de synthèse vocale (TTS) natif et multiplateforme.', 'props': 'Volume, Rate, VoiceName, Asynchronous', 'methods': 'Say, GetAvailableVoices', 'role': 'Synthétiser des alertes vocales générées par l\'IA.'},
        {'name': 'TAIDiskTreeScanner', 'desc': 'Scanneur asynchrone d\'arborescence de fichiers locaux.', 'props': 'TargetFolder, ShowProgress, IncludeSubfolders', 'methods': 'Scan, StopScan', 'role': 'Scanner des répertoires locaux et indexer des fichiers pour datasets.'},
        {'name': 'TAI_DOCFILESMANAGER', 'desc': 'Gestionnaire physique de documents et fichiers.', 'props': 'StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength', 'methods': 'Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument', 'role': 'Organiser les fichiers de documentation pour le RAG et l\'entraînement.'}
    ],
    'it': [
        {'name': 'TCHATGPT', 'desc': 'Connettore universale OpenAI e LLM cloud o server locali.', 'props': 'APIKey, Provider, TipoChat, CustomModel, MaxTokens', 'methods': 'SendQuestion(ASK): Boolean, TipoModelo: string', 'role': 'Elaborare il linguaggio naturale e generare risposte cognitive.'},
        {'name': 'TNeuralNetwork', 'desc': 'Rete Neurale Perceptron Multistrato nativa in puro Pascal.', 'props': 'LearningRate, ActivationType', 'methods': 'Initialize, Predict, Train, TrainEpochs, SaveNetwork', 'role': 'Addestrare modelli locali ed effettuare previsioni matematiche.'},
        {'name': 'TAICodeAssistant', 'desc': 'Assistente cognitivo per l\'auditing e l\'ottimizzazione del codice.', 'props': 'ChatGPT', 'methods': 'OptimizeCode, FindBugs, DocumentCode, ExplainCode', 'role': 'Analizzare sorgenti Pascal e suggerire refactoring.'},
        {'name': 'TAIDatasetGenerator', 'desc': 'Compilatore ed esportatore di dataset tabulari (JSONL, CSV).', 'props': 'DataRows', 'methods': 'AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV', 'role': 'Compilare database e suddividere i set di addestramento.'},
        {'name': 'TTokenizer', 'desc': 'Tokenizzatore di testo rapido e segmentatore di parole.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Pre-elaborare stringhe grezze in indici numerici (token).'},
        {'name': 'TAIGraphMap', 'desc': 'Classificatore di testo spiegabile basato su grafi di token pesati.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile', 'role': 'Classificare testi brevi e categorizzare ticket localmente senza dipendenze esterne.'},
        {'name': 'TPythonConnector', 'desc': 'Ponte di collegamento ed esecuzione runtime del motore Python.', 'props': 'DLLPath, Active, Version', 'methods': 'ExecString, GetVar, SetVar, Eval', 'role': 'Integrare modelli complessi dall\'ecosistema Python (TensorFlow, ecc.).'},
        {'name': 'TPerceptron', 'desc': 'Neurone Perceptron classico binario a singolo strato in Pascal.', 'props': 'LearningRate, Weights, Bias', 'methods': 'Initialize, Predict, Train, TrainEpochs', 'role': 'Classificare rapidamente stati logici binari lineari.'},
        {'name': 'TSOMMap', 'desc': 'Rete di Auto-Organizzazione di Kohonen per il clustering dei dati.', 'props': 'GridWidth, GridHeight, InputDim', 'methods': 'Initialize, FindBMU, TrainStep, Train', 'role': 'Raggruppare dati complessi su griglie bidimensionali.'},
        {'name': 'TCNNClassifier', 'desc': 'Classificatore convoluzionale profondo MobileNetV2 per immagini.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, ClassifyImage', 'role': 'Analizzare ed etichettare immagini o fotogrammi video.'},
        {'name': 'TLSTMPredictor', 'desc': 'Previsore di serie temporali tramite rete ricorrente LSTM.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, TrainLSTM, PredictNext', 'role': 'Prevedere l\'andamento futuro di dati sensoriali sequenziali.'},
        {'name': 'TAIVoiceSynthesizer', 'desc': 'Motore di sintesi vocale (TTS) nativo Windows e Linux.', 'props': 'Volume, Rate, VoiceName, Asynchronous', 'methods': 'Say, GetAvailableVoices', 'role': 'Generare messaggi vocali e allarmi IA tramite altoparlanti.'},
        {'name': 'TAIDiskTreeScanner', 'desc': 'Scansionatore asincrono dell\'albero dei file locali.', 'props': 'TargetFolder, ShowProgress, IncludeSubfolders', 'methods': 'Scan, StopScan', 'role': 'Scansionare directory locali e indicizzare file per dataset.'},
        {'name': 'TAI_DOCFILESMANAGER', 'desc': 'Gestore fisico di documenti e file.', 'props': 'StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength', 'methods': 'Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument', 'role': 'Organizzare i file di documentazione per RAG e addestramento.'}
    ],
    'ar': [
        {'name': 'TCHATGPT', 'desc': 'الموصل العام لنماذج OpenAI وLLMs السحابية أو الخواديم المحلية.', 'props': 'APIKey, Provider, TipoChat, CustomModel, MaxTokens', 'methods': 'SendQuestion(ASK): Boolean, TipoModelo: string', 'role': 'معالجة اللغة الطبيعية وتوليد استجابات معرفية ذكية.'},
        {'name': 'TNeuralNetwork', 'desc': 'الشبكة العصبية متعددة الطبقات الأصلية بلغة باسكال الخالصة.', 'props': 'LearningRate, ActivationType', 'methods': 'Initialize, Predict, Train, TrainEpochs, SaveNetwork', 'role': 'تدريب النماذج المحلية وإجراء عمليات التنبؤ الرياضي.'},
        {'name': 'TAICodeAssistant', 'desc': 'مساعد معرفي لمراجعة الأكواد البرمجية وتحسينها تلقائياً.', 'props': 'ChatGPT', 'methods': 'OptimizeCode, FindBugs, DocumentCode, ExplainCode', 'role': 'تحليل كود باسكال البرمجي واقتراح عمليات إعادة الهيكلة والتصحيح.'},
        {'name': 'TAIDatasetGenerator', 'desc': 'مولد ومصدر مجموعات البيانات المهيكلة (JSONL, CSV).', 'props': 'DataRows', 'methods': 'AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV', 'role': 'تجميع قواعد البيانات وتقسيم مجموعات التدريب.'},
        {'name': 'TTokenizer', 'desc': 'مقسم النصوص ومحلل الكلمات السريع.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'تحويل النصوص الخام البرمجية لفهارس رقمية.'},
        {'name': 'TAIGraphMap', 'desc': 'مصنف نصوص قابل للتفسير يعتمد على خرائط الرسوم البيانية الموزونة للرموز.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile', 'role': 'تصنيف النصوص القصيرة وتصنيف التذاكر محلياً دون أي اعتماديات خارجية.'},
        {'name': 'TPythonConnector', 'desc': 'جسر تشغيل ومحاكاة نصوص بايثون البرمجية في وقت التشغيل.', 'props': 'DLLPath, Active, Version', 'methods': 'ExecString, GetVar, SetVar, Eval', 'role': 'دمج النماذج المتقدمة من بيئة عمل بايثون (مثل TensorFlow).'},
        {'name': 'TPerceptron', 'desc': 'مكون العصبون المنفرد الكلاسيكي الثنائي في باسكال.', 'props': 'LearningRate, Weights, Bias', 'methods': 'Initialize, Predict, Train, TrainEpochs', 'role': 'تصنيف الحالات المنطقية الثنائية القابلة للفصل خطياً بسرعة.'},
        {'name': 'TSOMMap', 'desc': 'شبكة Kohonen ذاتية التنظيم لعمليات تجميع البيانات.', 'props': 'GridWidth, GridHeight, InputDim', 'methods': 'Initialize, FindBMU, TrainStep, Train', 'role': 'تجميع البيانات المعقدة وعرضها على شبكات ثنائية الأبعاد.'},
        {'name': 'TCNNClassifier', 'desc': 'مكون تصنيف الصور Convolucional العميقة MobileNetV2.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, ClassifyImage', 'role': 'تحليل وتصنيف الصور أو إطارات الفيديو المباشرة.'},
        {'name': 'TLSTMPredictor', 'desc': 'متنبئ السلاسل الزمنية باستخدام الشبكات التكرارية LSTM.', 'props': 'PythonConnector', 'methods': 'InstallDependencies, TrainLSTM, PredictNext', 'role': 'التنبؤ بالقيم المستقبلية لبيانات الحساسات المتسلسلة.'},
        {'name': 'TAIVoiceSynthesizer', 'desc': 'محرك أصلي متعدد المنصات لتخليق وتحويل النصوص لكلام مسموع.', 'props': 'Volume, Rate, VoiceName, Asynchronous', 'methods': 'Say, GetAvailableVoices', 'role': 'تخليق إشعارات صوتية مسموعة من مخرجات الذكاء الاصطناعي.'},
        {'name': 'TAIDiskTreeScanner', 'desc': 'ماسح شجرة الملفات المحلية غير المتزامن.', 'props': 'TargetFolder, ShowProgress, IncludeSubfolders', 'methods': 'Scan, StopScan', 'role': 'مسح المجلدات المحلية وفهرسة الملفات لإعداد مجموعات البيانات.'},
        {'name': 'TAI_DOCFILESMANAGER', 'desc': 'مدير المستندات والملفات المادي.', 'props': 'StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength', 'methods': 'Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument', 'role': 'تنظيم ملفات المستندات للاستخدام مع RAG والتدريب.'}
    ]
}

lazarus_example = """
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
"""

def generate():
    package_root = r"D:\projetos\maurinsoft\CHATGPT\pacote"
    for lang_code, lang_trans in langs.items():
        filename = f"README.{lang_code}.md"
        filepath = os.path.join(package_root, filename)
        
        # Build markdown content
        content = []
        content.append(f"# 🧠 {lang_trans['title']}")
        content.append("")
        content.append(f"> [!NOTE]")
        content.append(f"> {lang_trans['intro']}")
        content.append("")
        content.append(f"## {lang_trans['details']}")
        content.append("")
        
        # Components table
        content.append(f"| {lang_trans['comp']} | {lang_trans['desc']} | {lang_trans['props']} | {lang_trans['methods']} | {lang_trans['role']} |")
        content.append("|---|---|---|---|---|")
        for c in comps_info[lang_code]:
            content.append(f"| **{c['name']}** | {c['desc']} | `{c['props']}` | `{c['methods']}` | {c['role']} |")
        content.append("")
        
        # Lazarus Code Example
        content.append(f"### 💻 {lang_trans['example']}")
        content.append(lazarus_example)
        content.append("")
        
        # Samples
        content.append(f"### {lang_trans['samples_title']}")
        content.append(lang_trans['samples_desc'])
        content.append("")
        
        # Unified Bridge mention
        content.append(f"### ⚡ {lang_trans['unified']}")
        content.append(lang_trans['unified_text'])
        content.append("")
        
        # Save file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write("\n".join(content))
            
        print(f"Generated Root: {filepath}")

if __name__ == '__main__':
    generate()
