{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_agent;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagent, aiagent_executors, aiwizardconfig, frm_aiwizardconfig, aipipeline, 
  aiagent_browseractions, aiagentserial, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiagent', @aiagent.Register);
  RegisterUnit('aiwizardconfig', @aiwizardconfig.Register);
  RegisterUnit('aipipeline', @aipipeline.Register);
  RegisterUnit('aiagentserial', @aiagentserial.Register);
end;

initialization
  RegisterPackage('openai_agent', @Register);
end.
