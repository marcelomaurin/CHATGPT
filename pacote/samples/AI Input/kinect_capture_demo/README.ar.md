# kinect_capture_demo

عرض رسومي لاختبار التقاط الفيديو الملون من Kinect باستخدام `TAIKinectSensor` و `TAIKinectColorStream`، وبشكل اختياري `TAIKinectDepthStream`.

## الهدف

يفتح هذا العرض حساس Kinect، ويبدأ تدفق الصورة الملونة، ويعرض الإطارات على الشاشة، ويسجل الأحداث في تبويب **Log**. خيار **Depth** يشغل أيضا تدفق العمق.

## المتطلبات

- Windows.
- تثبيت Kinect for Windows SDK/Runtime 1.8.
- توفر `Kinect10.dll` في النظام.
- بناء التطبيق بنفس معمارية ملف DLL المثبت.
- توصيل حساس Kinect وأن لا يكون مستخدما من برنامج آخر.

## طريقة الاستخدام

1. شغل `kinect_capture_demo.exe`.
2. اترك `Device` على `0` عند استخدام backend SDK10.
3. فعل **Depth** فقط إذا أردت اختبار العمق.
4. اضغط **Conectar**.
5. شاهد الصورة في تبويب **Video**.
6. راجع الرسائل في تبويب **Log**.
7. اضغط **Desconectar** قبل الإغلاق.

## السجلات

يعرض البرنامج الأحداث في `memLog` ويقرأ سجل backend الداخلي:

`%TEMP%\aikinect_sdk10_backend.log`

يتضمن السجل تهيئة SDK وفتح التدفق والتقاط الإطارات و `LockRect` و `ReleaseFrame` و `NuiShutdown`.

## حل المشاكل

- إذا لم تظهر الصورة، راجع تبويب **Log**.
- إذا فشل `NuiInitialize`، تأكد أن Kinect غير مستخدم من برنامج آخر.
- إذا كان `Kinect10.dll` مفقودا، أعد تثبيت Runtime/SDK 1.8.
- لاختبار الكاميرا الملونة فقط، اترك **Depth** غير مفعل.