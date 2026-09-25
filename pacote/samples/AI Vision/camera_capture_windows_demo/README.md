# Windows Camera Preview

This sample uses `TAICaptureSource` with the Windows VFW camera backend.

## Build and run

1. Open `camera_capture_windows_demo.lpi` in Lazarus with the `openai_input`, `openai_vision`, and LCL packages available.
2. Build and run the project.
3. Leave **Simulation Mode** unchecked, enter the VFW driver index (normally `0`), and click **Start Camera**.
4. The camera stays active and displays a live preview in the black panel. Click **Stop Camera** to release it. Closing the window also stops capture.

The status and log show connection and capture errors. Simulation Mode only checks the interface flow; it does not open a camera or generate frames.

The index is a VFW driver index (0-9), not a DirectShow device-list position. This example does not require Python or OpenCV.
