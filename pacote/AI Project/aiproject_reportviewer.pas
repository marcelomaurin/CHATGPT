unit aiproject_reportviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms;

type
  TAIProjectReportViewer = class(TFrame)
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectReportViewer]);
end;

end.
