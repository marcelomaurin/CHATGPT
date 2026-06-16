# 🔌 Documentazione della Scheda AI Input

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Input**.

## Acquisizione Avanzata di Dispositivi di Input, Sensori e Reti.
Mappa e acquisisce dati del mondo reale (tastiera, mouse, telecamere, broker MQTT, socket) per alimentare i modelli cognitivi.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIInputData** | Normalizzatore lineare per vettori numerici. | `MinRange, MaxRange` | `Normalize, Denormalize` | Normalizzare dati grezzi per range tollerati dalle Reti Neurali. |
| **TAICameraInput** | Acquisitore di fotogrammi da telecamera fisica. | `DeviceIndex, Width, Height, Active` | `StartCapture, StopCapture, CaptureFrame` | Fornire fotogrammi video in tempo reale all'IA di visione. |
| **TAIAudioInput** | Registratore e mixer audio. | `InputSource (Mic, Wave), BitRate` | `StartRecord, StopRecord, MixAudio` | Registrare la voce e mixare canali WAV per elaborazioni neurali. |
| **TAIWebAPIServer** | Server HTTP API REST incorporato. | `Port, Active, AllowedRoutes` | `StartServer, StopServer` | Esporre un endpoint HTTP REST per ricevere chiamate esterne. |
| **TAISocketTCP** | Connettore Sockets TCP Client/Server. | `Host, Port, Mode, Active` | `Connect, Disconnect, SendText, ReceiveText` | Stabilire flussi di rete stabili a basso livello. |
| **TAISocketUDP** | Connettore di Sockets UDP veloce. | `Host, Port, Active` | `SendText, ReceiveText` | Trasmettere telemetria asincrona e rapida da sensori. |
| **TAISerialModem** | Porta Seriale e Gateway SMS GSM. | `DeviceName, BaudRate, Active` | `OpenPort, SendATCommand, SendSMS` | Inviare messaggi SMS ed effettuare connessioni a microcontrollori. |
| **TAICFTVIP** | Connettore telecamera IP MJPEG per CFTV. | `IPAddress, Port, Active` | `CaptureStreamFrame` | Acquisire video in rete da telecamere di sicurezza IP. |
| **TAIEmailClient** | Client SMTP/POP3 nativo. | `HostSMTP, PortSMTP, Username, Password` | `SendEmail, FetchEmails` | Recuperare messaggi di posta in arrivo e inviare notifiche. |
| **TAIMessenger** | Gateway WhatsApp e SMS via REST. | `SMSApiURL, WhatsAppApiURL, WhatsAppToken` | `SendSMS, SendWhatsApp` | Inviare notifiche push istantanee su dispositivi mobili. |
| **TAIChromiumBrowser** | Pannello Browser Web integrato. | `URL, ShowAddressBar` | `Navigate, GoBack, Reload` | Visualizzare pagine web ed estrarre il codice sorgente HTML. |
| **TAIOSInputCapture** | Acquisitore di eventi globale del sistema operativo. | `TrackMouse, TrackKeyboard, Active` | `CaptureScreen` | Catturare screenshot dello schermo e loggare tasti globali. |

### 💻 Esempio di Codice Lazarus (TAIInputData)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
