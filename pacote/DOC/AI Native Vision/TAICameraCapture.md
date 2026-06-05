# TAICameraCapture Documentation

The `TAICameraCapture` component provides cross-platform camera capture capabilities for Lazarus and Free Pascal. It is designed to be 100% native, running windowed preview or headless frame grabbing without any Python or OpenCV dependencies.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAICameraCapture`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `CameraIndex` | `Integer` | `0` | The device index of the camera to connect to. |
| `Width` | `Integer` | `640` | Requested frame width (pixels). |
| `Height` | `Integer` | `480` | Requested frame height (pixels). |
| `FPS` | `Integer` | `30` | Requested frame capture rate. |
| `Backend` | `TAICameraBackend` | `cbAuto` | Underlying API driver (`cbAuto`, `cbWindowsVFW`, `cbLinuxV4L2`, `cbNativeStub`). |
| `PreviewHandle` | `THandle` | `0` | Win32 visual handle (e.g. `Panel.Handle`) to bind direct video preview. |
| `PreviewEnabled` | `Boolean` | `True` | Activates visual preview binding when starting capture. |
| `TempFolder` | `string` | `''` | Custom directory to save frames. If empty, the OS temporary directory is used. |
| `AutoDeleteTempFiles` | `Boolean` | `True` | Automatically deletes prior frames when a new frame is fetched or upon destruction. |
| `CaptureInterval` | `Integer` | `100` | Timer interval (ms) for background polling of camera frames. |
| `MaxCameraScan` | `Integer` | `5` | Maximum device index to check when scanning cameras. |
| `Active` | `Boolean` | `False` | (Read-only) Indicates whether camera stream is running. |
| `LastFrameFile` | `string` | `''` | (Read-only) Path to the last successfully captured BMP frame on disk. |

## Key Methods

- **`function StartCapture: Boolean`**
  Initializes the camera connection, binds the visual preview if enabled, and sets the polling timer. Returns `True` on success.
  
- **`procedure StopCapture`**
  Disconnects from the camera, stops the polling timer, and deletes any residual temporary frame files.

- **`function QueryFrame: Boolean`**
  Triggers a manual single-frame capture to disk. Updates `LastFrameFile` and triggers `OnFrame`. Returns `True` on success.

- **`function CaptureToFile(const AFileName: string): Boolean`**
  Captures the current frame and copies it directly to `AFileName`.

- **`function CaptureToImage(AImage: TImage): Boolean`**
  Captures the current frame and loads it directly into the provided `TImage` component.

- **`function SelfTest: Boolean`**
  Connects, grabs a single frame, validates it exists, disconnects, and reports status. Useful for diagnostic sanity checks.

- **`function ListAvailableCameras: TStringList`**
  Scans devices up to `MaxCameraScan` and returns a list of detected camera indices and descriptions.

## Events

- **`OnFrame: TAIFrameEvent`**
  Triggered every time a new frame file is written:
  `procedure(Sender: TObject; const AFrameFile: string)`

- **`OnError: TAICameraErrorEvent`**
  Triggered when a capture or connection error occurs.

- **`OnStateChange: TAICameraStateEvent`**
  Triggered when the component transitions between active and inactive states.

## Error Handling
In case of method failure (returning `False`), the detail is populated in `LastError` and the state `LastSuccess` becomes `False`. Detailed log traces can be intercepted by subscribing to `OnLog`.

## Example Usage

```pascal
var
  Cam: TAICameraCapture;
begin
  Cam := TAICameraCapture.Create(nil);
  try
    Cam.CameraIndex := 0;
    Cam.PreviewEnabled := False; // Headless capture
    if Cam.StartCapture then
    begin
      Sleep(1000); // Wait for sensor warmth
      if Cam.QueryFrame then
        WriteLn('Frame saved to: ', Cam.LastFrameFile);
      Cam.StopCapture;
    end
    else
      WriteLn('Error starting camera: ', Cam.LastError);
  finally
    Cam.Free;
  end;
end;
```
