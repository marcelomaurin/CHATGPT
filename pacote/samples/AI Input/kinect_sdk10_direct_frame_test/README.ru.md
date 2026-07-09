# kinect_sdk10_direct_frame_test

Консольный тест, который напрямую вызывает `Kinect10.dll` без визуальных компонентов. Он помогает диагностировать проблемы взаимодействия с SDK 1.8.

## Вывод

- Лог: `capture_output\kinect_sdk10_direct_frame_test.log`
- Изображение: `capture_output\direct_color_frame.bmp`

## Что проверяет

- Загрузку `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` и `ReleaseFrame`.

## Требования

Windows, Kinect SDK/Runtime 1.8, DLL той же архитектуры и подключенный Kinect.