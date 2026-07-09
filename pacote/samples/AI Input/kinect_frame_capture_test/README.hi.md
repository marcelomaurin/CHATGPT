# kinect_frame_capture_test

Console test जो package के Kinect components से sensor खोलता है, पहला color frame capture करता है और उसे disk पर save करता है.

## Output

- Log: `capture_output\kinect_frame_capture_test.log`
- Image: `capture_output\captured_color_frame.bmp`

## कब उपयोग करें

जब graphical demo image न दिखाए या बिना visual interface capture validate करना हो.

## आवश्यकताएं

Windows, Kinect SDK/Runtime 1.8, `Kinect10.dll`, और connected Kinect sensor.