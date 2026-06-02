# 📅 توثيق علامة التبويب IA Schedulle

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Schedulle**.

## الجدولة التلقائية والمخطط الزمني العصبي.
مكونات لإدارة المهام الدورية الذكية المستندة إلى جداول زمنية وتعبيرات cron.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TIASchedule** | مجدول المهام والمخططات الزمنية. | `CronExpression, MaxIterations` | `ScheduleTask, CancelTask` | إدارة مشغلات الوقت وجداول التنفيذ لوكيل الذكاء الاصطناعي. |

### 💻 مثال على كود لازاروس (TIASchedule)

```pascal
var
  MyComponent: TIASchedule;
begin
  MyComponent := TIASchedule.Create(Self);
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
