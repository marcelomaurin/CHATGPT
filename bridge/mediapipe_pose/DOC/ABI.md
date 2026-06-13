# C ABI Specification

This document defines the frozen C ABI boundary contract for the `mp_pose_bridge` library.

## 1. Calling Convention
- **Convention:** `cdecl` must be used for all exported functions on all platforms (Windows and Linux).
- **Name Mangling:** Disabled via `extern "C"`.

## 2. Platform Target
- **Supported:** Exclusively 64-bit (`windows-x86_64` and `linux-x86_64`).
- **Unsupported:** 32-bit platforms.

## 3. Data Structs and Types
All structure properties must use standard fixed-width types (`int32_t`, `int64_t`, `float`). The caller is responsible for setting `struct_size = sizeof(<struct>)` as the first property for defensive version checks.

### mp_pose_info
Exposes runtime metadata. Safe to call without initializing a detector handle.
- `abi_version`: Expected to match `MP_POSE_ABI_VERSION` (currently `1`).
- `platform`: `"windows"` or `"linux"`.
- `arch`: `"x86_64"`.

### mp_image_raw
Contains packed raw image buffer:
- `channels`: `3` for RGB, `4` for RGBA.
- `stride`: Must be greater than or equal to `width * channels`.
- Ordem de cores: **RGB/RGBA** (not BGR/BGRA).

### mp_landmark & mp_world_landmark
- **Normalized Landmarks (`mp_landmark`):** Coordinates normalized in image space (`x` and `y` range: `[0.0, 1.0]`).
- **World Landmarks (`mp_world_landmark`):** Real-world metric 3D coordinates in meters.

## 4. Memory Ownership
- **Allocation:** Output structures (`mp_pose_result`) are allocated inside the DLL/SO heap context.
- **Deallocation:** The client application **MUST NOT** free or release memory using host malloc/free/Dispose. Memory allocated by the library must be released exclusively through the `mp_pose_free_result` call.

## 5. Error Codes Table

| Code | Constant | Meaning |
|---|---|---|
| `0` | `MP_OK` | Operation completed successfully. |
| `1` | `MP_ERR_ABI_MISMATCH` | Incompatible ABI or structure size. |
| `2` | `MP_ERR_BAD_ARG` | Invalid argument passed (e.g. null pointer, invalid stride). |
| `3` | `MP_ERR_MODEL_LOAD` | Failed to locate or load the model `.task` file. |
| `4` | `MP_ERR_NOT_INITIALIZED` | Detector session has not been initialized. |
| `5` | `MP_ERR_INFERENCE` | MediaPipe internal inference failed. |
| `6` | `MP_ERR_UNSUPPORTED` | Feature or target platform is not supported. |
| `7` | `MP_ERR_OUT_OF_MEMORY` | Memory allocation failure. |
| `8` | `MP_ERR_BACKEND` | Internal MediaPipe backend error. |

## 6. Simulated Backend Behavior (MP_BRIDGE_BACKEND = SIM)
When compiled with the `SIM` backend, the API functions behave as follows:
- `mp_pose_create`: Always succeeds and returns a mock pointer handle (`(void*)0xDEADBEEF`). Does not validate or open the `.task` file.
- `mp_pose_detect_rgb_buffer` / `mp_pose_detect_image_file`: Populate `mp_pose_result` with 1 detected pose containing 33 mock landmarks forming a static circle/skeleton, validating the struct size and pointer propagation.
- `mp_pose_free_result`: Safely deallocates the mock pose result memory from the heap context.

