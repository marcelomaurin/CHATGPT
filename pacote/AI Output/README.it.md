# 📄 Documentazione della scheda `AI Output`

> [!NOTE]
> Questa cartella contiene i componenti Lazarus che trasformano le uscite dell'IA in risultati utilizzabili: classificazione, report, documenti, fogli di calcolo, testo e comandi di stampa.

La scheda **AI Output** rappresenta il livello di uscita del progetto. Non esegue direttamente modelli di IA; organizza, formatta, esporta o invia i risultati prodotti da altri componenti.

---

## Obiettivo

Fornire componenti per:

- normalizzare probabilità e risultati di classificazione;
- generare report in PDF, DOCX, XLSX e TXT;
- creare, caricare, modificare e salvare documenti Word/OpenXML;
- visualizzare documenti Word su un canvas Lazarus;
- inviare comandi reali a stampanti POS, termiche e per etichette.

---

## Componenti principali

| Componente | Unit | Descrizione | Proprietà importanti | Metodi principali |
|---|---|---|---|---|
| **TAIOutputData** | `aioutput.pas` | Elabora probabilità e risultati di classificazione. | `Classes`, `Probabilities`, `ClassificationResult` | `SoftMax`, `GetBestClassIndex`, `GetBestClassName`, `UpdateResult` |
| **TAIPDFOutput** | `aioutput_docs.pas` | Genera documenti PDF nativi con `fpPDF`. | `FileName`, `Title`, `Author`, `Subject` | `StartDocument`, `AddPage`, `AddText`, `SavePDF` |
| **TAIWordOutput** | `aioutput_docs.pas` | Genera output compatibile con Word/HTML. | `FileName`, `Title` | `AddHeading`, `AddParagraph`, `AddTable`, `SaveWord` |
| **TAIExcelOutput** | `aioutput_docs.pas` | Genera output tabellare compatibile con Excel. | `FileName` | `SetCell`, `SaveExcel` |
| **TAITXTOutput** | `aioutput_docs.pas` | Esporta testo semplice. | `FileName` | `AddLine`, `AddHeader`, `Clear`, `SaveText` |
| **TAIOutputDocs** | `aioutput_docs.pas` | Centralizza diversi formati di documento. | `FileNamePDF`, `FileNameWord`, `FileNameExcel`, `FileNameTXT`, `Title`, `Author`, `Subject` | `AddHeading`, `AddParagraph`, `AddTable`, `SetCell`, `SaveAll` |
| **TAIWordDocument** | `aiworddocument.pas` | Crea, apre, modifica e salva file DOCX usando OpenXML. | `FileName`, `Title`, `Author`, `Subject`, `PreserveUnsupportedXml` | `NewDocument`, `LoadFromFile`, `SaveToFile`, `AddParagraph`, `AddImage`, `AddTable`, `ReplaceText`, `SetVariable`, `ApplyVariables` |
| **TAIWordLayoutEngine** | `aiwordviewer.pas` | Costruisce il modello visivo delle pagine di un documento Word. | `Pages`, `Zoom`, `DPI` | `BuildLayout`, `Clear` |
| **TAIWordRenderEngine** | `aiwordviewer.pas` | Renderizza pagine, paragrafi, immagini e tabelle su `TCanvas`. | — | `RenderPage`, `RenderParagraph`, `RenderImage`, `RenderTable` |
| **TAIPOSPrinter** | `aiposprinter.pas` | Invia comandi raw a stampanti POS, termiche e per etichette. | `InterfaceType`, `PrinterModel`, `Protocol`, `DeviceName`, `Host`, `Port`, `SerialBaud`, `Active`, `LastError` | `OpenConnection`, `CloseConnection`, `PrintTextLine`, `PrintBarcode`, `PrintQRCode`, `CutPaper`, `OpenDrawer`, `Beep` |

---

## Stampa: concetti corretti

La stampa deve separare tre concetti diversi.

| Concetto | Significato | Esempi |
|---|---|---|
| **Linguaggio della stampante** | Comandi compresi dal firmware. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **Trasporto** | Percorso usato per inviare byte. | Seriale, TCP 9100, USB raw, spooler, file |
| **Modalità di rendering** | Come viene prodotto il contenuto prima dell'invio. | Comandi raw o canvas del sistema operativo |

`Native OS` **non è un protocollo di stampante**. Rappresenta la stampa tramite sistema operativo, ad esempio con `Printer.Canvas` di Lazarus.

---

## Linguaggi di stampa

| Linguaggio | Uso corretto | Osservazioni |
|---|---|---|
| **ESC/POS** | Stampanti termiche per ricevute/POS. | Testo, QR Code, codici a barre, cassetto e taglio carta. |
| **ZPL** | Stampanti per etichette Zebra o compatibili. | L'etichetta normalmente inizia con `^XA` e termina con `^XZ`. |
| **TSPL/TSPL2** | Stampanti per etichette TSC o compatibili. | Usa `SIZE`, `GAP`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `PRINT`. |
| **EPL/EPL2** | Vecchie stampanti Eltron/Zebra. | Da mantenere sperimentale finché il modello non viene validato. |
| **Native OS** | Spooler/canvas del sistema operativo. | Non deve inviare direttamente comandi ESC/POS/ZPL/TSPL. |

---

## Raccomandazioni per `TAIPOSPrinter`

- Separare linguaggio, trasporto e modalità di rendering.
- `OpenConnection` deve aprire la connessione, non iniziare un documento.
- Separare `CutPaper` da `PrintLabel`.
- Generare byte (`TBytes`), non stringhe comuni.
- Mostrare errori reali quando la connessione o l'invio falliscono.
- Non mostrare successo se nessun comando è stato generato o inviato.

Modello consigliato:

```pascal
TPrinterLanguage = (plEscPos, plZpl, plTspl, plEpl);
TPrinterTransport = (ptSerial, ptTcp9100, ptFile, ptWindowsRawSpooler, ptCupsRaw);
TPrinterRenderMode = (rmRawCommand, rmNativeCanvas);
```

---

## Esempio correlato

```text
pacote/samples/AI Output/posprinter_demo
```

Il demo dovrebbe evolvere da `Simulation Mode` a:

```text
Preview only
```

Comportamento previsto:

- `Preview only = True`: generare comandi reali e mostrarli in testo/hex.
- `Preview only = False`: generare gli stessi comandi e inviarli al trasporto selezionato.
- Non mostrare mai successo se nessun comando è stato inviato.

---

## Ponte IA e hardware

I componenti di **AI Output** usano la proprietà published `Prompt` per documentare la loro API interna. Questo permette agli agenti (`TAIAgent`) di capire quali proprietà configurare e quali metodi eseguire.
