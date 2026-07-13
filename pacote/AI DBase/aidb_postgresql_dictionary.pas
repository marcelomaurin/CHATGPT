unit aidb_postgresql_dictionary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZDataset, aidb_types, aidb_dictionary_base, LResources;

type
  TAIPostgreSQLDictionary = class(TAICustomDBDictionary)
  protected
    function GetEngine: TAIDBEngine; override;
    function LoadTables: Boolean; override;
    function LoadColumns: Boolean; override;
    function LoadPrimaryKeys: Boolean; override;
    function LoadForeignKeys: Boolean; override;
    function LoadIndexes: Boolean; override;
    function LoadViews: Boolean; override;
    function LoadTriggers: Boolean; override;
    function LoadSequences: Boolean; override;
    function LoadRoutines: Boolean; override;
  end;

implementation

function TAIPostgreSQLDictionary.GetEngine: TAIDBEngine;
begin
  Result := dbPostgreSQL;
end;

function TAIPostgreSQLDictionary.LoadTables: Boolean;
var
  Query: TZQuery;
  Table: TAIDBTableInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT table_schema, table_name, table_type ' +
      'FROM information_schema.tables ' +
      'WHERE table_schema NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR table_schema = :schema) ' +
      'ORDER BY table_schema, table_name;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      Table := DataDictionary.Tables.Add;
      Table.SchemaName := Query.FieldByName('table_schema').AsString;
      Table.TableName := Query.FieldByName('table_name').AsString;
      Table.TableType := Query.FieldByName('table_type').AsString;
      Table.Description := '';
      Table.RowCount := 0;

      DoTableFound(Table.TableName);
      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL tables: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadColumns: Boolean;
var
  Query: TZQuery;
  Table: TAIDBTableInfo;
  Col: TAIDBColumnInfo;
  TName: string;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT table_schema, table_name, column_name, ordinal_position, ' +
      '       data_type, udt_name, character_maximum_length, ' +
      '       numeric_precision, numeric_scale, is_nullable, column_default ' +
      'FROM information_schema.columns ' +
      'WHERE table_schema NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR table_schema = :schema) ' +
      'ORDER BY table_schema, table_name, ordinal_position;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      TName := Query.FieldByName('table_name').AsString;
      Table := DataDictionary.Tables.FindTable(TName);
      if Assigned(Table) then
      begin
        Col := Table.Columns.Add;
        Col.TableName := TName;
        Col.ColumnName := Query.FieldByName('column_name').AsString;
        Col.DataType := Query.FieldByName('data_type').AsString;
        Col.NativeDataType := Query.FieldByName('udt_name').AsString;
        Col.Size := Query.FieldByName('character_maximum_length').AsInteger;
        Col.Precision := Query.FieldByName('numeric_precision').AsInteger;
        Col.Scale := Query.FieldByName('numeric_scale').AsInteger;
        Col.Nullable := SameText(Query.FieldByName('is_nullable').AsString, 'YES');
        Col.DefaultValue := Query.FieldByName('column_default').AsString;
        Col.IsPrimaryKey := False;
        Col.IsForeignKey := False;
        Col.IsUnique := False;
        Col.OrdinalPosition := Query.FieldByName('ordinal_position').AsInteger;
        Col.Description := '';

        DoColumnFound(TName, Col.ColumnName);
      end;
      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL columns: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadPrimaryKeys: Boolean;
var
  Query: TZQuery;
  Table: TAIDBTableInfo;
  Col: TAIDBColumnInfo;
  TName, CName: string;
  i: Integer;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT tc.table_schema, tc.table_name, kcu.column_name, tc.constraint_name ' +
      'FROM information_schema.table_constraints tc ' +
      'JOIN information_schema.key_column_usage kcu ' +
      '  ON tc.constraint_name = kcu.constraint_name ' +
      ' AND tc.table_schema = kcu.table_schema ' +
      'WHERE tc.constraint_type = ''PRIMARY KEY'' ' +
      '  AND (:schema = '''' OR tc.table_schema = :schema) ' +
      'ORDER BY tc.table_schema, tc.table_name, kcu.ordinal_position;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      TName := Query.FieldByName('table_name').AsString;
      CName := Query.FieldByName('column_name').AsString;
      Table := DataDictionary.Tables.FindTable(TName);
      if Assigned(Table) then
      begin
        for i := 0 to Table.Columns.Count - 1 do
        begin
          Col := Table.Columns[i];
          if SameText(Col.ColumnName, CName) then
          begin
            Col.IsPrimaryKey := True;
            Col.IsUnique := True;
            Break;
          end;
        end;
      end;
      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL primary keys: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadForeignKeys: Boolean;
var
  Query: TZQuery;
  FK: TAIDBForeignKeyInfo;
  Table: TAIDBTableInfo;
  Col: TAIDBColumnInfo;
  i: Integer;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT tc.constraint_name, tc.table_schema, tc.table_name, kcu.column_name, ' +
      '       ccu.table_schema AS foreign_table_schema, ccu.table_name AS foreign_table_name, ' +
      '       ccu.column_name AS foreign_column_name, rc.update_rule, rc.delete_rule ' +
      'FROM information_schema.table_constraints tc ' +
      'JOIN information_schema.key_column_usage kcu ' +
      '  ON tc.constraint_name = kcu.constraint_name ' +
      ' AND tc.table_schema = kcu.table_schema ' +
      'JOIN information_schema.constraint_column_usage ccu ' +
      '  ON ccu.constraint_name = tc.constraint_name ' +
      ' AND ccu.table_schema = tc.table_schema ' +
      'JOIN information_schema.referential_constraints rc ' +
      '  ON rc.constraint_name = tc.constraint_name ' +
      ' AND rc.constraint_schema = tc.table_schema ' +
      'WHERE tc.constraint_type = ''FOREIGN KEY'' ' +
      '  AND (:schema = '''' OR tc.table_schema = :schema) ' +
      'ORDER BY tc.table_schema, tc.table_name;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      FK := DataDictionary.ForeignKeys.Add;
      FK.ConstraintName := Query.FieldByName('constraint_name').AsString;
      FK.TableName := Query.FieldByName('table_name').AsString;
      FK.ColumnName := Query.FieldByName('column_name').AsString;
      FK.RefTableName := Query.FieldByName('foreign_table_name').AsString;
      FK.RefColumnName := Query.FieldByName('foreign_column_name').AsString;
      FK.UpdateRule := Query.FieldByName('update_rule').AsString;
      FK.DeleteRule := Query.FieldByName('delete_rule').AsString;

      // Mark the corresponding column as foreign key
      Table := DataDictionary.Tables.FindTable(FK.TableName);
      if Assigned(Table) then
      begin
        for i := 0 to Table.Columns.Count - 1 do
        begin
          Col := Table.Columns[i];
          if SameText(Col.ColumnName, FK.ColumnName) then
          begin
            Col.IsForeignKey := True;
            Break;
          end;
        end;
      end;

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL foreign keys: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadIndexes: Boolean;
var
  Query: TZQuery;
  Idx: TAIDBIndexInfo;
  Def: string;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT schemaname, tablename, indexname, indexdef ' +
      'FROM pg_indexes ' +
      'WHERE schemaname NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR schemaname = :schema) ' +
      'ORDER BY schemaname, tablename, indexname;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      Idx := DataDictionary.Indexes.Add;
      Idx.IndexName := Query.FieldByName('indexname').AsString;
      Idx.TableName := Query.FieldByName('tablename').AsString;
      Idx.ColumnName := ''; // We will keep it empty or populate if simple
      Idx.IndexType := 'INDEX';

      Def := Query.FieldByName('indexdef').AsString;
      Idx.IsUnique := Pos('UNIQUE', UpperCase(Def)) > 0;
      Idx.IsPrimary := Pos('PRIMARY KEY', UpperCase(Def)) > 0;

      // Simple extraction of column name inside parentheses e.g. "CREATE INDEX ... ON ... USING btree (col_name)"
      if Pos('(', Def) > 0 then
      begin
        Idx.ColumnName := Copy(Def, Pos('(', Def) + 1, Pos(')', Def) - Pos('(', Def) - 1);
      end;

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL indexes: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadViews: Boolean;
var
  Query: TZQuery;
  V: TAIDBViewInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT table_schema, table_name, view_definition ' +
      'FROM information_schema.views ' +
      'WHERE table_schema NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR table_schema = :schema) ' +
      'ORDER BY table_schema, table_name;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      V := DataDictionary.Views.Add;
      V.SchemaName := Query.FieldByName('table_schema').AsString;
      V.ViewName := Query.FieldByName('table_name').AsString;
      V.SQLDefinition := Query.FieldByName('view_definition').AsString;
      V.Description := '';

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL views: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadTriggers: Boolean;
var
  Query: TZQuery;
  Trig: TAIDBTriggerInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT trigger_schema, trigger_name, event_object_table, ' +
      '       event_manipulation, action_timing, action_statement ' +
      'FROM information_schema.triggers ' +
      'WHERE trigger_schema NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR trigger_schema = :schema) ' +
      'ORDER BY trigger_schema, event_object_table, trigger_name;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      Trig := DataDictionary.Triggers.Add;
      Trig.TriggerName := Query.FieldByName('trigger_name').AsString;
      Trig.TableName := Query.FieldByName('event_object_table').AsString;
      Trig.EventName := Query.FieldByName('event_manipulation').AsString;
      Trig.Timing := Query.FieldByName('action_timing').AsString;
      Trig.SQLDefinition := Query.FieldByName('action_statement').AsString;
      Trig.Enabled := True;

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL triggers: ' + E.Message);
  end;
  Query.Free;
end;

// Empty helper or metadata retrieval for sequence
function TAIPostgreSQLDictionary.LoadSequences: Boolean;
var
  Query: TZQuery;
  Seq: TAIDBSequenceInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT sequence_schema, sequence_name, increment ' +
      'FROM information_schema.sequences ' +
      'WHERE sequence_schema NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR sequence_schema = :schema) ' +
      'ORDER BY sequence_schema, sequence_name;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      Seq := DataDictionary.Sequences.Add;
      Seq.SchemaName := Query.FieldByName('sequence_schema').AsString;
      Seq.SequenceName := Query.FieldByName('sequence_name').AsString;
      Seq.IncrementBy := StrToIntDef(Query.FieldByName('increment').AsString, 1);
      Seq.CurrentValue := '';

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL sequences: ' + E.Message);
  end;
  Query.Free;
end;

function TAIPostgreSQLDictionary.LoadRoutines: Boolean;
var
  Query: TZQuery;
  Rt: TAIDBRoutineInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT routine_schema, routine_name, routine_type, data_type ' +
      'FROM information_schema.routines ' +
      'WHERE routine_schema NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:schema = '''' OR routine_schema = :schema) ' +
      'ORDER BY routine_schema, routine_name;';
    Query.ParamByName('schema').AsString := SchemaName;
    Query.Open;

    while not Query.EOF do
    begin
      Rt := DataDictionary.Routines.Add;
      Rt.SchemaName := Query.FieldByName('routine_schema').AsString;
      Rt.RoutineName := Query.FieldByName('routine_name').AsString;
      Rt.RoutineType := Query.FieldByName('routine_type').AsString;
      Rt.ReturnType := Query.FieldByName('data_type').AsString;
      Rt.SQLDefinition := ''; // Can be loaded from pg_proc if needed

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading PostgreSQL routines: ' + E.Message);
  end;
  Query.Free;
end;

initialization
  {$I aidb_postgresql_dictionary_icon.lrs}

end.
