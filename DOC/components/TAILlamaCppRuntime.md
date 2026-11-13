# TAILlamaCppRuntime

`TAILlamaCppRuntime` localiza e valida o runtime Windows x64 do llama.cpp.
O componente fica na aba **AI LlamaCpp** da paleta do Lazarus.

## Propriedades

- `RuntimeRoot`: raiz que contem `bin`, `dll` e `llamacpp.version`.
- `BinPath`: pasta dos executaveis `llama-cli.exe`, `llama-server.exe` e
  `llama-quantize.exe`.
- `LibraryPath`: pasta das DLLs do llama.cpp e do bridge nativo.
- `LastRuntimeError`: ultimo erro de validacao ou execucao.

## Metodos principais

- `ValidateRuntime`: valida diretorios, CLI, servidor e DLLs obrigatorias.
- `ValidateLibraries`: valida somente as DLLs necessarias.
- `GetVersion`: executa `llama-cli.exe --version`.
- `LoadVersionInfo`: le os dados fixados em `llamacpp.version`.
- `GetCliPath`, `GetServerPath`, `GetQuantizePath`: retornam caminhos
  absolutos das ferramentas.

## Exemplo

```pascal
if LlamaRuntime.ValidateRuntime then
  Memo1.Lines.Text := LlamaRuntime.GetVersion
else
  Memo1.Lines.Text := LlamaRuntime.LastRuntimeError;
```

O runtime distribuido neste projeto e CPU AVX2, x86_64, fixado no llama.cpp
b5200. Modelos GGUF devem permanecer fora do Git.
