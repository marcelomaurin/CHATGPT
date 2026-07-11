program hardware_system_manager_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, Forms, main;

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfrmHardwareSystemManagerDemo, frmHardwareSystemManagerDemo);
  Application.Run;
end.
