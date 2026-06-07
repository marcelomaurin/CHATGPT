# capture_source_demo

Sample demonstrating **TAICaptureSource** — the unified capture component of the Lazarus AI Suite.

## What It Shows

| Tab | Mode | Description |
|-----|------|-------------|
| Local Camera | `cskCameraLocal` | Captures frames from a USB/webcam via native OS backend (VFW on Windows, V4L2 on Linux) |
| IP Snapshot | `cskCameraIPSnapshot` | Fetches JPEG/PNG snapshots from an IP camera via HTTP/HTTPS GET |
| Screen Capture | `cskScreen` | Captures the desktop; optionally tracks mouse moves and global key presses |
| File Frame | `cskFile` | Loads a static image file (BMP, JPEG, PNG) as a single frame |
| RTSP (N/A) | `cskCameraIPRTSP` | Shows the "not yet implemented" error — does NOT simulate success |

## Shared Controls (All Tabs)

- **Start / Stop** — starts/stops the capture timer for the selected mode
- **Capture Frame** — captures a single frame on demand and displays it
- **Save Frame** — saves the current frame to a BMP file via Save dialog
- **Self Test** — tests the configured source without starting the continuous timer
- **List Sources** — logs all supported `TAICaptureSourceKind` values

## Build

```bash
# Windows
C:\lazarus\lazbuild.exe capture_source_demo.lpi

# Linux
lazbuild capture_source_demo.lpi
```

Requires: `openai_input.lpk`, `openai_vision.lpk` (for camera backends).

## Dependencies

- `TAICaptureSource` — `aicapturesource.pas` (openai_input package)
- Camera backends: `aicamera_vfw.pas` / `aicamera_v4l2.pas` (openai_vision package)
