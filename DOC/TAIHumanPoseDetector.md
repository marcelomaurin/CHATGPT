# TAIHumanPoseDetector Component Documentation

`TAIHumanPoseDetector` is a Lazarus component designed to interface with the MediaPipe Pose Landmarker using a versioned C/C++ bridge DLL/SO.

## Key Features

- **64-bit Exclusivity:** Supported only on `windows-x86_64` and `linux-x86_64`. Under 32-bit platforms, the component compiles fine but reports `Available = False` to prevent build issues.
- **Dynamic Bridge Loading:** Can load the bridge library dynamically from custom paths or automatic locations.
- **SIM / REAL Backends:**
  - **SIM Backend:** Runs mock inference returning 33 simulated landmarks (no external dependencies, no `.task` file required).
  - **REAL Backend:** Runs real MediaPipe machine learning inference (requires a valid `.task` model file).

## How to Build the SIM Bridge Library

1. Navigate to `bridge/mediapipe_pose/build`.
2. Configure CMake with backend set to `SIM`:
   ```bash
   cmake -B cmake-build-release -S . -DMP_BRIDGE_BACKEND=SIM -DCMAKE_BUILD_TYPE=Release
   ```
3. Build the project:
   ```bash
   cmake --build cmake-build-release --config Release
   ```
4. Find the output binary `mp_pose_bridge.dll` (Windows) or `libmp_pose_bridge.so` (Linux).

## Where to Place the Bridge Binary

The component looks for the library in the following order:
1. `BridgeDLLPath` (when `LoadMode = mplmManualPath`).
2. `RuntimePath` (if specified).
3. The automatic relative path: `runtime/mediapipe/pose/mp_0_10_35/<os>-x86_64/`
4. The executable directory.
5. System loader path.

## How to Use in Pascal/Lazarus

```pascal
var
  Detector: TAIHumanPoseDetector;
  Bmp: TBitmap;
begin
  Detector := TAIHumanPoseDetector.Create(nil);
  try
    Detector.LoadMode := mplmAuto; // Or mplmManualPath and set BridgeDLLPath
    if not Detector.Initialize then
    begin
      WriteLn('Failed to load bridge: ', Detector.LastError);
      Exit;
    end;

    Bmp := TBitmap.Create;
    try
      Bmp.LoadFromFile('person.png');
      if Detector.DetectBitmap(Bmp) then
      begin
        WriteLn('Poses detected: ', Detector.GetPoseCount);
        // Draw the skeleton
        Detector.DrawResult(MyPaintBox.Canvas, Rect(0, 0, MyPaintBox.Width, MyPaintBox.Height));
      end;
    finally
      Bmp.Free;
    end;
  finally
    Detector.Free;
  end;
end;
```

## Common Errors

- **Bridge DLL not found:** Ensure the library is copied to the correct runtime directory.
- **32-bit compilation attempt:** Ensure Lazarus builds for Target CPU `x86_64`.
