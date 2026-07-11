# Sample: agent_task_memory_action_demo

## الترجمات المتاحة

- [Português](README.md)
- [English](README.en.md)
- [Français](README.fr.md)
- [日本語](README.ja.md)
- [Deutsch](README.de.md)
- [Русский](README.ru.md)
- [中文](README.zh.md)
- [Español](README.es.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

---

يوضح هذا المثال سير عمل متعدد الوكلاء موجهًا بالمهام، مع ذاكرة تنفيذ، وتخطيط عبر LLM، ومعالجة معرفية، وأتمتة حقيقية لمتصفح Chromium، وتحضير الإجراءات، وإرسال البريد الإلكتروني.

الفكرة الأساسية هي تحويل prompt حر يكتبه المستخدم إلى سلسلة مهام قابلة للتدقيق. تحتوي كل مهمة على معرف، وترتيب، ونوع، ووصف، ووكيل مسؤول، وإجراء مقترح، واعتماديات، ومعاملات، وحالة، ونتيجة.

---

## هدف المثال

الهدف الرئيسي هو إظهار كيف يمكن لمكونات حزمة **AI Agent** أن تعمل معًا لمعالجة طلب مركب:

1. فتح موقع حقيقي في Chromium؛
2. التقاط نص الصفحة؛
3. إنشاء مهام وسيطة باستخدام LLM؛
4. معالجة المحتوى الملتقط معرفيًا؛
5. إنشاء ملخص مهني؛
6. نسخ النتيجة إلى منطقة النتائج في النموذج؛
7. تحضير نص البريد الإلكتروني؛
8. إرسال البريد باستخدام `TAIEmailClient` بعد تأكيد المستخدم؛
9. تسجيل المسار الكامل في خريطة الذاكرة.

هذا المثال ليس مجرد شاشة اختبار، بل هو عرض عملي للتنسيق بين الوكلاء، والإجراءات الحقيقية، وذاكرة التنفيذ، وأتمتة واجهة الويب.

---

## Prompt السيناريو الافتراضي

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

كما يقوم زر سيناريو المتصفح بتحميل صيغة مشابهة:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

القاعدة المهمة هي: **يجب نسخ الملخص الناتج مباشرة إلى جسم البريد الإلكتروني** بدون إنشاء ملفات TXT أو DOCX أو Word أو مرفقات.

---

## كيف يعمل التدفق

### 1. إدخال المستخدم

في تبويب **Prompt**، يحدد المستخدم مزود الذكاء الاصطناعي، والنموذج، والرمز، و Base URL، والـ prompt الرئيسي. يدعم المثال OpenAI ونقاط النهاية المحلية المتوافقة مع `/v1/chat/completions`.

### 2. اكتشاف URL

تبحث الدالة `ExtractURLFromPrompt` عن أول URL داخل الـ prompt. عند العثور على URL، يقوم المثال بتهيئة Chromium والانتقال إلى الصفحة الحقيقية.

### 3. التقاط الصفحة الأولي

بعد انتهاء التنقل، يستخدم `TAIChromiumBrowser` لالتقاط نص المحدد `body`. يتم حفظ النص في `FCapturedWebText` و `browser.last_text` و `browser.last_result_text`.

### 4. التصنيف

يتلقى `TAIClassifierAgent` الـ prompt الأصلي والمحتوى الملتقط، ثم يصنف الطلب ويسجل المرحلة في `TAIAgentMemoryMap`.

### 5. تخطيط المهام

يقوم `FTaskPlannerAgent`، المبني على `TAIDecisionAgent`، بتحويل الطلب إلى قائمة مهام JSON. تقوم `LoadTasksFromPlannerJSON` بقراءة JSON، وتطبيع الاعتماديات، وملء شبكة المهام.

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navigate to the requested page",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": { "url": "https://example.com" }
    }
  ]
}
```

### 6. تطبيع الخطة

يقوم المثال بتطبيع المعرفات، وترتيب المهام، وإعادة بناء الاعتماديات، وضمان مستلم البريد، وإنشاء خطوة التقاط بعد submit عند الحاجة، ورفض الإجراءات غير المعروفة، وتحويل إجراءات الملخص إلى مهام معرفية.

### 7. التنفيذ

قبل تنفيذ أي مهمة، يتحقق المثال من الحالة، والاعتماديات، والمعاملات المطلوبة. يتم تنفيذ مهام `BROWSER_*` مباشرة بواسطة `TAIActionExecutor` لتجنب تغيير الإجراء بواسطة LLM. أما المهام المعرفية فتتم معالجتها بواسطة `FTaskProcessorAgent`.

### 8. تحضير الإجراءات

يتم تحضير الإجراءات التشغيلية بصيغة JSON. يمكن إنشاء الإجراءات المباشرة مثل `SEND_EMAIL` و `CREATE_TEXT_DOCUMENT` و `REGISTER_RESULT` بطريقة حتمية عبر `BuildSingleActionJSON`. عند الحاجة، يحول `TAIActionBuilderAgent.BuildActionsWithRecovery` المخرجات المعرفية إلى معاملات تشغيلية صالحة.

### 9. النتيجة النهائية

يجب أن يظهر الملخص الناتج في `memConteudoCurriculo` و `memCorpoEmail` و `last_summary_text` و `last_text_content`. لا يجب إرسال البريد بعلامات مثل `<resumo_gerado>` أو `[EMAIL]` أو نص عام كبديل.

---

## المكونات المستخدمة

- `TCHATGPT`: موصل LLM مشترك بين الوكلاء.
- `TAIAgentMemoryMap`: يسجل مسار التنفيذ الكامل.
- `TAIClassifierAgent`: يصنف الـ prompt الأولي.
- `TAIDecisionAgent` كـ `FTaskPlannerAgent`: ينشئ قائمة المهام.
- `TAIDecisionAgent` كـ `FTaskProcessorAgent`: يعالج المهمة وينتج نتيجة معرفية.
- `TAIActionBuilderAgent`: يحول النتائج المعرفية إلى معاملات تشغيلية.
- `TAIActionExecutor`: ينفذ الإجراءات المسجلة ويحافظ على `ExecutionContext`.
- `TAIEmailClient`: يرسل البريد عبر SMTP بعد التأكيد.
- `TAIChromiumBrowser` و `TChromiumWindow`: أتمتة حقيقية لـ Chromium.

إجراءات المتصفح المسجلة: `BROWSER_NAVIGATE`, `BROWSER_WAIT_SELECTOR`, `BROWSER_READ_PAGE`, `BROWSER_DOM_LIST`, `BROWSER_CAPTURE_TEXT`, `BROWSER_SET_VALUE`, `BROWSER_FOCUS`, `BROWSER_CLICK`, `BROWSER_PRESS_ENTER`, `BROWSER_SUBMIT_FORM`, `BROWSER_SCREENSHOT`.

---

## تبويبات الواجهة

- **Prompt**: الإدخال الرئيسي وإعداد المزود.
- **Tarefas**: قائمة المهام التي أنشأها LLM.
- **Agente**: تدقيق الوكيل الحالي.
- **Mapa de Memória**: التاريخ المنظم للتدفق.
- **Resultado**: النص الناتج وحقول البريد.
- **Log**: سجل التنفيذ الزمني.
- **Navegador Chromium**: المتصفح الحقيقي المستخدم لفتح الصفحات.

---

## سياق التنفيذ

`FActionExecutor.ExecutionContext` هو الذاكرة التشغيلية المشتركة بين الإجراءات. المفاتيح المهمة: `browser.last_dom_kind`, `browser.last_dom_selector`, `browser.last_dom_json`, `browser.last_text`, `browser.last_result_text`, `last_text_content`, `last_summary_text`, `last_text_filename`.

---

## ملخص خط الأنابيب

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Task grid
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery, when needed
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-mail / Result
  -> MemoryMap / Log
```

---

## الأمان والتحقق

يقوم المثال بحظر المستلمين الفارغين أو placeholders، وجسم البريد الفارغ، والجسم الذي يحتوي placeholders، والإجراءات غير المعروفة، والمعاملات المطلوبة المفقودة. يتطلب إرسال البريد الحقيقي دائمًا تأكيدًا يدويًا.

---

## النتيجة المتوقعة

عند تشغيل السيناريو بشكل صحيح، يجب أن يرى المستخدم المهام التي تم إنشاؤها، والتنقل الحقيقي في Chromium، والمحتوى الملتقط، وملخصًا مهنيًا في منطقة النتائج، ونفس الملخص في جسم البريد، وسجلًا تفصيليًا، وخريطة ذاكرة للوكلاء.
