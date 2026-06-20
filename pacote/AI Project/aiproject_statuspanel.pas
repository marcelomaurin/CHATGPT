unit aiproject_statuspanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls;

type
  TAIProjectStatusPanel = class(TPanel)
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectStatusPanel]);
end;

end.
