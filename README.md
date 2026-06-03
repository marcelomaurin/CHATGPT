# TCHATGPT — Suíte de Componentes de IA para Lazarus

🌍 **Idiomas / Languages:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

Uma suíte completa de componentes visuais e não visuais para Free Pascal / Lazarus desenvolvida para integrar **IA generativa e aprendizado de máquina (Machine Learning)** nativamente em suas aplicações. Suporta **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras**, **modelos locais via Ollama** e redes neurais locais.

---

## 📦 Abas de Componentes Incluídos no Pacote

A suíte instala na paleta de componentes do Lazarus quatro abas repletas de ferramentas integradas:

---

### Aba: `IA` (IA Generativa e Aprendizado de Máquina)

*   **`TCHATGPT` (Conector de APIs de IA)**: O núcleo de processamento de LLMs. Permite enviar perguntas e receber respostas estruturadas de provedores globais (OpenAI, Gemini, Claude, OpenRouter, Cerebras) ou locais (Ollama).
*   **`TNeuralNetwork` (Rede Neural Multicamadas)**: Um Perceptron Multicamadas (MLP) escrito em **Pascal puro**, permitindo criar, treinar (`TrainEpochs` com cálculo de MSE Loss) e persistir redes neurais locais.
*   **`TAICodeAssistant` (Assistente de Código)**: Binda-se ao conector para otimizar códigos, achar bugs, documentar, gerar testes unitários e traduzir linguagens de forma automatizada.
*   **`TAIDatasetGenerator` (Gerador de Datasets)**: Prepara arquivos JSONL para fine-tuning de LLMs ou arquivos CSV para matrizes de treinamento local de redes neurais.
*   **`TTokenList` (Tokenizador utilitário)**: Analisador utilitário de strings em lista estruturada de tokens.

---

### Aba: `IA Filtros Sonoros` (Processamento Digital de Sinais - DSP)

*   **`TLowPassFilter`**: Filtro passa-baixa IIR de primeira ordem RC para suavização de transições abruptas.
*   **`THighPassFilter`**: Filtro passa-alta IIR de primeira ordem RC para remoção de baixas frequências (graves/ruído DC).
*   **`TAverageFilter`**: Filtro de média móvel baseado em janela deslizante para atenuação de flutuações rápidas.
*   **`TFDMMultiplexer`**: Multiplexador e Demodulador por Divisão de Frequência (FDM) usando modulação AM-DSB-SC e portadoras deslocadas.
*   **`TTDMMultiplexer`**: Multiplexador por Divisão de Tempo (TDM) dividindo frames em fatias temporais intercaladas.
*   **`TCDMMultiplexer`**: Multiplexador CDM (CDMA) que codifica canais usando códigos ortogonais Walsh-Hadamard.
*   **`TOFDMMultiplexer`**: Multiplexador OFDM ortogonal usando FFT e IFFT Radix-2 Cooley-Tukey e prefixo cíclico.

---

### Aba: `IA Image` (Processamento de Imagens e Visão Computacional)

*   **`TGrayscaleFilter`**: Conversão de imagem para escala de cinza por luminância fotométrica.
*   **`TNegativeFilter`**: Inversão total de canais de cor ($R_{new} = 65535 - R$).
*   **`TBrightnessContrastFilter`**: Ajustador linear de brilho e contraste em alta fidelidade.
*   **`TBinarizationFilter`**: Binarizador de limiar ajustável (preto e branco absoluto).
*   **`TBlurFilter`**: Suavizador de imagem baseado em convolução box blur $3\times3$ com tratamento de borda.
*   **`TSharpenFilter`**: Realçador de nitidez baseado em kernel Laplaciano $3\times3$.
*   **`TSobelFilter`**: Detector de bordas horizontais e verticais por magnitude de gradiente Sobel.
*   **`TErosionDilationFilter`**: Operações morfológicas matemáticas de Erosão ou Dilatação de raio regulável.

---

### Aba: `IA Schedulle` (Persistência JSON e Cronograma de Dependências)

*   **`TJSONGroupStorage`**: Componente de armazenamento chave-valor agrupado por nomes persistido automaticamente em arquivo texto JSON. Suporta strings e textos longos/grandes.
*   **`TIASchedule`**: Gerenciador de cronograma que suporta tarefas hierárquicas (Tarefa Pai / Tarefa Filha) e resolve dependências em tempo real, calculando se uma tarefa está pronta para execução (`IsReady`).

---

### Aba: `IA Voice` (Sintetização de Voz Nativa e Multiplataforma)

*   **`TAIVoiceSynthesizer`**: Componente de sintetização de voz (Text-to-Speech) de alta performance. Comunica-se diretamente com o subsistema nativo da plataforma: **SAPI (Speech API)** no Windows via COM Automation, e a biblioteca **eSpeak/eSpeak-NG** no Linux via ligação dinâmica de biblioteca.
    *   **Propriedades**: `Volume` (0..100), `Rate` (Velocidade, de -10 a 10), `Asynchronous` (fala sem travar a UI do aplicativo) e `VoiceName` (para trocar o idioma ou modelo de voz).
    *   **Métodos**: `Say(Texto)` para reproduzir o áudio falado e `GetAvailableVoices(Lista)` para obter dinamicamente todas as vozes instaladas no sistema operacional.

---

### Aba: `IA Agent` (Agentes Inteligentes Autônomos e Tomada de Decisões Estruturadas)

*   **`TAIAgent`**: O cérebro orquestrador do agente autônomo. Permite enviar de forma dinâmica e estruturada instruções complexas por meio de `TCHATGPT`, recebendo e tratando a resposta via parser JSON nativo de alta performance.
*   **`TAIAgentOptions`**: Armazena as diretrizes e regras de análise em formato de lista de perguntas/diretrizes (`Questions: TStrings`) e contexto geral de negócios (`Context`).
*   **`TAIAgentAction`**: Declara a lista de ações que o agente pode disparar no mundo externo (`AllowedActions: TStrings`) e a definição estruturada dos parâmetros exigidos para essas ações (`ParameterDefinitions: TStrings`), disparando callbacks nativos (`OnExecuteAction`) assim que a ação estruturada e seus parâmetros são decodificados pela inteligência artificial.
*   **`TAIAgentResource`**: Um banco gerenciador de recursos reais do sistema/rede (como E-mail, Escrita física de Arquivos, WhatsApp, SMS, pacotes TCP/UDP e Web API HTTP nativa com headers).
*   **`TAIAgentOutput`**: A ponte que escuta e intercepta as decisões de `TAIAgentAction` de forma automatizada por hooks internos, linca a ação para um recurso físico de `TAIAgentResource` via regras de mapeamento flexíveis e executa o canal físico correspondente gerando logs operacionais.

---

---

## Uso Rápido (Assistente de Código)

```pascal
uses chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  CodigoOtimizado: string;
begin
  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-SUA_CHAVE_AQUI';
    FChatgpt.Provider := AIP_CLAUDE;          // Configura Anthropic Claude
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
    
    FAssistant.ChatGPT := FChatgpt; // Associa o conector de IA
    
    CodigoOtimizado := FAssistant.OptimizeCode('procedure TForm1.Click; begin i := i + 1; end;');
    ShowMessage(CodigoOtimizado);
  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;
end;
```

---

## Treinamento Local (`TNeuralNetwork` & `TAIDatasetGenerator`)

```pascal
var
  FNet: TNeuralNetwork;
  FGen: TAIDatasetGenerator;
  Inputs, Targets: TMatrix;
  Loss: Double;
begin
  FNet := TNeuralNetwork.Create(nil);
  FGen := TAIDatasetGenerator.Create(nil);
  try
    // Carrega dados de treino diretamente de um arquivo CSV
    FGen.LoadFromCSV('dados.csv', Inputs, Targets, 2, 1); // 2 Entradas, 1 Saída

    // Inicializa a rede neural: 2 Entradas, 4 Ocultos, 1 Saída, Learning Rate = 0.05
    FNet.Initialize(2, 4, 1, 0.05);
    FNet.ActivationType := atSigmoid;

    // Executa o loop de treino sobre o dataset por 1000 épocas
    FNet.TrainEpochs(Inputs, Targets, 1000, Loss);
    ShowMessage(Format('Treino concluído! Perda MSE Final: %0.6f', [Loss]));

    FNet.SaveNetwork('modelo.net');
  finally
    FGen.Free;
    FNet.Free;
  end;
end;
```

---

## Provedores Suportados (LLMs)

| Provedor | Enum | Endpoint | Token Necessário | Detalhes de Versões Gratuitas |
|---|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Sim | Suporta `gpt-4o-mini` (baixo custo/free tier de API) |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Sim | Vários modelos gratuitos de uso ilimitado (ex: Llama 3, Gemma 2, DeepSeek R1) |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Sim | Acesso gratuito durante período beta |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Sim | **API REST Nativa v1beta** (`generateContent`). Possui cotas gratuitas generosas (ex: `gemini-1.5-flash`, `gemini-2.5-pro`) com autenticação via Query String (?key=) e suporte nativo a `systemInstruction`. |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Sim | Chave paga (teste/desenvolvimento) |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | Não | **Totalmente Gratuito** e offline (DeepSeek R1, Llama 3.2, etc.) |

---

## Instalação do Pacote no Lazarus

1. No Lazarus IDE, vá em **Package > Open Package File (.lpk)**
2. Navegue até a pasta `pacote/` e selecione **`openai.lpk`**
3. Clique em **Compile** para compilar o pacote
4. Clique em **Use > Install** — o Lazarus pedirá para reconstruir a IDE
5. Após reiniciar, os 5 componentes estarão disponíveis na aba **IA** da paleta de componentes.

---

## Requisitos de Bibliotecas (Windows)

Para que a comunicação HTTPS funcione no Windows, as DLLs OpenSSL adequadas para a arquitetura do seu aplicativo compilado (32-bit ou 64-bit) devem estar acessíveis. A suíte já inclui as DLLs na pasta `pacote/lib/`:

*   **Aplicativos 32-bit (i386-win32)**: `pacote/lib/i386-win32/`
    - `libcrypto-1_1.dll`, `libssl-1_1.dll`
*   **Aplicativos 64-bit (x86_64-win64)**: `pacote/lib/x86_64-win64/`
    - `libcrypto.dll`, `libssl-1_1-x64.dll`

**Recomendação:** Copie as DLLs da pasta `lib/` correspondente para a **mesma pasta onde está o seu executável compilado**.

---
## Screen Shots
![CNN Demo](screenshots/cnn_demo.jpg)
Detecção de objetos em Python

![math_input_output_demo](screenshots/math_input_output_demo.jpg)
Biblioteca matematica demo


---

## Licença

Este projeto está licenciado sob a [GNU General Public License v3.0](LICENSE).
