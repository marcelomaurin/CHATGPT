# [IA] توثيق علامة التبويب AI Project

> [!NOTE]
> يحتوي هذا المجموعة مكونات لازاروس ضمن علامة التبويب **AI Project**.

## التنسيق المتقدم لمشاريع الذكاء الاصطناعي وخطوط الأنابيب البرمجية.
يركز ويؤتمت الاتصال بين وحدات المشروع المختلفة (المدخلات؆ الشبكات العصبية؆ الوكلاء وتصدير المستندات).

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIProject** | المنسق والمحرك العام لمشروع الذكاء الاصطناعي. | `ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode` | `Initialize, TestConnection, ExecuteText, Execute, LoadFromFile, SaveToFile, BuildSystemPrompt` | تركيز مفاتيح الأمان؆ تحميل إعدادات المشاريع من ملفات JSON وتشغيل محاكاة الاختبارات. |
| **TAIPipeline** | موصل تدفق البيانات (الإدخال -> المعالجة -> الإخراج) المهيكل. | `Mode (pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor), ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax` | `Run, RunText, RunNumeric, RunAgent, RunDocument, RunIndustrialMonitor` | أتمتة نقل بيانات الحساسات الخام إلي مصنفات الشبكات العصبية وإصدار التقارير. |
| **TAIPromptBuilder** | بناء التوجيهات ديناميكياً من خلال خاصية الفحص. | `IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, LastPrompt` | `BuildFromOwner, BuildFromComponents, ExtractPrompt` | فحص النموذج وتجميع أوصاف موحدة (Prompt) لجميع المكونات والأدوات المتاحة من أجل إرسالها إلى ChatGPT. |

### [Code] مثال على كود لازاروس (TAIProject)

```pascal
var
  MyProject: TAIProject;
  MyPipeline: TAIPipeline;
begin
  MyProject := TAIProject.Create(Self);
  MyPipeline := TAIPipeline.Create(Self);
  try
    MyProject.ProjectName := 'Smart Factory AI';
    MyProject.ChatGPT := ChatGPT1;
    MyProject.Pipeline := MyPipeline;
    
    MyPipeline.Mode := pmTextLLM;
    MyPipeline.ChatGPT := ChatGPT1;
    MyPipeline.InputText := 'Como otimizar código em FPC?';
    
    if MyProject.Execute then
      ShowMessage(MyProject.LastResult)
    else
      ShowMessage(MyProject.LastError);
  finally
    MyPipeline.Free;
    MyProject.Free;
  end;
end;
```


### [Bridge] جسر الذكاء الاصطناعي والأجهزة
يتميز كل مكون من هذه المكونات بخاصية نشر `Prompt` والتي توثق بشكل شفاف وتوثيق واجهتها البرمجية لتوجيه وكلاء الذكاء الاصطناعي (`TAIAgent`) ذاتياً!
