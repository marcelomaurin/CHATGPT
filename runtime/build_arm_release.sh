#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH="$(uname -m)"

case "$ARCH" in
  aarch64|arm64)
    PROFILE="linux-arm64"
    ;;
  armv7l|armv7*|armhf)
    PROFILE="linux-armhf"
    ;;
  *)
    echo "ERRO: arquitetura ARM não suportada: $ARCH" >&2
    exit 2
    ;;
esac

DIR="$ROOT_DIR/runtime/$PROFILE"
chmod +x "$DIR"/*.sh

if [[ "${INSTALL_PREREQS:-0}" == "1" ]]; then
  "$DIR/install_prerequisites.sh"
fi

"$DIR/build_runtime.sh"
"$DIR/package_runtime.sh"

echo
printf 'Bundle ARM gerado para %s\n' "$PROFILE"
printf 'Diretório: %s/.runtime-dist\n' "$ROOT_DIR"
