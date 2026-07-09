# kinect_sdk10_direct_frame_test

Test console che chiama direttamente `Kinect10.dll`, senza passare dai componenti visuali. Aiuta a diagnosticare problemi di interoperabilita con la SDK 1.8.

## Output

- Log: `capture_output\kinect_sdk10_direct_frame_test.log`
- Immagine: `capture_output\direct_color_frame.bmp`

## Cosa valida

- Caricamento di `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` e `ReleaseFrame`.

## Requisiti

Windows, Kinect SDK/Runtime 1.8, DLL con la stessa architettura e Kinect collegato.