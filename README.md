# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌍 **Languages / Idiomas**

* [Português (PT-BR)](README.md)
* [English (EN)](README_EN.md)
* [Español (ES)](README_ES.md)
* [Français (FR)](README_FR.md)
* [Italiano (IT)](README_IT.md)
* [العربية (AR)](README_AR.md)
* [中文 (CH)](README_CH.md)
* [Русский (RU)](README_RU.md)
* [日本語 (JP)](README_JP.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow.svg)]()

---

## Visão geral

**TCHATGPT** é uma suíte open source de componentes visuais e não visuais para **Lazarus / Free Pascal**, criada para facilitar a integração de recursos de Inteligência Artificial em aplicações desktop, industriais, educacionais e corporativas.

O projeto oferece componentes para conexão com provedores de LLM, modelos locais, processamento de dados, aprendizado de máquina simples, voz, imagem, grafos, agentes, canais de entrada/saída, visão computacional e visualização 3D.

> Este projeto deve ser entendido como uma **suíte de componentes para integração de IA em aplicações Lazarus**, e não como uma plataforma completa para substituir frameworks especializados de treinamento, MLOps ou implantação de modelos em larga escala.

---

## Situação atual

O projeto está em desenvolvimento ativo e possui componentes em diferentes níveis de maturidade.

Use a matriz oficial em:

```text
pacote/COMPONENT_STATUS.md
```

Classificação usada:

| Status | Significado |
|---|---|
| Stable | Base consolidada e de baixo risco |
| Beta | Funcional, mas ainda precisa validação ampla |
| Experimental | API ou comportamento ainda pode mudar |
| Placeholder | Estrutura existe, mas ainda não entrega função real completa |
| Deprecated | Mantido apenas por compatibilidade |

---

## Arquitetura modular dos pacotes

A suíte é organizada em pacotes modulares dentro de:

```text
pacote/packages/
```

Para novos projetos, use diretamente os pacotes modulares.

| Pacote | Finalidade | Uso recomendado |
|---|---|---|
| `openai_core.lpk` | Componentes centrais, LLM, base comum, utilitários principais e integração Python (TPythonConnector, TYoloDetect, TFaceDetection, TCNNClassifier, TLSTMPredictor) | Instalar primeiro |
| `openai_ml.lpk` | Machine learning simples e matemática em Pascal | Opcional |
| `openai_graph.lpk` | Grafos, classificação por grafo e relatórios de treinamento | Opcional |
| `openai_vision.lpk` | OpenCV, câmera, frame, face e movimento | Opcional |
| `openai_image.lpk` | Filtros simples de imagem sem OpenCV | Opcional |
| `openai_voice.lpk` | Voz, áudio e filtros sonoros | Opcional |
| `openai_input.lpk` | Entrada, sensores, sockets, serial, e-mail, browser e protocolos | Opcional |
| `openai_output.lpk` | Saídas, documentos, PDF, TXT e relatórios | Opcional |
| `openai_industrial.lpk` | Modbus, MQTT e automação industrial | Experimental |
| `openai_graphic.lpk` | Visualização 3D, STL/OBJ, avatar e Tripo3D | Experimental |
| `openai_agent.lpk` | Agentes, segurança, ações e executores | Experimental |

---

## Instalação recomendada no Lazarus

1. Abra o Lazarus.
2. Acesse **Package > Open Package File (.lpk)**.
3. Instale primeiro:

```text
pacote/packages/openai_core.lpk
```

4. Compile e instale.
5. Instale apenas os pacotes adicionais necessários ao seu projeto.
6. Recompile a IDE quando o Lazarus solicitar.

### Ordem recomendada

```text
1. pacote/packages/openai_core.lpk
2. pacote/packages/openai_ml.lpk
3. pacote/packages/openai_graph.lpk
4. pacote/packages/openai_output.lpk
5. pacote/packages/openai_input.lpk
6. pacote/packages/openai_vision.lpk
7. pacote/packages/openai_image.lpk
8. pacote/packages/openai_voice.lpk
9. pacote/packages/openai_industrial.lpk
10. pacote/packages/openai_graphic.lpk
11. pacote/packages/openai_agent.lpk
```

---

## Dependências externas por pacote

| Pacote | Dependências comuns |
|---|---|
| `openai_core` | Lazarus, FPC, LCL, FCL, OpenSSL para HTTPS. Para componentes de integração Python: Python 3, arquitetura compatível e bibliotecas Python conforme componente |
| `openai_ml` | Sem Python obrigatório; usa Pascal/FPC |
| `openai_graph` | `openai_core`, `openai_ml` |
| `openai_vision` | Para `TAIOpenCV`: Python 3, `opencv-python`, `numpy`. Componentes nativos usam LCL/FPC; `TAICameraCapture` usa VFW no Windows |
| `openai_voice` | Windows SAPI ou Linux eSpeak/eSpeak-NG conforme uso |
| `openai_output` | `fpPDF`/FPC para PDF; Word/Excel podem ser HTML compatível |
| `openai_industrial` | Dependências de Modbus/MQTT e permissões do ambiente |
| `openai_graphic` | Dependências gráficas conforme viewer/3D |
| `openai_agent` | Depende de segurança e confirmação explícita para ações reais |

---

## Componentes principais

### AI Core

Componentes centrais:

* `TAIBaseComponent`
* `TCHATGPT`
* `TTokenList`
* `TAICodeAssistant`
* `TAIPromptBuilder`
* `TAIModelRegistry`
* `TAIWizardConfig`
* `TAIProject`
* `TAIPipeline`

> Nota técnica: atualmente `TAIPipeline` ainda está no pacote core, mas ele depende conceitualmente de módulos como agente, input, output, industrial e grafo. A meta futura é separá-lo em um pacote próprio ou reduzir o acoplamento.

### AI Vision

A camada de Visão Computacional do projeto é dividida em duas abordagens:

#### 1. AI Native Vision (100% Lazarus / Free Pascal)

Componentes Pascal, sem dependência de Python, OpenCV ou executores externos. Estão registrados principalmente na aba **`AI Native Vision`** da IDE e utilizam recursos como `TBitmap` e `TLazIntfImage`.

* `TAICameraCapture`: captura de câmera/webcam via Windows VFW/`avicap32.dll`. No Linux, a versão atual ainda retorna stub/erro de plataforma não suportada.
* `TAINativeImageFilter`: filtros de imagem nativos, como cinza, threshold, inverter, resize e blur box.
* `TAIImageInfo`: extração nativa de dimensões e informações básicas de imagem.
* `TAIFrameBuffer`: buffer circular de frames em memória para processamento de vídeo.
* `TAIMotionTracker`: detecção de movimento por variação de luminância entre bitmaps.
* `TAIFrameDiff`: geração de mapa de diferença absoluta entre frames.
* `TAIFaceTracker`: rastreador local baseado em template matching/SAD. Não é detector facial semântico.

Samples nativos previstos ou em validação:

* `pacote/samples/AI Native Vision/camera_capture_demo/`
* `pacote/samples/AI Native Vision/native_image_filter_demo/`
* `pacote/samples/AI Native Vision/motion_tracker_demo/`

#### 2. AI Python Vision (Integração Externa)

Componentes que realizam chamadas ou utilizam scripts Python externos para executar tarefas mais pesadas:

* `TAIOpenCV`: funcional via worker Python. Possui sample funcional em `pacote/samples/AI Vision/opencv_filter_demo/`.
  * Recursos atuais do `TAIOpenCV`: `SelfTest`, `Image Info`, `Gray`, `Blur`, `Canny`, `Threshold`, `Resize`.
  * Dependências do OpenCV Python: `pip install opencv-python numpy`.

### AI Output

Componentes de documentos e saídas. Atenção: quando a saída Word/Excel for feita por HTML compatível, a documentação do componente deve indicar isso claramente, sem prometer DOCX/XLSX nativo.

### AI Agent

Agentes são experimentais e devem ser usados com segurança. Ações reais de arquivo, rede, e-mail, industrial ou automação devem exigir configuração explícita e validação do usuário.

---

## Provedores de LLM

| Provedor | Enum | Tipo |
|---|---|---|
| OpenAI | `AIP_OPENAI` | API externa |
| OpenRouter | `AIP_OPENROUTER` | API externa/agregador |
| Cerebras | `AIP_CEREBRAS` | API externa |
| Google Gemini | `AIP_GEMINI` | API externa |
| Anthropic Claude | `AIP_CLAUDE` | API externa |
| Local/Ollama/compatível | `AIP_LOCAL` | Servidor local |

> Modelos, custos, limites e disponibilidade mudam conforme cada provedor. Sempre confira a documentação oficial do serviço usado.

---

## Samples

Os projetos de demonstração ficam em:

```text
pacote/samples/
```

Sample atualmente consolidado:

| Sample | Tipo | Pacote | Dependência externa | Status |
|---|---|---|---|---|
| `opencv_filter_demo` | GUI | `openai_vision` | Python + OpenCV | Funcional/Beta |

Samples nativos em validação/documentação:

| Sample | Tipo | Pacote | Dependência externa | Status |
|---|---|---|---|---|
| `camera_capture_demo` | GUI | `openai_vision` | Webcam VFW no Windows | Em validação |
| `native_image_filter_demo` | GUI | `openai_vision` | Nenhuma | Previsto/em validação |
| `motion_tracker_demo` | GUI | `openai_vision` | Nenhuma | Previsto/em validação |

---

## Limitações conhecidas

* O projeto ainda está em desenvolvimento.
* Nem todos os componentes possuem demonstração completa.
* Alguns componentes são placeholders ou experimentais.
* Integrações externas dependem de APIs, bibliotecas e permissões de terceiros.
* Componentes Python dependem de versão, arquitetura e ambiente compatíveis.
* É recomendado validar cada componente antes de uso em produção.
* Testes automatizados e integração contínua ainda precisam ser ampliados.
* `TAICameraCapture` usa VFW no Windows; Linux ainda precisa backend próprio.
* `TAIFaceTracker` rastreia template, não detecta rosto semanticamente.

---

## Roadmap

### Curto prazo

* validar compilação dos pacotes modulares em Windows e Linux;
* manter `COMPONENT_STATUS.md` atualizado;
* completar documentação técnica por aba;
* criar pelo menos um sample real por pacote principal;
* revisar o acoplamento do `TAIPipeline`.

### Médio prazo

* criar testes automatizados com `lazbuild`;
* criar releases versionadas;
* documentar dependências externas por componente;
* melhorar tratamento de erros;
* consolidar OpenCV, grafos, output e agentes.

### Longo prazo

* criar templates de projetos;
* criar assistente visual de configuração;
* consolidar componentes 3D;
* melhorar integração com modelos locais;
* evoluir agentes com controle de segurança;
* criar documentação de produção.

---

## Para quem este projeto é indicado?

* Desenvolvedores Lazarus/Free Pascal.
* Professores e estudantes.
* Projetos desktop com IA.
* Automação local.
* Sistemas corporativos legados.
* Prototipação de IA.
* Integração de IA com dispositivos e aplicações existentes.

---

## Para quem este projeto ainda não é indicado?

Neste momento, o projeto ainda não substitui:

* frameworks completos de machine learning;
* plataformas de MLOps;
* pipelines corporativos de treinamento;
* serviços profissionais de deploy de modelos;
* bibliotecas especializadas como PyTorch, TensorFlow, scikit-learn ou OpenCV completo;
* infraestrutura de IA em escala empresarial.

---

## Contribuindo

Contribuições são bem-vindas, especialmente em:

* correção de bugs;
* samples funcionais;
* documentação;
* testes automatizados;
* compatibilidade Windows/Linux;
* validação dos pacotes modulares;
* melhorias de segurança;
* integração com provedores de IA.

---

## Licença

Este projeto está licenciado sob a **GNU General Public License v3.0**.

Consulte o arquivo `LICENSE`.

---

## Aviso

Este projeto utiliza ou integra serviços externos de IA. O uso desses serviços pode envolver custos, limites de API, políticas próprias e envio de dados para terceiros.

Antes de usar em produção:

* revise os termos do provedor;
* proteja suas chaves de API;
* não envie dados sensíveis sem autorização;
* valide segurança, privacidade e conformidade;
* teste o comportamento do componente no ambiente real.
