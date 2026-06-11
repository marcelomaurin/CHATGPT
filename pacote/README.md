# Lazarus AI Suite — Package Index

Esta pasta contém os pacotes, units, scripts auxiliares e samples da suíte **TCHATGPT / Lazarus AI Suite**.

A organização atual é **modular**. O antigo pacote monolítico `openai.lpk` foi mantido apenas como wrapper legado de compatibilidade.

---

## Estrutura principal

```text
pacote/
  packages/          # Pacotes Lazarus modulares recomendados
  IA/                # Componentes centrais, LLM, ML simples e utilitários
  IA Agent/          # Agentes, ações, segurança e executores
  IA Graph/          # Grafos, datasets, classificação e relatórios
  IA Image/          # Filtros simples de imagem
  IA Input/          # Entrada, sensores, comunicação e integrações
  IA Math/           # Matemática, matrizes e estatística
  IA Output/         # Saídas, documentos e relatórios
  IA Voice/          # Voz, áudio e filtros sonoros
  AI Vision/         # OpenCV e visão computacional
  AI Graphic/        # Visualização 3D, avatar e modelos
  python/            # Workers/scripts Python usados por componentes
  samples/           # Projetos de demonstração
```

---

## Pacotes recomendados

Os pacotes principais ficam em:

```text
pacote/packages/
```

| Pacote | Finalidade |
|---|---|
| `openai_core.lpk` | Base comum, LLM, prompt builder, model registry, wizard, projeto, pipeline e integração Python (TPythonConnector, TYoloDetect, TFaceDetection, TCNNClassifier, TLSTMPredictor) |
| `openai_ml.lpk` | Machine learning simples, matrizes e utilitários matemáticos |
| `openai_graph.lpk` | Grafos, classificação, exportação, análise e relatórios |
| `openai_vision.lpk` | OpenCV, camera native backends (VFW/V4L2), frame, face tracker and motion tracker |
| `openai_image.lpk` | Filtros simples de imagem |
| `openai_voice.lpk` | Voz, áudio e filtros sonoros |
| `openai_input.lpk` | Entrada de dados: **TAICaptureSource** (captura unificada), comunicação, sensores e protocolos |
| `openai_output.lpk` | Saída de dados, documentos e impressoras |
| `openai_industrial.lpk` | Modbus, MQTT e componentes industriais |
| `openai_graphic.lpk` | 3D, viewer, avatar, cena e Tripo3D |
| `openai_agent.lpk` | Agentes, segurança e executores |
| `openai_simulation.lpk` | Simulação celular 2D: grade, entidades, regras, movimento, evolução e exportação |
| `openai_full.lpk` | Wrapper que agrega todos os pacotes acima |

---

## Pacote legado

```text
pacote/openai.lpk
```

Esse pacote é um **legacy wrapper**. Ele depende dos pacotes modulares e foi mantido para compatibilidade com projetos antigos.

Para novos projetos, prefira instalar diretamente os pacotes em `pacote/packages/`.

---

## Ordem recomendada de instalação

1. `packages/openai_core.lpk` (inclui os componentes de integração Python)
2. `packages/openai_ml.lpk`
3. `packages/openai_graph.lpk`
4. `packages/openai_output.lpk`
5. `packages/openai_input.lpk`
6. `packages/openai_vision.lpk`
7. `packages/openai_image.lpk`
8. `packages/openai_voice.lpk`
9. `packages/openai_industrial.lpk`
10. `packages/openai_graphic.lpk`
11. `packages/openai_agent.lpk`
12. `packages/openai_simulation.lpk`
13. `packages/openai_full.lpk` *(opcional — agrega todos)*

Instale apenas os pacotes necessários ao seu projeto.

---

## Documentação por área

Cada pasta funcional deve conter um `README.md` com:

* componentes da área;
* unit de origem;
* pacote Lazarus onde o componente está registrado;
* status de maturidade;
* dependências externas;
* samples disponíveis.

A matriz geral de maturidade fica em:

```text
COMPONENT_STATUS.md
```

---

## Python workers

A pasta:

```text
python/
```

contém scripts usados por componentes que chamam recursos externos via processo Python.

Exemplo atual:

```text
python/aiopencv_worker.py
```

Esse worker é usado por `TAIOpenCV` para processamento básico de imagem com OpenCV.

---

## Samples

Os samples ficam em:

```text
samples/
```

Samples funcionais:

```text
samples/AI Vision/opencv_filter_demo/
samples/IA Input/capture_source_demo/    ← TAICaptureSource (todos os 5 modos)
samples/IA Input/hardware_net_demo/
```

---

## Observações técnicas

* Nem todos os componentes estão no mesmo nível de maturidade.
* Alguns componentes ainda são experimentais ou placeholders.
* Componentes Python, OpenCV, industrial, 3D e agentes podem exigir dependências externas.
* O pacote `openai_core.lpk` ainda inclui `TAIPipeline`, que possui acoplamento com várias áreas. Isso deve ser revisto futuramente.
