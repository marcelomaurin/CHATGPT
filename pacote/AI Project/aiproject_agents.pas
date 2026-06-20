unit aiproject_agents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject;

type
  TAIProjectAgents = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectAgents]);
end;

end.
