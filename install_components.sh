#!/usr/bin/env bash
set -u

# ============================================================
# TCHATGPT - Lazarus package installer for Linux
# Author: Marcelo Maurin Martins
# Repository: https://github.com/marcelomaurin/CHATGPT
# ============================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-recommended}"
LAZBUILD="${2:-}"
FAILED=0

show_help() {
  cat <<'EOF'

TCHATGPT - Linux component installer

Usage:
  ./install_components.sh [mode] [path_to_lazbuild]

Modes:
  core         Installs only openai_core.lpk
  recommended  Installs the safest base set. Default.
  all          Installs all modular packages.

Examples:
  chmod +x install_components.sh
  ./install_components.sh
  ./install_components.sh core
  ./install_components.sh all
  ./install_components.sh recommended /usr/bin/lazbuild

EOF
}

find_lazbuild() {
  if [[ -n "$LAZBUILD" ]]; then
    return
  fi

  if command -v lazbuild >/dev/null 2>&1; then
    LAZBUILD="$(command -v lazbuild)"
    return
  fi

  for candidate in \
    "/usr/bin/lazbuild" \
    "/usr/local/bin/lazbuild" \
    "/opt/lazarus/lazbuild" \
    "$HOME/lazarus/lazbuild"; do
    if [[ -x "$candidate" ]]; then
      LAZBUILD="$candidate"
      return
    fi
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

  echo
  echo "------------------------------------------------------------"
  echo "Installing package: $pkg_rel"
  echo "------------------------------------------------------------"

  "$LAZBUILD" --add-package "$pkg"
  local rc=$?

  if [[ $rc -ne 0 ]]; then
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
  install_package "pacote/packages/openai_simulation.lpk"
  install_package "pacote/packages/openai_files.lpk"
}

install_all() {
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
  install_package "pacote/packages/openai_agents.lpk"
  install_package "pacote/packages/openai_agent.lpk"
  install_package "pacote/packages/openai_graph.lpk"
  install_package "pacote/packages/openai_simulation.lpk"
  install_package "pacote/packages/openai_files.lpk"
  install_package "pacote/packages/openai_aidbase.lpk"
  install_package "pacote/packages/openai_dbase.lpk"
  install_package "pacote/packages/openai_hardware.lpk"
  install_package "pacote/packages/openai_project.lpk"
}

case "$MODE" in
  -h|--help|help)
    show_help
    exit 0
    ;;
esac

find_lazbuild

if [[ -z "$LAZBUILD" || ! -x "$LAZBUILD" ]]; then
  echo
  echo "[ERROR] lazbuild was not found or is not executable."
  echo
  echo "Usage examples:"
  echo "  ./install_components.sh"
  echo "  ./install_components.sh core"
  echo "  ./install_components.sh all"
  echo "  ./install_components.sh recommended /usr/bin/lazbuild"
  echo
  exit 1
fi

echo
echo "============================================================"
echo "TCHATGPT - Component installer for Lazarus / Linux"
echo "============================================================"
echo "Repository path: $ROOT_DIR"
echo "lazbuild:       $LAZBUILD"
echo "Mode:           $MODE"
echo "============================================================"
echo

echo "Building AI Project icons..."
if command -v lazres >/dev/null 2>&1; then
  lazres "$ROOT_DIR/pacote/AI Project/aiproject_icon.lrs" "$ROOT_DIR/pacote/AI Project/TAIProject.png" "$ROOT_DIR/pacote/AI Project/TAIProjectLLMConfig.png" "$ROOT_DIR/pacote/AI Project/TAIProjectStorage.png"
elif [[ -x "/usr/bin/lazres" ]]; then
  /usr/bin/lazres "$ROOT_DIR/pacote/AI Project/aiproject_icon.lrs" "$ROOT_DIR/pacote/AI Project/TAIProject.png" "$ROOT_DIR/pacote/AI Project/TAIProjectLLMConfig.png" "$ROOT_DIR/pacote/AI Project/TAIProjectStorage.png"
elif [[ -x "/usr/lib/lazarus/default/tools/lazres" ]]; then
  /usr/lib/lazarus/default/tools/lazres "$ROOT_DIR/pacote/AI Project/aiproject_icon.lrs" "$ROOT_DIR/pacote/AI Project/TAIProject.png" "$ROOT_DIR/pacote/AI Project/TAIProjectLLMConfig.png" "$ROOT_DIR/pacote/AI Project/TAIProjectStorage.png"
fi
echo

case "$MODE" in
  core)
    install_package "pacote/packages/openai_core.lpk"
    ;;
  recommended)
    install_recommended
    ;;
  all)
    install_all
    ;;
  *)
    echo "[ERROR] Invalid mode: $MODE"
    show_help
    exit 1
    ;;
esac

echo
echo "============================================================"
if [[ $FAILED -eq 0 ]]; then
  echo "Installation commands finished successfully."
else
  echo "Installation finished with warnings or errors."
  echo "Review the messages above before using the components."
fi
echo
echo "------------------------------------------------------------"
echo "Rebuilding Lazarus IDE with installed packages..."
echo "------------------------------------------------------------"
"$LAZBUILD" --build-ide
rc=$?
if [[ $rc -ne 0 ]]; then
  echo "[ERROR] Lazarus IDE rebuild failed. Open Lazarus and rebuild manually."
  FAILED=1
else
  echo "[OK] Lazarus IDE rebuilt successfully."
fi
echo "============================================================"

exit "$FAILED"
