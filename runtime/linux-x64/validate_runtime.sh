#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-${CHATGPT_AI_HOME:-$HOME/.local/share/chatgpt-ai}}"
FAIL=0

check_exec() {
  local f="$1" name="$2"
  if [[ -x "$f" ]]; then echo "[OK] $name: $f"; else echo "[FALTA] $name: $f"; FAIL=1; fi
}

check_exec "$ROOT/bin/llama-server" "llama-server"
check_exec "$ROOT/bin/whisper-cli" "whisper-cli"
check_exec "$ROOT/bin/python3" "python3 wrapper"
check_exec "$ROOT/bin/pdftotext" "pdftotext wrapper"

if command -v ffmpeg >/dev/null 2>&1; then
  echo "[OK] ffmpeg: $(command -v ffmpeg)"
else
  echo "[FALTA] ffmpeg"
  FAIL=1
fi

if [[ -x "$ROOT/bin/python3" ]]; then
  if "$ROOT/bin/python3" - <<'PY'
import sys
print(sys.version)
import numpy
import cv2
print('numpy', numpy.__version__)
print('opencv', cv2.__version__)
PY
  then
    echo "[OK] Python/NumPy/OpenCV"
  else
    echo "[FALTA] Python/NumPy/OpenCV"
    FAIL=1
  fi
fi

if [[ -f "$ROOT/chatgpt_ai_runtime.ini" ]]; then
  echo "[OK] chatgpt_ai_runtime.ini"
else
  echo "[FALTA] chatgpt_ai_runtime.ini"
  FAIL=1
fi

exit "$FAIL"
