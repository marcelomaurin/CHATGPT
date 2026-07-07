# Python Connector Demo (`python_demo`)

Documentação do sample **`python_demo`**, criado para demonstrar o uso do componente **`TPythonConnector`** em aplicações Lazarus/Free Pascal.

## 🌐 Traduções

| Idioma | Arquivo |
|---|---|
| Português | `README.md` |
| English | `README.en.md` |
| Español | `README.es.md` |
| العربية | `README.ar.md` |
| Italiano | `README.it.md` |
| 日本語 | `README.ja.md` |
| 中文 | `README.zh.md` |
| Русский | `README.ru.md` |
| हिन्दी | `README.hi.md` |

---

## 1. Objetivo

Este exemplo mostra como integrar um interpretador Python a uma aplicação Lazarus usando o componente **`TPythonConnector`**. O sample permite ativar o Python, executar scripts, capturar a saída, avaliar expressões e trocar variáveis entre Pascal e Python.

Ele é útil para validar se o runtime Python está corretamente instalado ou embarcado antes de usar componentes mais complexos de IA, visão computacional, áudio ou aprendizado de máquina dentro do projeto **CHATGPT**.

---

## 2. O que este sample demonstra

- Seleção de biblioteca ou executável Python compatível com a arquitetura do aplicativo.
- Ativação e desativação do interpretador Python.
- Dois modos de execução:
  - **`pemDLL`**: carrega `python3.dll`, `python312.dll`, `libpython3.so` ou equivalente.
  - **`pemProcess`**: executa Python como processo externo persistente.
- Execução de scripts com **`ExecString`**.
- Captura de saída padrão e erros em **`LastOutput`** e **`LastError`**.
- Leitura e escrita de variáveis globais com **`GetVar`** e **`SetVar`**.
- Avaliação dinâmica de expressões com **`Eval`**.
- Relatório de diagnóstico com arquitetura, versão, modo de execução, biblioteca carregada e etapa de falha.

---

## 3. Estrutura do sample

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Projeto Lazarus
├── python_demo.lpr      # Programa principal
├── main.pas             # Lógica do formulário e integração com TPythonConnector
├── main.lfm             # Interface visual do formulário
└── README.md            # Documentação em português
```

O projeto depende dos pacotes **`LCL`** e **`openai_core`**.

---

## 4. Requisitos

### Lazarus / Free Pascal

- Lazarus instalado.
- Pacote **`openai_core`** disponível no caminho do projeto.
- Projeto aberto pelo arquivo **`python_demo.lpi`**.

### Python

O componente foi configurado para aceitar Python **3.8 até 3.14**.

A arquitetura precisa ser compatível:

| Aplicativo compilado | Python necessário |
|---|---|
| Windows 64 bits | Python 64 bits |
| Windows 32 bits | Python 32 bits |
| Linux 64 bits | `libpython`/`python3` 64 bits |
| Linux ARM/ARM64 | `libpython`/`python3` da mesma arquitetura |

Para o modo **DLL/SO**, instale também a biblioteca de desenvolvimento do Python quando necessário.

Exemplo no Debian/Ubuntu:

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. Como compilar

1. Abra o Lazarus.
2. Abra o arquivo:

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. Compile com:

```text
Run > Build
```

ou pressione:

```text
Ctrl + F9
```

4. Execute o binário gerado:

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. Como usar

1. Escolha uma DLL, SO ou executável Python na lista.
2. Deixe **Usar Processo Externo** marcado para testar primeiro o modo mais seguro.
3. Clique em **Ativar interpretador Python**.
4. Confira o painel **Logs de Operações**.
5. Execute o script padrão ou escreva um script no memo.
6. Use **SetVar**, **GetVar** e **Eval** para testar troca de dados entre Pascal e Python.

---

## 7. Teste rápido recomendado

### Script

Cole no memo de script:

```python
x = 10
print("Hello from Python")
print("x =", x)
```

Clique em **Executar Script no Python**.

### Ler variável

No campo **Nome Variável**, informe:

```text
x
```

Clique em **GetVar**.

O valor esperado é:

```text
10
```

### Avaliar expressão

No campo de expressão, use:

```python
x + 50
```

O resultado esperado é:

```text
60
```

### Atenção sobre `SetVar`

Atualmente, **`SetVar` grava valores como string**. Então, se você usar:

```text
Nome: y
Valor: 10
```

use esta expressão no Eval:

```python
int(y) + 50
```

Em vez de:

```python
y + 50
```

---

## 8. Modos de execução

### `pemProcess` — Processo externo

É o modo recomendado para começar.

Vantagens:

- Isola melhor o Python do processo Lazarus.
- Evita travamentos causados por conflito de DLL/SO.
- Facilita uso futuro com bibliotecas pesadas como TensorFlow, OpenCV, Torch ou Keras.
- Usa `python.exe`, `python3.exe`, `python3` ou outro executável encontrado no sistema.

### `pemDLL` — Biblioteca dinâmica

Carrega o Python diretamente no processo da aplicação.

Vantagens:

- Integração mais direta com a API C do Python.
- Pode ser mais rápido para chamadas simples.

Cuidados:

- A arquitetura precisa bater exatamente.
- A biblioteca precisa exportar as funções obrigatórias da API C.
- Um erro na biblioteca Python pode derrubar o processo Lazarus.

---

## 9. Diagnóstico

Ao ativar o Python, o sample imprime um relatório no painel de logs contendo:

- sistema operacional detectado;
- arquitetura do Lazarus;
- modo de execução;
- caminho configurado;
- biblioteca ou executável carregado;
- versão do Python;
- compatibilidade de arquitetura;
- funções obrigatórias encontradas;
- última etapa de carregamento;
- último erro, quando existir.

Use esse relatório antes de concluir que o componente falhou. Na maioria dos casos, o erro está em arquitetura incompatível, biblioteca ausente ou Python fora do PATH.

---

## 10. Problemas comuns

| Sintoma | Causa provável | Correção |
|---|---|---|
| `Falha ao carregar python3.dll` | Python não instalado, DLL ausente ou arquitetura incorreta | Instale Python da mesma arquitetura do executável |
| `Falha ao carregar libpython` | Pacote de desenvolvimento ausente no Linux | Instale `python3-dev`/`libpython3-dev` |
| Python ativa, mas `GetVar` falha | Funções opcionais da API C indisponíveis no modo DLL | Teste com `pemProcess` |
| `y + 50` falha após `SetVar` | `SetVar` injeta string | Use `int(y) + 50` ou defina `y = 10` no script |
| Nada aparece na saída | Script não usa `print` ou execução falhou | Verifique `LastError` e o log |
| Funciona no terminal, mas não no Lazarus | PATH diferente no ambiente da IDE | Informe caminho absoluto do Python |

---

## 11. Boas práticas

- Teste primeiro com **`pemProcess`**.
- Use **`pemDLL`** apenas quando precisar de integração direta com a API C.
- Mantenha Python e Lazarus na mesma arquitetura.
- Para distribuição, prefira organizar o runtime Python dentro da pasta do aplicativo ou de uma subpasta `libs`.
- Sempre copie o relatório de diagnóstico ao reportar erro.
- Evite scripts longos diretamente no memo; crie testes curtos e incrementais.

---

## 12. Relação com o projeto CHATGPT

Este sample é uma base para validar a ponte Lazarus ↔ Python. Ele prepara o caminho para outros componentes do projeto que dependem de Python, como:

- classificação de imagens;
- modelos CNN;
- YOLO;
- OpenCV;
- detecção facial;
- processamento de áudio;
- integração com bibliotecas de machine learning.

Antes de investigar erro em componentes de IA mais complexos, rode este sample para confirmar que o Python está carregando corretamente.

---

## 13. Melhorias futuras sugeridas

- Adicionar botão para localizar manualmente `python.exe`, `python3`, DLL, SO ou dylib.
- Mostrar claramente se o item selecionado é executável ou biblioteca.
- Separar a interface em abas: Configuração, Script, Variáveis, Eval e Diagnóstico.
- Adicionar botão **Copiar diagnóstico**.
- Salvar a última configuração usada.
- Validar previamente se o arquivo selecionado existe.
- Exibir aviso quando `SetVar` for usado com valor numérico, explicando que ele será tratado como string.

---

## 14. Resumo

O **`python_demo`** é o primeiro teste recomendado para qualquer integração Python dentro do pacote CHATGPT. Se este sample ativa o interpretador, executa script, lê variáveis e avalia expressões, a base de integração Python está funcionando.