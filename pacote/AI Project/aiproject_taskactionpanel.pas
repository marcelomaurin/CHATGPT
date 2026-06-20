unit aiproject_taskactionpanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls;

type
  TAITaskActionPanel = class(TPanel)
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAITaskActionPanel]);
end;

end.
