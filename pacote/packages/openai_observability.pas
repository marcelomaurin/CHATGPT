{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_observability;

{$warn 5023 off : no warning about unused units}
interface

uses
  aitrace, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aitrace', @aitrace.Register);
end;

initialization
  RegisterPackage('openai_observability', @Register);
end.
