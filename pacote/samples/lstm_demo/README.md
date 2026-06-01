# LSTM Trend Prediction Demo (lstm_demo)

Este exemplo demonstra o uso do componente recorrente **`TLSTMPredictor`** integrado ao conector Python para prever tendências futuras em séries temporais (Rolling Forecast) usando redes neurais recorrentes do tipo **LSTM (Long Short-Term Memory)**.

---

## 🚀 Funcionalidades

1. **Geração Dinâmica de Dados**: Botão para gerar e plotar na tela uma série senoidal com ruído aleatório.
2. **Treinamento Local da Rede**: Configuração de janela temporal deslizante e número de épocas para treinar a rede LSTM localmente via TensorFlow.
3. **Previsão de Próximos Passos**: Execução de previsão (*Rolling Forecast*) para estimar continuamente os próximos 10 passos da série temporal.
4. **Gráfico Comparativo**: Gráfico dinâmico desenhado no Canvas (`imgChart`) onde a linha verde representa a série real e a linha vermelha plota as tendências futuras preditas pela rede neural LSTM.

---

## 🛠️ Como Funciona

1. **Janela Deslizante**: O array de dados reais é fragmentado em sequências de treinamento de tamanho fixo.
2. **Modelagem Recorrente**: `TLSTMPredictor` treina um modelo de rede LSTM no TensorFlow, salvando o estado para inferência rápida.
3. **Rolling Forecast**: A previsão de cada novo passo alimenta a janela subsequente de forma contínua e iterativa.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`lstm_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Ative o interpretador Python na DLL selecionada e garanta que `numpy` e `tensorflow` estão instalados.
4. Clique em **Treinar Rede LSTM** e, em seguida, em **Prever Próximos Passos**.
