#!/usr/bin/env bash
set -euo pipefail

REPO="marcelomaurin/CHATGPT"
ASSET="CHATGPT-AI-runtime-linux-arm64.zip"
BASE_URL="https://github.com/$REPO/releases/latest/download"
INSTALL_DIR="${CHATGPT_AI_HOME:-$HOME/.local/share/chatgpt-ai}"
TMP_DIR="${TMPDIR:-/tmp}/chatgpt-ai-arm64-$$"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2; exit 2
fi
case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "ERRO: este instalador é ARM64; detectado $(uname -m)." >&2; exit 3 ;;
esac

for c in curl unzip sha256sum; do
  command -v "$c" >/dev/null 2>&1 || { echo "ERRO: pré-requisito ausente: $c" >&2; exit 4; }
done

mkdir -p "$TMP_DIR" "$INSTALL_DIR"

echo "CHATGPT-AI Runtime Installer - Linux ARM64"
echo "Destino: $INSTALL_DIR"

echo "Baixando $ASSET..."
curl -fL --retry 3 --connect-timeout 20 "$BASE_URL/$ASSET" -o "$TMP_DIR/$ASSET"
curl -fL --retry 3 --connect-timeout 20 "$BASE_URL/SHA256SUMS.txt" -o "$TMP_DIR/SHA256SUMS.txt"

EXPECTED="$(awk -v f="$ASSET" '$2==f || $2=="*"f {print $1; exit}' "$TMP_DIR/SHA256SUMS.txt")"
if [[ -z "$EXPECTED" ]]; then
  echo "ERRO: SHA256 de $ASSET não encontrado." >&2; exit 5
fi
ACTUAL="$(sha256sum "$TMP_DIR/$ASSET" | awk '{print $1}')"
if [[ "$EXPECTED" != "$ACTUAL" ]]; then
  echo "ERRO: SHA256 inválido." >&2; exit 6
fi

echo "SHA256 OK."

if [[ -f "$INSTALL_DIR/chatgpt_ai_runtime.ini" ]]; then
  cp -f "$INSTALL_DIR/chatgpt_ai_runtime.ini" "$INSTALL_DIR/chatgpt_ai_runtime.ini.bak"
fi

unzip -oq "$TMP_DIR/$ASSET" -d "$INSTALL_DIR"

# normaliza permissões de executáveis conhecidos
for f in \
  "$INSTALL_DIR/bin/llama-server" \
  "$INSTALL_DIR/bin/llama-cli" \
  "$INSTALL_DIR/bin/whisper-cli" \
  "$INSTALL_DIR/python/venv/bin/python"; do
  [[ -f "$f" ]] && chmod +x "$f"
done

cat > "$INSTALL_DIR/chatgpt_ai_runtime.ini" <<EOF
[runtime]
platform=linux-arm64
root=$INSTALL_DIR
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

[tools]
python=$INSTALL_DIR/python/venv/bin/python
llama_server=$INSTALL_DIR/bin/llama-server
whisper=$INSTALL_DIR/bin/whisper-cli
pdftotext=$(command -v pdftotext || true)
ffmpeg=$(command -v ffmpeg || true)
EOF

"$(dirname "$0")/validate_runtime.sh" "$INSTALL_DIR"

echo
echo "Runtime ARM64 instalado com sucesso em $INSTALL_DIR"
