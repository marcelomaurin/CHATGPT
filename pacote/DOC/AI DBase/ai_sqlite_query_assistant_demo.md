# AI SQLite Query Assistant Demo Documentation

The **AI SQLite Query Assistant** is a Lazarus demonstration application showing how to generate, validate, and execute SQLite SQL queries safely using natural language, `TCHATGPT` and the `TAISQLiteDictionary` component from the `openai_aidbase` package.

## Location
- Project Path: [ai_sqlite_query_assistant_demo](file:///d:/projetos/maurinsoft/CHATGPT/pacote/samples/AI%20DBase/ai_sqlite_query_assistant_demo/)
- Main Executable: `ai_sqlite_query_assistant_demo.exe`

## Technologies Used
- **Lazarus / Free Pascal** (GUI and logic)
- **ZeosLib** (`TZConnection`, `TZQuery`, `TDataSource`, `TDBGrid` for database access)
- **TCHATGPT** (LLM communication)
- **TAISQLiteDictionary** (schema catalog extractor)

## Architecture & Workflow

The application operates in a closed loop to safely execute SQL:

1. **Database Creation**: Creates a local SQLite database `sales_ai_demo.db` with structured tables (`customers`, `products`, `sales`, etc.) and fills it with sample sales data.
2. **Metadata Extraction**: Extracted schema information using `TAISQLiteDictionary` is compiled into a lightweight AI-optimized prompt (using `AsAIPrompt`).
3. **Prompt Composition**: The user request and the extracted schema are embedded into a system prompt.
4. **SQL Generation**: ChatGPT analyzes the schema and generates a single read-only SELECT statement.
5. **SQL Safety Validation**: An inline validator checks that the generated SQL begins with `SELECT` or `WITH`, and guarantees it does not contain mutating commands (`INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, etc.).
6. **Execution**: The query is executed using ZeosLib and the result is bound to a `TDBGrid` via a standard `TDataSource`.

## Security Features
All SQL queries are parsed prior to execution to enforce safety rules:
- Only `SELECT` and `WITH` statements are permitted.
- Destructive operations and keywords (`DROP`, `DELETE`, `ALTER`, etc.) are strictly blocked, protecting the SQLite database from unauthorized alterations.
