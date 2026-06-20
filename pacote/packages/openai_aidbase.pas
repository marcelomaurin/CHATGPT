{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_aidbase;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidb_types, aidb_dictionary_exporter, aidb_dictionary_base, 
  aidb_postgresql_dictionary, aidb_sqlite_dictionary, aidb_mysql_dictionary, 
  aidb_firebird_dictionary, aidb_sqlserver_dictionary, aidb_oracle_dictionary, 
  aidb_register, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidb_register', @aidb_register.Register);
end;

initialization
  RegisterPackage('openai_aidbase', @Register);
end.
