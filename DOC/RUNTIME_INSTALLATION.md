# Runtime Installation

A instalação do runtime externo deve ser feita por ZIP específico para cada plataforma/arquitetura.

## Arquivos previstos em Releases

- CHATGPT-AI-runtime-windows-x64.zip
- CHATGPT-AI-runtime-linux-x64.zip
- CHATGPT-AI-runtime-linux-arm64.zip
- CHATGPT-AI-runtime-linux-armhf.zip
- SHA256SUMS.txt

## Windows x64

1. Baixe `CHATGPT-AI-runtime-windows-x64.zip`.
2. Extraia o ZIP.
3. Execute `install.bat`.
4. Abra o Lazarus e confirme os pacotes instalados.

## Linux x64

1. Baixe `CHATGPT-AI-runtime-linux-x64.zip`.
2. Extraia o ZIP.
3. Execute o instalador Linux.
4. Confirme o caminho do `lazbuild`.

## Linux ARM64

Status experimental.

Use este pacote para Raspberry Pi 64 bits e placas ARM64 compatíveis.

Alguns pacotes Python podem exigir instalação específica da distribuição.

## Linux ARMHF

Status experimental.

Use este pacote para Raspberry Pi 32 bits e placas ARM compatíveis.

## Resultado esperado

Após a instalação, deve existir:

```text
chatgpt_ai_runtime.ini
```

E os pacotes Lazarus devem estar instalados ou prontos para instalação manual.

## Validação

Execute o verificador:

```text
installer/common/check_runtime.py
```

Ele valida versão do Python, arquitetura e imports principais conforme o perfil de runtime.
