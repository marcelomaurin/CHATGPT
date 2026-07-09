# kinect_sdk10_direct_frame_test

Prueba de consola que llama directamente a `Kinect10.dll`, sin usar los componentes visuales. Ayuda a diagnosticar problemas de interoperabilidad con la SDK 1.8.

## Salida

- Log: `capture_output\kinect_sdk10_direct_frame_test.log`
- Imagen: `capture_output\direct_color_frame.bmp`

## Que valida

- Carga de `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` y `ReleaseFrame`.

## Requisitos

Windows, Kinect SDK/Runtime 1.8, DLL con la misma arquitectura y Kinect conectado.