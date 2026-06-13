# AI MediaPipe Vision - Pose Detector Demo

This sample application demonstrates the `TAIHumanPoseDetector` component with the SIM bridge backend. It logs the loaded DLL, the bridge version, the MediaPipe version, and the backend (`SIM` or `REAL`) so the user does not confuse "DLL loaded" with "real image recognition".

## How to Run the Demo

1. Build the bridge in `SIM` mode.
2. Place the official binary in the runtime search path:
   - Windows: `runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll`
   - Linux: `runtime/mediapipe/pose/mp_0_10_35/linux-x86_64/libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so`
3. Compile and launch `human_pose_detector_demo` in Lazarus for `x86_64`.
4. In the app:
   - Open the **Setup** tab and click **Carregar / Re-inicializar** to load the library.
   - Open the **Detecao** tab, click **Carregar Imagem** to choose a picture.
   - Click **Detectar** to initialize the detector if needed and run inference.

## Backend Notes

- `SIM` backend: generates deterministic mock landmarks. It does not recognize the real image.
- `REAL` backend: requires `models/pose_landmarker_full.task` in the same runtime tree as the loaded DLL and is the only path that should be treated as real pose recognition.
- The demo log now prints `Backend`, `Bridge version`, `MediaPipe version`, `Landmarks` and `Tempo` so the user can tell the difference between "DLL loaded" and "real inference".

## Legacy Compatibility

Older local builds may still contain `mp_pose_bridge.dll` or `libmp_pose_bridge.so`, but those names are compatibility fallbacks only. The official runtime filenames are versioned.
