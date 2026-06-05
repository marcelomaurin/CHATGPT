# OpenCV Runtime Binaries

Este diretório contém os manifestos e subpastas para o runtime embarcado do OpenCV de acordo com o sistema operacional e a arquitetura.

## Estrutura de subpastas

- `windows/x86/bin/`: DLLs do OpenCV para processos Windows 32 bits.
- `windows/x64/bin/`: DLLs do OpenCV para processos Windows 64 bits.
- `linux/x64/lib/`: Bibliotecas compartilhadas `.so` do OpenCV para Linux x64.
- `linux/arm64/lib/`: Bibliotecas compartilhadas `.so` para Linux ARM64 (como Raspberry Pi OS 64 bits).
- `linux/armhf/lib/`: Bibliotecas compartilhadas `.so` para Linux ARM 32 bits (como Raspberry Pi OS 32 bits).

## Como adicionar as bibliotecas binárias

1. Baixe a biblioteca `opencv_world` correspondente para o seu sistema e arquitetura.
2. Copie os arquivos da biblioteca para as respectivas subpastas `bin` ou `lib`.
3. Certifique-se de que os arquivos batam com o mapeamento e os nomes definidos no `manifest.json`.
