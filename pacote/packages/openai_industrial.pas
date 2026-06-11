{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_industrial;

{$warn 5023 off : no warning about unused units}
interface

uses
  aimodbus, aimqtt, aiposprinter, aiindustrial, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aimodbus', @aimodbus.Register);
  RegisterUnit('aimqtt', @aimqtt.Register);
  RegisterUnit('aiposprinter', @aiposprinter.Register);
  RegisterUnit('aiindustrial', @aiindustrial.Register);
end;

initialization
  RegisterPackage('openai_industrial', @Register);
end.
