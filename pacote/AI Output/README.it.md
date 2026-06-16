# 📄 Documentazione della Scheda AI Output

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Output**.

## Uscita Strutturata dei Risultati, Elaborazione Decisionale e Generazione di Documenti.
Genera eleganti report nativi IA in molteplici formati (.pdf, .docx, .xlsx, .txt) senza dipendenze esterne.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIOutputData** | Elaboratore decisionale e attivatore SoftMax. | `Classes, Probabilities` | `SoftMax, GetBestClassIndex, GetBestClassName` | Determinare la previsione più probabile e formattare i risultati analitici. |
| **TAIPDFOutput** | Generatore di documenti PDF nativo. | `FileName, Title, Author` | `StartDocument, AddPage, AddText, SavePDF` | Generare report formali e documenti PDF stampabili. |
| **TAIWordOutput** | Generatore di report Word (.docx) nativo. | `FileName, Title` | `AddHeading, AddParagraph, AddTable, SaveWord` | Esportare riepiloghi testuali e tabelle compatibili con Microsoft Word. |
| **TAIExcelOutput** | Generatore di fogli di calcolo Excel (.xlsx) nativo. | `FileName` | `SetCell, SaveExcel` | Esportare dati tabulari predittivi, statistiche e metriche di accuratezza. |
| **TAITXTOutput** | Formattatore di testo ASCII grezzo. | `FileName` | `AddLine, AddHeader, SaveText` | Generare file di testo piano leggeri per i log operativi. |
| **TAIOutputDocs** | Suite di output documentale unificata. | `Title, Author, Subject` | `AddParagraph, AddTable, SaveAll` | Generare tutti e quattro i formati di documento contemporaneamente con un unico comando. |

### 💻 Esempio di Codice Lazarus (TAIOutputData)

```pascal
var
  MyComponent: TAIOutputData;
begin
  MyComponent := TAIOutputData.Create(Self);
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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
