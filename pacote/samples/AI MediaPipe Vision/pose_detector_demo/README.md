# Pose Detector Demo — TAIHumanPoseDetector

Demo GUI que demonstra o componente `TAIHumanPoseDetector` com a bridge SIM (e opcionalmente REAL).

## Pré-requisitos

- Lazarus compilado como **64-bit (x86_64)**. O componente não funciona em 32-bit.
- A DLL da bridge compilada (veja "Compilar a bridge" abaixo).

## Como rodar

1. Compile a bridge SIM:
   ```bash
   cd bridge/mediapipe_pose
   mkdir build && cd build
   cmake ..        # MP_BRIDGE_BACKEND=SIM por padrão
   cmake --build . --config Release
   ```
   Coloque a DLL gerada ao lado do executável do demo ou no diretório de runtime:
   ```
   runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/
     ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
   ```

2. Abra `human_pose_detector_demo.lpi` no Lazarus e compile para **x86_64**.

3. Execute o demo:
   - Aba **Setup / Runtime** → campo "Biblioteca Bridge" → **Procurar DLL/SO...** → selecione a DLL.
   - Clique **Carregar / Re-inicializar**.
   - Confira o label **Backend**: deve mostrar `SIM` ou `REAL`.
   - Aba **Detecção** → **Carregar Imagem** → escolha uma das 10 imagens em `images/`.
   - Clique **Detectar Pose**.

## Imagens de exemplo

A pasta `images/` contém 10 imagens de teste pré-carregadas:

| Arquivo | Conteúdo |
|---|---|
| pose_1_full_body_standing | Corpo inteiro, em pé |
| pose_2_walking_side_view | Caminhada, vista lateral |
| pose_3_sitting_chair | Sentado na cadeira |
| pose_4_running_front_view | Corrida, vista frontal |
| pose_5_head_close_up | Close de cabeça |
| pose_6_hand_open_palm | Mão aberta, palma |
| pose_7_hand_fist | Mão fechada |
| pose_8_squatting_pose | Agachamento |
| pose_9_jumping_jack | Jumping jack |
| pose_10_yoga_tree_pose | Yoga tree pose |

## Backend SIM × REAL

| Situação | O que acontece |
|---|---|
| DLL SIM + checkbox "Exigir backend REAL" marcado | Demo bloqueia a detecção e avisa |
| DLL SIM + checkbox desmarcado | Detecta com landmarks simulados (log avisa) |
| DLL REAL + modelo `.task` | Detecta landmarks reais do corpo |

Para backend REAL, baixe os modelos:
```powershell
# Windows
.\bridge\mediapipe_pose\tools\fetch_model.ps1
```

Os modelos ficam em `runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/models/`.

## Log de diagnóstico

O demo grava um log em `detector_execution.log` ao lado do executável. Cada linha tem timestamp e mensagem. Útil para depurar problemas de DLL ou detecção.

## Limitação

Somente **64-bit**. Abrir o demo compilado em 32-bit mostra a mensagem e encerra.
