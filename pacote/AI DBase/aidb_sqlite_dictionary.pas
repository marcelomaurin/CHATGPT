unit aidb_sqlite_dictionary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZDataset, aidb_types, aidb_dictionary_base;

type
  TAISQLiteDictionary = class(TAICustomDBDictionary)
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

function TAISQLiteDictionary.GetEngine: TAIDBEngine;
begin
  Result := dbSQLite;
end;

function TAISQLiteDictionary.LoadTables: Boolean;
var
  Query: TZQuery;
  Table: TAIDBTableInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT name, type ' +
      'FROM sqlite_master ' +
      'WHERE type = ''table'' ' +
      '  AND name NOT LIKE ''sqlite_%'' ' +
      'ORDER BY name;';
    Query.Open;

    while not Query.EOF do
    begin
      Table := DataDictionary.Tables.Add;
      Table.SchemaName := '';
      Table.TableName := Query.FieldByName('name').AsString;
      Table.TableType := 'BASE TABLE';
      Table.Description := '';
      Table.RowCount := 0;

      DoTableFound(Table.TableName);
      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading SQLite tables: ' + E.Message);
  end;
  Query.Free;
end;

function TAISQLiteDictionary.LoadColumns: Boolean;
var
  Query: TZQuery;
  Table: TAIDBTableInfo;
  Col: TAIDBColumnInfo;
  i: Integer;
begin
  Result := False;
  Query := CreateQuery;
  try
    for i := 0 to DataDictionary.Tables.Count - 1 do
    begin
      Table := DataDictionary.Tables[i];
      // Secure the table name with double quotes to prevent syntax errors
      Query.SQL.Text := 'PRAGMA table_info("' + Table.TableName + '");';
      Query.Open;

      while not Query.EOF do
      begin
        Col := Table.Columns.Add;
        Col.TableName := Table.TableName;
        Col.ColumnName := Query.FieldByName('name').AsString;
        Col.DataType := Query.FieldByName('type').AsString;
        Col.NativeDataType := Query.FieldByName('type').AsString;
        Col.Size := 0;
        Col.Precision := 0;
        Col.Scale := 0;
        Col.Nullable := Query.FieldByName('notnull').AsInteger = 0;
        Col.DefaultValue := Query.FieldByName('dflt_value').AsString;
        Col.IsPrimaryKey := Query.FieldByName('pk').AsInteger > 0;
        Col.IsForeignKey := False;
        Col.IsUnique := Col.IsPrimaryKey;
        Col.OrdinalPosition := Query.FieldByName('cid').AsInteger;
        Col.Description := '';

        DoColumnFound(Table.TableName, Col.ColumnName);
        Query.Next;
      end;
      Query.Close;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading SQLite columns: ' + E.Message);
  end;
  Query.Free;
end;

function TAISQLiteDictionary.LoadPrimaryKeys: Boolean;
begin
  // Handled inside LoadColumns on SQLite because PRAGMA table_info returns pk info.
  Result := True;
end;

function TAISQLiteDictionary.LoadForeignKeys: Boolean;
var
  Query: TZQuery;
  Table: TAIDBTableInfo;
  Col: TAIDBColumnInfo;
  FK: TAIDBForeignKeyInfo;
  i, j: Integer;
begin
  Result := False;
  Query := CreateQuery;
  try
    for i := 0 to DataDictionary.Tables.Count - 1 do
    begin
      Table := DataDictionary.Tables[i];
      Query.SQL.Text := 'PRAGMA foreign_key_list("' + Table.TableName + '");';
      Query.Open;

      while not Query.EOF do
      begin
        FK := DataDictionary.ForeignKeys.Add;
        FK.ConstraintName := 'fk_' + Table.TableName + '_' + Query.FieldByName('from').AsString;
        FK.TableName := Table.TableName;
        FK.ColumnName := Query.FieldByName('from').AsString;
        FK.RefTableName := Query.FieldByName('table').AsString;
        FK.RefColumnName := Query.FieldByName('to').AsString;
        FK.UpdateRule := Query.FieldByName('on_update').AsString;
        FK.DeleteRule := Query.FieldByName('on_delete').AsString;

        // Mark local column
        for j := 0 to Table.Columns.Count - 1 do
        begin
          Col := Table.Columns[j];
          if SameText(Col.ColumnName, FK.ColumnName) then
          begin
            Col.IsForeignKey := True;
            Break;
          end;
        end;

        Query.Next;
      end;
      Query.Close;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading SQLite foreign keys: ' + E.Message);
  end;
  Query.Free;
end;

function TAISQLiteDictionary.LoadIndexes: Boolean;
var
  Query, InfoQuery: TZQuery;
  Table: TAIDBTableInfo;
  Idx: TAIDBIndexInfo;
  i: Integer;
  IdxName: string;
begin
  Result := False;
  Query := CreateQuery;
  InfoQuery := CreateQuery;
  try
    for i := 0 to DataDictionary.Tables.Count - 1 do
    begin
      Table := DataDictionary.Tables[i];
      Query.SQL.Text := 'PRAGMA index_list("' + Table.TableName + '");';
      Query.Open;

      while not Query.EOF do
      begin
        IdxName := Query.FieldByName('name').AsString;

        Idx := DataDictionary.Indexes.Add;
        Idx.IndexName := IdxName;
        Idx.TableName := Table.TableName;
        Idx.IsUnique := Query.FieldByName('unique').AsInteger > 0;
        Idx.IsPrimary := SameText(Query.FieldByName('origin').AsString, 'pk');
        Idx.IndexType := 'INDEX';
        Idx.ColumnName := '';

        // Query details of this index to get column names
        InfoQuery.SQL.Text := 'PRAGMA index_info("' + IdxName + '");';
        InfoQuery.Open;
        if not InfoQuery.EOF then
        begin
          Idx.ColumnName := InfoQuery.FieldByName('name').AsString;
        end;
        InfoQuery.Close;

        Query.Next;
      end;
      Query.Close;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading SQLite indexes: ' + E.Message);
  end;
  Query.Free;
  InfoQuery.Free;
end;

function TAISQLiteDictionary.LoadViews: Boolean;
var
  Query: TZQuery;
  V: TAIDBViewInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT name, sql ' +
      'FROM sqlite_master ' +
      'WHERE type = ''view'' ' +
      '  AND name NOT LIKE ''sqlite_%'' ' +
      'ORDER BY name;';
    Query.Open;

    while not Query.EOF do
    begin
      V := DataDictionary.Views.Add;
      V.SchemaName := '';
      V.ViewName := Query.FieldByName('name').AsString;
      V.SQLDefinition := Query.FieldByName('sql').AsString;
      V.Description := '';

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading SQLite views: ' + E.Message);
  end;
  Query.Free;
end;

function TAISQLiteDictionary.LoadTriggers: Boolean;
var
  Query: TZQuery;
  Trig: TAIDBTriggerInfo;
begin
  Result := False;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT name, tbl_name, sql ' +
      'FROM sqlite_master ' +
      'WHERE type = ''trigger'' ' +
      'ORDER BY tbl_name, name;';
    Query.Open;

    while not Query.EOF do
    begin
      Trig := DataDictionary.Triggers.Add;
      Trig.TriggerName := Query.FieldByName('name').AsString;
      Trig.TableName := Query.FieldByName('tbl_name').AsString;
      Trig.EventName := ''; // SQLite sqlite_master doesn't separate events out-of-the-box simply
      Trig.Timing := '';
      Trig.SQLDefinition := Query.FieldByName('sql').AsString;
      Trig.Enabled := True;

      Query.Next;
    end;
    Result := True;
  except
    on E: Exception do
      SetError('Error loading SQLite triggers: ' + E.Message);
  end;
  Query.Free;
end;

function TAISQLiteDictionary.LoadSequences: Boolean;
begin
  // SQLite doesn't have standard sequences like Postgres, auto-increment fields are handled by sqlite_sequence implicitly.
  Result := True;
end;

function TAISQLiteDictionary.LoadRoutines: Boolean;
begin
  // SQLite does not support stored procedures or routines.
  Result := True;
end;

end.
