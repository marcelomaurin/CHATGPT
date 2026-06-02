# 🧠 توثيق علامة التبويب IA

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA**.

## نواة الذكاء الاصطناعي والاتصال العصبي.
يوفر اتصالاً بنماذج اللغة (OpenAI) وينفذ شبكات عصبية MLP بلغة باسكال الخالصة.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TCHATGPT** | موصل OpenAI/ChatGPT. | `APIKey, Model, MaxTokens` | `SendQuestion(const AQuestion: string): Boolean` | معالجة اللغة الطبيعية واتخاذ القرارات النصية. |
| **TNeuralNetwork** | شبكة عصبية متعددة الطبقات أصلية. | `InputNodes, HiddenNodes, OutputNodes, LearningRate` | `Train, Predict` | تعلم الأنماط المعقدة من مجموعات البيانات. |
| **TTokenizer** | مقسم النصوص (Tokenizer). | `LowerCase` | `Tokenize, GetVocabulary` | معالجة النصوص الخام وتحويلها لفهارس رقمية. |

### 💻 مثال على كود لازاروس (TCHATGPT)

```pascal
var
  MyComponent: TCHATGPT;
begin
  MyComponent := TCHATGPT.Create(Self);
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
