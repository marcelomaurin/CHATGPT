# 🤖 توثيق علامة التبويب IA Agent

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Agent**.

## الوكلاء الأذكياء المستقلون واتخاذ القرار.
إطار عمل لتنسيق الإدراك المعرفي يخطط للإجراءات ويرسم خرائط المخرجات المادية باستخدام RTTI الديناميكي.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIAgent** | دماغ الوكيل المعرفي. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | تحليل القياسات عن بعد وتخطيط الإجراءات المستقلة. |
| **TAIAgentResource** | مستودع الأجهزة والأدوات المتصلة. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | رسم خرائط القنوات المادية (البريد الإلكتروني، الشبكة، أجهزة الاستشعار) للذكاء الاصطناعي. |
| **TAIAgentOutput** | المرسل الآلي للقنوات المادية. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | ربط قرار الذكاء الاصطناعي المنطقي بالتنفيذ المادي. |

### 💻 مثال على كود لازاروس (TAIAgent)

```pascal
var
  MyComponent: TAIAgent;
begin
  MyComponent := TAIAgent.Create(Self);
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
