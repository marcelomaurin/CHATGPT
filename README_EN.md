# TCHATGPT — AI Component Suite for Lazarus

🌍 **Languages / Idiomas:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

A complete suite of visual and non-visual components for Free Pascal / Lazarus designed to integrate **generative AI and Machine Learning** natively into your applications. It supports **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras**, **local models via Ollama**, and local neural networks.

---

## 📦 Components Included in the Package

The suite installs the following tools under the **IA** tab of the Lazarus component palette:

### 1. `TCHATGPT` (AI API Connector)
The core engine for LLM integration. Send questions and receive structured text responses from global or local providers.
- **Supported Providers**: OpenAI, Gemini, Claude, OpenRouter, Cerebras, and Ollama/Local.
- **Features**: Control over Max Tokens, System/Developer Prompts, temperature, and custom models.

### 2. `TNeuralNetwork` (Multilayer Neural Network)
A Multilayer Perceptron (MLP) written in **pure Pascal**, allowing you to build and train local neural network models without external dependencies.
- **Built-in Activation Functions**: Sigmoid (`atSigmoid`), ReLU (`atReLU`), Tanh (`atTanh`), and Custom (`atCustom` via events).
- **Epoch Training**: The `TrainEpochs` method trains models from a dataset matrix and calculates the Mean Squared Error (MSE Loss).
- **Persistence**: Save and quickly load weights and biases (`SaveNetwork` / `LoadNetwork`).

### 3. `TAICodeAssistant` (Code Assistant)
A developer-focused virtual assistant. It binds to a configured `TCHATGPT` component to automate common programming tasks:
- **`OptimizeCode(ACode)`**: Optimizes routine performance and readability.
- **`FindBugs(ACode)`**: Scans for logic bugs, memory leaks, and recommends fixes.
- **`DocumentCode(ACode)`**: Automatically adds structured XML/Javadoc documentation comments.
- **`GenerateUnitTests(ACode)`**: Writes comprehensive unit tests using frameworks like `FPCUnit`.
- **`TranslateCode(ACode, From, To)`**: Translates code between languages (e.g., C# to Pascal).
- **`ExplainCode(ACode)`**: Explains the inner workings of an algorithm step-by-step.

### 4. `TAIDatasetGenerator` (Dataset Builder Helper)
An easy data preparer. Helps generate files for LLM Fine-Tuning or dataset files for local neural networks:
- **Fine-Tuning**: Exports conversations in the standard **JSONL** (JSON Lines) format accepted by OpenAI and Ollama.
- **Neural Network Integration**: Exports data to **CSV** and loads delimited CSV files directly into compatible input and target matrices (`TMatrix`) for use in `TNeuralNetwork.TrainEpochs`.

### 5. `TTokenList` (Utility Tokenizer)
An auxiliary string analyzer to build tokenized lists from text collections.

---

## Quick Start (Code Assistant)

```pascal
uses chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  OptimizedCode: string;
begin
  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-YOUR_KEY_HERE';
    FChatgpt.Provider := AIP_CLAUDE;          // Configures Anthropic Claude
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
    
    FAssistant.ChatGPT := FChatgpt; // Binds the AI engine connector
    
    OptimizedCode := FAssistant.OptimizeCode('procedure TForm1.Click; begin i := i + 1; end;');
    ShowMessage(OptimizedCode);
  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;
end;
```

---

## Local Training (`TNeuralNetwork` & `TAIDatasetGenerator`)

```pascal
var
  FNet: TNeuralNetwork;
  FGen: TAIDatasetGenerator;
  Inputs, Targets: TMatrix;
  Loss: Double;
begin
  FNet := TNeuralNetwork.Create(nil);
  FGen := TAIDatasetGenerator.Create(nil);
  try
    // Loads training data directly from a CSV file
    FGen.LoadFromCSV('data.csv', Inputs, Targets, 2, 1); // 2 Inputs, 1 Output

    // Initializes neural network: 2 Inputs, 4 Hidden, 1 Output, Learning Rate = 0.05
    FNet.Initialize(2, 4, 1, 0.05);
    FNet.ActivationType := atSigmoid;

    // Runs training loop over the dataset for 1000 epochs
    FNet.TrainEpochs(Inputs, Targets, 1000, Loss);
    ShowMessage(Format('Training complete! Final MSE Loss: %0.6f', [Loss]));

    FNet.SaveNetwork('model.net');
  finally
    FGen.Free;
    FNet.Free;
  end;
end;
```

---

## Supported Providers (LLMs)

| Provider | Enum | Endpoint | Token Required | Free/Low-cost Versions Details |
|---|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Yes | Supports `gpt-4o-mini` (low-cost/API free tier) |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Yes | Multi free models with unlimited access (e.g., Llama 3, Gemma 2, DeepSeek R1) |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Yes | Free access during beta phase |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Yes | Generous free usage tier (e.g., `gemini-2.5-flash`) |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Yes | Paid token (development/testing) |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | No | **100% Free** and offline (DeepSeek R1, Llama 3.2, etc.) |

---

## Package Installation in Lazarus

1. In the Lazarus IDE, go to **Package > Open Package File (.lpk)**
2. Navigate to the `pacote/` folder and select **`openai.lpk`**
3. Click **Compile** to compile the package
4. Click **Use > Install** — Lazarus will prompt to rebuild the IDE
5. After restarting, the 5 components will be available under the **IA** tab on the component palette.

---

## Library Requirements (Windows)

For HTTPS communication to work on Windows, the appropriate OpenSSL DLLs for your compiled application's architecture (32-bit or 64-bit) must be accessible. The suite already includes the DLLs in the `pacote/lib/` folder:

*   **32-bit Applications (i386-win32)**: `pacote/lib/i386-win32/`
    - `libcrypto-1_1.dll`, `libssl-1_1.dll`
*   **64-bit Applications (x86_64-win64)**: `pacote/lib/x86_64-win64/`
    - `libcrypto.dll`, `libssl-1_1-x64.dll`

**Recommendation:** Copy the DLLs from the corresponding `lib/` folder to the **same directory as your compiled executable**.

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
