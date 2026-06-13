# MediaPipe Pose Bridge — Automação de Build

Esta pasta contém os scripts para compilar, verificar, instalar e manter a DLL da bridge `TAIHumanPoseDetector`.

## DLL gerada

```text
ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll   (Windows 64-bit)
libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux_x86_64.so   (Linux 64-bit)
```

## Scripts disponíveis

| Arquivo | Função |
|---|---|
| `build_pose_bridge_local.bat` | Build completo local no Windows |
| `build_pose_bridge_remote_ssh.bat` | Aciona build em máquina remota via SSH + copia DLL |
| `build_pose_bridge_remote.ps1` | Script PowerShell chamado remotamente via SSH |
| `verify_pose_bridge_exports.bat` | Verifica exports obrigatórios da DLL |
| `clean_pose_bridge_legacy.bat` | Remove DLLs com nomes legados |
| `build_pose_bridge_linux_ssh.sh` | Build em Linux remoto via SSH |

## Pré-requisitos

**Windows local:**
- CMake 3.16+ no PATH
- MSVC Build Tools (Visual Studio 2019/2022) ou clang + ninja

**Build remoto via SSH:**
- OpenSSH Client local (Windows 10+ inclui por padrão)
- OpenSSH Server na máquina remota
- Mesmo layout de repositório na máquina remota

## Build local — Windows

```bat
:: Backend SIM (padrão — sem modelo, pontos simulados)
build_pose_bridge_local.bat SIM

:: Backend REAL (MediaPipe real — precisa de modelo .task)
build_pose_bridge_local.bat REAL
```

O script:
1. Configura e compila via CMake
2. Renomeia a DLL para o nome versionado oficial
3. Copia para `runtime\mediapipe\pose\mp_0_10_35\windows-x86_64\`
4. Copia para `pacote\samples\AI MediaPipe Vision\pose_detector_demo\`
5. Verifica os 6 exports obrigatórios
6. Remove DLLs legadas
7. Gera `bridge_manifest.json` e `build_report.txt`

## Build remoto — SSH para Windows

```bat
:: Disparar build REAL na máquina buildserver e copiar DLL
build_pose_bridge_remote_ssh.bat admin@buildserver REAL

:: SIM
build_pose_bridge_remote_ssh.bat admin@192.168.1.10 SIM
```

O script:
1. Testa conexão SSH
2. Executa `build_pose_bridge_local.bat REAL` na máquina remota
3. Copia a DLL de volta via `scp`
4. Instala localmente em runtime e demo
5. Verifica exports
6. Limpa DLLs legadas

**Pré-requisitos da máquina remota:**
- OpenSSH Server instalado e rodando
- Repositório clonado em `D:\projetos\maurinsoft\CHATGPT` (padrão)
- CMake + MSVC Build Tools instalados
- Chave SSH configurada (ou senha disponível)

Para usar outro caminho remoto, edite a variável `REMOTE_ROOT` no script.

## Build remoto — SSH para Linux

```bash
./build_pose_bridge_linux_ssh.sh dev@linuxserver SIM
./build_pose_bridge_linux_ssh.sh dev@linuxserver REAL
```

Gera o `.so` Linux e copia para `runtime\mediapipe\pose\mp_0_10_35\linux-x86_64\`.

Para usar outro caminho remoto, edite `REMOTE_ROOT` no script.

## Onde a DLL é instalada

Após qualquer build bem-sucedido a DLL está em:

```text
runtime\mediapipe\pose\mp_0_10_35\windows-x86_64\
  ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll  ← DLL oficial
  bridge_manifest.json                                  ← manifesto atualizado
  build_report.txt                                      ← relatório do build
  models\                                               ← modelos .task (não removidos)

pacote\samples\AI MediaPipe Vision\pose_detector_demo\
  ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll  ← cópia para o demo
```

## Validar exports

```bat
verify_pose_bridge_exports.bat runtime\mediapipe\pose\mp_0_10_35\windows-x86_64\ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
```

Exports obrigatórios verificados:
- `mp_pose_get_info`
- `mp_pose_create`
- `mp_pose_destroy`
- `mp_pose_detect`
- `mp_pose_free_result`
- `mp_pose_last_error`

Requer `dumpbin` (MSVC), `llvm-objdump` ou `objdump` no PATH.

## Baixar modelos (backend REAL)

```powershell
# Windows
.\bridge\mediapipe_pose\tools\fetch_model.ps1
```

```bash
# Linux
./bridge/mediapipe_pose/tools/fetch_model.sh
```

Os modelos ficam em `runtime\mediapipe\pose\mp_0_10_35\windows-x86_64\models\`. Os scripts de limpeza **nunca removem arquivos `.task`**.

## Como validar no demo

Após o build:

1. Abra `pacote\samples\AI MediaPipe Vision\pose_detector_demo\human_pose_detector_demo.lpi` no Lazarus **(compilar em x86_64)**.
2. Aba **Setup / Runtime** → campo "Biblioteca Bridge" → selecione a DLL versionada.
3. Backend REAL: informe também o modelo `.task`.
4. Clique **Carregar / Re-inicializar**.
5. Confira no log:
   ```
   Backend: REAL   (ou SIM)
   Bridge version: 1.0.0
   ```
6. Aba **Detecção** → **Carregar Imagem** → **Detectar Pose**.

## Diferença entre DLL carregada e reconhecimento real

| O que o build garante | O que o build NÃO garante |
|---|---|
| DLL compilada com o backend escolhido | Que a DLL reconhece imagens reais |
| DLL com exports corretos | Que os landmarks são do corpo detectado |
| DLL copiada para os destinos corretos | Precisão do modelo MediaPipe |

A validação de reconhecimento real acontece **no demo**, observando o log `Backend: REAL` e verificando se os landmarks mudam entre imagens diferentes.

O script nunca imprime "MediaPipe REAL funcionando" — apenas:
```
DLL compilada.
DLL copiada.
Exports encontrados.
Pronta para validacao no demo.
```

## Regras de limpeza

`clean_pose_bridge_legacy.bat` remove apenas nomes legados conhecidos:

| Remove | Não remove |
|---|---|
| `mp_pose_bridge.dll` | `ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll` |
| `pose_bridge.dll` | `*.task` (modelos) |
| `mediapipe_pose.dll` | |
| `old_mp_pose_bridge.dll` | |
