# OpenCV Runtime

Esta pasta é reservada para o runtime nativo do OpenCV usado pelos componentes e demos da Lazarus AI Suite.

O backend Python do `TAIOpenCV` continua usando `opencv-python` instalado no ambiente Python. Esta pasta é destinada ao backend nativo, baseado em DLL/SO.

## Estrutura esperada

```text
runtime/opencv/
  manifest.json
  windows/
    x86/bin/
    x64/bin/
  linux/
    x64/lib/
    arm64/lib/
    armhf/lib/
```

## Bibliotecas esperadas

Windows:

```text
opencv_world*.dll
```

Linux:

```text
libopencv_world.so*
```

## Regras

- Não misturar binários 32 e 64 bits.
- Não misturar binários Windows e Linux.
- Não copiar DLLs para `System32`.
- Não depender exclusivamente de `PATH`.
- Os demos devem localizar automaticamente a biblioteca correta pela plataforma.
- Usuários avançados podem informar caminho manual.

## Distribuição dos binários

A recomendação principal é publicar DLLs/SOs grandes em GitHub Releases ou instaladores por plataforma.

Caso sejam versionados diretamente no Git, cada pasta deve conter apenas os binários da arquitetura correspondente e um README informando versão, origem e licença.

Veja também:

```text
DOC/OPENCV_RUNTIME_SPEC.md
```
