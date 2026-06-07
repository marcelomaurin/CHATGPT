# Changelog - Lazarus AI Suite

Todas as alterações relevantes para a suíte de componentes Lazarus AI Suite serão registradas neste arquivo.

## [1.8.0] - 2026-06-07

### Adicionado
- **AI Simulation — Ícones completos**: Todos os 13 componentes do pacote `openai_simulation` receberam ícones na paleta do Lazarus IDE (`TAIGridWorld`, `TAISimEntity`, `TAIEntityFactory`, `TAISimulationEngine`, `TAIRuleEngine`, `TAITriggerEngine`, `TAIMovementEngine`, `TAIEvolutionEngine`, `TAISimulationStats`, `TAIGridRenderer2D`, `TAIScenarioConfig`, `TAIScenarioGenerator`, `TAISimulationExporter`). Gerados 13 arquivos `.lrs` com cor identificadora verde-azulada.
- **`generate_all_icons.py`**: Adicionada cor `C_SIMULATION` e entradas para todos os componentes do pacote AI Simulation. Os `.pas` foram patchados automaticamente com `LResources` e bloco `initialization`.
- **`news/`**: Criada pasta de novidades diárias com arquivo `news/2026-06-07.md` documentando todas as alterações do dia.

### Corrigido
- **AI Vision — Ícones faltantes**: 4 componentes nativos de visão estavam sem ícone na paleta: `TAIImageInfo`, `TAIFrameBuffer`, `TAINativeImageFilter` e `TAIFrameDiff`. Criados os respectivos arquivos `.lrs` e adicionado bloco `initialization` em cada `.pas`.
- **`install_components.bat` / `install_components.sh`**: Adicionados `openai_simulation.lpk` e `openai_full.lpk` que estavam faltando nos modos `recommended` e `all`. Scripts agora executam `lazbuild --build-ide=` automaticamente ao final de uma instalação bem-sucedida.

---

## [1.7.0] - 2026-06-02

### Adicionado
- **TAIBaseComponent**: Nova classe base comum (`aibase.pas`) que unifica logs estruturados (`OnLog`, `TAILogLevel`, `TAILogEvent`), versão global da suíte (`AI_SUITE_VERSION`) e propriedades comuns de controle de erro (`Prompt`, `LastError`, `LastResult`, `LastSuccess`).
- **TAIGraphMap**: Novo componente de classificação textual local e explicável baseado em grafo ponderado de tokens (IA local leve, sem necessidade de LLM ou GPU externos).
- **TAIProject**: Novo componente coordenador de projetos de IA, permitindo carregar e salvar definições de forma segura e gerenciar modos de simulação.
- **TAIPipeline**: Novo componente para orquestrar esteiras operacionais e conectar percepção a modelos e a geradores de documentos. Suporta classificação local usando `TAIGraphMap` com o modo `pmGraphMapClassification`.
- **TAIPromptBuilder**: Varrimento inteligente de componentes e formulários com suporte a idiomas (Português, Inglês, Espanhol) e múltiplos formatos de saída (Text, Markdown, JSON).
- **TAIAgentSafety**: Camada de proteção física para agentes autônomos com normalização estrita de diretórios, fallbacks de portas de rede (como HTTPS para 443) e confirmações de ações com o evento `OnConfirmAction`.
- **aiagent_executors.pas**: Novo módulo contendo executores modulares desacoplados (`TAIAgentDocsExecutor`, `TAIAgentNetworkExecutor`, `TAIAgentIndustrialExecutor`, `TAIAgentMessagingExecutor`, `TAIAgentHardwareExecutor`) para processar ações físicas solicitadas pelo Agente.

### Modificado
- `TAIAgent` agora herda de `TAIBaseComponent` e armazena os detalhes da sua última tomada de decisão no novo objeto encapsulado `TAIAgentDecision`.
- Refatorado `TAIAgentResourceItem.Execute` para utilizar o despachante de executores modulares em vez de manter uma lógica monolítica gigante.
- Refatorado `TAIModbusClient`, `TAIMQTTClient` e `TAIIndustrialBridge` para herdar de `TAIBaseComponent`.
- `TAIMQTTClient` agora armazena os campos `LastTopic` e `LastPayload` ao receber mensagens de tópicos subscritos.
- Melhorada a injeção RTTI de propriedades em recursos de agentes com suporte a listas de segurança de propriedades permitidas (`AllowedProperties`) e bloqueadas (`BlockedProperties`), além de suportar tipos enums e inteiros longos de 64 bits (`Int64`).

### Corrigido
- Corrigido vazamento potencial de API Keys no `TAIProject.SaveToFile` criando a propriedade `SaveToken` desativada por padrão.
- Corrigida validação de caminho seguro no `TAIAgentSafety` prevenindo desvio com comparação prefixada estrita.
- Corrigido check de objeto `Action` nulo no método `RunAgent` da classe `TAIPipeline` para evitar falhas de Access Violation.
- Corrigido trecho de instrução de idioma misto no prompt do Agente (`entre las listadas` alterado para `entre as listadas`).

---

## [1.6.0] - 2026-05-xx

### Adicionado
- **AI Simulation — Pacote completo**: Implementados todos os componentes do pacote `openai_simulation` com demos funcionais: `robot_grid_demo`, `service_queue_demo`, `contamination_demo`, `warehouse_agents_demo`.
- Componentes adicionados: `TAIGridWorld`, `TAIGridCell`, `TAIGridBuffer`, `TAISimEntity`, `TAIEntityFactory`, `TAISimulationEngine`, `TAIRuleEngine`, `TAITriggerEngine`, `TAIMovementEngine`, `TAIEvolutionEngine`, `TAISimulationStats`, `TAIGridRenderer2D`, `TAIScenarioConfig`, `TAIScenarioGenerator`, `TAISimulationExporter`.
- **`graph_visualizer_demo`**: Demo corrigido com propriedades corretas de `TAIGraphVisualizer` e método de exportação visual.

### Documentado
- Bugs conhecidos registrados para `avatar_demo`, `contamination_demo`, `warehouse_agents_demo`, `service_queue_demo`, `graph_visualizer_demo` e `robot_grid_demo`.

---

## [1.5.0] - 2026-05-xx

### Adicionado
- **AI Native Vision Layer**: Implementada camada de visão nativa multiplataforma sem dependência do OpenCV: `TAICameraCapture` (backend Windows VFW nativo), `TAINativeImageFilter`, `TAIMotionTracker` (detecção por luminância), `TAIFrameBuffer`, `TAIFrameDiff`, `TAIFaceTracker` (rastreamento por template nativo).
- `TAIImageInfo`: Componente de metadados de imagem.
- Suporte a câmera Linux via V4L2 (`aicamera_v4l2.pas`) e Windows VFW (`aicamera_vfw.pas`) com abstração via `aicamera_backend.pas`.

### Modificado
- `TAICameraCapture` refatorado para backend Windows VFW puro sem dependências externas.
- `TAIOpenCV` atualizado para usar runtime Python seguro com `TAISafeProcessRunner`.
- Detecção inteligente de runtime OpenCV com suporte a libraries placeholder identificadas por tamanho.

### Corrigido
- Corrigido `PreviewHandle` para usar `pnlCamera.Handle` antes de iniciar câmera no `opencv_vision_demo`.
- Corrigidos erros de compilação e incompatibilidade de tipos em demos de visão e câmera.

---

## [1.4.0] - 2026-05-xx

### Adicionado
- **Runtime OpenCV multiplataforma**: Adicionados templates de runtime para Windows x86/x64, Linux x64/arm64, Windows 7 x86/x64 (legado).
- **Scripts de instalação**: `install_components.bat` (Windows) e `install_components.sh` (Linux) com modos `core`, `recommended` e `all`.
- **Sistema de pacotes modular**: `openai_core`, `openai_ml`, `openai_graph`, `openai_output`, `openai_input`, `openai_python`, `openai_vision`, `openai_image`, `openai_voice`, `openai_industrial`, `openai_graphic`, `openai_agent`, `openai_simulation`, `openai_full`.
- **Guia de instalação** (`INSTALL.md`) com instruções detalhadas para Windows e Linux.

### Adicionado (Runtime)
- Estrutura de distribuição para Linux x64, armhf, arm64.
- Gerador de `runtime.ini`, verificador de runtime e notas de distribuição.
- Perfis de requisitos: vision, ml, python, arm64.

---

## [1.3.0] - 2026-04-xx

### Adicionado
- **TAIOpenCV**: Componente de integração com OpenCV via Python runtime com detecção segura de biblioteca.
- **TAISafeProcessRunner**: Executor seguro de processos externos.
- **TAICrossLibLoader**: Carregador de biblioteca multiplataforma.
- **TAIRuntimePathResolver**: Resolvedor de caminhos de runtime.
- **TAIPlatformHelper**: Auxiliares de detecção de plataforma.
- Unidades de runtime de plataforma registradas no pacote core.

---

## [1.2.0] - 2026-04-xx

### Adicionado
- **Documentação completa de componentes** em `DOC/`: guias individuais para `TAICameraCapture`, `TAIFrameProcessor`, `TAIFaceTracker`, `TAIMotionTracker`, `TAIAgent`, `TAIAgentSafety`, `TAIAgentExecutor`, `TPythonConnector`, `TAIOutputData`, `TAIOutputDocs` (PDF, Word, Excel, TXT), `TAIModel3D`, `TAI3DModelViewer`, `TAIAvatar3D`, `TAIScene3D`, `TYoloDetect`, `TFaceDetection`, `TCNNClassifier`, `TLSTMPredictor`, `TAIGraphMap`, `TAITrainingExporter`, `TAIDatasetAnalyzer`, `TAITrainingReport`, `TAIGraphVisualizer`, `TAIImageInfo`, `TAIFrameBuffer`, `TAIFrameDiff`, `TAINativeImageFilter`, `TAIMotionTracker` (nativo).
- **Ícones gerados** para todos os componentes existentes via `generate_all_icons.py` usando recursos BMP 24×24 px embutidos em arquivos `.lrs`.

---

## [1.1.0] - 2026-03-xx

### Adicionado
- **`TAICameraCapture`**: Implementação inicial com demo GUI e testes unitários.
- Componentes de ML: `TNeuralNetwork`, `TPerceptron`, `TSOMMap`, `TAIDatasetGenerator`.
- Componentes de IA: `TCHATGPT`, `TAICodeAssistant`, `TTokenList`, `TAIWizardConfig`, `TAIModelRegistry`.
- Documentação inicial no `DOC/` para componentes de base.

---

## [1.0.0] - 2026-02-xx

### Adicionado
- Estrutura inicial do projeto com `funcoes.pas` e componentes base.
- Suporte a `funcoes.pas` com diretivas para Raspberry Pi.
- Matriz de compatibilidade de plataformas.
- Manifesto, histórico e documento legado do projeto.
