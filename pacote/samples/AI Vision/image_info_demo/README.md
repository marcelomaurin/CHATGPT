# TAIImageInfo Demo

This demo shows how to use `TAIImageInfo` to read basic image information natively in Lazarus/FPC.

## Features

- Load image file
- Preview image
- Read width and height
- Count pixels
- Detect format by extension
- Show file size
- Show aspect ratio
- Show orientation
- Generate text report

## Component

Unit:

```pascal
aiimageinfo
```

Main class:

```pascal
TAIImageInfo
```

## Usage

```pascal
if AIImageInfo1.LoadInfoFromFile('sample.png') then
  Memo1.Lines.Text := AIImageInfo1.AsText
else
  Memo1.Lines.Text := AIImageInfo1.LastError;
```

## Requirements

* Lazarus
* Free Pascal
* No Python
* No OpenCV
* No external DLL
