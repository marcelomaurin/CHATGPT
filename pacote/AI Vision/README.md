# 👁️ AI Vision — Visão Computacional, OpenCV e Processamento de Frames

A pasta **`pacote/AI Vision/`** reúne os componentes de processamento de imagem, visão computacional, reconhecimento facial e rastreamento de movimento da suíte **TCHATGPT**. Estes componentes pertencem ao pacote Lazarus [**`openai_vision.lpk`**](../packages/openai_vision.lpk).

---

## 🎯 Propósito do Módulo

Integrar visão computacional de alto desempenho em aplicações Pascal nativas com duas abordagens complementares:
1. **Nativa (Sem dependência de DLLs externas):** Algoritmos em Pascal puro para manipulação de pixels, cálculo de diferença de frames ([`aiframediff.pas`](aiframediff.pas)), filtros nativos de imagem e leitura de metadados.
2. **OpenCV / MediaPipe:** Conexão com bibliotecas de visão computacional ([`aiopencv.pas`](aiopencv.pas)) para detecção e rastreamento de faces ([`aifacetracker.pas`](aifacetracker.pas)), reconhecimento facial ([`aifacerecognition.pas`](aifacerecognition.pas)) e detecção de poses humanas ([`aihumanposedetector.pas`](aihumanposedetector.pas)).

---

## 📂 Arquivos Fontes e Componentes

| Arquivo | Componente / Classe | Descrição |
|---|---|---|
| [`aiopencv.pas`](aiopencv.pas) | [`TAIOpenCV`](aiopencv.pas) | Conector principal com as bibliotecas nativas do OpenCV (OpenCV C-API). |
| [`aiframeprocessor.pas`](aiframeprocessor.pas) | [`TAIFrameProcessor`](aiframeprocessor.pas) | Pipeline modular para aplicar transformações, escalas e rotações em buffers de vídeo. |
| [`aifacetracker.pas`](aifacetracker.pas) | [`TAIFaceTracker`](aifacetracker.pas) | Rastreamento e detecção de coordenadas de faces em tempo real. |
| [`aifacerecognition.pas`](aifacerecognition.pas) | [`TAIFaceRecognition`](aifacerecognition.pas), [`TAIFaceMatcher`](aifacematcher.pas) | Extração de descritores faciais e comparação de similaridade de perfis faciais cadastrados. |
| [`aimotiontracker.pas`](aimotiontracker.pas) | [`TAIMotionTracker`](aimotiontracker.pas) | Detecção e rastreamento contínuo de blobs de movimento no fluxo de vídeo. |
| [`aiframediff.pas`](aiframediff.pas) | [`TAIFrameDiff`](aiframediff.pas) | Algoritmo nativo de subtração de frames consecutivos para detecção rápida de alterações no cenário. |
| [`aihumanposedetector.pas`](aihumanposedetector.pas) | [`TAIHumanPoseDetector`](aihumanposedetector.pas) | Detecção de pontos-chave do corpo humano (esqueleto 2D/3D via bridge MediaPipe). |
| [`aicamera_backend.pas`](aicamera_backend.pas) | [`TAICameraBackend`](aicamera_backend.pas) | Camada abstrata de captura de vídeo com suporte a V4L2 (Linux) e VFW/DirectShow (Windows). |

---

## 🎮 Exemplos e Demonstrações Práticas

- [**`samples/AI Vision/opencv_vision_demo/`**](../samples/AI%20Vision/opencv_vision_demo/): Playground completo com seleção de câmeras, detecção de face e filtros em tempo real.
- [**`samples/AI Vision/aiframeprocessor_demo/`**](../samples/AI%20Vision/aiframeprocessor_demo/): Processamento nativo de frames e manipulação de pixels.
- [**`samples/AI Vision/frame_diff_demo/`**](../samples/AI%20Vision/frame_diff_demo/): Detecção de movimento simplificada sem necessidade do OpenCV.
- [**`samples/AI Vision/face_recognition_demo/`**](../samples/AI%20Vision/face_recognition_demo/): Cadastro e reconhecimento biométrico facial.