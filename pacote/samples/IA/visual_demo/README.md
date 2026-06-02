# Unified AI Components Playground (visual_demo)

Este é o showcase unificado e a central de testes em interface gráfica para as quatro ferramentas fundamentais da suíte de IA: **`TCHATGPT`**, **`TNeuralNetwork`**, **`TAICodeAssistant`** e **`TAIDatasetGenerator`**.

---

## 🚀 Funcionalidades

1. **Aba ChatGPT**: Envio de prompts rápidos e complexos para LLMs. Permite configurar tokens de acesso, provedores (OpenAI, Gemini, Claude, OpenRouter, Cerebras, Ollama local) e modelos de forma visual, exibindo a resposta formatada e os dados JSON brutos de retorno.
2. **Aba Code Assistant**: Playground interativo para o assistente de código. Forneça qualquer código-fonte Pascal/C/Python e clique nos botões para **Otimizar**, **Achar Bugs**, **Documentar** ou **Explicar Código**.
3. **Aba Dataset Generator**: Crie e gerencie coleções estruturadas de treinamento. Adicione pares de Entrada/Saída interativamente e exporte-os imediatamente para os formatos **JSONL** (para fine-tuning de LLMs) ou **CSV** (para redes neurais).
4. **Aba Neural Network**: Treine localmente uma rede neural MLP em Pascal puro na lógica XOR. Regule a taxa de aprendizado, número de épocas, treine e veja a perda média (MSE Loss) decair na tela interativamente!

---

## 🛠️ Como Funciona

Toda a suíte de componentes da paleta **IA** do Lazarus é instanciada e vinculada de forma síncrona:
* `TAICodeAssistant` consome as configurações HTTP do `TCHATGPT`.
* `TNeuralNetwork` e `TAIDatasetGenerator` trocam dados matriciais e vetoriais de forma nativa e local sem qualquer dependência externa ou DLLs adicionais de C.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`visual_demo.lpi`** no Lazarus IDE.
2. Certifique-se de ter compilado e instalado o pacote `openai.lpk` na paleta de componentes.
3. No menu principal, clique em **Run > Run** (ou pressione `F9`).
4. **Nota (HTTPS Windows)**: Copie as DLLs OpenSSL de `pacote/lib/` para a mesma pasta do executável para habilitar conexões de rede SSL/TLS.
