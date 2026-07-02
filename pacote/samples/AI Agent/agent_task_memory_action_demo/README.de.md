# Sample: agent_task_memory_action_demo

## Verfügbare Übersetzungen

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

Dieses Sample demonstriert einen aufgabenorientierten Multi-Agenten-Workflow mit Ausführungsspeicher, LLM-gestützter Planung, kognitiver Verarbeitung, echter Chromium-Browserautomatisierung, Aktionsvorbereitung und E-Mail-Versand.

Die zentrale Idee ist, einen freien Benutzerprompt in eine auditierbare Sequenz von Aufgaben umzuwandeln. Jede Aufgabe besitzt ID, Reihenfolge, Typ, Beschreibung, verantwortlichen Agenten, vorgeschlagene Aktion, Abhängigkeit, Parameter, Status und Ergebnis.

---

## Ziel des Samples

Das Hauptziel besteht darin zu zeigen, wie die Komponenten des Pakets **AI Agent** gemeinsam eine zusammengesetzte Anforderung lösen:

1. eine reale Website in Chromium öffnen;
2. Seitentext erfassen;
3. Zwischentasks mit einem LLM erzeugen;
4. den erfassten Inhalt kognitiv verarbeiten;
5. eine professionelle Zusammenfassung erstellen;
6. das Ergebnis in die Ergebnisfläche kopieren;
7. den E-Mail-Text vorbereiten;
8. die E-Mail über `TAIEmailClient` nach Benutzerbestätigung versenden;
9. den gesamten Ablauf in der Speicherkarte protokollieren.

Dieses Sample ist keine reine Testoberfläche. Es zeigt praktische Orchestrierung zwischen Agenten, realen Aktionen, Ausführungsspeicher und Web-UI-Automatisierung.

---

## Standardprompt

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

Die Browser-Szenario-Schaltfläche lädt eine ähnliche Variante:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

Die wichtigste Regel lautet: **Die erzeugte Zusammenfassung muss direkt in den E-Mail-Text kopiert werden**, ohne TXT-, DOCX-, Word-Dateien oder Anhänge zu erzeugen.

---

## Funktionsweise

### 1. Benutzereingabe

Im Tab **Prompt** definiert der Benutzer KI-Anbieter, Modell, Token, Base URL und Hauptprompt. Unterstützt werden OpenAI sowie lokale Endpunkte, die mit `/v1/chat/completions` kompatibel sind.

### 2. URL-Erkennung

`ExtractURLFromPrompt` sucht die erste URL im Prompt. Wird eine URL gefunden, initialisiert das Sample Chromium und navigiert zur realen Seite.

### 3. Erste Seitenerfassung

Nach der Navigation erfasst `TAIChromiumBrowser` den Text des Selektors `body`. Der Text wird in `FCapturedWebText` sowie in `browser.last_text` und `browser.last_result_text` gespeichert.

### 4. Klassifikation

`TAIClassifierAgent` erhält Prompt und erfassten Inhalt, klassifiziert die Anfrage und speichert den Schritt in `TAIAgentMemoryMap`.

### 5. Aufgabenplanung

`FTaskPlannerAgent`, basierend auf `TAIDecisionAgent`, wandelt die Anfrage in eine JSON-Aufgabenliste um. `LoadTasksFromPlannerJSON` lädt das JSON, normalisiert Abhängigkeiten und füllt das Aufgabenraster.

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Zur angeforderten Seite navigieren",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": { "url": "https://example.com" }
    }
  ]
}
```

### 6. Plannormalisierung

Das Sample normalisiert IDs, sortiert Aufgaben, rekonstruiert Abhängigkeiten, stellt den E-Mail-Empfänger sicher, fügt bei Bedarf Capture-Schritte nach Formularübermittlungen hinzu, verhindert unbekannte Aktionen und wandelt Zusammenfassungsaktionen in kognitive Aufgaben um.

### 7. Ausführung

Vor der Ausführung werden Status, Abhängigkeiten und Pflichtparameter geprüft. `BROWSER_*`-Aufgaben werden direkt durch `TAIActionExecutor` ausgeführt, damit das LLM die Aktion nicht versehentlich ändert. Kognitive Aufgaben werden durch `FTaskProcessorAgent` verarbeitet.

### 8. Aktionsvorbereitung

Operationale Aktionen werden als JSON vorbereitet. Direkte Aktionen wie `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT` und `REGISTER_RESULT` können deterministisch mit `BuildSingleActionJSON` erzeugt werden. Bei Bedarf wandelt `TAIActionBuilderAgent.BuildActionsWithRecovery` kognitive Ergebnisse in gültige Aktionsparameter um.

### 9. Endergebnis

Die erzeugte Zusammenfassung muss in `memConteudoCurriculo`, `memCorpoEmail`, `last_summary_text` und `last_text_content` erscheinen. Die E-Mail darf nicht mit Platzhaltern wie `<resumo_gerado>`, `[EMAIL]` oder generischem Text versendet werden.

---

## Verwendete Komponenten

- `TCHATGPT`: gemeinsamer LLM-Konnektor.
- `TAIAgentMemoryMap`: protokolliert den vollständigen Ablauf.
- `TAIClassifierAgent`: klassifiziert den ursprünglichen Prompt.
- `TAIDecisionAgent` als `FTaskPlannerAgent`: erzeugt die Aufgabenliste.
- `TAIDecisionAgent` als `FTaskProcessorAgent`: verarbeitet einzelne Aufgaben und erzeugt kognitive Ergebnisse.
- `TAIActionBuilderAgent`: erzeugt operationale Aktionsparameter.
- `TAIActionExecutor`: führt registrierte Aktionen aus und verwaltet `ExecutionContext`.
- `TAIEmailClient`: sendet SMTP-E-Mails nach Bestätigung.
- `TAIChromiumBrowser` und `TChromiumWindow`: reale Chromium-Automatisierung.

Registrierte Browseraktionen: `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`.

---

## Oberfläche

- **Prompt**: Haupteingabe und Provider-Konfiguration.
- **Tarefas**: vom LLM erzeugte Aufgabenliste.
- **Agente**: Audit des aktuellen Agenten.
- **Mapa de Memória**: strukturierte Verlaufshistorie.
- **Resultado**: generierter Text und E-Mail-Felder.
- **Log**: chronologische Ablaufverfolgung.
- **Navegador Chromium**: realer Browser.

---

## Ausführungskontext

`FActionExecutor.ExecutionContext` ist der gemeinsam genutzte operative Speicher. Wichtige Schlüssel sind `browser.last_dom_kind`, `browser.last_dom_selector`, `browser.last_dom_json`, `browser.last_text`, `browser.last_result_text`, `last_text_content`, `last_summary_text`, `last_text_filename`.

---

## Pipeline

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Aufgabenraster
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery bei Bedarf
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-Mail / Ergebnis
  -> MemoryMap / Log
```

---

## Sicherheit und Validierung

Das Sample blockiert leere oder Platzhalter-Empfänger, leere E-Mail-Texte, Platzhalter im Text, unbekannte Aktionen und fehlende Pflichtparameter. Der reale E-Mail-Versand erfordert immer eine manuelle Bestätigung.

---

## Erwartetes Ergebnis

Bei korrekter Ausführung erscheinen erzeugte Aufgaben, reale Chromium-Navigation, erfasster Seiteninhalt, eine professionelle Zusammenfassung im Ergebnisbereich, dieselbe Zusammenfassung im E-Mail-Text, ein detailliertes Log und die Agenten-Speicherkarte.
