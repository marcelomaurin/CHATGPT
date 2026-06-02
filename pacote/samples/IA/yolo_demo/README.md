# YOLOv8 Object Detection Demo (yolo_demo)

Este exemplo demonstra o uso do componente **`TYOLO`** integrado ao conector Python para realizar detecção de objetos profunda em tempo real com o modelo **YOLOv8** (You Only Look Once) e desenhar retângulos delimitadores diretamente em imagens na tela do Lazarus.

---

## 🚀 Funcionalidades

1. **Seleção Inteligente de DLL**: ListBox com auto-detecção da arquitetura do executável (`32-bit` ou `64-bit`) e preenchimento de caminhos padrões.
2. **Carregamento de Imagens**: Escolha de qualquer foto local JPG/PNG ou seleção instantânea de uma das 10 fotos pré-carregadas (`cat.png`, `dog.png`, `car.png`, `bicycle.png`, etc.).
3. **Decodificação de Formato Segura**: Utiliza `ImagesForLazarus` e `lazpng` para impedir erros de decodificação na LCL ao carregar arquivos PNG.
4. **Instalador Silencioso**: Botão para baixar e instalar silenciosamente via pip interno a biblioteca oficial `ultralytics` do Python.
5. **Plotagem de Resultados**: O componente recebe a imagem, executa a inferência, desenha os retângulos delimitadores (*bounding boxes*) de cada objeto detectado e escreve o nome da classe com a respectiva porcentagem de confiança.

---

## 🛠️ Como Funciona

1. **Python Bridge**: O conector Python é inicializado dinamicamente.
2. **Ultralytics YOLOv8**: `TYOLO` faz chamadas diretas ao interpretador injetando o script que faz o carregamento do modelo pré-treinado compacto `yolov8n.pt` (de apenas 6MB).
3. **Retorno Pascal**: Os resultados de caixas de detecção são extraídos do Python e convertidos na estrutura estruturada Pascal `TYoloObjectArray`.
4. **Desenho em Canvas**: O formulário itera no array e desenha os retângulos azuis sobre o `imgView.Canvas` da tela nativamente.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`yolo_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Selecione a DLL do Python e clique em **Ativar Python**.
4. Se necessário, clique em **Instalar YOLOv8 (Pip)** para configurar as dependências Python automaticamente.
5. Escolha uma imagem na caixa de combinação ou selecione no seu disco e clique em **Detectar Objetos**.
