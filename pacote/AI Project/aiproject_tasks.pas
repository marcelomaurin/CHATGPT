unit aiproject_tasks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject;

type
  TAIProjectTasks = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectTasks]);
end;

end.
