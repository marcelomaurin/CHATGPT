# 🔌 Lazarus AI Suite — Aba `AI Input`

A pasta **AI Input** concentra componentes de entrada, captura e comunicação usados pela suíte CHATGPT em Lazarus/Free Pascal.

> Modbus, MQTT e bridges industriais pertencem ao pacote/área **AI Industrial**. Eles não devem ser documentados como componentes de AI Input.

## Principais grupos

- captura de dados e fontes de entrada;
- serial e modem;
- USB e descoberta de dispositivos;
- sockets TCP/UDP;
- servidor Web/API;
- Chromium/browser capture;
- e-mail como fonte de entrada;
- Kinect e sensores compatíveis;
- gerenciamento/inventário de hardware.

## Componentes e samples de referência

Entre os componentes demonstrados pelos samples da suíte estão `TAIUSB`, `TAICaptureSource`, `TAIChromiumBrowser`, `TAIEmailClient`, `TAIKinectSensor`, `TAIKinectColorStream`, `TAIKinectDepthStream`, `TAIKinectSkeleton`, `TAISerialModem`, `TAISocketTCP`, `TAISocketUDP` e `TAIWebAPIServer`.

Consulte `pacote/COMPONENT_STATUS.md` para o estado atual de cada integração e `pacote/samples/AI Input/` para exemplos executáveis.

## Hardware e runtime

A compilação de um sample não comprova automaticamente que o dispositivo, driver, DLL, browser runtime ou serviço externo esteja disponível na máquina final. Sempre valide o backend real da plataforma.

Para serial/USB/Kinect/câmera, trate ausência de dispositivo como condição normal de runtime e não como prova de erro de compilação do componente.

## Dependências

Evite dependências implícitas da configuração local do Lazarus. Quando um componente exigir biblioteca externa ou runtime nativo, a documentação e o instalador devem declarar essa dependência explicitamente.

## Idiomas

- [Português](README.pt.md)
- [English](README.en.md)
- [Español](README.es.md)
- [Français](README.fr.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

As traduções devem preservar a mesma lista de componentes e as mesmas limitações técnicas desta página.
