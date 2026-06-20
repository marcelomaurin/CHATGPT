unit aiproject_agentmanager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms;

type
  TAIAgentManagerFrame = class(TFrame)
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIAgentManagerFrame]);
end;

end.
