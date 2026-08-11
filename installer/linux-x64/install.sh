#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_DIR="${1:-/opt/chatgpt-ai}"
LAZBUILD="${2:-}"

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "[ERRO] Este instalador requer Linux x86_64."
  exit 1
fi

python3 "$ROOT_DIR/installer/common/create_runtime_ini.py" \
  --platform linux --arch x86_64 --install-dir "$TARGET_DIR" --lazbuild "$LAZBUILD" || exit $?
INSTALL_ARGS=(install --profile all)
if [[ -n "$LAZBUILD" ]]; then INSTALL_ARGS+=(--lazbuild "$LAZBUILD"); fi
python3 "$ROOT_DIR/installer/common/install_suite.py" "${INSTALL_ARGS[@]}" || exit $?
python3 "$ROOT_DIR/installer/common/check_runtime.py" --profile full --install-dir "$TARGET_DIR"
