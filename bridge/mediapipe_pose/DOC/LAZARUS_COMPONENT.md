# Integração Lazarus — TAIHumanPoseDetector

Este documento descreve como o componente Lazarus `TAIHumanPoseDetector` se integra com a bridge `mp_pose_bridge`.

## Arquitetura

```
[Aplicação Lazarus]
        ↓
[TAIHumanPoseDetector]  ←→  mp_pose_bridge.pas (binding Pascal)
        ↓  DynLibs — carregamento dinâmico em tempo de execução
[ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll]
        ├─ SIM backend: landmarks simulados (sem MediaPipe)
        └─ REAL backend: MediaPipe C API + modelo .task
```

## Funções ABI

O binding Pascal está em `pacote/AI Vision/mp_pose_bridge.pas`.

| Função C | Tipo Pascal | Descrição |
|---|---|---|
| `mp_pose_get_info` | `TFunc_mp_pose_get_info` | Metadados da bridge (versão, backend, ABI) |
| `mp_pose_create` | `TFunc_mp_pose_create` | Cria handle + contexto interno |
| `mp_pose_destroy` | `TFunc_mp_pose_destroy` | Libera handle (chama `delete ctx`) |
| `mp_pose_detect` | `TFunc_mp_pose_detect` | Detecta landmarks em buffer RGB |
| `mp_pose_free_result` | `TFunc_mp_pose_free_result` | Libera resultado (`var` — zera o ponteiro) |
| `mp_pose_last_error` | `TFunc_mp_pose_last_error` | Lê último erro do contexto |

## Structs Pascal (`{$PACKRECORDS C}`)

```pascal
tmp_pose_info = record
  struct_size: cint32;
  abi_version: cint32;
  bridge_version: array[0..31] of AnsiChar;
  mediapipe_version: array[0..31] of AnsiChar;
  platform: array[0..15] of AnsiChar;
  arch: array[0..15] of AnsiChar;
  model_name: array[0..127] of AnsiChar;
  backend: array[0..15] of AnsiChar;   { "SIM" | "REAL" }
end;
```

O campo `backend` é escrito pela bridge apenas se o caller alocou struct suficientemente grande (guard `offsetof`). Callers antigos que não conhecem o campo recebem a struct zerada nessa posição e não sofrem overflow.

## Ciclo de vida do componente

```
FormCreate
  └─ TAIHumanPoseDetector.Create   → aloca FDetector, FDiagnosticLog
                                      NÃO carrega DLL

Botão "Carregar / Re-inicializar"
  └─ FDetector.Initialize
       ├─ DestroyDetectorHandleOnly  (libera handle, mantém DLL se já carregada)
       ├─ LoadBridgeDLL              (carrega/re-carrega se necessário)
       ├─ mp_pose_get_info           (preenche BridgeBackend, BridgeVersionText)
       └─ mp_pose_create             (cria handle, preenche FDetectorHandle)

DetectBitmap / DetectRGBBuffer
  └─ mp_pose_detect                 (devolve Pmp_pose_result via double-pointer)
       └─ mp_pose_free_result        (libera resultado via var-parameter)

FormDestroy
  └─ FDetector.Free
       └─ FinalizeDetector
            ├─ DestroyDetectorHandleOnly  (mp_pose_destroy)
            └─ UnloadBridgeDLL
```

`DestroyDetectorHandleOnly` foi introduzido na FASE5 para separar a destruição do handle da descarga da DLL. Isso evita que `Initialize` chame `FinalizeDetector` (que descarregaria a DLL e tornaria inválidos os ponteiros de função antes de `mp_pose_create`).

## Gerenciamento de memória

- `mp_pose_context` é alocado com `new (std::nothrow) mp_pose_context()` e liberado com `delete`. Isso garante que construtores/destrutores de `std::string` rodem corretamente.
- `mp_pose_result` é POD puro (`calloc`/`free`). Liberado via `mp_pose_free_result(var LResult)` que zera o ponteiro do caller automaticamente.
- Exceções C++ não cruzam o boundary da ABI. Erros são reportados via `int32_t` de retorno + `mp_pose_last_error`.

## Dois canais de erro

| Canal | Quando usar |
|---|---|
| `mp_pose_last_error(nil)` | Erros antes de ter um handle válido (falha em `mp_pose_create`) |
| `mp_pose_last_error(handle)` | Erros durante `mp_pose_detect` |

O componente Pascal usa o canal correto automaticamente em `Initialize` e `DetectRGBBuffer`.

## Campo `BridgeBackend`

Após `Initialize`, `FDetector.BridgeBackend` contém `"SIM"`, `"REAL"` ou `"UNKNOWN"`. O demo exibe esse campo e pode bloquear a detecção se o usuário exigir backend `REAL` via checkbox.

## Compatibilidade com nomes legados

O loader `LoadMpPoseBridge` aceita como fallback:
- `mp_pose_bridge.dll` / `libmp_pose_bridge.so`

O nome oficial versionado tem prioridade. Builds locais mais antigos podem usar o nome legado enquanto o pipeline não é ajustado.

## Limitação de 64-bit

Todo o código de interop com a DLL está dentro de `{$IFDEF CPU64}`. O componente compila em 32-bit, mas `Initialize` retorna `False` imediatamente.
