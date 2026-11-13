# NeuroGraph v7: pesos aprendidos e geração contextual

Protótipo Python de uma rede associativa autoregressiva. Os pesos das conexões são ajustados pelo erro de previsão do próximo token. A inferência consulta pesos, pergunta, prefixo gerado e estado recorrente; não seleciona uma resposta completa armazenada. Não há regras gramaticais específicas de português no gerador.

É um modelo linear de características recorrentes, **não uma RNN profunda nem um LLM pré-treinado**. O avanço foi medido em um corpus pequeno, parcialmente sintético. Não substitui a implementação Free Pascal existente.

## Resultado verificado em 13/11/2026

156 exemplos de treinamento, 117 de validação e 54 de teste. As perguntas de teste não entram no ajuste dos pesos nem na seleção dos limiares. A v6 foi retreinada nos mesmos exemplos e recebeu sua própria calibração na validação, com 300 configurações; a política da v7 também foi escolhida apenas na validação.

| Teste separado | v6 recalibrada | v7 |
| --- | ---: | ---: |
| Paráfrases novas de fatos aprendidos | 29/31 | 30/31 |
| Mesma pergunta com contextos diferentes | 0/8 | 8/8 |
| Combinações de resposta ausentes do treino | 0/7 | 7/7 |
| Abstenção correta em assuntos desconhecidos | 8/8 | 6/8 |
| Total de decisões corretas, incluindo abstenções | 37/54 | 51/54 |

**Regressão conhecida:** a v7 deu duas respostas indevidas a perguntas desconhecidas (`plutônio` e `titânio`). Também recusou uma paráfrase que deveria responder. O relatório inclui todas as previsões e falhas. Não se demonstrou compreensão geral de português, aprendizagem de fatos nunca apresentados ou desempenho no Raspberry Pi.

Os nove testes automatizados passaram, incluindo atualização de pesos, geração condicionada, contexto, aprendizado incremental com repetição dos exemplos anteriores, persistência e rejeição de arquivos corrompidos. O arquivo de pesos publicado tem 1.520.134 bytes, 139 tokens de saída, 4.932 nós de características e 111.816 conexões armazenadas em float32. O consumo máximo do processo de experimento foi 89.056 KiB neste Linux x86_64; esse número inclui treinamento e comparação.

## Perguntar sem instalar bibliotecas

Python 3.10 ou superior. A inferência usa somente a biblioteca padrão e os pesos publicados; não precisa dos dados de treino, NumPy, SciPy ou internet.

```sh
cd NeuroGraph/experiments/contextual_v7
python3 ask.py "descreva luma e nino"
```

Saída verificada: `luma é azul e nino é verde`. Essa combinação completa não apareceu no treino; os fatos individuais sobre as entidades fictícias apareceram.

No Windows, depois de atualizar o clone local da branch `main`:

```powershell
git -C C:\projetos\maurinsoft\CHATGPT pull --ff-only origin main
cd C:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7
py -3 ask.py "descreva luma e nino"
```

Adapte somente a pasta se o clone estiver em outra unidade. Esses comandos precisam ser executados no computador do usuário; publicar no GitHub não atualiza automaticamente o clone local.

Contexto persistente é opcional:

```sh
python3 ask.py --session conversa.json "o que é um computador"
python3 ask.py --session conversa.json "pode repetir a explicação"
python3 ask.py --trace "descreva luma e nino"
```

Os arquivos de conversa são locais. A geração não modifica os pesos nem reforça automaticamente o próprio texto.

## Reproduzir treinamento e testes

```sh
python3 -m pip install -r requirements-training.txt
python3 -m unittest -v test_model.py
python3 run_experiment.py
```

`data/benchmark.json` foi congelado antes do primeiro ajuste. `make_dataset.py` documenta sua construção e não precisa ser executado para usar o modelo. Os 98 exemplos antigos já usados na calibração da v6 são somente validação. O teste novo contém perguntas e combinações separadas; os resultados ainda são de uma tarefa pequena criada para este experimento, não uma avaliação humana independente.

`run_experiment.py` ajusta os pesos somente com `train`, escolhe a política somente com `validation`, grava e recarrega os pesos e só então avalia `test`. Os parâmetros da v7 foram fixados antes da avaliação de teste. A calibração adicional da linha de base não alterou os pesos nem a política da v7. Tempos e últimos bits dos pesos podem variar entre versões de NumPy, SciPy e BLAS.

## Arquivos

- `model.py`: pesos, estado recorrente, treinamento, geração e formato binário.
- `ask.py`: perguntas e contexto persistente pela linha de comando.
- `test_model.py`: nove testes de comportamento e integridade.
- `data/benchmark.json`: treino, validação e teste com origem e categorias.
- `results/neurograph_contextual_v7.ngs`: pesos executáveis publicados.
- `results/evaluation.json`: métricas, parâmetros, hashes e todas as previsões.
- `baseline_v6/`: fontes e pesos originais necessários à comparação, preservados do pacote de continuidade de 12/11/2026.

O arquivo `.ngs` desta versão tem assinatura `NGCTX007`, esquema 1 e checksum SHA-256. Contém vocabulário, nomes das características e arestas binárias `(origem, destino, peso float32)`; não contém a lista de respostas de treinamento. Não é compatível com `NGSEQ005` nem com as unidades Pascal atuais. [Método e limites](../../docs/contextual_v7_20261113.md).
