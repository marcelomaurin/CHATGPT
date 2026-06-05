# AI Vision

Componentes de visão computacional da **Lazarus AI Suite**.

Esta área concentra componentes relacionados a OpenCV, processamento de frames, câmera, rastreamento facial e movimento.

---

## Pacote Lazarus

```text
pacote/packages/openai_vision.lpk
```

Dependência principal:

```text
openai_core.lpk
```

---

## Componentes

| Componente | Unit | Status | Descrição |
|---|---|---|---|
| `TAIOpenCV` | `aiopencv.pas` | Beta | Processamento básico de imagem via OpenCV usando worker Python |
| `TAICameraCapture` | `aicameracapture.pas` | Placeholder | Estrutura para captura de câmera; captura real ainda precisa validação |
| `TAIFrameProcessor` | `aiframeprocessor.pas` | Experimental | Estrutura para processamento de frames |
| `TAIFaceTracker` | `aifacetracker.pas` | Placeholder | Estrutura para rastreamento facial; implementação real ainda precisa validação |
| `TAIMotionTracker` | `aimotiontracker.pas` | Placeholder | Estrutura para detecção de movimento; implementação real ainda precisa validação |

---

## TAIOpenCV

`TAIOpenCV` é o componente mais funcional desta aba no estado atual.

Ele usa um worker Python para chamar OpenCV por processo externo.

Worker:

```text
pacote/python/aiopencv_worker.py
```

Dependências Python:

```bash
pip install opencv-python numpy
```

### Ações suportadas atualmente

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

### Observação sobre backend nativo

O backend `Native DLL` está previsto, mas ainda não deve ser tratado como funcional.

O backend recomendado atualmente é:

```text
Python Process
```

---

## Sample funcional

Caminho:

```text
pacote/samples/AI Vision/opencv_filter_demo/
```

Esse sample demonstra:

* SelfTest;
* carregamento de imagem;
* leitura de informações da imagem;
* aplicação de filtros básicos;
* preview antes/depois;
* salvamento do resultado;
* log de execução.

Arquivo de imagem de teste:

```text
pacote/samples/AI Vision/opencv_filter_demo/sample.jpg
```

---

## Limitações atuais

* `TAIOpenCV` ainda depende de Python para funcionar.
* O backend nativo via DLL/SO ainda não está implementado.
* Câmera, face tracker e motion tracker ainda precisam de implementação ou validação real.
* Esta aba deve ser considerada Beta/Experimental conforme o componente utilizado.

---

## Próximos passos recomendados

* Criar timeout/cancelamento no processamento OpenCV.
* Adicionar filtros novos somente após estabilizar os atuais.
* Criar samples separados para câmera, face tracker e motion tracker.
* Validar funcionamento em Windows e Linux.
* Documentar versões de Python/OpenCV testadas.
