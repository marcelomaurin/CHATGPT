# AI RAG

O package `openai_rag` fornece `TAIRAG`, componente de retrieval augmented
generation integrado a `TAIGraphMap` e `TCHATGPT`.

## Integracao com TAIAgent

`TAIRAG` implementa `IAIRAGProvider`, definido em `AI/airagbridge.pas`.
Assim, `TAIAgent` recebe o componente pela propriedade `RAG` sem depender da
unit concreta `airag`.

```pascal
RAG.GraphMap := GraphMap;
RAG.ChatGPT := ChatGPT;
Agent.RAG := RAG;
Agent.ChatGPT := ChatGPT;
```

O ownership nao e transferido pela interface. Os componentes continuam sendo
administrados pelo `Owner`/`Free`, e `TAIAgent` usa `FreeNotification` para
limpar sua referencia quando o RAG e destruido.

## Estado da ultima operacao

- `GetLastQuestion`: pergunta usada na ultima recuperacao.
- `GetLastContext`: contexto textual montado para o LLM.
- `GetLastAnswer`: resposta produzida pela ultima chamada de `Ask`.
- `GetLastSources`: lista pertencente ao provider com as fontes recuperadas.
  O consumidor pode ler ou copiar a lista, mas nao deve libera-la.

As propriedades legadas `LastQuestion`, `LastContext`, `LastAnswer` e
`LastSources` continuam disponiveis.

## Fluxo minimo

1. Associe `GraphMap` e, para geracao, `ChatGPT`.
2. Adicione conteudo com `AddText`, `AddFile` ou `AddFolder`.
3. Chame `BuildIndex`.
4. Use `BuildContext` para apenas recuperar contexto ou `Ask` para recuperar e
   gerar uma resposta.

Veja `samples/AI Agent/agent_rag_demo` para o fluxo completo com `TAIAgent` e
`samples/AI RAG/rag_file_indexing_demo` para indexacao de arquivos.

## Recuperação avançada

`RetrievalMode` seleciona `rrmGraph`, `rrmVector`, `rrmBM25` ou `rrmHybrid`.
O modo híbrido combina os rankings do grafo, busca vetorial e BM25 por
Reciprocal Rank Fusion (`RRFRankConstant`) e, opcionalmente, passa o resultado
por um componente que implemente `IAIReranker`. `ContextTokenBudget` limita os
trechos antes da montagem do prompt.

`airetrieval.pas` inclui:

- `TAILocalEmbeddingProvider`, determinístico e sem serviço externo;
- `TAIOpenAIEmbeddingProvider`, para endpoint compatível com embeddings;
- `TAIVectorStore` e `TAIVectorRetriever` em memória;
- `TAIBM25Retriever`, `TAIRankFusion` e `TAILLMReranker`.

`TAIRAG` mantém um índice de `ChunkID` e oferece `ReindexChunks` quando o host
altera `GraphMap.Training` diretamente. O sample
`samples/AI RAG/hybrid_retrieval_demo` mostra o fluxo completo sem API externa.

Detalhes da decisao de interface e ciclo de vida estao em
[`IAIRAGProvider.md`](IAIRAGProvider.md).
