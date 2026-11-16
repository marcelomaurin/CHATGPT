program neurograph_native;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Forms,
  NeuroGraphCore,
  NeuroGraphEngine,
  unative;

begin
  if RunCLIMode then
    Exit;
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.Title := 'NeuroGraph v8 Native (100% Free Pascal)';
  Application.CreateForm(TfrmNeuroGraphNative, frmNeuroGraphNative);
  Application.Run;
end.
