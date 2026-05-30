# TCHATGPT — Componente Lazarus per l'Integrazione con API di IA

🌍 **Lingue / Idiomas:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

Componente visivo per Free Pascal / Lazarus che consente di inviare domande e ricevere risposte da molteplici fornitori di intelligenza artificiale (IA), tra cui **OpenAI (ChatGPT)**, **OpenRouter**, **Cerebras** e **modelli locali tramite Ollama**.

## Funzionalità

- ✅ Supporto per molteplici fornitori (OpenAI, OpenRouter, Cerebras, Ollama/Local)
- ✅ Selezione del modello tramite enum o nome personalizzato
- ✅ Comunicazione via HTTPS con `TFPHttpClient` (senza dipendenza da Indy)
- ✅ Installazione come componente nella tavolozza di Lazarus (scheda **IA**)
- ✅ Componenti ausiliari inclusi: `TNeuralNetwork` e `TTokenList`
- ✅ Rilasciato sotto licenza GPL v3

---

## Guida Rapida

```pascal
uses chatgpt;

var
  FChatgpt: TCHATGPT;
begin
  FChatgpt := TCHATGPT.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-IL_TUO_TOKEN_QUI';
    FChatgpt.Provider := AIP_OPENAI;       // OpenAI, OpenRouter, Cerebras o Local
    FChatgpt.TipoChat := VCT_GPT4o;        // Modello desiderato
    FChatgpt.MaxTokens := 4096;            // Limite di token nella risposta

    if FChatgpt.SendQuestion('Qual è la capitale dell''Italia?') then
      ShowMessage(FChatgpt.Response)
    else
      ShowMessage('Errore: ' + FChatgpt.Response);
  finally
    FChatgpt.Free;
  end;
end;
```

---

## Fornitori Supportati

| Fornitore | Enum | Endpoint | Token Richiesto |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Sì |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Sì |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Sì |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | No |

---

## Modelli Disponibili

### OpenAI
| Enum | Modello API |
|---|---|
| `VCT_GPT35TURBO` | `gpt-3.5-turbo` |
| `VCT_GPT40` | `gpt-4` |
| `VCT_GPT40_TURBO` | `gpt-4-turbo-preview` |
| `VCT_GPT4o` | `gpt-4o` |
| `VCT_GPTo3_mini` | `o3-mini` |
| `VCT_GPT41` | `gpt-4.1` |
| `VCT_GPT41_MINI` | `gpt-4.1-mini` |
| `VCT_GPT5` | `gpt-5` |

### Ollama / Local
| Enum | Modello |
|---|---|
| `VCT_LLAMA32_3B` | `llama3.2:3b` |
| `VCT_QWEN25_15B` | `qwen2.5:1.5b` |
| `VCT_DEEPSEEK_R1_15B` | `deepseek-r1:1.5b` |
| `VCT_DEEPSEEK_R1_8B` | `deepseek-r1:8b` |
| `VCT_DEEPSEEK_R1_14B` | `deepseek-r1:14b` |
| `VCT_DEEPSEEK_R1_70B` | `deepseek-r1:70b` |

> Per utilizzare qualsiasi altro modello, definire `FChatgpt.CustomModel := 'nome-del-modello';`

---

## Proprietà

| Proprietà | Tipo | Descrizione |
|---|---|---|
| `TOKEN` | `WideString` | Chiave API del fornitore |
| `Provider` | `TAIProvider` | Fornitore di IA (OpenAI, OpenRouter, Cerebras, Local) |
| `TipoChat` | `TVersionChat` | Modello di IA selezionato |
| `CustomModel` | `WideString` | Nome del modello personalizzato (sovrascrive TipoChat) |
| `LocalIP` | `WideString` | URL del server locale Ollama (predefinito: `http://localhost:11434`) |
| `MaxTokens` | `Integer` | Limite di token nella risposta (predefinito: 4096) |
| `Dev` | `WideString` | Prompt di sistema (predefinito: "Sei un assistente.") |
| `Response` | `WideString` | Risposta all'ultima domanda |
| `Question` | `WideString` | Ultima domanda inviata (sola lettura) |
| `LastJSON` | `WideString` | JSON non elaborato dell'ultima risposta (sola lettura) |
| `OpenRouterTitle` | `WideString` | Titolo dell'applicazione (intestazione per OpenRouter) |
| `OpenRouterSite` | `WideString` | URL del sito (intestazione HTTP-Referer per OpenRouter) |

---

## Esempio con Ollama Locale

```pascal
FChatgpt := TCHATGPT.Create(nil);
try
  FChatgpt.Provider := AIP_LOCAL;
  FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B;
  FChatgpt.LocalIP := 'http://192.168.1.100:11434';  // IP del server

  if FChatgpt.SendQuestion('Spiega il concetto di ricorsione.') then
    Memo1.Text := FChatgpt.Response;
finally
  FChatgpt.Free;
end;
```

---

## Installazione del Pacchetto in Lazarus

1. Nell'IDE di Lazarus, andare su **Package > Open Package File (.lpk)**
2. Navigare alla cartella `pacote/` e selezionare **`openai.lpk`**
3. Fare clic su **Compile** per compilare il pacchetto
4. Fare clic su **Use > Install** — Lazarus chiederà di ricompilare l'IDE
5. Dopo il riavvio, i componenti saranno disponibili nella scheda **IA** della tavolozza dei componenti:
   - `TCHATGPT`
   - `TNeuralNetwork`
   - `TTokenList`

---

## Requisiti delle Librerie (Windows)

Affinché la comunicazione HTTPS funzioni correttamente su Windows, le seguenti DLL di OpenSSL devono essere accessibili dall'applicazione:

- `libcrypto-1_1.dll`
- `libssl-1_1.dll`
- `libssl-1_1-x64.dll` (64-bit)

**Raccomandazione:** Copiare queste DLL nella **stessa cartella dell'eseguibile dell'applicazione** (non in `System32`).

Le DLL sono incluse nella radice di questo repository per vostra comodità.

---

## Struttura del Progetto

```
CHATGPT/
├── chatgpt.pas           # Componente principale TCHATGPT
├── funcoes.pas           # Funzioni ausiliarie
├── pacote/
│   ├── openai.lpk        # Pacchetto Lazarus per l'installazione
│   ├── chatgpt.pas       # Copia sincronizzata del componente
│   ├── neuralnetwork.pas  # Componente TNeuralNetwork (semplice rete neurale)
│   ├── tokenizer.pas     # Componente TTokenList (supporto per tokenizzazione)
│   └── funcoes.pas       # Copia sincronizzata di funzioni ausiliarie
├── demo/
│   ├── demo1.lpr         # Applicazione di dimostrazione
│   └── main.pas          # Form principale della demo
├── tools/
│   └── script/           # Script di supporto (tokenizer Python)
├── dicionario/           # Dizionario PT-BR
├── LICENSE               # Licenza GPL v3
└── README.md             # Documentazione in portoghese
```

---

## Applicazione Demo

Un'applicazione demo completa è disponibile nella cartella `demo/`. Per eseguirla:

1. Aprire `demo/demo1.lpi` in Lazarus
2. Compilare ed eseguire
3. Inserire il proprio token dell'API nel campo corrispondente
4. Digitare la domanda e fare clic su **Submit** o premere **Invio**

---

## Avviso Importante

L'uso di fornitori cloud come OpenAI, OpenRouter o Cerebras richiede un **abbonamento attivo** e crediti disponibili. L'uso con **Ollama locale** non richiede alcuna chiave API.

---

## Riferimenti

- [Documentazione dell'API OpenAI](https://platform.openai.com/docs/)
- [OpenRouter](https://openrouter.ai/)
- [Ollama](https://ollama.ai/)
- [Cerebras](https://www.cerebras.ai/)
- [Dataset di parole PT-BR](https://github.com/j0aoarthur/Palavras-PT-BR)

---

## Licenza

Questo progetto è rilasciato sotto la [GNU General Public License v3.0](LICENSE).
