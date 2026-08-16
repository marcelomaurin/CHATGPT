unit aiagent_sourceactions_register;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, LResources, aiagent_sourceactions;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAISourceReadAction,
    TAISourceReplaceAction, TAISourceRollbackAction, TAIProjectBuildAction]);
end;

initialization
  {$I aiagent_sourceactions_icon.lrs}

end.
