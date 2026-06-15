# TAIImageInfo Demo

This demo reads basic image information and metadata from image files natively in Lazarus/FPC.

## Features

- Read image width and height
- Calculate pixel count
- Detect file format by extension
- Read file size
- Read PNG text metadata (tEXt, iTXt, zTXt detection)
- Read JPEG comment, EXIF/XMP/IPTC raw metadata
- Detect possible watermark information in metadata
- Show full diagnostic report

## Supported metadata in this version

| Format | Metadata |
|---|---|
| PNG | tEXt, iTXt, zTXt detection |
| JPEG | APP1 EXIF/XMP, APP13 IPTC, COM comment |

## Important

This component detects watermark information stored in metadata.
It does not detect visual watermarks drawn into image pixels (which belongs to a future `TAIWatermarkDetector` component).

## Requirements

* Lazarus
* Free Pascal
* No Python
* No OpenCV
* No external DLL
