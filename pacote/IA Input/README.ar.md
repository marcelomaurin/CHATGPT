# 🔌 توثيق علامة التبويب IA Input

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **IA Input**.

## التقاط متقدم لأجهزة الإدخال، وأجهزة الاستشعار، والشبكات.
يرسم خرائط البيانات من العالم الحقيقي (لوحة المفاتيح، الماوس، الكاميرات، موصلات MQTT، السوكيت) ويلتقطها لتغذية النماذج المعرفية.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIInputData** | مُهيئ ومُعادل خطي للمتجهات الرقمية. | `MinRange, MaxRange` | `Normalize, Denormalize` | تحجيم بيانات القياس الخام إلى نطاقات متوافقة للشبكات العصبية. |
| **TAICameraInput** | ملتقط إطارات الكاميرات المادية الأصلية. | `DeviceIndex, Width, Height, Active` | `StartCapture, StopCapture, CaptureFrame` | توفير تدفقات الفيديو من الكاميرا في الوقت الحقيقي لنماذج الرؤية الحاسوبية. |
| **TAIAudioInput** | مسجل وخلاط إشارات الصوت الرقمية. | `InputSource (Mic, Wave), BitRate` | `StartRecord, StopRecord, MixAudio` | تسجيل إشارات الصوت وتجميع قنوات WAV لنماذج نسخ النصوص. |
| **TAIWebAPIServer** | خادم HTTP REST API مدمج. | `Port, Active, AllowedRoutes` | `StartServer, StopServer` | توفير واجهة برمجية HTTP REST لاستلام البيانات من الأنظمة الخارجية. |
| **TAISocketTCP** | مقبس اتصالات TCP للعميل والخادم. | `Host, Port, Mode, Active` | `Connect, Disconnect, SendText, ReceiveText` | إنشاء تدفقات اتصالات مستقرة منخفضة المستوى للشبكة. |
| **TAISocketUDP** | مقبس اتصال UDP سريع. | `Host, Port, Active` | `SendText, ReceiveText` | إرسال ونقل بيانات حساسات القياس بسرعة كبيرة وبشكل غير متزامن. |
| **TAISerialModem** | منفذ تسلسلي وجسر إرسال SMS الخلوي. | `DeviceName, BaudRate, Active` | `OpenPort, SendATCommand, SendSMS` | إرسال تنبيهات SMS مادية والتفاعل مع الأجهزة والشرائح الدقيقة. |
| **TAIPOSPrinter** | طابعة إيصالات حرارية متوافقة مع Esc/POS. | `DevicePath, Active` | `PrintText, PrintBarcode` | طباعة سجلات الورق التلقائية والرموز الشريطية والإيصالات. |
| **TAICFTVIP** | موصل كاميرات IP للمراقبة بشبكة MJPEG. | `IPAddress, Port, Active` | `CaptureStreamFrame` | الحصول على تدفقات الفيديو من كاميرات الأمان الشبكية القياسية. |
| **TAIModbusClient** | عميل Modbus الصناعي (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | الاستعلام عن البيانات الحقيقية من حساسات درجات الحرارة والضغط الصناعية. |
| **TAIMQTTClient** | عميل شبكة اتصالات إنترنت الأشياء MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | نشر بيانات الحساسات بصيغة JSON بشكل غير متزامن لخواديم MQTT العامة. |
| **TAIEmailClient** | عميل بريد إلكتروني SMTP/POP3 أصلي. | `HostSMTP, PortSMTP, Username, Password` | `SendEmail, FetchEmails` | استرداد وقراءة الرسائل الواردة وإرسال إشعارات البريد الإلكتروني. |
| **TAIMessenger** | بوابة إرسال واتساب وSMS عبر REST. | `SMSApiURL, WhatsAppApiURL, WhatsAppToken` | `SendSMS, SendWhatsApp` | إرسال رسائل وتنبيهات فورية مباشرة لهواتف المشغلين والمهندسين. |
| **TAIIndustrialBridge** | جسر اتصالات Profinet/Profibus للمتحكمات CLPs. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | التفاعل وإصدار أوامر التحكم على روابط التشغيل الآلي للمصانع. |
| **TAIChromiumBrowser** | لوحة متصفح ويب مدمجة. | `URL, ShowAddressBar` | `Navigate, GoBack, Reload` | عرض واجهات المستخدم على الويب واستخلاص نصوص HTML البرمجية. |
| **TAIOSInputCapture** | ملتقط أحداث سطح مكتب نظام التشغيل العام. | `TrackMouse, TrackKeyboard, Active` | `CaptureScreen` | التقاط صور كاملة لسطح المكتب واعتراض مدخلات لوحة المفاتيح. |

### 💻 مثال على كود لازاروس (TAIInputData)

```pascal
var
  MyComponent: TAIInputData;
begin
  MyComponent := TAIInputData.Create(Self);
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
