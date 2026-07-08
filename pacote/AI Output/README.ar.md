# 📄 توثيق علامة التبويب `AI Output`

> [!NOTE]
> يحتوي هذا المجلد على مكونات Lazarus المسؤولة عن تحويل مخرجات الذكاء الاصطناعي إلى نتائج قابلة للاستخدام: التصنيف، التقارير، المستندات، الجداول، النصوص وأوامر الطباعة.

تمثل علامة التبويب **AI Output** طبقة الإخراج في المشروع. هذه الطبقة لا تقوم بتشغيل نماذج الذكاء الاصطناعي مباشرة، بل تقوم بتنظيم النتائج أو تنسيقها أو تصديرها أو إرسالها.

---

## الهدف

توفير مكونات من أجل:

- تطبيع الاحتمالات ونتائج التصنيف؛
- إنشاء تقارير بصيغ PDF و DOCX و XLSX و TXT؛
- إنشاء وفتح وتعديل وحفظ مستندات Word/OpenXML؛
- عرض مستندات Word على Canvas في Lazarus؛
- إرسال أوامر حقيقية إلى طابعات POS والطابعات الحرارية وطابعات الملصقات.

---

## المكونات الرئيسية

| المكون | الوحدة | الوصف | الخصائص المهمة | الأساليب الرئيسية |
|---|---|---|---|---|
| **TAIOutputData** | `aioutput.pas` | يعالج الاحتمالات ونتائج التصنيف. | `Classes`, `Probabilities`, `ClassificationResult` | `SoftMax`, `GetBestClassIndex`, `GetBestClassName`, `UpdateResult` |
| **TAIPDFOutput** | `aioutput_docs.pas` | ينشئ مستندات PDF أصلية باستخدام `fpPDF`. | `FileName`, `Title`, `Author`, `Subject` | `StartDocument`, `AddPage`, `AddText`, `SavePDF` |
| **TAIWordOutput** | `aioutput_docs.pas` | ينشئ مخرجات متوافقة مع Word/HTML. | `FileName`, `Title` | `AddHeading`, `AddParagraph`, `AddTable`, `SaveWord` |
| **TAIExcelOutput** | `aioutput_docs.pas` | ينشئ مخرجات جدولية متوافقة مع Excel. | `FileName` | `SetCell`, `SaveExcel` |
| **TAITXTOutput** | `aioutput_docs.pas` | يصدر نصوصاً بسيطة. | `FileName` | `AddLine`, `AddHeader`, `Clear`, `SaveText` |
| **TAIOutputDocs** | `aioutput_docs.pas` | يجمع عدة صيغ مستندات في مكون واحد. | `FileNamePDF`, `FileNameWord`, `FileNameExcel`, `FileNameTXT`, `Title`, `Author`, `Subject` | `AddHeading`, `AddParagraph`, `AddTable`, `SetCell`, `SaveAll` |
| **TAIWordDocument** | `aiworddocument.pas` | ينشئ ويفتح ويعدل ويحفظ ملفات DOCX باستخدام OpenXML. | `FileName`, `Title`, `Author`, `Subject`, `PreserveUnsupportedXml` | `NewDocument`, `LoadFromFile`, `SaveToFile`, `AddParagraph`, `AddImage`, `AddTable`, `ReplaceText`, `SetVariable`, `ApplyVariables` |
| **TAIWordLayoutEngine** | `aiwordviewer.pas` | يبني نموذج العرض البصري لصفحات مستند Word. | `Pages`, `Zoom`, `DPI` | `BuildLayout`, `Clear` |
| **TAIWordRenderEngine** | `aiwordviewer.pas` | يرسم الصفحات والفقرات والصور والجداول على `TCanvas`. | — | `RenderPage`, `RenderParagraph`, `RenderImage`, `RenderTable` |
| **TAIPOSPrinter** | `aiposprinter.pas` | يرسل أوامر خام إلى طابعات POS والطابعات الحرارية وطابعات الملصقات. | `InterfaceType`, `PrinterModel`, `Protocol`, `DeviceName`, `Host`, `Port`, `SerialBaud`, `Active`, `LastError` | `OpenConnection`, `CloseConnection`, `PrintTextLine`, `PrintBarcode`, `PrintQRCode`, `CutPaper`, `OpenDrawer`, `Beep` |

---

## الطباعة: المفاهيم الصحيحة

يجب فصل ثلاثة مفاهيم مختلفة عند التعامل مع الطباعة.

| المفهوم | المعنى | أمثلة |
|---|---|---|
| **لغة الطابعة** | الأوامر التي يفهمها برنامج الطابعة الداخلي. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **النقل** | المسار المستخدم لإرسال البايتات إلى الجهاز. | Serial, TCP 9100, USB raw, spooler, file |
| **وضع الرسم** | طريقة إنتاج المحتوى قبل الإرسال. | أوامر خام أو Canvas الخاص بنظام التشغيل |

`Native OS` **ليس بروتوكول طابعة**. إنه يمثل الطباعة عبر نظام التشغيل، مثل استخدام `Printer.Canvas` في Lazarus.

---

## لغات الطباعة

| اللغة | الاستخدام الصحيح | ملاحظات |
|---|---|---|
| **ESC/POS** | طابعات الإيصالات الحرارية/POS. | مناسبة للنصوص و QR Code والباركود ودرج النقود وقص الورق. |
| **ZPL** | طابعات ملصقات Zebra أو المتوافقة معها. | غالباً تبدأ الملصقة بـ `^XA` وتنتهي بـ `^XZ`. |
| **TSPL/TSPL2** | طابعات ملصقات TSC أو المتوافقة معها. | تستخدم `SIZE`, `GAP`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `PRINT`. |
| **EPL/EPL2** | طابعات Eltron/Zebra القديمة. | يجب اعتبارها تجريبية حتى يتم التحقق من الطراز المستهدف. |
| **Native OS** | الطباعة عبر spooler/canvas في نظام التشغيل. | لا يجب أن يرسل أوامر ESC/POS/ZPL/TSPL مباشرة. |

---

## توصيات لمكون `TAIPOSPrinter`

- فصل لغة الطابعة عن النقل وعن وضع الرسم.
- يجب أن يقوم `OpenConnection` بفتح الاتصال فقط، وليس بدء المستند.
- فصل `CutPaper` عن `PrintLabel`.
- توليد بايتات (`TBytes`) بدلاً من سلاسل نصية عادية.
- عرض أخطاء حقيقية عند فشل الاتصال أو الإرسال.
- عدم عرض نجاح إذا لم يتم توليد أو إرسال أي أمر.

النموذج المقترح:

```pascal
TPrinterLanguage = (plEscPos, plZpl, plTspl, plEpl);
TPrinterTransport = (ptSerial, ptTcp9100, ptFile, ptWindowsRawSpooler, ptCupsRaw);
TPrinterRenderMode = (rmRawCommand, rmNativeCanvas);
```

---

## المثال المرتبط

```text
pacote/samples/AI Output/posprinter_demo
```

يجب أن يتطور المثال من `Simulation Mode` إلى:

```text
Preview only
```

السلوك المتوقع:

- `Preview only = True`: توليد أوامر حقيقية وعرضها كنص/hex.
- `Preview only = False`: توليد نفس الأوامر وإرسالها إلى وسيلة النقل المحددة.
- عدم عرض نجاح إذا لم يتم إرسال أي أمر.

---

## جسر الذكاء الاصطناعي والأجهزة

تستخدم مكونات **AI Output** الخاصية published `Prompt` لتوثيق واجهتها الداخلية. هذا يسمح للوكلاء (`TAIAgent`) بفهم الخصائص التي يجب ضبطها والأساليب التي يجب تنفيذها.
