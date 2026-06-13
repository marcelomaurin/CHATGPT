# Backend API Selection and Decision (Task A0)

This document registers the gating design decisions and evaluation of the dynamic wrapper backend for the MediaPipe Pose Bridge.

> [!IMPORTANT]
> **GATE A0 (Gate de Bloqueio)**: Este documento é o Gate de Entrada para qualquer trabalho de integração do backend REAL (MediaPipe Tasks C API / Bazel / linkage real). Nenhum desenvolvimento, link, ou importação de dependências reais do SDK MediaPipe deve ser iniciado antes da aprovação explícita e assinatura deste gate (A0). Até lá, apenas o backend SIM (Simulado) é compilado e testado.

## 1. Selected API & Justification

- **Primary Choice:** **Tasks C API** (`mediapipe/tasks/c/vision/pose_landmarker/pose_landmarker_c_api.h`).
- **Justification:** High compatibility with dynamic linking ABI rules, clean C structs, and lightweight footprint.
- **Fallback Plan (Plan B):** **Tasks C++ API** (`PoseLandmarker`) wrapped manually inside the bridge. If the C API exhibits instability or build issues on desktop `x86_64` environments, the bridge implementation (`mp_pose_bridge.cpp`) will wrap the C++ API internally while keeping the external C ABI signatures unchanged.

## 2. Version and Model Pins

- **MediaPipe Version:** Pinned to **0.10.35**.
- **Model Task Files:**
  - `pose_landmarker_lite.task` (Fastest, lower accuracy).
  - `pose_landmarker_full.task` (Balanced, recommended default).
  - `pose_landmarker_heavy.task` (Highest accuracy, heavier resource usage).

## 3. Upstream Memory Ownership Semantics

- **Allocation:** The MediaPipe Tasks C API allocates result structure buffers (such as the landmark coordinates array and segmentation mask buffers).
- **Deallocation:** The C ABI dynamically frees resources. In the bridge wrapper, the deallocation is wrapped by `mp_pose_free_result(mp_pose_result** result)`.
- **Double Pointer Nullification:** The bridge nullifies the client's result pointer reference upon free, protecting against dangling/stale pointers. Chamar a liberação com `*result == NULL` é seguro.

## 4. Running the PoC (Proof of Concept) on Linux x86_64

To compile and execute the proof of concept under Linux:
```bash
# Configure Bazel repository dependencies
cd bridge/mediapipe_pose
bazel build :libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so --define MP_BRIDGE_BACKEND=REAL

# Run smoke test linking to the generated PoC
cd tests
gcc smoke_test.c -I../include -ldl -o smoke_test
./smoke_test
```
