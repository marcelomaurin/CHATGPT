# TAIMotionTracker Documentation

The `TAIMotionTracker` component provides native motion detection between successive video frames or bitmap images. It compares pixel luminance values to determine if, and how much, movement has occurred.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIMotionTracker`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Threshold` | `Integer` | `15` | Luminance variation tolerance per pixel (0-255). Differences below this threshold are ignored. |
| `MinMotionPercent` | `Double` | `1.5` | Minimum percentage of pixels that must change to classify the transition as containing motion. |
| `MotionPercent` | `Double` | `0.0` | (Read-only) Percentage of pixels that changed in the last comparison. |
| `LastMotionDetected` | `Boolean` | `False` | (Read-only) True if motion was detected in the last comparison. |
| `LastDifferencePixels` | `Integer` | `0` | (Read-only) Count of pixels that exceeded `Threshold` in the last comparison. |

## Key Methods

- **`function DetectMotion(AFrame1, AFrame2: TBitmap): Boolean`**
  Compares `AFrame1` and `AFrame2`. Calculates pixel variations and returns `True` if `MotionPercent` exceeds `MinMotionPercent`.

- **`function DetectMotionFromFiles(const AFile1, AFile2: string): Boolean`**
  Loads both image files and compares them to check for motion.

## Error Handling
If input bitmaps have mismatched dimensions or are unassigned, the method returns `False`, sets `LastSuccess := False`, and updates `LastError` with detailed information.

## Example Usage

```pascal
var
  Tracker: TAIMotionTracker;
  FrameA, FrameB: TBitmap;
begin
  Tracker := TAIMotionTracker.Create(nil);
  Tracker.Threshold := 20; // Ignore subtle lighting changes
  Tracker.MinMotionPercent := 2.0; // Require at least 2% of the scene to change
  
  FrameA := TBitmap.Create;
  FrameB := TBitmap.Create;
  try
    FrameA.LoadFromFile('t0.bmp');
    FrameB.LoadFromFile('t1.bmp');
    
    if Tracker.DetectMotion(FrameA, FrameB) then
      WriteLn('Motion detected! Volumetric change: ', Tracker.MotionPercent:0:2, '%')
    else
      WriteLn('No significant motion. Volumetric change: ', Tracker.MotionPercent:0:2, '%');
  finally
    FrameA.Free;
    FrameB.Free;
    Tracker.Free;
  end;
end;
```
