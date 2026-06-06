{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_simulation;

{$warn 5023 off : no warning about unused units}
interface

uses
  aigridcell, aigridworld, aigridbuffer, aisimentity, aientityfactory, 
  aisimulationengine, airuleengine, aitriggerengine, aimovementengine, 
  aievolutionengine, aisimulationstats, aigridrenderer2d, aiscenarioconfig, 
  aiscenariogenerator, aisimulationexporter, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aigridworld', @aigridworld.Register);
  RegisterUnit('aisimentity', @aisimentity.Register);
  RegisterUnit('aientityfactory', @aientityfactory.Register);
  RegisterUnit('aisimulationengine', @aisimulationengine.Register);
  RegisterUnit('airuleengine', @airuleengine.Register);
  RegisterUnit('aitriggerengine', @aitriggerengine.Register);
  RegisterUnit('aimovementengine', @aimovementengine.Register);
  RegisterUnit('aievolutionengine', @aievolutionengine.Register);
  RegisterUnit('aisimulationstats', @aisimulationstats.Register);
  RegisterUnit('aigridrenderer2d', @aigridrenderer2d.Register);
  RegisterUnit('aiscenarioconfig', @aiscenarioconfig.Register);
  RegisterUnit('aiscenariogenerator', @aiscenariogenerator.Register);
  RegisterUnit('aisimulationexporter', @aisimulationexporter.Register);
end;

initialization
  RegisterPackage('openai_simulation', @Register);
end.
