#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERRO: Linux obrigatório." >&2; exit 2
fi
case "$(uname -m)" in
  armv7l|armv7*|armhf) ;;
  *) echo "ERRO: esperado ARMHF/armv7; detectado $(uname -m)." >&2; exit 3 ;;
esac

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    ca-certificates curl unzip zip git build-essential cmake pkg-config \
    python3 python3-venv python3-pip python3-numpy python3-opencv \
    libopenblas-dev libopenblas0 libssl-dev libsndfile1 \
    ffmpeg poppler-utils
else
  echo "ERRO: ARMHF automático está preparado para Debian/Raspberry Pi OS. Instale manualmente os equivalentes da sua distribuição." >&2
  exit 4
fi

echo "Pré-requisitos ARMHF instalados."
