program AISerial_Test;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, main;

// {$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
