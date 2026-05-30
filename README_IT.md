# TCHATGPT — Suite di Componenti di IA per Lazarus

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

Una suite completa di componenti visivi e non visivi per Free Pascal / Lazarus progettata per integrare l'**IA generativa e l'apprendimento automatico (Machine Learning)** nativamente nelle vostre applicazioni. Supporta **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras**, **modelli locali tramite Ollama** e reti neurali locali.

---

## 📦 Componenti Inclusi nel Pacchetto

La suite installa nella tavolozza dei componenti di Lazarus (scheda **IA**) i seguenti strumenti:

### 1. `TCHATGPT` (Connettore per API di IA)
Il motore principale per l'integrazione dei LLM. Invia domande e ricevi risposte testuali strutturate da fornitori globali o locali.
- **Fornitori Supportati**: OpenAI, Gemini, Claude, OpenRouter, Cerebras e Ollama/Local.
- **Funzionalità**: Controllo di Max Tokens, System/Developer Prompts, temperatura e modelli personalizzati.

### 2. `TNeuralNetwork` (Rete Neurale Multistrato)
Un Perceptron Multistrato (MLP) scritto in **Pascal puro**, che consente di progettare e addestrare modelli di rete neurale localmente senza dipendenze esterne.
- **Funzioni di Attivazione Integrate**: Sigmoide (`atSigmoid`), ReLU (`atReLU`), Tanh (`atTanh`) e Personalizzata (`atCustom` tramite eventi).
- **Addestramento per Epoche**: Il metodo `TrainEpochs` addestra i modelli a partire da una matrice di dataset e calcola la perdita di errore quadratico medio (MSE Loss).
- **Persistenza**: Salva e carica rapidamente pesi e bias (`SaveNetwork` / `LoadNetwork`).

### 3. `TAICodeAssistant` (Assistente di Codice)
Un assistente virtuale orientato allo sviluppatore. Si collega ad un componente `TCHATGPT` configurato per automatizzare le attività di programmazione più comuni:
- **`OptimizeCode(ACode)`**: Ottimizza le prestazioni e la leggibilità delle routine.
- **`FindBugs(ACode)`**: Cerca bug logici, perdite di memoria e raccomanda correzioni.
- **`DocumentCode(ACode)`**: Aggiunge automaticamente commenti esplicativi strutturati in formato XML/Javadoc.
- **`GenerateUnitTests(ACode)`**: Scrive unit test completi utilizzando framework come `FPCUnit`.
- **`TranslateCode(ACode, Da, A)`**: Traduce il codice tra linguaggi (es. da C# a Pascal).
- **`ExplainCode(ACode)`**: Spiega passo dopo passo il funzionamento interno di un algoritmo.

### 4. `TAIDatasetGenerator` (Generatore di Datasets di Addestramento)
Uno strumento per facilitare la preparazione dei dati. Aiuta a generare file per il Fine-Tuning di LLM o file di dati per le reti neurali locali:
- **Fine-Tuning**: Esporta le conversazioni nel formato standard **JSONL** (JSON Lines) accettato da OpenAI e Ollama.
- **Integrazione della Rete Neurale**: Esporta i dati in formato **CSV** e carica i file CSV delimitati direttamente nelle matrici di input e output (`TMatrix`) compatibili con `TNeuralNetwork.TrainEpochs`.

### 5. `TTokenList` (Tokenizzatore ausiliario)
Utilità di analisi delle stringhe per creare elenchi segmentati a partire da collezioni di testo.

---

## Guida Rapida (Assistente di Codice)

```pascal
uses chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  CodeOttimizzato: string;
begin
  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-IL_TUO_TOKEN_QUI';
    FChatgpt.Provider := AIP_CLAUDE;          // Configura Anthropic Claude
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
    
    FAssistant.ChatGPT := FChatgpt; // Collega il connettore di IA
    
    CodeOttimizzato := FAssistant.OptimizeCode('procedure TForm1.Click; begin i := i + 1; end;');
    ShowMessage(CodeOttimizzato);
  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;
end;
```

---

## Addestramento Locale (`TNeuralNetwork` & `TAIDatasetGenerator`)

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
    // Carica i dati di addestramento direttamente da un file CSV
    FGen.LoadFromCSV('data.csv', Inputs, Targets, 2, 1); // 2 Ingressi, 1 Uscita

    // Inizializza la rete neurale: 2 Ingressi, 4 Nodi Nascosti, 1 Uscita, Learning Rate = 0.05
    FNet.Initialize(2, 4, 1, 0.05);
    FNet.ActivationType := atSigmoid;

    // Esegue il ciclo di addestramento sul dataset per 1000 epoche
    FNet.TrainEpochs(Inputs, Targets, 1000, Loss);
    ShowMessage(Format('Addestramento completato! Perdita MSE Finale: %0.6f', [Loss]));

    FNet.SaveNetwork('model.net');
  finally
    FGen.Free;
    FNet.Free;
  end;
end;
```

---

## Fornitori Supportati (LLMs)

| Fornitore | Enum | Endpoint | Token Richiesto | Dettagli sulle versioni gratuite |
|---|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Sì | Supporta `gpt-4o-mini` (basso costo / piano API gratuito) |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Sì | Diversi modelli gratuiti con accesso illimitato (es: Llama 3, Gemma 2, DeepSeek R1) |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Sì | Accesso gratuito durante il periodo beta |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Sì | Generoso piano di utilizzo gratuito (es: `gemini-2.5-flash`) |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Sì | Token a pagamento (sviluppo/test) |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | No | **100% Gratuito** ed offline (DeepSeek R1, Llama 3.2, ecc.) |

---

## Installazione del Pacchetto in Lazarus

1. Nell'IDE di Lazarus, andare su **Package > Open Package File (.lpk)**
2. Navigare alla cartella `pacote/` e selezionare **`openai.lpk`**
3. Fare clic su **Compile** per compilare il pacchetto
4. Fare clic su **Use > Install** — Lazarus chiederà di ricompilare l'IDE
5. Dopo il riavvio, i 5 componenti saranno disponibili nella scheda **IA** della tavolozza dei componenti.

---

## Requisiti delle Librerie (Windows)

Affinché la comunicazione HTTPS funzioni correttamente su Windows, le DLL di OpenSSL adeguate per l'architettura della vostra applicazione compilata (32-bit o 64-bit) devono essere accessibili. La suite include già le DLL nella cartella `pacote/lib/`:

*   **Applicazioni a 32-bit (i386-win32)**: `pacote/lib/i386-win32/`
    - `libcrypto-1_1.dll`, `libssl-1_1.dll`
*   **Applicazioni a 64-bit (x86_64-win64)**: `pacote/lib/x86_64-win64/`
    - `libcrypto.dll`, `libssl-1_1-x64.dll`

**Raccomandazione:** Copiare le DLL della cartella `lib/` corrispondente nella **stessa cartella del vostro eseguibile compilato**.

---

## Licenza

Questo progetto è rilasciato sotto la [GNU General Public License v3.0](LICENSE).
