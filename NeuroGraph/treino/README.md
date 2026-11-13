# Treinador do NeuroGraph via YouTube, PDF & IA ChatGPT

Módulo do ecossistema NeuroGraph para **coleta contínua e curadoria de conhecimento pedagógico em português (PT-BR)** através de:
1. **Vídeos educativos do YouTube** (legendas e transcrições automáticas/oficiais).
2. **Documentos e livros em PDF** (leitura local, segmentação semântica e curadoria).
3. **Curadoria com IA (ChatGPT / Heurística)**: extração de fatos conceituais e geração de pares de perguntas e respostas.
4. **Treinamento contínuo autoregressivo** do modelo `TokenGraph` do NeuroGraph com exportação para pesos binários `NGCTX007` (`.ngs`).

---

## 🎯 Arquitetura do Pipeline

```
  [ YouTube / PDF ]             [ ChatGPT / Heurística ]               [ NeuroGraph ]
  Busca de vídeos ou leitura --> Curadoria e extração       -->   Treinamento autoregressivo
  de documentos PDF em PT        Pares atômicos {P, R}           Pesos binários NGCTX007 (.ngs)
```

1. **`leitor_pdf.py`**:
   - Extrai texto integral de arquivos PDF usando `pypdf` ou `PyPDF2`.
   - Limpa quebras de linhas artificiais e remove ruídos estruturais.
   - Segmenta documentos longos em blocos semânticos para processamento com a IA.

2. **`capturador_youtube.py`**:
   - Localiza vídeos educativos em português por termos conceituais ("o que é...", "como funciona...").
   - Baixa e limpa legendas em português (`pt`, `pt-BR`) usando a biblioteca `youtube-transcript-api`.
   - Remove ruídos de áudio (marcadores de música, aplausos, carimbos de tempo).

3. **`curador_chatgpt.py`**:
   - Utiliza a IA do ChatGPT (OpenAI API / `gpt-4o-mini`) para:
     - Sugerir termos de busca didáticos para o YouTube.
     - Analisar textos (transcrições ou PDFs) e formular perguntas diretas e respostas concisas ($\le 60$ tokens).
   - Possui modo heurístico local que funciona offline mesmo se `OPENAI_API_KEY` não estiver definida.

4. **`treinador_neurograph.py`**:
   - Integra diretamente com o núcleo Python do NeuroGraph (`experiments/contextual_v7/model.py`).
   - Mescla a base existente do benchmark (`benchmark.json`) com os novos dados curados para evitar esquecimento catastrófico.
   - Ajusta os pesos das conexões via entropia cruzada (`TokenGraph.fit()`) e salva o novo binário `.ngs`.

5. **`app_treino.py`**:
   - Aplicativo com **menu interativo** e **interface de linha de comando** (CLI).

---

## 🚀 Instalação e Requisitos

O pipeline requer Python 3.10 ou superior e os seguintes pacotes já instalados:

```bash
pip install pypdf youtube-transcript-api openai numpy scipy
```

> **Nota sobre a chave da OpenAI:**
> Para usar o ChatGPT na curadoria, defina a variável de ambiente:
> ```powershell
> $env:OPENAI_API_KEY="sua_chave_aqui"
> ```
> Se a chave não for fornecida, o aplicativo funcionará no modo heurístico local.

---

## 💻 Como Usar

### 1. Interface Gráfica Desktop em Lazarus (Nativa)

O projeto conta com um aplicativo nativo desktop desenvolvido em **Lazarus / Free Pascal (LCL)** localizado em:
`NeuroGraph\treino\lazarus\`

#### Como Iniciar:
- **Duplo clique no inicializador:** [iniciar_treinador.bat](file:///D:/projetos/maurinsoft/CHATGPT/NeuroGraph/iniciar_treinador.bat)
- **Ou executando o binário compilado:**
  [neurograph_studio.exe](file:///D:/projetos/maurinsoft/CHATGPT/NeuroGraph/treino/lazarus/neurograph_studio.exe)
- **Para recompilar no Lazarus:**
  Abra o arquivo de projeto `neurograph_studio.lpi` no Lazarus IDE ou execute [compilar.bat](file:///D:/projetos/maurinsoft/CHATGPT/NeuroGraph/treino/lazarus/compilar.bat) com `lazbuild`.

#### Recursos da Interface Lazarus:
1. **Aba 🤖 Provedores & Modelos (TCHATGPT)**:
   - **Seleção de Provedores:** Suporta todos os 15 provedores oficiais (`OpenAI`, `OpenRouter`, `Cerebras`, `Local / Ollama`, `Google Gemini`, `Anthropic Claude`, `DeepSeek`, `OpenAI-compatible`, `llama.cpp`, `neural-api`, `RunPod`, `Groq`, `Mistral`, `xAI`, `Qwen`).
   - **Catálogo Dinâmico de Modelos:** Ao selecionar um provedor, lista automaticamente todos os modelos associados (ex: GPT-4o, GPT-4o-mini, o1, Gemini 2.0 Flash, Claude 3.7 Sonnet, DeepSeek R1, Llama 3.3 70B, etc.).
   - **URL / Endpoint:** Atualiza automaticamente com a URL padrão do provedor e modelo selecionado (editável para servidores locais ou customizados).
   - **Botão 🧪 Testar Conexão:** Envia um ping/pergunta de teste em tempo real com cronometragem em milissegundos e diagnóstico de erro.
   - **Interação Completa:** Envio de prompts, streaming de resposta e botão para enviar o par gerado direto ao dataset do NeuroGraph.
2. **Aba 🎥 Treinar via YouTube**:
   - Campo para tema ou conceito didático em português com controle de quantidade de vídeos.
   - Campo para colar URL direta de vídeo individual do YouTube.
3. **Aba 📄 Treinar via PDF**:
   - Diálogo nativo de seleção de arquivos (`TOpenDialog`) para escolher qualquer apostila ou livro `.pdf`.
   - Controle de quantidade de pares conceituais a extrair do documento.
4. **Aba 💬 Conversar com o NeuroGraph**:
   - Campo para enviar perguntas com resposta imediata e histórico visual das respostas geradas pelo modelo.
5. **Aba 📊 Dataset Consolidado**:
   - Visualização em tempo real de todos os fatos aprendidos (`dataset_curado.json`), estatísticas e botão para retreinar o modelo completo.
6. **Console de Log Inferior**:
   - `TMemo` de log em tempo real com `TProgressBar` alimentado via `TProcess`, permitindo acompanhar o progresso das épocas sem congelar a tela.

---

### 2. Modo Console Interativo (Menu Amigável)

```powershell
python D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\app_treino.py
```

Opções disponíveis no menu:
1. Buscar tema educativo no YouTube, curar e treinar.
2. Processar URL ou ID específico de vídeo do YouTube.
3. **Processar documento PDF local (extrair texto, gerar perguntas/respostas com IA e treinar).**
4. Retreinar o NeuroGraph com todo o dataset acumulado.
5. Fazer uma pergunta ao NeuroGraph treinado.
6. Ver estatísticas do dataset atual.

---

### 2. Linha de Comando (CLI Direta)

#### Treinar a partir de um arquivo PDF:
```powershell
python app_treino.py --pdf "C:\caminho\para\seu_documento.pdf" --max-pares 15
```

#### Buscar um tema no YouTube e treinar automaticamente:
```powershell
python app_treino.py --tema "energia solar" --max-videos 2
```

#### Processar um vídeo específico:
```powershell
python app_treino.py --video "https://www.youtube.com/watch?v=5Q0B273l5MQ"
```

#### Fazer perguntas ao modelo treinado:
```powershell
python app_treino.py --perguntar "o que é buraco negro"
```

---

## 📂 Estrutura de Arquivos Criada

- `dados/raw/`: Arquivos JSON com textos brutos de transcrições e PDFs lidos.
- `dados/processados/dataset_curado.json`: Coleção cumulativa de fatos conceituais `{question, answer}` prontos para o NeuroGraph.
- `modelos/neurograph_youtube.ngs`: Pesos binários do NeuroGraph gerados após o treinamento.
- `config.json`: Configurações de hiperparâmetros e limites.
