#!/usr/bin/env bash
set -euo pipefail

REPO="marcelomaurin/CHATGPT"
ASSET="CHATGPT-AI-runtime-linux-arm64.zip"
BASE_URL="https://github.com/$REPO/releases/latest/download"
INSTALL_DIR="${CHATGPT_AI_HOME:-$HOME/.local/share/chatgpt-ai}"
TMP_DIR="${TMPDIR:-/tmp}/chatgpt-ai-arm64-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2; exit 2
fi
case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "ERRO: este instalador é ARM64; detectado $(uname -m)." >&2; exit 3 ;;
esac

missing=()
for c in curl unzip sha256sum python3; do
  command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done
if ((${#missing[@]})); then
  echo "ERRO: pré-requisitos ausentes: ${missing[*]}" >&2
  if command -v apt-get >/dev/null 2>&1; then
    echo "Instale com: sudo apt-get install -y curl unzip python3 python3-venv python3-pip ffmpeg poppler-utils libopenblas0 libsndfile1" >&2
  fi
  exit 4
fi

if ! python3 -m venv --help >/dev/null 2>&1; then
  echo "ERRO: módulo python3-venv ausente." >&2
  exit 4
fi

mkdir -p "$TMP_DIR" "$INSTALL_DIR"

echo "CHATGPT-AI Runtime Installer - Linux ARM64"
echo "Destino: $INSTALL_DIR"

echo "Baixando $ASSET..."
curl -fL --retry 3 --connect-timeout 20 "$BASE_URL/$ASSET" -o "$TMP_DIR/$ASSET"
curl -fL --retry 3 --connect-timeout 20 "$BASE_URL/SHA256SUMS.txt" -o "$TMP_DIR/SHA256SUMS.txt"

EXPECTED="$(awk -v f="$ASSET" '$2==f || $2=="*"f {print $1; exit}' "$TMP_DIR/SHA256SUMS.txt")"
[[ -n "$EXPECTED" ]] || { echo "ERRO: SHA256 de $ASSET não encontrado." >&2; exit 5; }
ACTUAL="$(sha256sum "$TMP_DIR/$ASSET" | awk '{print $1}')"
[[ "$EXPECTED" == "$ACTUAL" ]] || { echo "ERRO: SHA256 inválido." >&2; exit 6; }
echo "SHA256 OK."

if [[ -f "$INSTALL_DIR/chatgpt_ai_runtime.ini" ]]; then
  cp -f "$INSTALL_DIR/chatgpt_ai_runtime.ini" "$INSTALL_DIR/chatgpt_ai_runtime.ini.bak"
fi

unzip -oq "$TMP_DIR/$ASSET" -d "$INSTALL_DIR"

for f in "$INSTALL_DIR/bin/llama-server" "$INSTALL_DIR/bin/llama-cli" "$INSTALL_DIR/bin/whisper-cli"; do
  [[ -f "$f" ]] && chmod +x "$f"
done

echo "Criando ambiente Python local..."
rm -rf "$INSTALL_DIR/python/venv"
python3 -m venv "$INSTALL_DIR/python/venv"
"$INSTALL_DIR/python/venv/bin/python" -m pip install --upgrade pip setuptools wheel
REQ="$INSTALL_DIR/python/requirements-arm64.txt"
if [[ -f "$REQ" ]]; then
  "$INSTALL_DIR/python/venv/bin/python" -m pip install -r "$REQ"
fi

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

if [[ -x "$SCRIPT_DIR/validate_runtime.sh" ]]; then
  "$SCRIPT_DIR/validate_runtime.sh" "$INSTALL_DIR"
elif [[ -f "$INSTALL_DIR/scripts/validate_runtime.sh" ]]; then
  chmod +x "$INSTALL_DIR/scripts/validate_runtime.sh"
  "$INSTALL_DIR/scripts/validate_runtime.sh" "$INSTALL_DIR"
fi

echo
echo "Runtime ARM64 instalado com sucesso em $INSTALL_DIR"
