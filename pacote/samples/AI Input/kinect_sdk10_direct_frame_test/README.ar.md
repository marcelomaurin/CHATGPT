# kinect_sdk10_direct_frame_test

اختبار من سطر الأوامر يستدعي `Kinect10.dll` مباشرة بدون المكونات الرسومية. يساعد في تشخيص مشاكل التوافق مع SDK 1.8.

## المخرجات

- السجل: `capture_output\kinect_sdk10_direct_frame_test.log`
- الصورة: `capture_output\direct_color_frame.bmp`

## ما الذي يتحقق منه

- تحميل `Kinect10.dll`.
- `NuiInitialize`.
- `NuiImageStreamOpen`.
- `NuiImageStreamGetNextFrame`.
- `LockRect` و `ReleaseFrame`.

## المتطلبات

Windows و Kinect SDK/Runtime 1.8 و DLL بنفس المعمارية وحساس Kinect متصل.