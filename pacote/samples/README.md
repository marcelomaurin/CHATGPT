# 📂 Projetos de Demonstração (Samples)

Este diretório contém a suíte completa de exemplos desenvolvidos para demonstrar e testar todos os componentes de Inteligência Artificial, Aprendizado de Máquina (Machine Learning), Processamento de Imagens, Processamento de Sinais (DSP) e Voz da biblioteca **`openai.lpk`**.

---

## 🖥️ Demonstrações em Interface Gráfica (GUI)

Os exemplos a seguir são projetos visuais prontos para compilação e execução interativa através do Lazarus:

### 1. [visual_demo/](visual_demo/) (Unified AI Showcase)
* **O que faz**: Central de controle unificada contendo abas de testes funcionais.
* **Componentes**: `TCHATGPT`, `TNeuralNetwork`, `TAICodeAssistant`, `TAIDatasetGenerator`.
* **Como funciona**: Interface aba por aba permitindo fazer perguntas às principais IAs, auditar códigos, exportar datasets de treinamento e rodar treinamento local na lógica XOR.

### 2. [voicesynthesizer_demo/](voicesynthesizer_demo/) (Sintetizador de Voz Nativo)
* **O que faz**: Painel de controle completo de sintetização de voz (Text-to-Speech).
* **Componentes**: `TAIVoiceSynthesizer`.
* **Como funciona**: Permite alternar dinamicamente entre SAPI (Windows) e eSpeak (Linux), listando todas as vozes (narradores) do sistema operacional de forma totalmente nativa, com ajustes de volume, velocidade e suporte a thread assíncrona.

### 3. [yolo_demo/](yolo_demo/) (YOLOv8 Deep Object Detection)
* **O que faz**: Detecção profunda de objetos com modelo YOLOv8 desenhando retângulos em tela.
* **Componentes**: `TYOLO`, `TPythonConnector`.
* **Como funciona**: Bridge dinâmica com Python que instala silenciosamente dependências pip, executa detecção local (modelo `yolov8n.pt` de 6MB) e plota contornos em canvas Pascal nativo com suporte seguro a imagens PNG.

### 4. [cnn_demo/](cnn_demo/) (MobileNetV2 Convolucional Classifier)
* **O que faz**: Classificação de imagens profunda usando redes neurais convolucionais (CNN).
* **Componentes**: `TCNNClassifier`, `TPythonConnector`.
* **Como funciona**: Carrega a MobileNetV2 (ImageNet) via TensorFlow no interpretador Python, classifica qualquer imagem local e retorna a classe identificada com percentual de confiança.

### 5. [lstm_demo/](lstm_demo/) (Recurrent LSTM Trend Prediction)
* **O que faz**: Previsão sequencial de tendências e dados temporais de forma gráfica.
* **Componentes**: `TLSTMPredictor`, `TPythonConnector`.
* **Como funciona**: Treina uma rede neural recorrente LSTM localmente em dados senoidais e projeta graficamente em tempo real as curvas futuras preditas pelo modelo.

### 6. [face_detection_demo/](face_detection_demo/) (OpenCV Face Detection)
* **O que faz**: Identificação facial em tempo real.
* **Componentes**: `TFaceDetection`, `TPythonConnector`.
* **Como funciona**: Acessa o OpenCV via bridge Python para rodar Haar Cascades e plotar em tempo real retângulos delimitadores vermelhos ao redor de faces.

### 7. [python_demo/](python_demo/) (Python Connector Playground)
* **O que faz**: Console e playground interativo integrado para o interpretador Python.
* **Componentes**: `TPythonConnector`.
* **Como funciona**: Escreva scripts no Memo, configure/leia variáveis globais dinamicamente e avalie equações complexas via `Eval`.

### 8. [neural_network_demo/](neural_network_demo/) (MLP XOR Trainer)
* **O que faz**: Playground local de redes neurais artificiais multicamadas (MLP).
* **Componentes**: `TNeuralNetwork`.
* **Como funciona**: Treina uma rede neural em Pascal puro na lógica XOR, exibe perda MSE e salva/restaura pesos estáveis de treinamento em arquivos texto.

### 9. [perceptron_demo/](perceptron_demo/) (Single-Layer Perceptron Gates)
* **O que faz**: Treinador de portas lógicas (AND, OR, NAND, NOR).
* **Componentes**: `TPerceptron`.
* **Como funciona**: Algoritmo escrito em Pascal puro que atualiza pesos sinápticos e bias via regra delta, permitindo visualizar a convergência de erro do neurônio.

### 10. [som_demo/](som_demo/) (Kohonen SOM Grid RGB Mapping)
* **O que faz**: Agrupamento topológico visual de cores em grade bidimensional.
* **Componentes**: `TSOMMap`.
* **Como funciona**: Organiza vetores RGB tridimensionais em degradês e agrupamentos de vizinhança topológica em Pascal puro em tempo real.

### 11. [tokenizer_demo/](tokenizer_demo/) (String Segmenter & Indexer)
* **O que faz**: Segmentação analítica e tokenização de strings.
* **Componentes**: `TTokenList`.
* **Como funciona**: Quebra frases em palavras ordenadas por frequência, indexando termos para buscas de texto rápidas com exportação JSON.

### 12. [image_filters_demo/](image_filters_demo/) (LCL Image Filtering)
* **O que faz**: Processamento matricial de imagens interativo.
* **Componentes**: Filtros da aba `IA Image` (`TBlurFilter`, `TSobelFilter`, `TGrayscaleFilter`, etc.).
* **Como funciona**: Aplica kernels convolucionais, binarizações e operações morfológicas nativamente em canvas Pascal de alta performance.

### 13. [sound_filters_demo/](sound_filters_demo/) (DSP Signals & RF Multiplexers)
* **O que faz**: Processamento digital de sinais (DSP) e modulação/demodulação de frequências.
* **Componentes**: Filtros da aba `IA Filtros Sonoros` (`TLowPassFilter`, `TFDMMultiplexer`, `TOFDMMultiplexer`, etc.).
* **Como funciona**: Simula atenuação de graves/agudos, multiplexações FDM, TDM, CDM (CDMA) e OFDM ortogonal baseada em FFT e prefixos cíclicos.

### 14. [schedule_demo/](schedule_demo/) (Tasks Schedule Resolver)
* **O que faz**: Gerenciador cronológico e encadeamento de cronogramas.
* **Componentes**: `TIASchedule`, `TJSONGroupStorage`.
* **Como funciona**: Resolução de árvore de dependências para calcular se tarefas estão prontas para rodar, com salvamento e carregamento automático persistido em arquivos JSON.

---

## 💻 Demonstrações em Linha de Comando (Console)

Estes exemplos demonstram a invocação direta de componentes via linha de comando para cenários de depuração rápida ou automação de rotinas:

*   **`aivoicesynthesizer_sample.lpr`**: Exemplo síncrono/assíncrono direto de sintetização de voz via console.
*   **`chatgpt_sample.lpr`**: Envio rápido de perguntas e auditoria de URLs e payloads brutos das principais IAs (OpenAI, Claude, Gemini, etc.).
*   **`aicodeassistant_sample.lpr`**: Rotina em console para otimização automática de código, auditoria de bugs e documentação estruturada.
*   **`aidatasetgenerator_sample.lpr`**: Loop de geração automática e exportação estruturada de datasets de conversas em formato JSONL.
*   **`neuralnetwork_sample.lpr`**: Demonstração em linha de comando de treinamento, iteração de épocas e predição XOR em Pascal puro.
