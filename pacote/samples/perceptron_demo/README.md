# Perceptron Logic Gates Playground (perceptron_demo)

Este exemplo demonstra o uso do componente **`TPerceptron`**, uma rede neural artificial clássica de camada única escrita em **Pascal puro**, para aprender portas lógicas linearmente separáveis (como AND, OR, NAND, NOR) de forma totalmente offline.

---

## 🚀 Funcionalidades

1. **Escolha da Porta Lógica**: Caixa de combinação selecionando qual operação lógica treinar.
2. **Exibição de Parâmetros**: Visualização em tempo real do Bias e dos pesos sinápticos (`Weight 1` e `Weight 2`).
3. **Treinamento Interativo**: Execute treinamento por épocas, com parada precoce caso os pesos convirjam para erro zero.
4. **Predição Manual**: Teste a ativação binária do neurônio para qualquer entrada [0 ou 1].

---

## 🛠️ Como Funciona

O perceptron clássico resolve problemas linearmente separáveis:
* Soma as entradas ponderadas pelos pesos, soma o bias e passa o resultado pela função degrau rápido (*hard-step*): retorna `0` se a soma for menor que zero, e `1` caso contrário.
* Ajusta pesos e bias usando a Regra Delta com base na taxa de aprendizado e no erro de ativação:
  $$W_i = W_i + \text{LearningRate} \times \text{Error} \times X_i$$

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`perceptron_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Selecione a porta lógica (ex: `AND`), clique em **Treinar** e veja os pesos se ajustando.
4. Teste as combinações no painel de predição interativa.
