# kinect_capture_demo

Demo grafico para validar a captura de video colorido do Kinect usando os componentes `TAIKinectSensor`, `TAIKinectColorStream` e, opcionalmente, `TAIKinectDepthStream`.

## Objetivo

Este demo abre o sensor Kinect, inicia o stream colorido, mostra os frames na tela e registra eventos na aba **Log**. A opcao **Depth** liga tambem o stream de profundidade.

## Requisitos

- Windows.
- Kinect para Windows SDK/Runtime 1.8 instalado.
- `Kinect10.dll` disponivel no sistema.
- Aplicacao compilada com a mesma arquitetura da DLL instalada.
- Sensor Kinect conectado e livre para uso.

## Como usar

1. Abra `kinect_capture_demo.exe`.
2. Deixe `Device` em `0` para o backend SDK10.
3. Marque **Depth** apenas se quiser testar profundidade.
4. Clique em **Conectar**.
5. Veja o video na aba **Video**.
6. Acompanhe mensagens na aba **Log**.
7. Clique em **Desconectar** antes de fechar.

## Logs

O demo mostra eventos no `memLog` e tambem le o log interno do backend:

`%TEMP%\aikinect_sdk10_backend.log`

Esse log inclui inicializacao da SDK, abertura de stream, captura de frames, `LockRect`, `ReleaseFrame` e `NuiShutdown`.

## Solucao de problemas

- Se nao aparecer imagem, confira a aba **Log**.
- Se `NuiInitialize` falhar, verifique se outro programa esta usando o Kinect.
- Se `Kinect10.dll` nao for encontrada, reinstale o Runtime/SDK 1.8.
- Para testar somente a camera colorida, deixe **Depth** desmarcado.