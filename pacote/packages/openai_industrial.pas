{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_industrial;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiarduinomodbuspinmap, aimodbus, aimqtt, aiindustrial, aiarm_robot, 
  aimodbuscommandmap, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiarduinomodbuspinmap', @aiarduinomodbuspinmap.Register);
  RegisterUnit('aimodbus', @aimodbus.Register);
  RegisterUnit('aimqtt', @aimqtt.Register);
  RegisterUnit('aiindustrial', @aiindustrial.Register);
  RegisterUnit('aiarm_robot', @aiarm_robot.Register);
  RegisterUnit('aimodbuscommandmap', @aimodbuscommandmap.Register);
end;

initialization
  RegisterPackage('openai_industrial', @Register);
end.
