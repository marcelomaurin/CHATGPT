# 🗣️ Documentação da Aba IA Voice

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **IA Voice**.

## Síntese de Voz e Sinais Vocais.
Motores nativos para conversão de texto para voz (TTS) em múltiplos timbres de Pascal.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIVoiceSynthesizer** | Sintetizador de voz. | `Pitch, Rate, Volume` | `Speak(const AText: string): Boolean` | Sintetizar fala natural a partir de relatórios produzidos pelo agente IA. |

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
