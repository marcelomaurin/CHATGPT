# 📊 توثيق علامة التبويب AI Graph

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **AI Graph**.

## تصنيف النصوص بواسطة خرائط الرسوم البيانية الموزونة.
مكون تصنيف نصوص قصير قابل للتفسير يعتمد على خرائط الرسوم البيانية للرموز المحلية.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIGraphMap** | مصنف نصوص يعتمد على الرسوم البيانية الموزونة للرموز. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | تصنيف النصوص القصيرة محلياً دون أي اتصال بالشبكة. |

### 💻 مثال على كود لازاروس (TAIGraphMap)

```pascal
var
  MyComponent: TAIGraphMap;
begin
  MyComponent := TAIGraphMap.Create(Self);
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
