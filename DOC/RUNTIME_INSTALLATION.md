# Runtime Installation

A instalação do runtime externo é feita por pacote ZIP específico para cada plataforma/arquitetura, publicado em GitHub Releases.

## Instalador gráfico recomendado

O instalador está em:

```text
runtime/installer/runtime_installer.lpi
```

Ele automatiza o processo completo:

```text
Detectar plataforma
        ↓
Baixar runtime_manifest.ini
        ↓
Selecionar pacote compatível
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
Validar ferramentas
```

## Arquivos previstos em Releases

- `CHATGPT-AI-runtime-windows-x64.zip`
- `CHATGPT-AI-runtime-linux-x64.zip`
- `CHATGPT-AI-runtime-linux-arm64.zip`
- `CHATGPT-AI-runtime-linux-armhf.zip`
- `SHA256SUMS.txt`

O manifesto contém também uma entrada Windows x86, mas ela permanece desabilitada até que exista um bundle compatível publicado.

## Manifesto

O catálogo dos runtimes fica em:

```text
runtime/runtime_manifest.ini
```

O Runtime Installer tenta obter primeiro a versão remota:

```text
https://raw.githubusercontent.com/marcelomaurin/CHATGPT/main/runtime/runtime_manifest.ini
```

Se não conseguir, tenta uma cópia local próxima ao executável.

Os downloads usam URLs no padrão:

```text
https://github.com/marcelomaurin/CHATGPT/releases/latest/download/<arquivo>
```

Assim novos runtimes podem ser publicados sem recompilar o instalador.

## Windows x64

Diretório padrão:

```text
C:\CHATGPT-AI
```

Compile `RuntimeInstaller_64.exe` e execute o wizard.

O instalador baixa automaticamente o bundle Windows x64 e gera o arquivo de configuração.

## Windows x86

O projeto possui modo de build `Release32`, produzindo:

```text
RuntimeInstaller_32.exe
```

Porém o manifesto atual mantém `windows-x86` desabilitado. Habilite somente quando `CHATGPT-AI-runtime-windows-x86.zip` estiver publicado e testado.

## Linux x64

Diretório padrão do usuário:

```text
~/.local/share/chatgpt-ai
```

Pode ser alterado na tela do instalador.

## Linux ARM64

Status experimental.

Use para Raspberry Pi 64 bits e placas ARM64 compatíveis. Alguns pacotes Python podem exigir builds específicos da distribuição.

## Linux ARMHF

Status experimental.

Use para Raspberry Pi 32 bits e placas ARM compatíveis.

## Conteúdo do bundle

A estrutura recomendada é:

```text
python/
whisper/
llama.cpp/
poppler/
f5-tts/
models/
bin/
```

Nem todos os itens são obrigatórios em todos os perfis.

## Resultado esperado

Após a instalação deve existir:

```text
chatgpt_ai_runtime.ini
```

Exemplo:

```ini
[runtime]
platform=windows-x64
root=C:\CHATGPT-AI
installed_at=2026-08-10 19:00:00

[tools]
python=C:\CHATGPT-AI\python\python.exe
whisper=C:\CHATGPT-AI\whisper\whisper-cli.exe
llama_server=C:\CHATGPT-AI\llama.cpp\llama-server.exe
pdftotext=C:\CHATGPT-AI\poppler\Library\bin\pdftotext.exe
f5tts=C:\CHATGPT-AI\f5-tts\src\f5_tts\infer\infer_cli.py
```

Os caminhos que não existirem no bundle permanecem vazios e são apresentados como opcionais na validação.

## Atualização

Se o runtime já estiver instalado no diretório escolhido, o wizard atualiza os arquivos no mesmo local e regenera `chatgpt_ai_runtime.ini`.

## Integridade

O Release deve sempre publicar `SHA256SUMS.txt` junto com os ZIPs. O instalador recusa o pacote quando o SHA256 local não corresponde ao publicado.

## Validação adicional

O verificador existente continua disponível:

```text
installer/common/check_runtime.py
```

Ele pode ser usado após o wizard para validar versão do Python, arquitetura e imports principais conforme o perfil de runtime.
