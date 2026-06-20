{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_agent;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagent, aiagentsafety, aiagent_executors, aiproject, aiwizardconfig, 
  frm_aiwizardconfig, aipipeline, aiproject_components, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiagent', @aiagent.Register);
  RegisterUnit('aiagentsafety', @aiagentsafety.Register);
  RegisterUnit('aiproject', @aiproject.Register);
  RegisterUnit('aiwizardconfig', @aiwizardconfig.Register);
  RegisterUnit('aipipeline', @aipipeline.Register);
  RegisterUnit('aiproject_components', @aiproject_components.Register);
end;

initialization
  RegisterPackage('openai_agent', @Register);
end.
