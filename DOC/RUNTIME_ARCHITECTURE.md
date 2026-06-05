# Runtime Architecture

A Lazarus AI Suite passa a usar um modelo de runtime externo controlado para componentes que dependem de Python ou bibliotecas nativas.

## Objetivo

Evitar que o usuário precise configurar manualmente Python, OpenCV, NumPy ou caminhos de DLL/SO para usar componentes como:

- TAIPythonRuntime
- TPythonConnector
- TAIOpenCV
- TYoloDetect
- TFaceDetection
- TCNNClassifier
- TLSTMPredictor

## Modelo adotado

O repositório contém a fábrica:

- código Lazarus;
- pacotes `.lpk`;
- templates;
- instaladores;
- requirements;
- documentação.

A aba GitHub Releases contém o produto pronto:

- ZIP por plataforma;
- runtime empacotado;
- scripts de instalação;
- checksums.

## Plataformas

| Plataforma | Arquitetura | Status |
|---|---|---|
| Windows | x64 | Suportado |
| Linux | x64 | Suportado |
| Linux | ARM64 | Experimental |
| Linux | ARMHF | Experimental |

## Princípio de isolamento

Não instalar DLLs em `System32` por padrão.
Não instalar `.so` em `/usr/lib` por padrão.

O runtime deve ficar em pasta isolada:

- Windows: `C:/CHATGPT-AI`
- Linux: `/opt/chatgpt-ai`
- Linux sem root: `~/.local/share/chatgpt-ai`

## Arquivo de configuração

O instalador gera:

```text
chatgpt_ai_runtime.ini
```

Esse arquivo deve ser lido pelos componentes Lazarus para localizar runtime, packages e bibliotecas.

## Regra para componentes

Componentes Python não devem procurar Python global diretamente.

Eles devem usar `TAIPythonRuntime` como fonte de configuração.

Cada componente dependente deve expor:

```pascal
property Runtime: TAIPythonRuntime;
property LastError: string;
function CheckDependencies: Boolean;
```
