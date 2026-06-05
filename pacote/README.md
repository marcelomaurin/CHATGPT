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
| `openai_core.lpk` | Base comum, LLM, prompt builder, model registry, wizard, projeto e pipeline |
| `openai_ml.lpk` | Machine learning simples, matrizes e utilitários matemáticos |
| `openai_graph.lpk` | Grafos, classificação, exportação, análise e relatórios |
| `openai_python.lpk` | Integração Python, YOLO, face, CNN e LSTM |
| `openai_vision.lpk` | OpenCV, câmera, frame, face tracker e motion tracker |
| `openai_image.lpk` | Filtros simples de imagem |
| `openai_voice.lpk` | Voz, áudio e filtros sonoros |
| `openai_input.lpk` | Entrada de dados, comunicação, sensores e protocolos |
| `openai_output.lpk` | Saída de dados, documentos e impressoras |
| `openai_industrial.lpk` | Modbus, MQTT e componentes industriais |
| `openai_graphic.lpk` | 3D, viewer, avatar, cena e Tripo3D |
| `openai_agent.lpk` | Agentes, segurança e executores |

---

## Pacote legado

```text
pacote/openai.lpk
```

Esse pacote é um **legacy wrapper**. Ele depende dos pacotes modulares e foi mantido para compatibilidade com projetos antigos.

Para novos projetos, prefira instalar diretamente os pacotes em `pacote/packages/`.

---

## Ordem recomendada de instalação

1. `packages/openai_core.lpk`
2. `packages/openai_ml.lpk`
3. `packages/openai_graph.lpk`
4. `packages/openai_output.lpk`
5. `packages/openai_input.lpk`
6. `packages/openai_python.lpk`
7. `packages/openai_vision.lpk`
8. `packages/openai_image.lpk`
9. `packages/openai_voice.lpk`
10. `packages/openai_industrial.lpk`
11. `packages/openai_graphic.lpk`
12. `packages/openai_agent.lpk`

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

Sample funcional atual:

```text
samples/AI Vision/opencv_filter_demo/
```

Esse demo usa `TAIOpenCV` com Python + OpenCV para processar imagens em uma interface gráfica Lazarus.

---

## Observações técnicas

* Nem todos os componentes estão no mesmo nível de maturidade.
* Alguns componentes ainda são experimentais ou placeholders.
* Componentes Python, OpenCV, industrial, 3D e agentes podem exigir dependências externas.
* O pacote `openai_core.lpk` ainda inclui `TAIPipeline`, que possui acoplamento com várias áreas. Isso deve ser revisto futuramente.
