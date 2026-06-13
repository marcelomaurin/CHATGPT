# MediaPipe Pose Runtime Binaries

Este diretório contém o manifesto de carregamento e as subpastas para o runtime do **MediaPipe Pose Detector**.

> [!IMPORTANT]
> **Suporte Exclusivo a 64-bit:** Este componente suporta apenas arquiteturas 64-bit (`windows-x86_64` e `linux-x86_64`). O suporte a 32-bit foi descontinuado e não está mais disponível.

## Estrutura de subpastas

- `windows/x64/`: DLL da bridge para processos Windows 64-bit (`ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll`).
- `linux/x64/`: Biblioteca `.so` da bridge para Linux 64-bit (`libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so`).

## Modelos (.task)

Os arquivos de modelo de pose do MediaPipe devem ser colocados na pasta de modelos (`models/`) correspondente no diretório de runtime da arquitetura, por exemplo:
- `windows/x64/models/pose_landmarker_full.task`
- `linux/x64/models/pose_landmarker_full.task`

Os modelos disponíveis são:
- `pose_landmarker_lite.task` (Mais rápido, menor precisão)
- `pose_landmarker_full.task` (Equilibrado, recomendado por padrão)
- `pose_landmarker_heavy.task` (Maior precisão, maior uso de CPU/recursos)

Você pode baixar os modelos pré-treinados do MediaPipe diretamente da documentação oficial do Google MediaPipe.
