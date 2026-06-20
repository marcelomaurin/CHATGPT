unit aidb_dictionary_exporter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aidb_types, fpjson, jsonparser;

type
  TAIDBDataDictionaryExporter = class
  private
    class function EngineToString(AEngine: TAIDBEngine): string;
  public
    class function ToText(ADictionary: TAIDBDataDictionary): string;
    class function ToMarkdown(ADictionary: TAIDBDataDictionary): string;
    class function ToJSON(ADictionary: TAIDBDataDictionary): string;
    class function ToAIPrompt(ADictionary: TAIDBDataDictionary): string;
  end;

implementation

class function TAIDBDataDictionaryExporter.EngineToString(AEngine: TAIDBEngine): string;
begin
  case AEngine of
    dbPostgreSQL: Result := 'PostgreSQL';
    dbMySQL:      Result := 'MySQL';
    dbMariaDB:    Result := 'MariaDB';
    dbSQLite:     Result := 'SQLite';
    dbFirebird:   Result := 'Firebird';
    dbSQLServer:  Result := 'SQL Server';
    dbOracle:     Result := 'Oracle';
    else          Result := 'Unknown';
  end;
end;

class function TAIDBDataDictionaryExporter.ToText(ADictionary: TAIDBDataDictionary): string;
var
  sb: TStringList;
  i, j: Integer;
  t: TAIDBTableInfo;
  c: TAIDBColumnInfo;
  fk: TAIDBForeignKeyInfo;
  idx: TAIDBIndexInfo;
  v: TAIDBViewInfo;
  trig: TAIDBTriggerInfo;
  seq: TAIDBSequenceInfo;
  rt: TAIDBRoutineInfo;
begin
  sb := TStringList.Create;
  try
    sb.Add('DATABASE DATA DICTIONARY');
    sb.Add('========================');
    sb.Add('Engine: ' + EngineToString(ADictionary.Engine));
    sb.Add('Database: ' + ADictionary.DatabaseName);
    sb.Add('Schema: ' + ADictionary.SchemaName);
    sb.Add('Generated At: ' + DateTimeToStr(ADictionary.GeneratedAt));
    sb.Add('');

    sb.Add('TABLES (' + IntToStr(ADictionary.Tables.Count) + ')');
    sb.Add('------');
    for i := 0 to ADictionary.Tables.Count - 1 do
    begin
      t := ADictionary.Tables[i];
      sb.Add(Format('Table: %s (Type: %s, Rows: %d)', [t.TableName, t.TableType, t.RowCount]));
      if t.Description <> '' then
        sb.Add('  Description: ' + t.Description);
      sb.Add('  Columns:');
      for j := 0 to t.Columns.Count - 1 do
      begin
        c := t.Columns[j];
        sb.Add(Format('    - %s (%s, Nullable: %s, PK: %s, FK: %s, Default: %s) - %s', [
          c.ColumnName, c.DataType, BoolToStr(c.Nullable, 'Yes', 'No'),
          BoolToStr(c.IsPrimaryKey, 'Yes', 'No'), BoolToStr(c.IsForeignKey, 'Yes', 'No'),
          c.DefaultValue, c.Description
        ]));
      end;
      sb.Add('');
    end;

    if ADictionary.ForeignKeys.Count > 0 then
    begin
      sb.Add('FOREIGN KEYS');
      sb.Add('------------');
      for i := 0 to ADictionary.ForeignKeys.Count - 1 do
      begin
        fk := ADictionary.ForeignKeys[i];
        sb.Add(Format('  - %s: %s.%s -> %s.%s (Update: %s, Delete: %s)', [
          fk.ConstraintName, fk.TableName, fk.ColumnName, fk.RefTableName, fk.RefColumnName,
          fk.UpdateRule, fk.DeleteRule
        ]));
      end;
      sb.Add('');
    end;

    if ADictionary.Indexes.Count > 0 then
    begin
      sb.Add('INDICES');
      sb.Add('-------');
      for i := 0 to ADictionary.Indexes.Count - 1 do
      begin
        idx := ADictionary.Indexes[i];
        sb.Add(Format('  - %s on %s.%s (Unique: %s, Primary: %s, Type: %s)', [
          idx.IndexName, idx.TableName, idx.ColumnName, BoolToStr(idx.IsUnique, 'Yes', 'No'),
          BoolToStr(idx.IsPrimary, 'Yes', 'No'), idx.IndexType
        ]));
      end;
      sb.Add('');
    end;

    if ADictionary.Views.Count > 0 then
    begin
      sb.Add('VIEWS');
      sb.Add('-----');
      for i := 0 to ADictionary.Views.Count - 1 do
      begin
        v := ADictionary.Views[i];
        sb.Add('  View: ' + v.ViewName);
        if v.Description <> '' then
          sb.Add('    Description: ' + v.Description);
        sb.Add('    Definition: ' + v.SQLDefinition);
        sb.Add('');
      end;
    end;

    if ADictionary.Triggers.Count > 0 then
    begin
      sb.Add('TRIGGERS');
      sb.Add('--------');
      for i := 0 to ADictionary.Triggers.Count - 1 do
      begin
        trig := ADictionary.Triggers[i];
        sb.Add(Format('  - Trigger: %s on %s (Event: %s, Timing: %s, Enabled: %s)', [
          trig.TriggerName, trig.TableName, trig.EventName, trig.Timing, BoolToStr(trig.Enabled, 'Yes', 'No')
        ]));
        sb.Add('    Definition: ' + trig.SQLDefinition);
      end;
      sb.Add('');
    end;

    if ADictionary.Sequences.Count > 0 then
    begin
      sb.Add('SEQUENCES');
      sb.Add('---------');
      for i := 0 to ADictionary.Sequences.Count - 1 do
      begin
        seq := ADictionary.Sequences[i];
        sb.Add(Format('  - %s (Current: %s, Increment: %d)', [
          seq.SequenceName, seq.CurrentValue, seq.IncrementBy
        ]));
      end;
      sb.Add('');
    end;

    if ADictionary.Routines.Count > 0 then
    begin
      sb.Add('ROUTINES');
      sb.Add('--------');
      for i := 0 to ADictionary.Routines.Count - 1 do
      begin
        rt := ADictionary.Routines[i];
        sb.Add(Format('  - %s: %s (Returns: %s)', [
          rt.RoutineType, rt.RoutineName, rt.ReturnType
        ]));
        if rt.SQLDefinition <> '' then
          sb.Add('    Definition: ' + rt.SQLDefinition);
      end;
      sb.Add('');
    end;

    Result := sb.Text;
  finally
    sb.Free;
  end;
end;

class function TAIDBDataDictionaryExporter.ToMarkdown(ADictionary: TAIDBDataDictionary): string;
var
  sb: TStringList;
  i, j, k: Integer;
  t: TAIDBTableInfo;
  c: TAIDBColumnInfo;
  fk: TAIDBForeignKeyInfo;
  idx: TAIDBIndexInfo;
  v: TAIDBViewInfo;
  trig: TAIDBTriggerInfo;
  seq: TAIDBSequenceInfo;
  rt: TAIDBRoutineInfo;
begin
  sb := TStringList.Create;
  try
    sb.Add('# Dicionário de Dados');
    sb.Add('');
    sb.Add('## Banco de Dados');
    sb.Add('');
    sb.Add('- **Engine**: ' + EngineToString(ADictionary.Engine));
    if ADictionary.DatabaseName <> '' then
      sb.Add('- **Banco**: ' + ADictionary.DatabaseName);
    if ADictionary.SchemaName <> '' then
      sb.Add('- **Schema**: ' + ADictionary.SchemaName);
    sb.Add('- **Gerado em**: ' + DateTimeToStr(ADictionary.GeneratedAt));
    sb.Add('');

    sb.Add('## Tabelas');
    sb.Add('');
    for i := 0 to ADictionary.Tables.Count - 1 do
    begin
      t := ADictionary.Tables[i];
      sb.Add('### Tabela: ' + t.TableName);
      sb.Add('');
      if t.Description <> '' then
      begin
        sb.Add('**Descrição**: ' + t.Description);
        sb.Add('');
      end;
      if t.RowCount > 0 then
      begin
        sb.Add(Format('**Registros**: %d', [t.RowCount]));
        sb.Add('');
      end;

      sb.Add('| Campo | Tipo | Tamanho | Nulo | PK | FK | Padrão | Descrição |');
      sb.Add('|---|---|---:|---|---|---|---|---|');
      for j := 0 to t.Columns.Count - 1 do
      begin
        c := t.Columns[j];
        sb.Add(Format('| %s | %s | %s | %s | %s | %s | %s | %s |', [
          c.ColumnName, c.DataType,
          IfThen(c.Size > 0, IntToStr(c.Size), ''),
          BoolToStr(c.Nullable, 'Sim', 'Não'),
          BoolToStr(c.IsPrimaryKey, 'Sim', 'Não'),
          BoolToStr(c.IsForeignKey, 'Sim', 'Não'),
          c.DefaultValue, c.Description
        ]));
      end;
      sb.Add('');

      // FKs of this table
      sb.Add('#### Chaves Estrangeiras');
      sb.Add('');
      sb.Add('| Nome | Campo | Referência | Regras |');
      sb.Add('|---|---|---|---|');
      k := 0;
      for j := 0 to ADictionary.ForeignKeys.Count - 1 do
      begin
        fk := ADictionary.ForeignKeys[j];
        if SameText(fk.TableName, t.TableName) then
        begin
          sb.Add(Format('| %s | %s | %s.%s | U: %s / D: %s |', [
            fk.ConstraintName, fk.ColumnName, fk.RefTableName, fk.RefColumnName,
            fk.UpdateRule, fk.DeleteRule
          ]));
          Inc(k);
        end;
      end;
      if k = 0 then
        sb.Add('| - | - | Nenhuma chave estrangeira | - |');
      sb.Add('');

      // Indices of this table
      sb.Add('#### Índices');
      sb.Add('');
      sb.Add('| Nome | Campos | Único | Tipo |');
      sb.Add('|---|---|---|---|');
      k := 0;
      for j := 0 to ADictionary.Indexes.Count - 1 do
      begin
        idx := ADictionary.Indexes[j];
        if SameText(idx.TableName, t.TableName) then
        begin
          sb.Add(Format('| %s | %s | %s | %s |', [
            idx.IndexName, idx.ColumnName,
            BoolToStr(idx.IsUnique, 'Sim', 'Não'),
            idx.IndexType
          ]));
          Inc(k);
        end;
      end;
      if k = 0 then
        sb.Add('| - | - | Nenhum índice | - |');
      sb.Add('');
    end;

    if ADictionary.Views.Count > 0 then
    begin
      sb.Add('## Views');
      sb.Add('');
      for i := 0 to ADictionary.Views.Count - 1 do
      begin
        v := ADictionary.Views[i];
        sb.Add('### View: ' + v.ViewName);
        sb.Add('');
        if v.Description <> '' then
          sb.Add('*Descrição*: ' + v.Description + sLineBreak);
        sb.Add('```sql');
        sb.Add(v.SQLDefinition);
        sb.Add('```');
        sb.Add('');
      end;
    end;

    if ADictionary.Triggers.Count > 0 then
    begin
      sb.Add('## Triggers');
      sb.Add('');
      for i := 0 to ADictionary.Triggers.Count - 1 do
      begin
        trig := ADictionary.Triggers[i];
        sb.Add(Format('### Trigger: %s (Tabela: %s, Evento: %s, Momento: %s)', [
          trig.TriggerName, trig.TableName, trig.EventName, trig.Timing
        ]));
        sb.Add('');
        sb.Add('```sql');
        sb.Add(trig.SQLDefinition);
        sb.Add('```');
        sb.Add('');
      end;
    end;

    if ADictionary.Sequences.Count > 0 then
    begin
      sb.Add('## Sequences');
      sb.Add('');
      sb.Add('| Nome | Schema | Valor Atual | Incremento |');
      sb.Add('|---|---|---|---|');
      for i := 0 to ADictionary.Sequences.Count - 1 do
      begin
        seq := ADictionary.Sequences[i];
        sb.Add(Format('| %s | %s | %s | %d |', [
          seq.SequenceName, seq.SchemaName, seq.CurrentValue, seq.IncrementBy
        ]));
      end;
      sb.Add('');
    end;

    if ADictionary.Routines.Count > 0 then
    begin
      sb.Add('## Procedures & Functions');
      sb.Add('');
      for i := 0 to ADictionary.Routines.Count - 1 do
      begin
        rt := ADictionary.Routines[i];
        sb.Add(Format('### %s: %s (Retorno: %s)', [
          rt.RoutineType, rt.RoutineName, rt.ReturnType
        ]));
        sb.Add('');
        if rt.SQLDefinition <> '' then
        begin
          sb.Add('```sql');
          sb.Add(rt.SQLDefinition);
          sb.Add('```');
          sb.Add('');
        end;
      end;
    end;

    Result := sb.Text;
  finally
    sb.Free;
  end;
end;

class function TAIDBDataDictionaryExporter.ToJSON(ADictionary: TAIDBDataDictionary): string;
var
  TableObj, ColObj, FkObj, IdxObj, ViewObj, TrigObj, SeqObj, RoutObj: TJSONObject;
  i, j: Integer;
  t: TAIDBTableInfo;
  c: TAIDBColumnInfo;
  fk: TAIDBForeignKeyInfo;
  idx: TAIDBIndexInfo;
  v: TAIDBViewInfo;
  trig: TAIDBTriggerInfo;
  seq: TAIDBSequenceInfo;
  rt: TAIDBRoutineInfo;
  TopLevel: TJSONObject;
  TablesArray, ViewsArray, FksArray, IdxsArray, TrigsArray, SeqsArray, RoutinesArray: TJSONArray;
  ColumnsArray: TJSONArray;
begin
  TopLevel := TJSONObject.Create;
  try
    TopLevel.Add('engine', EngineToString(ADictionary.Engine));
    TopLevel.Add('schema', ADictionary.SchemaName);
    TopLevel.Add('database', ADictionary.DatabaseName);
    TopLevel.Add('generated_at', DateTimeToStr(ADictionary.GeneratedAt));

    TablesArray := TJSONArray.Create;
    for i := 0 to ADictionary.Tables.Count - 1 do
    begin
      t := ADictionary.Tables[i];
      TableObj := TJSONObject.Create;
      TableObj.Add('schema', t.SchemaName);
      TableObj.Add('name', t.TableName);
      TableObj.Add('type', t.TableType);
      TableObj.Add('description', t.Description);
      TableObj.Add('row_count', t.RowCount);

      ColumnsArray := TJSONArray.Create;
      for j := 0 to t.Columns.Count - 1 do
      begin
        c := t.Columns[j];
        ColObj := TJSONObject.Create;
        ColObj.Add('name', c.ColumnName);
        ColObj.Add('type', c.DataType);
        ColObj.Add('native_type', c.NativeDataType);
        ColObj.Add('size', c.Size);
        ColObj.Add('precision', c.Precision);
        ColObj.Add('scale', c.Scale);
        ColObj.Add('nullable', c.Nullable);
        ColObj.Add('default', c.DefaultValue);
        ColObj.Add('primary_key', c.IsPrimaryKey);
        ColObj.Add('foreign_key', c.IsForeignKey);
        ColObj.Add('unique', c.IsUnique);
        ColObj.Add('description', c.Description);
        ColumnsArray.Add(ColObj);
      end;
      TableObj.Add('columns', ColumnsArray);
      TablesArray.Add(TableObj);
    end;
    TopLevel.Add('tables', TablesArray);

    ViewsArray := TJSONArray.Create;
    for i := 0 to ADictionary.Views.Count - 1 do
    begin
      v := ADictionary.Views[i];
      ViewObj := TJSONObject.Create;
      ViewObj.Add('schema', v.SchemaName);
      ViewObj.Add('name', v.ViewName);
      ViewObj.Add('sql', v.SQLDefinition);
      ViewObj.Add('description', v.Description);
      ViewsArray.Add(ViewObj);
    end;
    TopLevel.Add('views', ViewsArray);

    FksArray := TJSONArray.Create;
    for i := 0 to ADictionary.ForeignKeys.Count - 1 do
    begin
      fk := ADictionary.ForeignKeys[i];
      FkObj := TJSONObject.Create;
      FkObj.Add('name', fk.ConstraintName);
      FkObj.Add('table', fk.TableName);
      FkObj.Add('column', fk.ColumnName);
      FkObj.Add('ref_table', fk.RefTableName);
      FkObj.Add('ref_column', fk.RefColumnName);
      FkObj.Add('update_rule', fk.UpdateRule);
      FkObj.Add('delete_rule', fk.DeleteRule);
      FksArray.Add(FkObj);
    end;
    TopLevel.Add('foreign_keys', FksArray);

    IdxsArray := TJSONArray.Create;
    for i := 0 to ADictionary.Indexes.Count - 1 do
    begin
      idx := ADictionary.Indexes[i];
      IdxObj := TJSONObject.Create;
      IdxObj.Add('name', idx.IndexName);
      IdxObj.Add('table', idx.TableName);
      IdxObj.Add('column', idx.ColumnName);
      IdxObj.Add('unique', idx.IsUnique);
      IdxObj.Add('primary', idx.IsPrimary);
      IdxObj.Add('type', idx.IndexType);
      IdxsArray.Add(IdxObj);
    end;
    TopLevel.Add('indexes', IdxsArray);

    TrigsArray := TJSONArray.Create;
    for i := 0 to ADictionary.Triggers.Count - 1 do
    begin
      trig := ADictionary.Triggers[i];
      TrigObj := TJSONObject.Create;
      TrigObj.Add('name', trig.TriggerName);
      TrigObj.Add('table', trig.TableName);
      TrigObj.Add('event', trig.EventName);
      TrigObj.Add('timing', trig.Timing);
      TrigObj.Add('sql', trig.SQLDefinition);
      TrigObj.Add('enabled', trig.Enabled);
      TrigsArray.Add(TrigObj);
    end;
    TopLevel.Add('triggers', TrigsArray);

    SeqsArray := TJSONArray.Create;
    for i := 0 to ADictionary.Sequences.Count - 1 do
    begin
      seq := ADictionary.Sequences[i];
      SeqObj := TJSONObject.Create;
      SeqObj.Add('name', seq.SequenceName);
      SeqObj.Add('schema', seq.SchemaName);
      SeqObj.Add('value', seq.CurrentValue);
      SeqObj.Add('increment', seq.IncrementBy);
      SeqsArray.Add(SeqObj);
    end;
    TopLevel.Add('sequences', SeqsArray);

    RoutinesArray := TJSONArray.Create;
    for i := 0 to ADictionary.Routines.Count - 1 do
    begin
      rt := ADictionary.Routines[i];
      RoutObj := TJSONObject.Create;
      RoutObj.Add('name', rt.RoutineName);
      RoutObj.Add('type', rt.RoutineType);
      RoutObj.Add('schema', rt.SchemaName);
      RoutObj.Add('returns', rt.ReturnType);
      RoutObj.Add('sql', rt.SQLDefinition);
      RoutinesArray.Add(RoutObj);
    end;
    TopLevel.Add('routines', RoutinesArray);

    Result := TopLevel.AsJSON;
  finally
    TopLevel.Free;
  end;
end;

class function TAIDBDataDictionaryExporter.ToAIPrompt(ADictionary: TAIDBDataDictionary): string;
var
  sb: TStringList;
  i, j: Integer;
  t: TAIDBTableInfo;
  c: TAIDBColumnInfo;
  fk: TAIDBForeignKeyInfo;
begin
  sb := TStringList.Create;
  try
    sb.Add(Format('Você está analisando um banco de dados %s.', [EngineToString(ADictionary.Engine)]));
    sb.Add('');

    for i := 0 to ADictionary.Tables.Count - 1 do
    begin
      t := ADictionary.Tables[i];
      sb.Add(Format('Tabela %s:', [t.TableName]));
      if t.Description <> '' then
        sb.Add('  - Descrição: ' + t.Description);
      for j := 0 to t.Columns.Count - 1 do
      begin
        c := t.Columns[j];
        sb.Add(Format('  - %s: %s%s%s%s', [
          c.ColumnName, c.DataType,
          IfThen(c.IsPrimaryKey, ', PK', ''),
          IfThen(not c.Nullable, ', obrigatório', ', opcional'),
          IfThen(c.IsForeignKey, ', FK', '')
        ]));
      end;
      sb.Add('');
    end;

    if ADictionary.ForeignKeys.Count > 0 then
    begin
      sb.Add('Relacionamentos:');
      for i := 0 to ADictionary.ForeignKeys.Count - 1 do
      begin
        fk := ADictionary.ForeignKeys[i];
        sb.Add(Format('- %s.%s -> %s.%s', [
          fk.TableName, fk.ColumnName, fk.RefTableName, fk.RefColumnName
        ]));
      end;
      sb.Add('');
    end;

    sb.Add('Use este dicionário para responder perguntas, gerar SQL, criar relatórios e explicar a estrutura do sistema.');
    Result := sb.Text;
  finally
    sb.Free;
  end;
end;

end.
