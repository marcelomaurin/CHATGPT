# Neural Network XOR Playground (neural_network_demo)

Este exemplo demonstra o uso do componente **`TNeuralNetwork`**, uma rede neural artificial multicamadas (MLP - Multilayer Perceptron) escrita em **Pascal puro**, para aprender a lógica XOR (Ou Exclusivo) de forma totalmente local e offline.

---

## 🚀 Funcionalidades

1. **Taxa de Aprendizado (Learning Rate)**: Entrada editável para configurar a taxa de ajuste dos pesos a cada iteração.
2. **Épocas Customizáveis**: Escolha o número de iterações do treinamento em lotes.
3. **Treinamento Interativo**: Execute o treinamento por épocas com exibição instantânea do erro médio quadrado (MSE Loss) decaindo.
4. **Inferência interativa**: Insira valores binários [0 ou 1] para entrada A e B e teste a predição da rede em tempo real.
5. **Persistência de Rede**: Botões para salvar (`SaveNetwork`) e carregar (`LoadNetwork`) pesos e biases da rede em arquivos texto estruturados.

---

## 🛠️ Como Funciona

A lógica XOR é não-linearmente separável, o que requer pelo menos uma camada oculta. 
* O componente configura uma topologia `2 -> 4 -> 1` (2 Entradas, 4 Neurônios Ocultos, 1 Saída).
* Utiliza propagação para frente (Forward Pass) para computar a predição.
* Utiliza retropropagação do erro (Backpropagation) para recalcular pesos e biases.
* Todas as funções matemáticas (Sigmoide, ReLU, etc.) são calculadas em código Pascal nativo sem dependências externas.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`neural_network_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Clique em **Treinar Rede** e observe o erro final MSE se aproximar de zero.
4. Digite entradas no painel de predição e clique em **Predizer/Testar**.
