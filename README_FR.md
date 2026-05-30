# TCHATGPT — Suite de Composants d'IA pour Lazarus

🌍 **Langues / Idiomas:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

Une suite complète de composants visuels et non visuels pour Free Pascal / Lazarus conçue pour intégrer l'**IA générative et l'apprentissage automatique (Machine Learning)** nativement dans vos applications. Elle prend en charge **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras**, les **modèles locaux via Ollama** et des réseaux de neurones locaux.

---

## 📦 Composants Inclus dans le Paquet

La suite installe les outils suivants sous l'onglet **IA** de la palette de composants de Lazarus :

### 1. `TCHATGPT` (Connecteur d'API d'IA)
Le moteur principal pour l'intégration des LLM. Envoyez des questions et recevez des réponses textuelles structurées de fournisseurs mondiaux ou locaux.
- **Fournisseurs Pris en Charge** : OpenAI, Gemini, Claude, OpenRouter, Cerebras et Ollama/Local.
- **Fonctionnalités** : Contrôle de Max Tokens, System/Developer Prompts, température et modèles personnalisés.

### 2. `TNeuralNetwork` (Réseau de Neurones Multicouche)
Un Perceptron Multicouche (MLP) écrit en **Pascal pur**, vous permettant de concevoir et d'entraîner des modèles de réseau de neurones localement sans dépendances externes.
- **Fonctions d'Activation Intégrées** : Sigmoïde (`atSigmoid`), ReLU (`atReLU`), Tanh (`atTanh`) et Personnalisée (`atCustom` via des événements).
- **Entraînement par Époques** : La méthode `TrainEpochs` entraîne les modèles à partir d'une matrice de jeu de données et calcule la perte d'erreur quadratique moyenne (MSE Loss).
- **Persistance** : Sauvegardez et chargez rapidement les poids et biais (`SaveNetwork` / `LoadNetwork`).

### 3. `TAICodeAssistant` (Assistant de Code)
Un assistant virtuel orienté développeur. Il se lie à un composant `TCHATGPT` configuré pour automatiser les tâches de programmation courantes :
- **`OptimizeCode(ACode)`** : Optimise les performances et la lisibilité des routines.
- **`FindBugs(ACode)`** : Recherche les bugs logiques, les fuites de mémoire et recommande des correctifs.
- **`DocumentCode(ACode)`** : Ajoute automatiquement des commentaires explicatifs structurés au format XML/Javadoc.
- **`GenerateUnitTests(ACode)`** : Écrit des tests unitaires complets à l'aide de frameworks comme `FPCUnit`.
- **`TranslateCode(ACode, De, Vers)`** : Traduit du code entre langages (ex: C# vers Pascal).
- **`ExplainCode(ACode)`** : Explique pas à pas le fonctionnement interne d'un algorithme.

### 4. `TAIDatasetGenerator` (Générateur de Datasets d'Entraînement)
Un outil facilitant la préparation des données. Aide à générer des fichiers pour le Fine-Tuning de LLM ou des fichiers de données pour les réseaux de neurones locaux :
- **Fine-Tuning** : Exporte les conversations au format standard **JSONL** (JSON Lines) accepté par OpenAI et Ollama.
- **Intégration du Réseau de Neurones** : Exporte les données au format **CSV** et charge les fichiers CSV délimités directement dans les matrices d'entrée et de sortie (`TMatrix`) compatibles avec `TNeuralNetwork.TrainEpochs`.

### 5. `TTokenList` (Tokeniseur utilitaire)
Utilitaire d'analyse de chaînes pour créer des listes segmentées à partir de collections de texte.

---

## Démarrage Rapide (Assistant de Code)

```pascal
uses chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  CodeOptimise: string;
begin
  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-VOTRE_CLE_ICI';
    FChatgpt.Provider := AIP_CLAUDE;          // Configure Anthropic Claude
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
    
    FAssistant.ChatGPT := FChatgpt; // Lie le connecteur d'IA
    
    CodeOptimise := FAssistant.OptimizeCode('procedure TForm1.Click; begin i := i + 1; end;');
    ShowMessage(CodeOptimise);
  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;
end;
```

---

## Entraînement Local (`TNeuralNetwork` & `TAIDatasetGenerator`)

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
    // Charge les données d'entraînement directement depuis un fichier CSV
    FGen.LoadFromCSV('data.csv', Inputs, Targets, 2, 1); // 2 Entrées, 1 Sortie

    // Initialise le réseau de neurones : 2 Entrées, 4 Cachés, 1 Sortie, Learning Rate = 0.05
    FNet.Initialize(2, 4, 1, 0.05);
    FNet.ActivationType := atSigmoid;

    // Exécute la boucle d'entraînement sur le dataset pendant 1000 époques
    FNet.TrainEpochs(Inputs, Targets, 1000, Loss);
    ShowMessage(Format('Entraînement terminé ! Perte MSE Finale : %0.6f', [Loss]));

    FNet.SaveNetwork('model.net');
  finally
    FGen.Free;
    FNet.Free;
  end;
end;
```

---

## Fournisseurs Pris en Charge (LLMs)

| Fournisseur | Enum | Point de terminaison (Endpoint) | Clé requise | Détails des versions gratuites |
|---|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Oui | Prend en charge `gpt-4o-mini` (bas coût / niveau gratuit de l'API) |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Oui | Plusieurs modèles gratuits avec accès illimité (ex: Llama 3, Gemma 2, DeepSeek R1) |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Oui | Accès gratuit pendant la phase bêta |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Oui | Niveau d'utilisation gratuit généreux (ex: `gemini-2.5-flash`) |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Oui | Jeton payant (développement/tests) |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | Non | **100% Gratuit** et hors ligne (DeepSeek R1, Llama 3.2, etc.) |

---

## Installation du Paquet dans Lazarus

1. Dans l'IDE Lazarus, allez dans **Paquet > Ouvrir un fichier de paquet (.lpk)**
2. Accédez au dossier `pacote/` et sélectionnez **`openai.lpk`**
3. Cliquez sur **Compiler** pour compiler le paquet
4. Cliquez sur **Utiliser > Installer** — Lazarus vous demandera de reconstruire l'IDE
5. Après le redémarrage, les 5 composants seront disponibles sous l'onglet **IA** de la palette de composants.

---

## Configuration Requise des Bibliothèques (Windows)

Pour que la communication HTTPS fonctionne sous Windows, les DLL OpenSSL appropriées pour l'architecture de votre application compilée (32 bits ou 64 bits) doivent être accessibles. La suite comprend déjà les DLL dans le dossier `pacote/lib/` :

*   **Applications 32 bits (i386-win32)** : `pacote/lib/i386-win32/`
    - `libcrypto-1_1.dll`, `libssl-1_1.dll`
*   **Applications 64 bits (x86_64-win64)** : `pacote/lib/x86_64-win64/`
    - `libcrypto.dll`, `libssl-1_1-x64.dll`

**Recommandation :** Copiez les DLL du dossier `lib/` correspondant dans le **même répertoire que votre exécutable compilé**.

---

## Licence

Ce projet est sous licence [GNU General Public License v3.0](LICENSE).
