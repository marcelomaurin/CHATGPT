# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌍 **Languages / Langues**

* [Português (PT-BR)](README.md)
* [English (EN)](README_EN.md)
* [Español (ES)](README_ES.md)
* [Français (FR)](README_FR.md)
* [Italiano (IT)](README_IT.md)
* [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow.svg)]()

---

## Vue d’ensemble

**TCHATGPT** est une suite open source de composants visuels et non visuels pour **Lazarus / Free Pascal**, conçue pour faciliter l’intégration de ressources d’Intelligence Artificielle dans des applications de bureau, industrielles, éducatives et professionnelles.

Le projet propose des composants pour la connexion à des fournisseurs de LLM, l’utilisation de modèles locaux, le traitement des données, l’apprentissage automatique, la synthèse vocale, le traitement d’images, les agents, les graphes, les canaux d’entrée et de sortie, ainsi que des composants expérimentaux pour la vision par ordinateur et les ressources graphiques 3D.

> Ce projet doit être compris comme une **suite de composants pour l’intégration de l’IA dans des applications Lazarus**, et non comme une plateforme complète d’IA destinée à remplacer des frameworks spécialisés d’entraînement, des plateformes MLOps ou des infrastructures de déploiement de modèles à grande échelle.

---

## Objectif du projet

L’objectif principal est de permettre aux développeurs Lazarus / Free Pascal d’ajouter des capacités d’IA à leurs systèmes de manière simple, réutilisable et basée sur des composants.

La suite vise à prendre en charge des scénarios tels que :

* assistants avec IA générative ;
* intégration avec des APIs de LLM ;
* utilisation de modèles locaux via des serveurs compatibles ;
* génération et analyse de datasets ;
* classification simple de textes ;
* automatisation basée sur des agents ;
* synthèse vocale ;
* traitement basique d’images ;
* filtres numériques audio ;
* intégration avec des dispositifs, capteurs et canaux externes ;
* prototypage d’applications IA dans Lazarus.

---

## État actuel du projet

Le projet est en développement actif et contient des composants à différents niveaux de maturité.

### Composants les plus consolidés

* `TCHATGPT`
* `TAIBaseComponent`
* `TNeuralNetwork`
* `TTokenList`
* `TAICodeAssistant`
* `TAIDatasetGenerator`
* `TAIVoiceSynthesizer`
* filtres d’image
* filtres audio
* composants de graphes et de datasets

### Composants expérimentaux ou en évolution

* intégration avec Python ;
* composants CNN, YOLO, LSTM et SOM ;
* composants d’agents autonomes ;
* composants avancés d’entrée et de sortie ;
* composants OpenCV ;
* visualisation 3D ;
* intégration avec Tripo3D ;
* composants industriels, caméra, audio, navigateur, MQTT, Modbus et CCTV.

---

## Onglets de composants du paquet

Le paquet installe des composants dans la palette de Lazarus, organisés par domaine fonctionnel.

---

## AI Core

Composants principaux pour l’IA générative, le machine learning et le support du projet.

### `TCHATGPT`

Connecteur principal pour les fournisseurs d’IA générative.

Il permet d’envoyer des prompts, de configurer des fournisseurs, de sélectionner des modèles et de recevoir des réponses structurées.

Fournisseurs prévus ou pris en charge :

* OpenAI ;
* Google Gemini ;
* Anthropic Claude ;
* OpenRouter ;
* Cerebras ;
* serveur local compatible avec `/v1/chat/completions` ;
* Ollama ou services locaux similaires.

### `TNeuralNetwork`

Réseau de neurones multicouche simple implémenté en Pascal.

Il permet de :

* créer des réseaux locaux ;
* configurer les entrées, couches cachées et sorties ;
* entraîner par époques ;
* calculer la perte ;
* sauvegarder et charger des modèles.

### `TTokenList`

Composant utilitaire pour la tokenisation basique de texte.

Il peut être utilisé pour :

* classification ;
* analyse textuelle ;
* prétraitement ;
* graphes de décision ;
* préparation de datasets.

### `TAICodeAssistant`

Assistant de code basé sur un LLM.

Il peut être utilisé pour :

* réviser du code ;
* suggérer des améliorations ;
* générer des commentaires ;
* expliquer des blocs de code ;
* assister dans les tests ;
* convertir ou documenter des routines.

### `TAIDatasetGenerator`

Générateur de datasets pour l’entraînement, le fine-tuning ou la classification locale.

Il prend en charge ou vise à prendre en charge des structures telles que :

* CSV ;
* JSON ;
* JSONL ;
* matrices d’entrée et de sortie pour l’entraînement local.

### `TAIModelRegistry`

Registre central des modèles, fournisseurs, endpoints et paramètres.

Il aide à organiser :

* nom du modèle ;
* fournisseur ;
* endpoint ;
* température ;
* limite de tokens ;
* paramètres par défaut.

### `TAIWizardConfig`

Assistant de configuration pour de nouveaux projets d’IA.

Il peut être utilisé pour préparer des projets tels que :

* chatbot ;
* classificateur ;
* pipeline ;
* agent ;
* assistant technique.

---

## AI Sound Filters

Composants pour le traitement numérique du signal et le filtrage audio.

### `TLowPassFilter`

Filtre passe-bas IIR de premier ordre.

Utilisé pour lisser les variations rapides et réduire le bruit haute fréquence.

### `THighPassFilter`

Filtre passe-haut IIR de premier ordre.

Utilisé pour supprimer les composants basse fréquence, l’offset ou le bruit DC.

### `TAverageFilter`

Filtre de moyenne mobile.

Utilisé pour un lissage simple des signaux.

### `TFDMMultiplexer`

Composant de multiplexage par répartition en fréquence.

Permet de simuler des canaux dans différentes bandes de fréquence.

### `TTDMMultiplexer`

Composant de multiplexage par répartition dans le temps.

Permet d’intercaler des canaux par créneaux temporels.

### `TCDMMultiplexer`

Multiplexeur CDM/CDMA.

Utilise des codes orthogonaux pour séparer les signaux.

### `TOFDMMultiplexer`

Multiplexeur OFDM utilisant FFT/IFFT.

Utile pour les études et simulations de télécommunications.

---

## AI Image

Composants pour le traitement basique d’images.

### `TGrayscaleFilter`

Convertit les images en niveaux de gris.

### `TNegativeFilter`

Applique une inversion des couleurs.

### `TBrightnessContrastFilter`

Ajuste la luminosité et le contraste.

### `TBinarizationFilter`

Applique un seuillage pour produire des images en noir et blanc.

### `TBlurFilter`

Applique un lissage par convolution.

### `TSharpenFilter`

Améliore la netteté à l’aide d’un noyau de convolution.

### `TSobelFilter`

Détecte les contours à l’aide de l’opérateur Sobel.

### `TErosionDilationFilter`

Réalise des opérations morphologiques d’érosion et de dilatation.

---

## AI Schedule

Composants pour l’organisation, la persistance et la gestion des dépendances de tâches.

### `TJSONGroupStorage`

Composant de stockage de données groupées en JSON.

Il peut être utilisé pour :

* sauvegarder des configurations ;
* persister des paramètres ;
* stocker des textes ;
* organiser des données par groupes.

### `TIASchedule`

Gestionnaire de tâches avec contrôle des dépendances.

Il permet de modéliser :

* tâche parente ;
* tâche enfant ;
* dépendances ;
* état de disponibilité ;
* contrôle simple d’exécution.

---

## AI Voice

Composants de synthèse vocale.

### `TAIVoiceSynthesizer`

Composant Text-to-Speech.

Sous Windows, il peut utiliser SAPI.
Sous Linux, il peut utiliser eSpeak/eSpeak-NG.

Fonctionnalités principales :

* lire un texte à voix haute ;
* ajuster le volume ;
* ajuster la vitesse ;
* lister les voix disponibles ;
* exécution asynchrone ;
* intégration avec des applications de bureau.

---

## AI Agent

Composants pour agents intelligents et prise de décision structurée.

### `TAIAgent`

Composant orchestrateur de l’agent.

Il permet d’envoyer des instructions à un LLM, d’interpréter des réponses structurées et de coordonner des actions.

### `TAIAgentOptions`

Stocke le contexte, les questions, les directives et les règles d’analyse.

### `TAIAgentAction`

Définit les actions autorisées pour l’agent.

Il permet de configurer :

* actions disponibles ;
* paramètres attendus ;
* callbacks d’exécution.

### `TAIAgentResource`

Représente des ressources externes pouvant être déclenchées par l’agent.

Exemples :

* fichiers ;
* e-mail ;
* HTTP ;
* SMS ;
* WhatsApp ;
* TCP/UDP ;
* Web APIs.

### `TAIAgentOutput`

Couche de sortie reliant les décisions de l’agent aux ressources réelles du système.

---

## AI Graph

Composants pour la structuration de données, les graphes et les datasets.

### `TAIGraphMap`

Graphe pondéré pour la classification et l’analyse basée sur les tokens.

Il peut être utilisé pour :

* classification textuelle ;
* regroupement de concepts ;
* relations entre termes ;
* analyse simple de sujets.

### `TAITrainingExporter`

Exportateur de données d’entraînement.

Formats prévus ou pris en charge :

* CSV ;
* JSON ;
* JSONL ;
* ARFF ;
* vecteurs numériques.

### `TAIDatasetAnalyzer`

Analyseur de qualité de dataset.

Il peut détecter :

* catégories vides ;
* doublons ;
* déséquilibre des classes ;
* textes très courts ;
* textes très longs.

### `TAITrainingReport`

Générateur de rapports techniques d’entraînement.

Il peut enregistrer :

* précision ;
* erreur ;
* perte ;
* nombre de tokens ;
* confiance moyenne ;
* statistiques du dataset.

### `TAIGraphVisualizer`

Exportateur et visualiseur de graphes.

Formats prévus ou pris en charge :

* DOT / GraphViz ;
* Mermaid ;
* JSON de visualisation.

---

## AI Input

Composants pour l’entrée de données et l’intégration avec des sources externes.

Cet onglet regroupe les composants axés sur la capture d’informations, la communication et l’intégration avec des dispositifs ou systèmes.

Composants prévus ou en évolution :

* caméra ;
* audio ;
* serveur web ;
* sockets ;
* communication série ;
* imprimante POS ;
* CCTV/IP ;
* Modbus ;
* MQTT ;
* e-mail ;
* messagerie ;
* capture du système d’exploitation ;
* navigateur intégré ;
* entrées industrielles.

> Certains composants de cet onglet peuvent nécessiter des bibliothèques externes, des pilotes, des autorisations du système d’exploitation ou des services supplémentaires.

---

## AI Output

Composants pour la sortie de données, la génération de documents et l’intégration avec des destinations externes.

Ressources prévues ou en évolution :

* génération de documents ;
* exportation de réponses ;
* sortie structurée ;
* intégration avec des canaux externes ;
* automatisation des réponses.

---

## AI Vision

Composants pour la vision par ordinateur.

Composants prévus ou en évolution :

* OpenCV ;
* capture caméra ;
* traitement de frames ;
* suivi facial ;
* suivi de mouvement ;
* classification d’images ;
* détection d’objets.

> Cette zone doit être considérée comme expérimentale jusqu’à ce que les composants disposent de démonstrations complètes, de dépendances documentées et de tests d’intégration.

---

## AI Graphic

Composants graphiques et 3D liés à l’IA, à la simulation et à la visualisation.

Composants prévus ou en évolution :

* scène 2D/3D ;
* environnement d’entraînement ;
* simulateur physique ;
* capteurs virtuels ;
* fonction de récompense ;
* visualisation de modèles 3D ;
* rig de squelette ;
* contrôleur d’avatar ;
* bibliothèque de poses ;
* séquence d’animation ;
* intégration avec génération de modèles 3D.

### `TAI3DModelViewer`

Visualiseur de modèles 3D.

Objectif :

* charger des modèles 3D ;
* afficher des maillages ;
* faire pivoter ;
* zoomer ;
* dézoomer ;
* alterner entre mode solide, filaire et points.

### `TAITripo3DClient`

Client pour l’intégration avec un service externe de génération de modèles 3D.

Objectif :

* générer un modèle à partir d’un texte ;
* générer un modèle à partir d’une image ;
* générer un modèle à partir de plusieurs images ;
* télécharger le modèle 3D obtenu.

> L’intégration avec des services externes doit être validée conformément à la documentation officielle de l’API du fournisseur utilisé.

---

## Installation du paquet dans Lazarus

1. Ouvrez Lazarus.
2. Accédez à **Package > Open Package File (.lpk)**.
3. Sélectionnez le fichier `pacote/packages/openai_core.lpk`.
4. Cliquez sur **Compile**.
5. Cliquez ensuite sur **Use > Install**.
6. Lazarus demandera de reconstruire l’IDE.
7. Après le redémarrage, les composants apparaîtront dans la palette de composants.

---

## Fournisseurs de LLM

| Fournisseur                 | Enum             | Type                     |
| --------------------------- | ---------------- | ------------------------ |
| OpenAI                      | `AIP_OPENAI`     | API externe              |
| OpenRouter                  | `AIP_OPENROUTER` | API externe / agrégateur |
| Cerebras                    | `AIP_CEREBRAS`   | API externe              |
| Google Gemini               | `AIP_GEMINI`     | API externe              |
| Anthropic Claude            | `AIP_CLAUDE`     | API externe              |
| Local / Ollama / compatible | `AIP_LOCAL`      | Serveur local            |

> Les noms de modèles, limites, coûts et disponibilités peuvent changer selon chaque fournisseur. Consultez toujours la documentation officielle du service utilisé.

---

## Prérequis

### Environnement principal

* Lazarus 3.x ou supérieur ;
* version compatible de Free Pascal ;
* Windows ou Linux ;
* paquet `openai_core.lpk` ;
* connexion internet pour les fournisseurs externes ;
* serveur local configuré lorsque des modèles hors ligne sont utilisés.

### Windows

Pour la communication HTTPS, des DLL OpenSSL compatibles avec l’architecture de l’application peuvent être nécessaires.

Vérifiez le dossier `pacote/lib/`.

Il est recommandé de copier les DLL nécessaires dans le même dossier que l’exécutable final.

### Linux

Selon les composants utilisés, des paquets supplémentaires peuvent être nécessaires, tels que :

* OpenSSL ;
* eSpeak/eSpeak-NG ;
* libpython ;
* bibliothèques caméra ou audio ;
* bibliothèques spécifiques pour la vision par ordinateur.

Les prérequis peuvent varier selon le composant utilisé.

---

## Screenshots

> Les images ci-dessous présentent des fonctionnalités déjà testées ou actuellement en développement.
> Les nouveaux composants peuvent ne pas encore disposer de démonstrations visuelles complètes.

### CNN Demo

![CNN Demo](screenshots/cnn_demo.jpg)

Démonstration de classification d’images.

### Math Input / Output Demo

![Math Input Output Demo](screenshots/math_input_output_demo.jpg)

Démonstration de composants mathématiques.

### Python Connector Demo

![Python Demo](screenshots/python_demo.jpg)

Démonstration d’intégration avec Python.

### SOM Demo

![SOM Demo](screenshots/som_demo.jpg)

Démonstration de carte auto-organisatrice.

### Sound Filters Demo

![Sound Filters](screenshots/sound_filters.jpg)

Démonstration de filtres audio.

### Voice Synthesizer Demo

![Voice Synthesizer](screenshots/voicesynthesizer.jpg)

Démonstration de synthèse vocale.

---

## Limitations connues

Le projet est encore en développement et contient des composants à différents niveaux de stabilité.

Limitations actuelles attendues :

* certains composants peuvent encore être expérimentaux ;
* tous les composants ne disposent pas de démonstrations complètes ;
* les intégrations externes dépendent d’APIs tierces ;
* les composants de vision par ordinateur peuvent nécessiter des bibliothèques externes ;
* les composants Python dépendent de versions et d’architectures compatibles ;
* chaque composant doit être validé avant une utilisation en production ;
* les tests automatisés et l’intégration continue doivent encore être étendus.

---

## Roadmap

### Court terme

* revoir la documentation des composants ;
* standardiser les noms des onglets en anglais ;
* séparer les composants stables et expérimentaux ;
* ajouter des démonstrations minimales pour chaque composant ;
* valider la compilation du paquet sous Windows et Linux ;
* corriger les incohérences entre le README et le code source.

### Moyen terme

* créer des tests automatisés ;
* créer un pipeline avec `lazbuild` ;
* créer des releases versionnées ;
* documenter les dépendances externes ;
* améliorer la gestion des erreurs ;
* créer des démonstrations réelles avec LLM, voix, image et agents.

### Long terme

* créer des modèles de projets ;
* créer un assistant visuel de configuration d’IA ;
* consolider les composants OpenCV ;
* consolider les composants 3D ;
* améliorer l’intégration avec les modèles locaux ;
* faire évoluer les agents avec un contrôle de sécurité ;
* créer une documentation complète pour une utilisation en production.

---

## À qui s’adresse ce projet ?

Ce projet est adapté pour :

* développeurs Lazarus ;
* développeurs Free Pascal ;
* enseignants et étudiants ;
* projets desktop avec IA ;
* automatisation locale ;
* systèmes professionnels existants ;
* applications éducatives ;
* prototypes d’IA ;
* intégration de l’IA avec des dispositifs ;
* systèmes qui nécessitent de l’IA sans migrer toute la base de code vers Python ou JavaScript.

---

## À qui ce projet ne s’adresse pas encore ?

À ce stade, le projet ne remplace pas :

* frameworks complets de machine learning ;
* plateformes MLOps ;
* pipelines professionnels d’entraînement ;
* services professionnels de déploiement de modèles ;
* bibliothèques spécialisées comme PyTorch, TensorFlow, scikit-learn ou OpenCV complet ;
* infrastructures d’IA à l’échelle entreprise.

---

## Contribution

Les contributions sont les bienvenues.

Domaines prioritaires de contribution :

* correction de bugs ;
* démonstrations fonctionnelles ;
* documentation ;
* tests automatisés ;
* compatibilité Windows/Linux ;
* icônes et screenshots ;
* validation des composants ;
* amélioration de la gestion des erreurs ;
* intégration avec les fournisseurs d’IA ;
* démos pour chaque onglet de composants Lazarus.

---

## Licence

Ce projet est sous licence **GNU General Public License v3.0**.

Consultez le fichier `LICENSE`.

---

## Avis

Ce projet utilise ou intègre des services externes d’IA.
L’utilisation de ces services peut impliquer des coûts, des limites d’API, des politiques propres aux fournisseurs et la transmission de données à des tiers.

Avant une utilisation en production :

* vérifiez les conditions du fournisseur ;
* protégez vos clés d’API ;
* n’envoyez pas de données sensibles sans autorisation ;
* validez la sécurité, la confidentialité et la conformité ;
* testez le comportement du composant dans l’environnement réel.

---

## Conclusion

**TCHATGPT** est une suite prometteuse pour apporter des ressources d’IA à l’écosystème Lazarus / Free Pascal.

Sa plus grande valeur est d’offrir un pont pratique entre les applications traditionnelles et les ressources modernes d’IA, permettant aux systèmes desktop, industriels, éducatifs et professionnels d’incorporer des LLMs, de la voix, de l’image, des graphes, de l’automatisation et des modèles locaux de manière componentisée.

Le projet est encore en évolution, mais il possède déjà une base importante pour devenir une référence open source de composants IA pour Lazarus.
