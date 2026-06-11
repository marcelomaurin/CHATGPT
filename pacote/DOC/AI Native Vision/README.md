# AI Native Vision Layer

This directory documents the **AI Native Vision** components in the Lazarus AI Suite. These components compile and run using 100% pure Lazarus/Free Pascal LCL code (with Windows VFW API bindings for webcam capture guarded via `{$IFDEF MSWINDOWS}`). 

Unlike the components under **AI Python Vision**, these components **do not require Python, OpenCV, or external DLLs** to perform vision tasks.

## Table of Components

| Component | Class | Purpose | Key Properties/Methods |
|---|---|---|---|
| **Native Image Filter** | `TAINativeImageFilter` | Grayscale, Threshold, Inverted, Resize, and Box Blur | `FilterType`, `ThresholdValue`, `ApplyToBitmap`, `ApplyFile` |
| **Image Info** | `TAIImageInfo` | Extracts image dimensions & details | `LoadInfoFromBitmap`, `LoadInfoFromFile`, `Width`, `Height`, `PixelCount` |
| **Frame Buffer** | `TAIFrameBuffer` | Circular frame queue for video processing | `MaxFrames`, `AddFrame`, `GetLastFrame`, `GetPreviousFrame`, `Clear` |
| **Motion Tracker** | `TAIMotionTracker` | Luminance variation movement detection | `Threshold`, `MinMotionPercent`, `DetectMotion`, `MotionPercent` |
| **Frame Difference** | `TAIFrameDiff` | Generates a pixel absolute difference map | `GenerateDiffBitmap`, `GenerateDiffFile` |
| **Face Tracker** | `TAIFaceTracker` | Fast SAD template matching local tracker | `SearchRadius`, `MatchThreshold`, `SetTemplateFromBitmap`, `TrackInBitmap` |

---

## Code Examples

### 1. Processing Images with TAINativeImageFilter

```pascal
var
  Filter: TAINativeImageFilter;
  Bmp: TBitmap;
begin
  Filter := TAINativeImageFilter.Create(nil);
  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromFile('input.bmp');
    
    // Convert to grayscale
    Filter.FilterType := niftGray;
    Filter.ApplyToBitmap(Bmp);
    
    // Save output
    Bmp.SaveToFile('output_gray.bmp');
  finally
    Bmp.Free;
    Filter.Free;
  end;
end;
```

### 2. Basic Motion Tracking with TAIMotionTracker

```pascal
var
  Tracker: TAIMotionTracker;
  BmpA, BmpB: TBitmap;
begin
  Tracker := TAIMotionTracker.Create(nil);
  Tracker.Threshold := 15; // sensitivity
  Tracker.MinMotionPercent := 1.5; // threshold
  
  BmpA := TBitmap.Create;
  BmpB := TBitmap.Create;
  try
    BmpA.LoadFromFile('frame1.bmp');
    BmpB.LoadFromFile('frame2.bmp');
    
    if Tracker.DetectMotion(BmpA, BmpB) then
    begin
      WriteLn('Motion Detected! Change: ', Tracker.MotionPercent:0:2, '%');
    end;
  finally
    BmpA.Free;
    BmpB.Free;
    Tracker.Free;
  end;
end;
```

### 3. Tracking an Object with TAIFaceTracker (SAD Template Matching)

```pascal
var
  Tracker: TAIFaceTracker;
  BmpFrame: TBitmap;
  X, Y: Integer;
begin
  Tracker := TAIFaceTracker.Create(nil);
  Tracker.SearchRadius := 30;
  Tracker.MatchThreshold := 50.0;
  
  BmpFrame := TBitmap.Create;
  try
    BmpFrame.LoadFromFile('frame_initial.bmp');
    // Set what we want to track (e.g. at center 50, 50, size 30x30)
    Tracker.SetTemplateFromBitmap(BmpFrame, 50, 50, 30, 30);
    
    // Load next frame
    BmpFrame.LoadFromFile('frame_next.bmp');
    X := Tracker.LastX;
    Y := Tracker.LastY;
    
    if Tracker.TrackInBitmap(BmpFrame, X, Y) then
    begin
      WriteLn('Object moved to X: ', X, ' Y: ', Y);
    end
    else
    begin
      WriteLn('Lost track: ', Tracker.LastError);
    end;
  finally
    BmpFrame.Free;
    Tracker.Free;
  end;
end;
```