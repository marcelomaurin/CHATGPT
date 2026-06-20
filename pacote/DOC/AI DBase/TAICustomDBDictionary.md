# TAICustomDBDictionary

Classe base abstrata para todos os componentes de dicionário de dados da suíte `AIDBase`.

## Propriedades Principais

- **Connection** (`TZConnection`): Conexão do ZeosLib para acessar o banco de dados.
- **SchemaName** (`string`): Filtro de schema (se aplicável ao banco correspondente, como PostgreSQL).
- **IncludeTables** (`Boolean`): Se deve incluir tabelas no dicionário (padrão: `True`).
- **IncludeViews** (`Boolean`): Se deve incluir views (padrão: `True`).
- **IncludeIndexes** (`Boolean`): Se deve incluir índices (padrão: `True`).
- **IncludePrimaryKeys** (`Boolean`): Se deve incluir chaves primárias (padrão: `True`).
- **IncludeForeignKeys** (`Boolean`): Se deve incluir chaves estrangeiras (padrão: `True`).
- **IncludeTriggers** (`Boolean`): Se deve incluir triggers (padrão: `True`).
- **IncludeSequences** (`Boolean`): Se deve incluir sequences (padrão: `True`).
- **IncludeRoutines** (`Boolean`): Se deve incluir procedures e functions (padrão: `True`).
- **IncludeSystemObjects** (`Boolean`): Se deve extrair objetos do sistema (padrão: `False`).
- **AutoConnect** (`Boolean`): Se deve abrir a conexão automaticamente caso esteja fechada no início da geração (padrão: `False`).

## Métodos

- **Generate**: Executa todas as consultas de metadados correspondentes e preenche a estrutura interna. Retorna `True` em caso de sucesso.
- **AsMarkdown**: Retorna a documentação gerada em formato Markdown.
- **AsJSON**: Retorna a estrutura gerada em formato JSON.
- **AsText**: Retorna a estrutura gerada em formato Texto.
- **AsAIPrompt**: Retorna a estrutura formatada como prompt otimizado para IAs.
- **SaveToMarkdown(const AFileName: string)**: Salva o Markdown em um arquivo.
- **SaveToJSON(const AFileName: string)**: Salva o JSON em um arquivo.
