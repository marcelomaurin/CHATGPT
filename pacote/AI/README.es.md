# 🧠 Documentación de la Pestaña AI

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI**.

## Núcleo de Inteligencia Artificial y Conectividad Neural.
Proporciona conexiones a modelos de lenguaje (OpenAI) e implementa redes neurais MLP nativas en Pascal.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TCHATGPT** | Conector OpenAI/ChatGPT. | `APIKey, Model, MaxTokens` | `SendQuestion(const AQuestion: string): Boolean` | Procesar NLP y tomar decisiones basadas en texto. |
| **TNeuralNetwork** | Red Neuronal Multicapa nativa. | `InputNodes, HiddenNodes, OutputNodes, LearningRate` | `Train, Predict` | Aprender patrones complejos a partir de conjuntos de dados. |
| **TTokenizer** | Tokenizador de texto. | `LowerCase` | `Tokenize, GetVocabulary` | Preprocesar cadenas de texto en índices numéricos. |

### 💻 Ejemplo de Código Lazarus (TCHATGPT)

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


### ⚡ Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
