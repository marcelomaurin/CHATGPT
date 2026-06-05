{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_graphic;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiscene2d3d, aitrainingenvironment, aiphysicssimulator, aisensorvirtual, 
  airewardfunction, aimodel3d, ai3dmodelviewer, aiskeletonrig, 
  aiavatarcontroller, aiposelibrary, aianimationsequence, aitripo3dclient, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiscene2d3d', @aiscene2d3d.Register);
  RegisterUnit('aitrainingenvironment', @aitrainingenvironment.Register);
  RegisterUnit('aiphysicssimulator', @aiphysicssimulator.Register);
  RegisterUnit('aisensorvirtual', @aisensorvirtual.Register);
  RegisterUnit('airewardfunction', @airewardfunction.Register);
  RegisterUnit('aimodel3d', @aimodel3d.Register);
  RegisterUnit('ai3dmodelviewer', @ai3dmodelviewer.Register);
  RegisterUnit('aiskeletonrig', @aiskeletonrig.Register);
  RegisterUnit('aiavatarcontroller', @aiavatarcontroller.Register);
  RegisterUnit('aiposelibrary', @aiposelibrary.Register);
  RegisterUnit('aianimationsequence', @aianimationsequence.Register);
  RegisterUnit('aitripo3dclient', @aitripo3dclient.Register);
end;

initialization
  RegisterPackage('openai_graphic', @Register);
end.
