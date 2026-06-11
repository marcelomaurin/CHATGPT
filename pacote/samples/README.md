# Demonstration Projects — Samples

Esta pasta contém projetos de demonstração para validar componentes da **Lazarus AI Suite**.

Os samples devem ser documentados por **pacote modular**, não apenas pelo antigo pacote monolítico `openai_core.lpk`.

---

## Organização

Os samples podem ser:

| Tipo | Descrição |
|---|---|
| GUI | Aplicações visuais Lazarus com formulários, botões, imagens e logs |
| Console | Projetos `.lpr` simples para testes automatizados ou uso em linha de comando |

Cada sample deve conter, quando aplicável:

```text
sample_name.lpi
sample_name.lpr
main.pas
main.lfm
README.md
arquivos de entrada de teste
```

---

## Samples OpenCV/IA confirmados nos fontes

| Sample | Tipo | Pacote necessário | Componentes/units usados | Backend | Status |
|---|---|---|---|---|---|
| `AI Vision/opencv_filter_demo` | GUI | `openai_vision.lpk` | `TAIOpenCV`, `aiopencvruntime`, `aiplatform` | Python Process + Native DLL com fallback | Funcional/Beta |
| `AI Vision/opencv_image_real_demo` | GUI | `openai_vision.lpk` | `TAIOpenCV`, `TAIFrameProcessor`, `aiopencvruntime`, `aiplatform` | Native DLL com fallback Python e modo simulação | Funcional/Beta |
| `IA Python/cnn_classifier_complete_demo` | GUI | `openai_core.lpk` | `TCNNClassifier`, `TPythonConnector`, `pythonconnector` | Python DLL/SO (TensorFlow) | Funcional |

---

## Sample: CNN Classifier Complete Demo

Caminho:

```text
pacote/samples/IA Python/cnn_classifier_complete_demo/
```

Esse sample demonstra o componente `TCNNClassifier` e `TPythonConnector` em uma interface gráfica Lazarus para classificar imagens usando redes neurais convolucionais (CNN).

Recursos demonstrados:

* Inicialização de runtime Python embarcado em 64-bits;
* carregamento de modelo CNN (`weights.h5` customizado ou fallback automático para MobileNetV2 pré-treinado no ImageNet);
* carregamento e classificação de imagens selecionadas dinamicamente via `TComboBox` na pasta `/imagem`;
* exibição instantânea do preview de imagem (`TImage`);
* exibição do resultado da classificação (Classe identificada e confiança) diretamente na tela principal;
* uso de máscara de exceção de ponto flutuante (`SetExceptionMask`) para compatibilidade com inicializadores do TensorFlow/HDF5;
* reaproveitamento de sessão ativa do Python para evitar falhas consecutivas de re-inicialização do TensorFlow.

Dependências:

```bash
pip install tensorflow numpy pillow
```

---

## Sample: TAIOpenCV Filter Demo

Caminho:

```text
pacote/samples/AI Vision/opencv_filter_demo/
```

Esse sample demonstra o componente `TAIOpenCV` em uma interface gráfica Lazarus.

Recursos demonstrados:

* SelfTest do OpenCV;
* carregamento de imagem;
* leitura de metadados da imagem;
* filtros `None`, `Gray`, `Blur`, `Canny`, `Threshold` e `Resize`;
* seleção de backend `Python Process` ou `Native DLL`;
* detecção automática do runtime OpenCV nativo usando `aiopencvruntime`;
* fallback automático para Python quando o backend nativo não está disponível;
* visualização da imagem original e processada;
* salvamento do resultado;
* log de execução.

Dependências para backend Python:

```bash
pip install opencv-python numpy
```

Worker usado pelo backend Python:

```text
pacote/python/aiopencv_worker.py
```

---

## Sample: OpenCV Image Real Demo

Caminho:

```text
pacote/samples/AI Vision/opencv_image_real_demo/
```

Esse sample demonstra uso combinado de:

```text
TAIOpenCV
TAIFrameProcessor
aiopencvruntime
```

Recursos demonstrados:

* detecção do runtime OpenCV no `FormCreate`;
* uso de `TAIFrameProcessor` para parâmetros de processamento de frame;
* tentativa de uso de backend `Native DLL` quando a DLL/SO compatível é encontrada;
* fallback para `Python Process` quando o runtime nativo não está disponível ou falha ao carregar;
* modo de simulação para validar a interface sem runtime externo;
* log detalhado de sistema, arquitetura, pasta esperada e biblioteca resolvida.

---

## OpenCV runtime nos samples

Samples OpenCV que suportam backend nativo devem procurar primeiro nas pastas versionadas do projeto:

```text
runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
runtime/opencv/linux/x64/lib/
runtime/opencv/linux/arm64/lib/
runtime/opencv/linux/armhf/lib/
```

A unit comum de localização está em:

```text
pacote/AI Vision/aiopencvruntime.pas
```

A busca deve priorizar o runtime embarcado antes de `PATH`, `LD_LIBRARY_PATH`, `/usr/lib`, `/usr/local/lib` ou DLLs instaladas globalmente.

No Windows, o padrão esperado é:

```text
opencv_world*.dll
```

No Linux, o padrão esperado é:

```text
libopencv_world.so*
```

---

## Limitação importante do backend nativo

O backend `Native DLL` do `TAIOpenCV` hoje já localiza e carrega a DLL/SO nativa, mas o processamento real de imagem ainda não chama funções OpenCV nativas. No código atual, o processamento nativo é tratado como etapa simulada/cópia de arquivo.

Para processamento real com filtros OpenCV, o backend recomendado continua sendo:

```text
Python Process
```

---

## Regras para novos samples

Todo novo sample deve informar:

* pacote Lazarus necessário;
* componentes demonstrados;
* dependências externas;
* comandos de teste manual, quando houver;
* status do sample;
* se é GUI ou console;
* se exige API key, Python, OpenCV, hardware, banco ou serviço externo;
* se usa backend nativo, Python ou fallback;
* caminho do runtime esperado quando depender de DLL/SO.

---

## Status dos samples

Use a mesma classificação da matriz de componentes:

| Status | Significado |
|---|---|
| Funcional | Abre, compila e demonstra recurso real |
| Beta | Funciona, mas ainda precisa validação ampla |
| Experimental | Demonstra API em evolução |
| Placeholder | Estrutura existe, mas não comprova função real |
| Pendente | Ainda precisa ser criado |
