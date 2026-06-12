# MediaPipe Pose Bridge Compilation Guide

Este diretório contém os códigos-fonte da DLL/SO de integração entre o Lazarus (FPC) e o SDK C++ do Google MediaPipe, além dos scripts de compilação automatizados para Windows e Linux.

## Estrutura de Arquivos

- `bridge.h`: Definições da API C/C++ exposta (ABI compatível com Lazarus/Delphi).
- `bridge.cpp`: Implementação em C++ (para compilar linkando com a biblioteca real do MediaPipe C++ SDK).
- `bridge.lpr`: Implementação alternativa em Pascal/FPC (usada como stub de validação/mock interno da DLL).
- `Makefile`: Script para compilação automatizada em ambiente Linux/POSIX.
- `Makefile.bat`: Script para compilação automatizada em ambiente Windows.

---

## Compilação no Windows (`Makefile.bat`)

O arquivo `Makefile.bat` compila a biblioteca e a copia automaticamente para as pastas corretas de destino.

### Compilando o stub em Pascal (Padrão)
Para compilar utilizando o Free Pascal Compiler (FPC):
```cmd
Makefile.bat pascal
```

### Compilando a integração em C++
Para compilar a versão em C++ (requer o ambiente MSVC configurado no PATH com `cl.exe`):
```cmd
Makefile.bat cpp
```

### Destino de Cópia Automática
O script detecta a arquitetura do compilador (x86 ou x64) e copia a DLL para:
- `..\windows\` (Raiz do runtime Windows)
- `..\windows\x86\` ou `..\windows\x64\` (Subpasta correspondente)
- Pasta de demonstração do projeto (se existir)

---

## Compilação no Linux (`Makefile`)

O arquivo `Makefile` gerencia a compilação utilizando ferramentas Unix.

### Compilando o stub em Pascal (Padrão)
```bash
make pascal
```

### Compilando a integração em C++
```bash
make cpp
```

### Limpando arquivos temporários
```bash
make clean
```

### Destino de Cópia Automática
O Makefile detecta a arquitetura do sistema e copia a biblioteca `.so` para:
- `../linux/` (Raiz do runtime Linux)
- `../linux/x86/` ou `../linux/x64/` (Subpasta correspondente)
