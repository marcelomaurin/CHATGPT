# TAIHumanPoseDetector Component Documentation

`TAIHumanPoseDetector` is a Lazarus component designed to interface with the MediaPipe Pose Landmarker using a versioned C/C++ bridge DLL/SO.

## Key Features

- **64-bit Exclusivity:** Supported only on `windows-x86_64` and `linux-x86_64`. Under 32-bit platforms, the component compiles fine but reports `Available = False` to prevent build issues.
- **Dynamic Bridge Loading:** Can load the bridge library dynamically from custom paths or automatic runtime locations.
- **Versioned Native Bridge:** The bridge binary name must identify the bridge version, compatible MediaPipe version, platform and architecture.
- **SIM / REAL Backends:**
  - **SIM Backend:** Runs mock inference returning 33 simulated landmarks (no external dependencies, no `.task` file required).
  - **REAL Backend:** Runs real MediaPipe machine learning inference (requires a valid `.task` model file).

## Fase 6 Decision — Official Bridge DLL/SO Naming

The official bridge binary name is **versioned**. This is intentional and must not be replaced by a generic name as the default.

Official Windows x64 bridge name:

```text
ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
```

Meaning:

```text
ai_mediapipe_pose_bridge  = bridge purpose
v1_0_0                    = bridge implementation/API release
mp0_10_35                 = compatible MediaPipe version 0.10.35
win64                     = Windows 64-bit binary
```

`mp_pose_bridge.dll` is considered a **legacy compatibility fallback only**. It must not be the required name for normal runtime loading, because it hides the MediaPipe version and can accidentally load an incompatible binary.

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
4. The expected Windows output name for this phase is:
   ```text
   ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
   ```

## Where to Place the Bridge Binary

The component should look for the library in the following order:

1. `BridgeDLLPath` when `LoadMode = mplmManualPath`. This may point directly to the versioned DLL/SO.
2. `RuntimePath` if specified.
3. Automatic relative runtime path: `runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/` or `linux-x86_64/`.
4. The executable directory.
5. Legacy fallback name only when needed: `mp_pose_bridge.dll` or `libmp_pose_bridge.so`.

Recommended runtime layout:

```text
runtime/
  mediapipe/
    pose/
      mp_0_10_35/
        windows-x86_64/
          ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
          bridge_manifest.json
          models/
            pose_landmarker_lite.task
            pose_landmarker_full.task
            pose_landmarker_heavy.task
        linux-x86_64/
          libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so
          bridge_manifest.json
          models/
            pose_landmarker_lite.task
            pose_landmarker_full.task
            pose_landmarker_heavy.task
```

## Demo Loading Rule

The demo must allow the user to select the real versioned DLL/SO file. The selected file name must be respected. The demo must not require the user to rename the file to `mp_pose_bridge.dll`.

Correct manual selection example:

```text
D:\projetos\maurinsoft\CHATGPT\pacote\samples\AI MediaPipe Vision\ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
```

## How to Use in Pascal/Lazarus

```pascal
var
  Detector: TAIHumanPoseDetector;
  Bmp: TBitmap;
begin
  Detector := TAIHumanPoseDetector.Create(nil);
  try
    Detector.LoadMode := mplmManualPath;
    Detector.BridgeDLLPath := 'ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll';

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

- **Bridge DLL not found:** Ensure the versioned bridge binary is copied to the runtime directory or selected directly in `BridgeDLLPath`.
- **Wrong bridge filename:** Do not rename the official DLL to hide its MediaPipe version. Use the versioned file name.
- **32-bit compilation attempt:** Ensure Lazarus builds for Target CPU `x86_64`.
- **Dependency load failure:** If the DLL exists but loading still fails, check missing dependent DLLs, C++ runtime, wrong architecture, or missing exported functions.
