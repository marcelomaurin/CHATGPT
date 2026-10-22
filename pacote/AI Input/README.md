# 📥 AI Input — Componentes de Entrada e Captura

A pasta **`pacote/AI Input/`** concentra os componentes de captura de dados, sensores físicos, conexões de rede e periféricos da suíte **TCHATGPT**. Estes componentes pertencem ao pacote Lazarus [**`openai_input.lpk`**](../packages/openai_input.lpk).

---

## 🎯 Propósito do Módulo

O objetivo do módulo **AI Input** é fornecer uma interface uniforme para alimentar pipelines de IA com dados do mundo real e de fontes externas:
- **Periféricos de controle e interação:** Joysticks, gamepads Xbox/WinMM e dispositivos USB.
- **Áudio e Biometria Vocal:** Detecção de locutores e sessões de fala por similaridade de embeddings.
- **Sensores de Profundidade e Câmeras:** Captura de esqueletos e mapas de profundidade com Microsoft Kinect v1.
- **Comunicação e Redes:** Servidores web HTTP embutidos, WebSockets, Sockets TCP/UDP puros e portas seriais/modems.
- **Documentos e Navegação:** Leitura e extração de texto de PDF, DOCX, XLSX e captura de páginas via Chromium.

---

## 📂 Subpastas e Componentes Implementados

Abaixo está o detalhamento de cada subdiretório, seus arquivos fontes e componentes contidos:

| Diretório | Componentes / Unidades | Propósito e Funcionalidade |
|---|---|---|
| [**`AIJoystick/`**](AIJoystick/) | [`TAIJoystick`](AIJoystick/aijoystick.pas) ([README](AIJoystick/README.md)) | Suporte a controles XInput (Xbox 360/One) e joysticks genéricos WinMM com hotplug e normalização de eixos. |
| [**`AIAudio/`**](AIAudio/) | [`TAISpeakerSession`](AIAudio/aispeakersignature.pas), [`TAIAudio`](AIAudio/aiaudio.pas) | Captura de áudio e gerenciamento de sessões de assinatura vocal por similaridade de cosseno de embeddings. |
| [**`AIKinect/`**](AIKinect/) | [`TAIKinectSensor`](AIKinect/aikinect_sensor.pas), [`TAIKinectColorStream`](AIKinect/aikinect_streams.pas), [`TAIKinectDepthStream`](AIKinect/aikinect_streams.pas), [`TAIKinectSkeleton`](AIKinect/aikinect_skeleton.pas) | Integração completa com Kinect SDK 1.0 e libfreenect para rastreamento de esqueletos e profundidade. |
| [**`AICaptureSource/`**](AICaptureSource/) | [`TAICaptureSource`](AICaptureSource/aicapturesource.pas) | Provedor abstrato e genérico de fluxos contínuos de captura. |
| [**`AIUSB/`**](AIUSB/) | [`TAIUSB`](AIUSB/aiusb.pas), [`aiusb_register.pas`](AIUSB/aiusb_register.pas) | Descoberta e enumeração de dispositivos USB conectados ao sistema. |
| [**`AISerial/`**](AISerial/) | [`TAISerial`](AISerial/aiserial.pas), [`TAISerialFingerprint`](AISerial/aiserialfingerprint.pas), [`ailistserialdevices.pas`](AISerial/ailistserialdevices.pas) | Comunicação serial assíncrona, identificação de modems e leitura de periféricos RS-232/USB-Serial. |
| [**`AISockets/`**](AISockets/) | [`TAISocketTCP`](AISockets/aisockets.pas), [`TAISocketUDP`](AISockets/aisockets.pas) | Conexões de rede em baixo nível via sockets TCP e datagramas UDP para troca rápida de pacotes. |
| [**`AIWebServer/`**](AIWebServer/) | [`TAIWebServer`](AIWebServer/aiwebserver.pas) | Servidor web HTTP/REST embutido na aplicação para receber webhooks e requisições remotas de IA. |
| [**`AIChromiumBrowser/`**](AIChromiumBrowser/) | [`TAIChromiumBrowser`](AIChromiumBrowser/aichromiumbrowser.pas) | Navegação web programável e captura de telas e DOM para agentes e web scrapers. |
| [**`AIEmail/`**](AIEmail/) | [`TAIEmail`](AIEmail/aiemail.pas) | Leitura e ingestão de e-mails via protocolos padrão para classificação e extração de entidades. |
| [**`AIMessenger/`**](AIMessenger/) | [`TAIMessenger`](AIMessenger/aimessenger.pas) | Conectores para mensagens e chats bidirecionais. |
| [**`AIInput/`**](AIInput/) | [`TAIInput`](AIInput/aiinput.pas), [`aidocumentreader.pas`](AIInput/aidocumentreader.pas), [`aipdfinput.pas`](AIInput/aipdfinput.pas), [`aidocxinput.pas`](AIInput/aidocxinput.pas), [`aiexcelinput.pas`](AIInput/aiexcelinput.pas) | Ingestão e parsing estruturado de documentos locais (PDF, DOCX, Planilhas Excel). |

---

## 🎮 Exemplos e Demonstrações Práticas

Para ver estes componentes em funcionamento com interface visual e código-fonte completo:
- [**`samples/AI Input/`**](../samples/AI%20Input/):
  - [**`capture_source_demo`**](../samples/AI%20Input/capture_source_demo/): Demonstração de fontes de captura contínua.
  - [**`aiusb_devices_demo`**](../samples/AI%20Input/aiusb_devices_demo/): Listagem e telemetria de portas USB.
  - [**`document_input_demo`**](../samples/AI%20Input/document_input_demo/): Extração e parsing de PDF, Word e Excel.
  - [**`kinect_skeleton_demo`**](../samples/AI%20Input/kinect_skeleton_demo/): Visualização 3D de esqueleto corporal do Kinect.
  - [**`serial_demo`**](../samples/AI%20Input/serial_demo/): Monitor serial bidirecional.
  - [**`socket_server_client_demo`**](../samples/AI%20Input/socket_server_client_demo/): Comunicação cliente-servidor TCP/UDP.
  - [**`webserver_demo`**](../samples/AI%20Input/webserver_demo/): Servidor REST integrado.
- [**`samples/AI Audio/speaker_signature_demo/`**](../samples/AI%20Audio/speaker_signature_demo/): Demonstração e manual de validação de biometria vocal ([Manual do Usuário](../samples/AI%20Audio/speaker_signature_demo/README.md)).

---

## 🧪 Testes Unitários

- [**`test_aijoystick.lpr`**](../../tests/test_aijoystick.lpr): Teste automatizado do componente `TAIJoystick` com mock de desconexão e eixos normalizados.
- [**`test_speaker_signature.lpr`**](../../tests/test_speaker_signature.lpr): Teste automatizado da sessão de similaridade de locutor.