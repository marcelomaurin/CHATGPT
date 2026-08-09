# AI Evaluation

Componentes Lazarus para executar conjuntos de avaliacao de LLM e RAG sem
dependencia de servico externo.

- `TAIEvaluationDataset`: casos com entrada, esperado, obtido, contexto,
  chunks, fontes e score; persiste em JSON ou JSONL.
- `TAILexicalEvaluator`: F1 lexical deterministico e score RAG composto.
- `TAILLMJudge`: avaliador opcional via `TCHATGPT`, com retorno JSON
  estruturado e fallback lexical seguro.
- `TAIRegressionReporter`: relatorio legivel e JSON bruto com deltas.

Scores ficam no intervalo de 0 a 1. O avaliador lexical trabalha com tokens
alfanumericos normalizados; portanto e reproduzivel, mas nao mede equivalencia
semantica. Para isso, associe um `TCHATGPT` ao `TAILLMJudge`.
