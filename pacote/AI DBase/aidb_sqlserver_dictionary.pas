unit aidb_sqlserver_dictionary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, aidb_types, aidb_dictionary_base;

type
  TAISQLServerDictionary = class(TAICustomDBDictionary)
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

function TAISQLServerDictionary.GetEngine: TAIDBEngine;
begin
  Result := dbSQLServer;
end;

function TAISQLServerDictionary.LoadTables: Boolean;
begin
  // TODO: Implement SQL Server catalog queries
  Result := True;
end;

function TAISQLServerDictionary.LoadColumns: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadPrimaryKeys: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadForeignKeys: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadIndexes: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadViews: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadTriggers: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadSequences: Boolean;
begin
  Result := True;
end;

function TAISQLServerDictionary.LoadRoutines: Boolean;
begin
  Result := True;
end;

end.
