{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_drone;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidronefq777, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidronefq777', @aidronefq777.Register);
end;

initialization
  RegisterPackage('openai_drone', @Register);
end.
