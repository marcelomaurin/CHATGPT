# 🔌 Documentation for AI Input Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Input** tab.

## Advanced Input Devices, Sensors and Networks Capture.
Maps and captures real-world data (keyboard, mouse, cameras, MQTT brokers, sockets) to feed cognitive models.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIInputData** | Linear normalizer for numerical vectors. | `MinRange, MaxRange` | `Normalize, Denormalize` | Scale raw telemetry data into compatible neural network ranges. |
| **TAICameraInput** | Native camera frame grabber. | `DeviceIndex, Width, Height, Active` | `StartCapture, StopCapture, CaptureFrame` | Provide real-time camera visual streams for computer vision models. |
| **TAIAudioInput** | Audio recorder and wave mixer. | `InputSource (Mic, Wave), BitRate` | `StartRecord, StopRecord, MixAudio` | Record ambient voice signals and mix WAV channels for transcribers. |
| **TAIWebAPIServer** | Embedded REST API HTTP server. | `Port, Active, AllowedRoutes` | `StartServer, StopServer` | Expose HTTP REST endpoints for external system integrations. |
| **TAISocketTCP** | TCP Client/Server sockets. | `Host, Port, Mode, Active` | `Connect, Disconnect, SendText, ReceiveText` | Establish stable low-level network communication streams. |
| **TAISocketUDP** | UDP connection socket. | `Host, Port, Active` | `SendText, ReceiveText` | Transmit fast, asynchronous sensor telemetry logs. |
| **TAISerialModem** | Serial Port and GSM SMS Gateway. | `DeviceName, BaudRate, Active` | `OpenPort, SendATCommand, SendSMS` | Send physical cellular SMS alerts and interface legacy hardware. |
| **TAICFTVIP** | CFTV MJPEG IP camera connector. | `IPAddress, Port, Active` | `CaptureStreamFrame` | Acquire video streams from standard security network IP cameras. |
| **TAIEmailClient** | Native SMTP/POP3 email client. | `HostSMTP, PortSMTP, Username, Password` | `SendEmail, FetchEmails` | Retrieve inbox messages and dispatch email status notifications. |
| **TAIMessenger** | WhatsApp and SMS REST gateway. | `SMSApiURL, WhatsAppApiURL, WhatsAppToken` | `SendSMS, SendWhatsApp` | Dispatch instant alerts directly to mobile devices. |
| **TAIChromiumBrowser** | Embedded Web Browser panel. | `URL, ShowAddressBar` | `Navigate, GoBack, Reload` | Render web UIs and extract raw HTML content for web scraping. |
| **TAIOSInputCapture** | Global OS desktop event logger. | `TrackMouse, TrackKeyboard, Active` | `CaptureScreen` | Capture screen screenshots and capture global keyboard/mouse deltas. |

### 💻 Lazarus Code Example (TAIInputData)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
