#!/usr/bin/env bash
set -euo pipefail

LAZBUILD="${LAZBUILD:-$(command -v lazbuild || true)}"
if [[ -z "$LAZBUILD" ]]; then
  echo "lazbuild não encontrado."
  exit 1
fi

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
  case "$(uname -m)" in
    aarch64|arm64) MODE="LinuxARM64" ;;
    armv7l|armv7*|armhf) MODE="LinuxARMHF" ;;
    x86_64|amd64) MODE="LinuxX64" ;;
    i386|i486|i586|i686) echo "Linux x86 32 bits ainda não possui build mode." >&2; exit 2 ;;
    *) echo "Arquitetura não suportada automaticamente: $(uname -m)" >&2; exit 2 ;;
  esac
fi

echo "Build mode: $MODE"
"$LAZBUILD" --build-mode="$MODE" runtime_installer.lpi
