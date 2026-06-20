unit aiproject_dependencies;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject;

type
  TAIProjectDependencies = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectDependencies]);
end;

end.
