# 🧠 Documentação da Aba IA

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **IA**.

## Núcleo de Inteligência Artificial e Conectividade Neural.
Fornece conexões a modelos de linguagem (OpenAI) e implementa redes neurais MLP de Pascal puro.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TCHATGPT** | Conector OpenAI/ChatGPT. | `APIKey, Model, MaxTokens` | `SendQuestion(const AQuestion: string): Boolean` | Processar NLP e tomar decisões baseadas em texto. |
| **TNeuralNetwork** | Rede Neural Multicamadas nativa. | `InputNodes, HiddenNodes, OutputNodes, LearningRate` | `Train, Predict` | Aprender padrões complexos a partir de conjuntos de dados. |
| **TTokenizer** | Tokenizador de texto. | `LowerCase` | `Tokenize, GetVocabulary` | Pré-processar strings brutos em índices numéricos. |

### 💻 Exemplo de Código Lazarus (TCHATGPT)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
