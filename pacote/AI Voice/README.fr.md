# 🗣️ Documentation de l'onglet AI Voice

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Voice**.

## Synthèse Vocale et Traitement des Signaux de Parole.
Moteurs natifs pour la conversion de texte en parole (TTS) dans plusieurs timbres vocaux.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIVoiceSynthesizer** | Synthétiseur de voix et de parole. | `Pitch, Rate, Volume` | `Speak(const AText: string): Boolean` | Synthétiser une parole naturelle à partir de rapports d'analyse de l'IA. |

### 💻 Exemple de Code Lazarus (TAIVoiceSynthesizer)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
