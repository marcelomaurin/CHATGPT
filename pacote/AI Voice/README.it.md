# 🗣️ Documentazione della Scheda AI Voice

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Voice**.

## Sintesi Vocale ed Elaborazione dei Segnali Vocali.
Motori nativi per la conversione di testo in voce (TTS) in molteplici timbri vocali.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIVoiceSynthesizer** | Sintetizzatore vocale nativo. | `Pitch, Rate, Volume` | `Speak(const AText: string): Boolean` | Sintetizzare voce naturale da testi analitici prodotti dall'agente IA. |

### 💻 Esempio di Codice Lazarus (TAIVoiceSynthesizer)

```pascal
var
  MyComponent: TAIVoiceSynthesizer;
begin
  MyComponent := TAIVoiceSynthesizer.Create(Self);
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
