# TAIImageInfo Documentation

The `TAIImageInfo` component provides non-destructive metadata extraction for images in Lazarus. It analyzes files or bitmap headers to fetch resolution details, pixel counts, format characteristics, and embedded text metadata (like EXIF, XMP, IPTC, and PNG text chunks) without keeping heavy graphic data in memory.

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
| `HasMetadata` | `Boolean` | `False` | True if structural metadata is present. |
| `Title`, `Author`, `Artist`, `Creator`, `Copyright`, `Description`, `Comment`, `Software` | `string` | `''` | Extracted and parsed metadata fields. |
| `HasWatermarkInfo` | `Boolean` | `False` | True if watermark or copyright strings are detected in metadata. |
| `WatermarkText` | `string` | `''` | Content of the copyright watermark. |

## Key Methods

- **`procedure ClearInfo`**
  Resets all technical and metadata properties to defaults and clears any previous error.

- **`function LoadInfoFromFile(const AFileName: string): Boolean`**
  Reads the image file from disk and parses its header metadata, including EXIF, XMP, IPTC, and COM chunks.

- **`function LoadInfoFromBitmap(ABitmap: TBitmap): Boolean`**
  Queries the dimensions of the provided `TBitmap` and populates properties.

- **`function LoadInfoFromPicture(APicture: TPicture): Boolean`**
  Queries the dimensions of the provided `TPicture` and populates properties.

- **`function LoadMetadataFromFile(const AFileName: string): Boolean`**
  Parses metadata exclusively from the file.

- **`function AsText: string`**
  Returns a clean, formatted text report of the image properties and metadata.

- **`function AsJSON: string`**
  Returns a valid JSON representation of all properties.

- **`function GetDiagnosticReport: string`**
  Alias for `AsText`.

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
      if Info.HasWatermarkInfo then
        WriteLn('Copyright Notice: ', Info.WatermarkText);
      WriteLn('Full Details: ', Info.AsText);
    end
    else
      WriteLn('Metadata read failed: ', Info.LastError);
  finally
    Info.Free;
  end;
end;
```
