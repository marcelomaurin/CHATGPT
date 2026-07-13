program framework_graph_explorer;

{$mode objfpc}{$H+}

uses
  SysUtils, Interfaces, Forms, main;

{$R *.res}

function HeadlessRequested: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), '--headless') then Exit(True);
end;

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.ShowMainForm := not HeadlessRequested;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
  if Assigned(frmMain) and frmMain.Headless then
    System.ExitCode := frmMain.HeadlessExitCode;
end.
