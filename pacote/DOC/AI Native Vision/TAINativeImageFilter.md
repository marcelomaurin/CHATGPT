# TAINativeImageFilter Documentation

The `TAINativeImageFilter` component provides pure, fast, 100% native pixel manipulation routines for `TBitmap` objects and files in Lazarus, without requiring any third-party dependencies like OpenCV.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAINativeImageFilter`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `FilterType` | `TAINativeFilterType` | `niftGray` | Selected filter routine: `niftGray`, `niftThreshold`, `niftInvert`, `niftResize`, `niftBlurBox`. |
| `ThresholdValue` | `Byte` | `128` | Threshold luminance level (0-255) for binarization (`niftThreshold`). |
| `ResizeWidth` | `Integer` | `320` | Target width for the resize filter (`niftResize`). |
| `ResizeHeight` | `Integer` | `240` | Target height for the resize filter (`niftResize`). |

## Key Methods

- **`function ApplyToBitmap(ABitmap: TBitmap): Boolean`**
  Applies the configured `FilterType` filter directly to the provided `TBitmap` in-place. Returns `True` on success.

- **`function ApplyFile(const AInputFile, AOutputFile: string): Boolean`**
  Loads a BMP/image file from `AInputFile`, applies the configured filter, and writes the resulting bitmap to `AOutputFile`.

- **`function ConvertToGray(ABitmap: TBitmap): Boolean`**
  Helper method to convert a bitmap to Grayscale using standard NTSC/BT.601 luminance weights: `Y = 0.299*R + 0.587*G + 0.114*B`.

- **`function ApplyThreshold(ABitmap: TBitmap; AThreshold: Byte): Boolean`**
  Helper method to apply binary thresholding. Pixels with luminance below `AThreshold` become black, and those above or equal become white.

- **`function InvertColors(ABitmap: TBitmap): Boolean`**
  Inverts the color channels of the bitmap (`R = 255 - R`, `G = 255 - G`, `B = 255 - B`).

- **`function ResizeBitmap(ABitmap: TBitmap; AWidth, AHeight: Integer): Boolean`**
  Rescales the bitmap to the specified width and height using fast linear pixel sampling.

- **`function BlurBox(ABitmap: TBitmap): Boolean`**
  Applies a fast 3x3 local average box filter to soften the image and reduce high-frequency noise.

## Error Handling
Returns `False` on failure, setting `LastError` to the error description and `LastSuccess` to `False`.

## Example Usage

```pascal
var
  Filter: TAINativeImageFilter;
  Bmp: TBitmap;
begin
  Filter := TAINativeImageFilter.Create(nil);
  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromFile('input.bmp');
    
    // Configure threshold filter
    Filter.FilterType := niftThreshold;
    Filter.ThresholdValue := 120;
    
    if Filter.ApplyToBitmap(Bmp) then
      Bmp.SaveToFile('output_binary.bmp')
    else
      WriteLn('Filter failed: ', Filter.LastError);
  finally
    Bmp.Free;
    Filter.Free;
  end;
end;
```
