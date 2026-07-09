# kinect_capture_demo

Kinect की color video capture को जांचने के लिए graphical demo. यह `TAIKinectSensor`, `TAIKinectColorStream` और वैकल्पिक रूप से `TAIKinectDepthStream` का उपयोग करता है.

## उद्देश्य

यह demo Kinect sensor खोलता है, color stream शुरू करता है, frames स्क्रीन पर दिखाता है और events को **Log** tab में लिखता है. **Depth** विकल्प depth stream भी चालू करता है.

## आवश्यकताएं

- Windows.
- Kinect for Windows SDK/Runtime 1.8 installed.
- सिस्टम में `Kinect10.dll` उपलब्ध हो.
- Application की architecture installed DLL से मिलनी चाहिए.
- Kinect sensor connected हो और किसी दूसरे program द्वारा use न हो रहा हो.

## उपयोग

1. `kinect_capture_demo.exe` चलाएं.
2. SDK10 backend के लिए `Device` को `0` रखें.
3. Depth test करना हो तभी **Depth** चुनें.
4. **Conectar** क्लिक करें.
5. Image **Video** tab में देखें.
6. Messages **Log** tab में देखें.
7. बंद करने से पहले **Desconectar** क्लिक करें.

## Logs

Demo events को `memLog` में दिखाता है और backend log भी पढ़ता है:

`%TEMP%\aikinect_sdk10_backend.log`

इसमें SDK initialization, stream open, frame capture, `LockRect`, `ReleaseFrame` और `NuiShutdown` शामिल हैं.

## समस्या समाधान

- Image न दिखे तो **Log** देखें.
- `NuiInitialize` fail हो तो जांचें कि Kinect किसी और program में busy तो नहीं है.
- `Kinect10.dll` missing हो तो Runtime/SDK 1.8 reinstall करें.
- केवल color camera test करने के लिए **Depth** unchecked रखें.