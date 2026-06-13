# AI MediaPipe Vision — Pose Detector Demo

This sample application demonstrates the integration of the `TAIHumanPoseDetector` component with the `SIM` bridge backend to perform mock body pose tracking on bitmaps.

## How to Run the Demo

1. Compile the `mp_pose_bridge` in `SIM` mode.
2. Place the compiled binary (`mp_pose_bridge.dll` or `libmp_pose_bridge.so`) in the automatic search path:
   `runtime/mediapipe/pose/mp_0_10_35/<os>-x86_64/`
3. Compile and launch the demo `human_pose_detector_demo` in Lazarus (target CPU `x86_64`).
4. In the app:
   - Go to the **Setup** tab and click **Carregar / Re-inicializar** to load the library.
   - Go to the **Detecção** tab, click **Carregar Imagem** to choose a picture.
   - Click **Detectar** to see 33 simulated landmarks drawn as a green skeleton overlay on the TPaintBox.
