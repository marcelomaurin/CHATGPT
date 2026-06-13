# TAIHumanPoseDetector

## Finalidade

`TAIHumanPoseDetector` detecta a posição do corpo humano (pose) em imagens usando a bridge nativa do Google MediaPipe Pose Landmarker via carregamento dinâmico de DLL/SO.

O componente suporta dois backends:

- **SIM** — landmarks simulados, sem dependência de modelo. Usado para validar o pipeline de integração (Lazarus → DLL → handle → landmarks → draw → release) sem instalar o MediaPipe real.
- **REAL** — reconhecimento real via MediaPipe 0.10.35. Exige a DLL compilada com `MP_BRIDGE_BACKEND=REAL` e um arquivo modelo `.task`.

## Unit

```text
pacote/AI Vision/aihumanposedetector.pas
Tipos: pacote/AI Vision/aihumanpose_types.pas
```

## Pacote

```text
openai_vision.lpk  —  aba "AI Vision" na IDE
```

## Status

```text
Experimental — somente 64-bit (x86_64)
```

Em sistemas 32-bit o componente compila mas `Initialize` retorna `False` imediatamente.

## Arquitetura

```
TAIHumanPoseDetector (Pascal / Lazarus)
        ↓  carregamento dinâmico (DynLibs)
AI MediaPipe Pose Bridge  (C ABI, ABI v1)
        ↓  ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
MediaPipe v0.10.35
        ↓
pose_landmarker_full.task
```

## Propriedades publicadas

| Propriedade | Tipo | Padrão | Descrição |
|---|---|---|---|
| `BridgeDLLPath` | string | `''` | Caminho/nome da DLL (modo `mplmManualPath`) |
| `RuntimePath` | string | `''` | Diretório do runtime (resolve DLL + modelo automaticamente) |
| `ModelFile` | string | `''` | Nome do arquivo `.task` dentro de `models/` |
| `LoadMode` | TAIHumanPoseLoadMode | `mplmAuto` | Estratégia de busca da DLL |
| `Active` | Boolean | `False` | Não inicia automaticamente — use `Initialize` |
| `NumPoses` | Integer | `1` | Número máximo de poses a detectar |
| `ModelVariant` | TAIHumanPoseModelVariant | `hpmFull` | `hpmLite`, `hpmFull`, `hpmHeavy` |
| `MinPoseDetectionConfidence` | Single | — | Limiar de detecção (REAL) |
| `MinPosePresenceConfidence` | Single | — | Limiar de presença (REAL) |
| `MinTrackingConfidence` | Single | — | Limiar de rastreamento (REAL) |
| `DrawSkeleton` | Boolean | `True` | Desenha linhas do esqueleto |
| `DrawLandmarkPoints` | Boolean | `True` | Desenha círculos nos landmarks |
| `DrawLandmarkNames` | Boolean | `False` | Exibe nomes/índices dos landmarks |

## Propriedades somente leitura (public)

| Propriedade | Tipo | Descrição |
|---|---|---|
| `Available` | Boolean | `True` se a DLL pode ser carregada |
| `Initialized` | Boolean | `True` após `Initialize` bem-sucedido |
| `BridgeBackend` | string | `"SIM"`, `"REAL"` ou `"UNKNOWN"` |
| `BridgeVersionText` | string | Versão da bridge (ex: `"1.0.0"`) |
| `BridgeAbiVersion` | Integer | Versão ABI da bridge (deve ser 1) |
| `LoadedBridgeDLLPath` | string | Caminho completo da DLL carregada |
| `LoadedModelFile` | string | Caminho do modelo carregado (backend REAL) |
| `LastError` | string | Último erro |
| `DiagnosticLog` | TStringList | Log de diagnóstico interno |
| `LastResultData` | TAIHumanPoseResult | Último resultado de detecção |

## Métodos principais

| Método | Retorno | Descrição |
|---|---|---|
| `Initialize` | Boolean | Carrega DLL, cria handle, preenche metadados |
| `FinalizeDetector` | — | Libera handle e descarrega DLL |
| `DetectBitmap(ABitmap)` | Boolean | Detecta em TBitmap |
| `DetectImageFile(AFileName)` | Boolean | Detecta em arquivo de imagem |
| `DetectRGBBuffer(AData, W, H, Stride)` | Boolean | Detecta em buffer RGB bruto |
| `GetPoseCount` | Integer | Número de poses no último resultado |
| `GetLandmark(PoseIdx, LandmarkId, out ALandmark)` | Boolean | Lê landmark por enum |
| `DrawResult(ACanvas, ADestRect)` | — | Desenha esqueleto/landmarks sobre canvas |
| `ClearResult` | — | Limpa o último resultado |

## Exemplo — backend SIM (validação de pipeline)

```pascal
FDetector := TAIHumanPoseDetector.Create(Self);
FDetector.LoadMode      := mplmManualPath;
FDetector.BridgeDLLPath := 'ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll';

if not FDetector.Initialize then
begin
  ShowMessage('Erro: ' + FDetector.LastError);
  Exit;
end;

WriteLn('Backend: ', FDetector.BridgeBackend);  // "SIM"

if FDetector.DetectBitmap(MeuBitmap) and (FDetector.GetPoseCount > 0) then
  FDetector.DrawResult(Canvas, ClientRect);

FDetector.FinalizeDetector;
FDetector.Free;
```

## Exemplo — backend REAL com RuntimePath

```pascal
FDetector := TAIHumanPoseDetector.Create(Self);
FDetector.LoadMode    := mplmAuto;
FDetector.RuntimePath := 'runtime/mediapipe/pose/mp_0_10_35/windows-x86_64';

if not FDetector.Initialize then
begin
  ShowMessage('Erro: ' + FDetector.LastError);
  Exit;
end;

WriteLn('Backend: ', FDetector.BridgeBackend);  // "REAL"
WriteLn('Modelo:  ', FDetector.LoadedModelFile);
```

## Compilar a DLL SIM (bridge)

Requisitos: CMake 3.16+, compilador C++17 (MSVC ou GCC).

```bash
cd bridge/mediapipe_pose
mkdir build && cd build
cmake ..                        # MP_BRIDGE_BACKEND=SIM por padrão
cmake --build . --config Release
```

A DLL gerada é copiada para `runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/`.

## Baixar modelos (backend REAL)

```powershell
# Windows
.\bridge\mediapipe_pose\tools\fetch_model.ps1
```

```bash
# Linux
./bridge/mediapipe_pose/tools/fetch_model.sh
```

Os modelos são gravados em `runtime/mediapipe/pose/mp_0_10_35/<platform>/models/`.

## Diferença SIM × REAL

| Aspecto | SIM | REAL |
|---|---|---|
| `MP_BRIDGE_BACKEND` ao compilar | `SIM` (padrão) | `REAL` |
| Modelo `.task` necessário | Não | Sim |
| Landmarks gerados | Simulados | Reconhecimento real |
| `BridgeBackend` | `"SIM"` | `"REAL"` |
| Uso | Validação de pipeline | Produção |

## Mapeamento de landmarks (33 pontos)

```text
 0  Nose              11  LeftShoulder      22  RightThumb
 1  LeftEyeInner      12  RightShoulder     23  LeftHip
 2  LeftEye           13  LeftElbow         24  RightHip
 3  LeftEyeOuter      14  RightElbow        25  LeftKnee
 4  RightEyeInner     15  LeftWrist         26  RightKnee
 5  RightEye          16  RightWrist        27  LeftAnkle
 6  RightEyeOuter     17  LeftPinky         28  RightAnkle
 7  LeftEar           18  RightPinky        29  LeftHeel
 8  RightEar          19  LeftIndex         30  RightHeel
 9  MouthLeft         20  RightIndex        31  LeftFootIndex
10  MouthRight        21  LeftThumb         32  RightFootIndex
```

## Limitação de 64-bit

Todo o código de carregamento de DLL está protegido por `{$IFDEF CPU64}`. Em 32-bit `Initialize` retorna `False` com a mensagem `"Componente disponível apenas em 64-bit"`.

## Erros comuns

| Mensagem | Causa | Solução |
|---|---|---|
| `Bridge DLL não encontrada` | DLL ausente | Configurar `BridgeDLLPath` ou `RuntimePath` |
| `Exports ausentes na bridge` | DLL incorreta/corrompida | Verificar se é a bridge correta |
| `ABI mismatch` | DLL com ABI diferente | Recompilar a bridge |
| `mp_pose_create falhou` | Erro na bridge | Ver `LastError` e `DiagnosticLog` |
| `model_path obrigatório` | Backend REAL sem modelo | Baixar modelos com `fetch_model.*` |

## Demonstração de Teste Real

Abaixo está o screenshot do teste prático utilizando a bridge em modo REAL integrada no Lazarus com o modelo do MediaPipe detectando os 33 landmarks corporais:

![MediaPipe Pose Detection Demo](../../../screenshots/pose_detector_demo.jpg)

