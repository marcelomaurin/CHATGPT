# 📄 AI Output Tab Documentation

> [!NOTE]
> This folder contains Lazarus components that transform AI output into usable results: classification results, reports, documents, spreadsheets, text files and printer commands.

The **AI Output** tab is the output layer of the project. It does not run AI models directly; it formats, exports, stores or sends results produced by other components.

---

## Purpose

Provide components to:

- normalize probabilities and classification results;
- generate reports as PDF, DOCX, XLSX and TXT;
- create, load, edit and save Word/OpenXML documents;
- preview Word documents on a Lazarus canvas;
- send real commands to POS, thermal receipt and label printers.

---

## Main components

| Component | Unit | Description | Important properties | Main methods | AI agent role |
|---|---|---|---|---|---|
| **TAIOutputData** | `aioutput.pas` | Processes probabilities and classification results. | `Classes`, `Probabilities`, `ClassificationResult` | `SoftMax`, `GetBestClassIndex`, `GetBestClassName`, `UpdateResult` | Convert logits/probabilities into a readable final decision. |
| **TAIPDFOutput** | `aioutput_docs.pas` | Generates native PDF documents using `fpPDF`. | `FileName`, `Title`, `Author`, `Subject` | `StartDocument`, `AddPage`, `AddText`, `SavePDF` | Create reports, certificates and printable documents. |
| **TAIWordOutput** | `aioutput_docs.pas` | Generates Word/HTML-compatible output. | `FileName`, `Title` | `AddHeading`, `AddParagraph`, `AddTable`, `SaveWord` | Export text reports, summaries and tables for later editing. |
| **TAIExcelOutput** | `aioutput_docs.pas` | Generates Excel-compatible tabular output. | `FileName` | `SetCell`, `SaveExcel` | Export metrics, prediction history, logs and tabular data. |
| **TAITXTOutput** | `aioutput_docs.pas` | Exports plain text. | `FileName` | `AddLine`, `AddHeader`, `Clear`, `SaveText` | Create logs, lightweight summaries and simple integration files. |
| **TAIOutputDocs** | `aioutput_docs.pas` | Centralizes multiple document formats. | `FileNamePDF`, `FileNameWord`, `FileNameExcel`, `FileNameTXT`, `Title`, `Author`, `Subject` | `AddHeading`, `AddParagraph`, `AddTable`, `SetCell`, `SaveToPDF`, `SaveToWord`, `SaveToExcel`, `SaveToTXT`, `SaveAll` | Generate multiple output formats in one pipeline step. |
| **TAIWordDocument** | `aiworddocument.pas` | Creates, opens, edits and saves DOCX files using OpenXML. | `FileName`, `Title`, `Author`, `Subject`, `PreserveUnsupportedXml` | `NewDocument`, `LoadFromFile`, `SaveToFile`, `AddTitle`, `AddHeading`, `AddParagraph`, `AddImage`, `AddTable`, `ReplaceText`, `SetVariable`, `ApplyVariables` | Create editable documents, fill templates and generate structured reports. |
| **TAIWordLayoutEngine** | `aiwordviewer.pas` | Builds a page layout model for Word document preview. | `Pages`, `Zoom`, `DPI` | `BuildLayout`, `Clear` | Enable visual preview of generated documents. |
| **TAIWordRenderEngine** | `aiwordviewer.pas` | Renders pages, paragraphs, images and tables on `TCanvas`. | — | `RenderPage`, `RenderParagraph`, `RenderImage`, `RenderTable` | Display documents on screen before saving or printing. |
| **TAIPOSPrinter** | `aiposprinter.pas` | Sends raw commands to POS, thermal and label printers. | `Prompt`, `InterfaceType`, `PrinterModel`, `Protocol`, `DeviceName`, `Host`, `Port`, `SerialBaud`, `Active`, `LastError` | `OpenConnection`, `CloseConnection`, `SendRawBytes`, `SendRawString`, `PrintText`, `PrintTextLine`, `SetBold`, `SetNormal`, `SetDoubleText`, `SetUnderline`, `AlignCenter`, `AlignLeft`, `AlignRight`, `CutPaper`, `OpenDrawer`, `PrintBarcode`, `PrintQRCode`, `Beep` | Print receipts, labels, barcodes and QR Codes from agent actions. |

---

## Printing: correct concepts

Printing must separate three different concepts.

| Concept | Meaning | Examples |
|---|---|---|
| **Printer language** | Commands understood by the printer firmware. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **Transport** | Path used to send bytes to the device. | Serial, TCP 9100, USB raw, spooler, file |
| **Render mode** | How content is produced before sending. | Raw commands or operating-system canvas |

### Important note

`Native OS` is **not a printer protocol**. It represents operating-system printing, for example through Lazarus `Printer.Canvas`. It should not be treated as equivalent to `ESC/POS`, `ZPL`, `TSPL` or `EPL`.

---

## Printer languages

| Language | Correct use | Notes |
|---|---|---|
| **ESC/POS** | Thermal receipt/POS printers. | Good for text, QR Code, barcode, cash drawer and paper cutter. |
| **ZPL** | Zebra-compatible label printers. | A label usually starts with `^XA` and ends with `^XZ`. |
| **TSPL/TSPL2** | TSC-compatible label printers. | Uses commands such as `SIZE`, `GAP`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `PRINT`. |
| **EPL/EPL2** | Older Eltron/Zebra label printers. | Keep as experimental unless the target model is validated. |
| **Native OS** | OS spooler/canvas printing. | Should not send ESC/POS/ZPL/TSPL commands directly. |

---

## Current printer models

| Model | Expected type | Recommended language | Note |
|---|---|---|---|
| **Elgin i9** | 80 mm receipt printer | ESC/POS | May support cutter, drawer and QR Code depending on firmware/model. |
| **QR203** | 58 mm mini thermal printer | ESC/POS or compatible | Usually does not provide cutter or drawer support. |
| **Elgin L42DT** | Label printer | ZPL, TSPL or EPL depending on firmware | Do not treat as ESC/POS by default without validating the exact model. |

---

## Recommended `TAIPOSPrinter` evolution

The current component is a useful base, but it should evolve to represent real printer protocols more accurately.

### 1. Separate protocol, transport and rendering

Recommended model:

```pascal
TPrinterLanguage = (
  plEscPos,
  plZpl,
  plTspl,
  plEpl
);

TPrinterTransport = (
  ptSerial,
  ptTcp9100,
  ptFile,
  ptWindowsRawSpooler,
  ptCupsRaw
);

TPrinterRenderMode = (
  rmRawCommand,
  rmNativeCanvas
);
```

### 2. Do not start printing when opening a connection

`OpenConnection` should only open serial, TCP socket or spooler.

Command generation should be handled separately:

```pascal
BeginJob;
PrintTextLine;
PrintBarcode;
PrintQRCode;
EndJob;
SendDocument;
```

### 3. Separate `CutPaper` from `PrintLabel`

`CutPaper` means cutter/guillotine.

`^XZ`, `PRINT 1,1` and `P1` are not cutter commands; they are label closing/printing commands. Therefore:

- ESC/POS: `CutPaper` may send the cut command.
- ZPL: `EndLabel` should generate `^XZ`.
- TSPL: `PrintLabel` should generate `PRINT 1,1`.
- EPL: `PrintLabel` should generate `P1`.

### 4. Generate bytes, not regular strings

Printer protocols work with bytes. A byte builder is recommended:

```pascal
TAIByteBuilder = class
public
  procedure AddByte(B: Byte);
  procedure AddBytes(const ABytes: array of Byte);
  procedure AddAscii(const S: RawByteString);
  procedure AddTextEncoded(const S: string; AEncoding: TPrinterEncoding);
  function ToBytes: TBytes;
end;
```

---

## Basic example — TAIOutputData

```pascal
var
  OutData: TAIOutputData;
begin
  OutData := TAIOutputData.Create(Self);
  try
    OutData.Classes.Add('Normal');
    OutData.Classes.Add('Alert');

    SetLength(OutData.Probabilities, 2);
    OutData.Probabilities[0] := 1.2;
    OutData.Probabilities[1] := 3.8;

    OutData.SoftMax;
    ShowMessage(OutData.ClassificationResult);
  finally
    OutData.Free;
  end;
end;
```

---

## Basic example — TAIPOSPrinter with ESC/POS

```pascal
var
  Printer: TAIPOSPrinter;
begin
  Printer := TAIPOSPrinter.Create(Self);
  try
    Printer.InterfaceType := piEthernet;
    Printer.Host := '192.168.0.50';
    Printer.Port := 9100;
    Printer.PrinterModel := pmElginI9;
    Printer.Protocol := ppEscPos;

    if not Printer.OpenConnection then
      raise Exception.Create(Printer.LastError);

    Printer.AlignCenter;
    Printer.SetBold(True);
    Printer.PrintTextLine('PRINT TEST');
    Printer.SetNormal;
    Printer.PrintTextLine('AI Output / TAIPOSPrinter');
    Printer.PrintQRCode('https://github.com/marcelomaurin/CHATGPT');
    Printer.CutPaper;
  finally
    Printer.CloseConnection;
    Printer.Free;
  end;
end;
```

---

## Related sample

```text
pacote/samples/AI Output/posprinter_demo
```

The demo should be used to validate real printer commands. The recommended evolution is replacing `Simulation Mode` with:

```text
Preview only
```

Expected behavior:

- `Preview only = True`: generate real commands and show them in the log as text/hex.
- `Preview only = False`: generate the same commands and send them to the printer.
- Never report success when no command was sent.

---

## AI and hardware bridge

Components in the **AI Output** tab use the published `Prompt` property to document their internal API. This allows agents (`TAIAgent`) to understand which properties to configure and which methods to call.

For hardware-related components such as `TAIPOSPrinter`, the prompt and documentation must clearly describe the real limitations of the physical model and printer language being used.
