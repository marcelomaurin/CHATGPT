#!/bin/bash
TARGET="$1"
if [ -z "$TARGET" ]; then
    echo "Uso: ./copy_chromium_runtime_arm64.sh /caminho/do/sample/bin"
    exit 1
fi
mkdir -p "$TARGET"
cp -r "$(dirname "$0")/../../linux/arm64/bin/"* "$TARGET/"
chmod +x "$TARGET"/*.so
if [ -f "$TARGET/chrome-sandbox" ]; then
    chmod +x "$TARGET/chrome-sandbox"
    # sudo chown root:root "$TARGET/chrome-sandbox"
    # sudo chmod 4755 "$TARGET/chrome-sandbox"
fi
echo "Runtime Linux arm64 copiado para $TARGET e permissoes ajustadas."
