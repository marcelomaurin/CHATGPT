# 🔌 Suíte de Hardware, Redes e Captura Industrial (IA Input)

Este diretório contém a coleção completa de componentes de aquisição física, interfaces de rede e canais de comunicação industrial da aba **`IA Input`** da biblioteca de Inteligência Artificial para Lazarus/Free Pascal.

Esses componentes foram projetados especificamente para conectar fluxos de dados do mundo real (câmeras, sensores, modems seriais, CLPs industriais e páginas da web) diretamente a modelos de Aprendizado de Máquina (Machine Learning), Redes Neurais e Agentes de IA.

---

## 💻 Resumo dos Componentes

Todos os **13 componentes** são compatíveis com **Windows e Linux**, utilizando código condicional otimizado para o sistema operacional sem adicionar dependências binárias complexas e instáveis.

| Componente | Classe | Aba IDE | Objetivo Principal | Cross-Platform (Win/Linux) |
| :--- | :--- | :--- | :--- | :--- |
| **Data Input** | `TAIInputData` | `IA Input` | Normalização e denormalização linear de dados analíticos. | Pascal Puro |
| **Câmera** | `TAICameraInput` | `IA Input` | Captura nativa de quadros de vídeo. | DirectShow / V4L2 (`/dev/videoX`) |
| **Áudio** | `TAIAudioInput` | `IA Input` | Captura de microfone, arquivos de áudio e mixagem nativa WAV. | MCI / ALSA (`arecord`) |
| **Web Server API**| `TAIWebAPIServer` | `IA Input` | Exposição assíncrona de rotas REST JSON. | `TFPHTTPServer` nativo do FPC |
| **Socket TCP** | `TAISocketTCP` | `IA Input` | Canal cliente e servidor TCP orientado a fluxo de bytes. | Unit `sockets` nativa do FPC |
| **Socket UDP** | `TAISocketUDP` | `IA Input` | Canal leve UDP emissor e receptor de datagramas. | Unit `sockets` nativa do FPC |
| **Serial/Modem** | `TAISerialModem` | `IA Input` | Portas COM/ttyS e comandos AT de Modems GSM. | Unit `serial` nativa do FPC |
| **POS Printer** | `TAIPOSPrinter` | `IA Input` | Impressão térmica de recibos via comandos Esc/POS puros. | Serial e Raw TCP Sockets |
| **CFTV IP** | `TAICFTVIP` | `IA Input` | Captura de frames de câmeras de segurança IP MJPEG. | Requisições HTTP nativas FPC |
| **Modbus TCP** | `TAIModbusClient` | `IA Input` | Empacotamento binário de comandos Modbus de sensores. | Sockets de rede em Pascal puro |
| **MQTT Client** | `TAIMQTTClient` | `IA Input` | Publicação e assinatura IoT em brokers leves. | Thread de recebimento dedicada |
| **Email Client** | `TAIEmailClient` | `IA Input` | Envio via SMTP e checagem POP3 nativos por sockets. | Sockets puros com comandos RFC |
| **Messenger** | `TAIMessenger` | `IA Input` | Disparos de alertas e interações WhatsApp e SMS. | `TFPHTTPClient` nativo com SSL |
| **Ponte CLP** | `TAIIndustrialBridge`| `IA Input`| Comunicação industrial Ethernet com Profinet/Profibus. | Loader dinâmico `.dll` / `.so` |
| **Browser Web** | `TAIChromiumBrowser` | `IA Input` | Navegador embutido que renderiza páginas e HTML. | `TIpHTMLPanel` / CEF4Delphi |

---

## 🛠️ Detalhes dos Componentes e Assinaturas

### 1. `TAIChromiumBrowser`
*   **Descrição**: Componente visual para exibição e navegação em sites ou renderização de telas HTML.
*   **Propriedades**:
    *   `URL`: Endereço web a navegar.
    *   `HTML`: Código HTML bruto da página atual.
    *   `ShowAddressBar`: Mostra/oculta painel superior com barra de navegação e botões.
*   **Métodos**:
    *   `Navigate(const AURL: string)`: Carrega uma nova URL.
    *   `GoBack`: Retorna no histórico de navegação.
    *   `GoForward`: Avança no histórico.
    *   `Reload`: Recarrega a página atual.
    *   `GetHtmlContent: string`: Retorna o HTML em formato string.

### 2. `TAIMQTTClient`
*   **Descrição**: Cliente IoT leve em Pascal puro para se registrar em tópicos e enviar leituras de sensores para modelos de IA.
*   **Propriedades**:
    *   `Host`: Endereço do broker (ex: `broker.hivemq.com`).
    *   `Port`: Porta do broker (padrão: `1883`).
    *   `ClientID`: Identificador único do cliente.
    *   `Active`: Abre/fecha a conexão.
*   **Eventos**:
    *   `OnMessageReceived(Sender: TObject; const ATopic, APayload: string)`: Disparado assincronamente ao receber mensagens.

### 3. `TAIIndustrialBridge`
*   **Descrição**: Ponte para barramentos industriais (CLPs Siemens, Rockwell, etc.).
*   **Mecanismo**: Carrega drivers dinâmicos (`.dll` no Windows ou `.so` no Linux) em runtime. Caso o driver não esteja presente no caminho, entra em modo de simulação, permitindo desenvolver sem o hardware físico por perto.
*   **Métodos**:
    *   `ConnectBridge`: Ativa a ponte e conecta ao CLP.
    *   `ReadBytes(DBNumber, StartByte, Size: Integer; out AData: array of Byte): Boolean`: Lê bytes do banco de dados do CLP.
    *   `WriteBytes(DBNumber, StartByte, Size: Integer; const AData: array of Byte): Boolean`: Escreve dados no CLP.

### 4. `TAIEmailClient`
*   **Descrição**: Envio e captura de e-mails para monitoramento e geração de alertas assíncronos.
*   **Métodos**:
    *   `SendEmail(const ATo, ASubject, ABody: string): Boolean`: Envia e-mail formatado via protocolo SMTP.
    *   `FetchEmails(out AEmails: TStrings): Boolean`: Lê cabeçalhos das últimas mensagens da caixa de entrada POP3.

### 5. `TAIMessenger`
*   **Descrição**: Integração direta com APIs de envio de SMS e da API de nuvem oficial do WhatsApp.
*   **Métodos**:
    *   `SendSMS(const ANumber, AText: string): Boolean`
    *   `SendWhatsApp(const ANumber, AText: string): Boolean`

---

## 🎨 O Projeto de Demonstração GUI (`hardware_net_demo`)

Para testar todos os 13 componentes de forma simples e interativa, compile e execute o projeto localizado na pasta:
`pacote/samples/IA Input/hardware_net_demo/hardware_net_demo.lpi`

O exemplo oferece abas visuais dedicadas para simular conexões MQTT, enviar e-mails de teste, acionar a câmera ou ler dados de simulação CLP Profinet, além de um painel completo de navegação web utilizando o componente visual `TAIChromiumBrowser`.
