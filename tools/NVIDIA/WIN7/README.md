# NVIDIA / Windows 7 / GTX 1070

Esta pasta documenta a instalação de driver NVIDIA e CUDA para uma máquina legada com **Windows 7 64-bit** e **GeForce GTX 1070**.

> Importante: os instaladores proprietários da NVIDIA **não são incluídos neste repositório**. Eles devem ser baixados diretamente dos canais oficiais da NVIDIA para respeitar licença, integridade, tamanho dos arquivos e atualização de segurança.

---

## Estrutura

```text
tools/NVIDIA/WIN7/
  README.md
  drivers/README.md
  cuda/README.md
  scripts/check_cuda_win7.bat
```

---

## Hardware alvo

```text
GPU: NVIDIA GeForce GTX 1070
Arquitetura: Pascal
Sistema: Windows 7 64-bit / SP1 recomendado
Uso previsto: ambiente legado para testes locais com CUDA
```

---

## Ordem recomendada de instalação

1. Instalar/atualizar Windows 7 SP1.
2. Instalar atualizações básicas do sistema e certificados.
3. Instalar o driver NVIDIA compatível com Windows 7 64-bit e GTX 1070.
4. Reiniciar o computador.
5. Instalar CUDA Toolkit legado compatível com Windows 7.
6. Reiniciar novamente.
7. Validar com `nvidia-smi` e `nvcc --version`.

---

## Driver NVIDIA

Baixe sempre pelo site oficial:

```text
https://www.nvidia.com/Download/index.aspx
```

Parâmetros sugeridos na busca manual:

```text
Product Type: GeForce
Product Series: GeForce 10 Series
Product: GeForce GTX 1070
Operating System: Windows 7 64-bit
Download Type: Game Ready Driver ou Studio Driver, conforme disponível
Language: Português (Brazil) ou English (US)
```

Guarde o instalador localmente em:

```text
tools/NVIDIA/WIN7/drivers/
```

Não versionar o `.exe` no Git.

---

## CUDA Toolkit

Para Windows 7, use uma versão legada do CUDA Toolkit.

Página oficial do CUDA 10.2 archive:

```text
https://developer.nvidia.com/cuda-10.2-download-archive
```

Parâmetros sugeridos:

```text
Operating System: Windows
Architecture: x86_64
Version: 7
Installer Type: exe (local) ou exe (network), conforme disponível
```

Guarde o instalador localmente em:

```text
tools/NVIDIA/WIN7/cuda/
```

Não versionar o `.exe` no Git.

---

## Validação pós-instalação

Após instalar driver e CUDA, abra `cmd.exe` e rode:

```bat
nvidia-smi
nvcc --version
```

Também pode executar:

```bat
tools\NVIDIA\WIN7\scripts\check_cuda_win7.bat
```

---

## Observações importantes

* Windows 7 é um sistema legado e sem suporte geral atual.
* Drivers e toolkits compatíveis podem estar em arquivos legados da NVIDIA.
* Não use Windows 7 para ambiente conectado à internet sem controle de segurança.
* Para IA moderna, Windows 10/11 ou Linux são opções mais seguras e compatíveis.
* A GTX 1070 pode executar CUDA, mas bibliotecas modernas de IA podem exigir versões mais recentes de driver, CUDA, cuDNN e sistema operacional.

---

## O que esta pasta contém

Esta pasta contém **documentação, instruções e scripts de validação**.

Ela não contém:

```text
*.exe
*.msi
*.zip de drivers
instaladores CUDA
pacotes redistribuíveis proprietários
```
