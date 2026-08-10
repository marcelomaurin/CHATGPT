#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2
  exit 2
fi
case "$(uname -m)" in
  x86_64|amd64) ;;
  *) echo "ERRO: esperado x86_64; detectado $(uname -m)." >&2; exit 3 ;;
esac

chmod +x "$ROOT_DIR/runtime/linux-x64/"*.sh
"$ROOT_DIR/runtime/linux-x64/build_runtime.sh"
"$ROOT_DIR/runtime/linux-x64/package_runtime.sh"

DIST_DIR="${DIST_DIR:-$ROOT_DIR/.runtime-dist}"
HASH_FILE="$DIST_DIR/SHA256SUMS-linux-x64.txt"
COMMON_FILE="$DIST_DIR/SHA256SUMS.txt"

if [[ -f "$HASH_FILE" ]]; then
  touch "$COMMON_FILE"
  grep -v 'CHATGPT-AI-runtime-linux-x64.zip' "$COMMON_FILE" > "$COMMON_FILE.tmp" || true
  cat "$HASH_FILE" >> "$COMMON_FILE.tmp"
  mv "$COMMON_FILE.tmp" "$COMMON_FILE"
fi

echo
echo "Ubuntu/Linux x64 release pronto:"
echo "  $DIST_DIR/CHATGPT-AI-runtime-linux-x64.zip"
echo "  $COMMON_FILE"
