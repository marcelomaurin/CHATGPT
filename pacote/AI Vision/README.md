# AI Vision

Componentes de visão computacional da **Lazarus AI Suite**.

Esta área agora possui duas linhas de trabalho:

1. **AI Native Vision** — componentes 100% Lazarus/Free Pascal, sem Python.
2. **AI Python Vision** — componentes que usam Python/OpenCV por worker externo.

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
| `TAIOpenCV` | `aiopencv.pas` | Beta | Processamento básico de imagem via OpenCV usando worker Python |
| `TAICameraCapture` | `aicameracapture.pas` | Beta parcial | Captura nativa via Windows VFW; stub/não suportado no Linux nesta versão |
| `TAIFrameProcessor` | `aiframeprocessor.pas` | Experimental | Estrutura de processamento de frames em evolução |
| `TAIFaceTracker` | `aifacetracker.pas` | Beta técnico | Rastreamento por template matching/SAD em `TBitmap`; não é detector facial semântico |
| `TAIMotionTracker` | `aimotiontracker.pas` | Beta | Detecção de movimento por variação de luminância entre bitmaps |
| `TAIImageInfo` | `aiimageinfo.pas` | Beta | Extração nativa de metadados e contagem de pixels de imagem |
| `TAIFrameBuffer` | `aiframebuffer.pas` | Beta | Buffer circular de frames em memória para processamento de vídeo |
| `TAINativeImageFilter` | `ainativeimagefilter.pas` | Beta | Filtros nativos: cinza, threshold, inverter, resize e blur box |
| `TAIFrameDiff` | `aiframediff.pas` | Beta | Geração nativa de diferença absoluta entre frames |

---

## AI Native Vision

Componentes nativos em Pascal, sem dependência de Python ou OpenCV.

### `TAICameraCapture`

Captura frames de câmera/webcam no Windows usando VFW/`avicap32.dll`.

Recursos atuais:

* `StartCapture`
* `StopCapture`
* `QueryFrame`
* `CaptureToFile`
* `CaptureToImage`
* `SelfTest`
* `ListAvailableCameras`
* eventos `OnFrame`, `OnError` e `OnStateChange`

Limitação importante:

```text
Captura real disponível apenas no Windows nesta versão.
Linux retorna erro de plataforma não suportada/stub.
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

`TAIOpenCV` usa um worker Python para chamar OpenCV por processo externo.

Worker:

```text
pacote/python/aiopencv_worker.py
```

Dependências Python:

```bash
pip install opencv-python numpy
```

Ações suportadas atualmente:

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

Backend recomendado atualmente:

```text
Python Process
```

O backend `Native DLL` está previsto, mas ainda não deve ser tratado como funcional.

---

## Samples

### Python/OpenCV

```text
pacote/samples/AI Vision/opencv_filter_demo/
```

Demonstra:

* SelfTest;
* carregamento de imagem;
* leitura de informações da imagem;
* filtros básicos OpenCV;
* preview antes/depois;
* salvamento do resultado;
* log de execução.

### Native Vision

Samples previstos/documentados no README principal:

```text
pacote/samples/AI Native Vision/camera_capture_demo/
pacote/samples/AI Native Vision/native_image_filter_demo/
pacote/samples/AI Native Vision/motion_tracker_demo/
```

---

## Limitações atuais

* `TAIOpenCV` ainda depende de Python.
* O backend nativo DLL/SO do `TAIOpenCV` ainda não está implementado.
* `TAICameraCapture` usa VFW no Windows; Linux ainda precisa backend próprio.
* `TAIFaceTracker` rastreia template, não faz detecção facial semântica.
* Componentes nativos precisam de mais samples e validação em Windows/Linux.

---

## Próximos passos recomendados

* Criar/validar samples nativos: câmera, filtros, motion tracker e frame diff.
* Documentar versões de Windows/Lazarus testadas para `TAICameraCapture`.
* Criar alternativa Linux para captura de câmera.
* Criar testes manuais para cada componente `AI Native Vision`.
* Atualizar os READMEs individuais em `DOC/components/` sempre que a API mudar.
