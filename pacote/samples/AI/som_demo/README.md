# Kohonen Self-Organizing Maps RGB Demo (som_demo)

Este exemplo demonstra o uso do componente **`TSOMMap`**, uma Rede de Auto-Organização de Kohonen (Self-Organizing Map) escrita em **Pascal puro**, para mapear e agrupar vetores tridimensionais de cores RGB em uma grade bidimensional interativa de neurônios.

---

## 🚀 Funcionalidades

1. **Grade de Neurônios 20x20**: Grade visual que representa os pesos sinápticos tridimensionais (R, G, B) de cada neurônio como cores de pixels na tela.
2. **Treinamento Interativo por Épocas**: Execute o loop de treinamento Kohonen com decaimento exponencial do raio de vizinhança e taxa de aprendizado.
3. **Mapeamento Topológico Visual**: A grade começa com cores aleatórias estáticas e, após o treinamento, se organiza em transições e degradês de cores suaves (agrupando cores semelhantes próximas na grade).

---

## 🛠️ Como Funciona

1. **BMU (Best Matching Unit)**: Para cada cor de entrada, a rede varre a grade calculando a distância euclidiana tridimensional para achar o neurônio vencedor.
2. **Decaimento Gaussiano**: Os pesos do neurônio BMU e de sua vizinhança topológica na grade bidimensional são atualizados, aproximando-os da cor de entrada.
3. **Decaimento de Parâmetros**: O raio de aprendizado e a vizinhança encolhem a cada época de forma exponencial.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`som_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Clique em **Inicializar Grade** para gerar pesos de cores aleatórios.
4. Clique em **Treinar Grade (SOM)** e veja a grade se auto-organizar em degradês.
