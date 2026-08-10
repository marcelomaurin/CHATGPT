# Ubuntu / Linux x64 Runtime

Perfil principal para Ubuntu/Debian em `x86_64`.

## Preparar a máquina

```bash
chmod +x runtime/linux-x64/*.sh
./runtime/linux-x64/install_prerequisites.sh
```

## Montar o runtime

```bash
./runtime/linux-x64/build_runtime.sh
./runtime/linux-x64/package_runtime.sh
```

Resultado:

```text
.runtime-dist/CHATGPT-AI-runtime-linux-x64.zip
.runtime-dist/SHA256SUMS-linux-x64.txt
```

## Instalar pela Release

```bash
./runtime/linux-x64/install_runtime.sh
```

Por padrão instala em:

```text
~/.local/share/chatgpt-ai
```

Para instalar em outro local:

```bash
CHATGPT_AI_HOME=/opt/chatgpt-ai ./runtime/linux-x64/install_runtime.sh
```

## Conteúdo do perfil

- `llama-server` e `llama-cli` quando gerado;
- `whisper-cli`;
- bootstrap Python local;
- NumPy;
- OpenCV headless;
- wrapper `pdftotext` usando `poppler-utils` do sistema;
- FFmpeg do sistema;
- validação do runtime.

## Validação

```bash
./runtime/linux-x64/validate_runtime.sh
```

## Instalador gráfico

Em uma máquina Ubuntu x64 com Lazarus instalado:

```bash
cd runtime/installer
./build_runtime_installer.sh
```

O script detecta `x86_64` e usa o modo `LinuxX64`, gerando:

```text
RuntimeInstaller_linux_x64
```
