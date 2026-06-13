# TAIHumanPoseDetector - Componente com MediaPipe Runtime Versionado

Este componente foi projetado para integrar a detecção de pose humana usando o MediaPipe Runtime Versionado à Lazarus AI Suite. Ele utiliza uma biblioteca dinâmica (DLL/SO) intermediária para carregar o modelo de maneira eficiente e segura, sem dependência direta de scripts Python.

## 1. Finalidade

Detecção de 33 landmarks corporais (incluindo face, tronco, braços e pernas) em imagens estáticas, frames de vídeo e buffers RGB brutos.

## 2. Unit e Pacote Planejados

- **Unit:** `pacote/IA/aihumanposedetector.pas` (Tipos em `pacote/IA/aihumanpose_types.pas`)
- **Pacote:** `openai_vision.lpk`
- **Aba na IDE:** `AI Vision`

## 3. Arquitetura

```text
TAIHumanPoseDetector.pas (Lazarus/FPC)
        ↓
AI MediaPipe Pose Bridge ABI v1
        ↓
ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll (ou .so)
        ↓
MediaPipe v0.10.35
        ↓
pose_landmarker.task
```

### Versões da DLL/SO recomendadas:
- Windows x64: `ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll`
- Linux x64: `libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so`
- Linux ARM64: `libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_arm64.so`

## 4. Estrutura de Diretórios do Runtime

O runtime deve estar estruturado na seguinte árvore de diretórios para localização automática:

```text
runtime/
  mediapipe/
    pose/
      mp_0_10_35/
        windows/
          x64/
            ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
            bridge_manifest.json
            README_RUNTIME.md
            models/
              pose_landmarker_lite.task
              pose_landmarker_full.task
              pose_landmarker_heavy.task
            deps/
              *.dll
        linux/
          x64/
            libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so
            bridge_manifest.json
            ...
```

### Manifesto (`bridge_manifest.json`)
Cada diretório de runtime deve conter um manifesto JSON validando:
```json
{
  "name": "AI MediaPipe Pose Bridge",
  "component": "TAIHumanPoseDetector",
  "bridge_version": "1.0.0",
  "bridge_abi_version": 1,
  "compatible_mediapipe_version": "0.10.35",
  "binary": "ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll",
  "task": "PoseLandmarker",
  "models": {
    "lite": "models/pose_landmarker_lite.task",
    "full": "models/pose_landmarker_full.task",
    "heavy": "models/pose_landmarker_heavy.task"
  },
  "default_model": "full",
  "landmark_count": 33
}
```

## 5. Propriedades Planejadas

### Publicadas (Published)
- `BridgeDLLPath`: Caminho manual da DLL da bridge.
- `RuntimePath`: Caminho manual da pasta do runtime.
- `ModelFile`: Caminho manual do modelo `.task`.
- `Active`: Ativa/Desativa o detector.
- `LoadMode`: Método de busca (`mplmAuto`, `mplmManualPath`, etc.).
- `ExecutionMode`: Modo de execução (`mpemDLL` ou `mpemProcess`).
- `RequiredBridgeAbiVersion`: Versão mínima de ABI (Padrão: 1).
- `RequiredMediaPipeVersion`: Versão compatível necessária do MediaPipe (Ex: '0.10.35').
- `RunningMode`: Modo de processamento (`hprImage`, `hprVideo`, `hprLiveStream`).
- `NumPoses`: Quantidade máxima de poses a detectar.
- `MinPoseDetectionConfidence`: Limiar mínimo de detecção.
- `MinPosePresenceConfidence`: Limiar mínimo de presença.
- `MinTrackingConfidence`: Limiar mínimo de rastreamento.
- `OutputSegmentationMasks`: Habilitar máscara de segmentação de silhueta.
- `ModelVariant`: Variante de modelo (`hpmLite`, `hpmFull`, `hpmHeavy`, `hpmCustom`).
- `InputColorFormat`: Formato de cor de entrada (`hpcRGB`, `hpcBGR`, `hpcRGBA`, `hpcBGRA`).
- `DetectAllLandmarks`: Quando ativo, coleta todos os 33 landmarks.
- `EnabledBodyPartGroups`: Filtro de grupos corporais ativos (`hpgFace`, `hpgShoulders`, `hpgLeftArm`, etc.).
- `MinLandmarkVisibility` / `MinLandmarkPresence`: Filtros de confiança por ponto anatômico.
- `IgnoreInvisibleLandmarks`: Ignora landmarks com pouca visibilidade.
- `DrawSkeleton` / `DrawLandmarkPoints` / `DrawLandmarkNames`: Configurações de desenho.

### Públicas de Diagnóstico (Public - Read-Only)
- `LastError`: Mensagem do último erro ocorrido.
- `LastOutput`: Diagnóstico da última saída do detector.
- `LoadedBridgeDLLPath`: Caminho absoluto da DLL carregada de fato.
- `BridgeVersionText` / `BridgeAbiVersion`: Informações detalhadas da biblioteca.
- `LazarusArchitecture` / `BridgeArchitecture`: Verificação de compatibilidade de arquitetura (x64/x86/ARM64).
- `RequiredMethodsOK`: Flag indicando que todos os entrypoints foram resolvidos.
- `DiagnosticLog`: Histórico de passos executados na carga.

## 6. Lista Oficial de Landmarks (Mapeados na Ordem)

```text
0  - Nose             11 - LeftShoulder    22 - RightThumb
1  - LeftEyeInner     12 - RightShoulder   23 - LeftHip
2  - LeftEye          13 - LeftElbow       24 - RightHip
3  - LeftEyeOuter     14 - RightElbow      25 - LeftKnee
4  - RightEyeInner    15 - LeftWrist       26 - RightKnee
5  - RightEye         16 - RightWrist      27 - LeftAnkle
6  - RightEyeOuter    17 - LeftPinky       28 - RightAnkle
7  - LeftEar          18 - RightPinky      29 - LeftHeel
8  - RightEar         19 - LeftIndex       30 - RightHeel
9  - MouthLeft        20 - RightIndex      31 - LeftFootIndex
10 - MouthRight       21 - LeftThumb       32 - RightFootIndex
```

## 7. Exemplo de Uso Planejado

```pascal
var
  LShoulder: TAIHumanPoseLandmark;
begin
  AIHumanPoseDetector1.LoadMode := mplmAuto;
  AIHumanPoseDetector1.ModelVariant := hpmFull;

  if AIHumanPoseDetector1.Initialize then
  begin
    if AIHumanPoseDetector1.DetectImageFile('sample.jpg') then
    begin
      if AIHumanPoseDetector1.GetLandmark(0, hplLeftShoulder, LShoulder) then
      begin
        ShowMessage(Format('Ombro Esquerdo: X=%f Y=%f', [LShoulder.X, LShoulder.Y]));
      end;
    end;
  end;
end;
```

## 8. Demonstração de Teste Real

Abaixo está o screenshot do teste prático utilizando a bridge em modo REAL integrada no Lazarus com o modelo do MediaPipe detectando os 33 landmarks corporais:

![MediaPipe Pose Detection Demo](../../screenshots/pose_detector_demo.jpg)

