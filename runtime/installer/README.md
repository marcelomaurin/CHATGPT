# CHATGPT-AI Runtime Installer

Instalador gráfico do runtime externo da suíte CHATGPT-AI.

## Objetivo

Preparar uma máquina onde uma aplicação Lazarus/Free Pascal utilizará os componentes que dependem de runtimes externos.

O instalador não instala os packages Lazarus. Para isso use `tools/installer/`.

Este projeto instala apenas o runtime necessário para execução, por exemplo:

- Python;
- OpenCV/NumPy e bibliotecas relacionadas;
- `whisper-cli` e modelos disponibilizados no bundle;
- `llama-server`/llama.cpp;
- Poppler / `pdftotext`;
- F5-TTS;
- bibliotecas/DLLs/SOs auxiliares;
- modelos e arquivos de configuração distribuídos no bundle do Release.

## Compilar

Abra:

```text
runtime/installer/runtime_installer.lpi
```

No Windows existem os modos:

```text
Release64 -> RuntimeInstaller_64.exe
Release32 -> RuntimeInstaller_32.exe
```

O runtime Windows x86 permanece desabilitado no manifesto enquanto não houver um pacote correspondente publicado no GitHub Releases.

## Fluxo

1. Detecta plataforma e arquitetura do instalador.
2. Tenta baixar o manifesto mais recente de `runtime/runtime_manifest.ini`.
3. Se o manifesto remoto falhar, tenta o manifesto local.
4. Seleciona a seção correspondente à plataforma.
5. Mostra o diretório de destino sugerido.
6. Baixa o ZIP do GitHub Releases.
7. Baixa `SHA256SUMS.txt`.
8. Calcula SHA256 local.
9. Aborta se a integridade estiver incorreta.
10. Extrai o ZIP.
11. Gera `chatgpt_ai_runtime.ini`.
12. Valida as ferramentas localizadas.

## Publicação dos runtimes

Os assets esperados no GitHub Releases são:

```text
CHATGPT-AI-runtime-windows-x64.zip
CHATGPT-AI-runtime-linux-x64.zip
CHATGPT-AI-runtime-linux-arm64.zip
CHATGPT-AI-runtime-linux-armhf.zip
SHA256SUMS.txt
```

Os links no manifesto usam o endpoint estável:

```text
https://github.com/marcelomaurin/CHATGPT/releases/latest/download/<arquivo>
```

Portanto um novo Release pode substituir a versão anterior sem exigir recompilar o instalador.

## Estrutura recomendada do ZIP

```text
python/
whisper/
llama.cpp/
poppler/
f5-tts/
models/
bin/
```

Nem todos os diretórios são obrigatórios. O conteúdo depende do perfil publicado para cada plataforma.

## Resultado

No diretório de instalação será criado:

```text
chatgpt_ai_runtime.ini
```

Os componentes da suíte podem usar esse arquivo para descobrir os caminhos dos runtimes.

## Segurança

O instalador não executa binários baixados durante a instalação. Ele apenas:

- baixa;
- valida SHA256;
- extrai;
- registra caminhos;
- valida a presença dos arquivos.

A execução efetiva fica a cargo dos componentes da aplicação.
