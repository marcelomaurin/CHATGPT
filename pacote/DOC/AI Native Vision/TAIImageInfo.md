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
| `FileExists` | `Boolean` | `False` | True if the loaded file exists on disk. |
| `FileSizeBytes` | `Int64` | `0` | Size of the image file in bytes. |
| `Extension` | `string` | `''` | Lowercase file extension (e.g. `.png`). |
| `FormatName` | `string` | `''` | Image format detected (e.g. `PNG`, `JPEG`, `BMP`, `GIF`, `TIFF`, `WEBP`). |
| `AspectRatio` | `Double` | `0.0` | Proportional width/height ratio. |
| `MegaPixels` | `Double` | `0.0` | Millions of pixels in the image. |
| `Orientation` | `TAIImageOrientation` | `ioUnknown` | Orientation: `ioSquare`, `ioLandscape`, `ioPortrait`. |
| `IsLoaded` | `Boolean` | `False` | True if a source has been successfully loaded. |
| `SourceKind` | `TAIImageInfoSourceKind` | `iskNone` | The kind of loaded source: `iskNone`, `iskFile`, `iskBitmap`, `iskPicture`. |

## Key Methods

- **`procedure ClearInfo`**
  Resets all technical properties to defaults (0, empty string, etc.) and clears any previous error.

- **`function LoadInfoFromFile(const AFileName: string): Boolean`**
  Reads the image file from disk and parses its header metadata.

- **`function LoadInfoFromBitmap(ABitmap: TBitmap): Boolean`**
  Queries the dimensions of the provided `TBitmap` and populates properties.

- **`function LoadInfoFromPicture(APicture: TPicture): Boolean`**
  Queries the dimensions of the provided `TPicture` and populates properties.

- **`function AsText: string`**
  Returns a clean, formatted text report of the image properties.

- **`function AsJSON: string`**
  Returns a valid JSON representation of all properties.

- **`function GetDiagnosticReport: string`**
  Alias for `AsText`.

- **`function OrientationAsString: string`**
  Returns orientation as a string ('Square', 'Landscape', 'Portrait', 'Unknown').

- **`function SourceKindAsString: string`**
  Returns source kind as a string ('File', 'Bitmap', 'Picture', 'None').

## Example Usage

```pascal
var
  Info: TAIImageInfo;
begin
  Info := TAIImageInfo.Create(nil);
  try
    if Info.LoadInfoFromFile('photo.png') then
    begin
      WriteLn('Loaded: ', Info.FileName);
      WriteLn('Dimensions: ', Info.Width, 'x', Info.Height);
      WriteLn('Total Pixels: ', Info.PixelCount);
      WriteLn('MegaPixels: ', Info.MegaPixels:0:2, ' MP');
      WriteLn('Orientation: ', Info.OrientationAsString);
      WriteLn('JSON Report: ', Info.AsJSON);
    end
    else
      WriteLn('Metadata read failed: ', Info.LastError);
  finally
    Info.Free;
  end;
end;
```
