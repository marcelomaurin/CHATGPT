{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_drone;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidronebase, aidronefq777, aidronecx10w, aidronemavlink, aidronetello, aidroneespdrone, aidroneardrone, aidronecdp, openai_drone_paletteicons, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidronefq777', @aidronefq777.Register);
  RegisterUnit('aidronecx10w', @aidronecx10w.Register);
  RegisterUnit('aidronemavlink', @aidronemavlink.Register);
  RegisterUnit('aidronetello', @aidronetello.Register);
  RegisterUnit('aidroneespdrone', @aidroneespdrone.Register);
  RegisterUnit('aidroneardrone', @aidroneardrone.Register);
  RegisterUnit('aidronecdp', @aidronecdp.Register);
end;

initialization
  RegisterPackage('openai_drone', @Register);
end.
