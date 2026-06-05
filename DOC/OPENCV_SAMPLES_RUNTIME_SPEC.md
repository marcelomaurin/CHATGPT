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

## 2. Samples afetados confirmados nos fontes

### 2.1. Samples obrigatoriamente afetados

```text
pacote/samples/AI Vision/opencv_filter_demo/
pacote/samples/AI Vision/opencv_image_real_demo/
```

Esses samples usam `TAIOpenCV`, `aiopencvruntime` ou OpenCV e devem manter busca de runtime OpenCV embarcado antes de bibliotecas do sistema.

### 2.2. Samples a verificar e ajustar se existirem

```text
pacote/samples/AI Vision/opencv_native_demo/
pacote/samples/AI Vision/camera_capture_demo/
pacote/samples/AI Vision/opencv_vision_demo/
pacote/samples/AI Native Vision/native_image_filter_demo/
pacote/samples/AI Native Vision/motion_tracker_demo/
pacote/samples/AI Native Vision/frame_diff_demo/
pacote/samples/AI Native Vision/frame_buffer_demo/
pacote/samples/AI Native Vision/face_tracker_demo/
pacote/samples/AI Image/image_filters_demo/
```

### 2.3. Varredura obrigatória

Além dos caminhos acima, deve-se varrer toda a pasta:

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
aiopencvruntime
aiopencv_worker.py
```

### 2.4. Regra de inclusão

Um sample deve ser considerado afetado quando:

- usa `TAIOpenCV`;
- usa `aiopencv`;
- usa `aiopencvruntime`;
- usa worker Python relacionado ao OpenCV;
- usa `opencv-python`;
- menciona `opencv_world*.dll`;
- menciona `libopencv_world.so*`;
- permite escolher backend OpenCV;
- manipula imagens usando OpenCV;
- manipula câmera ou frames com backend OpenCV;
- declara dependência de OpenCV no README.

### 2.5. Regra de exclusão

Um sample não deve ser alterado apenas por trabalhar com imagem se for 100% nativo Pascal e não tiver dependência de OpenCV.

Exemplo: filtros simples baseados apenas em `TBitmap`, `TLazIntfImage` ou componentes nativos não precisam buscar `opencv_world.dll`, a menos que ofereçam backend OpenCV opcional.

### 2.6. Resultado esperado da varredura

O relatório da tarefa deve separar:

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

## 4. Unit comum usada pelos fontes atuais

A unit comum de localização do OpenCV nativo é:

```text
pacote/AI Vision/aiopencvruntime.pas
```

Essa unit centraliza:

- detecção de sistema operacional;
- detecção de arquitetura;
- definição da pasta `runtime/opencv/<os>/<arch>`;
- leitura do `manifest.json`, quando existir;
- seleção da biblioteca preferida;
- seleção da maior versão disponível;
- fallback para diretório do executável e caminhos do sistema;
- geração de log detalhado.

Funções principais presentes nos fontes:

```text
AIGetOpenCVPlatformFolder
AIGetOpenCVLibraryNames
AIFindOpenCVNativeLibrary
AILoadOpenCVLibrary
```

---

## 5. Ordem de busca obrigatória nos samples

Os samples devem usar esta prioridade lógica:

```text
1. Runtime OpenCV versionado em runtime/opencv/<os>/<arch>
2. Manifesto runtime/opencv/manifest.json, quando existir
3. Pasta do executável
4. Caminho configurado manualmente no sample/componente
5. PATH do Windows ou LD_LIBRARY_PATH do Linux
6. Caminhos comuns do sistema
7. Erro detalhado
```

A busca no runtime local deve sempre vir antes da busca no sistema.

---

## 6. Nomes aceitos para Windows

Os samples devem procurar:

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

## 7. Nomes aceitos para Linux

Os samples devem procurar:

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

## 8. Comportamento esperado dos demos Lazarus

Cada demo OpenCV deve:

1. Usar `pacote/AI Vision/aiopencvruntime.pas`.
2. Não duplicar lógica própria de busca divergente.
3. Não depender de caminho absoluto local.
4. Não depender de instalação global do OpenCV como primeira opção.
5. Mostrar no log a plataforma, arquitetura, pasta esperada e biblioteca resolvida.
6. Usar backend nativo somente quando uma biblioteca compatível for encontrada.
7. Aplicar fallback para backend Python quando o sample suportar esse fallback.
8. Informar claramente quando o backend nativo está apenas carregando DLL/SO, sem processamento OpenCV nativo real.

---

## 9. Log obrigatório nos samples

Todo sample OpenCV deve exibir no log:

```text
OpenCV runtime detection
Search mode: bundled runtime first
OS detected: <windows/linux>
CPU detected: <x86/x64/arm64/armhf>
Expected runtime folder: runtime/opencv/<...>
Manifest: <manifest encontrado ou vazio>
Resolved library: <arquivo encontrado>
Backend selected: <native/python>
Status: <OK/native unavailable/error>
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

## 10. Regras para README dos samples

Cada sample OpenCV deve conter seção informando:

```text
## OpenCV runtime

Este sample procura primeiro o OpenCV nativo nas pastas versionadas do projeto:

runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
runtime/opencv/linux/x64/lib/
runtime/opencv/linux/arm64/lib/
runtime/opencv/linux/armhf/lib/

Somente se não encontrar, tenta caminho manual ou bibliotecas do sistema.
```

Também deve informar:

- se usa backend Python;
- se usa backend nativo;
- se aceita fallback;
- quais DLLs/SOs são esperadas;
- qual pacote Lazarus precisa ser instalado;
- que a busca local do runtime tem prioridade;
- se o processamento real é Python ou nativo.

---

## 11. Critérios de aceite para cada demo

Um demo OpenCV só deve ser considerado completo quando:

- compilar sem caminho absoluto local do desenvolvedor;
- detectar sistema e arquitetura automaticamente;
- procurar primeiro em `runtime/opencv/`;
- registrar a DLL/SO encontrada no log;
- mostrar erro claro se a DLL/SO não existir;
- permitir fallback para Python quando aplicável;
- não exigir alteração manual de `PATH`;
- não misturar DLL/SO entre arquiteturas;
- documentar o runtime no README do próprio sample;
- documentar se o backend nativo faz processamento real ou apenas carregamento/teste.

---

## 12. Observação importante

A presença das DLLs/SOs no repositório não elimina a necessidade de validação por arquitetura.

O sample deve validar sempre:

```text
sistema operacional atual + arquitetura do processo + pasta correta + nome da biblioteca
```

Nunca carregar uma biblioteca apenas porque ela existe em alguma pasta do projeto.
