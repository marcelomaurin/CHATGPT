{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_project;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiproject, aiproject_llmconfig, aiproject_storage, aiproject_description, 
  aiproject_documents, aiproject_tasks, aiproject_specification, 
  aiproject_dependencies, aiproject_agents, aiproject_actions, 
  aiproject_reports, aiproject_revisions, aiproject_taskgrid, aiproject_gantt, 
  aiproject_timeline, aiproject_riskmatrix, aiproject_statuspanel, 
  aiproject_agentmanager, aiproject_taskactionpanel, aiproject_reportviewer, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiproject', @aiproject.Register);
  RegisterUnit('aiproject_llmconfig', @aiproject_llmconfig.Register);
  RegisterUnit('aiproject_storage', @aiproject_storage.Register);
  RegisterUnit('aiproject_description', @aiproject_description.Register);
  RegisterUnit('aiproject_documents', @aiproject_documents.Register);
  RegisterUnit('aiproject_tasks', @aiproject_tasks.Register);
  RegisterUnit('aiproject_specification', @aiproject_specification.Register);
  RegisterUnit('aiproject_dependencies', @aiproject_dependencies.Register);
  RegisterUnit('aiproject_agents', @aiproject_agents.Register);
  RegisterUnit('aiproject_actions', @aiproject_actions.Register);
  RegisterUnit('aiproject_reports', @aiproject_reports.Register);
  RegisterUnit('aiproject_revisions', @aiproject_revisions.Register);
  RegisterUnit('aiproject_taskgrid', @aiproject_taskgrid.Register);
  RegisterUnit('aiproject_gantt', @aiproject_gantt.Register);
  RegisterUnit('aiproject_timeline', @aiproject_timeline.Register);
  RegisterUnit('aiproject_riskmatrix', @aiproject_riskmatrix.Register);
  RegisterUnit('aiproject_statuspanel', @aiproject_statuspanel.Register);
  RegisterUnit('aiproject_agentmanager', @aiproject_agentmanager.Register);
  RegisterUnit('aiproject_taskactionpanel', @aiproject_taskactionpanel.Register
    );
  RegisterUnit('aiproject_reportviewer', @aiproject_reportviewer.Register);
end;

initialization
  RegisterPackage('openai_project', @Register);
end.
