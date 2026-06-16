# CNN Image Classification Demo (cnn_demo)

Este exemplo demonstra o uso do componente **`TCNNClassifier`** integrado ao conector Python para realizar classificação de imagens profunda em tempo real com o modelo **MobileNetV2** (pré-treinado no ImageNet).

---

## 🚀 Funcionalidades

1. **Seleção Inteligente de DLL**: ListBox com auto-detecção da arquitetura do executável (`32-bit` ou `64-bit`) e preenchimento de caminhos padrões.
2. **Carregamento de Fotos**: Escolha de qualquer foto local JPG/PNG com suporte seguro a PNG via `ImagesForLazarus` e `lazpng`.
3. **Instalação das Bibliotecas**: Botão para baixar e instalar silenciosamente via pip interno as dependências do interpretador (`tensorflow` e `pillow`).
4. **Classificação Profunda**: Inferência rápida que identifica o objeto da imagem de forma convolucional e retorna a etiqueta da classe e a porcentagem de confiança.

---

## 🛠️ Como Funciona

1. **Python Connector**: Carrega a DLL selecionada do interpretador Python.
2. **TensorFlow & Keras**: `TCNNClassifier` instancia o modelo MobileNetV2, pré-carrega os pesos padrão e faz o pré-processamento da imagem.
3. **Predição**: Retorna os resultados em Pascal de forma estruturada.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`cnn_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Selecione a DLL do Python e clique em **Ativar Python**.
4. Instale as dependências se for a primeira execução.
5. Selecione uma imagem local e clique em **Classificar Imagem (Executar CNN)**.
