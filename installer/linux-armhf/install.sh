#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_DIR="${1:-/opt/chatgpt-ai}"
LAZBUILD="${2:-}"
case "$(uname -m)" in armv6*|armv7*|armhf) ;; *) echo "[ERRO] Este instalador requer Linux ARM 32 bits."; exit 1;; esac
python3 "$ROOT_DIR/installer/common/create_runtime_ini.py" --platform linux --arch armhf --install-dir "$TARGET_DIR" --lazbuild "$LAZBUILD" || exit $?
INSTALL_ARGS=(install --profile all --arch armhf)
if [[ -n "$LAZBUILD" ]]; then INSTALL_ARGS+=(--lazbuild "$LAZBUILD"); fi
python3 "$ROOT_DIR/installer/common/install_suite.py" "${INSTALL_ARGS[@]}" || exit $?
python3 "$ROOT_DIR/installer/common/check_runtime.py" --profile arm --install-dir "$TARGET_DIR"
