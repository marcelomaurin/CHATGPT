# Especificação — Runtime OpenCV embarcado por plataforma

Esta especificação define como os componentes e demos da Lazarus AI Suite devem localizar bibliotecas nativas do OpenCV quando o backend `ocvNativeDLL`/nativo estiver disponível.

O objetivo é seguir o mesmo padrão do runtime Python: o usuário instala o pacote e os componentes localizam automaticamente as dependências corretas por sistema operacional e arquitetura, reduzindo erros de `PATH`, versão, 32/64 bits e instalação manual.

---

## 1. Decisão técnica

A suíte deve suportar duas formas de distribuição:

1. **Runtime embarcado/local** dentro da estrutura `runtime/opencv/`.
2. **Runtime externo** informado por configuração ou instalado no sistema.

Por padrão, os componentes e demos devem tentar usar primeiro o runtime embarcado compatível com o sistema atual.

> Observação: arquivos binários grandes como DLL/SO podem ser mantidos em GitHub Releases ou em pacotes de instalação. Caso sejam versionados diretamente no Git, devem respeitar licença, arquitetura e tamanho do repositório.

---

## 2. Estrutura de pastas recomendada

```text
runtime/
  opencv/
    README.md
    manifest.json
    windows/
      x86/
        bin/
          opencv_world*.dll
        README.md
      x64/
        bin/
          opencv_world*.dll
        README.md
    linux/
      x64/
        lib/
          libopencv_world.so*
        README.md
      arm64/
        lib/
          libopencv_world.so*
        README.md
      armhf/
        lib/
          libopencv_world.so*
        README.md
```

### Mapeamento Lazarus/FPC

| TargetOS | TargetCPU | Pasta runtime |
|---|---|---|
| `win32` | `i386` | `runtime/opencv/windows/x86/bin/` |
| `win64` | `x86_64` | `runtime/opencv/windows/x64/bin/` |
| `linux` | `x86_64` | `runtime/opencv/linux/x64/lib/` |
| `linux` | `aarch64` | `runtime/opencv/linux/arm64/lib/` |
| `linux` | `arm` | `runtime/opencv/linux/armhf/lib/` |

---

## 2.1. Lista de samples afetados

Devem ser analisados e ajustados todos os samples que utilizem direta ou indiretamente OpenCV, processamento de imagem, câmera, frames ou backend nativo de visão computacional.

### Samples obrigatoriamente afetados

```text
pacote/samples/AI Vision/opencv_filter_demo/
```

Este sample é afetado porque demonstra o componente `TAIOpenCV` e deve passar a verificar o runtime OpenCV embarcado antes de usar qualquer backend externo.

### Samples a verificar e ajustar se existirem

```text
pacote/samples/AI Vision/opencv_native_demo/
pacote/samples/AI Vision/camera_capture_demo/
pacote/samples/AI Native Vision/native_image_filter_demo/
pacote/samples/AI Native Vision/motion_tracker_demo/
pacote/samples/AI Native Vision/frame_diff_demo/
pacote/samples/AI Native Vision/frame_buffer_demo/
pacote/samples/AI Native Vision/face_tracker_demo/
pacote/samples/AI Image/image_filters_demo/
```

### Samples que devem ser procurados por varredura

Além dos caminhos acima, o bot deve varrer toda a pasta:

```text
pacote/samples/
```

e considerar afetado qualquer sample que contenha referência a:

```text
TAIOpenCV
OpenCV
opencv
ocvNativeDLL
ocvPythonProcess
opencv_world
libopencv_world
cv2
aiopencv
aiopencv_worker.py
```

### Regra de inclusão

Um sample deve ser considerado afetado quando:

* usa `TAIOpenCV`;
* usa `aiopencv.pas`;
* usa worker Python relacionado ao OpenCV;
* usa `opencv-python`;
* menciona `opencv_world*.dll`;
* menciona `libopencv_world.so*`;
* permite escolher backend OpenCV;
* manipula imagens usando OpenCV;
* manipula câmera ou frames com backend OpenCV;
* declara dependência de OpenCV no README.

### Regra de exclusão

Um sample **não** deve ser alterado apenas por trabalhar com imagem se for 100% nativo Pascal e não tiver dependência de OpenCV.

Exemplo: filtros simples baseados apenas em `TBitmap`, `TLazIntfImage` ou componentes nativos não precisam buscar `opencv_world.dll`, a menos que ofereçam backend OpenCV opcional.

### Resultado esperado da varredura

O bot deve gerar uma lista final no commit ou no relatório da tarefa com três grupos:

```text
1. Samples ajustados
2. Samples verificados e não afetados
3. Samples inexistentes ou não encontrados
```

Para cada sample ajustado, informar:

```text
- caminho do sample
- motivo da alteração
- backend usado
- se há fallback Python
- pasta runtime esperada
```

---

## 3. Bibliotecas esperadas

### Windows

Procurar por ordem:

```text
opencv_world.dll
opencv_world4110.dll
opencv_world4100.dll
opencv_world490.dll
opencv_world480.dll
opencv_world470.dll
opencv_world460.dll
```

Também deve aceitar padrão:

```text
opencv_world*.dll
```

### Linux

Procurar por ordem:

```text
libopencv_world.so
libopencv_world.so.411
libopencv_world.so.410
libopencv_world.so.409
libopencv_world.so.408
libopencv_world.so.407
libopencv_world.so.406
```

Também deve aceitar padrão:

```text
libopencv_world.so*
```

Caso `libopencv_world.so` não exista, futuramente poderá ser suportado carregamento por bibliotecas separadas:

```text
libopencv_core.so*
libopencv_imgproc.so*
libopencv_imgcodecs.so*
libopencv_videoio.so*
```

Mas a primeira fase deve priorizar `opencv_world` para reduzir complexidade.

---

## 4. Propriedades recomendadas no componente

Adicionar ao `TAIOpenCV` ou a um helper compartilhado:

```pascal
property UseBundledRuntime: Boolean default True;
property OpenCVLibraryPath: string;
property OpenCVLibraryName: string;
property AutoDetectLibrary: Boolean default True;
property ResolvedLibraryPath: string read FResolvedLibraryPath;
```

Significado:

| Propriedade | Função |
|---|---|
| `UseBundledRuntime` | tenta localizar primeiro em `runtime/opencv/<os>/<arch>` |
| `OpenCVLibraryPath` | caminho manual informado pelo usuário |
| `OpenCVLibraryName` | nome manual da DLL/SO |
| `AutoDetectLibrary` | habilita busca automática por nomes conhecidos |
| `ResolvedLibraryPath` | caminho final encontrado |

---

## 5. Ordem de busca obrigatória

Todos os demos e componentes que dependem da DLL/SO nativa devem usar a mesma ordem:

```text
1. OpenCVLibraryPath + OpenCVLibraryName, se ambos forem informados
2. OpenCVLibraryPath + lista de nomes conhecidos
3. Pasta do executável + runtime/opencv/<os>/<arch>/bin ou lib
4. Pasta raiz do projeto + runtime/opencv/<os>/<arch>/bin ou lib
5. Pasta informada no arquivo chatgpt_ai_runtime.ini
6. PATH do Windows ou LD_LIBRARY_PATH do Linux
7. Caminhos comuns do sistema
8. Erro claro com a lista de caminhos e nomes testados
```

### Caminhos comuns adicionais

Windows:

```text
C:\CHATGPT-AI\opencv\windows\x86\bin\
C:\CHATGPT-AI\opencv\windows\x64\bin\
```

Linux:

```text
/opt/chatgpt-ai/opencv/linux/x64/lib/
/opt/chatgpt-ai/opencv/linux/arm64/lib/
/opt/chatgpt-ai/opencv/linux/armhf/lib/
~/.local/share/chatgpt-ai/opencv/linux/x64/lib/
~/.local/share/chatgpt-ai/opencv/linux/arm64/lib/
~/.local/share/chatgpt-ai/opencv/linux/armhf/lib/
/usr/lib/
/usr/local/lib/
```

---

## 6. Helper Pascal recomendado

Criar uma unit compartilhada, por exemplo:

```text
pacote/IA/aiopencvruntime.pas
```

Funções mínimas:

```pascal
function AIGetOpenCVPlatformFolder: string;
function AIGetOpenCVLibraryNames: TStringArray;
function AIFindOpenCVLibrary(const AManualPath, AManualName: string; AUseBundled: Boolean; out AResolvedPath, AError: string): Boolean;
function AILoadOpenCVLibrary(const ALibraryPath: string; out AHandle: TLibHandle; out AError: string): Boolean;
```

### Regras internas

- Usar diretivas `{$IFDEF MSWINDOWS}` e `{$IFDEF LINUX}`.
- Usar `{$IFDEF CPU32}`, `{$IFDEF CPU64}`, `{$IFDEF CPUAARCH64}` ou equivalentes disponíveis no FPC.
- No Windows, antes do carregamento, quando possível, adicionar o diretório da DLL ao caminho de busca com API segura.
- No Linux, preferir carregar por caminho absoluto usando `DynLibs.LoadLibrary`.
- Nunca tentar carregar DLL x64 em processo 32 bits ou DLL x86 em processo 64 bits.
- Mensagem de erro deve indicar sistema, arquitetura, nomes procurados e diretórios testados.

---

## 7. Regras para demos

Todo demo que usa backend nativo OpenCV deve:

1. Não usar caminho fixo absoluto.
2. Não exigir cópia manual para `System32` ou `/usr/lib`.
3. Chamar o helper comum de resolução.
4. Mostrar no log:
   - sistema operacional detectado;
   - arquitetura detectada;
   - pasta runtime esperada;
   - DLL/SO encontrada;
   - erro detalhado se não encontrou.
5. Permitir botão ou campo para selecionar manualmente o caminho da DLL/SO.
6. Permitir fallback para backend Python quando o backend nativo não estiver disponível.

Exemplo de log esperado:

```text
OpenCV native runtime detection
OS: Windows
CPU: x86_64
Expected folder: runtime/opencv/windows/x64/bin
Found: runtime/opencv/windows/x64/bin/opencv_world490.dll
Status: OK
```

Erro esperado:

```text
OpenCV native library not found.
OS: Linux
CPU: aarch64
Expected folder: runtime/opencv/linux/arm64/lib
Tried names: libopencv_world.so, libopencv_world.so.411, libopencv_world.so.410, libopencv_world.so.409, libopencv_world.so.408
Configure OpenCVLibraryPath or install the OpenCV runtime package for this platform.
```

---

## 8. Manifesto de runtime

Criar ou manter:

```text
runtime/opencv/manifest.json
```

Formato recomendado:

```json
{
  "name": "opencv-runtime",
  "strategy": "bundled-by-platform",
  "windows": {
    "x86": {
      "folder": "runtime/opencv/windows/x86/bin",
      "libraries": ["opencv_world*.dll"]
    },
    "x64": {
      "folder": "runtime/opencv/windows/x64/bin",
      "libraries": ["opencv_world*.dll"]
    }
  },
  "linux": {
    "x64": {
      "folder": "runtime/opencv/linux/x64/lib",
      "libraries": ["libopencv_world.so*"]
    },
    "arm64": {
      "folder": "runtime/opencv/linux/arm64/lib",
      "libraries": ["libopencv_world.so*"]
    },
    "armhf": {
      "folder": "runtime/opencv/linux/armhf/lib",
      "libraries": ["libopencv_world.so*"]
    }
  }
}
```

---

## 9. Critérios de aceite

A implementação será considerada correta quando:

- `TAIOpenCV` localizar automaticamente a DLL/SO embarcada correta.
- Demos não tiverem caminhos absolutos.
- Windows x86 não tentar carregar x64.
- Windows x64 não tentar carregar x86.
- Linux x64, ARM64 e ARMHF usarem pastas separadas.
- Mensagens de erro forem claras.
- Fallback para Python continuar funcionando.
- A documentação indicar que `opencv_world` é dependência do backend nativo, não do backend Python.

---

## 10. Observação de licença

Antes de versionar DLLs/SOs diretamente no Git, confirmar:

- licença da build OpenCV usada;
- origem dos binários;
- arquitetura;
- versão;
- se o tamanho é adequado para Git ou se deve ir para GitHub Releases.

Preferência técnica:

```text
Git: documentação, manifestos, scripts, checksums pequenos.
GitHub Releases: pacotes binários grandes por plataforma.
```
