# Suporte a treinamento no llama.cpp b5200

## Versao verificada

- Tag: `b5200`
- Commit: `c0a97b762e5ec767dc414f0dc4979befd4c09a52`
- Arquitetura do runtime: `x86_64`
- Pacote oficial verificado: `llama-b5200-bin-win-avx2-x64.zip`
- SHA-256 do pacote: `BD37C76F6986AE8A3E64AE9929E1103A161C0B72837BA3925E9628D8D868823A`

## Resultado da verificacao

O commit fixado nao contem uma ferramenta utilizavel para treinar ou fazer
fine-tuning de modelos. A verificacao cobriu:

1. os alvos CMake e os fontes C/C++ do repositorio;
2. os diretorios em `examples/`;
3. os executaveis entregues no pacote oficial Windows x64 AVX2.

Nao foi encontrado alvo ou executavel `llama-train`, `llama-finetune` ou
equivalente. Consequentemente, nao existem parametros, tipos de treinamento
ou familias de modelos que possam ser expostos com seguranca nesta integracao.

O diretorio `examples/export-lora` e o executavel `llama-export-lora.exe` nao
treinam adapters. Eles recebem um modelo base e um ou mais adapters LoRA ja
treinados e geram um modelo mesclado em F16.

## Decisao de implementacao

Conforme a regra da tarefa LLAMA-160, a etapa de treinamento foi interrompida.
Por isso, nesta versao nao sao fornecidos:

- `aillamacpptrainer.pas`;
- `TAILlamaCppTrainer`;
- `llama-finetune.exe` ou outro nome inventado;
- demo ou teste de treinamento.

Treinamento devera ser reavaliado somente ao atualizar a versao fixada do
llama.cpp ou ao integrar uma ferramenta externa real, versionada e testada.
