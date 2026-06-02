# String Tokenizer Utility Demo (tokenizer_demo)

Este exemplo demonstra o uso do componente **`TTokenList`**, um utilitário escrito em **Pascal puro** projetado para segmentação (tokenização), contagem e indexação estruturada de termos e palavras em strings de texto.

---

## 🚀 Funcionalidades

1. **Tokenização Rápida**: Insira qualquer frase ou parágrafo de texto e quebre-o instantaneamente em uma lista estruturada de tokens individuais.
2. **Análise de Frequência**: Conta automaticamente as repetições de cada palavra, ordenando-as por relevância/ocorrência.
3. **Persistência de Dados**: Habilidade de ler e exportar estruturas de tokens no formato padronizado JSON.
4. **Busca Indexada**: Ferramenta interativa de busca rápida para verificar a existência de termos no índice gerado.

---

## 🛠️ Como Funciona

* O componente `TTokenList` analisa o texto delimitando termos por espaços e pontuações comuns.
* Constrói e mantém uma lista ordenada em memória de estruturas `TToken` contendo a string textual e o contador de frequência, simplificando tarefas de mineração de texto e pré-processamento para NLP locales.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`tokenizer_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Digite ou cole o texto na caixa de entrada e clique em **Tokenizar Texto**.
