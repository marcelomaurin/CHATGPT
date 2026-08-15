# rag_bulkload_bench

Benchmark visual (LCL) de **Carga em Massa (BulkLoad)** do componente `TAIRAG`.

Compara a velocidade e desempenho da indexação de grandes volumes de texto/dados:
1. **Modo Convencional (SEM `BeginBulkLoad`)**: Indexação e parsing registro a registro.
2. **Modo Otimizado (COM `BeginBulkLoad`)**: Agrupamento em lote e suspensão temporária de reindexações parciais até `EndBulkLoad`.

## Recursos da Interface Visual:
- **Painel de Configuração**:
  - Quantidade de registros configurável (padrão: 20.000)
  - Configuração de `ChunkSize` e `ChunkOverlap`
  - Botão de benchmark comparativo automatizado
- **Painel de Resumo**:
  - Cards comparativos de tempo gasto em milissegundos
  - Cálculo automático de ganho de desempenho (*Speedup* / redução percentual de tempo)
- **Tabela de Resultados (TListView)**:
  - Estratégia, quantidade de registros, tempo total em ms, total de chunks gerados e taxa de transferência (registros por segundo)
- **Log e Barra de Progresso**:
  - Acompanhamento em tempo real da carga de dados.
