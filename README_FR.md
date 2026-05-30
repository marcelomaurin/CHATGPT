# TCHATGPT — Composant Lazarus pour l'intégration des API d'IA

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

Composant visuel pour Free Pascal / Lazarus permettant d'envoyer des questions et de recevoir des réponses de plusieurs fournisseurs d'IA, notamment **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras** et des **modèles locaux via Ollama**.

## Fonctionnalités

- ✅ Prise en charge de plusieurs fournisseurs (OpenAI, OpenRouter, Cerebras, Ollama/Local, Gemini, Claude)
- ✅ Sélection du modèle par enum ou nom personnalisé
- ✅ Communication via HTTPS avec `TFPHttpClient` (sans dépendance à Indy)
- ✅ Installation en tant que composant dans la palette de Lazarus (onglet **IA**)
- ✅ Composants auxiliaires inclus : `TNeuralNetwork` et `TTokenList`
- ✅ Sous licence GPL v3

---

## Démarrage Rapide

```pascal
uses chatgpt;

var
  FChatgpt: TCHATGPT;
begin
  FChatgpt := TCHATGPT.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-VOTRE_CLE_ICI';
    FChatgpt.Provider := AIP_GEMINI;       // OpenAI, OpenRouter, Cerebras, Local, Gemini ou Claude
    FChatgpt.TipoChat := VCT_GEMINI_25_FLASH; // Modèle souhaité
    FChatgpt.MaxTokens := 4096;            // Limite de jetons dans la réponse

    if FChatgpt.SendQuestion('Quelle est la capitale de la France ?') then
      ShowMessage(FChatgpt.Response)
    else
      ShowMessage('Erreur : ' + FChatgpt.Response);
  finally
    FChatgpt.Free;
  end;
end;
```

---

## Fournisseurs Pris en Charge

| Fournisseur | Enum | Point de terminaison (Endpoint) | Clé requise |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Oui |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Oui |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Oui |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Oui |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Oui |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | Non |

---

## Modèles Disponibles

### OpenAI
| Enum | Modèle d'API |
|---|---|
| `VCT_GPT35TURBO` | `gpt-3.5-turbo` |
| `VCT_GPT40` | `gpt-4` |
| `VCT_GPT40_TURBO` | `gpt-4-turbo-preview` |
| `VCT_GPT4o` | `gpt-4o` |
| `VCT_GPTo3_mini` | `o3-mini` |
| `VCT_GPT41` | `gpt-4.1` |
| `VCT_GPT41_MINI` | `gpt-4.1-mini` |
| `VCT_GPT5` | `gpt-5` |

### Google Gemini (Gratuit & Payant)
| Enum | Modèle API |
|---|---|
| `VCT_GEMINI_25_FLASH` | `gemini-2.5-flash` |
| `VCT_GEMINI_25_PRO` | `gemini-2.5-pro` |
| `VCT_GEMINI_20_FLASH` | `gemini-2.0-flash` |
| `VCT_GEMINI_15_FLASH` | `gemini-1.5-flash` |
| `VCT_GEMINI_15_PRO` | `gemini-1.5-pro` |

### Anthropic Claude (Gratuit & Payant)
| Enum | Modèle API |
|---|---|
| `VCT_CLAUDE_35_SONNET` | `claude-3-5-sonnet-20241022` |
| `VCT_CLAUDE_35_HAIKU` | `claude-3-5-haiku-20241022` |
| `VCT_CLAUDE_3_OPUS` | `claude-3-opus-20240229` |

### Ollama / Local
| Enum | Modèle |
|---|---|
| `VCT_LLAMA32_3B` | `llama3.2:3b` |
| `VCT_QWEN25_15B` | `qwen2.5:1.5b` |
| `VCT_DEEPSEEK_R1_15B` | `deepseek-r1:1.5b` |
| `VCT_DEEPSEEK_R1_8B` | `deepseek-r1:8b` |
| `VCT_DEEPSEEK_R1_14B` | `deepseek-r1:14b` |
| `VCT_DEEPSEEK_R1_70B` | `deepseek-r1:70b` |

> Pour utiliser un autre modèle, définissez `FChatgpt.CustomModel := 'nom-du-modele';`

---

## Propriétés

| Propriété | Type | Description |
|---|---|---|
| `TOKEN` | `WideString` | Clé API du fournisseur |
| `Provider` | `TAIProvider` | Fournisseur d'IA (OpenAI, OpenRouter, Cerebras, Local, Gemini, Claude) |
| `TipoChat` | `TVersionChat` | Modèle d'IA sélectionné |
| `CustomModel` | `WideString` | Nom du modèle personnalisé (remplace TipoChat) |
| `LocalIP` | `WideString` | URL du serveur Ollama local (par défaut : `http://localhost:11434`) |
| `MaxTokens` | `Integer` | Limite de jetons dans la réponse (par défaut : 4096) |
| `Dev` | `WideString` | Prompt système (par défaut : "Vous êtes un assistant.") |
| `Response` | `WideString` | Réponse à la dernière question |
| `Question` | `WideString` | Dernière question envoyée (lecture seule) |
| `LastJSON` | `WideString` | JSON brut de la dernière réponse (lecture seule) |
| `OpenRouterTitle` | `WideString` | Titre de l'application (en-tête pour OpenRouter) |
| `OpenRouterSite` | `WideString` | URL du site (en-tête HTTP-Referer pour OpenRouter) |

---

## Exemple avec Ollama Local

```pascal
FChatgpt := TCHATGPT.Create(nil);
try
  FChatgpt.Provider := AIP_LOCAL;
  FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B;
  FChatgpt.LocalIP := 'http://192.168.1.100:11434';  // IP du serveur

  if FChatgpt.SendQuestion('Expliquez le concept de récursion.') then
    Memo1.Text := FChatgpt.Response;
finally
  FChatgpt.Free;
end;
```

---

## Installation du Paquet dans Lazarus

1. Dans l'IDE Lazarus, allez dans **Paquet > Ouvrir un fichier de paquet (.lpk)**
2. Accédez au dossier `pacote/` et sélectionnez **`openai.lpk`**
3. Cliquez sur **Compiler** pour compiler le paquet
4. Cliquez sur **Utiliser > Installer** — Lazarus vous demandera de reconstruire l'IDE
5. Après le redémarrage, les composants seront disponibles dans l'onglet **IA** de la palette de composants :
   - `TCHATGPT`
   - `TNeuralNetwork`
   - `TTokenList`

---

## Configuration Requise des Bibliothèques (Windows)

Pour que la communication HTTPS fonctionne sous Windows, les DLL OpenSSL suivantes doivent être accessibles par l'application :

- `libcrypto-1_1.dll`
- `libssl-1_1.dll`
- `libssl-1_1-x64.dll` (64 bits)

**Recommandation :** Copiez ces DLL dans le **même répertoire que l'exécutable de votre application** (pas dans `System32`).

Les DLL sont incluses à la racine de ce dépôt pour votre commodité.

---

## Structure du Projet

```
CHATGPT/
├── chatgpt.pas           # Composant principal TCHATGPT
├── funcoes.pas           # Fonctions utilitaires
├── pacote/
│   ├── openai.lpk        # Paquet Lazarus pour l'installation
│   ├── chatgpt.pas       # Copie synchronisée du composant
│   ├── neuralnetwork.pas  # Composant TNeuralNetwork (réseau de neurones simple)
│   ├── tokenizer.pas     # Composant TTokenList (aide au découpage en jetons)
│   └── funcoes.pas       # Copie synchronisée des fonctions utilitaires
├── demo/
│   ├── demo1.lpr         # Application de démonstration
│   └── main.pas          # Formulaire principal de la démo
├── tools/
│   └── script/           # Scripts de support (tokeniseur Python)
├── dicionario/           # Dictionnaire PT-BR
├── LICENSE               # Licence GPL v3
└── README.md             # Documentation en portugais
```

---

## Application de Démonstration

Une application de démonstration complète est disponible dans le dossier `demo/`. Pour l'exécuter :

1. Ouvrez `demo/demo1.lpi` dans Lazarus
2. Compilez et exécutez
3. Sélectionnez le fournisseur d'IA souhaité dans le menu déroulant
4. Sélectionnez le modèle ou définissez un modèle personnalisé
5. Entrez votre clé API dans le champ correspondant
6. Saisissez votre question et cliquez sur **Submit** ou appuyez sur **Entrée**

---

## Avis Important

L'utilisation de fournisseurs cloud comme OpenAI, OpenRouter, Cerebras, Gemini ou Claude nécessite un **abonnement actif** et des crédits disponibles. L'utilisation d'**Ollama local** ne nécessite aucune clé API.

---

## Références

- [Documentation de l'API OpenAI](https://platform.openai.com/docs/)
- [Documentation de l'API Google Gemini](https://ai.google.dev/docs)
- [Documentation de l'API Anthropic Claude](https://docs.anthropic.com/)
- [OpenRouter](https://openrouter.ai/)
- [Ollama](https://ollama.ai/)
- [Cerebras](https://www.cerebras.ai/)
- [Jeu de données de mots PT-BR](https://github.com/j0aoarthur/Palavras-PT-BR)

---

## Licence

Ce projet est sous licence [GNU General Public License v3.0](LICENSE).
