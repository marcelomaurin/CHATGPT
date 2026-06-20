{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_dbase;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidbase, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidbase', @aidbase.Register);
end;

initialization
  RegisterPackage('openai_dbase', @Register);
end.
