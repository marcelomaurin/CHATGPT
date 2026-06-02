# 🧠 Pacote de Componentes de IA — openai.lpk

> [!NOTE]
> Este diretório contém a implementação do pacote oficial de componentes de IA e Automação para Lazarus/Delphi (**openai.lpk**). Este pacote integra Inteligência Artificial, Aprendizado de Máquina, processamento de hardware, redes, áudio, imagem e documentos de forma nativa e multiplataforma.

## Referência dos Componentes Principais

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TCHATGPT** | Conector universal OpenAI e LLMs na nuvem ou servidores locais. | `APIKey, Provider, TipoChat, CustomModel, MaxTokens` | `SendQuestion(ASK): Boolean, TipoModelo: string` | Processar linguagem natural e gerar respostas cognitivas. |
| **TNeuralNetwork** | Rede Neural Perceptron Multicamadas nativa em Pascal puro. | `LearningRate, ActivationType` | `Initialize, Predict, Train, TrainEpochs, SaveNetwork` | Treinar modelos locais e realizar previsões matemáticas. |
| **TAICodeAssistant** | Assistente cognitivo de auditoria e otimização de código. | `ChatGPT` | `OptimizeCode, FindBugs, DocumentCode, ExplainCode` | Analisar blocos de código pascal e sugerir refatorações. |
| **TAIDatasetGenerator** | Gerador e exportador de dados tabulares (JSONL, CSV). | `DataRows` | `AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV` | Compilar bases de dados e dividir conjuntos de treinamento. |
| **TTokenizer** | Tokenizador e segmentador de texto rápido. | `LowerCase` | `Tokenize, GetVocabulary` | Converter strings brutas em sequências numéricas (tokens). |
| **TPythonConnector** | Ponte de execução e bindings do interpretador Python em tempo de execução. | `DLLPath, Active, Version` | `ExecString, GetVar, SetVar, Eval` | Integrar modelos avançados do ecossistema Python (TensorFlow, etc.). |
| **TPerceptron** | Neurônio Perceptron clássico binário de camada única em Pascal. | `LearningRate, Weights, Bias` | `Initialize, Predict, Train, TrainEpochs` | Classificar padrões binários linearmente separáveis de forma rápida. |
| **TSOMMap** | Rede de Auto-Organização de Kohonen para agrupamento de dados. | `GridWidth, GridHeight, InputDim` | `Initialize, FindBMU, TrainStep, Train` | Agrupar dados complexos em grades bidimensionais. |
| **TCNNClassifier** | Classificador convolucional profundo MobileNetV2 para imagens. | `PythonConnector` | `InstallDependencies, ClassifyImage` | Classificar fotos e frames obtidos de câmeras de segurança. |
| **TLSTMPredictor** | Previsor de séries temporais usando redes recorrentes LSTM. | `PythonConnector` | `InstallDependencies, TrainLSTM, PredictNext` | Prever tendências futuras em dados de sensores sequenciais. |
| **TAIVoiceSynthesizer** | Motor de síntese de voz (TTS) nativo Windows e Linux. | `Volume, Rate, VoiceName, Asynchronous` | `Say, GetAvailableVoices` | Falar relatórios ou alertas gerados pela IA via hardware de áudio. |

### 💻 Estrutura Geral de Instanciação

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


### 📂 Diretório de Exemplos (Samples)
A pasta `samples/` contém demonstrações completas de uso visual e console para cada um dos recursos do pacote.

### ⚡ Conectividade e Prompts de Agentes
Todos os componentes deste pacote possuem a propriedade published `Prompt` predefinida. Ela fornece as diretivas necessárias para que Agentes de IA autônomos (`TAIAgent`) compreendam a finalidade do hardware ou documento e injetem parâmetros dinamicamente via reflexão RTTI.
