unit aidb_register;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LResources,
  aidb_postgresql_dictionary,
  aidb_mysql_dictionary,
  aidb_sqlite_dictionary,
  aidb_firebird_dictionary,
  aidb_sqlserver_dictionary,
  aidb_oracle_dictionary;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI DBase', [
    TAIPostgreSQLDictionary,
    TAIMySQLDictionary,
    TAISQLiteDictionary,
    TAIFirebirdDictionary,
    TAISQLServerDictionary,
    TAIOracleDictionary
  ]);
end;

end.
