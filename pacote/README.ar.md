# 🧠 حزمة مكونات الذكاء الاصطناعي — openai.lpk

> [!NOTE]
> يحتوي هذا المجلد على حزمة المكونات الرسمية للذكاء الاصطناعي والأتمتة في لازاروس ودلفي (**openai.lpk**). تدمج هذه الحزمة الذكاء الاصطناعي، تعلم الآلة، أتمتة الأجهزة، الشبكات، معالجة الصوت والصور والمستندات بشكل أصلي ومتعدد المنصات.

## مرجع المكونات الأساسية

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TCHATGPT** | الموصل العام لنماذج OpenAI وLLMs السحابية أو الخواديم المحلية. | `APIKey, Provider, TipoChat, CustomModel, MaxTokens` | `SendQuestion(ASK): Boolean, TipoModelo: string` | معالجة اللغة الطبيعية وتوليد استجابات معرفية ذكية. |
| **TNeuralNetwork** | الشبكة العصبية متعددة الطبقات الأصلية بلغة باسكال الخالصة. | `LearningRate, ActivationType` | `Initialize, Predict, Train, TrainEpochs, SaveNetwork` | تدريب النماذج المحلية وإجراء عمليات التنبؤ الرياضي. |
| **TAICodeAssistant** | مساعد معرفي لمراجعة الأكواد البرمجية وتحسينها تلقائياً. | `ChatGPT` | `OptimizeCode, FindBugs, DocumentCode, ExplainCode` | تحليل كود باسكال البرمجي واقتراح عمليات إعادة الهيكلة والتصحيح. |
| **TAIDatasetGenerator** | مولد ومصدر مجموعات البيانات المهيكلة (JSONL, CSV). | `DataRows` | `AddDataRow, Clear, SaveAsJSONL, SaveAsCSV, LoadFromCSV` | تجميع قواعد البيانات وتقسيم مجموعات التدريب. |
| **TTokenizer** | مقسم النصوص ومحلل الكلمات السريع. | `LowerCase` | `Tokenize, GetVocabulary` | تحويل النصوص الخام البرمجية لفهارس رقمية. |
| **TAIGraphMap** | مصنف نصوص قابل للتفسير يعتمد على خرائط الرسوم البيانية الموزونة للرموز. | `Training, LowerCaseTokens, RemoveAccents, RemoveStopWords, WindowSize, UseGraphDepthSearch, MaxDepth, DepthDecay` | `Train, TrainItem, Predict, PredictRanking, ExplainPrediction, SaveGraphToFile, LoadGraphFromFile` | تصنيف النصوص القصيرة وتصنيف التذاكر محلياً دون أي اعتماديات خارجية. |
| **TPythonConnector** | جسر تشغيل ومحاكاة نصوص بايثون البرمجية في وقت التشغيل. | `DLLPath, Active, Version` | `ExecString, GetVar, SetVar, Eval` | دمج النماذج المتقدمة من بيئة عمل بايثون (مثل TensorFlow). |
| **TPerceptron** | مكون العصبون المنفرد الكلاسيكي الثنائي في باسكال. | `LearningRate, Weights, Bias` | `Initialize, Predict, Train, TrainEpochs` | تصنيف الحالات المنطقية الثنائية القابلة للفصل خطياً بسرعة. |
| **TSOMMap** | شبكة Kohonen ذاتية التنظيم لعمليات تجميع البيانات. | `GridWidth, GridHeight, InputDim` | `Initialize, FindBMU, TrainStep, Train` | تجميع البيانات المعقدة وعرضها على شبكات ثنائية الأبعاد. |
| **TCNNClassifier** | مكون تصنيف الصور Convolucional العميقة MobileNetV2. | `PythonConnector` | `InstallDependencies, ClassifyImage` | تحليل وتصنيف الصور أو إطارات الفيديو المباشرة. |
| **TLSTMPredictor** | متنبئ السلاسل الزمنية باستخدام الشبكات التكرارية LSTM. | `PythonConnector` | `InstallDependencies, TrainLSTM, PredictNext` | التنبؤ بالقيم المستقبلية لبيانات الحساسات المتسلسلة. |
| **TAIVoiceSynthesizer** | محرك أصلي متعدد المنصات لتخليق وتحويل النصوص لكلام مسموع. | `Volume, Rate, VoiceName, Asynchronous` | `Say, GetAvailableVoices` | تخليق إشعارات صوتية مسموعة من مخرجات الذكاء الاصطناعي. |

### 💻 نموذج عام لإنشاء وتجهيز المكون

```pascal
var
  ChatGPT: TCHATGPT;
begin
  ChatGPT := TCHATGPT.Create(Self);
  try
    ChatGPT.APIKey := 'sua-chave-api';
    ChatGPT.Provider := AIP_OPENAI;
    if ChatGPT.SendQuestion('Olá, como posso ajudar?') then
      ShowMessage(ChatGPT.Response);
  finally
    ChatGPT.Free;
  end;
end;
```


### 📂 مجلد أمثلة الاستخدام (Samples)
يحتوي المجلد `samples/` على مشاريع توضيحية مرئية وبسيطة لكل ميزة من ميزات الحزمة.

### ⚡ جسر الاتصال وتوجيه الوكلاء
تتميز جميع المكونات بخاصية نشر `Prompt` والتي توثق بشكل شفاف واجهتها البرمجية لتوجيه وكلاء الذكاء الاصطناعي (`TAIAgent`) ذاتياً وتلقائياً.
