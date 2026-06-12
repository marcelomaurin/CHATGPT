# MediaPipe Pose Runtime Binaries

Este diretório contém os manifestos e subpastas para o runtime embarcado do MediaPipe Pose Detector.

## Estrutura de subpastas

- `windows/x86/`: DLLs do MediaPipe Bridge para processos Windows 32 bits (`ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win32.dll`).
- `windows/x64/`: DLLs do MediaPipe Bridge para processos Windows 64 bits (`ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll`).
- `linux/x86/`: Bibliotecas `.so` para Linux 32 bits (`libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux32.so`).
- `linux/x64/`: Bibliotecas `.so` para Linux 64 bits (`libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so`).

## Modelos (.task)

Os arquivos de modelo de pose do MediaPipe devem ser colocados na pasta de modelos da arquitetura correspondente, por exemplo:
- `windows/x86/models/pose_landmarker_full.task`
- `windows/x64/models/pose_landmarker_full.task`

Você pode baixar os modelos pré-treinados do MediaPipe diretamente da documentação oficial do Google MediaPipe.
