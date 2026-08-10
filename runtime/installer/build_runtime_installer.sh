#!/usr/bin/env bash
set -e
LAZBUILD="${LAZBUILD:-$(command -v lazbuild || true)}"
if [[ -z "$LAZBUILD" ]]; then
  echo "lazbuild não encontrado."
  exit 1
fi
"$LAZBUILD" runtime_installer.lpi
