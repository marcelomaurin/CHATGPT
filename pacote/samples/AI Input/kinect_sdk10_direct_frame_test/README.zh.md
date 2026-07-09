# kinect_sdk10_direct_frame_test

控制台测试程序，直接调用 `Kinect10.dll`，不经过可视组件。用于诊断 SDK 1.8 互操作问题。

## 输出

- 日志：`capture_output\kinect_sdk10_direct_frame_test.log`
- 图像：`capture_output\direct_color_frame.bmp`

## 验证内容

- 加载 `Kinect10.dll`。
- `NuiInitialize`。
- `NuiImageStreamOpen`。
- `NuiImageStreamGetNextFrame`。
- `LockRect` 和 `ReleaseFrame`。

## 要求

Windows、Kinect SDK/Runtime 1.8、架构匹配的 DLL，以及已连接的 Kinect。