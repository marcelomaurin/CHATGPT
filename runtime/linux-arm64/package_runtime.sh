#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.runtime-out/linux-arm64}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/.runtime-dist}"
ASSET="CHATGPT-AI-runtime-linux-arm64.zip"

command -v zip >/dev/null 2>&1 || { echo "ERRO: zip ausente" >&2; exit 2; }
command -v sha256sum >/dev/null 2>&1 || { echo "ERRO: sha256sum ausente" >&2; exit 2; }
[[ -x "$OUT_DIR/bin/llama-server" ]] || { echo "ERRO: llama-server ausente" >&2; exit 3; }
[[ -x "$OUT_DIR/bin/whisper-cli" ]] || { echo "ERRO: whisper-cli ausente" >&2; exit 3; }
[[ -f "$OUT_DIR/python/requirements-arm64.txt" ]] || { echo "ERRO: requirements ARM64 ausente" >&2; exit 3; }

mkdir -p "$OUT_DIR/scripts" "$DIST_DIR"
cp -f "$ROOT_DIR/runtime/linux-arm64/validate_runtime.sh" "$OUT_DIR/scripts/"
chmod +x \
  "$OUT_DIR/bin/llama-server" \
  "$OUT_DIR/bin/whisper-cli" \
  "$OUT_DIR/bin/python3" \
  "$OUT_DIR/bin/pdftotext" \
  "$OUT_DIR/python/bootstrap.sh" \
  "$OUT_DIR/scripts/validate_runtime.sh"

rm -f "$DIST_DIR/$ASSET"
(
  cd "$OUT_DIR"
  zip -qr "$DIST_DIR/$ASSET" .
)
(
  cd "$DIST_DIR"
  sha256sum "$ASSET" > SHA256SUMS-arm64.txt
)

echo "Gerado: $DIST_DIR/$ASSET"
echo "Hash:   $DIST_DIR/SHA256SUMS-arm64.txt"
