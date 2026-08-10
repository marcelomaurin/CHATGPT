# Linux ARMHF Runtime

Use este perfil em Linux 32-bit ARMv7/ARMHF, especialmente Raspberry Pi OS 32 bits.

Este é um perfil `lite`: prioriza llama.cpp e whisper.cpp CPU. NumPy/OpenCV devem preferencialmente vir dos pacotes da distribuição.

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

F5-TTS, MediaPipe e outros runtimes Python pesados ficam fora do perfil ARMHF básico.
