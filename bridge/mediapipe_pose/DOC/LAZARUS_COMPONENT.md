# Lazarus Component Integration with Pose Bridge

This document details the interface layout and integration between the dynamic bridge library and the Lazarus `TAIHumanPoseDetector` component.

## Architecture

```
[Lazarus Application]
       │
       ▼
[TAIHumanPoseDetector]  <-- mp_pose_bridge.pas (Lazarus Binding)
       │
       ▼ (Dynamic Cdecl API Calls)
[mp_pose_bridge.dll / .so]
       │
       ├─► SIM Backend: sinusoid mock generator
       └─► REAL Backend: MediaPipe C API
```

## ABI Functions

The Pascal binding is defined in [mp_pose_bridge.pas](file:///D:/projetos/maurinsoft/CHATGPT/pacote/AI%20Vision/mp_pose_bridge.pas). It exports:

1. `mp_pose_get_info`: Retrieves struct info and current backend (`SIM` or `REAL`).
2. `mp_pose_create`: Creates the internal landmarker instance.
3. `mp_pose_destroy`: Releases context memory.
4. `mp_pose_detect`: Detects landmarks from raw RGB buffer.
5. `mp_pose_free_result`: Safely releases result structures.
6. `mp_pose_last_error`: Returns the last error message.

## Memory Safety

- **Context (`mp_pose_context`):** Managed in C++ using `new` and `delete` to correctly run constructors/destructors of standard library types (`std::string`).
- **Results (`mp_pose_result`):** Plain Old Data (POD) structs allocated with `calloc` and released using `mp_pose_free_result` which nullifies the caller's pointer (`mp_pose_result**`).
- **No exception propagation:** The bridge uses C calling convention (`cdecl`). No C++ exceptions are propagated to Pascal.
