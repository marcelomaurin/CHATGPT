# NeuroGraph Tester (`tests`) — Suite de Avaliação e Benchmarks de Perguntas e Respostas

Esta pasta contém o ambiente oficial de **testes, benchmarks e aferição de qualidade das respostas** geradas pelos modelos do NeuroGraph (`.ngs`).

---

## 🌐 Bases de Teste de QA em Português (Internet + Local)

O avaliador busca e mantém atualizadas na pasta [`benchmarks/`](benchmarks/) as seguintes bases científicas e de avaliação:

1. **FaQuAD (`faquad_internet_completo.json` e `faquad_internet_objetivo.json`)**:
   - Base oficial brasileira estilo SQuAD (*Portuguese Reading Comprehension Dataset*), desenvolvida pelo Laboratório de Inteligência Artificial da UFMS (`liafacom/faquad`).
   - Contém **900 pares** de perguntas e respostas reais em português (`faquad_internet_completo.json`) e um recorte de **868 pares objetivos** com respostas diretas de até 25 tokens (`faquad_internet_objetivo.json`).
2. **NeuroGraph v7 Holdout (`neurograph_v7_holdout_test.json`)**:
   - Conjunto de teste separado do treinamento para aferir generalização sintática, retenção de contexto de sessão e abstenção em perguntas desconhecidas.
3. **NeuroGraph v7 Base (`neurograph_v7_base_train.json`)**:
   - Conjunto base de verificação de memória associativa.
4. **Propagação Relacional Holdout (`relational_holdout_20261113.py`)**:
   - Teste de propagação em grafo de 1-Hop e 2-Hop com retenção de sujeitos inéditos e rejeição de relações inexistentes.

---

## 📏 Métricas de Aferição Calculadas (`avaliador_qa.py`)

Para cada pergunta da base de teste, o aferidor compara a resposta gerada pelo modelo NeuroGraph com o gabarito esperado utilizando as métricas padrão de *Question Answering* (SQuAD / FaQuAD):

- **Exact Match (EM %)**: Percentual de respostas que coincidem exatamente (ou contêm integralmente) a resposta normalizada do gabarito.
- **Token F1-Score (%)**: Média harmônica entre a **Precisão** (proporção de tokens gerados que estão corretos) e o **Recall** (proporção de tokens do gabarito que foram cobertos pela resposta).
- **Taxa de Aprovação (%)**: Percentual de questões classificadas como `EXATO`, `APROXIMADO (Parcial)` ou `CORRETO (Abstenção Esperada)`.
- **Latência Média (ms)**: Tempo médio em milissegundos gasto pelo grafo para gerar cada resposta.

---

## 🖥️ Interface Gráfica Desktop em Lazarus (`lazarus/neurograph_tester.exe`)

A aplicação desktop nativa construída em Lazarus / Free Pascal permite:
- Selecionar qualquer rede `.ngs` compilada (`neurograph_youtube.ngs`, `neurograph_contextual_v7.ngs`, etc.).
- Selecionar qualquer base de benchmark `.json` (ou clicar em **`🌐 Baixar Base FaQuAD (Internet)`** para baixar/atualizar direto do repositório oficial).
- Marcar a opção opcional **"Calibrar/Treinar Rede com esta Base antes de Aferir"** para medir a capacidade de absorção da rede sobre um novo domínio da internet.
- Visualizar os **Indicadores (KPIs)** no topo e inspecionar linha por linha na **Tabela Comparativa** (`Pergunta` vs. `Gabarito Esperado` vs. `Resposta do Modelo` vs. `F1-Score` vs. `Status` vs. `Tempo ms`).
- Executar o benchmark de **Propagação Relacional (1-Hop e 2-Hop)** em aba dedicada.

### Como Abrir a Interface Gráfica:
Execute [iniciar_testes.bat](iniciar_testes.bat) ou diretamente:
```cmd
D:\projetos\maurinsoft\CHATGPT\NeuroGraph\tests\lazarus\neurograph_tester.exe
```

### Como Rodar via Linha de Comando (CLI):
```cmd
python D:\projetos\maurinsoft\CHATGPT\NeuroGraph\tests\avaliador_qa.py --baixar-internet
python D:\projetos\maurinsoft\CHATGPT\NeuroGraph\tests\avaliador_qa.py --benchmark benchmarks\faquad_internet_objetivo.json --max-itens 100 --calibrar-antes
```
