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

## 📦 Componentes Incluídos no Pacote

A suíte instala na paleta de componentes do Lazarus (aba **IA**) as seguintes ferramentas:

### 1. `TCHATGPT` (Conector de APIs de IA)
O núcleo de processamento de LLMs. Permite enviar perguntas e receber respostas estruturadas de provedores globais ou locais.
- **Provedores Suportados**: OpenAI, Gemini, Claude, OpenRouter, Cerebras e Ollama/Local.
- **Recursos**: Controle de Max Tokens, System/Developer Prompts, temperatura e modelos customizados.

### 2. `TNeuralNetwork` (Rede Neural Multicamadas)
Um Perceptron Multicamadas (MLP) escrito em **Pascal puro**, permitindo criar e treinar modelos de rede neural localmente sem dependências externas.
- **Funções de Ativação Embutidas**: Sigmoid (`atSigmoid`), ReLU (`atReLU`), Tanh (`atTanh`) e Customizada (`atCustom` via eventos).
- **Treinamento por Épocas**: Método `TrainEpochs` que treina o modelo a partir de uma matriz de dataset e calcula a perda por erro médio quadrado (MSE Loss).
- **Persistência**: Salvamento e carregamento rápido de pesos e biases (`SaveNetwork` / `LoadNetwork`).

### 3. `TAICodeAssistant` (Assistente de Código)
Um assistente virtual voltado para desenvolvedores. Ele consome o componente `TCHATGPT` configurado para automatizar tarefas comuns de programação:
- **`OptimizeCode(ACode)`**: Otimiza desempenho e legibilidade de rotinas.
- **`FindBugs(ACode)`**: Busca erros de lógica, vazamentos e sugere correções.
- **`DocumentCode(ACode)`**: Adiciona comentários XML/Javadoc estruturados.
- **`GenerateUnitTests(ACode)`**: Escreve testes unitários usando frameworks como `FPCUnit`.
- **`TranslateCode(ACode, De, Para)`**: Traduz códigos entre linguagens (ex: C# para Pascal).
- **`ExplainCode(ACode)`**: Explica passo a passo o funcionamento do algoritmo.

### 4. `TAIDatasetGenerator` (Gerador de Datasets de Treino)
Um facilitador para preparação de dados. Ajuda a gerar os arquivos necessários para Fine-Tuning de LLMs ou arquivos de entrada para a rede neural local:
- **Fine-Tuning**: Exporta conversas no formato padrão **JSONL** (JSON Lines) aceito por OpenAI e Ollama.
- **Integração de Rede Neural**: Exporta dados em **CSV** e carrega arquivos CSV delimitados diretamente para matrizes de entrada e saída (`TMatrix`) compatíveis com o método `TrainEpochs` do `TNeuralNetwork`.

### 5. `TTokenList` (Tokenizador utilitário)
Utilitário para análise e contagem de strings em lista estruturada de tokens.

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
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Sim | Possui cotas gratuitas generosas (ex: `gemini-2.5-flash`) |
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

## Licença

Este projeto está licenciado sob a [GNU General Public License v3.0](LICENSE).
