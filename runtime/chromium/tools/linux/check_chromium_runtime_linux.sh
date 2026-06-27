#!/bin/bash
TARGET="$1"
if [ -z "$TARGET" ]; then
    echo "Uso: ./check_chromium_runtime_linux.sh /caminho/do/sample/bin"
    exit 1
fi
if [ ! -f "$TARGET/libcef.so" ]; then
    echo "[ERRO] libcef.so ausente em $TARGET"
    exit 1
fi
echo "Runtime basico validado no destino."
