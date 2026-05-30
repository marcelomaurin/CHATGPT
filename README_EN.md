# TCHATGPT — Lazarus Component for AI API Integration

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

A visual component for Free Pascal / Lazarus that allows sending questions and receiving answers from multiple AI providers, including **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras**, and **local models via Ollama**.

## Features

- ✅ Support for multiple providers (OpenAI, OpenRouter, Cerebras, Ollama/Local, Gemini, Claude)
- ✅ Model selection via enum or custom name
- ✅ Communication via HTTPS using `TFPHttpClient` (no Indy dependency)
- ✅ Installation as a component in the Lazarus palette (**IA** tab)
- ✅ Auxiliary components included: `TNeuralNetwork` and `TTokenList`
- ✅ GPL v3 Licensed

---

## Quick Start

```pascal
uses chatgpt;

var
  FChatgpt: TCHATGPT;
begin
  FChatgpt := TCHATGPT.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-YOUR_KEY_HERE';
    FChatgpt.Provider := AIP_GEMINI;       // OpenAI, OpenRouter, Cerebras, Local, Gemini, or Claude
    FChatgpt.TipoChat := VCT_GEMINI_25_FLASH; // Desired model
    FChatgpt.MaxTokens := 4096;            // Token limit in response

    if FChatgpt.SendQuestion('What is the capital of France?') then
      ShowMessage(FChatgpt.Response)
    else
      ShowMessage('Error: ' + FChatgpt.Response);
  finally
    FChatgpt.Free;
  end;
end;
```

---

## Supported Providers

| Provider | Enum | Endpoint | Token Required |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Yes |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Yes |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Yes |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Yes |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Yes |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | No |

---

## Available Models

### OpenAI
| Enum | API Model |
|---|---|
| `VCT_GPT35TURBO` | `gpt-3.5-turbo` |
| `VCT_GPT40` | `gpt-4` |
| `VCT_GPT40_TURBO` | `gpt-4-turbo-preview` |
| `VCT_GPT4o` | `gpt-4o` |
| `VCT_GPTo3_mini` | `o3-mini` |
| `VCT_GPT41` | `gpt-4.1` |
| `VCT_GPT41_MINI` | `gpt-4.1-mini` |
| `VCT_GPT5` | `gpt-5` |

### Google Gemini (Free & Paid)
| Enum | API Model |
|---|---|
| `VCT_GEMINI_25_FLASH` | `gemini-2.5-flash` |
| `VCT_GEMINI_25_PRO` | `gemini-2.5-pro` |
| `VCT_GEMINI_20_FLASH` | `gemini-2.0-flash` |
| `VCT_GEMINI_15_FLASH` | `gemini-1.5-flash` |
| `VCT_GEMINI_15_PRO` | `gemini-1.5-pro` |

### Anthropic Claude (Free & Paid)
| Enum | API Model |
|---|---|
| `VCT_CLAUDE_35_SONNET` | `claude-3-5-sonnet-20241022` |
| `VCT_CLAUDE_35_HAIKU` | `claude-3-5-haiku-20241022` |
| `VCT_CLAUDE_3_OPUS` | `claude-3-opus-20240229` |

### Ollama / Local
| Enum | Model |
|---|---|
| `VCT_LLAMA32_3B` | `llama3.2:3b` |
| `VCT_QWEN25_15B` | `qwen2.5:1.5b` |
| `VCT_DEEPSEEK_R1_15B` | `deepseek-r1:1.5b` |
| `VCT_DEEPSEEK_R1_8B` | `deepseek-r1:8b` |
| `VCT_DEEPSEEK_R1_14B` | `deepseek-r1:14b` |
| `VCT_DEEPSEEK_R1_70B` | `deepseek-r1:70b` |

> To use any other model, define `FChatgpt.CustomModel := 'model-name';`

---

## Properties

| Property | Type | Description |
|---|---|---|
| `TOKEN` | `WideString` | API Key of the provider |
| `Provider` | `TAIProvider` | AI Provider (OpenAI, OpenRouter, Cerebras, Local, Gemini, Claude) |
| `TipoChat` | `TVersionChat` | Selected AI Model |
| `CustomModel` | `WideString` | Custom model name (overrides TipoChat) |
| `LocalIP` | `WideString` | URL of the local Ollama server (default: `http://localhost:11434`) |
| `MaxTokens` | `Integer` | Response token limit (default: 4096) |
| `Dev` | `WideString` | System prompt (default: "You are an assistant.") |
| `Response` | `WideString` | Response to the last question |
| `Question` | `WideString` | Last question sent (read-only) |
| `LastJSON` | `WideString` | Raw JSON of the last response (read-only) |
| `OpenRouterTitle` | `WideString` | Application title (header for OpenRouter) |
| `OpenRouterSite` | `WideString` | Site URL (HTTP-Referer header for OpenRouter) |

---

## Local Ollama Example

```pascal
FChatgpt := TCHATGPT.Create(nil);
try
  FChatgpt.Provider := AIP_LOCAL;
  FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B;
  FChatgpt.LocalIP := 'http://192.168.1.100:11434';  // Server IP

  if FChatgpt.SendQuestion('Explain recursion.') then
    Memo1.Text := FChatgpt.Response;
finally
  FChatgpt.Free;
end;
```

---

## Package Installation in Lazarus

1. In the Lazarus IDE, go to **Package > Open Package File (.lpk)**
2. Navigate to the `pacote/` folder and select **`openai.lpk`**
3. Click **Compile** to compile the package
4. Click **Use > Install** — Lazarus will prompt to rebuild the IDE
5. After restarting, the components will be available under the **IA** tab on the component palette:
   - `TCHATGPT`
   - `TNeuralNetwork`
   - `TTokenList`

---

## Library Requirements (Windows)

For HTTPS communication to work on Windows, the following OpenSSL DLLs must be accessible by the application:

- `libcrypto-1_1.dll`
- `libssl-1_1.dll`
- `libssl-1_1-x64.dll` (64-bit)

**Recommendation:** Copy these DLLs to the **same directory as your application's executable** (not `System32`).

The DLLs are included in the root of this repository for your convenience.

---

## Project Structure

```
CHATGPT/
├── chatgpt.pas           # Core component TCHATGPT
├── funcoes.pas           # Utility functions
├── pacote/
│   ├── openai.lpk        # Lazarus package for installation
│   ├── chatgpt.pas       # Synchronized copy of the component
│   ├── neuralnetwork.pas  # Component TNeuralNetwork (simple neural network)
│   ├── tokenizer.pas     # Component TTokenList (tokenizer helper)
│   └── funcoes.pas       # Synchronized copy of utility functions
├── demo/
│   ├── demo1.lpr         # Demo application
│   └── main.pas          # Demo application main form
├── tools/
│   └── script/           # Supporting scripts (Python tokenizer)
├── dicionario/           # PT-BR dictionary
├── LICENSE               # GPL v3 License
└── README.md             # Portuguese Documentation
```

---

## Demo Application

A complete demo application is available in the `demo/` directory. To run it:

1. Open `demo/demo1.lpi` in Lazarus
2. Compile and run
3. Select your desired AI Provider from the dropdown
4. Select the Model or set a Custom Model
5. Enter your API Key in the corresponding field
6. Type your question and click **Submit** or press **Enter**

---

## Important Notice

Using cloud providers like OpenAI, OpenRouter, Cerebras, Gemini, or Claude requires an **active subscription** and available credits. Using a **local Ollama** setup does not require any API Key.

---

## References

- [OpenAI API Docs](https://platform.openai.com/docs/)
- [Google Gemini API Docs](https://ai.google.dev/docs)
- [Anthropic Claude API Docs](https://docs.anthropic.com/)
- [OpenRouter](https://openrouter.ai/)
- [Ollama](https://ollama.ai/)
- [Cerebras](https://www.cerebras.ai/)
- [PT-BR Words Dataset](https://github.com/j0aoarthur/Palavras-PT-BR)

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
