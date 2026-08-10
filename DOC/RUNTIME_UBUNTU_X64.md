# CHATGPT-AI Runtime para Ubuntu Linux x64

## Alvo

Perfil para:

- Ubuntu x86_64;
- Debian x86_64;
- distribuições compatíveis com `apt-get`.

## Dependências de sistema

O script instala:

```bash
sudo apt-get install -y \
  ca-certificates curl unzip zip git build-essential cmake pkg-config \
  python3 python3-venv python3-pip python3-dev \
  libopenblas-dev libopenblas0 libssl-dev libsndfile1 \
  ffmpeg poppler-utils
```

## Runtime produzido

O bundle contém:

```text
bin/
  llama-server
  llama-cli
  whisper-cli
  python3
  pdftotext

python/
  bootstrap.sh
  requirements-linux-x64.txt

models/
scripts/
  validate_runtime.sh
BUILD_INFO.txt
```

O ambiente Python é criado na máquina de destino, em `python/venv`, na primeira execução de `bin/python3`.

## Construção

```bash
chmod +x runtime/linux-x64/*.sh
./runtime/linux-x64/install_prerequisites.sh
./runtime/linux-x64/build_runtime.sh
./runtime/linux-x64/package_runtime.sh
```

Resultado:

```text
.runtime-dist/CHATGPT-AI-runtime-linux-x64.zip
.runtime-dist/SHA256SUMS-linux-x64.txt
```

## Release

O ZIP deve ser publicado no GitHub Release com o nome:

```text
CHATGPT-AI-runtime-linux-x64.zip
```

O hash deve ser incorporado ao arquivo comum:

```text
SHA256SUMS.txt
```

O `runtime/runtime_manifest.ini` já aponta `linux-x64` para `releases/latest/download`.

## Instalação

```bash
./runtime/linux-x64/install_runtime.sh
```

O instalador:

1. valida que a máquina é Linux x64;
2. baixa o ZIP da Release;
3. baixa `SHA256SUMS.txt`;
4. confere SHA256;
5. faz backup do `chatgpt_ai_runtime.ini` anterior;
6. extrai o runtime;
7. corrige permissões;
8. gera novo `chatgpt_ai_runtime.ini`;
9. executa a validação.

## Caminho padrão

```text
~/.local/share/chatgpt-ai
```

Para instalação compartilhada:

```bash
CHATGPT_AI_HOME=/opt/chatgpt-ai ./runtime/linux-x64/install_runtime.sh
```

## Arquivo de configuração

```ini
[runtime]
platform=linux-x64
root=/home/user/.local/share/chatgpt-ai

[tools]
python=/home/user/.local/share/chatgpt-ai/bin/python3
llama_server=/home/user/.local/share/chatgpt-ai/bin/llama-server
whisper=/home/user/.local/share/chatgpt-ai/bin/whisper-cli
pdftotext=/home/user/.local/share/chatgpt-ai/bin/pdftotext
ffmpeg=/usr/bin/ffmpeg
```

## Instalador gráfico Lazarus

O projeto `runtime/installer/runtime_installer.lpi` possui o modo:

```text
LinuxX64
```

Compilação automática:

```bash
cd runtime/installer
./build_runtime_installer.sh
```

Saída:

```text
RuntimeInstaller_linux_x64
```
