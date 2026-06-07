# TAICaptureSource

**Unit:** `aicapturesource.pas`  
**Package:** `openai_input.lpk`  
**Palette:** `AI Input`  
**Status:** Beta  
**Platforms:** Windows, Linux

## Overview

`TAICaptureSource` is the unified capture component of the Lazarus AI Suite. It consolidates four previously separate components (`TAICameraCapture`, `TAICameraInput`, `TAICFTVIP`, `TAIOSInputCapture`) into a single component with a clear backend architecture.

The active capture mode is selected via the `SourceKind` property.

## Class Hierarchy

```
TObject
  TPersistent
    TComponent
      TAIBaseComponent
        TAICaptureSource
```

## Source Kind Enum

```pascal
TAICaptureSourceKind = (
  cskCameraLocal,        // USB/webcam via native OS backend (VFW/V4L2)
  cskCameraIPSnapshot,   // IP camera HTTP/HTTPS JPEG snapshot
  cskCameraIPRTSP,       // IP camera RTSP (not yet implemented)
  cskScreen,             // Desktop / screen capture
  cskFile,               // Load frame from image file
  cskNone                // No source configured
);
```

## Properties

### Core

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `SourceKind` | `TAICaptureSourceKind` | `cskCameraLocal` | Selects the active capture backend |
| `Active` | `Boolean` | `False` | Read-only; True when capture is running |
| `Width` | `Integer` | `640` | Desired frame width (camera modes) |
| `Height` | `Integer` | `480` | Desired frame height (camera modes) |
| `FPS` | `Integer` | `30` | Target frames per second |
| `CaptureInterval` | `Integer` | `100` | Timer interval in ms (used when FPS = 0) |
| `AutoStart` | `Boolean` | `False` | Start capture automatically at design time |
| `TempFolder` | `string` | `''` | Temp folder for frame files (empty = system temp) |
| `AutoDeleteTempFiles` | `Boolean` | `True` | Auto-delete previous frame temp files |
| `LastFrameFile` | `string` | — | Path of the last captured frame file (read-only) |

### Local Camera (`cskCameraLocal`)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `CameraIndex` | `Integer` | `0` | Camera device index |
| `DeviceName` | `string` | `''` | Optional device name (Windows: overrides index if set) |
| `Backend` | `TAICameraBackend` | `cbAuto` | Native backend selection |
| `PreviewHandle` | `THandle` | `0` | Window handle for native preview |
| `PreviewEnabled` | `Boolean` | `True` | Enable native preview window |
| `MaxCameraScan` | `Integer` | `5` | Max devices to scan in `ListAvailableCameras` |

### IP Camera (`cskCameraIPSnapshot`)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `IPAddress` | `string` | `'192.168.1.50'` | Camera IP address |
| `Port` | `Integer` | `80` | HTTP port |
| `SnapshotURL` | `string` | `'/cgi-bin/snapshot.jpg'` | URL path for snapshot endpoint |
| `StreamURL` | `string` | `''` | RTSP stream URL (reserved for future use) |
| `Username` | `string` | `'admin'` | HTTP Basic Auth username |
| `Password` | `string` | `'admin'` | HTTP Basic Auth password |
| `UseHTTPS` | `Boolean` | `False` | Use HTTPS instead of HTTP |
| `TimeoutMs` | `Integer` | `5000` | HTTP connection/IO timeout in ms |

### Screen Capture (`cskScreen`)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `CaptureMonitorIndex` | `Integer` | `0` | Target monitor (reserved; currently captures primary) |
| `CaptureFullScreen` | `Boolean` | `True` | Capture full screen (False = use `CaptureRect`) |
| `CaptureRect` | `TRect` | `(0,0,0,0)` | Region to capture when `CaptureFullScreen = False` |
| `TrackMouse` | `Boolean` | `True` | Fire `OnMouseMove` on cursor position changes |
| `TrackKeyboard` | `Boolean` | `False` | Fire `OnKeyIntercepted` on global key events (security: off by default) |
| `PollingInterval` | `Integer` | `50` | Mouse/keyboard polling interval in ms |

### File Frame (`cskFile`)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `InputFile` | `string` | `''` | Path to source image file (BMP, JPEG, PNG) |

## Events

| Event | Signature | Description |
|-------|-----------|-------------|
| `OnFrame` | `(Sender; AFrameFile: string)` | Fired after each successful frame capture |
| `OnError` | `(Sender; AError: string)` | Fired on any capture error |
| `OnStateChange` | `(Sender; AActive: Boolean)` | Fired when capture starts or stops |
| `OnMouseMove` | `(Sender; X, Y: Integer)` | Fired when cursor moves (screen mode only) |
| `OnKeyIntercepted` | `(Sender; KeyCode: Word; KeyChar: Char)` | Fired on global key press (screen mode only) |

## Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `StartCapture` | `Boolean` | Starts the capture timer and backend |
| `StopCapture` | — | Stops the timer and frees the backend |
| `QueryFrame` | `Boolean` | Manually triggers a single frame capture |
| `CaptureToFile(AFileName)` | `Boolean` | Captures current frame directly to a file |
| `CaptureToBitmap(out ABmp)` | `Boolean` | Captures into a new `TBitmap` (caller frees) |
| `CaptureToImage(AImage)` | `Boolean` | Captures into a `TImage` control |
| `SelfTest` | `Boolean` | Tests the configured source without starting the timer |
| `ListAvailableSources` | `TStringList` | Returns all supported `TAICaptureSourceKind` values |
| `ListAvailableCameras` | `TStringList` | Enumerates available local cameras (creates backend temporarily) |

## Example — Local Camera

```pascal
uses aicapturesource;

procedure TForm1.FormCreate(Sender: TObject);
begin
  CaptureSource1.SourceKind  := cskCameraLocal;
  CaptureSource1.CameraIndex := 0;
  CaptureSource1.Width       := 640;
  CaptureSource1.Height      := 480;
  CaptureSource1.FPS         := 15;
  CaptureSource1.OnFrame     := @OnFrame;
  CaptureSource1.OnError     := @OnError;
  CaptureSource1.StartCapture;
end;

procedure TForm1.OnFrame(Sender: TObject; const AFrameFile: string);
var
  Bmp: TBitmap;
begin
  if CaptureSource1.CaptureToBitmap(Bmp) then
  try
    Image1.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;
```

## Example — IP Snapshot

```pascal
CaptureSource1.SourceKind  := cskCameraIPSnapshot;
CaptureSource1.IPAddress   := '192.168.1.100';
CaptureSource1.Port        := 80;
CaptureSource1.SnapshotURL := '/snapshot.jpg';
CaptureSource1.Username    := 'admin';
CaptureSource1.Password    := 'admin';
CaptureSource1.FPS         := 2;  // 2 snapshots per second
CaptureSource1.StartCapture;
```

## Example — Screen Capture with Mouse Tracking

```pascal
CaptureSource1.SourceKind      := cskScreen;
CaptureSource1.CaptureFullScreen := True;
CaptureSource1.TrackMouse      := True;
CaptureSource1.TrackKeyboard   := False; // security: off by default
CaptureSource1.OnMouseMove     := @OnMouseMove;
CaptureSource1.CaptureInterval := 500; // capture every 500ms
CaptureSource1.StartCapture;
```

## Migration Guide

| Old Component | New Property Mapping |
|---|---|
| `TAICameraCapture` / `TAICameraInput` | `SourceKind := cskCameraLocal` |
| `TAICFTVIP` | `SourceKind := cskCameraIPSnapshot; IPAddress := ...; SnapshotURL := ...` |
| `TAIOSInputCapture.CaptureScreen` | `SourceKind := cskScreen; CaptureToBitmap(Bmp)` |
| `TAIOSInputCapture.TrackKeyboard` | `TrackKeyboard := True` (⚠️ default is now **False**) |

## Notes

- `cskCameraIPRTSP` is **not implemented**. `StartCapture` will return `False` with a descriptive error — it does not simulate success.
- `CaptureToBitmap` returns a freshly allocated `TBitmap`. The caller is responsible for freeing it.
- Image decoding for HTTP snapshots uses `TPicture.LoadFromStream` with automatic format detection (JPEG, PNG, BMP).
- Camera backends (`aicamera_vfw.pas`, `aicamera_v4l2.pas`) are compiled-in via `{$IFDEF}` and require `openai_vision.lpk` at build time.
