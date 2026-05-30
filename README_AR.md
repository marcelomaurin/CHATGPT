# TCHATGPT — مكون لازاروس للدمج مع واجهات برمجة تطبيقات الذكاء الاصطناعي (AI APIs)

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

مكون مرئي لـ Free Pascal / Lazarus يسمح بإرسال الأسئلة وتلقي الإجابات من مزودي ذكاء اصطناعي متعددين، بما في ذلك **OpenAI (ChatGPT)** و **OpenRouter** و **Cerebras** و **النماذج المحلية عبر Ollama**.

## الميزات

- ✅ دعم مزودين متعددين (OpenAI و OpenRouter و Cerebras و Ollama/المحلي)
- ✅ اختيار النموذج عبر enum أو اسم مخصص
- ✅ الاتصال عبر HTTPS باستخدام `TFPHttpClient` (بدون الاعتماد على Indy)
- ✅ التثبيت كمكون في لوحة مكونات لازاروس (علامة التبويب **IA**)
- ✅ المكونات الإضافية المضمنة: `TNeuralNetwork` و `TTokenList`
- ✅ مرخص بموجب رخصة GPL v3

---

## البدء السريع

```pascal
uses chatgpt;

var
  FChatgpt: TCHATGPT;
begin
  FChatgpt := TCHATGPT.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-YOUR_KEY_HERE';
    FChatgpt.Provider := AIP_OPENAI;       // OpenAI, OpenRouter, Cerebras, or Local
    FChatgpt.TipoChat := VCT_GPT4o;        // النموذج المطلوب
    FChatgpt.MaxTokens := 4096;            // الحد الأقصى للرموز (Tokens) في الإجابة

    if FChatgpt.SendQuestion('ما هي عاصمة مصر؟') then
      ShowMessage(FChatgpt.Response)
    else
      ShowMessage('خطأ: ' + FChatgpt.Response);
  finally
    FChatgpt.Free;
  end;
end;
```

---

## المزودون المدعومون

| المزود | Enum | Endpoint | الرمز المطلوب (Token) |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | نعم |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | نعم |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | نعم |
| المحلي (Ollama) | `AIP_LOCAL` | `localhost:11434` | لا |

---

## النماذج المتاحة

### OpenAI
| Enum | نموذج API |
|---|---|
| `VCT_GPT35TURBO` | `gpt-3.5-turbo` |
| `VCT_GPT40` | `gpt-4` |
| `VCT_GPT40_TURBO` | `gpt-4-turbo-preview` |
| `VCT_GPT4o` | `gpt-4o` |
| `VCT_GPTo3_mini` | `o3-mini` |
| `VCT_GPT41` | `gpt-4.1` |
| `VCT_GPT41_MINI` | `gpt-4.1-mini` |
| `VCT_GPT5` | `gpt-5` |

### Ollama / المحلي
| Enum | النموذج |
|---|---|
| `VCT_LLAMA32_3B` | `llama3.2:3b` |
| `VCT_QWEN25_15B` | `qwen2.5:1.5b` |
| `VCT_DEEPSEEK_R1_15B` | `deepseek-r1:1.5b` |
| `VCT_DEEPSEEK_R1_8B` | `deepseek-r1:8b` |
| `VCT_DEEPSEEK_R1_14B` | `deepseek-r1:14b` |
| `VCT_DEEPSEEK_R1_70B` | `deepseek-r1:70b` |

> لاستخدام أي نموذج آخر، قم بتعريف: `FChatgpt.CustomModel := 'اسم-النموذج';`

---

## الخصائص

| الخاصية | النوع | الوصف |
|---|---|---|
| `TOKEN` | `WideString` | مفتاح واجهة برمجة التطبيقات (API Key) الخاص بالمزود |
| `Provider` | `TAIProvider` | مزود الذكاء الاصطناعي (OpenAI, OpenRouter, Cerebras, Local) |
| `TipoChat` | `TVersionChat` | نموذج الذكاء الاصطناعي المحدد |
| `CustomModel` | `WideString` | اسم نموذج مخصص (يتجاوز TipoChat) |
| `LocalIP` | `WideString` | عنوان URL لخادم Ollama المحلي (الافتراضي: `http://localhost:11434`) |
| `MaxTokens` | `Integer` | الحد الأقصى للرموز في الإجابة (الافتراضي: 4096) |
| `Dev` | `WideString` | التوجيه الخاص بالنظام (الافتراضي: "أنت مساعد ذكي.") |
| `Response` | `WideString` | الإجابة على آخر سؤال تم إرساله |
| `Question` | `WideString` | آخر سؤال تم إرساله (للقراءة فقط) |
| `LastJSON` | `WideString` | نص JSON الخام لآخر استجابة (للقراءة فقط) |
| `OpenRouterTitle` | `WideString` | عنوان التطبيق (رأس لـ OpenRouter) |
| `OpenRouterSite` | `WideString` | عنوان URL للموقع (رأس HTTP-Referer لـ OpenRouter) |

---

## مثال مع خادم Ollama محلي

```pascal
FChatgpt := TCHATGPT.Create(nil);
try
  FChatgpt.Provider := AIP_LOCAL;
  FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B;
  FChatgpt.LocalIP := 'http://192.168.1.100:11434';  // عنوان IP للخادم

  if FChatgpt.SendQuestion('اشرح مفهوم التكرار الحلقي أو التداخلي (Recursion).') then
    Memo1.Text := FChatgpt.Response;
finally
  FChatgpt.Free;
end;
```

---

## تثبيت الحزمة في لازاروس

1. في بيئة لازاروس، اذهب إلى **Package > Open Package File (.lpk)**
2. توجه إلى المجلد `pacote/` واختر **`openai.lpk`**
3. انقر على **Compile** لترجمة الحزمة
4. انقر على **Use > Install** — سيطلب منك لازاروس إعادة بناء بيئة التطوير
5. بعد إعادة التشغيل، ستكون المكونات متاحة في علامة التبويب **IA** في لوحة المكونات:
   - `TCHATGPT`
   - `TNeuralNetwork`
   - `TTokenList`

---

## متطلبات المكتبات (نظام ويندوز)

لكي يعمل اتصال HTTPS بشكل صحيح على ويندوز، يجب توفير ملفات مكتبة OpenSSL التالية لتكون قابلة للوصول من قبل التطبيق:

- `libcrypto-1_1.dll`
- `libssl-1_1.dll`
- `libssl-1_1-x64.dll` (لأنظمة 64-بت)

**توصية:** قم بنسخ هذه الملفات إلى **نفس المجلد الذي يحتوي على الملف التنفيذي لتطبيقك** (وليس في `System32`).

ملفات DLL مضمنة في المجلد الرئيسي لهذا المستودع لتسهيل الأمر عليك.

---

## هيكل المشروع

```
CHATGPT/
├── chatgpt.pas           # المكون الرئيسي TCHATGPT
├── funcoes.pas           # الدوال المساعدة والأدوات
├── pacote/
│   ├── openai.lpk        # حزمة لازاروس للتثبيت
│   ├── chatgpt.pas       # نسخة متزامنة من المكون
│   ├── neuralnetwork.pas  # مكون شبكة عصبية بسيطة TNeuralNetwork
│   ├── tokenizer.pas     # مكون مساعد لتقسيم الكلمات إلى رموز TTokenList
│   └── funcoes.pas       # نسخة متزامنة من الدوال المساعدة
├── demo/
│   ├── demo1.lpr         # التطبيق التجريبي
│   └── main.pas          # النموذج الرئيسي للتطبيق التجريبي
├── tools/
│   └── script/           # نصوص برمجية مساعدة (مقسم كلمات بلغة بايثون)
├── dicionario/           # قاموس البرتغالية (PT-BR)
├── LICENSE               # رخصة GPL v3
└── README.md             # التوثيق باللغة البرتغالية
```

---

## التطبيق التجريبي (Demo)

يتوفر تطبيق تجريبي كامل في المجلد `demo/`. لتشغيله:

1. افتح الملف `demo/demo1.lpi` في لازاروس
2. قم بترجمة وتشغيل المشروع
3. أدخل مفتاح واجهة برمجة التطبيقات (API Key) في الحقل المقابل
4. اكتب سؤالك وانقر فوق **Submit** أو اضغط على **Enter**

---

## ملاحظة هامة

يتطلب استخدام مزودي الخدمات السحابية مثل OpenAI أو OpenRouter أو Cerebras وجود **اشتراك نشط** ورصيد متاح في حسابك. استخدام **Ollama المحلي** مجاني تماماً ولا يتطلب أي مفاتيح API.

---

## المراجع

- [توثيق واجهة برمجة تطبيقات OpenAI](https://platform.openai.com/docs/)
- [OpenRouter](https://openrouter.ai/)
- [Ollama](https://ollama.ai/)
- [Cerebras](https://www.cerebras.ai/)
- [مجموعة بيانات الكلمات البرتغالية PT-BR](https://github.com/j0aoarthur/Palavras-PT-BR)

---

## الترخيص

هذا المشروع مرخص بموجب [رخصة جنو العمومية الإصدار 3.0](LICENSE).
