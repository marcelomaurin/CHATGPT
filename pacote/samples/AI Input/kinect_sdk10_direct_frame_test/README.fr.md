# kinect_sdk10_direct_frame_test

Test console qui appelle directement `Kinect10.dll`, sans passer par les composants visuels. Il aide a diagnostiquer les problemes d'interoperabilite avec le SDK 1.8.

## Sortie

- Log: `capture_output\kinect_sdk10_direct_frame_test.log`
- Image: `capture_output\direct_color_frame.bmp`

## Ce qui est valide

- Chargement de `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` et `ReleaseFrame`.

## Prerequis

Windows, Kinect SDK/Runtime 1.8, DLL de meme architecture et Kinect connecte.