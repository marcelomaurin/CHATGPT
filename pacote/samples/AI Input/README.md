# AI Input Samples

Esta pasta reúne exemplos de entrada de dados para os componentes do projeto **CHATGPT**, incluindo captura, automação, comunicação e integração com dispositivos.

## Observação sobre Kinect / AIKinect

Os demos e componentes da área **AI Input** que utilizam **Kinect** ou **AIKinect** dependem dos instaladores legados oficiais do **Kinect for Windows SDK** e do **Kinect for Windows Developer Toolkit**.

Para executar, compilar ou testar os pacotes relacionados ao Kinect, instale previamente os seguintes componentes no Windows:

| Componente | Arquivo esperado | Link oficial |
|---|---|---|
| Kinect for Windows SDK v1.7 | `KinectSDK-v1.7-Setup.exe` | [Microsoft Download Center - Kinect for Windows SDK v1.7](https://www.microsoft.com/en-us/download/details.aspx?id=36996) |
| Kinect for Windows Developer Toolkit v1.7 | `KinectDeveloperToolkit-v1.7.0-Setup.exe` | [Microsoft Download Center - Kinect for Windows Developer Toolkit v1.7](https://www.microsoft.com/en-us/download/details.aspx?id=36998) |
| Kinect for Windows Developer Toolkit v1.8 | `KinectDeveloperToolkit-v1.8.0-Setup.exe` | [Microsoft Download Center - Kinect for Windows Developer Toolkit v1.8](https://www.microsoft.com/en-us/download/details.aspx?id=40276) |

> Atenção: o **Kinect Developer Toolkit v1.8** normalmente espera o **Kinect for Windows SDK v1.8** instalado. Quando o objetivo for manter compatibilidade com código legado baseado na API 1.7, use o conjunto **SDK v1.7 + Developer Toolkit v1.7**. Se algum demo for migrado para 1.8, considere instalar também o [Kinect for Windows SDK v1.8](https://www.microsoft.com/en-us/download/details.aspx?id=40278).

## Ordem recomendada de instalação

1. Desconecte o sensor Kinect da USB.
2. Remova drivers Kinect antigos ou incompatíveis, se houver.
3. Instale o `KinectSDK-v1.7-Setup.exe`.
4. Instale o `KinectDeveloperToolkit-v1.7.0-Setup.exe`.
5. Se precisar validar recursos do Toolkit 1.8, instale o SDK/Toolkit 1.8 correspondente.
6. Reinicie o Windows, conecte a fonte externa do Kinect e depois conecte o sensor à USB.

## Requisitos importantes

- Windows 7, Windows 8 ou Windows Embedded Standard 7 para SDK v1.7.
- Processador x86 ou x64.
- USB 2.0 dedicado para o Kinect.
- .NET Framework 4.0 ou 4.5, conforme o ambiente.
- Visual Studio 2010 ou 2012 quando for compilar exemplos oficiais do toolkit.

## Observação para usuários do Lazarus

Os componentes em Lazarus/Free Pascal podem compilar sem o Toolkit em máquinas de desenvolvimento que não executem o hardware, mas os demos que acessam câmera, profundidade, esqueleto, áudio ou ferramentas do Kinect exigem o runtime/SDK instalado no Windows.

Em caso de erro de inicialização do sensor, confirme:

- se o sensor está alimentado por fonte externa;
- se ele está em uma porta USB 2.0 estável;
- se o SDK correto está instalado;
- se não há driver alternativo de Kinect conflitando com o driver da Microsoft;
- se a arquitetura do aplicativo e das bibliotecas instaladas está compatível com o Windows usado.
