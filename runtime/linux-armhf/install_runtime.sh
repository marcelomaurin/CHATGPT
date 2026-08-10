#!/usr/bin/env bash
set -euo pipefail

REPO="marcelomaurin/CHATGPT"
ASSET="CHATGPT-AI-runtime-linux-armhf.zip"
BASE_URL="https://github.com/$REPO/releases/latest/download"
INSTALL_DIR="${CHATGPT_AI_HOME:-$HOME/.local/share/chatgpt-ai}"
TMP_DIR="${TMPDIR:-/tmp}/chatgpt-ai-armhf-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2; exit 2
fi
case "$(uname -m)" in
  armv7l|armv7*|armhf) ;;
  *) echo "ERRO: este instalador é ARMHF; detectado $(uname -m)." >&2; exit 3 ;;
esac

missing=()
for c in curl unzip sha256sum python3; do
  command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
if ((${#missing[@]})); then
  echo "ERRO: pré-requisitos ausentes: ${missing[*]}" >&2
  exit 4
fi

mkdir -p "$TMP_DIR" "$INSTALL_DIR"

echo "CHATGPT-AI Runtime Installer - Linux ARMHF (perfil lite)"
echo "Destino: $INSTALL_DIR"

echo "Para visão Python em ARMHF, instale preferencialmente os pacotes da distribuição:"
echo "  sudo apt-get install -y python3-numpy python3-opencv python3-venv ffmpeg poppler-utils"

echo "Baixando $ASSET..."
curl -fL --retry 3 --connect-timeout 20 "$BASE_URL/$ASSET" -o "$TMP_DIR/$ASSET"
curl -fL --retry 3 --connect-timeout 20 "$BASE_URL/SHA256SUMS.txt" -o "$TMP_DIR/SHA256SUMS.txt"

EXPECTED="$(awk -v f="$ASSET" '$2==f || $2=="*"f {print $1; exit}' "$TMP_DIR/SHA256SUMS.txt")"
[[ -n "$EXPECTED" ]] || { echo "ERRO: SHA256 de $ASSET não encontrado." >&2; exit 5; }
ACTUAL="$(sha256sum "$TMP_DIR/$ASSET" | awk '{print $1}')"
[[ "$EXPECTED" == "$ACTUAL" ]] || { echo "ERRO: SHA256 inválido." >&2; exit 6; }

echo "SHA256 OK."
unzip -oq "$TMP_DIR/$ASSET" -d "$INSTALL_DIR"

for f in "$INSTALL_DIR/bin/llama-server" "$INSTALL_DIR/bin/llama-cli" "$INSTALL_DIR/bin/whisper-cli"; do
  [[ -f "$f" ]] && chmod +x "$f"
done

rm -rf "$INSTALL_DIR/python/venv"
python3 -m venv --system-site-packages "$INSTALL_DIR/python/venv"

cat > "$INSTALL_DIR/chatgpt_ai_runtime.ini" <<EOF
[runtime]
platform=linux-armhf
profile=lite
root=$INSTALL_DIR
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

[tools]
python=$INSTALL_DIR/python/venv/bin/python
llama_server=$INSTALL_DIR/bin/llama-server
whisper=$INSTALL_DIR/bin/whisper-cli
pdftotext=$(command -v pdftotext || true)
ffmpeg=$(command -v ffmpeg || true)
EOF

if [[ -x "$SCRIPT_DIR/validate_runtime.sh" ]]; then
  "$SCRIPT_DIR/validate_runtime.sh" "$INSTALL_DIR"
elif [[ -f "$INSTALL_DIR/scripts/validate_runtime.sh" ]]; then
  chmod +x "$INSTALL_DIR/scripts/validate_runtime.sh"
  "$INSTALL_DIR/scripts/validate_runtime.sh" "$INSTALL_DIR"
fi

echo "Runtime ARMHF lite instalado em $INSTALL_DIR"
