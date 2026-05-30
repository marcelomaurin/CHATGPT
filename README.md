# TCHATGPT — Componente Lazarus para Integração com APIs de IA

🌍 **Idiomas / Languages:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

Componente visual para Free Pascal / Lazarus que permite enviar perguntas e receber respostas de múltiplos provedores de IA, incluindo **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras** e **modelos locais via Ollama**.

## Recursos

- ✅ Suporte a múltiplos provedores (OpenAI, OpenRouter, Cerebras, Ollama/Local, Gemini, Claude)
- ✅ Seleção de modelo por enum ou nome customizado
- ✅ Comunicação via HTTPS com `TFPHttpClient` (sem dependência de Indy)
- ✅ Instalação como componente na paleta do Lazarus (aba **IA**)
- ✅ Componentes auxiliares: `TNeuralNetwork` e `TTokenList`
- ✅ Licença GPL v3

---

## Uso Rápido

```pascal
uses chatgpt;

var
  FChatgpt: TCHATGPT;
begin
  FChatgpt := TCHATGPT.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-SUA_CHAVE_AQUI';
    FChatgpt.Provider := AIP_GEMINI;       // OpenAI, OpenRouter, Cerebras, Local, Gemini ou Claude
    FChatgpt.TipoChat := VCT_GEMINI_25_FLASH; // Modelo desejado
    FChatgpt.MaxTokens := 4096;             // Limite de tokens na resposta

    if FChatgpt.SendQuestion('Qual a capital do Brasil?') then
      ShowMessage(FChatgpt.Response)
    else
      ShowMessage('Erro: ' + FChatgpt.Response);
  finally
    FChatgpt.Free;
  end;
end;
```

---

## Provedores Suportados

| Provedor | Enum | Endpoint | Token Necessário |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Sim |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Sim |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Sim |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Sim |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Sim |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | Não |

---

## Modelos Disponíveis

### OpenAI
| Enum | Modelo API |
|---|---|
| `VCT_GPT35TURBO` | `gpt-3.5-turbo` |
| `VCT_GPT40` | `gpt-4` |
| `VCT_GPT40_TURBO` | `gpt-4-turbo-preview` |
| `VCT_GPT4o` | `gpt-4o` |
| `VCT_GPTo3_mini` | `o3-mini` |
| `VCT_GPT41` | `gpt-4.1` |
| `VCT_GPT41_MINI` | `gpt-4.1-mini` |
| `VCT_GPT5` | `gpt-5` |

### Google Gemini (Gratuito & Pago)
| Enum | Modelo API |
|---|---|
| `VCT_GEMINI_25_FLASH` | `gemini-2.5-flash` |
| `VCT_GEMINI_25_PRO` | `gemini-2.5-pro` |
| `VCT_GEMINI_20_FLASH` | `gemini-2.0-flash` |
| `VCT_GEMINI_15_FLASH` | `gemini-1.5-flash` |
| `VCT_GEMINI_15_PRO` | `gemini-1.5-pro` |

### Anthropic Claude (Gratuito & Pago)
| Enum | Modelo API |
|---|---|
| `VCT_CLAUDE_35_SONNET` | `claude-3-5-sonnet-20241022` |
| `VCT_CLAUDE_35_HAIKU` | `claude-3-5-haiku-20241022` |
| `VCT_CLAUDE_3_OPUS` | `claude-3-opus-20240229` |

### Ollama / Local
| Enum | Modelo |
|---|---|
| `VCT_LLAMA32_3B` | `llama3.2:3b` |
| `VCT_QWEN25_15B` | `qwen2.5:1.5b` |
| `VCT_DEEPSEEK_R1_15B` | `deepseek-r1:1.5b` |
| `VCT_DEEPSEEK_R1_8B` | `deepseek-r1:8b` |
| `VCT_DEEPSEEK_R1_14B` | `deepseek-r1:14b` |
| `VCT_DEEPSEEK_R1_70B` | `deepseek-r1:70b` |

> Para usar qualquer outro modelo, defina `FChatgpt.CustomModel := 'nome-do-modelo';`

---

## Propriedades

| Propriedade | Tipo | Descrição |
|---|---|---|
| `TOKEN` | `WideString` | Chave de API do provedor |
| `Provider` | `TAIProvider` | Provedor de IA (OpenAI, OpenRouter, Cerebras, Local, Gemini, Claude) |
| `TipoChat` | `TVersionChat` | Modelo de IA selecionado |
| `CustomModel` | `WideString` | Nome de modelo customizado (sobrescreve TipoChat) |
| `LocalIP` | `WideString` | URL do servidor Ollama local (padrão: `http://localhost:11434`) |
| `MaxTokens` | `Integer` | Limite de tokens na resposta (padrão: 4096) |
| `Dev` | `WideString` | System prompt (padrão: "Você é um assistente.") |
| `Response` | `WideString` | Resposta da última pergunta |
| `Question` | `WideString` | Última pergunta enviada (somente leitura) |
| `LastJSON` | `WideString` | JSON bruto da última resposta (somente leitura) |
| `OpenRouterTitle` | `WideString` | Título da aplicação (header para OpenRouter) |
| `OpenRouterSite` | `WideString` | URL do site (header HTTP-Referer para OpenRouter) |

---

## Exemplo com Ollama Local

```pascal
FChatgpt := TCHATGPT.Create(nil);
try
  FChatgpt.Provider := AIP_LOCAL;
  FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B;
  FChatgpt.LocalIP := 'http://192.168.1.100:11434';  // IP do servidor

  if FChatgpt.SendQuestion('Explique o conceito de recursão.') then
    Memo1.Text := FChatgpt.Response;
finally
  FChatgpt.Free;
end;
```

---

## Instalação do Pacote no Lazarus

1. No Lazarus IDE, vá em **Package > Open Package File (.lpk)**
2. Navegue até a pasta `pacote/` e selecione **`openai.lpk`**
3. Clique em **Compile** para compilar o pacote
4. Clique em **Use > Install** — o Lazarus pedirá para reconstruir a IDE
5. Após reiniciar, os componentes estarão disponíveis na aba **IA** da paleta de componentes:
   - `TCHATGPT`
   - `TNeuralNetwork`
   - `TTokenList`

---

## Requisitos de Bibliotecas (Windows)

Para que a comunicação HTTPS funcione no Windows, as seguintes DLLs OpenSSL precisam estar acessíveis pela aplicação:

- `libcrypto-1_1.dll`
- `libssl-1_1.dll`
- `libssl-1_1-x64.dll` (64-bit)

**Recomendação:** Copie as DLLs para a **mesma pasta do executável** da sua aplicação (não para `System32`).

As DLLs estão incluídas na raiz deste repositório para conveniência.

---

## Estrutura do Projeto

```
CHATGPT/
├── chatgpt.pas           # Componente principal TCHATGPT
├── funcoes.pas           # Funções utilitárias
├── pacote/
│   ├── openai.lpk        # Pacote Lazarus para instalação
│   ├── chatgpt.pas       # Cópia sincronizada do componente
│   ├── neuralnetwork.pas  # Componente TNeuralNetwork (rede neural simples)
│   ├── tokenizer.pas     # Componente TTokenList (tokenizador)
│   └── funcoes.pas       # Cópia sincronizada das funções utilitárias
├── demo/
│   ├── demo1.lpr         # Aplicação demo
│   └── main.pas          # Form principal do demo
├── tools/
│   └── script/           # Scripts de apoio (tokenizador Python)
├── dicionario/           # Dicionário PT-BR
├── LICENSE               # GPL v3
└── README.md             # Esta documentação
```

---

## Aplicação Demo

Uma aplicação demo completa está disponível na pasta `demo/`. Para executar:

1. Abra `demo/demo1.lpi` no Lazarus
2. Compile e execute
3. Selecione o Provedor de IA desejado no menu suspenso
4. Selecione o Modelo ou defina um Modelo Customizado
5. Insira seu token da API no campo correspondente
6. Digite sua pergunta e clique em **Submit** ou pressione **Enter**

---

## Aviso Importante

Para utilizar provedores como OpenAI, OpenRouter, Cerebras, Gemini ou Claude, é necessário possuir uma **assinatura ativa** e créditos disponíveis. O uso com **Ollama local** não requer chave de API.

---

## Referências

- [OpenAI API](https://platform.openai.com/docs/)
- [Google Gemini API](https://ai.google.dev/docs)
- [Anthropic Claude API](https://docs.anthropic.com/)
- [OpenRouter](https://openrouter.ai/)
- [Ollama](https://ollama.ai/)
- [Cerebras](https://www.cerebras.ai/)
- [Palavras PT-BR](https://github.com/j0aoarthur/Palavras-PT-BR)

---

## Licença

Este projeto está licenciado sob a [GNU General Public License v3.0](LICENSE).
