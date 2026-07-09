# kinect_sdk10_direct_frame_test

Console test that calls `Kinect10.dll` directly, without using the visual components. It helps diagnose SDK 1.8 interop problems.

## Output

- Log: `capture_output\kinect_sdk10_direct_frame_test.log`
- Image: `capture_output\direct_color_frame.bmp`

## What it validates

- Loading `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` and `ReleaseFrame`.

## Requirements

Windows, Kinect SDK/Runtime 1.8, matching DLL architecture, and a connected Kinect sensor.