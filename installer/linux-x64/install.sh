#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_INSTALLER="$ROOT_DIR/runtime/linux-x64/install_runtime.sh"

if [[ ! -f "$RUNTIME_INSTALLER" ]]; then
  echo "ERRO: runtime/linux-x64/install_runtime.sh não encontrado." >&2
  exit 2
fi

chmod +x "$RUNTIME_INSTALLER"
exec "$RUNTIME_INSTALLER" "$@"
