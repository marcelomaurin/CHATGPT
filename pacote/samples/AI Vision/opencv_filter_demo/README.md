# TAIOpenCV Filter Demo

This demo shows how to use the `TAIOpenCV` component to process images using OpenCV from Lazarus / Free Pascal.

## Features

- Load image file
- Run OpenCV self-test
- Apply basic filters
- Preview original and processed image
- Save processed image
- Show component logs and errors

## Recommended backend

Python Process.

Install dependencies:

```bash
pip install opencv-python numpy
```

## Supported filters

* Gray
* Blur
* Gaussian Blur
* Median Blur
* Canny
* Threshold
* Adaptive Threshold
* Sharpen
* Invert
* Erode
* Dilate
* Resize
* Normalize
* Equalize Histogram

## How to run

1. Open `opencv_filter_demo.lpi` in Lazarus.
2. Compile the project.
3. Run the application.
4. Click `SelfTest`.
5. Load an image.
6. Choose a filter.
7. Click `Process`.

## Status

Experimental/Beta.
