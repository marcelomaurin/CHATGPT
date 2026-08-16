# AI RAG

O pacote `openai_rag` fornece componentes de Retrieval-Augmented Generation (RAG) para Lazarus/Free Pascal. Ele integra indexação de documentos, busca por grafo, BM25, busca vetorial, reranking e montagem de contexto para `TCHATGPT` e `TAIAgent`.

## Integração com TAIAgent

`TAIRAG` implementa `IAIRAGProvider`, definido em `AI/airagbridge.pas`. Assim, `TAIAgent` recebe o provider pela propriedade `RAG` sem depender diretamente da unit concreta `airag`.

```pascal
RAG.GraphMap := GraphMap;
RAG.ChatGPT := ChatGPT;
Agent.RAG := RAG;
Agent.ChatGPT := ChatGPT;
```

O ownership não é transferido pela interface. Os componentes continuam administrados pelo `Owner`/`Free`, e o Agent usa `FreeNotification` para invalidar a referência quando o RAG é destruído.

## Fluxo mínimo

1. associe `GraphMap` e, quando houver geração de resposta, `ChatGPT`;
2. adicione conteúdo com `AddText`, `AddFile` ou `AddFolder`;
3. chame `BuildIndex`;
4. use `BuildContext` para recuperar contexto ou `Ask` para recuperar e gerar resposta.

Samples principais:

- `pacote/samples/AI RAG/rag_file_indexing_demo/` — indexação e consulta de arquivos;
- `pacote/samples/AI RAG/hybrid_retrieval_demo/` — recuperação híbrida;
- `pacote/samples/AI Agent/agent_rag_demo/` — integração Agent + RAG.

## Recuperação avançada

`RetrievalMode` seleciona `rrmGraph`, `rrmVector`, `rrmBM25` ou `rrmHybrid`.

No modo híbrido, os rankings podem ser combinados por Reciprocal Rank Fusion (`RRFRankConstant`) e opcionalmente enviados a um componente que implemente `IAIReranker`.

`airetrieval.pas` inclui:

- `TAILocalEmbeddingProvider` — embedding local determinístico, sem serviço externo;
- `TAIOpenAIEmbeddingProvider` — cliente para endpoint compatível com embeddings;
- `TAIVectorStore` e `TAIVectorRetriever` — armazenamento e busca vetorial em memória;
- `TAIBM25Retriever` — recuperação lexical BM25;
- `TAIRankFusion` — fusão de rankings;
- `TAILLMReranker` — reranking com LLM.

## Tokenização e orçamento de contexto

A unit `airag_textutils.pas` centraliza utilitários de texto usados pelo retrieval. A tokenização usada pelo BM25 e pelo embedding local trata texto Unicode, evitando perder palavras acentuadas comuns em documentos em português e outros idiomas.

`ContextTokenBudget` limita os trechos usados na montagem do prompt. A estimativa atual é baseada em palavras/tokens aproximados e não em uma regra fixa de bytes ou caracteres. Portanto, o orçamento é uma aproximação para controle de contexto, não uma contagem exata do tokenizer do modelo remoto.

## Chunking semântico

Os utilitários de RAG incluem segmentação por parágrafo/sentença com overlap controlado. O objetivo é reduzir cortes no meio de unidades semânticas, preservando contexto entre chunks consecutivos.

Metadados de chunks devem manter, quando disponíveis, identificador, origem e posição necessárias para rastrear a fonte exibida ao usuário.

## Estado da última operação

- `GetLastQuestion` — pergunta usada na última recuperação;
- `GetLastContext` — contexto textual montado;
- `GetLastAnswer` — resposta produzida pela última chamada de `Ask`;
- `GetLastSources` — fontes recuperadas pertencentes ao provider.

O consumidor pode ler ou copiar `GetLastSources`, mas não deve liberar a lista retornada.

As propriedades legadas `LastQuestion`, `LastContext`, `LastAnswer` e `LastSources` continuam disponíveis para compatibilidade.

## Segurança de credenciais

`TAIOpenAIEmbeddingProvider.Token` não deve ser persistido em arquivos `.lfm`. Defina tokens em runtime, a partir da configuração segura da aplicação.

Nunca coloque chaves reais em samples, arquivos versionados ou propriedades serializadas do formulário.

## Reindexação

`TAIRAG` mantém identificação dos chunks e oferece `ReindexChunks` quando o host altera diretamente o conteúdo usado pelo índice. Reindexe sempre que a base documental for modificada fora do fluxo normal de `AddText`, `AddFile` ou `AddFolder`.

## Limitações atuais

A implementação oferece retrieval funcional, porém persistência completa de índices vetoriais/BM25, indexação assíncrona e benchmark de grandes coleções continuam áreas de evolução. Não trate o índice em memória como substituto automático de uma camada de persistência em aplicações que precisam reiniciar sem reindexar os documentos.

Detalhes do contrato e ciclo de vida: [`IAIRAGProvider.md`](IAIRAGProvider.md).
