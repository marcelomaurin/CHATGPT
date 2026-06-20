unit aiproject_storage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject;

type
  TAIProjectStorage = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectStorage]);
end;

end.
