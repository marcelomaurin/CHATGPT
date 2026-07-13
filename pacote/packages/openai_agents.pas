{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_agents;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagents, aiagent, aiagent_executors, aipipeline, aiagent_flowevents, 
  aiagent_memorymap, aiagent_core, aiagent_classifier, aiagent_decision, 
  aiagent_actionbuilder, aiagent_executor, aiagent_actions, 
  aiagent_orchestrator, aiagentserial, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiagents', @aiagents.Register);
  RegisterUnit('aiagent', @aiagent.Register);
  RegisterUnit('aipipeline', @aipipeline.Register);
  RegisterUnit('aiagent_memorymap', @aiagent_memorymap.Register);
  RegisterUnit('aiagent_orchestrator', @aiagent_orchestrator.Register);
  RegisterUnit('aiagentserial', @aiagentserial.Register);
end;

initialization
  RegisterPackage('openai_agents', @Register);
end.
