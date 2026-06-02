# 🧠 Paquete de Componentes de IA — openai.lpk

> [!NOTE]
> Este directorio contiene la implementación de la suite oficial de componentes de IA y automatización para Lazarus/Delphi (**openai.lpk**). Este paquete integra Inteligencia Artificial, Aprendizaje Automático, automatización de hardware, redes, audio, procesamiento de imágenes y documentos de forma nativa y multiplataforma.

## Referencia de Componentes Principales

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TCHATGPT** | Conector universal de OpenAI y LLMs en la nube o servidores locales. | `APIKey, Provider, TipoChat, CustomModel, MaxTokens` | `SendQuestion(ASK): Boolean, TipoModelo: string` | Procesar lenguaje natural y generar respuestas cognitivas. |
| **TNeuralNetwork** | Red Neuronal Perceptron Multicapa nativa en Pascal puro. | `LearningRate, ActivationType` | `Initialize, Predict, Train, TrainEpochs, SaveNetwork` | Entrenar modelos locales y realizar predicciones matemáticas. |
| **TAICodeAssistant** | Asistente cognitivo para auditar y optimizar código fuente. | `ChatGPT` | `OptimizeCode, FindBugs, DocumentCode, ExplainCode` | Analizar bloques de código Pascal y sugerir refactorizaciones. |
| **TAIDatasetGenerator** | Generador y exportador de conjuntos de datos (JSONL, CSV). | `DataRows` | `AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV` | Compilar bases de datos y dividir conjuntos de entrenamiento. |
| **TTokenizer** | Tokenizador de texto y segmentador de palabras rápido. | `LowerCase` | `Tokenize, GetVocabulary` | Preprocesar cadenas en secuencias numéricas (tokens). |
| **TPythonConnector** | Puente de ejecución y bindings dinámicos de Python en tiempo de ejecución. | `DLLPath, Active, Version` | `ExecString, GetVar, SetVar, Eval` | Integrar modelos avanzados del ecosistema Python (TensorFlow, etc.). |
| **TPerceptron** | Neurona Perceptron clásico binario de capa única en Pascal. | `LearningRate, Weights, Bias` | `Initialize, Predict, Train, TrainEpochs` | Clasificar estados lógicos binarios de forma rápida. |
| **TSOMMap** | Red de Auto-Organización de Kohonen para agrupamiento de datos. | `GridWidth, GridHeight, InputDim` | `Initialize, FindBMU, TrainStep, Train` | Agrupar datos complejos en rejillas bidimensionales. |
| **TCNNClassifier** | Clasificador convolucional profundo MobileNetV2 para imágenes. | `PythonConnector` | `InstallDependencies, ClassifyImage` | Analizar e identificar fotos u fotogramas de cámaras. |
| **TLSTMPredictor** | Previsor de series temporales usando redes recurrentes LSTM. | `PythonConnector` | `InstallDependencies, TrainLSTM, PredictNext` | Predecir tendencias futuras a partir de datos secuenciales. |
| **TAIVoiceSynthesizer** | Motor de síntesis de voz (TTS) nativo Windows y Linux. | `Volume, Rate, VoiceName, Asynchronous` | `Say, GetAvailableVoices` | Hablar reportes o alertas generadas por la IA a través del hardware. |

### 💻 Ejemplo General de Instanciación

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


### 📂 Directorio de Ejemplos (Samples)
La carpeta `samples/` contiene demostraciones visuales y de consola listas para usar para cada una de las funciones del paquete.

### ⚡ Conectividad y Prompts de Agentes
Todos los componentes del paquete cuentan con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
