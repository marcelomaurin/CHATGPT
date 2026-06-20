# TAIPostgreSQLDictionary

Componente de extração de dicionário de dados específico para o motor de banco de dados **PostgreSQL**.

Ele herda de `TAICustomDBDictionary` e implementa as consultas de metadados consultando a estrutura padrão do PostgreSQL em `information_schema` e views de catálogo como `pg_indexes`.

## Funcionalidades Específicas

- Consulta tabelas em `information_schema.tables` omitindo schemas internos (`pg_catalog`, `information_schema`).
- Extrai detalhes das colunas (tipo nativo, precisão, nulo/não nulo, valor padrão).
- Mapeia chaves primárias e relacionamentos de chaves estrangeiras.
- Mapeia triggers da tabela e definições de views.
- Mapeia procedures e functions cadastrados no banco de dados.
- Mapeia generators / sequences ativos.
