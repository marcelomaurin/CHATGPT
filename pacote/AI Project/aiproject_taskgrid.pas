unit aiproject_taskgrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Grids;

type
  TAIProjectTaskGrid = class(TStringGrid)
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectTaskGrid]);
end;

end.
