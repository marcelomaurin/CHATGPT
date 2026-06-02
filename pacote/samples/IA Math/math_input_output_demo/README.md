# Demonstração Visual: IA Math, IA Input e IA Output

Este exemplo é uma demonstração visual unificada criada para ilustrar o uso dos três novos componentes da suíte de componentes de IA para Lazarus:

1. **`TNumPS`** (Aba: **`IA Math`**): Equivalente em Pascal puro para operações vetoriais, matriciais e estatísticas similares às do **NumPy**.
2. **`TAIInputData`** (Aba: **`IA Input`**): Utilitário para carga, gerenciamento e normalização/denormalização linear de vetores numéricos de entrada.
3. **`TAIOutputData`** (Aba: **`IA Output`**): Utilitário para cálculo da ativação de probabilidade **SoftMax** sobre scores (logits) de saída e resolução de decisão categórica por maior probabilidade.

---

## 🛠️ Como Compilar e Executar

### 1. Requisitos
* Lazarus IDE (versão 3.x recomendada).
* Pacote `openai.lpk` instalado ou compilado na IDE.

### 2. Compilação via Linha de Comando (lazbuild)
Você pode compilar o executável diretamente a partir deste diretório utilizando a ferramenta `lazbuild` do Lazarus:
```powershell
C:\lazarus\lazbuild.exe math_input_output_demo.lpi
```

---

## 💡 Guia de Uso da Interface

O aplicativo está estruturado em três abas funcionais:

### 1. Aba: `IA Math (TNumPS)`
* **O que faz**: Permite selecionar de forma interativa e executar múltiplas operações matemáticas e estatísticas do `TNumPS`.
* **Operações Disponíveis**:
  * `Zeros`: Geração de matrizes nulas.
  * `Ones`: Geração de matrizes preenchidas com 1.
  * `Arange` e `LinSpace`: Sequenciadores e espaçadores de intervalo.
  * `Identity (Eye)`: Matrizes identidades.
  * `Random Matrix`: Matrizes contendo flutuantes aleatórios entre 0 e 1.
  * `MatMul`: Multiplicação de matrizes com dimensões compatíveis.
  * `Statistics`: Cálculo de Soma, Média, Desvio Padrão, Máximo/Mínimo e seus respectivos índices (ArgMin/ArgMax).

### 2. Aba: `IA Input (TAIInputData)`
* **O que faz**: Carrega uma lista de números flutuantes e aplica normalização linear para faixas desejadas (ex: `0.0` a `1.0`).
* **Como testar**:
  1. Digite valores separados por vírgula no campo de dados.
  2. Ajuste os campos `MinRange` e `MaxRange` desejados.
  3. Clique em **Normalizar** para ver os dados normalizados formatados.
  4. Clique em **Desnormalizar** para reverter os dados normalizados de volta para a faixa original.

### 3. Aba: `IA Output (TAIOutputData)`
* **O que faz**: Mapeia logits brutos para probabilidades de probabilidade SoftMax e exibe o rótulo da classe com maior pontuação.
* **Como testar**:
  1. Insira os nomes das classes (um por linha) na caixa à esquerda.
  2. Insira os logits brutos (um por linha) correspondentes a cada classe na caixa central.
  3. Clique em **Aplicar SoftMax e Decidir**.
  4. A caixa da direita exibirá os logits e a distribuição de probabilidade normalizada SoftMax de cada classe, e o rótulo exibirá a classe predita mais provável com a respectiva porcentagem.
