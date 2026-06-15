# AI Vision

Componentes de visão computacional da **Lazarus AI Suite**.

Esta área possui três linhas de trabalho:

1. **AI Native Vision** — componentes 100% Lazarus/Free Pascal, sem Python.
2. **AI Python Vision** — componentes que usam Python/OpenCV por worker externo.
3. **AI Native OpenCV Runtime** — suporte parcial para localizar e carregar DLL/SO nativa do OpenCV.

---

## Pacote Lazarus

```text
pacote/packages/openai_vision.lpk
```

Dependência principal:

```text
openai_core.lpk
```

O pacote registra componentes principalmente nas abas:

```text
AI Vision
AI Native Vision
```

---

## Componentes

| Componente | Unit | Status | Descrição |
|---|---|---|---|
| `TAIOpenCV` | `aiopencv.pas` | Beta | Processamento básico via backend Python e carregamento parcial de runtime nativo OpenCV |
| `TAIFrameProcessor` | `aiframeprocessor.pas` | Beta | Pré-processador nativo de imagens para Lazarus/FPC, capaz de redimensionar, converter para grayscale e manipular canais RGB |
| `TAIFaceTracker` | `aifacetracker.pas` | Experimental | Rastreamento por template matching/SAD em `TBitmap`; não é detector facial semântico |
| `TAIMotionTracker` | `aimotiontracker.pas` | Experimental | Detecção de movimento por variação de luminância entre bitmaps |
| `TAIImageInfo` | `aiimageinfo.pas` | Beta | Extração nativa de metadados e contagem de pixels de imagem |
| `TAIFrameBuffer` | `aiframebuffer.pas` | Experimental | Buffer circular de frames em memória para processamento de vídeo |
| `TAINativeImageFilter` | `ainativeimagefilter.pas` | Experimental | Filtros nativos: cinza, threshold, inverter, resize e blur box |
| `TAIFrameDiff` | `aiframediff.pas` | Experimental | Geração nativa de diferença absoluta entre frames |
| `aiopencvruntime` | `aiopencvruntime.pas` | Infraestrutura | Helper para localizar `opencv_world*.dll` e `libopencv_world.so*` por sistema/arquitetura |

---

## AI Native Vision

Componentes nativos em Pascal, sem dependência de Python ou OpenCV.

###

Captura frames de câmera/webcam usando backend específico de plataforma.

Backends atuais nos fontes:

```text
Windows: VFW / avicap32.dll
Linux: V4L2 / /dev/video*
```

Recursos atuais:

* `StartCapture`
* `StopCapture`
* `QueryFrame`
* `CaptureToFile`
* `CaptureToImage`
* `SelfTest`
* `ListAvailableCameras`
* eventos `OnFrame`, `OnError` e `OnStateChange`

Observação técnica:

```text
O backend Linux V4L2 existe nos fontes, mas deve ser validado em ambientes reais Linux/Raspberry antes de ser tratado como estável.
```

### `TAINativeImageFilter`

Filtros nativos sobre `TBitmap`/`TLazIntfImage`.

Filtros atuais:

* `niftNone`
* `niftGray`
* `niftThreshold`
* `niftInvert`
* `niftResize`
* `niftBlurBox`

Métodos principais:

* `ApplyToBitmap`
* `ApplyFile`

### `TAIMotionTracker`

Detecta movimento comparando dois `TBitmap` ou dois arquivos de imagem.

Estratégia atual:

```text
luminância por pixel + threshold + percentual mínimo de movimento
```

Métodos principais:

* `DetectMotion`
* `DetectMotionFromFiles`
* `GetMotionPercent`

### `TAIFaceTracker`

Rastreia uma região usando template matching por SAD.

Atenção:

```text
Este componente não detecta rosto semanticamente.
Ele rastreia uma região/template dentro de um bitmap.
```

Métodos principais:

* `SetTemplateFromBitmap`
* `TrackInBitmap`
* `TrackFace`
* `ClearTemplate`

### `TAIFrameBuffer`, `TAIFrameDiff` e `TAIImageInfo`

Componentes nativos auxiliares para pipelines de vídeo/imagem:

* buffer circular de frames;
* diferença absoluta entre frames;
* extração de informações de imagem.

---

## AI Python Vision

### `TAIOpenCV`

`TAIOpenCV` possui dois backends:

| Backend | Status | Uso recomendado |
|---|---|---|
| `ocvPythonProcess` | Funcional/Beta | Processamento real de imagens com filtros OpenCV |
| `ocvNativeDLL` | Parcial/Experimental | Localização e carregamento de DLL/SO nativa OpenCV |

Worker Python:

```text
pacote/python/aiopencv_worker.py
```

Dependências Python:

```bash
pip install opencv-python numpy
```

Ações suportadas pelo worker Python:

| Ação | Descrição |
|---|---|
| `selftest` | Verifica se o OpenCV está disponível |
| `info` | Lê largura, altura e canais da imagem |
| `none` | Salva a imagem sem alteração |
| `gray` | Converte para escala de cinza |
| `blur` | Aplica blur simples |
| `canny` | Aplica detecção de bordas Canny |
| `threshold` | Aplica threshold binário |
| `resize` | Redimensiona a imagem |

---

## AI Native OpenCV Runtime

A unit:

```text
pacote/AI Vision/aiopencvruntime.pas
```

centraliza a busca por bibliotecas nativas do OpenCV.

Ela procura primeiro em:

```text
runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
runtime/opencv/linux/x64/lib/
runtime/opencv/linux/arm64/lib/
runtime/opencv/linux/armhf/lib/
```

No Windows, aceita:

```text
opencv_world*.dll
```

No Linux, aceita:

```text
libopencv_world.so*
```

A busca registra log com:

* sistema operacional detectado;
* arquitetura detectada;
* pasta esperada;
* manifesto encontrado;
* biblioteca resolvida;
* fallback usado.

---

## Limitação atual do backend nativo OpenCV

O backend `ocvNativeDLL` de `TAIOpenCV` atualmente **localiza e carrega** a DLL/SO nativa, mas o processamento real de imagem ainda não chama funções OpenCV nativas.

No código atual, o fluxo nativo de `ProcessFile` executa uma etapa simulada/cópia de arquivo.

Para aplicar filtros reais, use:

```text
ocvPythonProcess
```

---

## Samples

### OpenCV

```text
pacote/samples/AI Vision/opencv_filter_demo/
pacote/samples/AI Vision/opencv_image_real_demo/
```

`opencv_filter_demo` demonstra:

* SelfTest;
* carregamento de imagem;
* leitura de informações da imagem;
* filtros básicos OpenCV;
* preview antes/depois;
* seleção de backend;
* detecção de runtime nativo;
* fallback Python;
* salvamento do resultado;
* log de execução.

`opencv_image_real_demo` demonstra:

* uso conjunto de `TAIOpenCV` e `TAIFrameProcessor`;
* detecção do runtime OpenCV no início do formulário;
* tentativa de backend nativo;
* fallback para Python;
* modo simulação;
* log da detecção.

### Native Vision

Samples previstos/documentados no README principal:

```text
pacote/samples/AI Vision/aiframeprocessor_demo/
pacote/samples/AI Native Vision/camera_capture_demo/
pacote/samples/AI Native Vision/native_image_filter_demo/
pacote/samples/AI Native Vision/motion_tracker_demo/
```

---

## Limitações atuais

* `TAIOpenCV` usa Python como backend recomendado para processamento real.
* `ocvNativeDLL` ainda não implementa chamadas reais às funções OpenCV nativas.
* `TAIFaceTracker` rastreia template, não faz detecção facial semântica.
* Componentes nativos precisam de mais samples e validação em Windows/Linux.

---

## Próximos passos recomendados

* Implementar processamento real no backend `ocvNativeDLL` ou renomear explicitamente como loader/teste nativo.
* Validar V4L2 no Raspberry Pi 32/64 bits.
* Criar/validar samples nativos: câmera, filtros, motion tracker e frame diff.
* Documentar versões de Windows/Linux/Lazarus testadas.
* Atualizar os READMEs individuais em `DOC/components/` sempre que a API mudar.