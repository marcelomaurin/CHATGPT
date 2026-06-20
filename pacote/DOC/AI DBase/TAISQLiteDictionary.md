# TAISQLiteDictionary

Componente de extração de dicionário de dados específico para o motor de banco de dados local **SQLite**.

Ele herda de `TAICustomDBDictionary` e implementa as consultas utilizando as views internas `sqlite_master` e comandos específicos da API do SQLite como `PRAGMA table_info`, `PRAGMA foreign_key_list` e `PRAGMA index_list`.

## Funcionalidades Específicas

- Consulta tabelas e views estruturadas em `sqlite_master`.
- Executa `PRAGMA table_info` dinamicamente para cada tabela para obter os campos, tipos nativos e chaves primárias.
- Executa `PRAGMA foreign_key_list` para recuperar as relações de integridade referencial.
- Executa `PRAGMA index_list` e `PRAGMA index_info` para identificar índices locais e colunas indexadas.
- Extrai triggers diretamente através da tabela `sqlite_master`.
- Devido às limitações nativas do SQLite, o mapeamento de Procedures/Functions e Sequences não retorna registros de catálogo (o retorno para essas etapas será vazio/True).
