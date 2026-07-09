# kinect_sdk10_direct_frame_test

Teste de console que chama `Kinect10.dll` diretamente, sem passar pelos componentes visuais. Ele ajuda a diagnosticar problemas de interoperabilidade com a SDK 1.8.

## Saida

- Log: `capture_output\kinect_sdk10_direct_frame_test.log`
- Imagem: `capture_output\direct_color_frame.bmp`

## O que valida

- Carregamento da `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` e `ReleaseFrame`.

## Requisitos

Windows, Kinect SDK/Runtime 1.8, DLL da mesma arquitetura e Kinect conectado.