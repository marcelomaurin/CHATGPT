# Runtime llama.cpp para Windows x64

Este diretorio contem o runtime CPU AVX2 do llama.cpp b5200 usado pelo package
`openai_llamacpp` e pelos samples da aba **AI LlamaCpp**.

## Arquivos distribuidos

Em `bin/`:

- `llama-cli.exe`: diagnostico de versao e inferencia por linha de comando;
- `llama-server.exe`: servidor HTTP compativel com a API OpenAI;
- `llama-quantize.exe`: quantizacao de modelos GGUF.

Em `dll/`:

- `chatgpt_llama_bridge.dll`: bridge nativo usado pelos componentes Lazarus;
- `llama.dll`;
- `ggml.dll`;
- `ggml-base.dll`;
- `ggml-cpu.dll`;
- DLLs auxiliares entregues no pacote oficial b5200 e necessarias aos
  executaveis que as utilizam.

O arquivo `llamacpp.version` registra versao, commit, arquitetura, backend,
asset oficial e SHA-256.

## Instalacao

Mantenha a estrutura `bin/` e `dll/`. Configure `TAILlamaCppRuntime.RuntimeRoot`
para este diretorio, ou copie a estrutura para o local de runtime resolvido
pelo `openai_core`.

O backend e somente CPU AVX2. O Windows deve ter o Microsoft Visual C++
Redistributable 2015-2022 x64 instalado. CUDA e Vulkan nao fazem parte deste
runtime.

## Modelos

Modelos e adapters usam o formato GGUF e nao sao distribuidos neste repositorio.
Armazene-os, por exemplo, em:

```text
%LOCALAPPDATA%\Maurinsoft\CHATGPT\models\
```

Nao adicione modelos grandes ao Git.

## Origem verificavel

- Release: `b5200`
- Commit: `c0a97b762e5ec767dc414f0dc4979befd4c09a52`
- Asset: `llama-b5200-bin-win-avx2-x64.zip`
- SHA-256: `BD37C76F6986AE8A3E64AE9929E1103A161C0B72837BA3925E9628D8D868823A`
