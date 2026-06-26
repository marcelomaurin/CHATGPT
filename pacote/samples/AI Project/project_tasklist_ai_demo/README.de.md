# Project TaskList AI Demo

Dieses Sample zeigt die Verwendung von Komponenten aus dem Paket **AI Project** der Lazarus AI Suite, um einen einfachen projektplanerischen Ablauf mit Unterstützung eines LLM zu erstellen.

Das aktuelle Ziel dieses Samples ist es, praktisch zu zeigen, wie ein Lazarus-Formular:

1. einen KI-Anbieter/ein Modell konfiguriert;
2. grundlegende Projektdaten erfasst;
3. vom LLM eine erste JSON-Spezifikation anfordert;
4. vom LLM technische Aufgaben generieren lässt;
5. den Projektzustand in `ProjectData` speichert;
6. Aufgaben in Grid, Statusbereich und JSON/Log-Ansichten anzeigt;
7. die Datei `.aiproj.json` speichert und lädt.

> Wichtiger Hinweis: Dieses README beschreibt, was das Sample **heute** tut. Es beschreibt keine ideale zukünftige Version der Demo.

---

## Tatsächliches Ziel des Samples

`project_tasklist_ai_demo` ist ein Proof of Concept für die Integration zwischen:

- einem Lazarus-Formular;
- der Komponente `TCHATGPT`;
- der zentralen Komponente `TAIProject`;
- Hilfskomponenten aus dem Paket `AI Project`;
- einer Projekt-JSON-Struktur, die in `AIProject1.ProjectData` gehalten wird.

Es ist noch kein vollständiger Projektmanager. In dieser Version ist es auch noch keine saubere Demo, die ausschließlich auf gekapselten Komponenten basiert. Ein wichtiger Teil der Prompt-, Validierungs- und JSON-Integrationslogik ist weiterhin in `main.pas` implementiert.

---

## Derzeit implementierter Ablauf

### 1. KI-Konfiguration

Im Tab **Config IA** wählt der Benutzer:

- Anbieter;
- Modell;
- Token;
- Endpoint/lokale URL;
- KI-Version der Komponente `TCHATGPT`.

Beim Klick auf **Aplicar Configuração** füllt das Formular `AIProjectLLMConfig1`, wendet die Konfiguration auf `AIProject1` an und aktualisiert zusätzlich direkt die Komponente `ChatGPT1`.

Die Schaltfläche **Testar IA** sendet eine einfache Frage an `ChatGPT1` und wartet auf eine Antwort des LLM.

### 2. Grunddaten des Projekts

Im Tab **Projeto** gibt der Benutzer ein:

- Projektname;
- Beschreibung/Ziel;
- Einschränkungen;
- erwartete Lieferobjekte.

Diese Informationen werden in Eigenschaften von `AIProject1` kopiert, zum Beispiel `ProjectName`, `Goal`, `Constraints` und `ExpectedDeliverables`.

### 3. Generierung der Spezifikation mit KI

Die Schaltfläche **Gerar Descrição Elaborada (IA)** führt den Spezifikationsablauf aus.

In der aktuellen Implementierung wird der Prompt direkt in `main.pas` zusammengesetzt, über `ChatGPT1.SendQuestion` gesendet, als JSON interpretiert und in `AIProject1.ProjectData` integriert.

Erwartete Struktur:

```json
{
  "project": {
    "name": "...",
    "description": "...",
    "goal": "...",
    "context": "...",
    "scope": "...",
    "constraints": "...",
    "expected_deliverables": "..."
  },
  "agile_documents": {
    "business_vision": "...",
    "functional_requirements": [],
    "non_functional_requirements": [],
    "stakeholders": [],
    "risk_map": [],
    "epics": [],
    "user_stories": []
  }
}
```

Die generierte Dokumentation wird in `ProjectData.project` und `ProjectData.agile_documents` integriert.

### 4. Aufgabengenerierung mit KI

Die Schaltfläche **Gerar Tarefas com IA** sendet das aktuelle Projekt-JSON an das LLM und fordert eine Liste technischer Aufgaben an.

Erwartete Struktur:

```json
{
  "planning": {
    "tasks": [
      {
        "id": "T001",
        "epic_id": "E001",
        "title": "...",
        "description": "...",
        "long_description": "...",
        "acceptance_criteria": "...",
        "priority": "alta",
        "status": "draft",
        "dependency_type": "serial",
        "dependencies": [],
        "can_run_in_parallel": false,
        "estimated_hours": {
          "intern": 8,
          "junior": 6,
          "mid_level": 4,
          "senior": 2
        },
        "suggested_skill_level": "mid_level",
        "assigned_skill_level": "mid_level",
        "assigned_to": "DEV",
        "responsible_profile": "DEV",
        "planned_start_date": "2026-06-26",
        "planned_end_date": "2026-06-27",
        "estimated_duration_days": 1,
        "progress_percent": 0,
        "deliverable": "...",
        "notes": "...",
        "revision_created": 1,
        "revision_updated": 1
      }
    ]
  }
}
```

Nach der Validierung der Antwort ersetzt das Sample `ProjectData.planning.tasks` durch die zurückgegebenen Aufgaben und ruft `AIProjectTasks1.RecalculateEstimates` auf.

### 5. Anzeige der Aufgaben

Der Tab **Tarefas** verwendet:

- `TAIProjectStatusPanel` für die Statuszusammenfassung;
- `TAIProjectTaskGrid` zur Auflistung der Aufgaben;
- `MemoTaskDescription` zur Anzeige der ausführlichen Beschreibung der ausgewählten Aufgabe.

Wenn im Grid eine Zeile ausgewählt wird, sucht das Sample die Aufgabe anhand der ID und zeigt `long_description` oder `description` im Memo an.

### 6. JSON und Log

Der Tab **JSON/Log** zeigt:

- das vollständige JSON aus `AIProject1.ProjectData`;
- Logmeldungen des ausgeführten Ablaufs;
- ursprüngliche LLM-Antworten bei Parsing- oder Validierungsfehlern.

### 7. Projekt speichern und laden

Die Schaltfläche **Salvar Projeto** verwendet `AIProjectStorage1.SaveProjectToFile`, um die Datei zu speichern:

```text
project_tasklist_demo.aiproj.json
```

Die Schaltfläche **Carregar Projeto** verwendet `AIProjectStorage1.LoadProjectFromFile`, um dieselbe Datei zu laden.

In der aktuellen Version verwenden Speichern und Laden zusätzlich Hilfsaufrufe an das LLM für Validierung/Zusammenfassung. Das ist das aktuelle Verhalten des Samples, aber für die Projektpersistenz nicht erforderlich.

---

## Tatsächlich im aktuellen Ablauf integrierte Komponenten

### `TCHATGPT` / `ChatGPT1`

Dies ist die tatsächlich verwendete Komponente für die Kommunikation mit dem LLM.

Das Sample ruft direkt auf:

```pascal
ChatGPT1.SendQuestion(APrompt)
```

Diese Komponente wird verwendet für:

- Verbindungstest;
- Spezifikationsgenerierung;
- Aufgabengenerierung;
- Generierung zusätzlicher Aufgaben;
- Zusammenfassung;
- textuelle Berichte;
- JSON-Validierung/Export;
- Validierung vor dem Speichern;
- Bestätigung des Zurücksetzens.

### `TAIProject` / `AIProject1`

Dies ist die zentrale Komponente des Samples.

Sie hält die Hauptstruktur in:

```pascal
AIProject1.ProjectData
```

Das Sample verwendet `AIProject1` zum Speichern von:

- Projektdaten;
- agilen Dokumenten in `agile_documents`;
- Aufgabenliste in `planning.tasks`;
- grundlegender Projektkonfiguration;
- serialisierbarem Zustand der `.aiproj.json`.

Außerdem wird aufgerufen:

```pascal
AIProject1.EnsureProjectStructure;
```

um sicherzustellen, dass die minimale JSON-Struktur existiert.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

Wird verwendet, um die Daten aus dem Tab **Config IA** aufzunehmen und die Konfiguration auf `AIProject1` und `ChatGPT1` anzuwenden.

Das Sample verwendet:

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

Zusätzlich aktualisiert das Formular noch direkt einige Eigenschaften von `ChatGPT1`, wie Modell, Token, Endpoint und Chat-Typ.

### `TAIProjectStorage` / `AIProjectStorage1`

Wird für die Projektpersistenz verwendet.

Verwendete Methoden:

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

Die Komponente ist wirklich in den Speicher- und Ladeablauf integriert.

### `TAIProjectTasks` / `AIProjectTasks1`

Wird verwendet, um mit Aufgaben zu arbeiten, die bereits in `ProjectData` gespeichert sind.

In der aktuellen Version wird sie hauptsächlich verwendet für:

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

Die Aufgabengenerierung wird weiterhin von `main.pas` ausgeführt, mit einem manuellen Prompt an `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

Die Komponente ist im Formular vorhanden und mit `AIProject1` verbunden.

In der aktuellen Version des Samples ruft die Spezifikationsgenerierung jedoch keine öffentliche Methode dieser Komponente direkt auf. Der Spezifikationsablauf erfolgt in `main.pas`, mit manuellem Prompt, manuellem Parsing und manueller Integration in `ProjectData`.

Daher ist diese Komponente **vorhanden und verbunden**, aber **nicht der Hauptausführer des aktuellen Ablaufs**.

### `TAIProjectTaskGrid` / `TaskGrid1`

Eine tatsächlich integrierte visuelle Komponente.

Wird verwendet, um `ProjectData.planning.tasks` als Grid anzuzeigen.

Das Formular ruft auf:

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

Eine tatsächlich integrierte visuelle Komponente.

Wird verwendet, um das Statuspanel anhand des aktuellen Projekts zu aktualisieren.

Das Formular ruft auf:

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

Die Komponente ist im Formular vorhanden und mit dem Projekt verbunden.

In der aktuellen Version ist sie kein zentraler Bestandteil des demonstrierten visuellen Ablaufs. Es gibt keinen vollständigen Tab oder Bereich für Aufgabenaktionen, der dem Benutzer in diesem Sample angezeigt wird.

### `TAIProjectDescription` / `AIProjectDescription1`

Die Komponente ist vorhanden und mit dem Projekt verbunden.

In der aktuellen Version des Samples wird sie nicht direkt im Hauptablauf für Spezifikations- oder Aufgabengenerierung verwendet.

---

## Vorhandene oder erwähnte, aber nicht vollständig demonstrierte Komponenten

### Agents

Die frühere Dokumentation sagte, dass Agents aus dem Sample entfernt wurden. Im aktuellen Projektzustand ist diese Entfernung noch nicht vollständig.

Das Sample enthält weiterhin:

- Tab `Agent`;
- `TAIAgentManagerFrame`;
- Verweise auf Agent-Units;
- Schaltflächen und Methoden zur Agent-Generierung;
- Abhängigkeit vom Paket `openai_agent` in der `.lpi`.

Daher sind Agents **teilweise vorhanden**, aber der Hauptablauf des Samples bleibt Spezifikations- und Aufgabengenerierung.

### Gantt und Timeline

Das frühere README beschrieb Gantt- und Timeline-Tabs als Teil des Hauptablaufs.

In der aktuellen Version des Samples werden diese Tabs noch nicht vollständig in der Hauptoberfläche demonstriert.

Die Komponente `TAIProjectGantt` ist in `main.pas` deklariert, aber der aktuelle Bildschirm zeigt keinen vollständigen Gantt-Tab, der in den Ablauf integriert ist. Es gibt auch keinen vollständigen Timeline-Tab im aktuellen Formular.

### Berichte

Das Sample besitzt Schaltflächen und Methoden für Zusammenfassung, Aufgabenbericht, Agent-Bericht, Markdown-Export und JSON-Export.

In der aktuellen Version werden diese Berichte durch LLM-Aufrufe im Formular selbst erzeugt, nicht durch einen vollständigen visuellen Ablauf auf Basis von `TAIProjectReports`.

---

## Generierte Datei

Das Sample speichert das Projekt in der festen Datei:

```text
project_tasklist_demo.aiproj.json
```

Diese Datei enthält das vollständige Projekt-JSON, einschließlich:

- `project`;
- `agile_documents`;
- `planning.tasks`;
- weiterer Strukturen, die durch `AIProject1.EnsureProjectStructure` garantiert werden.

---

## Ausführung des aktuellen Ablaufs

1. Öffnen Sie `project_tasklist_ai_demo.lpi` in Lazarus.
2. Kompilieren und ausführen.
3. Zum Tab **Config IA** wechseln.
4. Anbieter und Modell auswählen.
5. Token oder Endpoint je nach Anbieter eingeben.
6. Auf **Aplicar Configuração** klicken.
7. Auf **Testar IA** klicken, um die Kommunikation zu validieren.
8. Zum Tab **Projeto** wechseln.
9. Name, Ziel, Einschränkungen und Lieferobjekte ausfüllen.
10. Die Spezifikation mit **Gerar Descrição Elaborada (IA)** erzeugen, aktuell im Tab **Tarefas** verfügbar.
11. Aufgaben mit **Gerar Tarefas com IA** erzeugen.
12. Ergebnis im Tab **Tarefas** prüfen.
13. JSON und Logs im Tab **JSON/Log** prüfen.
14. Projekt mit **Salvar Projeto** speichern.
15. Mit **Carregar Projeto** erneut laden.

---

## Bekannte Einschränkungen dieser Version

- Das Formular konzentriert weiterhin viel Prompt-, Parsing- und JSON-Validierungslogik.
- `TAIProjectSpecification` ist verbunden, aber der aktuelle Spezifikationsablauf wird noch manuell von `main.pas` ausgeführt.
- `TAIProjectTasks` wird zum Neuberechnen und Abfragen von Aufgaben verwendet, aber die Aufgabengenerierung erfolgt weiterhin im Formular.
- Agents erscheinen noch teilweise im Sample, obwohl sie nicht der Hauptfokus der Demo sind.
- Gantt und Timeline sind noch nicht als vollständige Tabs im Formular verfügbar.
- Markdown-Export und JSON-Validierung verwenden weiterhin LLM-Aufrufe, statt ausschließlich Bericht-/Exportkomponenten zu nutzen.
- Speichern, Laden und Zurücksetzen haben noch Hilfsaufrufe an das LLM, obwohl diese Operationen lokal sein können.
- Die gespeicherte Datei verwendet den festen Namen `project_tasklist_demo.aiproj.json`.

---

## Tatsächlicher Umfang dieser Version

Dieses Sample sollte als praktische Anfangsintegration zwischen `TCHATGPT`, `TAIProject`, `TAIProjectLLMConfig`, `TAIProjectStorage`, `TAIProjectTasks`, `TAIProjectTaskGrid` und `TAIProjectStatusPanel` verstanden werden.

Es sollte noch nicht als finales Beispiel der idealen Architektur des Pakets `AI Project` behandelt werden.
