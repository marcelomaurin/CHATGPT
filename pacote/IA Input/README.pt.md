# 🔌 Documentação da Aba IA Input

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **IA Input**.

## Captura Avançada de Dispositivos de Entrada, Sensores e Redes.
Mapeia e captura dados do mundo real (teclado, mouse, câmeras, brokers MQTT, sockets) para alimentar modelos cognitivos.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIInputData** | Normalizador linear de vetores numéricos. | `MinRange, MaxRange` | `Normalize, Denormalize` | Normalizar dados flutuantes brutos para faixas toleradas por Redes Neurais. |
| **TAICameraInput** | Capturador de frames de câmera física nativa. | `DeviceIndex, Width, Height, Active` | `StartCapture, StopCapture, CaptureFrame` | Fornecer quadros visuais em tempo real para IA de visão computacional. |
| **TAIAudioInput** | Gravador e mixer de áudio. | `InputSource (Mic, Wave), BitRate` | `StartRecord, StopRecord, MixAudio` | Gravar vozes do ambiente e preparar WAV para modelos de transcrição. |
| **TAIWebAPIServer** | Servidor REST API incorporado. | `Port, Active, AllowedRoutes` | `StartServer, StopServer` | Expor um endpoint HTTP para receber dados de agentes externos. |
| **TAISocketTCP** | Conector de Sockets TCP Cliente/Servidor. | `Host, Port, Mode, Active` | `Connect, Disconnect, SendText, ReceiveText` | Estabelecer links e canais de streaming de texto de baixo nível. |
| **TAISocketUDP** | Conector de Sockets UDP rápido. | `Host, Port, Active` | `SendText, ReceiveText` | Transmitir telemetria de sensores de forma rápida e assíncrona. |
| **TAISerialModem** | Porta Serial e Gateway de SMS GSM. | `DeviceName, BaudRate, Active` | `OpenPort, SendATCommand, SendSMS` | Enviar mensagens SMS físicas via modems analógicos e microcontroladores. |
| **TAICFTVIP** | Câmera IP MJPEG. | `IPAddress, Port, Active` | `CaptureStreamFrame` | Adquirir vídeo de câmeras de segurança CFTV distribuídas na rede. |
| **TAIEmailClient** | Cliente SMTP/POP3 nativo. | `HostSMTP, PortSMTP, Username, Password` | `SendEmail, FetchEmails` | Ler caixas de entrada de e-mails em sockets e enviar notificações. |
| **TAIMessenger** | Gateway WhatsApp e SMS via REST. | `SMSApiURL, WhatsAppApiURL, WhatsAppToken` | `SendSMS, SendWhatsApp` | Disparar alertas em tempo real direto nos celulares dos operadores. |
| **TAIChromiumBrowser** | Navegador Web incorporado. | `URL, ShowAddressBar` | `Navigate, GoBack, Reload` | Renderizar interfaces web e extrair dados HTML brutos de páginas. |
| **TAIOSInputCapture** | Capturador de eventos de sistema do SO. | `TrackMouse, TrackKeyboard, Active` | `CaptureScreen` | Screenshot do desktop e interceptar teclado/mouse para telemetria de atividade. |

### 💻 Exemplo de Código Lazarus (TAIInputData)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
