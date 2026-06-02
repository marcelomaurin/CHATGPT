# 🎵 توثيق علامة التبويب IA Filtros Sonoros

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Filtros Sonoros**.

## معالجة إشارات الصوت والفلاتر الرقمية.
وحدة لتحويل الترددات الصوتية وتطبيق مرشحات خطية سريعة.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAISoundFilters** | معالج إشارات الصوت الرقمية. | `FilterType (LowPass, HighPass, BandPass), CutoffFrequency` | `ApplyFilter(const AInputWav, AOutputWav: string): Boolean` | تنظيف ضوضاء الخلفية وضبط ترددات تسجيلات الميكروفون. |

### 💻 مثال على كود لازاروس (TAISoundFilters)

```pascal
var
  MyComponent: TAISoundFilters;
begin
  MyComponent := TAISoundFilters.Create(Self);
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
