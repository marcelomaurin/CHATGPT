#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-recommended}"
LAZBUILD="${2:-}"

case "$MODE" in
  core|recommended|all) ;;
  -h|--help|help)
    echo "Uso: ./install_components.sh [core|recommended|all] [caminho_lazbuild]"
    echo "Variáveis opcionais: ZEOS_ROOT, CEF4DELPHI_ROOT e GLSCENE_ROOT."
    exit 0
    ;;
  *) echo "[ERRO] Modo inválido: $MODE"; exit 1 ;;
esac

PYTHON_BIN="${PYTHON_BIN:-python3}"
ARGS=(install --profile "$MODE")
if [[ -n "$LAZBUILD" ]]; then ARGS+=(--lazbuild "$LAZBUILD"); fi
exec "$PYTHON_BIN" "$ROOT_DIR/installer/common/install_suite.py" "${ARGS[@]}"
