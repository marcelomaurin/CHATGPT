# TAIOpenCV Filter Demo

This sample demonstrates how to use the `TAIOpenCV` component in a Lazarus graphical application.

## Features

- OpenCV SelfTest
- Load image
- Read image information
- Apply basic filters
- Preview original image
- Preview processed image
- Save processed output
- Show logs and errors

## Supported filters

- None
- Gray
- Blur
- Canny
- Threshold
- Resize

## Required backend

The current implementation uses Python Process.

Install dependencies:

```bash
pip install opencv-python numpy
```

## Sample Image

The sample includes a pre-generated `sample.jpg` in its directory for quick testing.

## Worker

The component expects the worker script at:

```text
pacote/python/aiopencv_worker.py
```

Make sure the worker exists in the package's python folder.

## How to run

1. Open `opencv_filter_demo.lpi` in Lazarus.
2. Compile the project.
3. Run the application.
4. Click `SelfTest`.
5. Load an image.
6. Select a filter.
7. Click `Process`.
8. Preview and save the processed image.

## Status

Experimental/Beta.
