# CHATGPT-AI Runtime para Linux ARM

## Escopo

O runtime ARM é dividido em dois perfis porque ARM64 e ARMHF possuem ecossistemas de binários Python diferentes.

### Linux ARM64 / AArch64

Perfil principal.

Inclui no bundle:

- `llama-server` compilado nativamente;
- `llama-cli` quando produzido pelo build;
- `whisper-cli` compilado nativamente;
- bootstrap Python relocável;
- `requirements-arm64.txt`;
- wrapper `bin/python3`;
- wrapper `bin/pdftotext`;
- script de validação.

Dependências de sistema recomendadas:

```bash
sudo apt-get install -y \
  ca-certificates curl unzip zip git build-essential cmake pkg-config \
  python3 python3-venv python3-pip \
  libopenblas-dev libopenblas0 libssl-dev libsndfile1 \
  ffmpeg poppler-utils
```

O ambiente Python é criado na máquina de destino. O bundle não contém um `venv` pré-criado.

Pacotes Python básicos do perfil ARM64:

```text
numpy
opencv-python-headless
```

## Linux ARMHF / armv7

Perfil `lite`.

Inclui:

- `llama-server` CPU;
- `llama-cli` quando disponível;
- `whisper-cli` CPU;
- wrapper Python;
- wrapper Poppler;
- script de validação.

Para ARMHF, NumPy e OpenCV devem preferencialmente vir dos pacotes da distribuição:

```bash
sudo apt-get install -y \
  python3 python3-venv python3-pip python3-numpy python3-opencv \
  ffmpeg poppler-utils
```

O `venv` é criado com `--system-site-packages` para reutilizar os módulos ARMHF fornecidos pela distribuição.

F5-TTS, MediaPipe e outros runtimes Python pesados não fazem parte do perfil ARMHF básico.

## Scripts ARM64

```text
runtime/linux-arm64/install_prerequisites.sh
runtime/linux-arm64/build_runtime.sh
runtime/linux-arm64/package_runtime.sh
runtime/linux-arm64/install_runtime.sh
runtime/linux-arm64/validate_runtime.sh
```

### Criar bundle ARM64

```bash
chmod +x runtime/linux-arm64/*.sh
./runtime/linux-arm64/install_prerequisites.sh
./runtime/linux-arm64/build_runtime.sh
./runtime/linux-arm64/package_runtime.sh
```

Resultado:

```text
.runtime-dist/CHATGPT-AI-runtime-linux-arm64.zip
.runtime-dist/SHA256SUMS-arm64.txt
```

## Scripts ARMHF

```text
runtime/linux-armhf/install_prerequisites.sh
runtime/linux-armhf/build_runtime.sh
runtime/linux-armhf/package_runtime.sh
runtime/linux-armhf/install_runtime.sh
runtime/linux-armhf/validate_runtime.sh
```

### Criar bundle ARMHF

```bash
chmod +x runtime/linux-armhf/*.sh
./runtime/linux-armhf/install_prerequisites.sh
./runtime/linux-armhf/build_runtime.sh
./runtime/linux-armhf/package_runtime.sh
```

Resultado:

```text
.runtime-dist/CHATGPT-AI-runtime-linux-armhf.zip
.runtime-dist/SHA256SUMS-armhf.txt
```

## Publicação

Antes de publicar o Release, unir os hashes dos bundles em um único arquivo:

```bash
cat .runtime-dist/SHA256SUMS-arm64.txt \
    .runtime-dist/SHA256SUMS-armhf.txt \
    > .runtime-dist/SHA256SUMS.txt
```

Publicar no mesmo GitHub Release:

```text
CHATGPT-AI-runtime-linux-arm64.zip
CHATGPT-AI-runtime-linux-armhf.zip
SHA256SUMS.txt
```

## Instalação shell

ARM64:

```bash
./runtime/linux-arm64/install_runtime.sh
```

ARMHF:

```bash
./runtime/linux-armhf/install_runtime.sh
```

Por padrão o runtime é instalado em:

```text
~/.local/share/chatgpt-ai
```

Para alterar:

```bash
CHATGPT_AI_HOME=/opt/chatgpt-ai ./runtime/linux-arm64/install_runtime.sh
```

## Instalador gráfico Lazarus

`runtime/installer/runtime_installer.lpi` possui os modos:

```text
LinuxARM64 -> RuntimeInstaller_arm64
LinuxARMHF -> RuntimeInstaller_armhf
```

Em uma máquina ARM com Lazarus instalado:

```bash
cd runtime/installer
./build_runtime_installer.sh
```

O script detecta `aarch64` ou `armv7` e escolhe automaticamente o modo adequado.

## Runtime INI

O resultado mantém o contrato comum:

```ini
[runtime]
platform=linux-arm64
root=/home/user/.local/share/chatgpt-ai

[tools]
python=/home/user/.local/share/chatgpt-ai/bin/python3
llama_server=/home/user/.local/share/chatgpt-ai/bin/llama-server
whisper=/home/user/.local/share/chatgpt-ai/bin/whisper-cli
pdftotext=/home/user/.local/share/chatgpt-ai/bin/pdftotext
```

Os componentes devem continuar acessando os caminhos através da infraestrutura de runtime do projeto, sem hardcode específico para ARM.
