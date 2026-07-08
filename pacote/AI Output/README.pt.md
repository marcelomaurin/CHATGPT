# 📄 Documentação da Aba `AI Output`

> [!NOTE]
> Esta pasta contém os componentes Lazarus responsáveis por transformar saídas de IA em resultados utilizáveis: classificação, relatórios, documentos, planilhas, texto e comandos de impressão.

A aba **AI Output** representa a camada de saída do projeto. Ela não executa modelos de IA; ela organiza, formata, exporta ou envia os resultados produzidos por outros componentes.

---

## Objetivo

Fornecer componentes para:

- normalizar probabilidades e resultados de classificação;
- gerar relatórios em PDF, DOCX, XLSX e TXT;
- criar, carregar, editar e salvar documentos Word/OpenXML;
- visualizar documentos Word em canvas Lazarus;
- enviar comandos reais para impressoras POS, térmicas e de etiqueta.

---

## Componentes principais

| Componente | Unidade | Descrição | Propriedades importantes | Métodos principais | Uso pelo agente de IA |
|---|---|---|---|---|---|
| **TAIOutputData** | `aioutput.pas` | Processa probabilidades e resultados de classificação. | `Classes`, `Probabilities`, `ClassificationResult` | `SoftMax`, `GetBestClassIndex`, `GetBestClassName`, `UpdateResult` | Transformar logits/probabilidades em uma resposta final compreensível. |
| **TAIPDFOutput** | `aioutput_docs.pas` | Gera documentos PDF nativos usando `fpPDF`. | `FileName`, `Title`, `Author`, `Subject` | `StartDocument`, `AddPage`, `AddText`, `SavePDF` | Criar relatórios formais, certificados e documentos prontos para impressão. |
| **TAIWordOutput** | `aioutput_docs.pas` | Gera documento Word/HTML compatível. | `FileName`, `Title` | `AddHeading`, `AddParagraph`, `AddTable`, `SaveWord` | Exportar textos, pareceres, resumos e tabelas para edição posterior. |
| **TAIExcelOutput** | `aioutput_docs.pas` | Gera saída tabular em formato compatível com Excel. | `FileName` | `SetCell`, `SaveExcel` | Exportar métricas, histórico de predição, logs e dados tabulares. |
| **TAITXTOutput** | `aioutput_docs.pas` | Exporta texto simples. | `FileName` | `AddLine`, `AddHeader`, `Clear`, `SaveText` | Criar logs, resumos leves e arquivos para integração simples. |
| **TAIOutputDocs** | `aioutput_docs.pas` | Centraliza a geração de múltiplos formatos. | `FileNamePDF`, `FileNameWord`, `FileNameExcel`, `FileNameTXT`, `Title`, `Author`, `Subject` | `AddHeading`, `AddParagraph`, `AddTable`, `SetCell`, `SaveToPDF`, `SaveToWord`, `SaveToExcel`, `SaveToTXT`, `SaveAll` | Gerar vários formatos em uma única etapa de pipeline. |
| **TAIWordDocument** | `aiworddocument.pas` | Cria, abre, edita e salva arquivos DOCX usando OpenXML. | `FileName`, `Title`, `Author`, `Subject`, `PreserveUnsupportedXml` | `NewDocument`, `LoadFromFile`, `SaveToFile`, `AddTitle`, `AddHeading`, `AddParagraph`, `AddImage`, `AddTable`, `ReplaceText`, `SetVariable`, `ApplyVariables` | Criar documentos editáveis, preencher modelos e gerar documentos estruturados. |
| **TAIWordLayoutEngine** | `aiwordviewer.pas` | Monta o layout de páginas de um documento Word para visualização. | `Pages`, `Zoom`, `DPI` | `BuildLayout`, `Clear` | Permitir pré-visualização visual de documentos gerados. |
| **TAIWordRenderEngine** | `aiwordviewer.pas` | Renderiza páginas, parágrafos, imagens e tabelas em `TCanvas`. | — | `RenderPage`, `RenderParagraph`, `RenderImage`, `RenderTable` | Exibir documentos em tela antes de salvar/imprimir. |
| **TAIPOSPrinter** | `aiposprinter.pas` | Envia comandos crus para impressoras POS, térmicas e de etiqueta. | `Prompt`, `InterfaceType`, `PrinterModel`, `Protocol`, `DeviceName`, `Host`, `Port`, `SerialBaud`, `Active`, `LastError` | `OpenConnection`, `CloseConnection`, `SendRawBytes`, `SendRawString`, `PrintText`, `PrintTextLine`, `SetBold`, `SetNormal`, `SetDoubleText`, `SetUnderline`, `AlignCenter`, `AlignLeft`, `AlignRight`, `CutPaper`, `OpenDrawer`, `PrintBarcode`, `PrintQRCode`, `Beep` | Imprimir recibos, etiquetas, códigos de barras e QR Codes a partir de ações de agentes. |

---

## Impressão: conceitos corretos

A impressão deve separar três conceitos diferentes.

| Conceito | O que é | Exemplos |
|---|---|---|
| **Linguagem da impressora** | Conjunto de comandos entendidos pelo firmware. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **Transporte** | Caminho usado para enviar bytes. | Serial, TCP 9100, USB raw, spooler, arquivo |
| **Modo de renderização** | Forma de gerar o conteúdo antes de enviar. | Comandos crus ou canvas nativo do sistema operacional |

### Observação importante

`Native OS` **não é protocolo de impressora**. Ele representa impressão pelo sistema operacional, por exemplo usando `Printer.Canvas` do Lazarus. Por isso ele não deve ser tratado como igual a `ESC/POS`, `ZPL`, `TSPL` ou `EPL`.

---

## Protocolos e linguagens de impressão

| Linguagem | Uso correto | Observações |
|---|---|---|
| **ESC/POS** | Impressoras térmicas de cupom/recibo. | Ideal para texto, QR Code, código de barras, gaveta e guilhotina. |
| **ZPL** | Impressoras de etiqueta Zebra ou compatíveis. | O documento normalmente começa com `^XA` e termina com `^XZ`. |
| **TSPL/TSPL2** | Impressoras de etiqueta TSC ou compatíveis. | Usa comandos como `SIZE`, `GAP`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `PRINT`. |
| **EPL/EPL2** | Impressoras Eltron/Zebra antigas. | Deve ser considerado experimental até validação real do modelo. |
| **Native OS** | Impressão via spooler/canvas do sistema. | Não deve enviar comandos ESC/POS/ZPL/TSPL diretamente. |

---

## Modelos atuais no componente de impressão

| Modelo | Tipo esperado | Linguagem recomendada | Observação |
|---|---|---|---|
| **Elgin i9** | Cupom/recibo 80 mm | ESC/POS | Pode ter guilhotina, gaveta e QR Code conforme firmware/modelo. |
| **QR203** | Mini térmica 58 mm | ESC/POS ou compatível | Geralmente não possui guilhotina nem gaveta. |
| **Elgin L42DT** | Etiqueta | ZPL, TSPL ou EPL conforme firmware | Não tratar como ESC/POS por padrão sem confirmação do modelo. |

---

## Recomendações para evolução do `TAIPOSPrinter`

O componente atual funciona como base, mas precisa evoluir para representar melhor a realidade dos protocolos.

### 1. Separar protocolo, transporte e renderização

Modelo recomendado:

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

### 2. Não iniciar impressão ao abrir conexão

`OpenConnection` deve apenas abrir serial, socket TCP ou spooler.

A geração de comandos deve ficar em métodos separados:

```pascal
BeginJob;
PrintTextLine;
PrintBarcode;
PrintQRCode;
EndJob;
SendDocument;
```

### 3. Separar `CutPaper` de `PrintLabel`

`CutPaper` é guilhotina.

`^XZ`, `PRINT 1,1` e `P1` não são guilhotina; são comandos de fechamento/impressão de etiqueta. Portanto:

- ESC/POS: `CutPaper` pode enviar comando de corte.
- ZPL: `EndLabel` deve gerar `^XZ`.
- TSPL: `PrintLabel` deve gerar `PRINT 1,1`.
- EPL: `PrintLabel` deve gerar `P1`.

### 4. Gerar bytes, não strings comuns

Protocolos de impressora trabalham com bytes. O ideal é criar um construtor de bytes:

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

## Exemplo básico — TAIOutputData

```pascal
var
  OutData: TAIOutputData;
begin
  OutData := TAIOutputData.Create(Self);
  try
    OutData.Classes.Add('Normal');
    OutData.Classes.Add('Alerta');

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

## Exemplo básico — TAIPOSPrinter com ESC/POS

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
    Printer.PrintTextLine('TESTE DE IMPRESSAO');
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

## Sample relacionado

```text
pacote/samples/AI Output/posprinter_demo
```

O demo deve ser usado para validar comandos reais de impressão. A evolução recomendada é trocar `Simulation Mode` por:

```text
Preview only
```

Comportamento esperado:

- `Preview only = True`: gerar comandos reais e mostrar no log em texto/hex.
- `Preview only = False`: gerar os mesmos comandos e enviar para a impressora.
- Nunca informar sucesso quando nenhum comando foi enviado.

---

## Ponte de IA e Hardware

Os componentes da aba **AI Output** usam a propriedade published `Prompt` para documentar sua API interna. Isso permite que agentes (`TAIAgent`) entendam quais propriedades configurar e quais métodos executar.

Para componentes ligados a hardware, como `TAIPOSPrinter`, o `Prompt` e a documentação devem deixar claras as limitações reais do modelo físico e da linguagem de impressão usada.
