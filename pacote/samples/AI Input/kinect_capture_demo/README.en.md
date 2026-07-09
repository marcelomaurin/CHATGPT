# kinect_capture_demo

Graphical demo for validating Kinect color video capture using `TAIKinectSensor`, `TAIKinectColorStream`, and optionally `TAIKinectDepthStream`.

## Purpose

This demo opens the Kinect sensor, starts the color stream, displays frames on screen, and records events in the **Log** tab. The **Depth** option also enables the depth stream.

## Requirements

- Windows.
- Kinect for Windows SDK/Runtime 1.8 installed.
- `Kinect10.dll` available on the system.
- Application built for the same architecture as the installed DLL.
- Kinect sensor connected and not in use by another application.

## How to use

1. Run `kinect_capture_demo.exe`.
2. Keep `Device` set to `0` for the SDK10 backend.
3. Enable **Depth** only if you want to test depth capture.
4. Click **Conectar**.
5. Watch the image in the **Video** tab.
6. Check messages in the **Log** tab.
7. Click **Desconectar** before closing.

## Logs

The demo writes events to `memLog` and reads the backend log:

`%TEMP%\aikinect_sdk10_backend.log`

The backend log includes SDK initialization, stream opening, frame capture, `LockRect`, `ReleaseFrame`, and `NuiShutdown`.

## Troubleshooting

- If no image appears, check the **Log** tab.
- If `NuiInitialize` fails, make sure no other application is using the Kinect.
- If `Kinect10.dll` is missing, reinstall Runtime/SDK 1.8.
- To test only the color camera, leave **Depth** unchecked.