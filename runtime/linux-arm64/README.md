# Linux ARM64 Runtime

Use este perfil em `aarch64`/ARM64, incluindo Raspberry Pi OS 64 bits, Debian ARM64 e Ubuntu ARM64.

## Preparar a máquina

```bash
chmod +x *.sh
./install_prerequisites.sh
```

## Montar o bundle para Release

```bash
./build_runtime.sh
./package_runtime.sh
```

## Instalar a partir do GitHub Release

```bash
./install_runtime.sh
```

## Validar

```bash
./validate_runtime.sh
```

O perfil ARM64 inclui llama.cpp, whisper.cpp e bootstrap local de Python com NumPy e OpenCV headless.
