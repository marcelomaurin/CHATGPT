# Architectural Limitations

This document lists the scope limitations and architectural constraints of the `mp_pose_bridge` version 1.0.

## 1. 64-bit Target Only
- **Constraint:** The library only targets `windows-x86_64` and `linux-x86_64`.
- **Reasoning:** MediaPipe's underlying TensorFlow Lite engine relies on SIMD instructions (AVX, SSE) and x86-64 assembly extensions. No official support or build targets exist for 32-bit (i386/x86) desktop architectures. Attempting to build or load the library on 32-bit platforms will result in linkage errors or compilation crashes.

## 2. Supported Modes (Synchronous Only)
The initial release only supports synchronous modes:
- **`IMAGE` (Mode 0):** Decodes a single static image and returns results immediately.
- **`VIDEO` (Mode 1):** Processes video frames sequentially. Requires a monotonically increasing timestamp (`timestamp_ms`).
- **`LIVE_STREAM` (Async callbacks):** NOT supported in v1.0. Live streaming callbacks require asynchronous multi-threading synchronization, thread marshaling back to the LCL main thread (via `Synchronize`/`Queue`), and pointer protection, which will be addressed in future ABI v2 updates.

## 3. OS System Dependencies
Because the library wraps TensorFlow Lite and MediaPipe, the host machine must have basic operating system packages installed:
- Windows: **VC++ Redistributable Runtime** (if the bridge was not compiled with `/MT`).
- Linux: **glibc 2.29+** and standard thread libraries.
