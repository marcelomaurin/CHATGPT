# 🏭 توثيق علامة التبويب AI Industrial

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **AI Industrial**.

## مكونات الأتمتة الصناعية Modbus و MQTT و PLC.
يوفر جسور PLC الصناعية (Profinet/Profibus)، وعملاء IoT MQTT، ومراقبة سجلات Modbus، والتحكم في الطابعات الحرارية Esc/POS.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIPOSPrinter** | طابعة إيصالات حرارية متوافقة مع Esc/POS. | `DevicePath, Active` | `PrintText, PrintBarcode` | طباعة سجلات الورق التلقائية والرموز الشريطية والإيصالات. |
| **TAIModbusClient** | عميل Modbus الصناعي (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | الاستعلام عن البيانات الحقيقية من حساسات درجات الحرارة والضغط الصناعية. |
| **TAIMQTTClient** | عميل شبكة اتصالات إنترنت الأشياء MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | نشر بيانات الحساسات بصيغة JSON بشكل غير متزامن لخواديم MQTT العامة. |
| **TAIIndustrialBridge** | جسر اتصالات Profinet/Profibus للمتحكمات CLPs. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | التفاعل وإصدار أوامر التحكم على روابط التشغيل الآلي للمصانع. |

### 💻 مثال على كود لازاروس (TAIPOSPrinter)

```pascal
var
  MyComponent: TAIPOSPrinter;
begin
  MyComponent := TAIPOSPrinter.Create(Self);
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
