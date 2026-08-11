# Instaladores da Lazarus AI Suite

O instalador resolve dependências de compilação, registra os pacotes na ordem
topológica, valida o runtime HTTPS e reconstrói a IDE. A definição única fica em
`installer/dependencies.json`; a CI usa o mesmo manifesto.

## Dependências externas

| Dependência | Resolução |
|---|---|
| ZeosLib | Detectada por `ZEOS_ROOT`/Lazarus ou baixada do espelho público mantido do projeto |
| CEF4Delphi | Detectada por `CEF4DELPHI_ROOT`/Lazarus ou baixada do repositório oficial |
| GLScene Lazarus | Detectada por `GLSCENE_ROOT`; obrigatória somente para `openai_industrial` |

O Core depende realmente de Zeos (`TDBTokenList` e `TGroupResponse`). O CEF é
preparado para os componentes e samples Chromium. GLScene é usado pelo
componente de braço robótico do pacote Industrial.

## Uso

```text
install_components.bat recommended
install_components.bat all C:\lazarus\lazbuild.exe
./install_components.sh recommended /usr/bin/lazbuild
```

Variáveis opcionais: `ZEOS_ROOT`, `CEF4DELPHI_ROOT` e `GLSCENE_ROOT`.

Instaladores completos por plataforma:

- `windows-x86/install.bat`;
- `windows-x64/install.bat`;
- `linux-x64/install.sh`;
- `linux-arm64/install.sh`;
- `linux-armhf/install.sh`.

Os instaladores Windows copiam o OpenSSL 3 da arquitetura correta. Linux x86,
x64, ARMHF e ARM64 usam as bibliotecas OpenSSL da distribuição e recusam a
instalação quando `ssl` ou `crypto` não estão disponíveis.

Os ZIPs finais e runtimes externos grandes devem ser publicados em Releases.
