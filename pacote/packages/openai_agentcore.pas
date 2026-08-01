{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_agentcore;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagent_flowevents, aiagent_memorymap, aiagent_core, aiagent_classifier, 
  aiagent_decision, aiagent_actionbuilder, aiagent_actions, aiagent_executor, 
  aiagent_orchestrator, aiagentsafety, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiagent_memorymap', @aiagent_memorymap.Register);
  RegisterUnit('aiagent_orchestrator', @aiagent_orchestrator.Register);
  RegisterUnit('aiagentsafety', @aiagentsafety.Register);
end;

initialization
  RegisterPackage('openai_agentcore', @Register);
end.
