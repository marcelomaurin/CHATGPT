# kinect_capture_demo

Demo grafico para validar la captura de video en color del Kinect usando `TAIKinectSensor`, `TAIKinectColorStream` y, opcionalmente, `TAIKinectDepthStream`.

## Objetivo

El demo abre el sensor Kinect, inicia el stream de color, muestra los frames en pantalla y registra eventos en la pestaña **Log**. La opcion **Depth** tambien activa el stream de profundidad.

## Requisitos

- Windows.
- Kinect for Windows SDK/Runtime 1.8 instalado.
- `Kinect10.dll` disponible en el sistema.
- Aplicacion compilada para la misma arquitectura de la DLL instalada.
- Sensor Kinect conectado y libre.

## Como usar

1. Ejecute `kinect_capture_demo.exe`.
2. Mantenga `Device` en `0` para el backend SDK10.
3. Active **Depth** solo si desea probar profundidad.
4. Haga clic en **Conectar**.
5. Vea la imagen en la pestaña **Video**.
6. Revise mensajes en **Log**.
7. Haga clic en **Desconectar** antes de cerrar.

## Logs

El demo escribe eventos en `memLog` y lee el log interno del backend:

`%TEMP%\aikinect_sdk10_backend.log`

Incluye inicializacion de la SDK, apertura de stream, captura de frames, `LockRect`, `ReleaseFrame` y `NuiShutdown`.

## Solucion de problemas

- Si no aparece imagen, revise **Log**.
- Si falla `NuiInitialize`, verifique que otro programa no use el Kinect.
- Si falta `Kinect10.dll`, reinstale Runtime/SDK 1.8.
- Para probar solo la camara color, deje **Depth** desmarcado.