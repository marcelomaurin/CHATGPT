{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_agent;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagent, aiagentsafety, aiagent_executors, aiwizardconfig, 
  frm_aiwizardconfig, aipipeline, aiagent_flowevents, aiagent_memorymap,
  aiagent_core, aiagent_classifier, aiagent_decision, aiagent_actionbuilder,
  aiagent_executor, aiagent_actions, aiagent_orchestrator, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiagent', @aiagent.Register);
  RegisterUnit('aiagentsafety', @aiagentsafety.Register);
  RegisterUnit('aiwizardconfig', @aiwizardconfig.Register);
  RegisterUnit('aipipeline', @aipipeline.Register);
  RegisterUnit('aiagent_memorymap', @aiagent_memorymap.Register);
  RegisterUnit('aiagent_orchestrator', @aiagent_orchestrator.Register);
end;

initialization
  RegisterPackage('openai_agent', @Register);
end.
