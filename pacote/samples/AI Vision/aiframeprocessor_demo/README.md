# TAIFrameProcessor Demo (Native Lazarus)

This sample project demonstrates the usage of component `TAIFrameProcessor` from the `openai_vision` package without OpenCV or Python dependencies.

## Features Illustrated
- **ModifyInput (True/False)**: Observe if input source bitmap is preserved or altered in memory.
- **ScaleFactor (Resize)**: Resize input dynamically using nearest-neighbor.
- **Grayscale Conversion**: Realize native weighted grayscale filtering.
- **RGB Channel Modes**: Try extraction, keeping, removing, swapping, and inverting color channels.
- **Individual Channel Tweaking**: Tweak gains, offsets, and inversion parameters when custom or overrides are enabled.
- **Diagnostic Reports**: View exact sizing, timing, and properties of the last execution.

## How to Build & Run
1. Open `aiframeprocessor_demo.lpi` in Lazarus.
2. Build the project (`Ctrl+F9` or run `lazbuild.exe`).
3. Launch, load any local image, select desired channel parameters, and click "Processar Frame".

## Interface
![TAIFrameProcessor Demo](../../../../screenshots/TAIFrameProcessor%20Demo.jpg)
