{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_a2a;

{$warn 5023 off : no warning about unused units}
interface

uses
  aia2a, aia2aserver, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aia2a', @aia2a.Register);
  RegisterUnit('aia2aserver', @aia2aserver.Register);
end;

initialization
  RegisterPackage('openai_a2a', @Register);
end.
