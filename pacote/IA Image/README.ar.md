# 🖼️ توثيق علامة التبويب IA Image

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Image**.

## الرؤية الحاسوبية وفلاتر الصور الرقمية.
فلاتر متقدمة لمعالجة مصفوفة الصور وتهيئتها للمعالجة العصبية البصرية.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIImageFilters** | فلتر الصور الرقمية للمصفوفات. | `FilterType (Sobel, Canny, Gaussian, Grayscale)` | `ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean` | معالجة الصور المسبقة وإطارات الكاميرات لتعزيز دقة التعرف البصري. |

### 💻 مثال على كود لازاروس (TAIImageFilters)

```pascal
var
  MyComponent: TAIImageFilters;
begin
  MyComponent := TAIImageFilters.Create(Self);
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
