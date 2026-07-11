# Sherpa-ONNX Runtime - macOS

Este diretório armazena o runtime oficial do `sherpa-onnx` para macOS.

## Estrutura

- `universal2/lib/`: bibliotecas dinâmicas para Intel e Apple Silicon.

## Arquivos principais

- `libsherpa-onnx-c-api.dylib`
- `libsherpa-onnx-cxx-api.dylib`
- `libonnxruntime.dylib`

## Observação

O pacote oficial aqui instalado é `universal2`, então cobre máquinas Intel e Apple Silicon sem separar duas pastas distintas.

