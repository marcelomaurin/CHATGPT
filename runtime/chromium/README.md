# Chromium Embedded Framework (CEF) Runtimes

Este diretório centraliza os binários em tempo de execução necessários para as aplicações que utilizam o CEF4Delphi no ecossistema CHATGPT.

## Estrutura
- `windows/win32`: Runtime para Windows 32 bits.
- `windows/win64`: Runtime para Windows 64 bits.
- `linux/x64`: Runtime para Linux 64 bits.
- `linux/arm32`: Runtime para Linux ARM 32 bits (ex: Raspberry Pi).
- `linux/arm64`: Runtime para Linux ARM 64 bits.
- `tools/`: Scripts para automatizar a cópia das bibliotecas para a pasta de saída do seu executável.

> **Nota:** Os binários em si (DLLs, `.so`, arquivos `.pak`) não estão sob controle de versão do Git devido ao seu grande tamanho. Eles devem ser baixados usando os scripts de instalação apropriados, e armazenados dentro da subpasta `bin/` de cada arquitetura.
