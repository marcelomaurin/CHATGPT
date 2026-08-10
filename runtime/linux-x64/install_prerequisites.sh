#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2
  exit 2
fi
case "$(uname -m)" in
  x86_64|amd64) ;;
  *) echo "ERRO: esperado Linux x64; detectado $(uname -m)." >&2; exit 3 ;;
esac

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERRO: este script foi preparado para Ubuntu/Debian com apt-get." >&2
  exit 4
fi

sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl unzip zip git build-essential cmake pkg-config \
  python3 python3-venv python3-pip python3-dev \
  libopenblas-dev libopenblas0 libssl-dev libsndfile1 \
  ffmpeg poppler-utils

echo "Pré-requisitos Ubuntu x64 instalados."
