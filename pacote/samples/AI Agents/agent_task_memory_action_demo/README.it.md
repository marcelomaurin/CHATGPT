# Sample: agent_task_memory_action_demo

## Traduzioni disponibili

- [Português](README.md)
- [English](README.en.md)
- [Français](README.fr.md)
- [日本語](README.ja.md)
- [Deutsch](README.de.md)
- [Русский](README.ru.md)
- [中文](README.zh.md)
- [Español](README.es.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

---

Questo sample dimostra un workflow multi-agente orientato alle attività, con memoria di esecuzione, pianificazione tramite LLM, elaborazione cognitiva, automazione reale del browser Chromium, preparazione delle azioni e invio di e-mail.

L’idea centrale è trasformare un prompt libero dell’utente in una sequenza di attività verificabile. Ogni attività possiede ID, ordine, tipo, descrizione, agente responsabile, azione suggerita, dipendenza, parametri, stato e risultato.

---

## Obiettivo del sample

L’obiettivo principale è mostrare come i componenti del pacchetto **AI Agent** possano lavorare insieme per risolvere una richiesta composta:

1. aprire un sito reale in Chromium;
2. catturare il testo della pagina;
3. creare attività intermedie usando un LLM;
4. elaborare cognitivamente il contenuto catturato;
5. generare un riepilogo professionale;
6. copiare il risultato nell’area risultato del form;
7. preparare il corpo dell’e-mail;
8. inviare l’e-mail con `TAIEmailClient`, dopo conferma dell’utente;
9. registrare tutto il percorso nella mappa di memoria.

Questo sample non è solo una schermata di test. È una dimostrazione pratica di orchestrazione tra agenti, azioni reali, memoria di esecuzione e automazione web.

---

## Prompt dello scenario predefinito

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

Il pulsante dello scenario browser carica una variante equivalente:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

La regola importante è: **il riepilogo generato deve essere copiato direttamente nel corpo dell’e-mail**, senza creare file TXT, DOCX, Word o allegati.

---

## Come funziona il flusso

### 1. Input dell’utente

Nella scheda **Prompt**, l’utente imposta provider IA, modello, token, Base URL e prompt principale. Il sample supporta OpenAI e endpoint locali compatibili con `/v1/chat/completions`.

### 2. Rilevamento URL

`ExtractURLFromPrompt` trova il primo URL nel prompt. Quando trova un URL, il sample inizializza Chromium e naviga verso la pagina reale.

### 3. Cattura iniziale della pagina

Dopo la navigazione, `TAIChromiumBrowser` cattura il testo del selettore `body`. Il testo viene salvato in `FCapturedWebText`, `browser.last_text` e `browser.last_result_text`.

### 4. Classificazione

`TAIClassifierAgent` riceve il prompt originale e il contenuto catturato, classifica la richiesta e registra il passaggio in `TAIAgentMemoryMap`.

### 5. Pianificazione delle attività

`FTaskPlannerAgent`, basato su `TAIDecisionAgent`, trasforma la richiesta in una lista JSON di attività. `LoadTasksFromPlannerJSON` interpreta il JSON, normalizza le dipendenze e popola la griglia.

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navigate to the requested page",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": { "url": "https://example.com" }
    }
  ]
}
```

### 6. Normalizzazione del piano

Il sample normalizza gli ID, ordina le attività, ricostruisce le dipendenze, garantisce il destinatario e-mail, crea catture dopo l’invio dei form quando necessario, rifiuta azioni sconosciute e converte le azioni di riepilogo in attività cognitive.

### 7. Esecuzione

Prima dell’esecuzione, il sample controlla stato, dipendenze e parametri obbligatori. Le attività `BROWSER_*` sono eseguite direttamente da `TAIActionExecutor` per evitare che il LLM cambi l’azione. Le attività cognitive sono processate da `FTaskProcessorAgent`.

### 8. Preparazione delle azioni

Le azioni operative sono preparate come JSON. Azioni dirette come `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT` e `REGISTER_RESULT` possono essere generate in modo deterministico con `BuildSingleActionJSON`. Quando necessario, `TAIActionBuilderAgent.BuildActionsWithRecovery` converte l’output cognitivo in parametri validi.

### 9. Risultato finale

Il riepilogo generato deve apparire in `memConteudoCurriculo`, `memCorpoEmail`, `last_summary_text` e `last_text_content`. L’e-mail non deve essere inviata con marcatori come `<resumo_gerado>`, `[EMAIL]` o testo generico.

---

## Componenti utilizzati

- `TCHATGPT`: connettore LLM condiviso dagli agenti.
- `TAIAgentMemoryMap`: registra l’intero percorso di esecuzione.
- `TAIClassifierAgent`: classifica il prompt iniziale.
- `TAIDecisionAgent` come `FTaskPlannerAgent`: genera la lista attività.
- `TAIDecisionAgent` come `FTaskProcessorAgent`: elabora una singola attività e genera risultati cognitivi.
- `TAIActionBuilderAgent`: converte i risultati cognitivi in parametri operativi.
- `TAIActionExecutor`: esegue le azioni registrate e mantiene `ExecutionContext`.
- `TAIEmailClient`: invia e-mail SMTP dopo conferma.
- `TAIChromiumBrowser` e `TChromiumWindow`: automazione reale di Chromium.

Azioni browser registrate: `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`.

---

## Schede dell’interfaccia

- **Prompt**: input principale e configurazione provider.
- **Tarefas**: lista attività generata dal LLM.
- **Agente**: audit dell’agente corrente.
- **Mapa de Memória**: storico strutturato del flusso.
- **Resultado**: testo generato e campi e-mail.
- **Log**: traccia cronologica.
- **Navegador Chromium**: browser reale.

---

## Contesto di esecuzione

`FActionExecutor.ExecutionContext` è la memoria operativa condivisa tra azioni. Chiavi importanti: `browser.last_dom_kind`, `browser.last_dom_selector`, `browser.last_dom_json`, `browser.last_text`, `browser.last_result_text`, `last_text_content`, `last_summary_text`, `last_text_filename`.

---

## Pipeline riassunta

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Task grid
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery quando necessario
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-mail / Risultato
  -> MemoryMap / Log
```

---

## Sicurezza e validazioni

Il sample blocca destinatari vuoti o placeholder, corpi e-mail vuoti, corpi con placeholder, azioni sconosciute e parametri obbligatori mancanti. L’invio reale richiede sempre conferma manuale.

---

## Risultato atteso

Con lo scenario eseguito correttamente, l’utente vede attività generate, navigazione reale in Chromium, contenuto catturato, un riepilogo professionale nell’area risultato, lo stesso riepilogo nel corpo dell’e-mail, log dettagliato e mappa di memoria degli agenti.
