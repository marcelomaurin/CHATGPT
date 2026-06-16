# Python Connector Demo (python_demo)

Este exemplo demonstra como utilizar o componente **`TPythonConnector`** para carregar interpretadores Python dinamicamente e executar códigos, avaliar expressões matemáticas e interagir com variáveis globais diretamente de aplicações Lazarus/Delphi de forma multiplataforma.

---

## 🚀 Funcionalidades

1. **Seleção Inteligente de DLL**: ListBox dinâmica com auto-detecção da arquitetura de compilação do executável (`32-bit` ou `64-bit`) e preenchimento de caminhos padrões (Windows e Linux).
2. **Execução de Código**: Memo interativo para escrever e executar scripts inteiros no Python.
3. **Gerenciamento de Variáveis**: Interface gráfica para criar (`SetVar`) e ler (`GetVar`) variáveis globais do contexto Python.
4. **Avaliação Dinâmica (`Eval`)**: Caixa de entrada para avaliar equações e comandos rápidos, imprimindo o resultado em tempo real.
5. **Console de Logs**: Memo com registros detalhados das transições de estados e transações do interpretador.

---

## 🛠️ Como Funciona

O conector faz a ligação tardia (Dynamic Binding) através da unidade `DynLibs` de forma nativa:
* **No Windows**: Carrega bibliotecas dinâmicas como `python3.dll` ou `python312.dll`.
* **No Linux**: Carrega bibliotecas compartilhadas como `libpython3.so` ou `libpython3.12.so`.

Ao ativar o conector (`TPythonConnector.Active := True`), todos os ponteiros da API C do interpretador Python são mapeados para funções Pascal, habilitando a execução isolada na memória do seu programa.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`python_demo.lpi`** no Lazarus IDE.
2. No menu superior, clique em **Run > Build** (ou pressione `Ctrl + F9`).
3. O executável `python_demo.exe` (ou `python_demo` no Linux) será gerado na pasta.
4. **Nota**: Certifique-se de que a DLL/Shared Library do Python correspondente à sua arquitetura está instalada no sistema operacional ou na mesma pasta do executável.
