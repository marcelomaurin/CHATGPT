# RAG retrieval and graph benchmark

Teste de integração e benchmark para embeddings locais, vector store em memória,
BM25, fusão RRF, orçamento de contexto e índices internos do `TAIRAG` e
`TAIGraphMap`.

```powershell
lazbuild rag_retrieval_graph_benchmark.lpi
.\rag_retrieval_graph_benchmark.exe
```

O executável usa `heaptrc`, falha com código diferente de zero em qualquer
asserção e imprime a vazão observada do ranking do grafo.
