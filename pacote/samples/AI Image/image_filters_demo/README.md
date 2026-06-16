# LCL Image Filters Demo (image_filters_demo)

Este exemplo demonstra o uso dos filtros de processamento de imagens matriciais inclusos na aba **`AI Image`** da paleta de componentes do Lazarus, implementados em **Pascal puro** de alta performance.

---

## 🚀 Filtros Demonstrados

1. **Grayscale**: Conversão por luminância fotométrica padrão para escala de cinza.
2. **Negative**: Inversão total de cores.
3. **Brightness & Contrast**: Ajuste linear em tempo real por trackbars de brilho e contraste.
4. **Binarization**: Divisão por limiar em preto e branco absoluto.
5. **Blur**: Suavização baseada em Box Blur 3x3 de alto desempenho.
6. **Sharpen**: Realçador de nitidez usando kernel laplaciano.
7. **Sobel**: Detecção profunda de bordas horizontais e verticais por magnitude de gradiente.
8. **Erosion & Dilation**: Operações morfológicas matemáticas com raio regulável.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`image_filters_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Carregue uma imagem, ajuste os parâmetros deslizantes e aplique os filtros instantaneamente!
