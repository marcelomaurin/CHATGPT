# OpenCV Face Detection Demo (face_detection_demo)

Este exemplo demonstra o uso do componente **`TFaceDetection`** integrado ao conector Python para realizar detecção facial em tempo real com **OpenCV** e desenhar retângulos delimitadores vermelhos ao redor de faces humanas.

---

## 🚀 Funcionalidades

1. **Seleção Inteligente de DLL**: ListBox com auto-detecção da arquitetura do executável (`32-bit` ou `64-bit`) e preenchimento de caminhos padrões.
2. **Carregamento de Fotos**: Escolha de qualquer foto local JPG/PNG com suporte seguro a PNG via `ImagesForLazarus` e `lazpng`.
3. **Instalação Silenciosa**: Botão para baixar e instalar silenciosamente via pip interno a biblioteca oficial `opencv-python`.
4. **Detecção Rápida**: Identifica as faces, extrai as coordenadas Pascal estruturadas e desenha os contornos de detecção na tela nativamente.

---

## 🛠️ Como Funciona

1. **OpenCV Bridge**: O conector Python é ativado dinamicamente.
2. **Haar Cascades / DNN**: `TFaceDetection` faz a chamada ao OpenCV para rodar a detecção em escala de cinzas.
3. **Retorno Pascal**: Coordenadas de detecção são convertidas na estrutura estruturada Pascal `TFaceRectArray` e desenhadas em tela via `imgView.Canvas`.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`face_detection_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Ative o interpretador Python na DLL selecionada.
4. Clique em **Detectar Faces** para rodar a inferência.
