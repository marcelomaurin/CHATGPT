# kinect_capture_demo

用于验证 Kinect 彩色视频采集的图形演示程序，使用 `TAIKinectSensor`、`TAIKinectColorStream`，也可选择使用 `TAIKinectDepthStream`。

## 目的

该演示会打开 Kinect 传感器，启动彩色流，在界面中显示图像帧，并在 **Log** 页签记录事件。**Depth** 选项会额外启用深度流。

## 要求

- Windows。
- 已安装 Kinect for Windows SDK/Runtime 1.8。
- 系统中可用 `Kinect10.dll`。
- 应用程序架构必须与 DLL 架构一致。
- Kinect 已连接，并且没有被其他程序占用。

## 使用方法

1. 运行 `kinect_capture_demo.exe`。
2. SDK10 backend 使用 `Device = 0`。
3. 只有在需要测试深度时才勾选 **Depth**。
4. 点击 **Conectar**。
5. 在 **Video** 页签查看图像。
6. 在 **Log** 页签查看消息。
7. 关闭前点击 **Desconectar**。

## 日志

演示会写入 `memLog`，并读取 backend 内部日志：

`%TEMP%\aikinect_sdk10_backend.log`

日志包含 SDK 初始化、打开流、采集帧、`LockRect`、`ReleaseFrame` 和 `NuiShutdown`。

## 故障排查

- 如果没有图像，请查看 **Log**。
- 如果 `NuiInitialize` 失败，请确认没有其他程序占用 Kinect。
- 如果缺少 `Kinect10.dll`，请重新安装 Runtime/SDK 1.8。
- 只测试彩色相机时，请不要勾选 **Depth**。