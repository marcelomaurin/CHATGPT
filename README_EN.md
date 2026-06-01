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

## 📦 Component Palette Tabs Included in the Package

The suite installs four feature-rich tabs under the Lazarus component palette:

---

### Tab: `IA` (Generative AI and Machine Learning)

*   **`TCHATGPT` (AI API Connector)**: The core engine for LLM integration. Send questions and receive structured text responses from global providers (OpenAI, Gemini, Claude, OpenRouter, Cerebras) or local ones (Ollama).
*   **`TNeuralNetwork` (Multilayer Neural Network)**: A Multilayer Perceptron (MLP) written in **pure Pascal**, allowing you to build, train (`TrainEpochs` calculating MSE Loss), and persist local neural networks.
*   **`TAICodeAssistant` (Code Assistant)**: Binds to a configured connector to optimize code, scan for bugs, document, write unit tests, and translate programming languages.
*   **`TAIDatasetGenerator` (Dataset Builder)**: Easily formats JSONL conversations for LLM Fine-Tuning or dataset CSV files for local TNeuralNetwork training.
*   **`TTokenList` (Tokenizer)**: Utility string tokenizer for text analyzing.

---

### Tab: `IA Filtros Sonoros` (Digital Signal Processing - DSP)

*   **`TLowPassFilter`**: IIR RC first-order low-pass filter to smooth sudden transitions.
*   **`THighPassFilter`**: IIR RC first-order high-pass filter to reject low frequencies (rumble/DC bias).
*   **`TAverageFilter`**: Sliding window moving average filter to attenuate fast fluctuations.
*   **`TFDMMultiplexer`**: Frequency Division Multiplexing (FDM) modulator/demodulator using AM-DSB-SC with shifted carrier frequencies.
*   **`TTDMMultiplexer`**: Time Division Multiplexing (TDM) modulator slicing frames into interleaved time slots.
*   **`TCDMMultiplexer`**: CDM (CDMA) multiplexer using Walsh-Hadamard orthogonal codes.
*   **`TOFDMMultiplexer`**: Orthogonal Frequency Division Multiplexing (OFDM) modulator/demodulator using FFT and IFFT Radix-2 Cooley-Tukey with cyclic prefixes.

---

### Tab: `IA Image` (Computer Vision and Image Processing)

*   **`TGrayscaleFilter`**: Converts images to grayscale using photometric luminance weights.
*   **`TNegativeFilter`**: Fully inverts all color channels ($R_{new} = 65535 - R$).
*   **`TBrightnessContrastFilter`**: Adjusts brightness and contrast linearly with high fidelity.
*   **`TBinarizationFilter`**: Threshold binarizer to output absolute black-and-white images.
*   **`TBlurFilter`**: Defocuses images using a $3\times3$ box blur convolution with edge clamping.
*   **`TSharpenFilter`**: Sharpens images using a high-pass Laplacian $3\times3$ kernel.
*   **`TSobelFilter`**: Sobel edge detector returning horizontal/vertical gradient magnitude maps.
*   **`TErosionDilationFilter`**: Morphological mathematical operators (Erosion / Dilation) with custom radii.

---

### Tab: `IA Schedulle` (JSON Persistence and Dependency Scheduler)

*   **`TJSONGroupStorage`**: Named grouped key-value storage component automatically persisted in JSON files. Seamlessly accommodates very large strings and texts.
*   **`TIASchedule`**: Work schedule manager supporting hierarchical parent-child tasks and live dependency solving (`IsReady`).

---

### Tab: `IA Voice` (Native Multiplatform Text-to-Speech)

*   **`TAIVoiceSynthesizer`**: High-performance Text-to-Speech synthesis component. Communicates directly with the platform's native subsystem: **SAPI (Speech API)** on Windows via COM Automation, and the **eSpeak/eSpeak-NG** library on Linux via dynamic linking.
    *   **Properties**: `Volume` (0..100), `Rate` (Speed, from -10 to 10), `Asynchronous` (speaks without blocking the application UI), and `VoiceName` (to override language or voice model).
    *   **Methods**: `Say(Text)` to speak, and `GetAvailableVoices(List)` to dynamically query all voice models installed on the OS.

---

### Tab: `IA Agent` (Autonomous Intelligent Agents and Decision Making)

*   **`TAIAgent`**: The orchestrator brain of the autonomous agent. Dynamically constructs complex instructions via `TCHATGPT` and decodes analytical responses using a native FCL JSON parser.
*   **`TAIAgentOptions`**: Houses rules and guidelines as a list of directives (`Questions: TStrings`) and operational business context (`Context`).
*   **`TAIAgentAction`**: Declares allowed external actions (`AllowedActions: TStrings`) and their required parameter definitions (`ParameterDefinitions: TStrings`), triggering native callback events (`OnExecuteAction`) as soon as the structured action and parameters are parsed.
*   **`TAIAgentResource`**: A bank managing real-world physical channels (such as Email, local File writing, WhatsApp, SMS, TCP/UDP packets, and native HTTP POST Web API with headers).
*   **`TAIAgentOutput`**: The bridging component that automatically hooks `TAIAgentAction` decisions, maps them to `TAIAgentResource` channels, and executes the physical world actions, yielding detailed logs.

---

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
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Yes | **Native v1beta REST API** (`generateContent`). Generous free usage tier (e.g., `gemini-1.5-flash`, `gemini-2.5-pro`) using URL Query parameter authentication (?key=) and native `systemInstruction` support. |
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
