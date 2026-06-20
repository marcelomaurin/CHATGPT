unit aiproject_reports;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject;

type
  TAIProjectReports = class(TComponent)
  private
    FProject: TAIProject;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectReports]);
end;

end.
