# Runtime Architecture

This document outlines the folder layout and deployment structure for the MediaPipe Pose Bridge runtime.

## 1. Directory Layout

The binary and model files are organized into versioned folders to enable dynamic auto-resolution:

```text
runtime/
  mediapipe/
    pose/
      mp_0_10_35/
        windows-x86_64/
          ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
          bridge.json
          models/
            pose_landmarker_full.task
            pose_landmarker_lite.task
            pose_landmarker_heavy.task
        linux-x86_64/
          libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so
          bridge.json
          models/
            pose_landmarker_full.task
            ...
```

For `REAL` backend validation, the loader expects the selected DLL/SO to live in the same runtime tree as `models/pose_landmarker_full.task`. The SIM backend can run with the DLL/SO alone.

## 2. Runtime Manifest (`bridge.json`)

Every platform directory contains a `bridge.json` file. The Lazarus application can use it to validate runtime parameters:

```json
{
  "name": "AI MediaPipe Pose Bridge",
  "component": "TAIHumanPoseDetector",
  "bridge_version": "1.0.0",
  "bridge_abi_version": 1,
  "compatible_mediapipe_version": "0.10.35",
  "binary": "ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll",
  "task": "PoseLandmarker",
  "models": {
    "lite": "models/pose_landmarker_lite.task",
    "full": "models/pose_landmarker_full.task",
    "heavy": "models/pose_landmarker_heavy.task"
  },
  "default_model": "full",
  "landmark_count": 33,
  "backend": "SIM",
  "link_mode": "static",
  "dependencies": []
}
```

## 3. Dynamic Loading and Link Modes

The runtime bridge supports two link modes recorded in `bridge.json`:
- `static`: the bridge is compiled completely statically and does not require secondary libraries.
- `sidecar`: the bridge relies on external sidecar libraries that live in the same directory as the bridge binary.

### Loader Resolution Requirements (Sidecar mode)

To prevent polluting global paths such as `PATH` or `LD_LIBRARY_PATH`, the client loader resolves dependencies locally:
1. Windows: the loader uses `SetDllDirectory` or `AddDllDirectory` for the directory that contains the bridge binary and its sidecar DLLs.
2. Linux: the shared library is built with `rpath` set to `$ORIGIN`, forcing the loader to resolve sidecar `.so` dependencies from the same directory.

## 4. Legacy Compatibility

`mp_pose_bridge.dll` and `libmp_pose_bridge.so` are kept only as compatibility fallbacks inside the loader. They are not the official runtime filenames.
