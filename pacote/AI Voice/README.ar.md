# 🗣️ توثيق علامة التبويب AI Voice

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **AI Voice**.

## تخليق الصوت وتحويل النصوص إلى كلام منطوق.
محركات أصلية لتحويل النصوص إلى كلام منطوق (TTS) بنبرات صوتية متعددة.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIVoiceSynthesizer** | مخلق الصوت والنصوص المنطوقة. | `Pitch, Rate, Volume` | `Speak(const AText: string): Boolean` | تخليق كلام منطوق طبيعي من نصوص التحليلات المنتجة بواسطة الوكيل. |

### 💻 مثال على كود لازاروس (TAIVoiceSynthesizer)

```pascal
var
  MyComponent: TAIVoiceSynthesizer;
begin
  MyComponent := TAIVoiceSynthesizer.Create(Self);
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
