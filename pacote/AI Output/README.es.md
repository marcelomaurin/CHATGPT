# 📄 Documentación de la pestaña `AI Output`

> [!NOTE]
> Esta carpeta contiene los componentes de Lazarus responsables de transformar salidas de IA en resultados utilizables: clasificación, informes, documentos, hojas de cálculo, texto y comandos de impresión.

La pestaña **AI Output** es la capa de salida del proyecto. No ejecuta modelos de IA directamente; organiza, formatea, exporta o envía los resultados producidos por otros componentes.

---

## Objetivo

Proporcionar componentes para:

- normalizar probabilidades y resultados de clasificación;
- generar informes en PDF, DOCX, XLSX y TXT;
- crear, cargar, editar y guardar documentos Word/OpenXML;
- visualizar documentos Word en un canvas de Lazarus;
- enviar comandos reales a impresoras POS, térmicas y de etiquetas.

---

## Componentes principales

| Componente | Unidad | Descripción | Propiedades importantes | Métodos principales |
|---|---|---|---|---|
| **TAIOutputData** | `aioutput.pas` | Procesa probabilidades y resultados de clasificación. | `Classes`, `Probabilities`, `ClassificationResult` | `SoftMax`, `GetBestClassIndex`, `GetBestClassName`, `UpdateResult` |
| **TAIPDFOutput** | `aioutput_docs.pas` | Genera documentos PDF nativos usando `fpPDF`. | `FileName`, `Title`, `Author`, `Subject` | `StartDocument`, `AddPage`, `AddText`, `SavePDF` |
| **TAIWordOutput** | `aioutput_docs.pas` | Genera salida compatible con Word/HTML. | `FileName`, `Title` | `AddHeading`, `AddParagraph`, `AddTable`, `SaveWord` |
| **TAIExcelOutput** | `aioutput_docs.pas` | Genera salida tabular compatible con Excel. | `FileName` | `SetCell`, `SaveExcel` |
| **TAITXTOutput** | `aioutput_docs.pas` | Exporta texto simple. | `FileName` | `AddLine`, `AddHeader`, `Clear`, `SaveText` |
| **TAIOutputDocs** | `aioutput_docs.pas` | Centraliza varios formatos de documento. | `FileNamePDF`, `FileNameWord`, `FileNameExcel`, `FileNameTXT`, `Title`, `Author`, `Subject` | `AddHeading`, `AddParagraph`, `AddTable`, `SetCell`, `SaveAll` |
| **TAIWordDocument** | `aiworddocument.pas` | Crea, abre, edita y guarda DOCX usando OpenXML. | `FileName`, `Title`, `Author`, `Subject`, `PreserveUnsupportedXml` | `NewDocument`, `LoadFromFile`, `SaveToFile`, `AddParagraph`, `AddImage`, `AddTable`, `ReplaceText`, `SetVariable`, `ApplyVariables` |
| **TAIWordLayoutEngine** | `aiwordviewer.pas` | Construye el modelo visual de páginas de un documento Word. | `Pages`, `Zoom`, `DPI` | `BuildLayout`, `Clear` |
| **TAIWordRenderEngine** | `aiwordviewer.pas` | Renderiza páginas, párrafos, imágenes y tablas en `TCanvas`. | — | `RenderPage`, `RenderParagraph`, `RenderImage`, `RenderTable` |
| **TAIPOSPrinter** | `aiposprinter.pas` | Envía comandos crudos a impresoras POS, térmicas y de etiquetas. | `InterfaceType`, `PrinterModel`, `Protocol`, `DeviceName`, `Host`, `Port`, `SerialBaud`, `Active`, `LastError` | `OpenConnection`, `CloseConnection`, `PrintTextLine`, `PrintBarcode`, `PrintQRCode`, `CutPaper`, `OpenDrawer`, `Beep` |

---

## Impresión: conceptos correctos

La impresión debe separar tres conceptos diferentes.

| Concepto | Qué significa | Ejemplos |
|---|---|---|
| **Lenguaje de impresora** | Comandos entendidos por el firmware. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **Transporte** | Camino usado para enviar bytes. | Serial, TCP 9100, USB raw, spooler, archivo |
| **Modo de renderizado** | Forma de producir el contenido antes de enviarlo. | Comandos crudos o canvas del sistema operativo |

`Native OS` **no es un protocolo de impresora**. Representa impresión por el sistema operativo, por ejemplo con `Printer.Canvas` de Lazarus.

---

## Lenguajes de impresión

| Lenguaje | Uso correcto | Observaciones |
|---|---|---|
| **ESC/POS** | Impresoras térmicas de recibos/POS. | Texto, QR Code, códigos de barras, cajón y corte de papel. |
| **ZPL** | Impresoras de etiquetas Zebra o compatibles. | La etiqueta normalmente empieza con `^XA` y termina con `^XZ`. |
| **TSPL/TSPL2** | Impresoras de etiquetas TSC o compatibles. | Usa `SIZE`, `GAP`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `PRINT`. |
| **EPL/EPL2** | Impresoras Eltron/Zebra antiguas. | Mantener como experimental hasta validar el modelo. |
| **Native OS** | Spooler/canvas del sistema operativo. | No debe enviar comandos ESC/POS/ZPL/TSPL directamente. |

---

## Recomendaciones para `TAIPOSPrinter`

- Separar lenguaje, transporte y modo de renderizado.
- `OpenConnection` debe abrir la conexión, no iniciar un documento.
- Separar `CutPaper` de `PrintLabel`.
- Generar bytes (`TBytes`), no strings comunes.
- Mostrar errores reales cuando la conexión o el envío fallen.
- No informar éxito si no se generó ni envió ningún comando.

Modelo recomendado:

```pascal
TPrinterLanguage = (plEscPos, plZpl, plTspl, plEpl);
TPrinterTransport = (ptSerial, ptTcp9100, ptFile, ptWindowsRawSpooler, ptCupsRaw);
TPrinterRenderMode = (rmRawCommand, rmNativeCanvas);
```

---

## Sample relacionado

```text
pacote/samples/AI Output/posprinter_demo
```

El demo debe evolucionar de `Simulation Mode` a:

```text
Preview only
```

Comportamiento esperado:

- `Preview only = True`: generar comandos reales y mostrarlos en texto/hex.
- `Preview only = False`: generar los mismos comandos y enviarlos al transporte seleccionado.
- Nunca mostrar éxito cuando ningún comando fue enviado.

---

## Puente de IA y hardware

Los componentes de **AI Output** usan la propiedad published `Prompt` para documentar su API interna. Esto permite que agentes (`TAIAgent`) comprendan qué propiedades configurar y qué métodos ejecutar.
