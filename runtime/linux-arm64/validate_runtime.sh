#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-${CHATGPT_AI_HOME:-$HOME/.local/share/chatgpt-ai}}"
FAIL=0

check_file() {
  local label="$1" file="$2"
  if [[ -x "$file" || -f "$file" ]]; then
    echo "[OK] $label: $file"
  else
    echo "[FALTA] $label: $file"
    FAIL=1
  fi
}

case "$(uname -m)" in
  aarch64|arm64) echo "[OK] arquitetura ARM64: $(uname -m)" ;;
  *) echo "[ERRO] arquitetura inesperada: $(uname -m)"; FAIL=1 ;;
esac

check_file "runtime ini" "$ROOT/chatgpt_ai_runtime.ini"
check_file "llama-server" "$ROOT/bin/llama-server"
check_file "whisper-cli" "$ROOT/bin/whisper-cli"
check_file "python" "$ROOT/python/venv/bin/python"

if [[ -x "$ROOT/bin/llama-server" ]]; then
  "$ROOT/bin/llama-server" --version >/dev/null 2>&1 || true
fi
if [[ -x "$ROOT/bin/whisper-cli" ]]; then
  "$ROOT/bin/whisper-cli" --help >/dev/null 2>&1 || true
fi
if [[ -x "$ROOT/python/venv/bin/python" ]]; then
  "$ROOT/python/venv/bin/python" - <<'PY' || FAIL=1
import sys
print('[OK] Python', sys.version.split()[0])
import numpy
print('[OK] numpy', numpy.__version__)
try:
    import cv2
    print('[OK] cv2', cv2.__version__)
except Exception as exc:
    print('[ERRO] cv2:', exc)
    raise
PY
fi

command -v pdftotext >/dev/null 2>&1 && echo "[OK] pdftotext: $(command -v pdftotext)" || echo "[WARN] pdftotext não instalado"
command -v ffmpeg >/dev/null 2>&1 && echo "[OK] ffmpeg: $(command -v ffmpeg)" || echo "[WARN] ffmpeg não instalado"

exit "$FAIL"
