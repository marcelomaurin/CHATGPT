# Whisper.cpp Runtime

Este diretório contém o runtime oficial do `whisper.cpp` para Windows x64.

## Estrutura

- `windows/x64/bin/`: executáveis e DLLs do release oficial.

## Executavel principal

- `whisper-cli.exe`
- `main.exe` como fallback legado

## Modelos

Os modelos de transcrição não fazem parte deste pacote.
O componente Lazarus deve apontar `WhisperCppModel` para um arquivo de modelo compatível no disco.

