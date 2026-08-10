#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2; exit 2
fi
case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "ERRO: esperado ARM64/aarch64; detectado $(uname -m)." >&2; exit 3 ;;
esac

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    ca-certificates curl unzip zip git build-essential cmake pkg-config \
    python3 python3-venv python3-pip \
    libopenblas-dev libopenblas0 libssl-dev libsndfile1 \
    ffmpeg poppler-utils
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y \
    ca-certificates curl unzip zip git gcc gcc-c++ cmake pkgconf-pkg-config \
    python3 python3-pip openblas-devel openssl-devel libsndfile \
    ffmpeg poppler-utils
else
  echo "ERRO: distribuição não suportada automaticamente. Instale manualmente curl, unzip, python3+venv, OpenBLAS, FFmpeg e Poppler." >&2
  exit 4
fi

echo "Pré-requisitos ARM64 instalados."
