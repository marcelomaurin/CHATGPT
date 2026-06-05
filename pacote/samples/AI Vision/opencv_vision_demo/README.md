# OpenCV Vision Demo

This sample demonstrates the combined usage of visual tracking and processing components (`TAIOpenCV`, `TAICameraCapture`, `TAIFrameProcessor`, `TAIFaceTracker`, and `TAIMotionTracker`) from the `openai_vision` package.

## Features

- Dynamic loading of OpenCV runtime.
- Simulated or real camera capturing.
- Real-time frame processing filters (Grayscale, Equalize).
- Simulated face and motion tracking between frames.
- Standardized logging system.

## How to Build & Run

1. Open this project folder in Lazarus.
2. Verify package `openai_vision` is available.
3. Build and run the project.
4. Click "Load OpenCV" to initialize the runtime.
5. Click "Start Camera" and activate tracking filters to see real-time log output.

## Busca Inteligente de Runtime OpenCV

Este demo utiliza uma busca inteligente e padronizada para carregar a biblioteca nativa do OpenCV (via `TAIOpenCV` com backend `Native DLL`), priorizando o runtime local incluído no repositório antes das pastas do sistema.

### Regras de Busca

O sistema detecta automaticamente o sistema operacional e a arquitetura do processo ativo (ex: `windows/x64`, `linux/arm64`) e busca as DLLs/SOs correspondentes na pasta:
`runtime/opencv/<sistema_operacional>/<arquitetura>/bin/` (ou `lib/` no Linux).

Caso as bibliotecas nativas não sejam encontradas ou falhem ao carregar:
1. O demo exibe uma mensagem clara de aviso nos logs detalhando todos os caminhos testados.
2. O backend faz fallback automático e transparente para a execução via **Python Process**, permitindo que o demo funcione sem quebras.
