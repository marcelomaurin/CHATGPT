{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_agent;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagent, aiwizardconfig, frm_aiwizardconfig, aiagentserial, 
  aiagent_flowevents, aiagent_memorymap, aiagent_deterministicmemory, 
  aiagent_capabilityrouter, aiagent_supervisor, aiagent_core, 
  aiagent_classifier, aiagent_decision, aiagent_actionbuilder, 
  aiagent_actions, aiagent_sourceactions, aiagent_testaction, aitools, 
  aiagentgraph, aiguardrails, aiagent_executor, aiagent_orchestrator, 
  aiagentsafety, aidevagents, aiserviceagents, aicommonserviceagents, 
  airosagent, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiagent', @aiagent.Register);
  RegisterUnit('aiwizardconfig', @aiwizardconfig.Register);
  RegisterUnit('aiagentserial', @aiagentserial.Register);
  RegisterUnit('aiagent_memorymap', @aiagent_memorymap.Register);
  RegisterUnit('aiagent_sourceactions', @aiagent_sourceactions.Register);
  RegisterUnit('aiagent_testaction', @aiagent_testaction.Register);
  RegisterUnit('aitools', @aitools.Register);
  RegisterUnit('aiagentgraph', @aiagentgraph.Register);
  RegisterUnit('aiguardrails', @aiguardrails.Register);
  RegisterUnit('aiagent_orchestrator', @aiagent_orchestrator.Register);
  RegisterUnit('aiagentsafety', @aiagentsafety.Register);
  RegisterUnit('aidevagents', @aidevagents.Register);
  RegisterUnit('aiserviceagents', @aiserviceagents.Register);
  RegisterUnit('aicommonserviceagents', @aicommonserviceagents.Register);
  RegisterUnit('airosagent', @airosagent.Register);
end;

initialization
  RegisterPackage('openai_agent', @Register);
end.
