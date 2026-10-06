{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_marlin;

{$warn 5023 off : no warning about unused units}
interface

uses
  aigcodeparser, aimarlinsimulator, aimarlinserialdevice, aivirtualserialpair, 
  aimarlin_register, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aimarlin_register', @aimarlin_register.Register);
end;

initialization
  RegisterPackage('openai_marlin', @Register);
end.
