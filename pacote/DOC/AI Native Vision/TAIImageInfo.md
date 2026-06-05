# TAIImageInfo Documentation

The `TAIImageInfo` component provides non-destructive metadata extraction for images in Lazarus. It analyzes files or bitmap headers to fetch resolution details, pixel counts, and formats without keeping heavy graphic data in memory.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIImageInfo`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Width` | `Integer` | `0` | Width of the analyzed image (pixels). |
| `Height` | `Integer` | `0` | Height of the analyzed image (pixels). |
| `PixelCount` | `Int64` | `0` | Total number of pixels (`Width * Height`). |
| `FileName` | `string` | `''` | Path to the last analyzed image file. |
| `AsText` | `string` | `''` | (Read-only) Summary string containing formatted dimensions and pixel counts. |

## Key Methods

- **`function LoadInfoFromBitmap(ABitmap: TBitmap): Boolean`**
  Queries the dimensions of the provided `TBitmap` and populates the component properties.

- **`function LoadInfoFromFile(const AFileName: string): Boolean`**
  Reads the image file from disk and parses its header metadata.

## Error Handling
Returns `False` on failure (e.g. invalid file format or missing file), setting `LastSuccess := False` and setting the error description inside `LastError`.

## Example Usage

```pascal
var
  Info: TAIImageInfo;
begin
  Info := TAIImageInfo.Create(nil);
  try
    if Info.LoadInfoFromFile('photo.bmp') then
    begin
      WriteLn('Loaded: ', Info.FileName);
      WriteLn('Dimensions: ', Info.Width, 'x', Info.Height);
      WriteLn('Total Pixels: ', Info.PixelCount);
      WriteLn('Stats: ', Info.AsText);
    end
    else
      WriteLn('Metadata read failed: ', Info.LastError);
  finally
    Info.Free;
  end;
end;
```
