# CHATGPT-AI Runtime

Esta pasta define a estrutura de runtime externo controlado por plataforma para os componentes da Lazarus AI Suite que dependem de Python, OpenCV, NumPy ou bibliotecas nativas.

## Regra principal

O repositório Git deve conter apenas:

- templates;
- requirements;
- manifestos;
- scripts de instalação;
- documentação.

O Git **não deve** armazenar Python expandido, `venv`, `site-packages`, DLLs/SOs pesados ou ZIPs finais gerados.

Os pacotes prontos por arquitetura devem ser publicados em **GitHub Releases**.

## Plataformas previstas

| Plataforma | Arquitetura | Status |
|---|---|---|
| Windows | x64 | Suportado |
| Linux | x64 | Suportado |
| Linux | ARM64 | Experimental |
| Linux | ARMHF | Experimental |

## Instalação padrão

| Sistema | Caminho recomendado |
|---|---|
| Windows | `C:\CHATGPT-AI` |
| Linux root | `/opt/chatgpt-ai` |
| Linux usuário | `~/.local/share/chatgpt-ai` |

## Arquivo gerado na instalação

O instalador deve gerar:

```text
chatgpt_ai_runtime.ini
```

Esse arquivo será usado pelos componentes Lazarus, especialmente `TAIPythonRuntime`, para localizar Python, DLLs/SOs, pacotes e diretórios auxiliares.
