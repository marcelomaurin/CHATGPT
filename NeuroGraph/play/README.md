# NeuroGraph Player (`play`)

Esta pasta contém o ambiente para **tocar / executar a inferência de modelos do NeuroGraph**.
Ela permite carregar qualquer modelo compilado (`.ngs`) e submeter perguntas para que o modelo gere respostas utilizando o grafo associativo contextual.

---

## 📁 Estrutura de Arquivos

- **`play.py`**: Motor de inferência em Python.
  - Carrega pesos binários `.ngs` usando a arquitetura `TokenGraph`.
  - Oferece modo interativo REPL com comandos especiais (`sair`, `reset`, `modelos`).
  - Suporta modo direto com `--pergunta "sua pergunta"`.
  - Suporta formato JSON `--json` para integração com interfaces gráficas.
  - Mantém estado de sessão contextual (`Session`) entre perguntas.
- **`play.bat`**: Script de execução rápida no Windows em UTF-8.
- **`lazarus/`**: Interface desktop nativa compilada com Lazarus / Free Pascal (LCL):
  - `neurograph_player.exe`: Executável desktop autônomo.
  - `uplayer.pas`: Formulário de diálogo, histórico de chat, seletor de modelos e persistência INI (`neurograph_player.ini`).
  - `neurograph_player.lpi` e `compilar.bat`: Projeto e script de compilação com `lazbuild`.

---

## 🚀 Como Executar

### 1. Pela Interface Desktop (Lazarus)
Dê um duplo clique em:
```text
D:\projetos\maurinsoft\CHATGPT\NeuroGraph\play\lazarus\neurograph_player.exe
```
Ou execute pelo terminal:
```cmd
cd D:\projetos\maurinsoft\CHATGPT\NeuroGraph\play\lazarus
neurograph_player.exe
```

### 2. Pelo Terminal Interativo (REPL)
Execute o arquivo batch ou o script Python diretamente:
```cmd
cd D:\projetos\maurinsoft\CHATGPT\NeuroGraph\play
play.bat
```
Ou:
```cmd
python play.py
```

### 3. Por Linha de Comando (Pergunta Única)
```cmd
python play.py --pergunta "o que e um computador"
```

Saída com saída JSON:
```cmd
python play.py --pergunta "o que e um computador" --json
```

Especificando outro modelo:
```cmd
python play.py --modelo "D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\results\neurograph_contextual_v7.ngs" --pergunta "o que e inteligencia artificial"
```
