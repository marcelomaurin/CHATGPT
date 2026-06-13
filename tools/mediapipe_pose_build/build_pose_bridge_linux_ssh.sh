#!/bin/bash
# ============================================================
# build_pose_bridge_linux_ssh.sh
# Compila a bridge MediaPipe Pose em Linux x86_64 via SSH
# e copia o .so de volta para o runtime local.
#
# Uso:
#   ./build_pose_bridge_linux_ssh.sh usuario@host [SIM|REAL]
#
# Exemplos:
#   ./build_pose_bridge_linux_ssh.sh dev@linuxserver SIM
#   ./build_pose_bridge_linux_ssh.sh dev@192.168.1.20 REAL
#
# Pre-requisitos:
#   - ssh/scp no PATH local
#   - cmake + g++/clang++ na maquina remota Linux
#   - Repositorio clonado na maquina remota em REMOTE_ROOT
# ============================================================

set -euo pipefail

# ---- Parametros ----------------------------------------------------------
SSH_HOST="${1:-}"
BACKEND="${2:-SIM}"
BACKEND="${BACKEND^^}"   # uppercase

if [[ -z "$SSH_HOST" ]]; then
    echo "ERRO: informe o host SSH."
    echo "Uso: $0 usuario@host [SIM|REAL]"
    exit 1
fi

if [[ "$BACKEND" != "SIM" && "$BACKEND" != "REAL" ]]; then
    echo "ERRO: backend invalido '$BACKEND'. Use SIM ou REAL."
    exit 1
fi

# ---- Variáveis -----------------------------------------------------------
BRIDGE_VERSION="v1_0_0"
MEDIAPIPE_VERSION="mp0_10_35"
SO_NAME="libai_mediapipe_pose_bridge_${BRIDGE_VERSION}_${MEDIAPIPE_VERSION}_linux_x86_64.so"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Ajuste REMOTE_ROOT se o projeto estiver em outro caminho no Linux remoto
REMOTE_ROOT="/opt/projetos/maurinsoft/CHATGPT"
REMOTE_CMAKE_SOURCE="bridge/mediapipe_pose/build"
REMOTE_BUILD_DIR="bridge/mediapipe_pose/build_linux_${BACKEND}"
REMOTE_SO="${REMOTE_ROOT}/runtime/mediapipe/pose/mp_0_10_35/linux-x86_64/${SO_NAME}"

LOCAL_RUNTIME="${LOCAL_ROOT}/runtime/mediapipe/pose/mp_0_10_35/linux-x86_64"

echo ""
echo "============================================================"
echo "  MediaPipe Pose Bridge -- Build Linux via SSH"
echo "============================================================"
echo "  Host SSH    : $SSH_HOST"
echo "  Backend     : $BACKEND"
echo "  SO alvo     : $SO_NAME"
echo "  Raiz local  : $LOCAL_ROOT"
echo "  Raiz remota : $REMOTE_ROOT"
echo "============================================================"
echo ""

# ---- [1/5] Validar ssh/scp -----------------------------------------------
command -v ssh >/dev/null 2>&1 || { echo "ERRO: ssh nao encontrado."; exit 1; }
command -v scp >/dev/null 2>&1 || { echo "ERRO: scp nao encontrado."; exit 1; }

# ---- [2/5] Testar conexao SSH -------------------------------------------
echo "[1/5] Testando conexao SSH com $SSH_HOST..."
ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_HOST" "echo 'SSH conectado.'"
echo "SSH conectado."

# ---- [3/5] Build remoto -------------------------------------------------
echo ""
echo "[2/5] Executando build remoto (Backend=$BACKEND)..."

ssh "$SSH_HOST" bash <<REMOTE_SCRIPT
set -e
cd "$REMOTE_ROOT"

echo ">>> CMake configure (Backend=$BACKEND)..."
cmake -B "$REMOTE_BUILD_DIR" \\
      -S "$REMOTE_CMAKE_SOURCE" \\
      -DMP_BRIDGE_BACKEND=$BACKEND \\
      -DMP_POSE_BUILD=ON \\
      -DCMAKE_BUILD_TYPE=Release

echo ">>> CMake build..."
cmake --build "$REMOTE_BUILD_DIR" --config Release

# Localizar .so gerado
SO_SRC=\$(find "$REMOTE_BUILD_DIR" -name "${SO_NAME}" -o -name "libmp_pose_bridge.so" 2>/dev/null | head -1)
if [[ -z "\$SO_SRC" ]]; then
    SO_SRC=\$(find "$REMOTE_BUILD_DIR" -name "*.so" 2>/dev/null | head -1)
fi
if [[ -z "\$SO_SRC" ]]; then
    echo "ERRO: .so nao encontrado em $REMOTE_BUILD_DIR"
    exit 1
fi

echo ">>> .so gerado: \$SO_SRC"

# Renomear para nome versionado se necessário
SO_BASENAME=\$(basename "\$SO_SRC")
DEST_DIR="$REMOTE_ROOT/runtime/mediapipe/pose/mp_0_10_35/linux-x86_64"
mkdir -p "\$DEST_DIR"
cp -f "\$SO_SRC" "\$DEST_DIR/${SO_NAME}"
echo ">>> .so copiado para: \$DEST_DIR/${SO_NAME}"
REMOTE_SCRIPT

echo "Build remoto finalizado."

# ---- [4/5] Copiar .so via SCP -------------------------------------------
echo ""
echo "[3/5] Copiando .so via SCP..."
mkdir -p "$LOCAL_RUNTIME"
scp "${SSH_HOST}:${REMOTE_SO}" "${LOCAL_RUNTIME}/${SO_NAME}"
echo "SO copiado: ${LOCAL_RUNTIME}/${SO_NAME}"

# ---- [5/5] Verificar exports localmente (se objdump disponivel) ----------
echo ""
echo "[4/5] Verificando exports..."

REQUIRED_EXPORTS="mp_pose_get_info mp_pose_create mp_pose_destroy mp_pose_detect mp_pose_free_result mp_pose_last_error"
ALL_OK=1

if command -v objdump >/dev/null 2>&1; then
    DUMP_OUT=$(objdump -p "${LOCAL_RUNTIME}/${SO_NAME}" 2>/dev/null)
    for EXP in $REQUIRED_EXPORTS; do
        if ! echo "$DUMP_OUT" | grep -q "$EXP"; then
            echo "ERRO: export ausente: $EXP"
            ALL_OK=0
        fi
    done
elif command -v nm >/dev/null 2>&1; then
    NM_OUT=$(nm -D "${LOCAL_RUNTIME}/${SO_NAME}" 2>/dev/null)
    for EXP in $REQUIRED_EXPORTS; do
        if ! echo "$NM_OUT" | grep -q "$EXP"; then
            echo "ERRO: export ausente: $EXP"
            ALL_OK=0
        fi
    done
else
    echo "AVISO: objdump/nm nao encontrado. Pulando verificacao de exports."
fi

if [[ "$ALL_OK" == "1" ]]; then
    echo "OK: todos os exports obrigatorios encontrados."
fi

# ---- Resumo --------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Build Linux concluido."
echo "  Host SSH    : $SSH_HOST"
echo "  Backend     : $BACKEND"
echo "  SO copiado  : ${LOCAL_RUNTIME}/${SO_NAME}"
echo "============================================================"
echo ""
echo "DLL compilada."
echo "DLL copiada."
echo "Exports encontrados."
echo "Pronta para validacao no demo Linux."
