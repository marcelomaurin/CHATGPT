# Pacote de Componentes de IA — openai.lpk

Este diretório contém a implementação do pacote oficial de componentes de IA para Lazarus/Delphi (**openai.lpk**). Este pacote adiciona 5 ferramentas de Inteligência Artificial e Aprendizado de Máquina (Machine Learning) na aba **IA** da paleta de componentes do Lazarus.

---

## 📦 Componentes do Pacote

### 1. `TCHATGPT` (chatgpt.pas)
O componente central de conectividade com LLMs (Modelos de Linguagem). Ele abstrai as requisições HTTP e o tratamento de JSON para os principais provedores de nuvem e servidores locais.
- **Propriedades Principais**:
  - `TOKEN: WideString`: Chave de acesso (API Key) do provedor selecionado.
  - `Provider: TAIProvider`: Enum para definir a IA (`AIP_OPENAI`, `AIP_OPENROUTER`, `AIP_CEREBRAS`, `AIP_LOCAL`, `AIP_GEMINI`, `AIP_CLAUDE`).
  - `TipoChat: TVersionChat`: Enum para selecionar o modelo padrão (ex: `VCT_GPT4o`, `VCT_GEMINI_25_FLASH`, `VCT_CLAUDE_35_SONNET`, `VCT_DEEPSEEK_R1_8B`).
  - `CustomModel: WideString`: Nome de modelo personalizado (sobrescreve a seleção padrão de `TipoChat`).
  - `LocalIP: WideString`: URL base do servidor Ollama local (padrão: `http://localhost:11434`).
  - `MaxTokens: Integer`: Limite máximo de tokens de retorno na resposta (padrão: 4096).
  - `Dev: WideString`: Instruções do prompt do sistema (System/Developer prompt).
  - `Response: WideString` (Apenas leitura): Contém a resposta da última pergunta.
  - `LastJSON: WideString` (Apenas leitura): Retorna o JSON completo bruto da resposta HTTP.
- **Métodos Principais**:
  - `function SendQuestion(ASK: WideString): Boolean`: Envia a pergunta e retorna `True` em caso de sucesso.
  - `function ProviderName: WideString`: Retorna o nome amigável do provedor selecionado.
  - `function TipoModelo: WideString`: Retorna a string do modelo final enviada à API.

---

### 2. `TNeuralNetwork` (neuralnetwork.pas)
Rede Neural Multicamadas (Perceptron Multicamadas) escrita em **Pascal puro**, desenvolvida para criar, treinar e executar modelos preditivos locais sem dependências externas.
- **Propriedades Principais**:
  - `LearningRate: Double`: Taxa de aprendizado que dita o tamanho dos ajustes de pesos (padrão: 0.1).
  - `ActivationType: TActivationType`: Enum com funções de ativação embutidas (`atSigmoid`, `atReLU`, `atTanh`, `atCustom`).
- **Métodos Principais**:
  - `procedure Initialize(LInputs, LHiddens, LOutputs: Integer; LLearningRate: Double)`: Configura a topografia da rede neural (número de neurônios nas camadas de entrada, oculta e saída) e preenche os pesos iniciais com He-initialization.
  - `function Predict(const LInputs: TArray): TArray`: Realiza a propagação para frente (Forward Pass) e retorna as predições.
  - `procedure Train(const LInputs, LTargets: TArray)`: Executa o ajuste de pesos pelo algoritmo de Backpropagation para uma única linha de dados.
  - `procedure TrainEpochs(const LDatasetInputs, LDatasetTargets: TMatrix; LEpochs: Integer; out LFinalLoss: Double)`: Treina a rede neural em lotes por um número configurado de épocas e calcula a taxa final de erro médio quadrado (MSE Loss).
  - `procedure SaveNetwork(const LFileName: String)`: Salva os pesos e biases da rede em arquivo de texto.
  - `procedure LoadNetwork(const LFileName: String)`: Carrega os pesos e biases de uma rede pré-treinada.

---

### 3. `TAICodeAssistant` (aicodeassistant.pas)
Assistente virtual de codificação integrado para apoiar desenvolvedores na otimização e manutenção de projetos:
- **Propriedades Principais**:
  - `ChatGPT: TCHATGPT`: Referência ao componente de comunicação configurado com as chaves e modelos ativos.
- **Métodos Principais**:
  - `function OptimizeCode(const ACode: string): string`: Solicita otimização estrutural e de legibilidade.
  - `function FindBugs(const ACode: string): string`: Analisa o código fonte em busca de erros comuns e sugere correções.
  - `function DocumentCode(const ACode: string): string`: Adiciona automaticamente documentação XML ou Javadoc estruturada.
  - `function GenerateUnitTests(const ACode: string; const ATestFramework: string = 'FPCUnit'): string`: Gera classes de testes unitários para a rotina informada.
  - `function TranslateCode(const ACode, ASourceLang, ATargetLang: string): string`: Traduz o código de uma linguagem para outra.
  - `function ExplainCode(const ACode: string): string`: Descreve passo a passo o funcionamento do algoritmo.

---

### 4. `TAIDatasetGenerator` (aidatasetgenerator.pas)
Gerenciador e exportador de dados focado em simplificar o fluxo de modelagem de conjuntos de dados em Machine Learning e Fine-Tuning:
- **Métodos Principais**:
  - `procedure AddDataRow(const AInput, AOutput: string)`: Adiciona uma linha contendo dados de entrada e saída.
  - `procedure Clear`: Limpa as linhas armazenadas em memória.
  - `procedure SaveAsJSONL(const AFileName: string)`: Compila e salva a lista no formato de conversa padrão **JSONL** (JSON Lines) para Fine-Tuning de LLMs.
  - `procedure SaveAsCSV(const AFileName: string; const ADelimiter: Char = ';')`: Exporta os dados para formato estruturado CSV.
  - `procedure LoadFromCSV(const AFileName: string; out LInputs, LTargets: TMatrix; LInputCols, LTargetCols: Integer; const ADelimiter: Char = ';')`: Lê dados tabulares em CSV e os divide em matrizes de treino compatíveis com o método `TrainEpochs` da Rede Neural.

---

### 5. `TTokenList` (tokenizer.pas)
Um utilitário de conveniência para contagem, análise e segmentação (tokenização) de palavras em listas estruturadas.

---

### 6. `TPythonConnector` (pythonconnector.pas)
Um conector dinâmico e multiplataforma para integrar scripts e código Python nativamente em aplicações Lazarus/Delphi:
- **Propriedades Principais**:
  - `DLLPath: string`: Caminho para a biblioteca dinâmica do Python (ex: `python3.dll`, `python312.dll`, `libpython3.so`).
  - `Active: Boolean`: Ativa ou desativa o interpretador de forma dinâmica carregando os ponteiros da biblioteca em memória.
  - `Version: string` (Apenas leitura): Retorna a versão oficial do interpretador carregado via API C.
  - `LastError: string` (Apenas leitura): Detalha mensagens de erro no carregamento da DLL ou falhas de execução de scripts.
- **Métodos Principais**:
  - `function ExecString(const AScript: string): Boolean`: Executa instruções ou scripts arbitrários no Python.
  - `function GetVar(const AVarName: string): string`: Lê qualquer variável do namespace global e retorna sua representação em string.
  - `procedure SetVar(const AVarName, AValue: string)`: Cria ou atualiza uma variável do tipo string no contexto global do Python.
  - `function Eval(const AExpression: string): string`: Avalia expressões matemáticas/lógicas no interpretador e retorna o resultado.

---

## 📂 Diretório de Exemplos (Samples)

A pasta **[samples/](samples/)** contém demonstrações completas para cada recurso da suíte:

### 🖥️ Demonstrações Visuais (GUI Completa)
*   **[visual_demo/](samples/visual_demo/)**: Showcase unificado com abas para TCHATGPT, TNeuralNetwork, TAICodeAssistant e TAIDatasetGenerator.
*   **[python_demo/](samples/python_demo/)**: Playground dinâmico completo para TPythonConnector (permite escrever scripts, manipular variáveis e rodar Eval interativo). *Já inclui as DLLs `python3.dll` e `python312.dll` copiadas para testes imediatos!*
*   **[neural_network_demo/](samples/neural_network_demo/)**: Demonstração dedicada para treinamento interativo XOR, predições, ajuste de LR/épocas e persistência de pesos.
*   **[tokenizer_demo/](samples/tokenizer_demo/)**: Playground completo para inserção e busca de tokens, processamento de frases inteiras e importação de JSON estruturado.

### 💻 Demonstrações em Console
*   `samples/chatgpt_sample.lpr`: Integração direta com OpenAI, Gemini e Claude.
*   `samples/neuralnetwork_sample.lpr`: Loop clássico de aprendizado XOR local.
*   `samples/aicodeassistant_sample.lpr`: Auditoria, otimização e geração de testes unitários.
*   `samples/aidatasetgenerator_sample.lpr`: Criação de conjuntos de treinamento local e Fine-Tuning.
