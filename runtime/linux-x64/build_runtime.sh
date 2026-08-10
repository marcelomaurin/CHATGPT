#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.runtime-build/linux-x64}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.runtime-out/linux-x64}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: este script deve rodar em Linux." >&2; exit 2
fi
case "$(uname -m)" in
  x86_64|amd64) ;;
  *) echo "ERRO: esperado x86_64; detectado $(uname -m)." >&2; exit 3 ;;
esac

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERRO: comando ausente: $1" >&2; exit 4; }; }
for c in git cmake "$PYTHON_BIN" curl unzip zip sha256sum; do need "$c"; done

mkdir -p "$WORK_DIR" "$OUT_DIR/bin" "$OUT_DIR/models" "$OUT_DIR/python" "$OUT_DIR/scripts"

clone_or_update() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" fetch --depth=1 origin
    git -C "$dir" reset --hard origin/HEAD
  else
    git clone --depth=1 "$url" "$dir"
  fi
}

echo "== llama.cpp Linux x64 =="
clone_or_update https://github.com/ggml-org/llama.cpp "$WORK_DIR/llama.cpp"
cmake -S "$WORK_DIR/llama.cpp" -B "$WORK_DIR/llama.cpp/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS \
  -DGGML_NATIVE=ON
cmake --build "$WORK_DIR/llama.cpp/build" --config Release -j "$JOBS"
cp -f "$WORK_DIR/llama.cpp/build/bin/llama-server" "$OUT_DIR/bin/"
[[ -f "$WORK_DIR/llama.cpp/build/bin/llama-cli" ]] && cp -f "$WORK_DIR/llama.cpp/build/bin/llama-cli" "$OUT_DIR/bin/"

echo "== whisper.cpp Linux x64 =="
clone_or_update https://github.com/ggml-org/whisper.cpp "$WORK_DIR/whisper.cpp"
cmake -S "$WORK_DIR/whisper.cpp" -B "$WORK_DIR/whisper.cpp/build" \
  -DCMAKE_BUILD_TYPE=Release -DGGML_BLAS=ON
cmake --build "$WORK_DIR/whisper.cpp/build" --config Release -j "$JOBS"
cp -f "$WORK_DIR/whisper.cpp/build/bin/whisper-cli" "$OUT_DIR/bin/"

cat > "$OUT_DIR/python/requirements-linux-x64.txt" <<'EOF'
numpy
opencv-python-headless
EOF

cat > "$OUT_DIR/python/bootstrap.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$ROOT/python/venv"
if [[ ! -x "$VENV/bin/python" ]]; then
  python3 -m venv "$VENV"
  "$VENV/bin/python" -m pip install --upgrade pip setuptools wheel
  "$VENV/bin/python" -m pip install -r "$ROOT/python/requirements-linux-x64.txt"
fi
exec "$VENV/bin/python" "$@"
EOF
chmod +x "$OUT_DIR/python/bootstrap.sh"

cat > "$OUT_DIR/bin/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/python/bootstrap.sh" "$@"
EOF
chmod +x "$OUT_DIR/bin/python3"

cat > "$OUT_DIR/bin/pdftotext" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
EXE="$(command -v /usr/bin/pdftotext 2>/dev/null || command -v pdftotext 2>/dev/null || true)"
if [[ -z "$EXE" || "$EXE" == "$0" ]]; then
  echo "pdftotext não encontrado. Instale poppler-utils." >&2
  exit 127
fi
exec "$EXE" "$@"
EOF
chmod +x "$OUT_DIR/bin/pdftotext"

cat > "$OUT_DIR/BUILD_INFO.txt" <<EOF
platform=linux-x64
machine=$(uname -m)
kernel=$(uname -r)
python=$($PYTHON_BIN --version 2>&1)
llama_source=https://github.com/ggml-org/llama.cpp
whisper_source=https://github.com/ggml-org/whisper.cpp
built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "Runtime Ubuntu/Linux x64 montado em: $OUT_DIR"
