unit aidb_oracle_dictionary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, aidb_types, aidb_dictionary_base, LResources;

type
  TAIOracleDictionary = class(TAICustomDBDictionary)
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

function TAIOracleDictionary.GetEngine: TAIDBEngine;
begin
  Result := dbOracle;
end;

function TAIOracleDictionary.LoadTables: Boolean;
begin
  // TODO: Implement Oracle user/all metadata table queries
  Result := True;
end;

function TAIOracleDictionary.LoadColumns: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadPrimaryKeys: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadForeignKeys: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadIndexes: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadViews: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadTriggers: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadSequences: Boolean;
begin
  Result := True;
end;

function TAIOracleDictionary.LoadRoutines: Boolean;
begin
  Result := True;
end;

initialization
  {$I aidb_oracle_dictionary_icon.lrs}

end.
