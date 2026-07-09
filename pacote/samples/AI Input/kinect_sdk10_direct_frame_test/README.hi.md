# kinect_sdk10_direct_frame_test

Console test जो सीधे `Kinect10.dll` call करता है, visual components के बिना. यह SDK 1.8 interop problems diagnose करने में मदद करता है.

## Output

- Log: `capture_output\kinect_sdk10_direct_frame_test.log`
- Image: `capture_output\direct_color_frame.bmp`

## क्या validate करता है

- `Kinect10.dll` loading.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` और `ReleaseFrame`.

## आवश्यकताएं

Windows, Kinect SDK/Runtime 1.8, matching DLL architecture, और connected Kinect sensor.