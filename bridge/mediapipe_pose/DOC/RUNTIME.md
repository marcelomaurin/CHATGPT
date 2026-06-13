# Runtime Architecture

This document outlines the folder layout and deployment structures for packaging the MediaPipe Pose Bridge runtime.

## 1. Directory Layout

The binary and model files must be organized into versioned folders to enable dynamic auto-resolution:

```text
runtime/
  mediapipe/
    pose/
      mp_0_10_35/                      # MediaPipe version used
        windows-x86_64/
          mp_pose_bridge.dll           # The compiled Windows DLL
          bridge.json                  # Runtime manifest description
          models/
            pose_landmarker_full.task  # Full precision model
            pose_landmarker_lite.task  # Lite precision model
            pose_landmarker_heavy.task # Heavy precision model
        linux-x86_64/
          libmp_pose_bridge.so         # The compiled Linux SO
          bridge.json
          models/
            pose_landmarker_full.task
            ...
```

## 2. Runtime Manifest (`bridge.json`)
Every platform directory contains a `bridge.json` file. This is checked by the Lazarus application to validate the parameters:
```json
{
  "name": "AI MediaPipe Pose Bridge",
  "component": "TAIHumanPoseDetector",
  "bridge_version": "1.0.0",
  "bridge_abi_version": 1,
  "compatible_mediapipe_version": "0.10.35",
  "binary": "mp_pose_bridge.dll",
  "task": "PoseLandmarker",
  "models": {
    "lite": "models/pose_landmarker_lite.task",
    "full": "models/pose_landmarker_full.task",
    "heavy": "models/pose_landmarker_heavy.task"
  },
  "default_model": "full",
  "landmark_count": 33
}
```

## 3. Dynamic Loading Policy
The Lazarus component resolves pathing automatically:
1. It searches up to 5 parent directories starting from the executable's directory.
2. It looks for the folder matching `runtime/mediapipe/pose/mp_<version>/<platform>-x86_64/`.
3. If not found, it falls back to looking for the bridge library right next to the application binary.
