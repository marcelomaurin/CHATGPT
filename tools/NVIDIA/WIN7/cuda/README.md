# CUDA Toolkit — Windows 7 / GTX 1070

Coloque nesta pasta, localmente, o instalador do CUDA Toolkit compatível com **Windows 7 64-bit**.

## Versão recomendada para ambiente legado

Para Windows 7, use CUDA Toolkit legado, especialmente CUDA 10.2 quando precisar manter compatibilidade com esse sistema.

Página oficial:

```text
https://developer.nvidia.com/cuda-10.2-download-archive
```

Configuração sugerida:

```text
Operating System: Windows
Architecture: x86_64
Version: 7
Installer Type: exe (local)
```

## Instalação recomendada

1. Instale primeiro o driver NVIDIA.
2. Reinicie.
3. Instale o CUDA Toolkit.
4. Reinicie.
5. Abra `cmd.exe`.
6. Teste:

```bat
nvcc --version
nvidia-smi
```

## Observação sobre IA moderna

Mesmo com CUDA instalado, frameworks modernos podem não suportar Windows 7 ou CUDA legado.

Para IA moderna, normalmente é melhor usar:

```text
Windows 10/11
Linux recente
CUDA mais novo
Drivers atuais
```

## Não versionar instaladores

Não subir arquivos como:

```text
cuda_*.exe
*.msi
*.zip
```

Baixe sempre diretamente da NVIDIA.
