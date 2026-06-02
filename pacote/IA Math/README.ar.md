# 📐 توثيق علامة التبويب IA Math

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Math**.

## جبر المتجهات والمصفوفات فائق السرعة.
ينفذ عمليات الرياضيات للمصفوفات الرياضية بشكل مشابه لمكتبة NumPy في بايثون.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TNumPS** | منشئ ومحرك المصفوفات والمتجهات. | `ThreadSafe` | `Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random` | إجراء الحسابات الإحصائية الثقيلة وعمليات الجبر الخطي للذكاء الاصطناعي. |

### 💻 مثال على كود لازاروس (TNumPS)

```pascal
var
  MyComponent: TNumPS;
begin
  MyComponent := TNumPS.Create(Self);
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
