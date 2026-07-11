# Sherpa-ONNX Runtime

Este diretório contém o runtime oficial do `sherpa-onnx` para Windows x64.

## Estrutura

- `windows/x64/bin/`: executáveis e DLLs do release oficial para Windows 64 bits.
- `windows/x86/bin/`: executáveis e DLLs do release oficial para Windows 32 bits.
- `macos/universal2/lib/`: bibliotecas dinâmicas do release oficial para macOS Intel e Apple Silicon.
- `windows/x64/lib/`: DLLs de C API e bibliotecas de importação.
- `windows/x64/include/`: headers da C API.

## Arquivos principais para o Lazarus

- `sherpa-onnx-c-api.dll`
- `onnxruntime.dll`
- `onnxruntime_providers_shared.dll`
- `libsherpa-onnx-c-api.dylib`
- `libonnxruntime.dylib`

## Modelos

Os modelos ONNX continuam separados do runtime.
Para o backend `offline.sherpaonnx`, configure `SherpaEncoderFile`, `SherpaDecoderFile` e `SherpaTokensFile` com os arquivos do modelo correspondente.

