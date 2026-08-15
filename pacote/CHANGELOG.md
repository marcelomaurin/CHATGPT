# CHANGELOG — Lazarus AI Suite

## v1.11.0 (2026-08-15)

### ✨ New
- **`TAIMQTTClient` & Real MQTT v3.1.1 Protocol** (`aimqtt.pas`, package `openai_industrial`):
  - User and password authentication (`Username` and `Password`), connect flags (`0x80`/`0x40`) and `CleanSession`.
  - Full support for `test.mosquitto.org` profiles: port 1883 (unauthenticated), port 1884 (authenticated `rw`/`readwrite`, `ro`/`readonly`, `wo`/`writeonly`), `wildcard` topic discovery, and local brokers (`localhost:1883`).
  - DNS resolution via WinSock2 (`WSAStartup`) and hostname detection (`gethostbyname` / `ResolveHostByName`).
  - Millisecond protocol event logging `[hh:nn:ss.zzz]` for DNS, sockets, `CONNECT`, `CONNACK`, `SUBSCRIBE`, `SUBACK`, `PUBLISH`, `PINGREQ`/`PINGRESP`, and `DISCONNECT`.
- **`mqtt_demo` Sample** (`samples/AI Industrial/mqtt_demo/`):
  - Fully real MQTT communication (all simulations removed).
  - Form integration with `AIMQTTClient1: TAIMQTTClient` in `.lfm` and published in `TfrmMain`.
  - Profile selector for `test.mosquitto.org`, host/credentials inputs, and live JSON telemetry.
- **`model3d_viewer_demo` Sample** (`samples/AI Graphic/model3d_viewer_demo/`):
  - Components `AIModel3D1` and `AI3DModelViewer1` placed directly on the `.lfm` form with real rendering.
- **OpenSSL 1.1.1.10 Runtime Resolution**:
  - `airuntimepaths.pas` and installer configured for `runtime/OpenSSL/1.1.1.10` on Win32/Win64.

### 🔧 Fixes
- **Socket Error Code Preservation**: Immediate capture of `WSAGetLastError` / `SocketError` before `CloseSocket` with `SysErrorMessage` details.
- **Duplicate Log Removal**: Cleaned redundant `Log(llError, ...)` invocations following `SetError`.
- **Search Paths**: Added `AI Vision` search path to `openai_input.lpk` and cleaned `mqtt_demo.lpi` search paths.

## v1.9.0 (2026-06-07)

### ⚡ Breaking Changes

  - All projects using these components must be updated to use `TAICaptureSource`.
  - See migration table below.

### ✨ New

- **`TAICaptureSource`** (`aicapturesource.pas`, package `openai_input`): unified capture source component supporting 5 modes via `SourceKind`:
  - `cskCameraLocal` — local USB/webcam (VFW on Windows, V4L2 on Linux)
  - `cskCameraIPSnapshot` — IP camera HTTP/HTTPS JPEG snapshot (real decoding via `TPicture`)
  - `cskCameraIPRTSP` — RTSP (returns clear error, does not simulate success)
  - `cskScreen` — desktop capture + optional mouse/keyboard tracking
  - `cskFile` — static image file frame
- **`aicapturesource_icon.lrs`** — palette icon for `TAICaptureSource` (sigla `CS`, cor `C_INPUT`)
- **`capture_source_demo`** sample (`samples/AI Input/capture_source_demo/`) demonstrating all 5 modes

### 🗑️ Removed

| File | Reason |
|------|--------|
| `AI Input/aicamera.pas` + icon | Replaced by `TAICaptureSource` |
| `AI Input/aicftvip.pas` + icon | Replaced by `TAICaptureSource` |
| `AI Input/aioscapture.pas` + icon | Replaced by `TAICaptureSource` |
| `AI Vision/aicameracapture.pas` + icon | Replaced by `TAICaptureSource` |
| `samples/AI Vision/camera_capture_linux_demo/` | Replaced by `capture_source_demo` |
| `samples/AI Native Vision/camera_capture_demo/` | Replaced by `capture_source_demo` |
| `samples/AI Input/os_capture_demo/` | Replaced by `capture_source_demo` |

### 🔧 Modified

- **`openai_input.lpk`**: added `aicapturesource.pas` + icon, removed `aicamera`, `aicftvip`, `aioscapture`
- **`openai_vision.lpk`**: removed `aicameracapture`; camera backends (`aicamera_backend`, `aicamera_vfw`, `aicamera_v4l2`) remain as auxiliary units
- **`hardware_net_demo/main.pas`**: migrated `TAICameraInput` → `TAICaptureSource (cskCameraLocal)`, `TAIOSInputCapture` → `TAICaptureSource (cskScreen)`, removed `TAICFTVIP`
- **`COMPONENT_STATUS.md`**: added Input section with `TAICaptureSource`, moved removed components to Legacy
- **`DOC/AI Input/`**: new directory with `README.md` and `TAICaptureSource.md`
- **`README.md`**: updated package descriptions and samples list

### 🔄 Migration Guide

| Old Component | New Code |
|---|---|
| `TAICameraInput` /| `TAICaptureSource` with `SourceKind := cskCameraLocal` |
| `TAICFTVIP` | `TAICaptureSource` with `SourceKind := cskCameraIPSnapshot; IPAddress := ...; SnapshotURL := ...` |
| `TAIOSInputCapture.CaptureScreen(Bmp)` | `TAICaptureSource.CaptureToBitmap(Bmp)` with `SourceKind := cskScreen` |
| `TAIOSInputCapture.TrackMouse` | `TAICaptureSource.TrackMouse` |
| `TAIOSInputCapture.TrackKeyboard` | `TAICaptureSource.TrackKeyboard` (**default changed from True to False**) |

---

## v1.8.x and earlier

*(No CHANGELOG maintained before v1.9.0)*