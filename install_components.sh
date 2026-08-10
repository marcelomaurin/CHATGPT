#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-recommended}"
LAZBUILD="${2:-}"
FAILED=0

show_help() {
  cat <<'EOF'
TCHATGPT - Lazarus/Free Pascal component installer for Linux

Usage:
  ./install_components.sh [mode] [path_to_lazbuild]

Modes:
  core         Installs only openai_core.lpk
  recommended  Installs the recommended Lazarus AI packages. Default.
  all          Installs all modular packages.
EOF
}

find_lazbuild() {
  if [[ -n "$LAZBUILD" ]]; then return; fi
  if command -v lazbuild >/dev/null 2>&1; then
    LAZBUILD="$(command -v lazbuild)"
    return
  fi
  for candidate in /usr/bin/lazbuild /usr/local/bin/lazbuild /opt/lazarus/lazbuild "$HOME/lazarus/lazbuild"; do
    if [[ -x "$candidate" ]]; then LAZBUILD="$candidate"; return; fi
  done
}

install_package() {
  local pkg_rel="$1"
  local pkg="$ROOT_DIR/$pkg_rel"
  if [[ ! -f "$pkg" ]]; then
    echo "[WARN] Package not found: $pkg_rel"
    FAILED=1
    return
  fi
  echo "Installing package: $pkg_rel"
  "$LAZBUILD" --add-package "$pkg"
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] Failed to install: $pkg_rel"
    FAILED=1
  else
    echo "[OK] Installed: $pkg_rel"
  fi
}

install_recommended() {
  install_package "pacote/packages/openai_core.lpk"
  install_package "pacote/packages/openai_ml.lpk"
  install_package "pacote/packages/openai_output.lpk"
  install_package "pacote/packages/openai_input.lpk"
  install_package "pacote/packages/openai_python.lpk"
  install_package "pacote/packages/openai_vision.lpk"
  install_package "pacote/packages/openai_image.lpk"
  install_package "pacote/packages/openai_voice.lpk"
  install_package "pacote/packages/openai_industrial.lpk"
  install_package "pacote/packages/openai_graphic.lpk"
  install_package "pacote/packages/openai_agent.lpk"
  install_package "pacote/packages/openai_graph.lpk"
  install_package "pacote/packages/openai_rag.lpk"
  install_package "pacote/packages/openai_mcp.lpk"
  install_package "pacote/packages/openai_a2a.lpk"
  install_package "pacote/packages/openai_evaluation.lpk"
  install_package "pacote/packages/openai_observability.lpk"
  install_package "pacote/packages/openai_simulation.lpk"
  install_package "pacote/packages/openai_files.lpk"
}

install_all() {
  install_recommended
  install_package "pacote/packages/openai_agents.lpk"
  install_package "pacote/packages/openai_aidbase.lpk"
  install_package "pacote/packages/openai_dbase.lpk"
  install_package "pacote/packages/openai_hardware.lpk"
  install_package "pacote/packages/openai_project.lpk"
}

case "$MODE" in
  -h|--help|help) show_help; exit 0 ;;
esac

find_lazbuild
if [[ -z "$LAZBUILD" || ! -x "$LAZBUILD" ]]; then
  echo "[ERROR] lazbuild was not found or is not executable."
  show_help
  exit 1
fi

echo "TCHATGPT - Lazarus/Free Pascal installer"
echo "Repository: $ROOT_DIR"
echo "lazbuild:   $LAZBUILD"
echo "Mode:       $MODE"

if command -v lazres >/dev/null 2>&1; then
  lazres "$ROOT_DIR/pacote/AI Project/aiproject_icon.lrs" "$ROOT_DIR/pacote/AI Project/TAIProject.png" "$ROOT_DIR/pacote/AI Project/TAIProjectLLMConfig.png" "$ROOT_DIR/pacote/AI Project/TAIProjectStorage.png" || true
fi

case "$MODE" in
  core) install_package "pacote/packages/openai_core.lpk" ;;
  recommended) install_recommended ;;
  all) install_all ;;
  *) echo "[ERROR] Invalid mode: $MODE"; show_help; exit 1 ;;
esac

echo "Rebuilding Lazarus IDE..."
"$LAZBUILD" --build-ide || FAILED=1
exit "$FAILED"
