# hybrid_retrieval_demo

Demonstração visual (LCL) de **Recuperação Híbrida** combinando:
- **Busca Vetorial Densa (`TAIVectorRetriever`)** via embeddings locais
- **Busca Léxica (`TAIBM25Retriever`)** via algoritmo BM25
- **Fusão de Ranqueamento Recíproco (RRF - Reciprocal Rank Fusion)** via `TAIRAG` (`RetrievalMode = rrmHybrid`)

## Recursos da Interface Visual (.lfm / .pas):
1. **Painel de Documentos**:
   - Inserção e edição dinâmica de textos e fontes de conhecimento
   - Listagem dos documentos indexados com contagem de caracteres
   - Botão de recarga dos exemplos pré-configurados (Lazarus, Python, PostgreSQL)
   - Botão para reconstruir o índice vetorial e BM25 em tempo real
2. **Painel de Recuperação e Teste**:
   - Seletor de Modo de Recuperação: *Híbrido (RRF)*, *Vetorial Denso*, *Léxico BM25*
   - Configuração de `TopK`
   - Campo para digitação de queries e perguntas
   - `TListView` com exibição de ranking, documento/fonte, score de similaridade/RRF e trecho recuperado
   - `TMemo` de detalhamento do chunk selecionado
3. **Barra de Status**:
   - Exibição de tempo de indexação e tempo de resposta da busca em milissegundos.
