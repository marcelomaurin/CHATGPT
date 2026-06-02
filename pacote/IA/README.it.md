# 🧠 Documentazione della Scheda IA

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **IA**.

## Nucleo di Intelligenza Artificiale e Connettività Neurale.
Fornisce connettività ai modelli linguistici (OpenAI) e implementa reti neurali MLP in puro Pascal.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TCHATGPT** | Connettore OpenAI/ChatGPT. | `APIKey, Model, MaxTokens` | `SendQuestion(const AQuestion: string): Boolean` | Elaborare il NLP e prendere decisioni basate sul testo. |
| **TNeuralNetwork** | Rete Neurale Perceptron Multistrato nativa. | `InputNodes, HiddenNodes, OutputNodes, LearningRate` | `Train, Predict` | Apprendere schemi complessi dai set di dati. |
| **TTokenizer** | Tokenizzatore di testo. | `LowerCase` | `Tokenize, GetVocabulary` | Pre-elaborare stringhe grezze in indici numerici. |

### 💻 Esempio di Codice Lazarus (TCHATGPT)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
