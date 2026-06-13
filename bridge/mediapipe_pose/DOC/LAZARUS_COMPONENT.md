# Lazarus Component Integration with Pose Bridge

This document describes the interface layout and integration between the dynamic bridge library and the Lazarus `TAIHumanPoseDetector` component.

## Architecture

```text
[Lazarus Application]
       |
       v
[TAIHumanPoseDetector]  <-- mp_pose_bridge.pas (Lazarus Binding)
       |
       v (Dynamic cdecl API calls)
[ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll / libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so]
       |
       +--> SIM backend: sinusoid mock generator
       +--> REAL backend: MediaPipe C API
```

## ABI Functions

The Pascal binding is defined in `mp_pose_bridge.pas`. It exports:

1. `mp_pose_get_info`: retrieves struct info and current backend (`SIM` or `REAL`).
2. `mp_pose_create`: creates the internal landmarker instance.
3. `mp_pose_destroy`: releases context memory.
4. `mp_pose_detect`: detects landmarks from a raw RGB buffer.
5. `mp_pose_free_result`: safely releases result structures.
6. `mp_pose_last_error`: returns the last error message.

## Memory Safety

- Context is managed in C++ using `new` and `delete` so constructors and destructors run correctly.
- Results are plain data structs allocated with `calloc` and released through `mp_pose_free_result`, which nullifies the caller pointer.
- No C++ exceptions are propagated through the C ABI boundary.

## Component Readiness

The Lazarus component exposes an `Initialized` property. Use it to tell whether the detector handle exists, instead of treating `Available` as "ready to detect".

## Legacy Compatibility

The loader still accepts `mp_pose_bridge.dll` and `libmp_pose_bridge.so` as fallback names for older local builds, but the versioned filenames above are the official ones.
