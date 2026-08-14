program action_builder_recovery_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main;

{$R *.res}

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmActionBuilderRecoveryTest, frmActionBuilderRecoveryTest);
  Application.Run;
end.
