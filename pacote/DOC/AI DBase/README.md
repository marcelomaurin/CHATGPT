# AIDBase - Dicionário de Estrutura de Banco de Dados para IA

Este pacote fornece componentes não visuais do Lazarus que geram um **dicionário de dados** estrutural a partir de uma conexão ZeosLib (`TZConnection`).
A documentação estrutural gerada é ideal para análise técnica, auditorias de banco de dados, e especialmente para servir de contexto em prompts de modelos de IA (como GPT, Claude, Gemini).

## Componentes Disponíveis

- **TAIPostgreSQLDictionary**: Extração de metadados de bancos PostgreSQL utilizando `information_schema`.
- **TAISQLiteDictionary**: Extração de metadados de bancos locais SQLite utilizando `sqlite_master` e comandos `PRAGMA`.
- **Outros bancos**: Estruturas preparadas para MySQL, Firebird, SQL Server e Oracle.

## Formatos de Exportação

- **Markdown**: Formato legível e estruturado em tabelas.
- **JSON**: Formato ideal para consumo automatizado e transmissão por APIs.
- **Texto Simples**: Formato legível em texto puro.
- **AI Prompt**: Formato otimizado para que um Large Language Model (LLM) compreenda instantaneamente a estrutura e relacionamentos do banco de dados.

## Exemplo de Uso (Delphi/Pascal)

```pascal
var
  Dict: TAIPostgreSQLDictionary;
begin
  Dict := TAIPostgreSQLDictionary.Create(Self);
  try
    Dict.Connection := ZConnection1;
    Dict.SchemaName := 'public';
    Dict.IncludeTables := True;
    Dict.IncludeViews := True;
    Dict.IncludeForeignKeys := True;
    Dict.OutputFormat := dofMarkdown;
    
    if Dict.Generate then
    begin
      Memo1.Text := Dict.AsMarkdown; // Ou Dict.AsJSON, Dict.AsAIPrompt
    end
    else
    begin
      ShowMessage('Erro: ' + Dict.LastError);
    end;
  finally
    Dict.Free;
  end;
end;
```
