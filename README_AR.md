# TCHATGPT — حزمة مكونات الذكاء الاصطناعي لبيئة لازاروس (Lazarus)

🌍 **اللغات / Idiomas / Languages:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

مجموعة كاملة من المكونات المرئية وغير المرئية لبيئة Free Pascal / Lazarus المصممة لدمج **الذكاء الاصطناعي التوليدي والتعلم الآلي (Machine Learning)** برمجياً في تطبيقاتك. تدعم الحزمة **OpenAI (ChatGPT)** و **Google Gemini** و **Anthropic Claude** و **OpenRouter** و **Cerebras** و **النماذج المحلية عبر Ollama** بالإضافة إلى الشبكات العصبية المحلية المكتوبة بالباسكال بالكامل.

---

## 📦 المكونات المضمنة في الحزمة

تثبت الحزمة المكونات التالية في علامة التبويب **IA** في لوحة مكونات لازاروس:

### 1. `TCHATGPT` (موصل واجهات برمجة تطبيقات الذكاء الاصطناعي)
المحرك الأساسي لدمج نماذج اللغات الكبيرة (LLMs). يسمح بإرسال الأسئلة وتلقي الإجابات النصية المهيكلة من موفري الخدمات السحابية أو النماذج المحلية.
- **المزودون المدعومون**: OpenAI و Gemini و Claude و OpenRouter و Cerebras و Ollama/المحلي.
- **الميزات**: التحكم في الحد الأقصى للرموز (Max Tokens)، والتوجيهات المخصصة للمطور/النظام، والحرارة (Temperature)، والنماذج المخصصة.

### 2. `TNeuralNetwork` (شبكة عصبية متعددة الطبقات)
شبكة عصبية من نوع Perceptron متعددة الطبقات (MLP) مكتوبة **بلغة بايثون/باسكال نقية**، مما يتيح لك بناء وتدريب نماذج شبكات عصبية محلياً ودون الحاجة لمكتبات خارجية ضخمة.
- **دوال التنشيط المدمجة**: Sigmoid (`atSigmoid`) و ReLU (`atReLU`) و Tanh (`atTanh`) والتنشيط المخصص (`atCustom` عبر الأحداث).
- **التدريب على فترات (Epochs)**: توفر الدالة `TrainEpochs` لتدريب الشبكة على مصفوفات كاملة وحساب نسبة الخسارة الإجمالية عبر الخطأ التربيعي المتوسط (MSE Loss).
- **الحفظ والاسترجاع**: حفظ وتحميل الأوزان والانحيازات بسهولة (`SaveNetwork` / `LoadNetwork`).

### 3. `TAICodeAssistant` (مساعد البرمجة الذكي)
مساعد برمجيات افتراضي موجه للمطورين. يرتبط بمكون `TCHATGPT` المختار لأتمتة المهام البرمجية الشائعة:
- **`OptimizeCode(ACode)`**: تحسين أداء وسهولة قراءة الأكواد البرمجية.
- **`FindBugs(ACode)`**: فحص الأخطاء المنطقية، تسريب الذاكرة، وتقديم حلول مصححة.
- **`DocumentCode(ACode)`**: إضافة تعليقات توثيقية مهيكلة بصيغة XML/Javadoc تلقائياً.
- **`GenerateUnitTests(ACode)`**: كتابة اختبارات وحدات شاملة باستخدام بيئات مثل `FPCUnit`.
- **`TranslateCode(ACode, From, To)`**: ترجمة الأكواد البرمجية بين اللغات المختلفة (مثل C# إلى Pascal).
- **`ExplainCode(ACode)`**: شرح منطق عمل الخوارزميات خطوة بخطوة بالتفصيل.

### 4. `TAIDatasetGenerator` (منشئ مجموعات البيانات التدريبية)
أداة لتسهيل إعداد البيانات وتجهيزها. تساعد على إنشاء الملفات اللازمة للضبط الدقيق (Fine-Tuning) لنماذج اللغات أو مجموعات البيانات للشبكة العصبية المحلية:
- **Fine-Tuning**: تصدير المحادثات بالصيغة القياسية **JSONL** (JSON Lines) المقبولة من OpenAI و Ollama.
- **تكامل الشبكات العصبية**: تصدير البيانات بصيغة **CSV**، وتحميل ملفات CSV المفصولة بترميز معين مباشرة إلى مصفوفات التدريب (`TMatrix`) المتوافقة مع مكون الشبكة العصبية `TNeuralNetwork.TrainEpochs`.

### 5. `TTokenList` (مقسم الكلمات المساعد)
أداة مساعدة لتحليل النصوص وتقسيم الجمل إلى قائمة مهيكلة من الرموز (Tokens).

---

## البدء السريع (مساعد البرمجة الذكي)

```pascal
uses chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  OptimizedCode: string;
begin
  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-YOUR_KEY_HERE';
    FChatgpt.Provider := AIP_CLAUDE;          // ضبط موصل الأنثروبيك كلاود
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
    
    FAssistant.ChatGPT := FChatgpt; // ربط مساعد البرمجة بمكون الاتصال
    
    OptimizedCode := FAssistant.OptimizeCode('procedure TForm1.Click; begin i := i + 1; end;');
    ShowMessage(OptimizedCode);
  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;
end;
```

---

## التدريب المحلي للشبكات العصبية (`TNeuralNetwork` & `TAIDatasetGenerator`)

```pascal
var
  FNet: TNeuralNetwork;
  FGen: TAIDatasetGenerator;
  Inputs, Targets: TMatrix;
  Loss: Double;
begin
  FNet := TNeuralNetwork.Create(nil);
  FGen := TAIDatasetGenerator.Create(nil);
  try
    // تحميل بيانات التدريب مباشرة من ملف CSV
    FGen.LoadFromCSV('data.csv', Inputs, Targets, 2, 1); // مدخلان، مخرج واحد

    // تهيئة الشبكة العصبية: مدخلان، 4 خلايا مخفية، مخرج واحد، معدل التعلم = 0.05
    FNet.Initialize(2, 4, 1, 0.05);
    FNet.ActivationType := atSigmoid;

    // تشغيل حلقة التدريب على مجموعة البيانات لمدة 1000 دورة
    FNet.TrainEpochs(Inputs, Targets, 1000, Loss);
    ShowMessage(Format('اكتمل التدريب! نسبة الخسارة النهائية MSE: %0.6f', [Loss]));

    FNet.SaveNetwork('model.net');
  finally
    FGen.Free;
    FNet.Free;
  end;
end;
```

---

## المزودون المدعومون (LLMs)

| المزود | Enum | Endpoint | الرمز المطلوب (Token) |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | نعم |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | نعم |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | نعم |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | نعم |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | نعم |
| المحلي (Ollama) | `AIP_LOCAL` | `localhost:11434` | لا |

---

## تثبيت الحزمة في لازاروس

1. في بيئة لازاروس، اذهب إلى **Package > Open Package File (.lpk)**
2. توجه إلى المجلد `pacote/` واختر **`openai.lpk`**
3. انقر على **Compile** لترجمة الحزمة
4. انقر على **Use > Install** — سيطلب منك لازاروس إعادة بناء بيئة التطوير
5. بعد إعادة التشغيل، ستكون المكونات الخمسة (5) متوفرة في علامة التبويب **IA** في لوحة المكونات.

---

## متطلبات المكتبات (نظام ويندوز)

لكي يعمل اتصال HTTPS بشكل صحيح على ويندوز، يجب توفير ملفات مكتبة OpenSSL المناسبة لبنية تطبيقك المصدر (32-بت أو 64-بت). تحتوي الحزمة بالفعل على ملفات DLL في المجلد `pacote/lib/`:

*   **تطبيقات 32-بت (i386-win32)**: `pacote/lib/i386-win32/`
    - `libcrypto-1_1.dll`, `libssl-1_1.dll`
*   **تطبيقات 64-بت (x86_64-win64)**: `pacote/lib/x86_64-win64/`
    - `libcrypto.dll`, `libssl-1_1-x64.dll`

**توصية:** قم بنسخ ملفات DLL من مجلد `lib/` المقابل لبنية تطبيقك إلى **نفس المجلد الذي يحتوي على الملف التنفيذي لتطبيقك**.

---

## الترخيص

هذا المشروع مرخص بموجب [رخصة جنو العمومية الإصدار 3.0](LICENSE).
