# 🔌 Documentation de l'onglet AI Input

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Input**.

## Capture Avancée de Périphériques d'Entrée, de Capteurs et de Réseaux.
Cartographie et capture les données du monde réel (clavier, souris, caméras, brokers MQTT, sockets) pour alimenter les modèles cognitifs.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIInputData** | Normalisateur linéaire pour vecteurs numériques. | `MinRange, MaxRange` | `Normalize, Denormalize` | Normaliser les données brutes dans des plages tolérées par les réseaux de neurones. |
| **TAICameraInput** | Captureur de flux de caméra physique native. | `DeviceIndex, Width, Height, Active` | `StartCapture, StopCapture, CaptureFrame` | Fournir des flux visuels en temps réel pour l'IA de vision. |
| **TAIAudioInput** | Enregistreur et mixeur audio. | `InputSource (Mic, Wave), BitRate` | `StartRecord, StopRecord, MixAudio` | Enregistrer les signaux vocaux ambiants et mélanger les pistes WAV pour l'IA. |
| **TAIWebAPIServer** | Serveur HTTP API REST embarqué. | `Port, Active, AllowedRoutes` | `StartServer, StopServer` | Exposer des points de terminaison HTTP REST pour des systèmes externes. |
| **TAISocketTCP** | Connecteur Sockets TCP Client/Serveur. | `Host, Port, Mode, Active` | `Connect, Disconnect, SendText, ReceiveText` | Établir des flux stables de communication réseau de bas niveau. |
| **TAISocketUDP** | Connecteur de Sockets UDP rapide. | `Host, Port, Active` | `SendText, ReceiveText` | Transmettre la télémétrie asynchrone des capteurs. |
| **TAISerialModem** | Port Série et Passerelle SMS GSM. | `DeviceName, BaudRate, Active` | `OpenPort, SendATCommand, SendSMS` | Envoyer des SMS et interfacer le matériel hérité via modems. |
| **TAICFTVIP** | Connecteur caméra IP MJPEG pour CFTV. | `IPAddress, Port, Active` | `CaptureStreamFrame` | Acquérir des flux vidéo de caméras IP de sécurité sur le réseau. |
| **TAIEmailClient** | Client SMTP/POP3 natif. | `HostSMTP, PortSMTP, Username, Password` | `SendEmail, FetchEmails` | Récupérer des e-mails et envoyer des rapports d'état. |
| **TAIMessenger** | Passerelle WhatsApp et SMS via REST. | `SMSApiURL, WhatsAppApiURL, WhatsAppToken` | `SendSMS, SendWhatsApp` | Envoyer des alertes instantanées sur téléphones mobiles. |
| **TAIChromiumBrowser** | Panneau de Navigateur Web intégré. | `URL, ShowAddressBar` | `Navigate, GoBack, Reload` | Afficher des UIs web et extraire du contenu HTML brut. |
| **TAIOSInputCapture** | Enregistreur d'événements globaux du système. | `TrackMouse, TrackKeyboard, Active` | `CaptureScreen` | Capturer l'écran entier et intercepter des touches claviers. |
| **TAIListSerialDevices**| Énumérateur et identificateur de ports série. | `ProbeOpenable, AutoRefresh, AutoRefreshIntervalMs` | `Refresh` | Fournir des métadonnées matérielles riches (VID, PID, pilote, numéro de série, fabricant) des Arduinos et périphériques connectés pour l'IA. |

### 💻 Exemple de Code Lazarus (TAIInputData)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
