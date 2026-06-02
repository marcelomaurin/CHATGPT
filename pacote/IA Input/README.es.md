# 🔌 Documentación de la Pestaña IA Input

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **IA Input**.

## Captura Avanzada de Dispositivos de Entrada, Sensores y Redes.
Mapea y captura datos del mundo real (teclado, mouse, cámaras, brokers MQTT, sockets) para alimentar modelos cognitivos.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIInputData** | Normalizador lineal de vectores numéricos. | `MinRange, MaxRange` | `Normalize, Denormalize` | Normalizar datos brutos para rangos tolerados por Redes Neuronales. |
| **TAICameraInput** | Capturador de fotogramas de cámara física nativa. | `DeviceIndex, Width, Height, Active` | `StartCapture, StopCapture, CaptureFrame` | Proporcionar cuadros visuales en tiempo real para IA de visión computacional. |
| **TAIAudioInput** | Grabador y mezclador de audio. | `InputSource (Mic, Wave), BitRate` | `StartRecord, StopRecord, MixAudio` | Grabar voces del ambiente y mezclar canales WAV para transcribidores. |
| **TAIWebAPIServer** | Servidor REST API incorporado. | `Port, Active, AllowedRoutes` | `StartServer, StopServer` | Exponer un punto final HTTP REST para recibir datos de sistemas externos. |
| **TAISocketTCP** | Conector de Sockets TCP Cliente/Servidor. | `Host, Port, Mode, Active` | `Connect, Disconnect, SendText, ReceiveText` | Establecer conexiones estables de flujo de red a bajo nivel. |
| **TAISocketUDP** | Conector rápido de Sockets UDP. | `Host, Port, Active` | `SendText, ReceiveText` | Transmitir telemetría de sensores de forma rápida y asíncrona. |
| **TAISerialModem** | Puerto Serial y Gateway de SMS GSM. | `DeviceName, BaudRate, Active` | `OpenPort, SendATCommand, SendSMS` | Enviar mensajes SMS físicos a través de módems celulares y microcontroladores. |
| **TAIPOSPrinter** | Impresora térmica de recibos Esc/POS. | `DevicePath, Active` | `PrintText, PrintBarcode` | Imprimir registros de papel automáticos, códigos de barras y recibos. |
| **TAICFTVIP** | Conector de cámara IP MJPEG para CFTV. | `IPAddress, Port, Active` | `CaptureStreamFrame` | Adquirir vídeo de cámaras de seguridad CFTV distribuidas en la red. |
| **TAIModbusClient** | Cliente Modbus industrial (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | Consultar registros físicos de sensores de temperatura y presión. |
| **TAIMQTTClient** | Cliente de red IoT MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Sincronizar telemetría IoT con brokers (ej. HiveMQ) de forma asíncrona. |
| **TAIEmailClient** | Cliente SMTP/POP3 nativo. | `HostSMTP, PortSMTP, Username, Password` | `SendEmail, FetchEmails` | Recuperar mensajes de bandeja de entrada e iniciar notificaciones de estado. |
| **TAIMessenger** | Gateway WhatsApp y SMS via REST. | `SMSApiURL, WhatsAppApiURL, WhatsAppToken` | `SendSMS, SendWhatsApp` | Despejar alertas instantáneas directamente a los teléfonos móviles de los operadores. |
| **TAIIndustrialBridge** | Puente Profinet/Profibus de PLC. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Interconectar y leer estados físicos de autómatas industriales. |
| **TAIChromiumBrowser** | Panel de Navegador Web incorporado. | `URL, ShowAddressBar` | `Navigate, GoBack, Reload` | Renderizar interfaces web y extraer código HTML en bruto. |
| **TAIOSInputCapture** | Capturador de eventos de sistema del SO. | `TrackMouse, TrackKeyboard, Active` | `CaptureScreen` | Tomar screenshots del escritorio y capturar pulsaciones de teclas globales. |

### 💻 Ejemplo de Código Lazarus (TAIInputData)

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


### ⚡ Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
