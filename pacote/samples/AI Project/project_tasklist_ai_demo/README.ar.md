# Project TaskList AI Demo

يوضح هذا المثال استخدام مكونات حزمة **AI Project** من Lazarus AI Suite لإنشاء تدفق بسيط لتخطيط المشاريع بدعم من نموذج لغوي كبير LLM.

الهدف الحالي من هذا المثال هو إظهار كيفية قيام نموذج Lazarus عملياً بما يلي:

1. إعداد مزود/نموذج الذكاء الاصطناعي؛
2. جمع البيانات الأساسية للمشروع؛
3. طلب مواصفة أولية بصيغة JSON من LLM؛
4. طلب توليد مهام تقنية من LLM؛
5. تخزين حالة المشروع في `ProjectData`؛
6. عرض المهام في grid ولوحة حالة وعروض JSON/log؛
7. حفظ وتحميل ملف `.aiproj.json`.

> ملاحظة مهمة: هذا README يصف ما يفعله المثال **حالياً**. لا يصف نسخة مثالية مستقبلية من العرض التجريبي.

---

## الهدف الحقيقي من المثال

`project_tasklist_ai_demo` هو إثبات مفهوم للتكامل بين:

- نموذج Lazarus؛
- المكون `TCHATGPT`؛
- المكون المركزي `TAIProject`؛
- مكونات مساعدة من حزمة `AI Project`؛
- بنية JSON للمشروع محفوظة في `AIProject1.ProjectData`.

هذا المثال ليس بعد مدير مشاريع كاملاً. وفي هذه النسخة، ليس أيضاً مثالاً نظيفاً يعتمد فقط على مكونات مغلفة بالكامل. جزء مهم من منطق prompt والتحقق ودمج JSON لا يزال منفذاً داخل `main.pas`.

---

## التدفق المنفذ حالياً

### 1. إعداد الذكاء الاصطناعي

في تبويب **Config IA**، يختار المستخدم:

- المزود؛
- النموذج؛
- token؛
- endpoint/عنوان URL محلي؛
- إصدار الذكاء الاصطناعي الخاص بالمكون `TCHATGPT`.

عند النقر على **Aplicar Configuração**، يقوم النموذج بملء `AIProjectLLMConfig1`، وتطبيق الإعداد على `AIProject1`، كما يقوم أيضاً بتحديث المكون `ChatGPT1` مباشرة.

زر **Testar IA** يرسل سؤالاً بسيطاً إلى `ChatGPT1` وينتظر رداً من LLM.

### 2. التسجيل الأساسي للمشروع

في تبويب **Projeto**، يقوم المستخدم بإدخال:

- اسم المشروع؛
- الوصف/الهدف؛
- القيود؛
- المخرجات المتوقعة.

يتم نسخ هذه المعلومات إلى خصائص `AIProject1` مثل `ProjectName` و `Goal` و `Constraints` و `ExpectedDeliverables`.

### 3. توليد المواصفة بالذكاء الاصطناعي

زر **Gerar Descrição Elaborada (IA)** ينفذ تدفق توليد المواصفة.

في التنفيذ الحالي، يتم بناء prompt داخل `main.pas`، ثم إرساله بواسطة `ChatGPT1.SendQuestion`، ثم تفسير النتيجة كـ JSON ودمجها داخل `AIProject1.ProjectData`.

البنية المتوقعة هي:

```json
{
  "project": {
    "name": "...",
    "description": "...",
    "goal": "...",
    "context": "...",
    "scope": "...",
    "constraints": "...",
    "expected_deliverables": "..."
  },
  "agile_documents": {
    "business_vision": "...",
    "functional_requirements": [],
    "non_functional_requirements": [],
    "stakeholders": [],
    "risk_map": [],
    "epics": [],
    "user_stories": []
  }
}
```

يتم دمج التوثيق الناتج في `ProjectData.project` و `ProjectData.agile_documents`.

### 4. توليد المهام بالذكاء الاصطناعي

زر **Gerar Tarefas com IA** يرسل JSON الحالي للمشروع إلى LLM ويطلب قائمة بالمهام التقنية.

البنية المتوقعة هي:

```json
{
  "planning": {
    "tasks": [
      {
        "id": "T001",
        "epic_id": "E001",
        "title": "...",
        "description": "...",
        "long_description": "...",
        "acceptance_criteria": "...",
        "priority": "alta",
        "status": "draft",
        "dependency_type": "serial",
        "dependencies": [],
        "can_run_in_parallel": false,
        "estimated_hours": {
          "intern": 8,
          "junior": 6,
          "mid_level": 4,
          "senior": 2
        },
        "suggested_skill_level": "mid_level",
        "assigned_skill_level": "mid_level",
        "assigned_to": "DEV",
        "responsible_profile": "DEV",
        "planned_start_date": "2026-06-26",
        "planned_end_date": "2026-06-27",
        "estimated_duration_days": 1,
        "progress_percent": 0,
        "deliverable": "...",
        "notes": "...",
        "revision_created": 1,
        "revision_updated": 1
      }
    ]
  }
}
```

بعد التحقق من الاستجابة، يستبدل المثال `ProjectData.planning.tasks` بالمهام التي تم إرجاعها، ثم يستدعي `AIProjectTasks1.RecalculateEstimates`.

### 5. عرض المهام

يستخدم تبويب **Tarefas**:

- `TAIProjectStatusPanel` لملخص الحالة؛
- `TAIProjectTaskGrid` لعرض قائمة المهام؛
- `MemoTaskDescription` لعرض الوصف الطويل للمهمة المحددة.

عند تحديد صف في grid، يبحث المثال عن المهمة بواسطة ID ويعرض `long_description` أو `description` في memo.

### 6. JSON و log

يعرض تبويب **JSON/Log**:

- JSON الكامل من `AIProject1.ProjectData`؛
- رسائل log الخاصة بالتدفق المنفذ؛
- استجابات LLM الأصلية عند حدوث أخطاء parsing أو validation.

### 7. حفظ وتحميل المشروع

يستخدم زر **Salvar Projeto** الدالة `AIProjectStorage1.SaveProjectToFile` لحفظ الملف:

```text
project_tasklist_demo.aiproj.json
```

ويستخدم زر **Carregar Projeto** الدالة `AIProjectStorage1.LoadProjectFromFile` لتحميل الملف نفسه.

في النسخة الحالية، تستخدم عمليتا الحفظ والتحميل أيضاً استدعاءات مساعدة إلى LLM للتحقق/التلخيص. هذا هو السلوك الحالي للمثال، لكنه ليس مطلوباً لاستمرارية بيانات المشروع.

---

## المكونات المدمجة فعلاً في التدفق الحالي

### `TCHATGPT` / `ChatGPT1`

هذا هو المكون المستخدم فعلياً للتواصل مع LLM.

يستدعي المثال مباشرة:

```pascal
ChatGPT1.SendQuestion(APrompt)
```

يُستخدم هذا المكون في:

- اختبار الاتصال؛
- توليد المواصفة؛
- توليد المهام؛
- توليد مهمة إضافية؛
- توليد ملخص؛
- توليد تقرير نصي؛
- التحقق/تصدير JSON؛
- التحقق قبل الحفظ؛
- تأكيد التنظيف.

### `TAIProject` / `AIProject1`

هذا هو المكون المركزي للمثال.

يحافظ على البنية الرئيسية في:

```pascal
AIProject1.ProjectData
```

يستخدم المثال `AIProject1` لتخزين:

- بيانات المشروع؛
- الوثائق agile داخل `agile_documents`؛
- قائمة المهام داخل `planning.tasks`؛
- الإعداد الأساسي للمشروع؛
- الحالة القابلة للتسلسل في `.aiproj.json`.

كما يتم استدعاء:

```pascal
AIProject1.EnsureProjectStructure;
```

لضمان وجود الحد الأدنى من بنية JSON.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

يُستخدم لاستقبال بيانات تبويب **Config IA** وتطبيق الإعدادات على `AIProject1` و `ChatGPT1`.

يستخدم المثال:

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

بالإضافة إلى ذلك، لا يزال النموذج يحدّث مباشرة بعض خصائص `ChatGPT1` مثل النموذج و token و endpoint ونوع المحادثة.

### `TAIProjectStorage` / `AIProjectStorage1`

يُستخدم لاستمرارية المشروع.

الدوال المستخدمة:

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

هذا المكون مدمج فعلاً في تدفق الحفظ والتحميل.

### `TAIProjectTasks` / `AIProjectTasks1`

يُستخدم للعمل مع المهام المحفوظة مسبقاً في `ProjectData`.

في النسخة الحالية، يُستخدم أساساً لـ:

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

أما توليد المهام نفسه فلا يزال يتم في `main.pas`، باستخدام prompt يدوي مرسل إلى `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

هذا المكون موجود في النموذج ومرتبط بـ `AIProject1`.

لكن في النسخة الحالية من المثال، لا يستدعي توليد المواصفة مباشرة طريقة عامة من هذا المكون. يتم تنفيذ تدفق المواصفة في `main.pas` باستخدام prompt يدوي و parsing يدوي ودمج يدوي في `ProjectData`.

لذلك، هذا المكون **موجود ومتصل**، لكنه **ليس المنفذ الرئيسي للتدفق الحالي**.

### `TAIProjectTaskGrid` / `TaskGrid1`

مكون بصري مدمج فعلاً.

يُستخدم لعرض `ProjectData.planning.tasks` في شكل grid.

يستدعي النموذج:

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

مكون بصري مدمج فعلاً.

يُستخدم لتحديث لوحة الحالة بناءً على المشروع الحالي.

يستدعي النموذج:

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

هذا المكون موجود في النموذج ومرتبط بالمشروع.

في النسخة الحالية، ليس جزءاً مركزياً من التدفق البصري المعروض. لا توجد في هذا المثال تبويب أو لوحة كاملة لإجراءات المهام معروضة للمستخدم.

### `TAIProjectDescription` / `AIProjectDescription1`

هذا المكون موجود ومرتبط بالمشروع.

في النسخة الحالية من المثال، لا يُستخدم مباشرة في التدفق الرئيسي لتوليد المواصفة أو المهام.

---

## مكونات موجودة أو مذكورة ولكنها غير معروضة بالكامل

### Agents

كانت الوثائق السابقة تقول إن agents تمت إزالتها من المثال. في الحالة الحالية للمشروع، لم تكتمل الإزالة بعد.

لا يزال المثال يحتوي على:

- تبويب `Agent`؛
- `TAIAgentManagerFrame`؛
- مراجع إلى وحدات agents؛
- أزرار وطرق مرتبطة بتوليد agents؛
- اعتماد على الحزمة `openai_agent` داخل `.lpi`.

لذلك، agents **موجودة جزئياً**، لكن التدفق الرئيسي للمثال لا يزال هو توليد المواصفة والمهام.

### Gantt و Timeline

كان README السابق يصف تبويبات Gantt و Timeline كجزء من التدفق الرئيسي.

في النسخة الحالية من المثال، لم يتم عرض هذه التبويبات بالكامل في الواجهة الرئيسية.

المكون `TAIProjectGantt` يظهر مصرحاً به في `main.pas`، لكن الشاشة الحالية لا تعرض تبويب Gantt كاملاً مدمجاً في التدفق. كما لا يوجد تبويب Timeline كامل في النموذج الحالي.

### التقارير

يحتوي المثال على أزرار وطرق للملخص، وتقرير المهام، وتقرير agents، وتصدير Markdown، وتصدير JSON.

في النسخة الحالية، يتم توليد هذه التقارير عبر استدعاءات LLM داخل النموذج نفسه، وليس عبر تدفق بصري كامل يعتمد على `TAIProjectReports`.

---

## الملف الناتج

يحفظ المثال المشروع في ملف ثابت:

```text
project_tasklist_demo.aiproj.json
```

يحتوي هذا الملف على JSON الكامل للمشروع، بما في ذلك:

- `project`؛
- `agile_documents`؛
- `planning.tasks`؛
- البنى الأخرى التي يضمنها `AIProject1.EnsureProjectStructure`.

---

## كيفية تشغيل التدفق الحالي

1. افتح `project_tasklist_ai_demo.lpi` في Lazarus.
2. قم بالترجمة والتشغيل.
3. انتقل إلى تبويب **Config IA**.
4. اختر المزود والنموذج.
5. أدخل token أو endpoint حسب المزود.
6. انقر على **Aplicar Configuração**.
7. انقر على **Testar IA** للتحقق من الاتصال.
8. انتقل إلى تبويب **Projeto**.
9. املأ الاسم والهدف والقيود والمخرجات.
10. ولّد المواصفة باستخدام **Gerar Descrição Elaborada (IA)**، المتاح حالياً في تبويب **Tarefas**.
11. ولّد المهام باستخدام **Gerar Tarefas com IA**.
12. راجع النتيجة في تبويب **Tarefas**.
13. راجع JSON و logs في تبويب **JSON/Log**.
14. احفظ المشروع باستخدام **Salvar Projeto**.
15. حمّله مرة أخرى باستخدام **Carregar Projeto**.

---

## القيود المعروفة لهذه النسخة

- لا يزال النموذج يركز الكثير من منطق prompt و parsing و validation الخاص بـ JSON.
- `TAIProjectSpecification` متصل، لكن تدفق المواصفة الحالي لا يزال ينفذ يدوياً بواسطة `main.pas`.
- `TAIProjectTasks` يُستخدم لإعادة الحساب والاستعلام عن المهام، لكن توليد المهام لا يزال يتم داخل النموذج.
- agents لا تزال تظهر جزئياً في المثال، رغم أنها ليست محور العرض الرئيسي.
- Gantt و Timeline لم يتم عرضهما بعد كتبويبات كاملة داخل النموذج.
- تصدير Markdown والتحقق من JSON لا يزالان يستخدمان استدعاءات LLM بدلاً من الاعتماد حصراً على مكونات التقارير/التصدير.
- الحفظ والتحميل والتنظيف لا تزال تحتوي على استدعاءات مساعدة إلى LLM، رغم أن هذه العمليات يمكن أن تكون محلية.
- الملف المحفوظ يستخدم الاسم الثابت `project_tasklist_demo.aiproj.json`.

---

## النطاق الحقيقي لهذه النسخة

ينبغي فهم هذا المثال كعرض عملي للتكامل الأولي بين `TCHATGPT` و `TAIProject` و `TAIProjectLLMConfig` و `TAIProjectStorage` و `TAIProjectTasks` و `TAIProjectTaskGrid` و `TAIProjectStatusPanel`.

ولا ينبغي بعد اعتباره المثال النهائي للمعمارية المثالية لحزمة `AI Project`.
