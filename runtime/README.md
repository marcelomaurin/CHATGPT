# CHATGPT-AI Runtime

Esta pasta define a estrutura de runtime externo controlado por plataforma para os componentes da Lazarus AI Suite que dependem de Python, OpenCV, NumPy, Whisper, llama.cpp, Poppler/PDF, F5-TTS ou bibliotecas nativas.

## Regra principal

O repositório Git deve conter apenas:

- templates;
- requirements;
- manifestos;
- scripts de instalação;
- documentação;
- fontes do instalador do runtime.

O Git **não deve** armazenar Python expandido, `venv`, `site-packages`, DLLs/SOs pesados, modelos grandes ou ZIPs finais gerados.

Os pacotes prontos por arquitetura devem ser publicados em **GitHub Releases**.

## Plataformas previstas

| Plataforma | Arquitetura | Status |
|---|---|---|
| Windows | x64 | Suportado |
| Windows | x86 | Manifesto reservado / ainda desabilitado |
| Linux | x64 | Suportado |
| Linux | ARM64 | Experimental |
| Linux | ARMHF | Experimental |

## Instalação padrão

| Sistema | Caminho recomendado |
|---|---|
| Windows | `C:\CHATGPT-AI` |
| Linux root | `/opt/chatgpt-ai` |
| Linux usuário | `~/.local/share/chatgpt-ai` |

## Runtime Installer

O projeto gráfico está em:

```text
runtime/installer/runtime_installer.lpi
```

O fluxo é:

```text
Detectar plataforma
        ↓
Baixar runtime_manifest.ini
        ↓
Escolher pacote da plataforma
        ↓
Baixar ZIP do GitHub Releases
        ↓
Baixar SHA256SUMS.txt
        ↓
Validar SHA256
        ↓
Extrair no diretório local
        ↓
Gerar chatgpt_ai_runtime.ini
        ↓
Validar ferramentas encontradas
```

O manifesto central fica em:

```text
runtime/runtime_manifest.ini
```

A URL padrão do manifesto remoto é:

```text
https://raw.githubusercontent.com/marcelomaurin/CHATGPT/main/runtime/runtime_manifest.ini
```

Isso permite alterar URLs e nomes dos pacotes publicados sem recompilar o Runtime Installer.

## Arquivos esperados nos Releases

```text
CHATGPT-AI-runtime-windows-x64.zip
CHATGPT-AI-runtime-linux-x64.zip
CHATGPT-AI-runtime-linux-arm64.zip
CHATGPT-AI-runtime-linux-armhf.zip
SHA256SUMS.txt
```

O package Windows x86 está previsto no manifesto, mas permanece `enabled=0` até existir um runtime compatível publicado.

## Conteúdo esperado do runtime

O pacote pode conter, conforme a plataforma e versão:

```text
python/
whisper/
llama.cpp/
poppler/
f5-tts/
models/
bin/
```

O instalador procura caminhos conhecidos para Python, `whisper-cli`, `llama-server`, `pdftotext` e F5-TTS e grava os caminhos encontrados no arquivo de configuração.

## Arquivo gerado na instalação

Após a instalação deve existir:

```text
chatgpt_ai_runtime.ini
```

O arquivo registra, no mínimo:

```ini
[runtime]
platform=windows-x64
root=C:\CHATGPT-AI
installed_at=...

[tools]
python=...
whisper=...
llama_server=...
pdftotext=...
f5tts=...
```

Esse arquivo será usado pelos componentes Lazarus, especialmente `TAIPythonRuntime` e os engines externos, para localizar executáveis, DLLs/SOs, modelos e diretórios auxiliares.

## Atualização

Se `chatgpt_ai_runtime.ini` já existir no diretório escolhido, o Runtime Installer trata a operação como atualização e extrai o novo pacote no mesmo local, regenerando o arquivo INI ao final.

## Integridade

O Runtime Installer baixa também `SHA256SUMS.txt` e recusa o ZIP quando o SHA256 calculado localmente não corresponde ao valor publicado no Release.
