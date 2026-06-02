# -*- coding: utf-8 -*-
import os

langs = {
    'pt': {
        'title': 'Documentação da Aba {}',
        'intro': 'Esta pasta contém a suíte de componentes do Lazarus sob a aba **{}**.',
        'details': 'Referência Detalhada dos Componentes',
        'comp': 'Componente',
        'desc': 'Descrição',
        'props': 'Propriedades Importantes',
        'methods': 'Métodos Principais',
        'role': 'Papel do Agente de IA',
        'example': 'Exemplo de Código Lazarus',
        'dir': 'Diretório',
        'unified': 'Ponte de IA e Hardware'
    },
    'en': {
        'title': 'Documentation for {} Tab',
        'intro': 'This folder contains the Lazarus components suite under the **{}** tab.',
        'details': 'Detailed Component Reference',
        'comp': 'Component',
        'desc': 'Description',
        'props': 'Important Properties',
        'methods': 'Main Methods',
        'role': 'AI Agent Role',
        'example': 'Lazarus Code Example',
        'dir': 'Directory',
        'unified': 'AI and Hardware Bridge'
    },
    'es': {
        'title': 'Documentación de la Pestaña {}',
        'intro': 'Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **{}**.',
        'details': 'Referencia Detallada de Componentes',
        'comp': 'Componente',
        'desc': 'Descripción',
        'props': 'Propiedades Importantes',
        'methods': 'Métodos Principales',
        'role': 'Rol del Agente de IA',
        'example': 'Ejemplo de Código Lazarus',
        'dir': 'Directorio',
        'unified': 'Puente de IA y Hardware'
    },
    'fr': {
        'title': 'Documentation de l\'onglet {}',
        'intro': 'Ce dossier contient la suite de composants Lazarus sous l\'onglet **{}**.',
        'details': 'Référence Détaillée des Composants',
        'comp': 'Composant',
        'desc': 'Description',
        'props': 'Propriétés Importantes',
        'methods': 'Méthodes Principales',
        'role': 'Rôle de l\'Agent d\'IA',
        'example': 'Exemple de Code Lazarus',
        'dir': 'Dossier',
        'unified': 'Pont d\'IA et de Matériel'
    },
    'it': {
        'title': 'Documentazione della Scheda {}',
        'intro': 'Questa cartella contiene la suite di componenti Lazarus sotto la scheda **{}**.',
        'details': 'Riferimento Dettagliato dei Componenti',
        'comp': 'Componente',
        'desc': 'Descrizione',
        'props': 'Proprietà Importanti',
        'methods': 'Metodi Principali',
        'role': 'Ruolo dell\'Agente di IA',
        'example': 'Esempio di Codice Lazarus',
        'dir': 'Directory',
        'unified': 'Ponte di IA e Hardware'
    },
    'ar': {
        'title': 'توثيق علامة التبويب {}',
        'intro': 'يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **{}**.',
        'details': 'مرجع المكونات التفصيلي',
        'comp': 'المكون',
        'desc': 'الوصف',
        'props': 'الخصائص الهامة',
        'methods': 'الأساليب الرئيسية',
        'role': 'دور وكيل الذكاء الاصطناعي',
        'example': 'مثال على كود لازاروس',
        'dir': 'المجلد',
        'unified': 'جسر الذكاء الاصطناعي والأجهزة'
    }
}

tab_data = {
    'IA': {
        'icon': '🧠',
        'pt': {
            'desc': 'Núcleo de Inteligência Artificial e Conectividade Neural.',
            'info': 'Fornece conexões a modelos de linguagem (OpenAI) e implementa redes neurais MLP de Pascal puro.',
            'comps': [
                {'name': 'TCHATGPT', 'desc': 'Conector OpenAI/ChatGPT.', 'props': 'APIKey, Model, MaxTokens', 'methods': 'SendQuestion(const AQuestion: string): Boolean', 'role': 'Processar NLP e tomar decisões baseadas em texto.'},
                {'name': 'TNeuralNetwork', 'desc': 'Rede Neural Multicamadas nativa.', 'props': 'InputNodes, HiddenNodes, OutputNodes, LearningRate', 'methods': 'Train, Predict', 'role': 'Aprender padrões complexos a partir de conjuntos de dados.'},
                {'name': 'TTokenizer', 'desc': 'Tokenizador de texto.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Pré-processar strings brutos em índices numéricos.'},
                {'name': 'TAIGraphMap', 'desc': 'Classificador textual por grafo ponderado.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction', 'role': 'Classificar textos curtos localmente sem dependências de rede.'}
            ]
        },
        'en': {
            'desc': 'Artificial Intelligence Core and Neural Connectivity.',
            'info': 'Provides connectivity to language models (OpenAI) and implements pure Pascal MLP neural networks.',
            'comps': [
                {'name': 'TCHATGPT', 'desc': 'OpenAI/ChatGPT connector.', 'props': 'APIKey, Model, MaxTokens', 'methods': 'SendQuestion(const AQuestion: string): Boolean', 'role': 'Process NLP and make text-based decisions.'},
                {'name': 'TNeuralNetwork', 'desc': 'Native Multilayer Perceptron Neural Network.', 'props': 'InputNodes, HiddenNodes, OutputNodes, LearningRate', 'methods': 'Train, Predict', 'role': 'Learn complex patterns from datasets.'},
                {'name': 'TTokenizer', 'desc': 'Text tokenizer.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Preprocess raw strings into numerical indices.'},
                {'name': 'TAIGraphMap', 'desc': 'Weighted graph text classifier.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction', 'role': 'Classify short texts locally without network dependencies.'}
            ]
        },
        'es': {
            'desc': 'Núcleo de Inteligencia Artificial y Conectividad Neural.',
            'info': 'Proporciona conexiones a modelos de lenguaje (OpenAI) e implementa redes neuronales MLP nativas en Pascal.',
            'comps': [
                {'name': 'TCHATGPT', 'desc': 'Conector OpenAI/ChatGPT.', 'props': 'APIKey, Model, MaxTokens', 'methods': 'SendQuestion(const AQuestion: string): Boolean', 'role': 'Procesar NLP y tomar decisiones basadas en texto.'},
                {'name': 'TNeuralNetwork', 'desc': 'Red Neuronal Multicapa nativa.', 'props': 'InputNodes, HiddenNodes, OutputNodes, LearningRate', 'methods': 'Train, Predict', 'role': 'Aprender patrones complejos a partir de conjuntos de datos.'},
                {'name': 'TTokenizer', 'desc': 'Tokenizador de texto.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Preprocesar cadenas de texto en índices numéricos.'},
                {'name': 'TAIGraphMap', 'desc': 'Clasificador textual por grafo ponderado.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction', 'role': 'Clasificar textos cortos localmente sin dependencias de red.'}
            ]
        },
        'fr': {
            'desc': 'Noyau d\'Intelligence Artificielle et Connectivité Neurone.',
            'info': 'Fournit une connectivité aux modèles de langage (OpenAI) et implémente des réseaux de neurones MLP en pur Pascal.',
            'comps': [
                {'name': 'TCHATGPT', 'desc': 'Connecteur OpenAI/ChatGPT.', 'props': 'APIKey, Model, MaxTokens', 'methods': 'SendQuestion(const AQuestion: string): Boolean', 'role': 'Traiter le NLP et prendre des décisions textuelles.'},
                {'name': 'TNeuralNetwork', 'desc': 'Réseau de neurones Perceptron Multicouche natif.', 'props': 'InputNodes, HiddenNodes, OutputNodes, LearningRate', 'methods': 'Train, Predict', 'role': 'Apprendre des modèles complexes à partir d\'ensembles de données.'},
                {'name': 'TTokenizer', 'desc': 'Tokeniseur de texte.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Prétraiter des chaînes brutes en indices numériques.'},
                {'name': 'TAIGraphMap', 'desc': 'Classificateur de texte par graphe pondéré.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction', 'role': 'Classifier des textes courts localement sans dépendance réseau.'}
            ]
        },
        'it': {
            'desc': 'Nucleo di Intelligenza Artificiale e Connettività Neurale.',
            'info': 'Fornisce connettività ai modelli linguistici (OpenAI) e implementa reti neurali MLP in puro Pascal.',
            'comps': [
                {'name': 'TCHATGPT', 'desc': 'Connettore OpenAI/ChatGPT.', 'props': 'APIKey, Model, MaxTokens', 'methods': 'SendQuestion(const AQuestion: string): Boolean', 'role': 'Elaborare il NLP e prendere decisioni basate sul testo.'},
                {'name': 'TNeuralNetwork', 'desc': 'Rete Neurale Perceptron Multistrato nativa.', 'props': 'InputNodes, HiddenNodes, OutputNodes, LearningRate', 'methods': 'Train, Predict', 'role': 'Apprendere schemi complessi dai set di dati.'},
                {'name': 'TTokenizer', 'desc': 'Tokenizzatore di testo.', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'Pre-elaborare stringhe grezze in indici numerici.'},
                {'name': 'TAIGraphMap', 'desc': 'Classificatore testuale per grafo pesato.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction', 'role': 'Classificare testi brevi localmente senza dipendenze di rete.'}
            ]
        },
        'ar': {
            'desc': 'نواة الذكاء الاصطناعي والاتصال العصبي.',
            'info': 'يوفر اتصالاً بنماذج اللغة (OpenAI) وينفذ شبكات عصبية MLP بلغة باسكال الخالصة.',
            'comps': [
                {'name': 'TCHATGPT', 'desc': 'موصل OpenAI/ChatGPT.', 'props': 'APIKey, Model, MaxTokens', 'methods': 'SendQuestion(const AQuestion: string): Boolean', 'role': 'معالجة اللغة الطبيعية واتخاذ القرارات النصية.'},
                {'name': 'TNeuralNetwork', 'desc': 'شبكة عصبية متعددة الطبقات أصلية.', 'props': 'InputNodes, HiddenNodes, OutputNodes, LearningRate', 'methods': 'Train, Predict', 'role': 'تعلم الأنماط المعقدة من مجموعات البيانات.'},
                {'name': 'TTokenizer', 'desc': 'مقسم النصوص (Tokenizer).', 'props': 'LowerCase', 'methods': 'Tokenize, GetVocabulary', 'role': 'معالجة النصوص الخام وتحويلها لفهارس رقمية.'},
                {'name': 'TAIGraphMap', 'desc': 'مصنف نصوص يعتمد على الرسوم البيانية الموزونة للرموز.', 'props': 'Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay', 'methods': 'Train, TrainItem, Predict, PredictRanking, ExplainPrediction', 'role': 'تصنيف النصوص القصيرة محلياً دون أي اتصال بالشبكة.'}
            ]
        }
    },
    'IA Agent': {
        'icon': '🤖',
        'pt': {
            'desc': 'Agentes Inteligentes Autônomos e Tomada de Decisão.',
            'info': 'Estrutura de orquestração cognitiva que planeja ações e mapeia saídas físicas usando RTTI dinâmico.',
            'comps': [
                {'name': 'TAIAgent', 'desc': 'Cérebro do Agente cognitivo.', 'props': 'ChatGPT, Options, Action, SystemPrompt', 'methods': 'Execute(const AInputData: string): Boolean', 'role': 'Analisar telemetria e planejar ações autônomas.'},
                {'name': 'TAIAgentResource', 'desc': 'Repositório de dispositivos e hardware vinculado.', 'props': 'Resources (Collection)', 'methods': 'FindResource(const AName: string): TAIAgentResourceItem', 'role': 'Mapear canais físicos (e-mail, redes, sensores) para a IA.'},
                {'name': 'TAIAgentOutput', 'desc': 'Disparador automático de canais de saída.', 'props': 'Action, Resource, Mappings', 'methods': 'ExecuteAction(const AActionName: string; AParams: TStrings): Boolean', 'role': 'Conectar a decisão lógica da IA à execução em hardware.'}
            ]
        },
        'en': {
            'desc': 'Autonomous Intelligent Agents and Decision Making.',
            'info': 'Cognitive orchestration framework that plans actions and maps physical outputs using dynamic RTTI.',
            'comps': [
                {'name': 'TAIAgent', 'desc': 'Brain of the cognitive Agent.', 'props': 'ChatGPT, Options, Action, SystemPrompt', 'methods': 'Execute(const AInputData: string): Boolean', 'role': 'Analyze telemetry and plan autonomous actions.'},
                {'name': 'TAIAgentResource', 'desc': 'Repository of connected hardware and devices.', 'props': 'Resources (Collection)', 'methods': 'FindResource(const AName: string): TAIAgentResourceItem', 'role': 'Map physical channels (email, network, sensors) to the AI.'},
                {'name': 'TAIAgentOutput', 'desc': 'Automated dispatcher for physical channels.', 'props': 'Action, Resource, Mappings', 'methods': 'ExecuteAction(const AActionName: string; AParams: TStrings): Boolean', 'role': 'Connect logical AI decision to hardware execution.'}
            ]
        },
        'es': {
            'desc': 'Agentes Inteligentes Autónomos y Toma de Decisiones.',
            'info': 'Estructura de orquestación cognitiva que planifica acciones y mapea salidas físicas utilizando RTTI dinámico.',
            'comps': [
                {'name': 'TAIAgent', 'desc': 'Cerebro del Agente cognitivo.', 'props': 'ChatGPT, Options, Action, SystemPrompt', 'methods': 'Execute(const AInputData: string): Boolean', 'role': 'Analizar telemetría y planificar acciones autónomas.'},
                {'name': 'TAIAgentResource', 'desc': 'Repositorio de dispositivos y hardware vinculados.', 'props': 'Resources (Collection)', 'methods': 'FindResource(const AName: string): TAIAgentResourceItem', 'role': 'Mapear canales físicos (correo, redes, sensores) para la IA.'},
                {'name': 'TAIAgentOutput', 'desc': 'Disparador automático de canales de salida.', 'props': 'Action, Resource, Mappings', 'methods': 'ExecuteAction(const AActionName: string; AParams: TStrings): Boolean', 'role': 'Conectar la decisión lógica de la IA con la ejecución de hardware.'}
            ]
        },
        'fr': {
            'desc': 'Agents Intelligents Autonomes et Prise de Décision.',
            'info': 'Framework d\'orchestration cognitive qui planifie les actions et cartographie les sorties physiques via RTTI dynamique.',
            'comps': [
                {'name': 'TAIAgent', 'desc': 'Cerveau de l\'agent cognitif.', 'props': 'ChatGPT, Options, Action, SystemPrompt', 'methods': 'Execute(const AInputData: string): Boolean', 'role': 'Analyser la télémétrie et planifier des actions autonomes.'},
                {'name': 'TAIAgentResource', 'desc': 'Répertoire de matériels et dispositifs connectés.', 'props': 'Resources (Collection)', 'methods': 'FindResource(const AName: string): TAIAgentResourceItem', 'role': 'Associer les canaux physiques (e-mail, réseau, capteurs) à l\'IA.'},
                {'name': 'TAIAgentOutput', 'desc': 'Déclencheur automatique de canaux physiques.', 'props': 'Action, Resource, Mappings', 'methods': 'ExecuteAction(const AActionName: string; AParams: TStrings): Boolean', 'role': 'Connecter la décision logique de l\'IA à l\'exécution matérielle.'}
            ]
        },
        'it': {
            'desc': 'Agenti Intelligenti Autonomi e Presa di Decisione.',
            'info': 'Framework di orchestrazione cognitiva che pianifica azioni e mappa le uscite fisiche utilizzando RTTI dinamico.',
            'comps': [
                {'name': 'TAIAgent', 'desc': 'Cervello dell\'Agente cognitivo.', 'props': 'ChatGPT, Options, Action, SystemPrompt', 'methods': 'Execute(const AInputData: string): Boolean', 'role': 'Analizzare la telemetria e pianificare azioni autonome.'},
                {'name': 'TAIAgentResource', 'desc': 'Repository di dispositivi e hardware collegati.', 'props': 'Resources (Collection)', 'methods': 'FindResource(const AName: string): TAIAgentResourceItem', 'role': 'Mappare canali fisici (e-mail, reti, sensori) per l\'IA.'},
                {'name': 'TAIAgentOutput', 'desc': 'Disparatore automatico di canali fisici.', 'props': 'Action, Resource, Mappings', 'methods': 'ExecuteAction(const AActionName: string; AParams: TStrings): Boolean', 'role': 'Collegare la decisione logica dell\'IA all\'esecuzione hardware.'}
            ]
        },
        'ar': {
            'desc': 'الوكلاء الأذكياء المستقلون واتخاذ القرار.',
            'info': 'إطار عمل لتنسيق الإدراك المعرفي يخطط للإجراءات ويرسم خرائط المخرجات المادية باستخدام RTTI الديناميكي.',
            'comps': [
                {'name': 'TAIAgent', 'desc': 'دماغ الوكيل المعرفي.', 'props': 'ChatGPT, Options, Action, SystemPrompt', 'methods': 'Execute(const AInputData: string): Boolean', 'role': 'تحليل القياسات عن بعد وتخطيط الإجراءات المستقلة.'},
                {'name': 'TAIAgentResource', 'desc': 'مستودع الأجهزة والأدوات المتصلة.', 'props': 'Resources (Collection)', 'methods': 'FindResource(const AName: string): TAIAgentResourceItem', 'role': 'رسم خرائط القنوات المادية (البريد الإلكتروني، الشبكة، أجهزة الاستشعار) للذكاء الاصطناعي.'},
                {'name': 'TAIAgentOutput', 'desc': 'المرسل الآلي للقنوات المادية.', 'props': 'Action, Resource, Mappings', 'methods': 'ExecuteAction(const AActionName: string; AParams: TStrings): Boolean', 'role': 'ربط قرار الذكاء الاصطناعي المنطقي بالتنفيذ المادي.'}
            ]
        }
    },
    'IA Filtros Sonoros': {
        'icon': '🎵',
        'pt': {
            'desc': 'Processamento de Sinais de Áudio e Filtros Digitais.',
            'info': 'Módulo para transformação de frequências sonoras e aplicação de filtros lineares rápidos.',
            'comps': [
                {'name': 'TAISoundFilters', 'desc': 'Processador de sinais sonoros.', 'props': 'FilterType (LowPass, HighPass, BandPass), CutoffFrequency', 'methods': 'ApplyFilter(const AInputWav, AOutputWav: string): Boolean', 'role': 'Limpar ruídos e ajustar frequências de gravações obtidas via microfone.'}
            ]
        },
        'en': {
            'desc': 'Audio Signal Processing and Digital Filters.',
            'info': 'Module for sound frequency transformations and fast linear filtering applications.',
            'comps': [
                {'name': 'TAISoundFilters', 'desc': 'Sound signal digital processor.', 'props': 'FilterType (LowPass, HighPass, BandPass), CutoffFrequency', 'methods': 'ApplyFilter(const AInputWav, AOutputWav: string): Boolean', 'role': 'Clean background noises and adjust frequencies of recordings obtained via microphones.'}
            ]
        },
        'es': {
            'desc': 'Procesamiento de Señales de Audio y Filtros Digitales.',
            'info': 'Módulo para la transformación de frecuencias sonoras y la aplicación de filtros lineales rápidos.',
            'comps': [
                {'name': 'TAISoundFilters', 'desc': 'Procesador de señales de sonido.', 'props': 'FilterType (LowPass, HighPass, BandPass), CutoffFrequency', 'methods': 'ApplyFilter(const AInputWav, AOutputWav: string): Boolean', 'role': 'Limpiar ruidos de fondo y ajustar frecuencias de grabaciones obtenidas de micrófonos.'}
            ]
        },
        'fr': {
            'desc': 'Traitement des Signaux Audio et Filtres Numériques.',
            'info': 'Module pour la transformation des fréquences sonores et l\'application de filtres linéaires rapides.',
            'comps': [
                {'name': 'TAISoundFilters', 'desc': 'Processeur numérique de signaux sonores.', 'props': 'FilterType (LowPass, HighPass, BandPass), CutoffFrequency', 'methods': 'ApplyFilter(const AInputWav, AOutputWav: string): Boolean', 'role': 'Nettoyer les bruits de fond et ajuster les fréquences des enregistrements micro.'}
            ]
        },
        'it': {
            'desc': 'Elaborazione dei Segnali Audio e Filtri Digitali.',
            'info': 'Modulo per la trasformazione delle frequenze sonore e l\'applicazione di filtri lineari veloci.',
            'comps': [
                {'name': 'TAISoundFilters', 'desc': 'Elaboratore digitale di segnali sonori.', 'props': 'FilterType (LowPass, HighPass, BandPass), CutoffFrequency', 'methods': 'ApplyFilter(const AInputWav, AOutputWav: string): Boolean', 'role': 'Ripulire i rumori di fondo e regolare le frequenze delle registrazioni da microfoni.'}
            ]
        },
        'ar': {
            'desc': 'معالجة إشارات الصوت والفلاتر الرقمية.',
            'info': 'وحدة لتحويل الترددات الصوتية وتطبيق مرشحات خطية سريعة.',
            'comps': [
                {'name': 'TAISoundFilters', 'desc': 'معالج إشارات الصوت الرقمية.', 'props': 'FilterType (LowPass, HighPass, BandPass), CutoffFrequency', 'methods': 'ApplyFilter(const AInputWav, AOutputWav: string): Boolean', 'role': 'تنظيف ضوضاء الخلفية وضبط ترددات تسجيلات الميكروفون.'}
            ]
        }
    },
    'IA Image': {
        'icon': '🖼️',
        'pt': {
            'desc': 'Visão Computacional e Filtros Digitais de Imagem.',
            'info': 'Filtros avançados de preparação matricial de imagens para processamento neural de visão.',
            'comps': [
                {'name': 'TAIImageFilters', 'desc': 'Filtro digital matricial de imagem.', 'props': 'FilterType (Sobel, Canny, Gaussian, Grayscale)', 'methods': 'ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean', 'role': 'Pré-processar imagens e frames de câmeras para melhorar taxas de reconhecimento.'}
            ]
        },
        'en': {
            'desc': 'Computer Vision and Digital Image Filters.',
            'info': 'Advanced matrix image preparation filters for neural vision processing.',
            'comps': [
                {'name': 'TAIImageFilters', 'desc': 'Digital matrix image filter.', 'props': 'FilterType (Sobel, Canny, Gaussian, Grayscale)', 'methods': 'ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean', 'role': 'Preprocess images and camera frames to enhance neural recognition accuracy.'}
            ]
        },
        'es': {
            'desc': 'Visión Computacional y Filtros Digitales de Imagen.',
            'info': 'Filtros avanzados de preparación matricial de imágenes para procesamiento neural de visión.',
            'comps': [
                {'name': 'TAIImageFilters', 'desc': 'Filtro de imagen matricial digital.', 'props': 'FilterType (Sobel, Canny, Gaussian, Grayscale)', 'methods': 'ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean', 'role': 'Preprocesar imágenes y cuadros de cámara para mejorar las tasas de reconocimiento.'}
            ]
        },
        'fr': {
            'desc': 'Vision par Ordinateur et Filtres d\'Image Numériques.',
            'info': 'Filtres matriciels avancés de préparation d\'image pour le traitement de la vision neuronale.',
            'comps': [
                {'name': 'TAIImageFilters', 'desc': 'Filtre matriciel numérique d\'image.', 'props': 'FilterType (Sobel, Canny, Gaussian, Grayscale)', 'methods': 'ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean', 'role': 'Prétraiter les images et les flux caméras pour améliorer la reconnaissance.'}
            ]
        },
        'it': {
            'desc': 'Visione Artificiale e Filtri Digitali di Immagine.',
            'info': 'Filtri avanzati di preparazione matriciale delle immagini per l\'elaborazione della visione neurale.',
            'comps': [
                {'name': 'TAIImageFilters', 'desc': 'Filtro d\'immagine matriciale digitale.', 'props': 'FilterType (Sobel, Canny, Gaussian, Grayscale)', 'methods': 'ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean', 'role': 'Pre-elaborare immagini e fotogrammi per migliorare la precisione del riconoscimento.'}
            ]
        },
        'ar': {
            'desc': 'الرؤية الحاسوبية وفلاتر الصور الرقمية.',
            'info': 'فلاتر متقدمة لمعالجة مصفوفة الصور وتهيئتها للمعالجة العصبية البصرية.',
            'comps': [
                {'name': 'TAIImageFilters', 'desc': 'فلتر الصور الرقمية للمصفوفات.', 'props': 'FilterType (Sobel, Canny, Gaussian, Grayscale)', 'methods': 'ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean', 'role': 'معالجة الصور المسبقة وإطارات الكاميرات لتعزيز دقة التعرف البصري.'}
            ]
        }
    },
    'IA Math': {
        'icon': '📐',
        'pt': {
            'desc': 'Álgebra Vetorial e Matricial de Alta Velocidade.',
            'info': 'Implementa rotinas matemáticas de processamento de tensores semelhantes ao NumPy do Python.',
            'comps': [
                {'name': 'TNumPS', 'desc': 'Gerador e manipulador de matrizes e vetores.', 'props': 'ThreadSafe', 'methods': 'Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random', 'role': 'Realizar operações matemáticas pesadas e álgebra linear para IA.'}
            ]
        },
        'en': {
            'desc': 'High-Speed Vector and Matrix Algebra.',
            'info': 'Implements mathematical tensor routines similar to Python\'s NumPy library.',
            'comps': [
                {'name': 'TNumPS', 'desc': 'Matrix and vector generator and manipulator.', 'props': 'ThreadSafe', 'methods': 'Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random', 'role': 'Perform heavy statistical computations and linear algebra operations for the AI.'}
            ]
        },
        'es': {
            'desc': 'Álgebra Vectorial y Matricial de Alta Velocidad.',
            'info': 'Implementa rutinas matemáticas de procesamiento de tensores similares a la biblioteca NumPy de Python.',
            'comps': [
                {'name': 'TNumPS', 'desc': 'Generador y manipulador de matrices y vectores.', 'props': 'ThreadSafe', 'methods': 'Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random', 'role': 'Realizar operaciones matemáticas pesadas y álgebra lineal para la IA.'}
            ]
        },
        'fr': {
            'desc': 'Algèbre Vectorielle et Matricielle à Haute Vitesse.',
            'info': 'Implémente des routines mathématiques de traitement de tenseurs similaires à NumPy en Python.',
            'comps': [
                {'name': 'TNumPS', 'desc': 'Générateur et manipulateur de matrices et de vecteurs.', 'props': 'ThreadSafe', 'methods': 'Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random', 'role': 'Effectuer des calculs statistiques lourds et de l\'algèbre linéaire pour l\'IA.'}
            ]
        },
        'it': {
            'desc': 'Algebra Vettoriale e Matriciale ad Alta Velocità.',
            'info': 'Implementa routine matematiche per l\'elaborazione di tensori simili a NumPy di Python.',
            'comps': [
                {'name': 'TNumPS', 'desc': 'Generatore e manipolatore di matrici e vettori.', 'props': 'ThreadSafe', 'methods': 'Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random', 'role': 'Eseguire calcoli statistici pesanti e operazioni di algebra lineare per l\'IA.'}
            ]
        },
        'ar': {
            'desc': 'جبر المتجهات والمصفوفات فائق السرعة.',
            'info': 'ينفذ عمليات الرياضيات للمصفوفات الرياضية بشكل مشابه لمكتبة NumPy في بايثون.',
            'comps': [
                {'name': 'TNumPS', 'desc': 'منشئ ومحرك المصفوفات والمتجهات.', 'props': 'ThreadSafe', 'methods': 'Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random', 'role': 'إجراء الحسابات الإحصائية الثقيلة وعمليات الجبر الخطي للذكاء الاصطناعي.'}
            ]
        }
    },
    'IA Input': {
        'icon': '🔌',
        'pt': {
            'desc': 'Captura Avançada de Dispositivos de Entrada, Sensores e Redes.',
            'info': 'Mapeia e captura dados do mundo real (teclado, mouse, câmeras, brokers MQTT, sockets) para alimentar modelos cognitivos.',
            'comps': [
                {'name': 'TAIInputData', 'desc': 'Normalizador linear de vetores numéricos.', 'props': 'MinRange, MaxRange', 'methods': 'Normalize, Denormalize', 'role': 'Normalizar dados flutuantes brutos para faixas toleradas por Redes Neurais.'},
                {'name': 'TAICameraInput', 'desc': 'Capturador de frames de câmera física nativa.', 'props': 'DeviceIndex, Width, Height, Active', 'methods': 'StartCapture, StopCapture, CaptureFrame', 'role': 'Fornecer quadros visuais em tempo real para IA de visão computacional.'},
                {'name': 'TAIAudioInput', 'desc': 'Gravador e mixer de áudio.', 'props': 'InputSource (Mic, Wave), BitRate', 'methods': 'StartRecord, StopRecord, MixAudio', 'role': 'Gravar vozes do ambiente e preparar WAV para modelos de transcrição.'},
                {'name': 'TAIWebAPIServer', 'desc': 'Servidor REST API incorporado.', 'props': 'Port, Active, AllowedRoutes', 'methods': 'StartServer, StopServer', 'role': 'Expor um endpoint HTTP para receber dados de agentes externos.'},
                {'name': 'TAISocketTCP', 'desc': 'Conector de Sockets TCP Cliente/Servidor.', 'props': 'Host, Port, Mode, Active', 'methods': 'Connect, Disconnect, SendText, ReceiveText', 'role': 'Estabelecer links e canais de streaming de texto de baixo nível.'},
                {'name': 'TAISocketUDP', 'desc': 'Conector de Sockets UDP rápido.', 'props': 'Host, Port, Active', 'methods': 'SendText, ReceiveText', 'role': 'Transmitir telemetria de sensores de forma rápida e assíncrona.'},
                {'name': 'TAISerialModem', 'desc': 'Porta Serial e Gateway de SMS GSM.', 'props': 'DeviceName, BaudRate, Active', 'methods': 'OpenPort, SendATCommand, SendSMS', 'role': 'Enviar mensagens SMS físicas via modems analógicos e microcontroladores.'},
                {'name': 'TAIPOSPrinter', 'desc': 'Impressora Esc/POS térmica.', 'props': 'DevicePath, Active', 'methods': 'PrintText, PrintBarcode', 'role': 'Emitir relatórios impressos e comprovantes em bobina de papel.'},
                {'name': 'TAICFTVIP', 'desc': 'Câmera IP MJPEG.', 'props': 'IPAddress, Port, Active', 'methods': 'CaptureStreamFrame', 'role': 'Adquirir vídeo de câmeras de segurança CFTV distribuídas na rede.'},
                {'name': 'TAIModbusClient', 'desc': 'Cliente Modbus industrial (TCP/RTU).', 'props': 'Host, Port, Mode, Active', 'methods': 'ReadHoldingRegisters, WriteRegister', 'role': 'Leitura de registradores sensores de temperatura, pressão e estado físico.'},
                {'name': 'TAIMQTTClient', 'desc': 'Cliente de Rede IoT MQTT.', 'props': 'Host, Port, Active', 'methods': 'ConnectBroker, Publish, Subscribe', 'role': 'Sincronizar telemetria IoT com brokers (ex: HiveMQ) sem travar a UI.'},
                {'name': 'TAIEmailClient', 'desc': 'Cliente SMTP/POP3 nativo.', 'props': 'HostSMTP, PortSMTP, Username, Password', 'methods': 'SendEmail, FetchEmails', 'role': 'Ler caixas de entrada de e-mails em sockets e enviar notificações.'},
                {'name': 'TAIMessenger', 'desc': 'Gateway WhatsApp e SMS via REST.', 'props': 'SMSApiURL, WhatsAppApiURL, WhatsAppToken', 'methods': 'SendSMS, SendWhatsApp', 'role': 'Disparar alertas em tempo real direto nos celulares dos operadores.'},
                {'name': 'TAIIndustrialBridge', 'desc': 'Ponte dinâmica Profinet/Profibus CLP.', 'props': 'IPAddress, Rack, Slot, Active', 'methods': 'ConnectBridge, ReadBytes, WriteBytes', 'role': 'Controlar e ler estado físico de pontes automatizadas industriais (S7).'},
                {'name': 'TAIChromiumBrowser', 'desc': 'Navegador Web incorporado.', 'props': 'URL, ShowAddressBar', 'methods': 'Navigate, GoBack, Reload', 'role': 'Renderizar interfaces web e extrair dados HTML brutos de páginas.'},
                {'name': 'TAIOSInputCapture', 'desc': 'Capturador de eventos de sistema do SO.', 'props': 'TrackMouse, TrackKeyboard, Active', 'methods': 'CaptureScreen', 'role': 'Screenshot do desktop e interceptar teclado/mouse para telemetria de atividade.'}
            ]
        },
        'en': {
            'desc': 'Advanced Input Devices, Sensors and Networks Capture.',
            'info': 'Maps and captures real-world data (keyboard, mouse, cameras, MQTT brokers, sockets) to feed cognitive models.',
            'comps': [
                {'name': 'TAIInputData', 'desc': 'Linear normalizer for numerical vectors.', 'props': 'MinRange, MaxRange', 'methods': 'Normalize, Denormalize', 'role': 'Scale raw telemetry data into compatible neural network ranges.'},
                {'name': 'TAICameraInput', 'desc': 'Native camera frame grabber.', 'props': 'DeviceIndex, Width, Height, Active', 'methods': 'StartCapture, StopCapture, CaptureFrame', 'role': 'Provide real-time camera visual streams for computer vision models.'},
                {'name': 'TAIAudioInput', 'desc': 'Audio recorder and wave mixer.', 'props': 'InputSource (Mic, Wave), BitRate', 'methods': 'StartRecord, StopRecord, MixAudio', 'role': 'Record ambient voice signals and mix WAV channels for transcribers.'},
                {'name': 'TAIWebAPIServer', 'desc': 'Embedded REST API HTTP server.', 'props': 'Port, Active, AllowedRoutes', 'methods': 'StartServer, StopServer', 'role': 'Expose HTTP REST endpoints for external system integrations.'},
                {'name': 'TAISocketTCP', 'desc': 'TCP Client/Server sockets.', 'props': 'Host, Port, Mode, Active', 'methods': 'Connect, Disconnect, SendText, ReceiveText', 'role': 'Establish stable low-level network communication streams.'},
                {'name': 'TAISocketUDP', 'desc': 'UDP connection socket.', 'props': 'Host, Port, Active', 'methods': 'SendText, ReceiveText', 'role': 'Transmit fast, asynchronous sensor telemetry logs.'},
                {'name': 'TAISerialModem', 'desc': 'Serial Port and GSM SMS Gateway.', 'props': 'DeviceName, BaudRate, Active', 'methods': 'OpenPort, SendATCommand, SendSMS', 'role': 'Send physical cellular SMS alerts and interface legacy hardware.'},
                {'name': 'TAIPOSPrinter', 'desc': 'Esc/POS thermal receipt printer.', 'props': 'DevicePath, Active', 'methods': 'PrintText, PrintBarcode', 'role': 'Print automated paper logs, barcodes and receipts.'},
                {'name': 'TAICFTVIP', 'desc': 'CFTV MJPEG IP camera connector.', 'props': 'IPAddress, Port, Active', 'methods': 'CaptureStreamFrame', 'role': 'Acquire video streams from standard security network IP cameras.'},
                {'name': 'TAIModbusClient', 'desc': 'Industrial Modbus RTU/TCP Client.', 'props': 'Host, Port, Mode, Active', 'methods': 'ReadHoldingRegisters, WriteRegister', 'role': 'Query physical registers from temperature and automated sensors.'},
                {'name': 'TAIMQTTClient', 'desc': 'IoT MQTT network client.', 'props': 'Host, Port, Active', 'methods': 'ConnectBroker, Publish, Subscribe', 'role': 'Publish JSON sensor data asynchronously to public/private brokers.'},
                {'name': 'TAIEmailClient', 'desc': 'Native SMTP/POP3 email client.', 'props': 'HostSMTP, PortSMTP, Username, Password', 'methods': 'SendEmail, FetchEmails', 'role': 'Retrieve inbox messages and dispatch email status notifications.'},
                {'name': 'TAIMessenger', 'desc': 'WhatsApp and SMS REST gateway.', 'props': 'SMSApiURL, WhatsAppApiURL, WhatsAppToken', 'methods': 'SendSMS, SendWhatsApp', 'role': 'Dispatch instant alerts directly to mobile devices.'},
                {'name': 'TAIIndustrialBridge', 'desc': 'CLP Profinet/Profibus bridge.', 'props': 'IPAddress, Rack, Slot, Active', 'methods': 'ConnectBridge, ReadBytes, WriteBytes', 'role': 'Interface and trigger controls on physical PLC industrial automation links.'},
                {'name': 'TAIChromiumBrowser', 'desc': 'Embedded Web Browser panel.', 'props': 'URL, ShowAddressBar', 'methods': 'Navigate, GoBack, Reload', 'role': 'Render web UIs and extract raw HTML content for web scraping.'},
                {'name': 'TAIOSInputCapture', 'desc': 'Global OS desktop event logger.', 'props': 'TrackMouse, TrackKeyboard, Active', 'methods': 'CaptureScreen', 'role': 'Capture screen screenshots and capture global keyboard/mouse deltas.'}
            ]
        },
        'es': {
            'desc': 'Captura Avanzada de Dispositivos de Entrada, Sensores y Redes.',
            'info': 'Mapea y captura datos del mundo real (teclado, mouse, cámaras, brokers MQTT, sockets) para alimentar modelos cognitivos.',
            'comps': [
                {'name': 'TAIInputData', 'desc': 'Normalizador lineal de vectores numéricos.', 'props': 'MinRange, MaxRange', 'methods': 'Normalize, Denormalize', 'role': 'Normalizar datos brutos para rangos tolerados por Redes Neuronales.'},
                {'name': 'TAICameraInput', 'desc': 'Capturador de fotogramas de cámara física nativa.', 'props': 'DeviceIndex, Width, Height, Active', 'methods': 'StartCapture, StopCapture, CaptureFrame', 'role': 'Proporcionar cuadros visuales en tiempo real para IA de visión computacional.'},
                {'name': 'TAIAudioInput', 'desc': 'Grabador y mezclador de audio.', 'props': 'InputSource (Mic, Wave), BitRate', 'methods': 'StartRecord, StopRecord, MixAudio', 'role': 'Grabar voces del ambiente y mezclar canales WAV para transcribidores.'},
                {'name': 'TAIWebAPIServer', 'desc': 'Servidor REST API incorporado.', 'props': 'Port, Active, AllowedRoutes', 'methods': 'StartServer, StopServer', 'role': 'Exponer un punto final HTTP REST para recibir datos de sistemas externos.'},
                {'name': 'TAISocketTCP', 'desc': 'Conector de Sockets TCP Cliente/Servidor.', 'props': 'Host, Port, Mode, Active', 'methods': 'Connect, Disconnect, SendText, ReceiveText', 'role': 'Establecer conexiones estables de flujo de red a bajo nivel.'},
                {'name': 'TAISocketUDP', 'desc': 'Conector rápido de Sockets UDP.', 'props': 'Host, Port, Active', 'methods': 'SendText, ReceiveText', 'role': 'Transmitir telemetría de sensores de forma rápida y asíncrona.'},
                {'name': 'TAISerialModem', 'desc': 'Puerto Serial y Gateway de SMS GSM.', 'props': 'DeviceName, BaudRate, Active', 'methods': 'OpenPort, SendATCommand, SendSMS', 'role': 'Enviar mensajes SMS físicos a través de módems celulares y microcontroladores.'},
                {'name': 'TAIPOSPrinter', 'desc': 'Impresora térmica de recibos Esc/POS.', 'props': 'DevicePath, Active', 'methods': 'PrintText, PrintBarcode', 'role': 'Imprimir registros de papel automáticos, códigos de barras y recibos.'},
                {'name': 'TAICFTVIP', 'desc': 'Conector de cámara IP MJPEG para CFTV.', 'props': 'IPAddress, Port, Active', 'methods': 'CaptureStreamFrame', 'role': 'Adquirir vídeo de cámaras de seguridad CFTV distribuidas en la red.'},
                {'name': 'TAIModbusClient', 'desc': 'Cliente Modbus industrial (TCP/RTU).', 'props': 'Host, Port, Mode, Active', 'methods': 'ReadHoldingRegisters, WriteRegister', 'role': 'Consultar registros físicos de sensores de temperatura y presión.'},
                {'name': 'TAIMQTTClient', 'desc': 'Cliente de red IoT MQTT.', 'props': 'Host, Port, Active', 'methods': 'ConnectBroker, Publish, Subscribe', 'role': 'Sincronizar telemetría IoT con brokers (ej. HiveMQ) de forma asíncrona.'},
                {'name': 'TAIEmailClient', 'desc': 'Cliente SMTP/POP3 nativo.', 'props': 'HostSMTP, PortSMTP, Username, Password', 'methods': 'SendEmail, FetchEmails', 'role': 'Recuperar mensajes de bandeja de entrada e iniciar notificaciones de estado.'},
                {'name': 'TAIMessenger', 'desc': 'Gateway WhatsApp y SMS via REST.', 'props': 'SMSApiURL, WhatsAppApiURL, WhatsAppToken', 'methods': 'SendSMS, SendWhatsApp', 'role': 'Despejar alertas instantáneas directamente a los teléfonos móviles de los operadores.'},
                {'name': 'TAIIndustrialBridge', 'desc': 'Puente Profinet/Profibus de PLC.', 'props': 'IPAddress, Rack, Slot, Active', 'methods': 'ConnectBridge, ReadBytes, WriteBytes', 'role': 'Interconectar y leer estados físicos de autómatas industriales.'},
                {'name': 'TAIChromiumBrowser', 'desc': 'Panel de Navegador Web incorporado.', 'props': 'URL, ShowAddressBar', 'methods': 'Navigate, GoBack, Reload', 'role': 'Renderizar interfaces web y extraer código HTML en bruto.'},
                {'name': 'TAIOSInputCapture', 'desc': 'Capturador de eventos de sistema del SO.', 'props': 'TrackMouse, TrackKeyboard, Active', 'methods': 'CaptureScreen', 'role': 'Tomar screenshots del escritorio y capturar pulsaciones de teclas globales.'}
            ]
        },
        'fr': {
            'desc': 'Capture Avancée de Périphériques d\'Entrée, de Capteurs et de Réseaux.',
            'info': 'Cartographie et capture les données du monde réel (clavier, souris, caméras, brokers MQTT, sockets) pour alimenter les modèles cognitifs.',
            'comps': [
                {'name': 'TAIInputData', 'desc': 'Normalisateur linéaire pour vecteurs numériques.', 'props': 'MinRange, MaxRange', 'methods': 'Normalize, Denormalize', 'role': 'Normaliser les données brutes dans des plages tolérées par les réseaux de neurones.'},
                {'name': 'TAICameraInput', 'desc': 'Captureur de flux de caméra physique native.', 'props': 'DeviceIndex, Width, Height, Active', 'methods': 'StartCapture, StopCapture, CaptureFrame', 'role': 'Fournir des flux visuels en temps réel pour l\'IA de vision.'},
                {'name': 'TAIAudioInput', 'desc': 'Enregistreur et mixeur audio.', 'props': 'InputSource (Mic, Wave), BitRate', 'methods': 'StartRecord, StopRecord, MixAudio', 'role': 'Enregistrer les signaux vocaux ambiants et mélanger les pistes WAV pour l\'IA.'},
                {'name': 'TAIWebAPIServer', 'desc': 'Serveur HTTP API REST embarqué.', 'props': 'Port, Active, AllowedRoutes', 'methods': 'StartServer, StopServer', 'role': 'Exposer des points de terminaison HTTP REST pour des systèmes externes.'},
                {'name': 'TAISocketTCP', 'desc': 'Connecteur Sockets TCP Client/Serveur.', 'props': 'Host, Port, Mode, Active', 'methods': 'Connect, Disconnect, SendText, ReceiveText', 'role': 'Établir des flux stables de communication réseau de bas niveau.'},
                {'name': 'TAISocketUDP', 'desc': 'Connecteur de Sockets UDP rapide.', 'props': 'Host, Port, Active', 'methods': 'SendText, ReceiveText', 'role': 'Transmettre la télémétrie asynchrone des capteurs.'},
                {'name': 'TAISerialModem', 'desc': 'Port Série et Passerelle SMS GSM.', 'props': 'DeviceName, BaudRate, Active', 'methods': 'OpenPort, SendATCommand, SendSMS', 'role': 'Envoyer des SMS et interfacer le matériel hérité via modems.'},
                {'name': 'TAIPOSPrinter', 'desc': 'Imprimante de reçus thermique Esc/POS.', 'props': 'DevicePath, Active', 'methods': 'PrintText, PrintBarcode', 'role': 'Imprimer des reçus, des codes-barres et des tickets.'},
                {'name': 'TAICFTVIP', 'desc': 'Connecteur caméra IP MJPEG pour CFTV.', 'props': 'IPAddress, Port, Active', 'methods': 'CaptureStreamFrame', 'role': 'Acquérir des flux vidéo de caméras IP de sécurité sur le réseau.'},
                {'name': 'TAIModbusClient', 'desc': 'Client Modbus industriel (TCP/RTU).', 'props': 'Host, Port, Mode, Active', 'methods': 'ReadHoldingRegisters, WriteRegister', 'role': 'Interroger des registres physiques de capteurs thermiques et pressions.'},
                {'name': 'TAIMQTTClient', 'desc': 'Client réseau IoT MQTT.', 'props': 'Host, Port, Active', 'methods': 'ConnectBroker, Publish, Subscribe', 'role': 'Synchroniser la télémétrie IoT avec des serveurs MQTT de façon asynchrone.'},
                {'name': 'TAIEmailClient', 'desc': 'Client SMTP/POP3 natif.', 'props': 'HostSMTP, PortSMTP, Username, Password', 'methods': 'SendEmail, FetchEmails', 'role': 'Récupérer des e-mails et envoyer des rapports d\'état.'},
                {'name': 'TAIMessenger', 'desc': 'Passerelle WhatsApp et SMS via REST.', 'props': 'SMSApiURL, WhatsAppApiURL, WhatsAppToken', 'methods': 'SendSMS, SendWhatsApp', 'role': 'Envoyer des alertes instantanées sur téléphones mobiles.'},
                {'name': 'TAIIndustrialBridge', 'desc': 'Pont Profinet/Profibus automate PLC.', 'props': 'IPAddress, Rack, Slot, Active', 'methods': 'ConnectBridge, ReadBytes, WriteBytes', 'role': 'Interfacer et déclencher des contrôles sur automates industriels.'},
                {'name': 'TAIChromiumBrowser', 'desc': 'Panneau de Navigateur Web intégré.', 'props': 'URL, ShowAddressBar', 'methods': 'Navigate, GoBack, Reload', 'role': 'Afficher des UIs web et extraire du contenu HTML brut.'},
                {'name': 'TAIOSInputCapture', 'desc': 'Enregistreur d\'événements globaux du système.', 'props': 'TrackMouse, TrackKeyboard, Active', 'methods': 'CaptureScreen', 'role': 'Capturer l\'écran entier et intercepter des touches claviers.'}
            ]
        },
        'it': {
            'desc': 'Acquisizione Avanzata di Dispositivi di Input, Sensori e Reti.',
            'info': 'Mappa e acquisisce dati del mondo reale (tastiera, mouse, telecamere, broker MQTT, socket) per alimentare i modelli cognitivi.',
            'comps': [
                {'name': 'TAIInputData', 'desc': 'Normalizzatore lineare per vettori numerici.', 'props': 'MinRange, MaxRange', 'methods': 'Normalize, Denormalize', 'role': 'Normalizzare dati grezzi per range tollerati dalle Reti Neurali.'},
                {'name': 'TAICameraInput', 'desc': 'Acquisitore di fotogrammi da telecamera fisica.', 'props': 'DeviceIndex, Width, Height, Active', 'methods': 'StartCapture, StopCapture, CaptureFrame', 'role': 'Fornire fotogrammi video in tempo reale all\'IA di visione.'},
                {'name': 'TAIAudioInput', 'desc': 'Registratore e mixer audio.', 'props': 'InputSource (Mic, Wave), BitRate', 'methods': 'StartRecord, StopRecord, MixAudio', 'role': 'Registrare la voce e mixare canali WAV per elaborazioni neurali.'},
                {'name': 'TAIWebAPIServer', 'desc': 'Server HTTP API REST incorporato.', 'props': 'Port, Active, AllowedRoutes', 'methods': 'StartServer, StopServer', 'role': 'Esporre un endpoint HTTP REST per ricevere chiamate esterne.'},
                {'name': 'TAISocketTCP', 'desc': 'Connettore Sockets TCP Client/Server.', 'props': 'Host, Port, Mode, Active', 'methods': 'Connect, Disconnect, SendText, ReceiveText', 'role': 'Stabilire flussi di rete stabili a basso livello.'},
                {'name': 'TAISocketUDP', 'desc': 'Connettore di Sockets UDP veloce.', 'props': 'Host, Port, Active', 'methods': 'SendText, ReceiveText', 'role': 'Trasmettere telemetria asincrona e rapida da sensori.'},
                {'name': 'TAISerialModem', 'desc': 'Porta Seriale e Gateway SMS GSM.', 'props': 'DeviceName, BaudRate, Active', 'methods': 'OpenPort, SendATCommand, SendSMS', 'role': 'Inviare messaggi SMS ed effettuare connessioni a microcontrollori.'},
                {'name': 'TAIPOSPrinter', 'desc': 'Stampante termica per ricevute Esc/POS.', 'props': 'DevicePath, Active', 'methods': 'PrintText, PrintBarcode', 'role': 'Stampare report cartacei, codici a barre e ricevute.'},
                {'name': 'TAICFTVIP', 'desc': 'Connettore telecamera IP MJPEG per CFTV.', 'props': 'IPAddress, Port, Active', 'methods': 'CaptureStreamFrame', 'role': 'Acquisire video in rete da telecamere di sicurezza IP.'},
                {'name': 'TAIModbusClient', 'desc': 'Client Modbus industriale (TCP/RTU).', 'props': 'Host, Port, Mode, Active', 'methods': 'ReadHoldingRegisters, WriteRegister', 'role': 'Interrogare registri di sensori fisici di temperatura e pressione.'},
                {'name': 'TAIMQTTClient', 'desc': 'Client di rete IoT MQTT.', 'props': 'Host, Port, Active', 'methods': 'ConnectBroker, Publish, Subscribe', 'role': 'Sincronizzare dati sensoriali con server MQTT in background.'},
                {'name': 'TAIEmailClient', 'desc': 'Client SMTP/POP3 nativo.', 'props': 'HostSMTP, PortSMTP, Username, Password', 'methods': 'SendEmail, FetchEmails', 'role': 'Recuperare messaggi di posta in arrivo e inviare notifiche.'},
                {'name': 'TAIMessenger', 'desc': 'Gateway WhatsApp e SMS via REST.', 'props': 'SMSApiURL, WhatsAppApiURL, WhatsAppToken', 'methods': 'SendSMS, SendWhatsApp', 'role': 'Inviare notifiche push istantanee su dispositivi mobili.'},
                {'name': 'TAIIndustrialBridge', 'desc': 'Ponte Profinet/Profibus per PLC.', 'props': 'IPAddress, Rack, Slot, Active', 'methods': 'ConnectBridge, ReadBytes, WriteBytes', 'role': 'Controllare e leggere stati da controllori PLC industriali.'},
                {'name': 'TAIChromiumBrowser', 'desc': 'Pannello Browser Web integrato.', 'props': 'URL, ShowAddressBar', 'methods': 'Navigate, GoBack, Reload', 'role': 'Visualizzare pagine web ed estrarre il codice sorgente HTML.'},
                {'name': 'TAIOSInputCapture', 'desc': 'Acquisitore di eventi globale del sistema operativo.', 'props': 'TrackMouse, TrackKeyboard, Active', 'methods': 'CaptureScreen', 'role': 'Catturare screenshot dello schermo e loggare tasti globali.'}
            ]
        },
        'ar': {
            'desc': 'التقاط متقدم لأجهزة الإدخال، وأجهزة الاستشعار، والشبكات.',
            'info': 'يرسم خرائط البيانات من العالم الحقيقي (لوحة المفاتيح، الماوس، الكاميرات، موصلات MQTT، السوكيت) ويلتقطها لتغذية النماذج المعرفية.',
            'comps': [
                {'name': 'TAIInputData', 'desc': 'مُهيئ ومُعادل خطي للمتجهات الرقمية.', 'props': 'MinRange, MaxRange', 'methods': 'Normalize, Denormalize', 'role': 'تحجيم بيانات القياس الخام إلى نطاقات متوافقة للشبكات العصبية.'},
                {'name': 'TAICameraInput', 'desc': 'ملتقط إطارات الكاميرات المادية الأصلية.', 'props': 'DeviceIndex, Width, Height, Active', 'methods': 'StartCapture, StopCapture, CaptureFrame', 'role': 'توفير تدفقات الفيديو من الكاميرا في الوقت الحقيقي لنماذج الرؤية الحاسوبية.'},
                {'name': 'TAIAudioInput', 'desc': 'مسجل وخلاط إشارات الصوت الرقمية.', 'props': 'InputSource (Mic, Wave), BitRate', 'methods': 'StartRecord, StopRecord, MixAudio', 'role': 'تسجيل إشارات الصوت وتجميع قنوات WAV لنماذج نسخ النصوص.'},
                {'name': 'TAIWebAPIServer', 'desc': 'خادم HTTP REST API مدمج.', 'props': 'Port, Active, AllowedRoutes', 'methods': 'StartServer, StopServer', 'role': 'توفير واجهة برمجية HTTP REST لاستلام البيانات من الأنظمة الخارجية.'},
                {'name': 'TAISocketTCP', 'desc': 'مقبس اتصالات TCP للعميل والخادم.', 'props': 'Host, Port, Mode, Active', 'methods': 'Connect, Disconnect, SendText, ReceiveText', 'role': 'إنشاء تدفقات اتصالات مستقرة منخفضة المستوى للشبكة.'},
                {'name': 'TAISocketUDP', 'desc': 'مقبس اتصال UDP سريع.', 'props': 'Host, Port, Active', 'methods': 'SendText, ReceiveText', 'role': 'إرسال ونقل بيانات حساسات القياس بسرعة كبيرة وبشكل غير متزامن.'},
                {'name': 'TAISerialModem', 'desc': 'منفذ تسلسلي وجسر إرسال SMS الخلوي.', 'props': 'DeviceName, BaudRate, Active', 'methods': 'OpenPort, SendATCommand, SendSMS', 'role': 'إرسال تنبيهات SMS مادية والتفاعل مع الأجهزة والشرائح الدقيقة.'},
                {'name': 'TAIPOSPrinter', 'desc': 'طابعة إيصالات حرارية متوافقة مع Esc/POS.', 'props': 'DevicePath, Active', 'methods': 'PrintText, PrintBarcode', 'role': 'طباعة سجلات الورق التلقائية والرموز الشريطية والإيصالات.'},
                {'name': 'TAICFTVIP', 'desc': 'موصل كاميرات IP للمراقبة بشبكة MJPEG.', 'props': 'IPAddress, Port, Active', 'methods': 'CaptureStreamFrame', 'role': 'الحصول على تدفقات الفيديو من كاميرات الأمان الشبكية القياسية.'},
                {'name': 'TAIModbusClient', 'desc': 'عميل Modbus الصناعي (TCP/RTU).', 'props': 'Host, Port, Mode, Active', 'methods': 'ReadHoldingRegisters, WriteRegister', 'role': 'الاستعلام عن البيانات الحقيقية من حساسات درجات الحرارة والضغط الصناعية.'},
                {'name': 'TAIMQTTClient', 'desc': 'عميل شبكة اتصالات إنترنت الأشياء MQTT.', 'props': 'Host, Port, Active', 'methods': 'ConnectBroker, Publish, Subscribe', 'role': 'نشر بيانات الحساسات بصيغة JSON بشكل غير متزامن لخواديم MQTT العامة.'},
                {'name': 'TAIEmailClient', 'desc': 'عميل بريد إلكتروني SMTP/POP3 أصلي.', 'props': 'HostSMTP, PortSMTP, Username, Password', 'methods': 'SendEmail, FetchEmails', 'role': 'استرداد وقراءة الرسائل الواردة وإرسال إشعارات البريد الإلكتروني.'},
                {'name': 'TAIMessenger', 'desc': 'بوابة إرسال واتساب وSMS عبر REST.', 'props': 'SMSApiURL, WhatsAppApiURL, WhatsAppToken', 'methods': 'SendSMS, SendWhatsApp', 'role': 'إرسال رسائل وتنبيهات فورية مباشرة لهواتف المشغلين والمهندسين.'},
                {'name': 'TAIIndustrialBridge', 'desc': 'جسر اتصالات Profinet/Profibus للمتحكمات CLPs.', 'props': 'IPAddress, Rack, Slot, Active', 'methods': 'ConnectBridge, ReadBytes, WriteBytes', 'role': 'التفاعل وإصدار أوامر التحكم على روابط التشغيل الآلي للمصانع.'},
                {'name': 'TAIChromiumBrowser', 'desc': 'لوحة متصفح ويب مدمجة.', 'props': 'URL, ShowAddressBar', 'methods': 'Navigate, GoBack, Reload', 'role': 'عرض واجهات المستخدم على الويب واستخلاص نصوص HTML البرمجية.'},
                {'name': 'TAIOSInputCapture', 'desc': 'ملتقط أحداث سطح مكتب نظام التشغيل العام.', 'props': 'TrackMouse, TrackKeyboard, Active', 'methods': 'CaptureScreen', 'role': 'التقاط صور كاملة لسطح المكتب واعتراض مدخلات لوحة المفاتيح.'}
            ]
        }
    },
    'IA Output': {
        'icon': '📄',
        'pt': {
            'desc': 'Saída Estruturada de Resultados, Decisões e Geração de Documentos.',
            'info': 'Gera relatórios nativos elegantes de IA em múltiplos formatos (.pdf, .docx, .xlsx, .txt) sem requisições externas.',
            'comps': [
                {'name': 'TAIOutputData', 'desc': 'Decisor e ativador SoftMax.', 'props': 'Classes, Probabilities', 'methods': 'SoftMax, GetBestClassIndex, GetBestClassName', 'role': 'Determinar a classe mais provável de saída e formatar resultados analíticos.'},
                {'name': 'TAIPDFOutput', 'desc': 'Gerador de documentos PDF nativo.', 'props': 'FileName, Title, Author', 'methods': 'StartDocument, AddPage, AddText, SavePDF', 'role': 'Gerar relatórios formais e certificados em PDF prontos para impressão.'},
                {'name': 'TAIWordOutput', 'desc': 'Gerador de relatórios Word (.docx) nativo.', 'props': 'FileName, Title', 'methods': 'AddHeading, AddParagraph, AddTable, SaveWord', 'role': 'Exportar resumos textuais e tabelas estruturadas compatíveis com Office/LibreOffice.'},
                {'name': 'TAIExcelOutput', 'desc': 'Gerador de planilhas Excel (.xlsx) nativo.', 'props': 'FileName', 'methods': 'SetCell, SaveExcel', 'role': 'Exportar dados tabulares densos, métricas estatísticas e históricos de predição.'},
                {'name': 'TAITXTOutput', 'desc': 'Exportador de texto tabulado ASCII puro.', 'props': 'FileName', 'methods': 'AddLine, AddHeader, SaveText', 'role': 'Gerar resumos leves em texto plano para logs rápidos ou envio por SMS.'},
                {'name': 'TAIOutputDocs', 'desc': 'Suite unificada de saída de relatórios.', 'props': 'Title, Author, Subject', 'methods': 'AddParagraph, AddTable, SaveAll', 'role': 'Gerar todos os 4 formatos de documentos anteriores em uma única chamada de pipeline.'}
            ]
        },
        'en': {
            'desc': 'Structured Output, Decision Processing and Document Generation.',
            'info': 'Generates elegant native AI reports in multiple formats (.pdf, .docx, .xlsx, .txt) without external dependencies.',
            'comps': [
                {'name': 'TAIOutputData', 'desc': 'Decision maker and SoftMax activator.', 'props': 'Classes, Probabilities', 'methods': 'SoftMax, GetBestClassIndex, GetBestClassName', 'role': 'Determine the highest probability prediction and format structural classification results.'},
                {'name': 'TAIPDFOutput', 'desc': 'Native PDF document generator.', 'props': 'FileName, Title, Author', 'methods': 'StartDocument, AddPage, AddText, SavePDF', 'role': 'Generate formal reports and printable PDF documents.'},
                {'name': 'TAIWordOutput', 'desc': 'Native Word (.docx) report generator.', 'props': 'FileName, Title', 'methods': 'AddHeading, AddParagraph, AddTable, SaveWord', 'role': 'Export text-rich summaries and tables fully compatible with MS Word.'},
                {'name': 'TAIExcelOutput', 'desc': 'Native Excel (.xlsx) spreadsheet generator.', 'props': 'FileName', 'methods': 'SetCell, SaveExcel', 'role': 'Export tabular predictive data, statistics and metrics.'},
                {'name': 'TAITXTOutput', 'desc': 'Plain ASCII text formatter.', 'props': 'FileName', 'methods': 'AddLine, AddHeader, SaveText', 'role': 'Generate light plain-text file logs.'},
                {'name': 'TAIOutputDocs', 'desc': 'Unified document exporter.', 'props': 'Title, Author, Subject', 'methods': 'AddParagraph, AddTable, SaveAll', 'role': 'Generate all four document formats simultaneously in a single pipeline stream.'}
            ]
        },
        'es': {
            'desc': 'Salida Estructurada de Resultados, Decisiones y Generación de Documentos.',
            'info': 'Genera informes nativos elegantes de IA en múltiples formatos (.pdf, .docx, .xlsx, .txt) sin requisitos externos.',
            'comps': [
                {'name': 'TAIOutputData', 'desc': 'Procesador de decisiones y SoftMax.', 'props': 'Classes, Probabilities', 'methods': 'SoftMax, GetBestClassIndex, GetBestClassName', 'role': 'Determinar la predicción de mayor probabilidad y formatear resultados estructurales.'},
                {'name': 'TAIPDFOutput', 'desc': 'Generador de documentos PDF nativo.', 'props': 'FileName, Title, Author', 'methods': 'StartDocument, AddPage, AddText, SavePDF', 'role': 'Generar informes formales y documentos PDF listos para imprimir.'},
                {'name': 'TAIWordOutput', 'desc': 'Generador de informes Word (.docx) nativo.', 'props': 'FileName, Title', 'methods': 'AddHeading, AddParagraph, AddTable, SaveWord', 'role': 'Exportar resúmenes de texto densos y tablas estructuradas compatibles con Word/LibreOffice.'},
                {'name': 'TAIExcelOutput', 'desc': 'Generador de hojas de cálculo Excel (.xlsx) nativo.', 'props': 'FileName', 'methods': 'SetCell, SaveExcel', 'role': 'Exportar datos tabulares densos y métricas de rendimiento estadístico.'},
                {'name': 'TAITXTOutput', 'desc': 'Formateador de texto plano ASCII puro.', 'props': 'FileName', 'methods': 'AddLine, AddHeader, SaveText', 'role': 'Generar registros de texto plano rápidos y livianos.'},
                {'name': 'TAIOutputDocs', 'desc': 'Suite unificada de salida de informes.', 'props': 'Title, Author, Subject', 'methods': 'AddParagraph, AddTable, SaveAll', 'role': 'Generar todos los 4 formatos de documentos anteriores en una sola llamada de pipeline.'}
            ]
        },
        'fr': {
            'desc': 'Sortie Structurée de Résultats, Traitement Décisionnel et Génération de Documents.',
            'info': 'Génère d\'élégants rapports d\'IA natifs dans plusieurs formats (.pdf, .docx, .xlsx, .txt) sans dépendances externes.',
            'comps': [
                {'name': 'TAIOutputData', 'desc': 'Processeur de décision et activation SoftMax.', 'props': 'Classes, Probabilities', 'methods': 'SoftMax, GetBestClassIndex, GetBestClassName', 'role': 'Déterminer la prédiction la plus probable et formater les résultats analytiques.'},
                {'name': 'TAIPDFOutput', 'desc': 'Générateur de documents PDF natif.', 'props': 'FileName, Title, Author', 'methods': 'StartDocument, AddPage, AddText, SavePDF', 'role': 'Générer des rapports formels et des documents PDF imprimables.'},
                {'name': 'TAIWordOutput', 'desc': 'Générateur de rapports Word (.docx) natif.', 'props': 'FileName, Title', 'methods': 'AddHeading, AddParagraph, AddTable, SaveWord', 'role': 'Exporter des résumés textuels et des tableaux structurés compatibles MS Word.'},
                {'name': 'TAIExcelOutput', 'desc': 'Générateur de feuilles de calcul Excel (.xlsx) natif.', 'props': 'FileName', 'methods': 'SetCell, SaveExcel', 'role': 'Exporter des données tabulaires denses, des statistiques et métriques.'},
                {'name': 'TAITXTOutput', 'desc': 'Formateur de texte ASCII brut.', 'props': 'FileName', 'methods': 'AddLine, AddHeader, SaveText', 'role': 'Générer des résumés légers en texte brut pour les fichiers de log.'},
                {'name': 'TAIOutputDocs', 'desc': 'Suite de sortie de documents unifiée.', 'props': 'Title, Author, Subject', 'methods': 'AddParagraph, AddTable, SaveAll', 'role': 'Générer les quatre formats de documents simultanément dans un seul flux de pipeline.'}
            ]
        },
        'it': {
            'desc': 'Uscita Strutturata dei Risultati, Elaborazione Decisionale e Generazione di Documenti.',
            'info': 'Genera eleganti report nativi IA in molteplici formati (.pdf, .docx, .xlsx, .txt) senza dipendenze esterne.',
            'comps': [
                {'name': 'TAIOutputData', 'desc': 'Elaboratore decisionale e attivatore SoftMax.', 'props': 'Classes, Probabilities', 'methods': 'SoftMax, GetBestClassIndex, GetBestClassName', 'role': 'Determinare la previsione più probabile e formattare i risultati analitici.'},
                {'name': 'TAIPDFOutput', 'desc': 'Generatore di documenti PDF nativo.', 'props': 'FileName, Title, Author', 'methods': 'StartDocument, AddPage, AddText, SavePDF', 'role': 'Generare report formali e documenti PDF stampabili.'},
                {'name': 'TAIWordOutput', 'desc': 'Generatore di report Word (.docx) nativo.', 'props': 'FileName, Title', 'methods': 'AddHeading, AddParagraph, AddTable, SaveWord', 'role': 'Esportare riepiloghi testuali e tabelle compatibili con Microsoft Word.'},
                {'name': 'TAIExcelOutput', 'desc': 'Generatore di fogli di calcolo Excel (.xlsx) nativo.', 'props': 'FileName', 'methods': 'SetCell, SaveExcel', 'role': 'Esportare dati tabulari predittivi, statistiche e metriche di accuratezza.'},
                {'name': 'TAITXTOutput', 'desc': 'Formattatore di testo ASCII grezzo.', 'props': 'FileName', 'methods': 'AddLine, AddHeader, SaveText', 'role': 'Generare file di testo piano leggeri per i log operativi.'},
                {'name': 'TAIOutputDocs', 'desc': 'Suite di output documentale unificata.', 'props': 'Title, Author, Subject', 'methods': 'AddParagraph, AddTable, SaveAll', 'role': 'Generare tutti e quattro i formati di documento contemporaneamente con un unico comando.'}
            ]
        },
        'ar': {
            'desc': 'المخرجات المهيكلة، معالجة القرارات وإنشاء المستندات والتقارير.',
            'info': 'ينشئ تقارير ذكاء اصطناعي أنيقة أصلية بتنسيقات متعددة (.pdf، .docx، .xlsx، .txt) دون متطلبات خارجية.',
            'comps': [
                {'name': 'TAIOutputData', 'desc': 'معالج القرارات ومنشط دالة SoftMax.', 'props': 'Classes, Probabilities', 'methods': 'SoftMax, GetBestClassIndex, GetBestClassName', 'role': 'تحديد الفئة الأكثر احتمالاً للتنبؤ وصياغة النتائج التحليلية.'},
                {'name': 'TAIPDFOutput', 'desc': 'منشئ مستندات PDF الأصلي.', 'props': 'FileName, Title, Author', 'methods': 'StartDocument, AddPage, AddText, SavePDF', 'role': 'توليد تقارير رسمية وشهادات مطبوعة بصيغة PDF.'},
                {'name': 'TAIWordOutput', 'desc': 'منشئ تقارير Word (.docx) الأصلي.', 'props': 'FileName, Title', 'methods': 'AddHeading, AddParagraph, AddTable, SaveWord', 'role': 'تصدير ملخصات نصية وجداول هيكلية متوافقة مع برامج الأوفيس.'},
                {'name': 'TAIExcelOutput', 'desc': 'منشئ جداول بيانات Excel (.xlsx) الأصلي.', 'props': 'FileName', 'methods': 'SetCell, SaveExcel', 'role': 'تصدير بيانات التنبؤات والتحليلات الإحصائية.'},
                {'name': 'TAITXTOutput', 'desc': 'مقسم وصانع النصوص البسيطة ASCII.', 'props': 'FileName', 'methods': 'AddLine, AddHeader, SaveText', 'role': 'إنشاء ملفات نصوص بسيطة خفيفة الحجم لعمليات تسجيل السجلات.'},
                {'name': 'TAIOutputDocs', 'desc': 'المجموعة الموحدة لتصدير التقارير.', 'props': 'Title, Author, Subject', 'methods': 'AddParagraph, AddTable, SaveAll', 'role': 'إنشاء جميع مستندات التقارير الأربعة السابقة معًا في وقت واحد.'}
            ]
        }
    },
    'IA Schedulle': {
        'icon': '📅',
        'pt': {
            'desc': 'Agendamento Automatizado e Linha de Tempo Neural.',
            'info': 'Componentes para gerenciamento inteligente de tarefas periódicas baseadas em tempo cron e relógios.',
            'comps': [
                {'name': 'TIASchedule', 'desc': 'Agendador de cronogramas.', 'props': 'CronExpression, MaxIterations', 'methods': 'ScheduleTask, CancelTask', 'role': 'Gerenciar gatilhos de tempo para atividades do agente IA.'}
            ]
        },
        'en': {
            'desc': 'Automated Scheduling and Neural Timeline.',
            'info': 'Components for intelligent cron-based periodic task management and timers.',
            'comps': [
                {'name': 'TIASchedule', 'desc': 'Chronogram scheduler and manager.', 'props': 'CronExpression, MaxIterations', 'methods': 'ScheduleTask, CancelTask', 'role': 'Manage background execution timers and triggers for the AI agent.'}
            ]
        },
        'es': {
            'desc': 'Programación Automatizada y Línea de Tiempo Neural.',
            'info': 'Componentes para la gestión inteligente de tareas periódicas basadas en cronómetros y expresiones cron.',
            'comps': [
                {'name': 'TIASchedule', 'desc': 'Programador de cronogramas.', 'props': 'CronExpression, MaxIterations', 'methods': 'ScheduleTask, CancelTask', 'role': 'Gestionar activadores de tiempo para las tareas del agente de IA.'}
            ]
        },
        'fr': {
            'desc': 'Planification Automatique et Ligne Temporelle Neuronale.',
            'info': 'Composants pour la gestion intelligente des tâches périodiques basées sur des expressions cron.',
            'comps': [
                {'name': 'TIASchedule', 'desc': 'Planificateur de tâches.', 'props': 'CronExpression, MaxIterations', 'methods': 'ScheduleTask, CancelTask', 'role': 'Gérer les déclencheurs temporels pour les activités de l\'agent d\'IA.'}
            ]
        },
        'it': {
            'desc': 'Pianificazione Automatica e Linea Temporale Neurale.',
            'info': 'Componenti per la gestione intelligente delle attività periodiche basate su espressioni cron.',
            'comps': [
                {'name': 'TIASchedule', 'desc': 'Pianificatore di compiti e cronoprogrammi.', 'props': 'CronExpression, MaxIterations', 'methods': 'ScheduleTask, CancelTask', 'role': 'Gestire attivatori temporali per le attività del cervello dell\'IA.'}
            ]
        },
        'ar': {
            'desc': 'الجدولة التلقائية والمخطط الزمني العصبي.',
            'info': 'مكونات لإدارة المهام الدورية الذكية المستندة إلى جداول زمنية وتعبيرات cron.',
            'comps': [
                {'name': 'TIASchedule', 'desc': 'مجدول المهام والمخططات الزمنية.', 'props': 'CronExpression, MaxIterations', 'methods': 'ScheduleTask, CancelTask', 'role': 'إدارة مشغلات الوقت وجداول التنفيذ لوكيل الذكاء الاصطناعي.'}
            ]
        }
    },
    'IA Voice': {
        'icon': '🗣️',
        'pt': {
            'desc': 'Síntese de Voz e Sinais Vocais.',
            'info': 'Motores nativos para conversão de texto para voz (TTS) em múltiplos timbres de Pascal.',
            'comps': [
                {'name': 'TAIVoiceSynthesizer', 'desc': 'Sintetizador de voz.', 'props': 'Pitch, Rate, Volume', 'methods': 'Speak(const AText: string): Boolean', 'role': 'Sintetizar fala natural a partir de relatórios produzidos pelo agente IA.'}
            ]
        },
        'en': {
            'desc': 'Voice Synthesis and Speech Signal Engine.',
            'info': 'Native engines for text-to-speech (TTS) conversion in multiple Pascal voice timbres.',
            'comps': [
                {'name': 'TAIVoiceSynthesizer', 'desc': 'Speech and voice synthesizer.', 'props': 'Pitch, Rate, Volume', 'methods': 'Speak(const AText: string): Boolean', 'role': 'Synthesize natural-sounding speech from summaries generated by the AI.'}
            ]
        },
        'es': {
            'desc': 'Síntesis de Voz y Señales Vocales.',
            'info': 'Motores nativos para la conversión de texto a voz (TTS) en múltiples timbres en Pascal.',
            'comps': [
                {'name': 'TAIVoiceSynthesizer', 'desc': 'Sintetizador de voz.', 'props': 'Pitch, Rate, Volume', 'methods': 'Speak(const AText: string): Boolean', 'role': 'Sintetizar el habla natural a partir de los informes de análisis generados por la IA.'}
            ]
        },
        'fr': {
            'desc': 'Synthèse Vocale et Traitement des Signaux de Parole.',
            'info': 'Moteurs natifs pour la conversion de texte en parole (TTS) dans plusieurs timbres vocaux.',
            'comps': [
                {'name': 'TAIVoiceSynthesizer', 'desc': 'Synthétiseur de voix et de parole.', 'props': 'Pitch, Rate, Volume', 'methods': 'Speak(const AText: string): Boolean', 'role': 'Synthétiser une parole naturelle à partir de rapports d\'analyse de l\'IA.'}
            ]
        },
        'it': {
            'desc': 'Sintesi Vocale ed Elaborazione dei Segnali Vocali.',
            'info': 'Motori nativi per la conversione di testo in voce (TTS) in molteplici timbri vocali.',
            'comps': [
                {'name': 'TAIVoiceSynthesizer', 'desc': 'Sintetizzatore vocale nativo.', 'props': 'Pitch, Rate, Volume', 'methods': 'Speak(const AText: string): Boolean', 'role': 'Sintetizzare voce naturale da testi analitici prodotti dall\'agente IA.'}
            ]
        },
        'ar': {
            'desc': 'تخليق الصوت وتحويل النصوص إلى كلام منطوق.',
            'info': 'محركات أصلية لتحويل النصوص إلى كلام منطوق (TTS) بنبرات صوتية متعددة.',
            'comps': [
                {'name': 'TAIVoiceSynthesizer', 'desc': 'مخلق الصوت والنصوص المنطوقة.', 'props': 'Pitch, Rate, Volume', 'methods': 'Speak(const AText: string): Boolean', 'role': 'تخليق كلام منطوق طبيعي من نصوص التحليلات المنتجة بواسطة الوكيل.'}
            ]
        }
    }
}

lazarus_example = """
```pascal
var
  MyComponent: {classname};
begin
  MyComponent := {classname}.Create(Self);
  try
    // Configuration properties
    // MyComponent.Property := Value;
    
    // Execute call
    // MyComponent.ExecuteMethod;
  finally
    MyComponent.Free;
  end;
end;
```
"""

def generate():
    package_root = r"D:\projetos\maurinsoft\CHATGPT\pacote"
    for folder, data in tab_data.items():
        folder_path = os.path.join(package_root, folder)
        if not os.path.exists(folder_path):
            os.makedirs(folder_path)
            
        for lang_code, lang_trans in langs.items():
            lang_data = data[lang_code]
            filename = f"README.{lang_code}.md"
            filepath = os.path.join(folder_path, filename)
            
            # Build markdown content
            content = []
            content.append(f"# {data['icon']} {lang_trans['title'].format(folder)}")
            content.append("")
            content.append(f"> [!NOTE]")
            content.append(f"> {lang_trans['intro'].format(folder)}")
            content.append("")
            content.append(f"## {lang_data['desc']}")
            content.append(f"{lang_data['info']}")
            content.append("")
            content.append(f"### {lang_trans['details']}")
            content.append("")
            
            # Components table
            content.append(f"| {lang_trans['comp']} | {lang_trans['desc']} | {lang_trans['props']} | {lang_trans['methods']} | {lang_trans['role']} |")
            content.append("|---|---|---|---|---|")
            for c in lang_data['comps']:
                content.append(f"| **{c['name']}** | {c['desc']} | `{c['props']}` | `{c['methods']}` | {c['role']} |")
            content.append("")
            
            # Lazarus Code Example
            first_classname = lang_data['comps'][0]['name']
            content.append(f"### 💻 {lang_trans['example']} ({first_classname})")
            ex_code = lazarus_example.replace("{classname}", first_classname)
            content.append(ex_code)
            content.append("")
            
            # Unified Bridge mention
            content.append(f"### ⚡ {lang_trans['unified']}")
            if lang_code == 'pt':
                content.append("Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!")
            elif lang_code == 'en':
                content.append("Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!")
            elif lang_code == 'es':
                content.append("Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.")
            elif lang_code == 'fr':
                content.append("Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.")
            elif lang_code == 'it':
                content.append("Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.")
            elif lang_code == 'ar':
                content.append("يتميز كل مكون من هذه المكونات بخاصية نشر `Prompt` والتي توثق بشكل شفاف واجهتها البرمجية لتوجيه وكلاء الذكاء الاصطناعي (`TAIAgent`) ذاتياً!")
                
            content.append("")
            
            # Save file
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write("\n".join(content))
                
            print(f"Generated: {filepath}")

if __name__ == '__main__':
    generate()
