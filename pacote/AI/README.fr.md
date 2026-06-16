# 🧠 Documentation de l'onglet IA

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **IA**.

## Noyau d'Intelligence Artificielle et Connectivité Neurone.
Fournit une connectivité aux modèles de langage (OpenAI) e implémente des réseaux de neurones MLP en pur Pascal.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TCHATGPT** | Connecteur OpenAI/ChatGPT. | `APIKey, Model, MaxTokens` | `SendQuestion(const AQuestion: string): Boolean` | Traiter le NLP et prendre des décisions textuelles. |
| **TNeuralNetwork** | Réseau de neurones Perceptron Multicouche natif. | `InputNodes, HiddenNodes, OutputNodes, LearningRate` | `Train, Predict` | Apprendre des modèles complexes à partir d'ensembles de données. |
| **TTokenizer** | Tokeniseur de texte. | `LowerCase` | `Tokenize, GetVocabulary` | Prétraiter des chaînes brutes en indices numériques. |

### 💻 Exemple de Code Lazarus (TCHATGPT)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
