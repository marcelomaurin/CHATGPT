# Runtime — MediaPipe Pose Bridge

## Estrutura de diretórios

```
runtime/mediapipe/pose/mp_0_10_35/
  windows-x86_64/
    bridge.json
    ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll   ← colocar aqui após compilar
    models/
      pose_landmarker_lite.task    ← somente backend REAL
      pose_landmarker_full.task    ← somente backend REAL
      pose_landmarker_heavy.task   ← somente backend REAL
  linux-x86_64/
    bridge.json
    libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so  ← colocar aqui após compilar
    models/
      pose_landmarker_lite.task    ← somente backend REAL
      pose_landmarker_full.task    ← somente backend REAL
      pose_landmarker_heavy.task   ← somente backend REAL
```

Os arquivos `.gitkeep` são marcadores de diretório. Não há modelos nem DLLs no repositório Git — apenas a estrutura de pastas e o `bridge.json`.

## Backend SIM

A DLL compilada com `MP_BRIDGE_BACKEND=SIM` (padrão do CMake) **não precisa de modelos**. Ela retorna landmarks simulados para validar o pipeline Lazarus → DLL → handle → landmarks → draw → release sem dependências externas.

Fluxo com backend SIM:
1. Compile a bridge: `cmake -DMP_BRIDGE_BACKEND=SIM ..` (ou apenas `cmake ..`)
2. Copie a DLL gerada para este diretório (ao lado do `bridge.json`).
3. No componente Lazarus, configure `BridgeDLLPath` apontando para a DLL.
4. Chame `Initialize` — não precisa de `ModelFile`.

## Backend REAL

A DLL compilada com `MP_BRIDGE_BACKEND=REAL` exige modelos `.task` do Google MediaPipe.

Fluxo com backend REAL:
1. Compile a bridge: `cmake -DMP_BRIDGE_BACKEND=REAL ..`
2. Copie a DLL gerada para este diretório.
3. Baixe os modelos:
   - **Windows**: `bridge\mediapipe_pose\tools\fetch_model.ps1`
   - **Linux**: `bridge/mediapipe_pose/tools/fetch_model.sh`
4. Os modelos são gravados automaticamente em `models/` neste diretório.
5. No componente Lazarus, configure `RuntimePath` apontando para este diretório.
6. Chame `Initialize` — o componente resolve `model_path` automaticamente via `RuntimePath`.

## Propriedades do componente

| Propriedade      | Uso                                                               |
|------------------|-------------------------------------------------------------------|
| `BridgeDLLPath`  | Caminho absoluto ou nome da DLL (quando `LoadMode = mplmManualPath`) |
| `RuntimePath`    | Diretório desta pasta (resolve DLL + modelo automaticamente)      |
| `ModelFile`      | Nome do arquivo `.task` dentro de `models/` (padrão: `pose_landmarker_full.task`) |
| `LoadMode`       | `mplmAuto` (busca em paths padrão), `mplmManualPath` (usa `BridgeDLLPath`) |

## Limitação de arquitetura

O componente `TAIHumanPoseDetector` e a bridge são **exclusivos de 64-bit (x86_64)**. Em 32-bit, o componente compila mas `Initialize` retorna `False` imediatamente.

## Verificação rápida após instalação

```pascal
FDetector.LoadMode    := mplmManualPath;
FDetector.BridgeDLLPath := 'caminho/para/a/DLL';
if FDetector.Initialize then
  WriteLn('Backend: ', FDetector.BridgeBackend)   { "SIM" ou "REAL" }
else
  WriteLn('Erro: ', FDetector.LastError);
```
