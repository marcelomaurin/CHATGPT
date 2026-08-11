#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_DIR="${1:-/opt/chatgpt-ai}"
LAZBUILD="${2:-}"
case "$(uname -m)" in aarch64|arm64) ;; *) echo "[ERRO] Este instalador requer Linux ARM64."; exit 1;; esac
python3 "$ROOT_DIR/installer/common/create_runtime_ini.py" --platform linux --arch aarch64 --install-dir "$TARGET_DIR" --lazbuild "$LAZBUILD" || exit $?
INSTALL_ARGS=(install --profile all --arch aarch64)
if [[ -n "$LAZBUILD" ]]; then INSTALL_ARGS+=(--lazbuild "$LAZBUILD"); fi
python3 "$ROOT_DIR/installer/common/install_suite.py" "${INSTALL_ARGS[@]}" || exit $?
python3 "$ROOT_DIR/installer/common/check_runtime.py" --profile arm --install-dir "$TARGET_DIR"
