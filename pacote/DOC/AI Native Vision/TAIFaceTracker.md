# TAIFaceTracker Documentation

The `TAIFaceTracker` component provides local object and face tracking routines using a fast SAD (Sum of Absolute Differences) template matching algorithm. It works 100% natively without external dependencies, Python processes, or model loading overhead.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIFaceTracker`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `SearchRadius` | `Integer` | `30` | Maximum pixel distance to search in all directions around the last known coordinates. |
| `MatchThreshold` | `Double` | `50.0` | Maximum allowable template match divergence (SAD score). |
| `LastX` | `Integer` | `0` | (Read-only) Last known X coordinate of the tracked template. |
| `LastY` | `Integer` | `0` | (Read-only) Last known Y coordinate of the tracked template. |
| `TemplateWidth` | `Integer` | `0` | (Read-only) Width of the stored tracking template. |
| `TemplateHeight` | `Integer` | `0` | (Read-only) Height of the stored tracking template. |

## Key Methods

- **`function SetTemplateFromBitmap(ABitmap: TBitmap; AX, AY, AWidth, AHeight: Integer): Boolean`**
  Caches the specified sub-region of `ABitmap` as the tracking template. Sets `LastX` and `LastY` to the center of the template. Returns `True` on success.

- **`function TrackInBitmap(ABitmap: TBitmap; var AX, AY: Integer): Boolean`**
  Searches for the tracking template within the `SearchRadius` area surrounding the coordinates `AX, AY`. Updates `AX, AY` to the best matching position. Returns `True` if a match is successfully found below `MatchThreshold`.

- **`procedure ClearTemplate`**
  Frees the cached tracking template, resetting `TemplateWidth` and `TemplateHeight` to `0`.

## Error Handling
If input bitmaps are unassigned, or if the template search fails to find a location under `MatchThreshold`, the method returns `False`, sets `LastSuccess := False`, and updates `LastError`.

## Example Usage

```pascal
var
  Tracker: TAIFaceTracker;
  Frame: TBitmap;
  X, Y: Integer;
begin
  Tracker := TAIFaceTracker.Create(nil);
  Tracker.SearchRadius := 40;
  Tracker.MatchThreshold := 45.0; // divergence tolerance
  
  Frame := TBitmap.Create;
  try
    Frame.LoadFromFile('scene_t0.bmp');
    // Lock on an object at X=100 Y=150 (size 30x30)
    Tracker.SetTemplateFromBitmap(Frame, 100, 150, 30, 30);
    
    // Load next frame in stream
    Frame.LoadFromFile('scene_t1.bmp');
    X := Tracker.LastX;
    Y := Tracker.LastY;
    
    if Tracker.TrackInBitmap(Frame, X, Y) then
      WriteLn('Target successfully tracked to position X: ', X, ' Y: ', Y)
    else
      WriteLn('Target lost: ', Tracker.LastError);
  finally
    Frame.Free;
    Tracker.Free;
  end;
end;
```
