#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.runtime-build/arm64}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.runtime-out/linux-arm64}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: este script deve rodar em Linux." >&2
  exit 2
fi

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) ;;
  *) echo "ERRO: esperado ARM64/aarch64; detectado $ARCH" >&2; exit 3 ;;
esac

mkdir -p "$WORK_DIR" "$OUT_DIR/bin" "$OUT_DIR/models" "$OUT_DIR/python"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERRO: comando ausente: $1" >&2; exit 4; }; }
for c in git cmake "$PYTHON_BIN" curl unzip sha256sum; do need "$c"; done

if command -v apt-get >/dev/null 2>&1; then
  echo "Dependências recomendadas (Debian/Ubuntu/Raspberry Pi OS 64):"
  echo "  sudo apt-get install -y build-essential cmake git curl unzip python3 python3-venv python3-pip libopenblas-dev libssl-dev libsndfile1 ffmpeg poppler-utils"
fi

clone_or_update() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" fetch --depth=1 origin
    git -C "$dir" reset --hard origin/HEAD
  else
    git clone --depth=1 "$url" "$dir"
  fi
}

echo "== llama.cpp ARM64 =="
clone_or_update https://github.com/ggml-org/llama.cpp "$WORK_DIR/llama.cpp"
cmake -S "$WORK_DIR/llama.cpp" -B "$WORK_DIR/llama.cpp/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS \
  -DGGML_NATIVE=ON
cmake --build "$WORK_DIR/llama.cpp/build" --config Release -j "$JOBS"
cp -f "$WORK_DIR/llama.cpp/build/bin/llama-server" "$OUT_DIR/bin/"
[[ -f "$WORK_DIR/llama.cpp/build/bin/llama-cli" ]] && cp -f "$WORK_DIR/llama.cpp/build/bin/llama-cli" "$OUT_DIR/bin/"

echo "== whisper.cpp ARM64 =="
clone_or_update https://github.com/ggml-org/whisper.cpp "$WORK_DIR/whisper.cpp"
cmake -S "$WORK_DIR/whisper.cpp" -B "$WORK_DIR/whisper.cpp/build" \
  -DCMAKE_BUILD_TYPE=Release -DGGML_BLAS=ON
cmake --build "$WORK_DIR/whisper.cpp/build" --config Release -j "$JOBS"
cp -f "$WORK_DIR/whisper.cpp/build/bin/whisper-cli" "$OUT_DIR/bin/"

echo "== Python venv ARM64 =="
"$PYTHON_BIN" -m venv "$OUT_DIR/python/venv"
"$OUT_DIR/python/venv/bin/python" -m pip install --upgrade pip setuptools wheel
"$OUT_DIR/python/venv/bin/python" -m pip install numpy opencv-python-headless

cat > "$OUT_DIR/chatgpt_ai_runtime.ini" <<EOF
[runtime]
platform=linux-arm64
root=$OUT_DIR

[tools]
python=$OUT_DIR/python/venv/bin/python
llama_server=$OUT_DIR/bin/llama-server
whisper=$OUT_DIR/bin/whisper-cli
pdftotext=$(command -v pdftotext || true)
ffmpeg=$(command -v ffmpeg || true)
EOF

cat > "$OUT_DIR/BUILD_INFO.txt" <<EOF
platform=linux-arm64
machine=$(uname -m)
kernel=$(uname -r)
python=$($PYTHON_BIN --version 2>&1)
llama_source=https://github.com/ggml-org/llama.cpp
whisper_source=https://github.com/ggml-org/whisper.cpp
built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "Runtime ARM64 montado em: $OUT_DIR"
