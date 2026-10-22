# TCHATGPT — Suite di Componenti IA per Lazarus / Free Pascal

🌐 **Lingue / Idiomas**

[Português](README.md) • [English](README_EN.md) • [Español](README_ES.md) • [Français](README_FR.md) • [Italiano](README_IT.md) • [العربية](README_AR.md) • [中文](README_CH.md) • [Русский](README_RU.md) • [日本語](README_JP.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)

---

## 🎯 1. Obiettivo del Progetto

**TCHATGPT** (sviluppato da [Maurinsoft](https://maurinsoft.com.br)) è una suite modulare di componenti visuali e non visuali in **Object Pascal (Free Pascal / Lazarus)** per l'integrazione diretta e nativa di Intelligenza Artificiale moderna, Visione Artificiale, Elaborazione Vocale, Agenti Autonomi, Automazione Industriale, Hardware e Gestione dei Progetti.

L'obiettivo fondamentale è consentire agli sviluppatori desktop ed embedded di integrare capacità avanzate di IA direttamente in codice nativo con:
1. **Controllo Totale e Bassa Latenza:** Senza intermediari web o pesanti framework frontend.
2. **Connettività Ibrida:** Supporto sia per modelli LLM su cloud (OpenAI, Claude, Gemini, Ollama) che per inferenza locale offline al 100% tramite [`llama.cpp`](pacote/AI%20LlamaCpp/).
3. **Agenti Autonomi e Strumenti:** Architettura ad agenti capaci di eseguire codice, interagire con database, interrogare file, controllare bracci robotici e collaborare mediante i protocolli [A2A](pacote/AI%20A2A/) e [MCP](pacote/AI%20MCP/).
4. **Interazione con il Mondo Fisico:** Dispositivi USB, porte seriali, sensori Kinect, controller di gioco, PLC Modbus, broker MQTT ed emulazione del firmware Marlin per stampanti 3D e macchine CNC.

---

## 📦 2. Catalogo dei Pacchetti: Finalità e Stato

La tabella seguente illustra la **finalità concettuale** di ogni pacchetto (cosa manipola, elabora o controlla) e il relativo stato di maturità:

| Pacchetto Lazarus | Cartella Sorgente | Finalità (Cosa manipola / fa) | Stato Attuale |
|---|---|---|---|
| [**`openai_core.lpk`**](pacote/packages/openai_core.lpk) | [`pacote/AI/`](pacote/AI/) | Connette alle API dei modelli LLM (OpenAI, Claude, Gemini, Ollama), gestisce token, prompt, modelli e fornisce le classi base. | **Stable / Beta** |
| [**`openai_agent.lpk`**](pacote/packages/openai_agent.lpk) | [`pacote/AI Agent/`](pacote/AI%20Agent/) | Orchestra agenti autonomi, chiamate di funzioni (tool calling), memoria fattuale e regole di sicurezza (guardrails). | **Stable / Beta**; pipeline composte *Experimental* |
| [**`openai_a2a.lpk`**](pacote/packages/openai_a2a.lpk) | [`pacote/AI A2A/`](pacote/AI%20A2A/) | Standardizza la comunicazione e lo scambio di messaggi strutturati direttamente tra agenti intelligenti in rete (Agent-to-Agent). | **Stable / Beta** |
| [**`openai_mcp.lpk`**](pacote/packages/openai_mcp.lpk) | [`pacote/AI MCP/`](pacote/AI%20MCP/) | Implementa lo standard aperto Model Context Protocol (Anthropic/OpenAI) come client e server JSON-RPC per esporre strumenti. | **Stable / Beta** |
| [**`openai_input.lpk`**](pacote/packages/openai_input.lpk) | [`pacote/AI Input/`](pacote/AI%20Input/) | Cattura dati dall'esterno: joystick XInput/WinMM, impronte vocali, telecamere, sensori Kinect, porte seriali, socket TCP/UDP, server web e documenti locali. | **Stable / Beta**; integrazione hardware_net_demo *Experimental* |
| [**`openai_output.lpk`**](pacote/packages/openai_output.lpk) | [`pacote/AI Output/`](pacote/AI%20Output/) | Genera documenti formattati Word (DOCX/OpenXML), fogli Excel (XLSX), PDF, testo semplice, JSON strutturato e scontrini termici POS. | **Stable / Beta** |
| [**`openai_vision.lpk`**](pacote/packages/openai_vision.lpk) | [`pacote/AI Vision/`](pacote/AI%20Vision/) | Elabora flussi video e immagini tramite OpenCV o metodi nativi: rileva volti, traccia il movimento e riconosce posture umane. | **Stable / Beta** |
| [**`openai_image.lpk`**](pacote/packages/openai_image.lpk) | [`pacote/AI Image/`](pacote/AI%20Image/) | Applica filtri e manipolazioni grafiche a immagini direttamente in Pascal nativo, senza librerie esterne. | **Stable / Beta** |
| [**`openai_voice.lpk`**](pacote/packages/openai_voice.lpk) | [`pacote/AI Voice/`](pacote/AI%20Voice/) | Elabora l'audio vocale: sintesi da testo a voce (TTS), trascrizione da voce a testo (STT) e filtri acustici. | **Stable / Beta** |
| [**`openai_project.lpk`**](pacote/packages/openai_project.lpk) | [`pacote/AI Project/`](pacote/AI%20Project/) | Disegna interfacce grafiche di gestione: diagrammi di Gantt interattivi, reti PERT/CPM, lavagne Kanban e istogrammi delle risorse. | **Stable / Beta** |
| [**`openai_project_core.lpk`**](pacote/packages/openai_project_core.lpk) | [`pacote/AI Project Core/`](pacote/AI%20Project%20Core/) | Esegue calcoli matematici di pianificazione: calcola il percorso critico (CPM), valida grafi aciclici e gestisce calendari lavorativi. | **Stable / Beta** |
| [**`openai_industrial.lpk`**](pacote/packages/openai_industrial.lpk) | [`pacote/AI Industrial/`](pacote/AI%20Industrial/) | Comunica con apparecchiature industriali tramite Modbus TCP/RTU, broker MQTT, pinmap Arduino e controllo di bracci robotici. | **Stable / Beta** |
| [**`openai_marlin.lpk`**](pacote/packages/openai_marlin.lpk) | [`pacote/AI Simulation/AIMarlin/`](pacote/AI%20Simulation/AIMarlin/) | Emula il firmware di stampanti 3D e frese CNC Marlin, interpretando comandi G-Code e fornendo porte seriali virtuali. | **Stable / Beta** |
| [**`openai_simulation.lpk`**](pacote/packages/openai_simulation.lpk) | [`pacote/AI Simulation/`](pacote/AI%20Simulation/) | Esegue simulazioni bidimensionali basate su automi cellulari, code di servizio e navigazione di robot mobili. | **Stable / Beta** |
| [**`openai_graphic.lpk`**](pacote/packages/openai_graphic.lpk) | [`pacote/AI Graphic/`](pacote/AI%20Graphic/) | Gestisce grafica tridimensionale OpenGL, avatar virtuali con animazione labiale, scheletri e ambienti fisici. | **Stable / Beta** |
| [**`openai_hardware.lpk`**](pacote/packages/openai_hardware.lpk) | [`pacote/AI Hardware/`](pacote/AI%20Hardware/) | Raccoglie telemetria del sistema operativo e dell'hardware: uso di CPU, memoria RAM, dischi, schede grafiche e processi attivi. | **Stable / Beta** |
| [**`openai_graph.lpk`**](pacote/packages/openai_graph.lpk) | [`pacote/AI Graph/`](pacote/AI%20Graph/) | Costruisce, analizza e visualizza grafi di dipendenze logiche, reti di conoscenza e percorsi stradali GeoJSON. | **Stable / Beta** |
| [**`openai_llamacpp.lpk`**](pacote/packages/openai_llamacpp.lpk) | [`pacote/AI LlamaCpp/`](pacote/AI%20LlamaCpp/) | Esegue modelli LLM in formato GGUF in locale senza connessione internet tramite il motore `llama.cpp` x64. | **Stable / Beta** |
| [**`openai_ml.lpk`**](pacote/packages/openai_ml.lpk) | [`pacote/AI Math/`](pacote/AI%20Math/) | Esegue algoritmi di machine learning classici (reti neurali, perceptron, mappe SOM) e calcolo matriciale (NUMPS) in Pascal puro. | **Stable / Beta** |
| [**`openai_python.lpk`**](pacote/packages/openai_python.lpk) | [`pacote/python/`](pacote/python/) | Integra ambienti Python per eseguire modelli di deep learning (YOLOv8, CNN, LSTM) collegati a Lazarus. | **Stable / Beta** |
| [**`openai_rag.lpk`**](pacote/packages/openai_rag.lpk) | [`pacote/AI RAG/`](pacote/AI%20RAG/) | Esegue ricerca semantica e generazione aumentata da recupero (RAG), indicizzando collezioni di documenti per i modelli LLM. | **Stable / Beta** |
| [**`openai_dbase.lpk`**](pacote/packages/openai_dbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Si collega a database relazionali per archiviare la cronologia delle chat, log di audit e memoria persistente tramite ZeosLib. | **Stable / Beta** |
| [**`openai_aidbase.lpk`**](pacote/packages/openai_aidbase.lpk) | [`pacote/AI DBase/`](pacote/AI%20DBase/) | Estrae dizionari di dati e schemi SQL per consentire ai modelli di formulare interrogazioni con precisione. | **Stable / Beta** |
| [**`openai_files.lpk`**](pacote/packages/openai_files.lpk) | [`pacote/AI Files/`](pacote/AI%20Files/) | Esplora e indicizza alberi di cartelle su disco, generando dataset strutturati per l'addestramento e la ricerca. | **Stable / Beta** |
| [**`openai_observability.lpk`**](pacote/packages/openai_observability.lpk) | [`pacote/AI Observability/`](pacote/AI%20Observability/) | Monitora le operazioni di IA: registra tracce/span, misura la latenza, controlla il consumo di token e segnala anomalie. | **Stable / Beta** |
| [**`openai_evaluation.lpk`**](pacote/packages/openai_evaluation.lpk) | [`pacote/AI Evaluation/`](pacote/AI%20Evaluation/) | Valuta la correttezza delle risposte generate tramite valutatori automatici (LLM-as-a-judge) e report di regressione. | **Stable / Beta** |
| [**`openai_integration.lpk`**](pacote/packages/openai_integration.lpk) | [`pacote/AI/`](pacote/AI/) | Connette molteplici componenti in pipeline unificate di elaborazione ed esecutori concatenati. | **Stable / Beta** |
| [**`openai_webrtc.lpk`**](pacote/packages/openai_webrtc.lpk) | [`pacote/AI Communication/`](pacote/AI%20Communication/) | Stabilisce canali dati peer-to-peer a bassa latenza (WebRTC DataChannel) usando la libreria libdatachannel. | **Stable / Beta** |

---

## 📂 3. Organizzazione delle Cartelle del Repository

Di seguito viene illustrato lo scopo di ciascuna cartella del progetto, il relativo contenuto e l'utilità pratica:

| Cartella | Scopo del Direttorio | Cosa contiene | A cosa serve (Utilità Pratica) |
|---|---|---|---|
| [**`pacote/AI/`**](pacote/AI/) | Infrastruttura centrale | Classi fondamentali ([`aibase.pas`](pacote/AI/aibase.pas), [`aiconfig.pas`](pacote/AI/aiconfig.pas)), client LLM ([`chatgpt.pas`](pacote/AI/chatgpt.pas), [`aiclaude.pas`](pacote/AI/aiclaude.pas), [`aigemini.pas`](pacote/AI/aigemini.pas), [`aiollama.pas`](pacote/AI/aiollama.pas)), tokenizer e router. | Centralizza la comunicazione HTTP/REST con i fornitori di IA e fornisce l'architettura comune condivisa. |
| [**`pacote/AI Agent/`**](pacote/AI%20Agent/) | Orchestrazione di Agenti Autonomi | Moduli agente ([`aiagent.pas`](pacote/AI%20Agent/aiagent.pas)), memoria deterministica, mappe concettuali, guardrail di sicurezza e autoriparazione del codice. | Consente di creare agenti che risolvono obiettivi in più fasi, decidendo quando invocare codice Pascal o interrogare dati. |
| [**`pacote/AI A2A/`**](pacote/AI%20A2A/) | Protocollo Agent-to-Agent | Protocollo di comunicazione e messaggistica tra agenti di IA ([`aia2a_client.pas`](pacote/AI%20A2A/aia2a_client.pas)). | Permette a più agenti distribuiti di collaborare, delegare compiti e condividere contesto strutturato in rete. |
| [**`pacote/AI MCP/`**](pacote/AI%20MCP/) | Model Context Protocol | Implementazione client e server MCP su JSON-RPC ([`aimcp_client.pas`](pacote/AI%20MCP/aimcp_client.pas), [`aimcp_server.pas`](pacote/AI%20MCP/aimcp_server.pas)). | Permette ai modelli LLM di interagire direttamente con gli strumenti e i dati dell'applicazione tramite lo standard aperto MCP. |
| [**`pacote/AI Input/`**](pacote/AI%20Input/) | Dispositivi e Sorgenti di Ingresso | Joystick ([`aijoystick.pas`](pacote/AI%20Input/AIJoystick/aijoystick.pas)), audio ([`aispeakersignature.pas`](pacote/AI%20Input/AIAudio/aispeakersignature.pas)), Kinect ([`aikinectsensor.pas`](pacote/AI%20Input/AIKinect/aikinectsensor.pas)), USB, Seriale, Socket, Server Web e lettori di documenti. | Cattura e normalizza ingressi dal mondo fisico (sensori, rete, controller, file) per alimentare i flussi di IA. |
| [**`pacote/AI Output/`**](pacote/AI%20Output/) | Generazione di Uscite Strutturate | Generatori di documenti Word ([`aiworddocument.pas`](pacote/AI%20Output/aiworddocument.pas)), fogli Excel ([`aixlsxwriter.pas`](pacote/AI%20Output/aixlsxwriter.pas)), stampanti termiche POS ([`aiposprinter.pas`](pacote/AI%20Output/aiposprinter.pas)) e formattatori JSON. | Produce stampe fisiche (scontrini) o file digitali formattati a partire dalle risposte dell'IA. |
| [**`pacote/AI Vision/`**](pacote/AI%20Vision/) | Visione Artificiale | Connettore OpenCV ([`aiopencv.pas`](pacote/AI%20Vision/aiopencv.pas)), tracciamento facciale ([`aifacetracker.pas`](pacote/AI%20Vision/aifacetracker.pas)), tracciamento del movimento ([`aimotiontracker.pas`](pacote/AI%20Vision/aimotiontracker.pas)), stima delle posture ([`aihumanposedetector.pas`](pacote/AI%20Vision/aihumanposedetector.pas)) ed elaborazione di fotogrammi. | Analizza flussi video da webcam e file per il riconoscimento visivo e il tracciamento di persone e oggetti. |
| [**`pacote/AI Voice/`**](pacote/AI%20Voice/) | Voce, Riconoscimento e Sintesi | Sintetizzatore vocale TTS ([`aivoicesynthesizer.pas`](pacote/AI%20Voice/aivoicesynthesizer.pas)), riconoscimento STT ([`aispeechrecognizer.pas`](pacote/AI%20Voice/aispeechrecognizer.pas)), assistenti e clonazione vocale. | Permette all'applicazione di parlare chiaramente all'utente e di riconoscere comandi vocali dal microfono. |
| [**`pacote/AI Project Core/`**](pacote/AI%20Project%20Core/) | Motore Matematico di Progetto | Pianificatore CPM ([`aicpmscheduler.pas`](pacote/AI%20Project%20Core/aicpmscheduler.pas)), grafo aciclico delle attività ([`aitaskgraph.pas`](pacote/AI%20Project%20Core/aitaskgraph.pas)), calendario lavorativo ([`aiworkcalendar.pas`](pacote/AI%20Project%20Core/aiworkcalendar.pas)) e bilanciamento delle risorse. | Calcola tempistiche, margini e percorsi critici senza dipendere da interfacce grafiche, utilizzabile anche in servizi console. |
| [**`pacote/AI Project/`**](pacote/AI%20Project/) | Viste Visuali di Progetto (LCL) | Controlli interattivi: diagramma di Gantt ([`aiganttview.pas`](pacote/AI%20Project/aiganttview.pas)), rete PERT ([`ainetworkview.pas`](pacote/AI%20Project/ainetworkview.pas)), lavagna Kanban ([`aiboardview.pas`](pacote/AI%20Project/aiboardview.pas)) e istogramma delle risorse ([`airesourceview.pas`](pacote/AI%20Project/airesourceview.pas)). | Mostra controlli grafici interattivi per la pianificazione visuale di progetti e compiti. |
| [**`pacote/AI Industrial/`**](pacote/AI%20Industrial/) | Automazione e Reti Industriali | Client Modbus TCP/RTU ([`aimodbus.pas`](pacote/AI%20Industrial/aimodbus.pas)), client MQTT ([`aimqtt.pas`](pacote/AI%20Industrial/aimqtt.pas)), cinematica di bracci robotici ([`aiarm_robot.pas`](pacote/AI%20Industrial/aiarm_robot.pas)) e mappatura pin Arduino. | Connette le applicazioni Lazarus al mondo industriale, leggendo registri PLC e azionando dispositivi fisici. |
| [**`pacote/AI Simulation/`**](pacote/AI%20Simulation/) | Simulazione 2D ed Emulazione Marlin | Motore di simulazione cellulare 2D ([`aisimulationengine.pas`](pacote/AI%20Simulation/aisimulationengine.pas)), code di attesa ed emulatore Marlin G-code ([`aimarlinsimulator.pas`](pacote/AI%20Simulation/AIMarlin/aimarlinsimulator.pas)). | Simula scenari di logistica e collauda traiettorie CNC prima dell'esecuzione su macchinari fisici. |
| [**`pacote/AI Graphic/`**](pacote/AI%20Graphic/) | Grafica 3D e Avatar | Visualizzatore 3D OpenGL ([`ai3dmodelviewer.pas`](pacote/AI%20Graphic/ai3dmodelviewer.pas)), avatar con sincronizzazione labiale ([`aiavatar_lipsync.pas`](pacote/AI%20Graphic/aiavatar_lipsync.pas)), scheletri e client Tripo3D API. | Manipola e mostra personaggi virtuali e modelli tridimensionali direttamente nell'interfaccia. |
| [**`pacote/AI Hardware/`**](pacote/AI%20Hardware/) | Telemetria Hardware | Misuratori di consumo CPU ([`aicpu.pas`](pacote/AI%20Hardware/aicpu.pas)), RAM ([`aimemory.pas`](pacote/AI%20Hardware/aimemory.pas)), Disco ([`aidisk.pas`](pacote/AI%20Hardware/aidisk.pas)), GPU ([`aigpu.pas`](pacote/AI%20Hardware/aigpu.pas)) e sistema operativo ([`aiso.pas`](pacote/AI%20Hardware/aiso.pas)). | Fornisce metriche di utilizzo delle risorse fisiche per diagnostica e bilanciamento dei carichi di lavoro. |
| [**`pacote/AI Graph/`**](pacote/AI%20Graph/) | Grafi e Percorsi Stradali | Grafo delle dipendenze ([`aidependencygraph.pas`](pacote/AI%20Graph/aidependencygraph.pas)), visualizzatore di grafi ([`aigraphvisualizer.pas`](pacote/AI%20Graph/aigraphvisualizer.pas)), calcolo di percorsi GeoJSON ([`airoutecalculator.pas`](pacote/AI%20Graph/airoutecalculator.pas)). | Costruisce e disegna reti nodali, flussi logici e profili di viaggio su mappe geografiche. |
| [**`pacote/AI LlamaCpp/`**](pacote/AI%20LlamaCpp/) | Inferenza LLM Locale | Connettore di API e runtime x64 per `llama.cpp` ([`aillamacppruntime.pas`](pacote/AI%20LlamaCpp/aillamacppruntime.pas)), quantizzazione e LoRA. | Permette di eseguire modelli di IA localmente sul PC dell'utente in modo completamente privato e senza internet. |
| [**`pacote/AI Math/`**](pacote/AI%20Math/) | Matematica e Machine Learning | Libreria di algebra lineare NUMPS ([`numps.pas`](pacote/AI%20Math/numps.pas)), reti percettrone e mappe auto-organizzanti (SOM). | Esegue calcoli di matrici/vettori e addestramento di reti neurali direttamente in Pascal puro. |
| [**`pacote/AI RAG/`**](pacote/AI%20RAG/) | Ricerca Semantica e RAG | Generazione aumentata da recupero ([`airag.pas`](pacote/AI%20RAG/airag.pas)), estrattori di testo e indicizzazione di massa. | Trova passaggi pertinenti in archivi di documenti estesi per arricchire il contesto fornito ai modelli di linguaggio. |
| [**`pacote/AI DBase/`**](pacote/AI%20DBase/) | Database e Metadati | Dizionari di schemi relazionali ([`aidbdictionary.pas`](pacote/AI%20DBase/aidbdictionary.pas)), persistenza dello storico tramite ZeosLib. | Mappa le tabelle del database relazionale affinché gli agenti intelligenti possano generare query SQL precise. |
| [**`pacote/AI Observability/`**](pacote/AI%20Observability/) | Osservabilità dell'IA | Raccoglitore di tracce e metriche ([`aitrace.pas`](pacote/AI%20Observability/aitrace.pas)). | Registra l'audit delle chiamate, il consumo di token e i tempi di risposta di ogni richiesta. |
| [**`pacote/AI Evaluation/`**](pacote/AI%20Evaluation/) | Valutazione e Benchmark | Giudice automatico basato su LLM ([`aieval_judge.pas`](pacote/AI%20Evaluation/aieval_judge.pas)). | Verifica e assegna punteggi oggettivi alla qualità delle risposte fornite dai prompt. |
| [**`pacote/packages/`**](pacote/packages/) | File dei Pacchetti Lazarus | 28 file `.lpk` configurati. | Consente di installare i componenti nella tavolozza dell'IDE Lazarus a seconda delle necessità. |
| [**`pacote/samples/`**](pacote/samples/) | Applicazioni Dimostrative | Più di 95 esempi completi con interfacce e codice sorgente ([`pacote/samples/README.md`](pacote/samples/README.md)). | Fornisce guide pratiche e manuali operativi di riferimento per ciascun componente della suite. |
| [**`tests/`**](tests/) | Test Automatizzati | Progetti di console `.lpr` verificabili tramite Free Pascal. | Garantisce l'integrità e la regressione zero per tutti gli algoritmi e i componenti della libreria. |

---

## 🧭 4. Come Navigare nella Documentazione e negli Esempi

Per approfondire ciascun sottosistema:
1. Consultate la [**Guida Generale degli Esempi**](pacote/samples/README.md) per scoprire i 95+ progetti con descrizioni e schermate.
2. Esplorate la cartella del modulo desiderato (es.: [**`pacote/AI Input/`**](pacote/AI%20Input/)) per visualizzare i file sorgente e i componenti.
3. Per i singoli esempi, consultate il manuale con **Proprietà**, **Metodi** ed **Eventi** nel relativo `README.md` (es.: [Manuale dell'Esempio Joystick](pacote/samples/AI%20Input/joystick_demo_README.md) e [Manuale Dimostrativo Progetti](pacote/samples/AI%20Project/Demo_AI_Project/README.md)).

---

## 🛠️ 5. Requisiti e Installazione

- **Compilatore:** [Free Pascal (FPC)](https://www.freepascal.org/) versione 3.2.2 o superiore.
- **IDE:** [Lazarus](https://www.lazarus-ide.org/) versione 3.0 o superiore (32-bit o 64-bit).
- **Installazione dei Pacchetti:**
  1. In Lazarus, aprite il menu `Pacchetto` -> `Apri file di pacchetto (.lpk)...`.
  2. Spostatevi nella cartella [`pacote/packages/`](pacote/packages/).
  3. Aprite e compilate il pacchetto base [`openai_core.lpk`](pacote/packages/openai_core.lpk).
  4. Cliccate su `Compila` e, se desiderate i componenti nella tavolozza dell'IDE, su `Usa` -> `Installa`.
  5. Installate gli altri pacchetti secondo le necessità del vostro progetto.

---

## 📄 6. Licenza

Questo progetto è distribuito sotto i termini della licenza **GPL v3**. Consultare il file [LICENSE](LICENSE) per ulteriori dettagli.