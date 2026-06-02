# 📄 توثيق علامة التبويب IA Output

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Output**.

## المخرجات المهيكلة، معالجة القرارات وإنشاء المستندات والتقارير.
ينشئ تقارير ذكاء اصطناعي أنيقة أصلية بتنسيقات متعددة (.pdf، .docx، .xlsx، .txt) دون متطلبات خارجية.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIOutputData** | معالج القرارات ومنشط دالة SoftMax. | `Classes, Probabilities` | `SoftMax, GetBestClassIndex, GetBestClassName` | تحديد الفئة الأكثر احتمالاً للتنبؤ وصياغة النتائج التحليلية. |
| **TAIPDFOutput** | منشئ مستندات PDF الأصلي. | `FileName, Title, Author` | `StartDocument, AddPage, AddText, SavePDF` | توليد تقارير رسمية وشهادات مطبوعة بصيغة PDF. |
| **TAIWordOutput** | منشئ تقارير Word (.docx) الأصلي. | `FileName, Title` | `AddHeading, AddParagraph, AddTable, SaveWord` | تصدير ملخصات نصية وجداول هيكلية متوافقة مع برامج الأوفيس. |
| **TAIExcelOutput** | منشئ جداول بيانات Excel (.xlsx) الأصلي. | `FileName` | `SetCell, SaveExcel` | تصدير بيانات التنبؤات والتحليلات الإحصائية. |
| **TAITXTOutput** | مقسم وصانع النصوص البسيطة ASCII. | `FileName` | `AddLine, AddHeader, SaveText` | إنشاء ملفات نصوص بسيطة خفيفة الحجم لعمليات تسجيل السجلات. |
| **TAIOutputDocs** | المجموعة الموحدة لتصدير التقارير. | `Title, Author, Subject` | `AddParagraph, AddTable, SaveAll` | إنشاء جميع مستندات التقارير الأربعة السابقة معًا في وقت واحد. |

### 💻 مثال على كود لازاروس (TAIOutputData)

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


### ⚡ جسر الذكاء الاصطناعي والأجهزة
يتميز كل مكون من هذه المكونات بخاصية نشر `Prompt` والتي توثق بشكل شفاف واجهتها البرمجية لتوجيه وكلاء الذكاء الاصطناعي (`TAIAgent`) ذاتياً!
