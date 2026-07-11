# 🗣️ Documentação da Aba AI Voice

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Voice**.

## Síntese de Voz e Sinais Vocais.
Motores nativos para conversão de texto para voz (TTS) em múltiplos timbres de Pascal.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIVoiceSynthesizer** | Sintetizador de voz. | `Pitch, Rate, Volume` | `Speak(const AText: string): Boolean` | Sintetizar fala natural a partir de relatórios produzidos pelo agente IA. |
| **TAISpeechRecognizer** | Reconhecedor de fala com quatro integrações reais. | `Backend, InputFile, Language, PromptText, WhisperCppModel, SherpaEncoderFile, OpenAIToken, AzureSubscriptionKey` | `Recognize, RecognizeFile, ValidateInputFile, GetSupportedBackends` | Converter áudios gravados em texto auditável usando Whisper.cpp, Sherpa-ONNX, OpenAI ou Azure. |

### 💻 Exemplo de Código Lazarus (TAIVoiceSynthesizer)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!

### Reconhecimento de voz
`TAISpeechRecognizer` foi incluído no pacote para receber arquivos WAV e devolver o texto transcrito por backend, com validação de entrada e fallback controlado.
