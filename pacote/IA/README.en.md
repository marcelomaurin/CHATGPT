# 🧠 Documentation for IA Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **IA** tab.

## Artificial Intelligence Core and Neural Connectivity.
Provides connectivity to language models (OpenAI) and implements pure Pascal MLP neural networks.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TCHATGPT** | OpenAI/ChatGPT connector. | `APIKey, Model, MaxTokens` | `SendQuestion(const AQuestion: string): Boolean` | Process NLP and make text-based decisions. |
| **TNeuralNetwork** | Native Multilayer Perceptron Neural Network. | `InputNodes, HiddenNodes, OutputNodes, LearningRate` | `Train, Predict` | Learn complex patterns from datasets. |
| **TTokenizer** | Text tokenizer. | `LowerCase` | `Tokenize, GetVocabulary` | Preprocess raw strings into numerical indices. |
| **TAIGraphMap** | Weighted graph text classifier. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction` | Classify short texts locally without network dependencies. |

### 💻 Lazarus Code Example (TCHATGPT)

```pascal
var
  MyComponent: TCHATGPT;
begin
  MyComponent := TCHATGPT.Create(Self);
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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
