# TCHATGPT — Suite de Composants IA pour Lazarus / Free Pascal

🌐 **Langues / Idiomas**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md) • [العربية](README_AR.md) • [中文](README_CH.md) • [Русский](README_RU.md) • [日本語](README_JP.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 1. Objectif du Projet

**TCHATGPT** (développé par [Maurinsoft](https://maurinsoft.com.br)) est une suite modulaire de composants visuels et non visuels en **Object Pascal (Free Pascal / Lazarus)** pour l'intégration directe et native de l'Intelligence Artificielle moderne, de la Vision par Ordinateur, du Traitement Vocal, des Agents Autonomes, de l'Automatisation Industrielle, du Matériel et de la Gestion de Projet.

L'objectif central est de permettre aux développeurs desktop et embarqués d'intégrer des fonctionnalités d'IA de pointe directement en code natif, avec :
1. **Contrôle Total et Faible Latence :** Sans dépendre de serveurs intermédiaires ni de frameworks web lourds.
2. **Connectivité Hybride :** Prise en charge des LLMs cloud (OpenAI, Claude, Gemini, Ollama) et de l'inférence locale 100% hors ligne via [`llama.cpp`](pacote/AI%20LlamaCpp/).
3. **Agents Autonomes et Outils :** Architecture d'agents capables d'exécuter du code, d'interagir avec des bases de données, de consulter des fichiers, de contrôler des robots et de collaborer via les protocoles [A2A](pacote/AI%20A2A/) et [MCP](pacote/AI%20MCP/).
4. **Interaction avec le Monde Réel :** Périphériques USB, ports série, capteurs Kinect, manettes, automates Modbus, courtiers MQTT et émulation de micrologiciel Marlin CNC/imprimante 3D.

---

## 📦 2. Catalogue des Paquets : Finalité et Statut

Le tableau ci-dessous présente la **finalité conceptuelle** de chaque paquet (ce qu'il manipule, traite ou contrôle) et son niveau de maturité actuel :

| Paquet Lazarus | Dossier Source | Finalité (Ce qu'il manipule / fait) | Statut Actuel |
|---|---|---|---|
| [**`openai_core.lpk`**](pacote/packages/openai_core.lpk) | [`pacote/AI/`](pacote/AI/) | Connecte aux APIs LLM (OpenAI, Claude, Gemini, Ollama), gère les jetons, prompts, modèles et fournit les classes de base. | **Stable / Beta** |
| [**`openai_agent.lpk`**](pacote/packages/openai_agent.lpk) | [`pacote/AI Agent/`](pacote/AI%20Agent/) | Orchestre les agents autonomes, les appels d'outils (tool calling), la mémoire factuelle et les filtres de sécurité. | **Stable / Beta**; pipelines composites *Experimental* |
| [**`openai_a2a.lpk`**](pacote/packages/openai_a2a.lpk) | [`pacote/AI A2A/`](pacote/AI%20A2A/) | Standardise la communication et l'échange de messages structurés directement entre différents agents sur le réseau (Agent-to-Agent). | **Stable / Beta** |
| [**`openai_mcp.lpk`**](pacote/packages/openai_mcp.lpk) | [`pacote/AI MCP/`](pacote/AI%20MCP/) | Implémente le standard ouvert Model Context Protocol (Anthropic/OpenAI) en client et serveur JSON-RPC pour exposer des outils. | **Stable / Beta** |
| [**`openai_input.lpk`**](pacote/packages/openai_input.lpk) | [`pacote/AI Input/`](pacote/AI%20Input/) | Capture les données du monde extérieur : manettes XInput/WinMM, empreintes vocales, caméras, capteurs Kinect, ports série, sockets TCP/UDP, serveurs web et documents locaux. | **Stable / Beta**; intégration hardware_net_demo *Experimental* |
| [**`openai_output.lpk`**](pacote/packages/openai_output.lpk) | [`pacote/AI Output/`](pacote/AI%20Output/) | Génère des documents Word (DOCX/OpenXML), feuilles Excel (XLSX), PDFs, texte brut, JSON structuré et tickets thermiques POS. | **Stable / Beta** |
| [**`openai_vision.lpk`**](pacote/packages/openai_vision.lpk) | [`pacote/AI Vision/`](pacote/AI%20Vision/) | Traite les flux vidéo et images via OpenCV ou méthodes natives : détection faciale, suivi de mouvement et estimation de postures. | **Stable / Beta** |
| [**`openai_image.lpk`**](pacote/packages/openai_image.lpk) | [`pacote/AI Image/`](pacote/AI%20Image/) | Applique des filtres et manipulations d'images directement en Pascal natif, sans bibliothèques externes. | **Stable / Beta** |
| [**`openai_voice.lpk`**](pacote/packages/openai_voice.lpk) | [`pacote/AI Voice/`](pacote/AI%20Voice/) | Traite l'audio parlé : synthèse vocale (TTS), transcription de la parole en texte (STT) et filtres acoustiques. | **Stable / Beta** |
| [**`openai_project.lpk`**](pacote/packages/openai_project.lpk) | [`pacote/AI Project/`](pacote/AI%20Project/) | Rend des vues visuelles de gestion : diagrammes de Gantt interactifs, réseaux PERT/CPM, tableaux Kanban et histogrammes d'équipe. | **Stable / Beta** |
| [**`openai_project_core.lpk`**](pacote/packages/openai_project_core.lpk) | [`pacote/AI Project Core/`](pacote/AI%20Project%20Core/) | Exécute les calculs mathématiques d'ordonnancement : calcule le chemin critique (CPM), valide les graphes acycliques et gère les calendriers ouvrés. | **Stable / Beta** |
| [**`openai_industrial.lpk`**](pacote/packages/openai_industrial.lpk) | [`pacote/AI Industrial/`](pacote/AI%20Industrial/) | Communique avec les équipements industriels via Modbus TCP/RTU, broker MQTT, pinmap Arduino et contrôle de bras robotisés. | **Stable / Beta** |
| [**`openai_marlin.lpk`**](pacote/packages/openai_marlin.lpk) | [`pacote/AI Simulation/AIMarlin/`](pacote/AI%20Simulation/AIMarlin/) | Émule le micrologiciel d'imprimantes 3D et CNC Marlin, interprète les commandes G-Code et fournit des ports série virtuels. | **Stable / Beta** |
| [**`openai_simulation.lpk`**](pacote/packages/openai_simulation.lpk) | [`pacote/AI Simulation/`](pacote/AI%20Simulation/) | Exécute des simulations 2D basées sur des automates cellulaires, des files d'attente et le déplacement de robots mobiles. | **Stable / Beta** |
| [**`openai_graphic.lpk`**](pacote/packages/openai_graphic.lpk) | [`pacote/AI Graphic/`](pacote/AI%20Graphic/) | Manipule des objets graphiques 3D OpenGL, des avatars virtuels avec synchronisation labiale, des squelettes et des scènes physiques. | **Stable / Beta** |
| [**`openai_hardware.lpk`**](pacote/packages/openai_hardware.lpk) | [`pacote/AI Hardware/`](pacote/AI%20Hardware/) | Collecte la télémétrie du système d'exploitation et du matériel : utilisation processeur (CPU), RAM, disques, GPUs et processus. | **Stable / Beta** |
| [**`openai_graph.lpk`**](pacote/packages/openai_graph.lpk) | [`pacote/AI Graph/`](pacote/AI%20Graph/) | Construit, analyse et visualise des graphes de dépendances logiques, réseaux de connaissances et profils de routes GeoJSON. | **Stable / Beta** |
| [**`openai_llamacpp.lpk`**](pacote/packages/openai_llamacpp.lpk) | [`pacote/AI LlamaCpp/`](pacote/AI%20LlamaCpp/) | Exécute des modèles LLM localement et en toute confidentialité grâce au runtime `llama.cpp` x64 au format GGUF sans internet. | **Stable / Beta** |
| [**`openai_ml.lpk`**](pacote/packages/openai_ml.lpk) | [`pacote/AI Math/`](pacote/AI%20Math/) | Exécute des algorithmes d'apprentissage automatique classiques (réseaux de neurones, perceptrons, cartes SOM) et d'algèbre (NUMPS) en Pascal pur. | **Stable / Beta** |
| [**`openai_python.lpk`**](pacote/packages/openai_python.lpk) | [`pacote/python/`](pacote/python/) | Intègre des environnements Python pour exécuter des modèles d'apprentissage profond (YOLOv8, CNNs, LSTMs) couplés à Lazarus. | **Stable / Beta** |
| [**`openai_rag.lpk`**](pacote/packages/openai_rag.lpk) | [`pacote/AI RAG/`](pacote/AI%20RAG/) | Effectue de la recherche sémantique et de la génération augmentée (RAG), indexant des collections de documents pour les LLMs. | **Stable / Beta** |
| [**`openai_dbase.lpk`**](pacote/packages/openai_dbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Se connecte aux bases relationnelles pour conserver l'historique des échanges, journaux d'audit et la mémoire d'IA via ZeosLib. | **Stable / Beta** |
| [**`openai_aidbase.lpk`**](pacote/packages/openai_aidbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Extrait des dictionnaires de données et des métadonnées SQL pour formuler des requêtes avec exactitude. | **Stable / Beta** |
| [**`openai_files.lpk`**](pacote/packages/openai_files.lpk) | [`pacote/AI Files/`](pacote/AI%20Files/) | Analyse et indexe les arborescences de répertoires sur disque, générant des jeux de données structurés. | **Stable / Beta** |
| [**`openai_observability.lpk`**](pacote/packages/openai_observability.lpk) | [`pacote/AI Observability/`](pacote/AI%20Observability/) | Surveille les opérations d'IA : trace les appels, mesure la latence, audite la consommation de jetons et signale les erreurs. | **Stable / Beta** |
| [**`openai_evaluation.lpk`**](pacote/packages/openai_evaluation.lpk) | [`pacote/AI Evaluation/`](pacote/AI%20Evaluation/) | Évalue la précision des réponses d'IA au moyen de juges automatisés (LLM-as-a-judge) et de rapports de régression. | **Stable / Beta** |
| [**`openai_integration.lpk`**](pacote/packages/openai_integration.lpk) | [`pacote/AI/`](pacote/AI/) | Relie plusieurs composants au sein de pipelines de traitement unifiés et d'exécuteurs chaînés. | **Stable / Beta** |
| [**`openai_webrtc.lpk`**](pacote/packages/openai_webrtc.lpk) | [`pacote/AI Communication/`](pacote/AI%20Communication/) | Établit des canaux de données poste à poste à faible latence (WebRTC DataChannel) à l'aide de libdatachannel. | **Stable / Beta** |

---

## 📂 3. Organisation des Dossiers du Répertoire

Voici le rôle de chaque dossier du projet, son contenu et son utilité pratique :

| Dossier | Rôle du Répertoire | Ce qu'il contient | Utilité Pratique (Pourquoi l'utiliser) |
|---|---|---|---|
| [**`pacote/AI/`**](pacote/AI/) | Infrastructure de base | Classes fondamentales ([`aibase.pas`](pacote/AI/aibase.pas)), clients LLM ([`chatgpt.pas`](pacote/AI/chatgpt.pas), [`aiclaude.pas`](pacote/AI/aiclaude.pas), [`aigemini.pas`](pacote/AI/aigemini.pas), [`aiollama.pas`](pacote/AI/aiollama.pas)), compteurs de jetons et routeurs. | Centralise les communications HTTP/REST avec les fournisseurs d'IA et fournit la base architecturale partagée. |
| [**`pacote/AI Agent/`**](pacote/AI%20Agent/) | Orchestration d'Agents Autonomes | Modules d'agents ([`aiagent.pas`](pacote/AI%20Agent/aiagent.pas)), mémoire déterministe, cartes conceptuelles, filtres de sécurité et autoréparation de code. | Permet de créer des agents capables de raisonner en plusieurs étapes, d'appeler du code Pascal ou de consulter des données. |
| [**`pacote/AI A2A/`**](pacote/AI%20A2A/) | Protocole Agent-to-Agent | Protocole de communication et messagerie entre agents d'IA ([`aia2a_client.pas`](pacote/AI%20A2A/aia2a_client.pas)). | Permet à plusieurs agents de collaborer, de déléguer des tâches et de partager un contexte structuré sur le réseau. |
| [**`pacote/AI MCP/`**](pacote/AI%20MCP/) | Model Context Protocol | Implémentation client et serveur MCP sur JSON-RPC ([`aimcp_client.pas`](pacote/AI%20MCP/aimcp_client.pas), [`aimcp_server.pas`](pacote/AI%20MCP/aimcp_server.pas)). | Permet aux LLMs d'interagir directement avec les outils et données du système via le standard ouvert MCP. |
| [**`pacote/AI Input/`**](pacote/AI%20Input/) | Périphériques et Sources d'Entrée | Manettes ([`aijoystick.pas`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), audio ([`aispeakersignature.pas`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Kinect ([`aikinectsensor.pas`](pacote/AI%20Input/AIKinect/aikinectsensor.pas)), USB, Série, Sockets, Serveur Web et lecteurs de documents. | Capture et normalise les entrées physiques (capteurs, réseau, manettes, fichiers) pour alimenter les flux d'IA. |
| [**`pacote/AI Output/`**](pacote/AI%20Output/) | Génération de Sorties Structurées | Générateurs Word ([`aiworddocument.pas`](pacote/AI%20Output/aiworddocument.pas)), classeurs Excel ([`aixlsxwriter.pas`](pacote/AI%20Output/aixlsxwriter.pas)), imprimantes thermiques POS ([`aiposprinter.pas`](pacote/AI%20Output/aiposprinter.pas)) et formateurs JSON. | Produit des sorties physiques (tickets de caisse) ou des fichiers formatés à partir des résultats d'IA. |
| [**`pacote/AI Vision/`**](pacote/AI%20Vision/) | Vision par Ordinateur | Connecteur OpenCV ([`aiopencv.pas`](pacote/AI%20Vision/aiopencv.pas)), suivi de visage ([`aifacetracker.pas`](pacote/AI%20Vision/aifacetracker.pas)), suivi de mouvement ([`aimotiontracker.pas`](pacote/AI%20Vision/aimotiontracker.pas)), estimation de pose ([`aihumanposedetector.pas`](pacote/AI%20Vision/aihumanposedetector.pas)) et traitement d'images. | Analyse les flux vidéo pour la reconnaissance visuelle en temps réel et le suivi de personnes ou d'objets. |
| [**`pacote/AI Voice/`**](pacote/AI%20Voice/) | Voix, Reconnaissance et Synthèse | Synthétiseur vocal TTS ([`aivoicesynthesizer.pas`](pacote/AI%20Voice/aivoicesynthesizer.pas)), reconnaissance STT ([`aispeechrecognizer.pas`](pacote/AI%20Voice/aispeechrecognizer.pas)), assistants et clonage vocal. | Permet à l'application de s'exprimer vocalement et de comprendre les ordres dictés au microphone. |
| [**`pacote/AI Project Core/`**](pacote/AI%20Project%20Core/) | Cœur Mathématique de Projets | Ordonnanceur CPM ([`aicpmscheduler.pas`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), graphe acyclique de tâches ([`aitaskgraph.pas`](pacote/AI%20Project%20Core/aitaskgraph.pas)), calendrier de travail ([`aiworkcalendar.pas`](pacote/AI%20Project%20Core/aiworkcalendar.pas)) et nivellement des ressources. | Calcule les plannings, marges et chemins critiques de façon autonome, utilisable en interface graphique ou en service console. |
| [**`pacote/AI Project/`**](pacote/AI%20Project/) | Vues Visuelles de Projets (LCL) | Vues interactives : diagramme de Gantt ([`aiganttview.pas`](pacote/AI%20Project/aiganttview.pas)), réseau PERT ([`ainetworkview.pas`](pacote/AI%20Project/ainetworkview.pas)), tableau Kanban ([`aiboardview.pas`](pacote/AI%20Project/aiboardview.pas)) et histogramme des ressources ([`airesourceview.pas`](pacote/AI%20Project/airesourceview.pas)). | Affiche des composants graphiques interactifs pour la planification visuelle de tâches. |
| [**`pacote/AI Industrial/`**](pacote/AI%20Industrial/) | Automatisation et Réseaux Industriels | Client Modbus TCP/RTU ([`aimodbus.pas`](pacote/AI%20Industrial/aimodbus.pas)), client MQTT ([`aimqtt.pas`](pacote/AI%20Industrial/aimqtt.pas)), cinématique de bras robotisé ([`aiarm_robot.pas`](pacote/AI%20Industrial/aiarm_robot.pas)) et plan de broches Arduino. | Relie les applications Lazarus aux lignes de production, lisant les automates et commandant des actionneurs physiques. |
| [**`pacote/AI Simulation/`**](pacote/AI%20Simulation/) | Simulation 2D et Émulation Marlin | Moteur cellulaire 2D en grille ([`aisimulationengine.pas`](pacote/AI%20Simulation/aisimulationengine.pas)), files d'attente et émulateur Marlin G-code ([`aimarlinsimulator.pas`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas)). | Simule des scénarios logistiques et valide les trajectoires CNC avant exécution sur de vraies machines. |
| [**`pacote/AI Graphic/`**](pacote/AI%20Graphic/) | Graphismes 3D et Avatars | Visionneuse 3D OpenGL ([`ai3dmodelviewer.pas`](pacote/AI%20Graphic/ai3dmodelviewer.pas)), avatars synchronisés avec la parole ([`aiavatar_lipsync.pas`](pacote/AI%20Graphic/aiavatar_lipsync.pas)), squelettes et client Tripo3D API. | Manipule et affiche des personnages virtuels et des modèles tridimensionnels sur l'interface. |
| [**`pacote/AI Hardware/`**](pacote/AI%20Hardware/) | Télémétrie Matérielle | Mesures d'utilisation du CPU ([`aicpu.pas`](pacote/AI%20Hardware/aicpu.pas)), de la RAM ([`aimemory.pas`](pacote/AI%20Hardware/aimemory.pas)), du disque ([`aidisk.pas`](pacote/AI%20Hardware/aidisk.pas)), du GPU ([`aigpu.pas`](pacote/AI%20Hardware/aigpu.pas)) et du système d'exploitation ([`aiso.pas`](pacote/AI%20Hardware/aiso.pas)). | Fournit les mesures matérielles en temps réel pour le diagnostic et l'équilibrage de charge. |
| [**`pacote/AI Graph/`**](pacote/AI%20Graph/) | Graphes et Itinéraires Routiers | Graphe de dépendances ([`aidependencygraph.pas`](pacote/AI%20Graph/aidependencygraph.pas)), visualiseur de graphes ([`aigraphvisualizer.pas`](pacote/AI%20Graph/aigraphvisualizer.pas)), calcul d'itinéraires GeoJSON ([`airoutecalculator.pas`](pacote/AI%20Graph/airoutecalculator.pas)). | Construit et affiche des réseaux nodaux, des flux logiques et des profils routiers cartographiques. |
| [**`pacote/AI LlamaCpp/`**](pacote/AI%20LlamaCpp/) | Inférence LLM Locale | Connecteur d'API et runtime x64 pour `llama.cpp` ([`aillamacppruntime.pas`](pacote/AI%20LlamaCpp/aillamacppruntime.pas)), quantification et LoRA. | Permet d'exécuter des modèles d'IA hors ligne et de façon entièrement confidentielle sur la machine de l'utilisateur. |
| [**`pacote/AI Math/`**](pacote/AI%20Math/) | Mathématiques et Apprentissage Automatique | Bibliothèque d'algèbre linéaire NUMPS ([`numps.pas`](pacote/AI%20Math/numps.pas)), réseaux perceptron et cartes auto-organisatrices (SOM). | Réalise des calculs vectoriels/matriciels et l'entraînement de réseaux neuronaux en Pascal pur. |
| [**`pacote/AI RAG/`**](pacote/AI%20RAG/) | Recherche Sémantique et RAG | Génération augmentée par récupération ([`airag.pas`](pacote/AI%20RAG/airag.pas)), extracteurs de texte et indexation en masse. | Retrouve les passages pertinents dans des bases documentaires volumineuses pour appuyer les réponses des LLMs. |
| [**`pacote/AI DBase/`**](pacote/AI%20DBase/) | Bases de Données et Métadonnées | Dictionnaires de schémas relationnels ([`aidbdictionary.pas`](pacote/AI%20DBase/aidbdictionary.pas)), persistance d'historique avec ZeosLib. | Mappe les tables relationnelles afin que les agents d'IA puissent composer des requêtes SQL fiables. |
| [**`pacote/AI Observability/`**](pacote/AI%20Observability/) | Observabilité d'IA | Collecteur de traces et métriques ([`aitrace.pas`](pacote/AI%20Observability/aitrace.pas)). | Enregistre l'audit des requêtes, la consommation de jetons et les temps de réponse de chaque appel. |
| [**`pacote/AI Evaluation/`**](pacote/AI%20Evaluation/) | Évaluation et Benchmarking | Juge d'évaluation basé sur des LLMs ([`aieval_judge.pas`](pacote/AI%20Evaluation/aieval_judge.pas)). | Teste et note automatiquement la qualité des réponses générées selon des critères objectifs. |
| [**`pacote/packages/`**](pacote/packages/) | Fichiers de Paquets Lazarus | 28 fichiers `.lpk` configurés. | Permet d'installer les composants dans la palette de composants de l'IDE Lazarus. |
| [**`pacote/samples/`**](pacote/samples/) | Applications de Démonstration | Plus de 95 exemples complets accompagnés de formulaires et de code source ([`pacote/samples/README.md`](pacote/samples/README.md)). | Fournit des guides concrets d'utilisation et des manuels pratiques pour chaque composant. |
| [**`tests/`**](tests/) | Suite de Tests Automatisés | Projets console `.lpr` exécutables via Free Pascal. | Assure l'absence de régression et le bon fonctionnement continu des algorithmes de la suite. |

---

## 🧭 4. Comment Naviguer dans la Documentation et les Exemples

Pour explorer chaque sous-système :
1. Consultez le [**Guide Général des Exemples**](pacote/samples/README.md) pour découvrir les 95+ démonstrations avec explications et captures d'écran.
2. Rendez-vous dans le dossier du module souhaité (par ex. [**`pacote/AI Input/`**](pacote/AI%20Input/)) pour examiner les unités et composants associés.
3. Pour chaque exemple, consultez le manuel détaillant les **Propriétés**, **Méthodes** et **Événements** dans son `README.md` (par ex. : [Manuel de l'Exemple Joystick](pacote/samples/AI%20Input/joystick_demo_README.md) et [Manuel de la Démonstration Projets](pacote/samples/AI%20Project/Demo_AI_Project/README.md)).

---

## 🛠️ 5. Prérequis et Installation

- **Compilateur :** [Free Pascal (FPC)](https://www.freepascal.org/) version 3.2.2 ou supérieure.
- **IDE :** [Lazarus](https://www.lazarus-ide.org/) version 3.0 ou supérieure (32-bit ou 64-bit).
- **Installation des Paquets :**
  1. Dans Lazarus, ouvrez le menu `Paquet` -> `Ouvrir le fichier de paquet (.lpk)...`.
  2. Rendez-vous dans [`pacote/packages/`](pacote/packages/).
  3. Ouvrez et compilez le paquet de base [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Cliquez sur `Compiler` puis, si vous souhaitez voir les composants dans la palette, sur `Utiliser` -> `Installer`.
  5. Installez les paquets supplémentaires selon les besoins de votre projet.

---

## 📄 6. Licence

Ce projet est distribué sous les termes de la licence **GPL v3**. Consultez le fichier [LICENSE](LICENSE) pour plus d'informations.