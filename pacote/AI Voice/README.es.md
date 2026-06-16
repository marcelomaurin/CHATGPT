# 🗣️ Documentación de la Pestaña AI Voice

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Voice**.

## Síntesis de Voz y Señales Vocales.
Motores nativos para la conversión de texto a voz (TTS) en múltiples timbres en Pascal.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIVoiceSynthesizer** | Sintetizador de voz. | `Pitch, Rate, Volume` | `Speak(const AText: string): Boolean` | Sintetizar el habla natural a partir de los informes de análisis generados por la IA. |

### 💻 Ejemplo de Código Lazarus (TAIVoiceSynthesizer)

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


### ⚡ Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
