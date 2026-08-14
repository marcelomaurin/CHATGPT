# Instaladores da Lazarus AI Suite

O instalador resolve dependências de compilação, registra os pacotes na ordem
topológica, valida o runtime HTTPS e reconstrói a IDE. A definição única fica em
`installer/dependencies.json`; a CI usa o mesmo manifesto.

## Requisito do Python

Os instaladores exigem Python 3.8 ou superior e recusam Python 2. No Windows, o
`install_components.bat` procura o interpretador nesta ordem:

1. executável informado pela variável `PYTHON_EXE`;
2. launcher `py -3`;
3. comando `python3`;
4. comando `python`, desde que seja realmente Python 3.8 ou superior.

O Windows 7 SP1 deve usar o Python 3.8.10, última versão da série com instalador
compatível com esse sistema. Durante a instalação, habilite o Python Launcher e
a inclusão no `PATH`.

Quando o Python 3 estiver fora do `PATH`, informe o executável antes de instalar:

```bat
set "PYTHON_EXE=C:\Python38\python.exe"
install_components.bat recommended
```

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

Variáveis opcionais: `PYTHON_EXE`, `ZEOS_ROOT`, `CEF4DELPHI_ROOT` e
`GLSCENE_ROOT`.

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
