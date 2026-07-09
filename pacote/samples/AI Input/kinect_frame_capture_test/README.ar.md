# kinect_frame_capture_test

اختبار يعمل من سطر الأوامر ويستخدم مكونات Kinect في الحزمة لفتح الحساس والتقاط أول إطار ملون وحفظه على القرص.

## المخرجات

- السجل: `capture_output\kinect_frame_capture_test.log`
- الصورة: `capture_output\captured_color_frame.bmp`

## متى يستخدم

استخدم هذا الاختبار إذا لم يعرض demo الرسومي صورة أو إذا أردت اختبار الالتقاط بدون واجهة رسومية.

## المتطلبات

Windows و Kinect SDK/Runtime 1.8 و `Kinect10.dll` وحساس Kinect متصل.