# Especificação — Samples OpenCV com busca automática do runtime nativo

Esta especificação define como todos os projetos de demonstração que usam OpenCV devem localizar as bibliotecas nativas `opencv_world*.dll` ou `libopencv_world.so*`.

A regra principal é: **os samples devem procurar primeiro nas pastas `runtime/opencv/` versionadas no próprio projeto**, separadas por sistema operacional e arquitetura.

---

## 1. Objetivo

Garantir que os samples OpenCV funcionem de forma previsível em Windows, Linux, Raspberry Pi e demais plataformas suportadas, sem depender de OpenCV instalado globalmente no sistema.

Motivos:

- evitar quebra por mudança de versão do OpenCV;
- evitar conflito entre DLLs/SOs diferentes no `PATH` ou `LD_LIBRARY_PATH`;
- evitar mistura entre 32 e 64 bits;
- facilitar execução em máquina limpa;
- manter os demos reproduzíveis.

---

## 2. Samples afetados

Todo sample que usar OpenCV nativo deve seguir esta especificação.

Inicialmente, isso inclui ou poderá incluir:

```text
pacote/samples/AI Vision/opencv_filter_demo/
pacote/samples/AI Vision/opencv_native_demo/
pacote/samples/AI Vision/camera_capture_demo/
pacote/samples/AI Native Vision/native_image_filter_demo/
pacote/samples/AI Native Vision/motion_tracker_demo/
```

Observação:

- Samples que usam apenas o backend Python continuam podendo usar `opencv-python`.
- Se o sample permitir alternar entre backend Python e backend nativo, ele deve aplicar esta busca somente quando o backend nativo estiver selecionado.

---

## 3. Estrutura de runtime que deve ser usada primeiro

Os samples devem procurar primeiro nestas pastas, conforme sistema e arquitetura:

```text
runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
runtime/opencv/linux/x64/lib/
runtime/opencv/linux/arm64/lib/
runtime/opencv/linux/armhf/lib/
```

Mapeamento obrigatório:

| Sistema | Arquitetura do processo | Pasta de busca principal |
|---|---|---|
| Windows | 32 bits / i386 | `runtime/opencv/windows/x86/bin/` |
| Windows | 64 bits / x86_64 | `runtime/opencv/windows/x64/bin/` |
| Linux | x86_64 | `runtime/opencv/linux/x64/lib/` |
| Linux | ARM64 / aarch64 | `runtime/opencv/linux/arm64/lib/` |
| Linux | ARM 32 bits / armhf | `runtime/opencv/linux/armhf/lib/` |

---

## 4. Ordem de busca obrigatória nos samples

Os samples devem usar exatamente esta ordem:

```text
1. Pasta do executável + runtime/opencv/<os>/<arch>/bin ou lib
2. Pasta raiz do projeto/repositório + runtime/opencv/<os>/<arch>/bin ou lib
3. Caminho configurado no sample pelo usuário
4. Caminho configurado no componente TAIOpenCV.OpenCVLibraryPath
5. Caminho informado em chatgpt_ai_runtime.ini
6. PATH do Windows ou LD_LIBRARY_PATH do Linux
7. Caminhos comuns do sistema
8. Erro detalhado
```

A busca no runtime local deve sempre vir antes da busca no sistema.

---

## 5. Nomes aceitos para Windows

Os samples devem procurar, nesta ordem:

```text
opencv_world.dll
opencv_world4110.dll
opencv_world4100.dll
opencv_world490.dll
opencv_world480.dll
opencv_world470.dll
opencv_world460.dll
opencv_world*.dll
```

Regras:

- Não carregar DLL x64 em sample compilado 32 bits.
- Não carregar DLL x86 em sample compilado 64 bits.
- Não copiar DLL para `System32`.
- Não exigir instalação global do OpenCV.

---

## 6. Nomes aceitos para Linux

Os samples devem procurar, nesta ordem:

```text
libopencv_world.so
libopencv_world.so.411
libopencv_world.so.410
libopencv_world.so.409
libopencv_world.so.408
libopencv_world.so.407
libopencv_world.so.406
libopencv_world.so*
```

Regras:

- Linux x64 deve usar somente `runtime/opencv/linux/x64/lib/`.
- Linux ARM64 deve usar somente `runtime/opencv/linux/arm64/lib/`.
- Linux ARMHF deve usar somente `runtime/opencv/linux/armhf/lib/`.
- Não depender de `/usr/lib` antes de testar o runtime local.

---

## 7. Implementação recomendada nos demos Lazarus

Cada demo OpenCV deve usar uma unit comum, por exemplo:

```text
pacote/IA/aiopencvruntime.pas
```

O demo não deve implementar sua própria busca manual duplicada.

Funções recomendadas:

```pascal
function AIGetOpenCVRuntimeFolder: string;
function AIFindOpenCVNativeLibrary(out AResolvedPath: string; out AError: string): Boolean;
function AIDetectOSName: string;
function AIDetectCPUName: string;
```

O sample deve fazer algo assim:

```pascal
var
  LOpenCVLib: string;
  LError: string;
begin
  if AIFindOpenCVNativeLibrary(LOpenCVLib, LError) then
  begin
    MemoLog.Lines.Add('OpenCV native library found: ' + LOpenCVLib);
    AIOpenCV1.OpenCVLibraryPath := ExtractFilePath(LOpenCVLib);
    AIOpenCV1.OpenCVLibraryName := ExtractFileName(LOpenCVLib);
  end
  else
  begin
    MemoLog.Lines.Add(LError);
    MemoLog.Lines.Add('Falling back to Python OpenCV backend when available.');
    AIOpenCV1.Backend := ocvPythonProcess;
  end;
end;
```

---

## 8. Log obrigatório nos samples

Todo sample OpenCV deve exibir no log:

```text
OpenCV runtime detection
OS: <Windows/Linux>
CPU: <x86/x64/arm64/armhf>
Expected runtime folder: <pasta>
Search priority: bundled runtime first
Resolved library: <arquivo encontrado>
Backend selected: <native/python>
```

Se falhar:

```text
OpenCV native runtime not found.
Expected folder: <pasta>
Tried names: <lista>
Tried folders: <lista>
Suggestion: copy the correct OpenCV runtime files to runtime/opencv/<os>/<arch>/.
```

---

## 9. Regras para arquivos dos samples

Cada sample OpenCV deve conter no README próprio:

```text
## OpenCV runtime

Este sample procura primeiro o OpenCV nativo em:

runtime/opencv/<sistema>/<arquitetura>/

Somente se não encontrar, tenta caminho manual ou bibliotecas do sistema.
```

Também deve informar:

- se usa backend Python;
- se usa backend nativo;
- se aceita fallback;
- quais DLLs/SOs são esperadas;
- qual pacote Lazarus precisa ser instalado.

---

## 10. Critérios de aceite para cada demo

Um demo OpenCV só deve ser considerado completo quando:

- compilar sem caminho absoluto local do desenvolvedor;
- detectar sistema e arquitetura automaticamente;
- procurar primeiro em `runtime/opencv/`;
- registrar a DLL/SO encontrada no log;
- mostrar erro claro se a DLL/SO não existir;
- permitir fallback para Python quando aplicável;
- não exigir alteração manual de `PATH`;
- não misturar DLL/SO entre arquiteturas;
- documentar o runtime no README do próprio sample.

---

## 11. Tarefa para implementação

Implementar ou ajustar os samples OpenCV para:

1. Criar/usar a unit comum `aiopencvruntime.pas`.
2. Adicionar propriedades em `TAIOpenCV` quando necessário:

```pascal
UseBundledRuntime: Boolean;
OpenCVLibraryPath: string;
OpenCVLibraryName: string;
AutoDetectLibrary: Boolean;
ResolvedLibraryPath: string;
```

3. No `FormCreate` dos demos, chamar a detecção do runtime.
4. Mostrar resultado no log visual.
5. Usar backend nativo somente se a biblioteca compatível for encontrada.
6. Caso contrário, usar backend Python ou mostrar erro controlado.

---

## 12. Observação importante

A presença das DLLs/SOs no repositório não elimina a necessidade de validação por arquitetura.

O sample deve validar sempre:

```text
sistema operacional atual + arquitetura do processo + pasta correta + nome da biblioteca
```

Nunca carregar uma biblioteca apenas porque ela existe em alguma pasta do projeto.
