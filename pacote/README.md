# Lazarus AI Suite — Package Index

Esta pasta contém os pacotes, units, scripts auxiliares e samples da suíte **TCHATGPT / Lazarus AI Suite**.

A organização é **modular** para facilitar a manutenção e permitir instalações parciais.

---

## Estrutura principal

```text
pacote/
  packages/          # Pacotes Lazarus modulares recomendados
  IA/                # Componentes centrais, LLM, ML simples e utilitários
  AI Agent/          # Agentes, ações, segurança e executores
  AI Graph/          # Grafos, datasets, classificação e relatórios
  AI Image/          # Filtros simples de imagem
  AI Input/          # Entrada, sensores, comunicação e integrações
  AI Math/           # Matemática, matrizes e estatística
  AI Output/         # Saídas, documentos e relatórios
  AI Files/          # Escaneamento, indexação de diretórios e gerenciamento de arquivos
  AI Voice/          # Voz, áudio e filtros sonoros
  AI Vision/         # OpenCV e visão computacional
  AI Graphic/        # Visualização 3D, avatar e modelos
  AI DBase/          # Dicionários de dados e metadados de bancos
  python/            # Workers/scripts Python usados por componentes
  samples/           # Projetos de demonstração
```

---

## Pacotes recomendados

Os pacotes principais ficam em:

```text
pacote/packages/
```

| Pacote | Finalidade | Status |
|---|---|---|
| `openai_core.lpk` | Base comum, LLM, prompt builder, model registry e dicionário de tokens | **Essencial** |
| `openai_python.lpk` | Conectores Python e executores de modelos (TPythonConnector, TYoloDetect, TFaceDetection, TCNNClassifier, TLSTMPredictor, TAIPythonRuntime) | **Opcional** |
| `openai_ml.lpk` | Machine learning simples, matrizes e utilitários matemáticos | **Opcional** |
| `openai_graph.lpk` | Grafos, classificação, exportação, análise e relatórios | **Opcional** |
| `openai_files.lpk` | Escaneamento de diretórios, Disk Tree Scanner e gerenciamento físico de arquivos | **Opcional** |
| `openai_output.lpk` | Saída de dados, documentos e relatórios | **Opcional** |
| `openai_input.lpk` | Entrada de dados, captura unificada (TAICaptureSource), e-mail, sockets e serial | **Opcional** |
| `openai_vision.lpk` | OpenCV, backends nativos de câmera (VFW/V4L2), face e motion tracker, pose detector (MediaPipe) | **Opcional** |
| `openai_image.lpk` | Filtros simples de imagem nativos | **Opcional** |
| `openai_voice.lpk` | Voz, áudio e filtros sonoros | **Opcional** |
| `openai_simulation.lpk` | Simulação celular 2D: grade, entidades, regras, movimento e evolução | **Opcional** |
| `openai_industrial.lpk` | Modbus, MQTT e componentes industriais | **Experimental** |
| `openai_graphic.lpk` | 3D, viewer, avatar, cena e Tripo3D | **Experimental** |
| `openai_agent.lpk` | Agentes, segurança, executores, projetos (TAIProject), pipeline (TAIPipeline) e wizard de configuração (TAIWizardConfig) | **Beta** |
| `openai_aidbase.lpk` | Dicionários de dados e metadados de bancos de dados para IA (TAIPostgreSQLDictionary, TAISQLiteDictionary, etc.) | **Opcional** |

> **Nota sobre o Pacote Legado**: O pacote antigo `openai.lpk` foi totalmente removido. Utilize os pacotes modulares da lista acima.

---

## Ordem recomendada de instalação

1. `packages/openai_core.lpk` (Essencial)
2. `packages/openai_python.lpk` (Opcional - Conectores Python)
3. `packages/openai_ml.lpk`
4. `packages/openai_graph.lpk`
5. `packages/openai_files.lpk`
6. `packages/openai_output.lpk`
7. `packages/openai_input.lpk`
8. `packages/openai_vision.lpk`
9. `packages/openai_image.lpk`
10. `packages/openai_voice.lpk`
11. `packages/openai_simulation.lpk`
12. `packages/openai_industrial.lpk`
13. `packages/openai_graphic.lpk`
14. `packages/openai_agent.lpk`
15. `packages/openai_aidbase.lpk` (Opcional - Dicionário de Dados)

Instale apenas os pacotes necessários ao seu projeto.
Recompile a IDE quando solicitado.

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
samples/AI Input/capture_source_demo/           ← TAICaptureSource (todos os 5 modos)
samples/AI Input/hardware_net_demo/
samples/AI Voice/voice_synthesizer_complete_demo/ ← TAIVoiceSynthesizer (local e OpenAI real)
```

---

## Observações técnicas

* Nem todos os componentes estão no mesmo nível de maturidade.
* Alguns componentes ainda são experimentais ou placeholders.
* Componentes Python, OpenCV, industrial, 3D e agentes podem exigir dependências externas.
* O pacote `openai_core.lpk` ainda inclui `TAIPipeline`, que possui acoplamento com várias áreas. Isso deve ser revisto futuramente.