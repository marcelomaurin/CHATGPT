# CHANGELOG — Lazarus AI Suite

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
- **`capture_source_demo`** sample (`samples/IA Input/capture_source_demo/`) demonstrating all 5 modes

### 🗑️ Removed

| File | Reason |
|------|--------|
| `IA Input/aicamera.pas` + icon | Replaced by `TAICaptureSource` |
| `IA Input/aicftvip.pas` + icon | Replaced by `TAICaptureSource` |
| `IA Input/aioscapture.pas` + icon | Replaced by `TAICaptureSource` |
| `AI Vision/aicameracapture.pas` + icon | Replaced by `TAICaptureSource` |
| `samples/AI Vision/camera_capture_linux_demo/` | Replaced by `capture_source_demo` |
| `samples/AI Native Vision/camera_capture_demo/` | Replaced by `capture_source_demo` |
| `samples/IA Input/os_capture_demo/` | Replaced by `capture_source_demo` |

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