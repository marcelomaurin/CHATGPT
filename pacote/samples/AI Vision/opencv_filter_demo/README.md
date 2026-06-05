# TAIOpenCV Filter Demo

This sample demonstrates how to use the `TAIOpenCV` component in a Lazarus graphical application.

## Features

- OpenCV SelfTest
- Load image
- Read image information
- Apply basic filters
- Preview original image
- Preview processed image
- Save processed output
- Show logs and errors

## Supported filters

- None
- Gray
- Blur
- Canny
- Threshold
- Resize

## Required backend

The current implementation uses Python Process.

Install dependencies:

```bash
pip install opencv-python numpy
```

## Included files

- `opencv_filter_demo.lpi`
- `opencv_filter_demo.lpr`
- `main.pas`
- `main.lfm`
- `sample.jpg`
- `README.md`

## Worker

The OpenCV worker is located at:

```text
pacote/python/aiopencv_worker.py
```

The component searches for the worker relative to the executable and package folders.

## Testing the worker manually

From the sample folder:

```bash
python ../../../python/aiopencv_worker.py --action selftest
python ../../../python/aiopencv_worker.py --action info --input sample.jpg
python ../../../python/aiopencv_worker.py --action gray --input sample.jpg --output output/sample_gray.jpg
python ../../../python/aiopencv_worker.py --action canny --input sample.jpg --output output/sample_canny.jpg --canny1 100 --canny2 200
```

## How to run

1. Open `opencv_filter_demo.lpi` in Lazarus.
2. Compile the project.
3. Run the application.
4. Click `SelfTest`.
5. Load an image.
6. Select a filter.
7. Click `Process`.
8. Preview and save the processed image.

## Status

Experimental/Beta.

## Busca Inteligente de Runtime OpenCV

Este demo utiliza uma busca inteligente e padronizada para carregar a biblioteca nativa do OpenCV (via `TAIOpenCV` com backend `Native DLL`), priorizando o runtime local incluído no repositório antes das pastas do sistema.

### Regras de Busca

O sistema detecta automaticamente o sistema operacional e a arquitetura do processo ativo (ex: `windows/x64`, `linux/arm64`) e busca as DLLs/SOs correspondentes na pasta:
`runtime/opencv/<sistema_operacional>/<arquitetura>/bin/` (ou `lib/` no Linux).

Caso as bibliotecas nativas não sejam encontradas ou falhem ao carregar:
1. O demo exibe uma mensagem clara de aviso nos logs detalhando todos os caminhos testados.
2. O backend faz fallback automático e transparente para a execução via **Python Process**, permitindo que o demo funcione sem quebras.

