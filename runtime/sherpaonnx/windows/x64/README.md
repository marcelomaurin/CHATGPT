# Sherpa-ONNX Runtime - Windows x64

Este diretório armazena os binários oficiais do `sherpa-onnx` para Windows 64 bits.

## Conteúdo esperado

- `bin/` com executáveis e DLLs
- `lib/` com `sherpa-onnx-c-api.dll` e bibliotecas de importação
- `include/` com os headers da C API

## Uso com o componente

O componente `TAISpeechRecognizer` pode apontar `SherpaLibraryPath` diretamente para:

```text
runtime/sherpaonnx/windows/x64/lib/sherpa-onnx-c-api.dll
```

ou para a mesma DLL copiada em `bin/`.

