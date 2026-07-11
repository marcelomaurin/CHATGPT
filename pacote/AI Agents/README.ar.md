# 🤖 توثيق تبويب AI Agent

يحتوي هذا المجلد على المجموعة الكاملة لمكونات Lazarus تحت تبويب **AI Agent**، والمخصصة للربط المعرفي واتخاذ القرار بواسطة وكلاء الذكاء الاصطناعي المستقلين وتكامل الأجهزة ومسارات العمل (pipelines).

---

> **التوافق:** تم الاحتفاظ مؤقتًا بالأسماء المستعارة القديمة `TAIMapaDeMemoria` و `TAIMapaDeMemoriaItem` و `TAIMapaDeMemoriaCollection` وخاصية `MapaDeMemoria` لتجنب كسر المشاريع الحالية.

## 📋 فهرس المكونات

- [TAIAgent](#taiagent)
- [TAIAgentOptions](#taiagentoptions)
- [TAIAgentAction](#taiagentaction)
- [TAIAgentResource](#taiagentresource)
- [TAIAgentOutput](#taiagentoutput)
- [TAIAgentOrchestrator](#taiagentorchestrator)
- [TAIClassifierAgent](#taiclassifieragent)
- [TAIDecisionAgent](#taidecisionagent)
- [TAIActionBuilderAgent](#taiactionbuilderagent)
- [TAIActionExecutor](#taiactionexecutor)
- [TAIAgentMemoryMap](#taimapadememoria)
- [TAIAgentSafety](#taiagentsafety)
- [TAIPipeline](#taipipeline)
- [TAIWizardConfig](#taiwizardconfig)

---

## 🔍 تفاصيل المكونات

### TAIAgent

**الوظيفة:** دماغ الوكيل المعرفي. يقوم بتنسيق المحادثات مع نماذج اللغة الكبيرة (LLM) للتخطيط للمهام وتشغيل الإجراءات بناءً على ذاكرة الجلسة.

- **الخصائص (Published):**
  - `ChatGPT: TCHATGPT` - موصل للتخاطب مع نموذج LLM.
  - `Options: TAIAgentOptions` - الأسئلة والفرز المعرفي للوكيل.
  - `Action: TAIAgentAction` - الإجراءات المسموح بها والتحكم بالمعايير.
  - `Resource: TAIAgentResource` - الموارد المتاحة (بريد إلكتروني، Modbus، ملفات).
  - `Safety: TAIAgentSafety` - جدار الحماية لحماية تشغيل الإجراءات غير المصرح بها.
  - `SystemPrompt: string` - التوجيه الافتراضي للنظام الذي يوجه سلوك الوكيل.
  - `LastRationale: string` - المبرر المنطقي وراء القرار الأخير المتخذ (للقراءة فقط).
  - `Memory: TStrings` - سجل المحادثات وسياق الذاكرة.
  - `MaxMemoryLimit: Integer` - الحد الأقصى لحجم سياق الذاكرة.
  - `MaxRetries: Integer` - أقصى محاولات لتنسيق رد JSON سليم.
  - `LastDecision: TAIAgentDecision` - البيانات التفصيلية للقرار الأخير والمعايير المستخرجة (للقراءة فقط).
- **الدوال (Public):**
  - `Execute(const AInputData: string): Boolean` - معالجة الطلب، وتحديد الإجراء الأنسب، وتمريره للتنفيذ.
  - `ClearMemory` - مسح سجل المحادثات والذاكرة للوكيل.
- **الأحداث:**
  - `OnActionTriggered: TAgentActionEvent` - يتم إطلاقه عندما يقرر الوكيل اتخاذ إجراء ويقوم بإرسال المعلمات.

---

### TAIAgentOptions

**الوظيفة:** تخزين الأسئلة الهيكلية وسياق الدعم لتوجيه تحليل الوكيل الرئيسي `TAIAgent`.

- **الخصائص (Published):**
  - `Questions: TStrings` - قائمة أسئلة التحقق الهيكلية.
  - `Context: string` - وصف نصي تفصيلي لقواعد العمل.
  - `Action: TAIAgentAction` - الإجراء المرتبط بهذه الخيارات.

---

### TAIAgentAction

**الوظيفة:** تعريف قائمة الإجراءات والتحقق من صحة معايير الإجراء المولد ضد مخطط معين.

- **الخصائص (Published):**
  - `AllowedActions: TStrings` - قائمة الإجراءات المسموحة (مثل: `SEND_EMAIL` ، `ACTIVATE_RELAY`).
  - `ParameterDefinitions: TStrings` - تعريف المعايير المتوقعة لكل إجراء (تنسيق JSON عادة).
  - `SelectedAction: string` - الاسم الأخير للإجراء المتخذ.
  - `SelectedParameters: TStrings` - أزواج المفتاح=القيمة للمعايير المولدة للإجراء الحالي.
- **الدوال (Public):**
  - `ClearSelection` - مسح الإجراءات والمعايير المحددة.
  - `GetParamValue(const AName: string): string` - استرجاع قيم المعايير المحددة.
  - `TriggerAction(const AActionName: string; AParams: TStrings)` - محاكاة تشغيل الإجراء يدويًا.
- **الأحداث:**
  - `OnExecuteAction: TAgentActionEvent` - يتم إطلاقه لتشغيل الكود الفعلي للإجراء.

---

### TAIAgentResource

**الوظيفة:** دليل يربط التوصيلات المادية والمكونات الخارجية (البريد الإلكتروني، الاتصال، أجهزة PLC، قواعد البيانات) المتاحة للذكاء الاصطناعي.

- **الخصائص (Published):**
  - `Resources: TAIAgentResourceCollection` - مجموعة الموارد المهيأة. كل مورد (`TAIAgentResourceItem`) يعرف خصائص مثل `Name` و `ResourceType` و `Host` و `Port` و `Sender` و `Recipient` و `Component` (الربط المباشر مع مكونات حقيقية مثل `TAIEmailClient` أو `TAIMqttClient`).
- **الدوال (Public):**
  - `FindResource(const AName: string): TAIAgentResourceItem` - البحث عن مورد مهيأ بالاسم.

---

### TAIAgentOutput

**الوظيفة:** موجه التنفيذ المباشر. يربط القرارات المنطقية في `TAIAgentAction` بالمستقبلات المعرفة في `TAIAgentResource`.

- **الخصائص (Published):**
  - `Action: TAIAgentAction` - مكون أفعال المصدر للاستماع إليها.
  - `Resource: TAIAgentResource` - دليل موارد المصدر.
  - `Mappings: TAIAgentOutputMappingCollection` - خريطة الربط بين اسم الإجراء واسم المورد.
  - `LastExecutionLog: string` - تفاصيل سجل آخر عملية إرسال.
- **الدوال (Public):**
  - `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` - إرسال أمر التنفيذ ديناميكيًا إلى المورد المربوط.
- **الأحداث:**
  - `OnOutputExecuted: TAIAgentOutputEvent` - يتم إطلاقه بعد التنفيذ مع توضيح حالة النجاح وسجلات التشغيل.

---

### TAIAgentOrchestrator

**الوظيفة:** منسق العمليات المعرفي المركزي. ينظم سير العمل عبر عدة وكلاء متخصصين ويدير الدورة المعرفية الكاملة للوكيل.

- **الخصائص (Published):**
  - `ChatGPT: TCHATGPT` - موصل LLM.
  - `MemoryMap: TAIAgentMemoryMap` - الذاكرة المشتركة للعمليات.
  - `CriarMapaAutomaticamente: Boolean` - إنشاء خريطة ذاكرة مؤقتة تلقائيًا إذا لم تكن مرتبطة.
  - `Classifier: TAIClassifierAgent` - وكيل التصنيف المبدئي.
  - `DecisionAgent: TAIDecisionAgent` - وكيل التخطيط واتخاذ القرارات.
  - `ActionBuilder: TAIActionBuilderAgent` - وكيل التحقق وضبط معلمات الإجراء.
  - `Executor: TAIActionExecutor` - وكيل التنفيذ الفعلي أو المحاكاة.
- **الدوال (Public):**
  - `Run(const AInput: string): Boolean` - تشغيل سير العمل المعرفي المتسلسل (التصنيف -> التخطيط -> الضبط -> التنفيذ).
- **الأحداث:**
  - `OnBeforeFlowStart` / `OnAfterFlowStart` - أحداث بداية ونهاية سير العمل.
  - `OnBeforeClassifier` / `OnAfterClassifier` - مرحة التصنيف المبدئي.
  - `OnBeforeDecisionAgent` / `OnAfterDecisionAgent` - مرحلة التخطيط والقرارات.
  - `OnBeforeActionBuilder` / `OnAfterActionBuilder` - مرحلة معالجة المعايير.
  - `OnBeforeExecutor` / `OnAfterExecutor` - مرحلة تشغيل المخطط.
  - `OnInformationLossDetected` - يتم إطلاقه إذا تم اكتشاف فقدان معلومات هامة بين المراحل.
  - `OnFlowError` - يتم إطلاقه عند حدوث خطأ عام.
  - `OnFlowFinished` - يتم إطلاقه عند اكتمال سير العمل بنجاح.

---

### TAIClassifierAgent

**الوظيفة:** وكيل الفرز والتصنيف المبدئي لنية المستخدم وتوجيهها.

- **الدوال (Public):**
  - `Classify(const AInput: string; out AOutput: string): Boolean` - تصنيف وتوجيه الطلب.
- **الأحداث:**
  - `OnBeforeClassify: TAIFluxoEtapaControlEvent`
  - `OnAfterClassify: TAIFluxoEtapaEvent`
  - `OnClassificationLowConfidence: TAIFluxoEtapaEvent`

---

### TAIDecisionAgent

**الوظيفة:** وكيل التخطيط المعني بتعريف مخطط المهام المنطقي اللازم للطلب.

- **الدوال (Public):**
  - `Decide(const AInput: string; out AOutput: string): Boolean` - توليد وحساب مخطط المهام.
- **الأحداث:**
  - `OnBeforeDecision: TAIFluxoEtapaControlEvent`
  - `OnAfterDecision: TAIFluxoEtapaEvent`
  - `OnInvalidActionSelected: TAIFluxoEtapaEvent`
  - `OnDecisionLowConfidence: TAIFluxoEtapaEvent`

---

### TAIActionBuilderAgent

**الوظيفة:** وكيل الضبط المعني بالتحقق من صحة المعلمات، وتعيين القيم الافتراضية، وتنقية المدخلات غير الآمنة.

- **الدوال (Public):**
  - `BuildActions(const AInput: string; out AOutput: string): Boolean` - تنقية وتفصيل معايير الإجراءات المخططة.
- **الأحداث:**
  - `OnBeforeBuildAction: TAIFluxoEtapaControlEvent`
  - `OnAfterBuildAction: TAIFluxoEtapaEvent`
  - `OnMissingRequiredParameter: TAIFluxoEtapaEvent`
  - `OnUnsafeParameterDetected: TAIFluxoEtapaEvent`

---

### TAIActionExecutor

**الوظيفة:** محاكي ومنفذ خطط الإجراءات. يربط إرسال الأوامر النهائي عبر `TAIAgentOutput`.

- **الخصائص (Published):**
  - `ChatGPT: TCHATGPT` - موصل ChatGPT.
  - `MemoryMap: TAIAgentMemoryMap` - ذاكرة التدقيق.
  - `ForcarSimulacaoGlobal: Boolean` - في حال تفعيله، يتم منع أي تغيير مادي (وضع المحاكاة/العرض).
  - `AutoRegistrarNoMapa: Boolean` - تسجيل الخطوات المنطقية في خريطة الذاكرة تلقائيًا.
- **الدوال (Public):**
  - `ExecutePlan(const AInputPlan: string; out AOutput: string): Boolean` - معالجة وإرسال المهام.
- **الأحداث:**
  - `OnBeforeExecutePlan: TAIFluxoEtapaControlEvent`
  - `OnAfterExecutePlan: TAIFluxoEtapaEvent`
  - `OnExecutionBlocked: TAIFluxoEtapaEvent`

---

### TAIAgentMemoryMap

**الوظيفة:** سجل مستمر لحفظ وتدقيق دورة سير العمل المعرفي، مع ميزة الكشف التلقائي عن فقدان السياق والمعلومات الهامة.

- **الخصائص (Published):**
  - `SessionId: string` - معرف الجلسة الفريد.
  - `FlowName: string` - اسم التدفق الحالي.
  - `Items: TAIAgentMemoryMapItem` - قائمة الخطوات المكتملة بالفعل.
  - `DetectInformationLoss: Boolean` - في حال تفعيله، يتم التحقق مما إذا كان النموذج قد أغفل معلمات حرجة أدخلها المستخدم في البداية.
- **الدوال (Public):**
  - `StartFlow(const AFlowName: string; const AInput: string)` - تسجيل مدخلات المستخدم الأولية.
  - `BuildContextForAgent(const ANomeAgente: string): string` - تصدير السجل بتنسيق XML محسن لتوجيه النموذج التالي.
- **الأحداث:**
  - `OnInformationLossDetected: TAIFluxoEtapaEvent` - يتم إطلاقه عند نسيان أو إغفال أي من المعلمات المدخلة الأساسية.

---

### TAIAgentSafety

**الوظيفة:** جدار الحماية للعمليات. يعترض استدعاءات الملفات أو الشبكة أو الأجهزة للتأكد من أمانها قبل التنفيذ.

- **الخصائص (Published):**
  - `Enabled: Boolean` - تفعيل الحماية (افتراضيًا `True`).
  - `RequireConfirmation: Boolean` - تطلب موافقة المستخدم اليدوية (افتراضيًا `True`).
  - `ReadOnlyMode: Boolean` - منع أي تعديل أو كتابة مادية (افتراضيًا `True`).
  - `AllowFileWrite: Boolean` - السماح بكتابة الملفات محليًا.
  - `SafeBasePath: string` - المجلد الآمن المسموح بالكتابة داخله فقط.
- **الدوال (Public):**
  - `ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean` - التحقق من سلامة الإجراء.
- **الأحداث:**
  - `OnConfirmAction: TAIConfirmActionEvent` - اعتراض التدفق لطلب موافقة المستخدم يدويًا بشكل مرئي.

---

### TAIPipeline

**الوظيفة:** موصل خطي للبيانات. يربط بين معالجة النصوص، وحسابات الشبكة العصبية المحلية، وتدفقات الوكلاء، وإنتاج المستندات.

- **الخصائص (Published):**
  - `Mode: TAIPipelineMode` - وضع التشغيل.
  - `ChatGPT: TCHATGPT` - موصل ChatGPT.
  - `NeuralNetwork: TNeuralNetwork` - الشبكة العصبية المحلية (MLP).
  - `OutputDocs: TAIOutputDocs` - مولد التقارير والمستندات.
- **الدوال (Public):**
  - `Run: Boolean` - تشغيل سير العمل كما يحدده الوضع.
  - `RunNumeric: Boolean` - معالجة وحساب الشبكة العصبية محليًا.

---

### TAIWizardConfig

**الوظيفة:** معالج الإعداد التفاعلي خطوة بخطوة. يربط ويعد مشاريع الذكاء الاصطناعي والموصلات والنماذج في Lazarus.

- **الخصائص (Published):**
  - `Project: TAIProject` - المشروع المرتبط.
  - `ChatGPT: TCHATGPT` - مكون ChatGPT.
- **الدوال (Public):**
  - `ConfigureVisual` - فتح واجهة المعالج التفاعلي خطوة بخطوة (`TfrmAIWizardConfig`).
  - `Apply` - تطبيق وتمرير الإعدادات المهيأة.
