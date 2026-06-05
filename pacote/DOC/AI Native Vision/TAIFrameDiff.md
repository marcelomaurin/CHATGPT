# TAIFrameDiff Documentation

The `TAIFrameDiff` component generates an absolute pixel-by-pixel difference map between two images, highlighting changed regions. It is a vital building block for motion mask overlays and visual debug graphics.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIFrameDiff`**

## Key Methods

- **`function GenerateDiffBitmap(AFrame1, AFrame2, ADiffFrame: TBitmap): Boolean`**
  Generates an absolute difference map between `AFrame1` and `AFrame2`, writing the output directly to `ADiffFrame`. The resulting pixels represent the absolute difference in luminance: `|L1 - L2|`. Returns `True` on success.

- **`function GenerateDiffFile(const AFile1, AFile2, ADiffFile: string): Boolean`**
  Loads `AFile1` and `AFile2` from disk, calculates the difference, and writes the output file to `ADiffFile`.

## Error Handling
In case input bitmaps are unassigned or have different sizes, the method returns `False` and details the issue inside `LastError`.

## Example Usage

```pascal
var
  DiffGen: TAIFrameDiff;
  Bmp1, Bmp2, BmpResult: TBitmap;
begin
  DiffGen := TAIFrameDiff.Create(nil);
  Bmp1 := TBitmap.Create;
  Bmp2 := TBitmap.Create;
  BmpResult := TBitmap.Create;
  try
    Bmp1.LoadFromFile('t0.bmp');
    Bmp2.LoadFromFile('t1.bmp');
    
    if DiffGen.GenerateDiffBitmap(Bmp1, Bmp2, BmpResult) then
      BmpResult.SaveToFile('difference_mask.bmp')
    else
      WriteLn('Diff generation failed: ', DiffGen.LastError);
  finally
    BmpResult.Free;
    Bmp2.Free;
    Bmp1.Free;
    DiffGen.Free;
  end;
end;
```
