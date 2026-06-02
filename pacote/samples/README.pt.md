# 📂 Projetos de Demonstração (Samples)

> [!NOTE]
> Este diretório contém a suíte completa de exemplos desenvolvidos para demonstrar e testar todos os componentes de Inteligência Artificial, Aprendizado de Máquina (Machine Learning), Processamento de Imagens, Processamento de Sinais (DSP), Automação de Hardware e Geração de Documentos do pacote **openai.lpk**.

## 🖥️ Demonstrações em Interface Gráfica (GUI)
Os exemplos a seguir são projetos visuais prontos para compilação e execução interativa através do Lazarus:

| Exemplo | O que faz | Componentes | Como funciona |
|---|---|---|---|
| **[visual_demo/](visual_demo/)** | Central de controle unificada contendo abas de testes funcionais. | `TCHATGPT, TNeuralNetwork, TAICodeAssistant, TAIDatasetGenerator` | Interface aba por aba permitindo fazer perguntas às IAs, auditar códigos, exportar datasets e rodar treinamento local XOR. |
| **[voicesynthesizer_demo/](voicesynthesizer_demo/)** | Painel de controle de sintetização de voz (Text-to-Speech). | `TAIVoiceSynthesizer` | Permite alternar entre SAPI (Windows) e eSpeak (Linux), listando vozes instaladas com ajuste de volume, velocidade e suporte assíncrono. |
| **[yolo_demo/](yolo_demo/)** | Detecção profunda de objetos com modelo YOLOv8. | `TYOLO, TPythonConnector` | Instala silenciosamente dependências pip, executa detecção local (yolov8n.pt) e plota contornos em canvas Pascal. |
| **[cnn_demo/](cnn_demo/)** | Classificação de imagens profunda usando redes neurais convolucionais (CNN). | `TCNNClassifier, TPythonConnector` | Carrega a MobileNetV2 via TensorFlow no interpretador Python, classifica imagem local e retorna classe com confiança. |
| **[lstm_demo/](lstm_demo/)** | Previsão sequencial de tendências e dados temporais de forma gráfica. | `TLSTMPredictor, TPythonConnector` | Treina uma rede LSTM localmente em dados senoidais e projeta graficamente as previsões futuras. |
| **[face_detection_demo/](face_detection_demo/)** | Identificação facial em tempo real. | `TFaceDetection, TPythonConnector` | Acessa OpenCV via Python para rodar Haar Cascades e plotar retângulos delimitadores vermelhos ao redor de faces em tempo real. |
| **[python_demo/](python_demo/)** | Console e playground interativo integrado para o interpretador Python. | `TPythonConnector` | Escreva scripts, configure/leia variáveis globais dinamicamente e avalie equações complexas via Eval. |
| **[neural_network_demo/](neural_network_demo/)** | Playground local de redes neurais artificiais multicamadas (MLP). | `TNeuralNetwork` | Treina rede em Pascal puro na lógica XOR, exibe perda MSE e salva/restaura pesos em arquivos texto. |
| **[perceptron_demo/](perceptron_demo/)** | Treinador de portas lógicas (AND, OR, NAND, NOR). | `TPerceptron` | Algoritmo em Pascal puro que atualiza pesos e bias via regra delta, visualizando a convergência do erro. |
| **[som_demo/](som_demo/)** | Agrupamento topológico visual de cores em grade bidimensional. | `TSOMMap` | Organiza vetores RGB tridimensionais em degradês e agrupamentos de vizinhança topológica em Pascal puro. |
| **[tokenizer_demo/](tokenizer_demo/)** | Segmentação analítica e tokenização de strings. | `TTokenList` | Quebra frases em palavras por frequência, indexando termos para buscas com exportação JSON. |
| **[image_filters_demo/](image_filters_demo/)** | Processamento matricial de imagens interativo. | `Filtros da aba IA Image (TAIImageFilters)` | Aplica kernels convolucionais, binarizações e detecções de borda nativamente em canvas Pascal. |
| **[sound_filters_demo/](sound_filters_demo/)** | Processamento digital de sinais (DSP) e modulações de frequências. | `Filtros da aba IA Filtros Sonoros (TAISoundFilters)` | Simula filtros passa-baixas/altas, multiplexações FDM, TDM, CDM e OFDM ortogonal. |
| **[schedule_demo/](schedule_demo/)** | Gerenciador cronológico e encadeamento de cronogramas. | `TIASchedule` | Resolução de árvore de dependências para tarefas baseadas em cron, com persistência JSON. |
| **[hardware_net_demo/](hardware_net_demo/)** | Showcase avançado de hardware, redes, CLP e brokers IoT. | `TAICameraInput, TAIMQTTClient, TAIEmailClient, TAIMessenger, TAIIndustrialBridge, TAIChromiumBrowser, TAIOSInputCapture` | Liga câmeras, lê brokers MQTT, envia e-mails/WhatsApp, faz pontes CLP industriais e monitora o SO de forma integrada. |
| **[graphmap_demo/](graphmap_demo/)** | Classificação e roteamento de texto por mapas de grafos ponderados de tokens. | `TAIGraphMap` | Permite adicionar frases de treinamento e classes de destino, treinar o modelo e visualizar o ranking de categorias e explicações com pesos. |

## 💻 Demonstrações em Linha de Comando (Console)
Estes exemplos demonstram a invocação direta de componentes via linha de comando para cenários de depuração rápida ou automação de rotinas:

*   **aivoicesynthesizer_sample.lpr**: Invocação direta de sintetização síncrona/assíncrona de voz via console.
*   **chatgpt_sample.lpr**: Envio de perguntas e auditoria de respostas brutas em OpenAI, Claude e Gemini.
*   **aicodeassistant_sample.lpr**: Rotina em console para otimização e documentação automática de código pascal.
*   **aidatasetgenerator_sample.lpr**: Loop de compilação e exportação de base de dados em formato JSONL.
*   **neuralnetwork_sample.lpr**: Treinamento clássico de perceptron multicamadas XOR em Pascal puro.
