# 📄 Lazarus AI Suite — Tab: `AI Output`

> [!NOTE]
> Components for structured AI output, native document generation and printer output in Lazarus/Free Pascal.

This folder contains the output layer of the project. It is responsible for transforming AI decisions, reports and generated content into usable artifacts such as PDF, DOCX, XLSX, TXT and printer commands.

---

## 🌐 Select Language / Selecione o Idioma

| Language | Country Flag | Documentation Link |
|---|---|---|
| **Português (PT)** | 🇧🇷 / 🇵🇹 | 📄 [README.pt.md](README.pt.md) |
| **English (EN)** | 🇺🇸 / 🇬🇧 | 📄 [README.en.md](README.en.md) |
| **Español (ES)** | 🇪🇸 / 🇲🇽 | 📄 [README.es.md](README.es.md) |
| **Français (FR)** | 🇫🇷 | 📄 [README.fr.md](README.fr.md) |
| **Italiano (IT)** | 🇮🇹 | 📄 [README.it.md](README.it.md) |
| **العربية (AR)** | 🇦🇪 / 🇸🇦 | 📄 [README.ar.md](README.ar.md) |

---

## 📦 Components in this folder

| Area | Components / units | Purpose |
|---|---|---|
| AI decision output | `TAIOutputData` / `aioutput.pas` | Applies SoftMax, selects the most probable class and formats classification results. |
| Document output | `TAIPDFOutput`, `TAIWordOutput`, `TAIExcelOutput`, `TAITXTOutput`, `TAIOutputDocs` / `aioutput_docs.pas` | Generates native reports and data exports in PDF, Word-compatible, Excel-compatible and TXT formats. |
| DOCX editing | `TAIWordDocument` / `aiworddocument.pas` | Creates, loads, edits and saves DOCX documents using OpenXML structures. |
| DOCX preview | `TAIWordLayoutEngine`, `TAIWordRenderEngine` / `aiwordviewer.pas` | Builds a visual layout model and renders Word document pages on a Lazarus canvas. |
| POS / label printing | `TAIPOSPrinter` / `aiposprinter.pas` | Sends raw printer commands by serial or TCP/IP for receipt and label printers. |
| Printer command generators | `imp_generico.pas`, `imp_elgini9.pas`, `imp_qr203.pas`, `imp_elginl42dt.pas` | Current printer command drivers for ESC/POS, ZPL, TSPL and EPL-style output. |

---

## 🖨️ Printer protocol note

Printer output must separate three different concepts:

| Concept | Meaning | Examples |
|---|---|---|
| **Language** | Commands understood by the printer firmware. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **Transport** | How bytes are sent to the device. | Serial, TCP 9100, USB raw, spooler, file |
| **Render mode** | How content is produced before printing. | Raw commands or OS canvas rendering |

`Native OS` is not a printer protocol. It is an operating-system rendering/spooler mode. It should not be mixed with ESC/POS, ZPL, TSPL or EPL in the same protocol enum.

Recommended interpretation:

- **ESC/POS**: receipt printers, fiscal/non-fiscal POS printers, cash drawer, cut paper, QR Code and barcodes.
- **ZPL**: Zebra-compatible label printers.
- **TSPL/TSPL2**: TSC-compatible label printers.
- **EPL/EPL2**: older Eltron/Zebra label language; keep as experimental unless the target model is validated.
- **Native OS**: canvas/spooler printing through Lazarus `Printers`; not raw printer command mode.

---

## 🧪 Related sample

See:

```text
pacote/samples/AI Output/posprinter_demo
```

The POS printer demo should be treated as a protocol validation sample. Its next evolution should replace fake simulation with real command preview:

```text
Preview only = generate real commands and show them in text/hex
Send to printer = generate the same commands and send them by the selected transport
```

The demo should not show success when no real command was generated or sent.

---

## ⚡ AI and Hardware Integration

Each component in this folder exposes a published `Prompt` property or a documented component API so AI agents (`TAIAgent`) can understand its purpose, important properties and callable methods at runtime.

For hardware-oriented components such as `TAIPOSPrinter`, the prompt/documentation must describe the real protocol limits instead of promising generic support for all printer models.
