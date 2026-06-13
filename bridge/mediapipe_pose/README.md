# Bridge MediaPipe Pose (mp_pose_bridge)

Ponte (bridge) dinâmica de ligação entre o motor de inferência **MediaPipe Pose Landmarker** e o componente Lazarus `TAIHumanPoseDetector`.

## 1. Escopo e Decisões de Design

- **Arquitetura:** Exclusivamente 64-bit (`windows-x86_64` e `linux-x86_64`). Alvos de 32-bit estão fora de escopo.
- **Interface:** Exposta através de uma ABI em C puro para garantir compatibilidade estável com Lazarus/Pascal via carregamento dinâmico.
- **Engine:** Baseada na API oficial C do MediaPipe Tasks.

## 2. Pré-requisitos de Build

Para compilar este projeto, são necessários:
- **CMake** (versão 3.16 ou superior)
- **Bazel** (versão recomendada compatível com o MediaPipe)
- Toolchain C/C++ compatível (MSVC no Windows, GCC no Linux)
- Git com suporte a Git LFS para arquivos de grande porte (modelos e binários compilados).

## 3. Estrutura do Projeto

- `include/`: Definições da ABI pública (`mp_pose_bridge.h`).
- `src/`: Implementação do adaptador C/C++ e versão.
- `build/`: Arquivos de configuração de build (CMakeLists.txt, scripts de exportação).
- `third_party/`: Dependências de terceiros, como o repositório MediaPipe.
- `tests/`: Testes de fumaça e validação.
- `tools/`: Utilitários auxiliares.
