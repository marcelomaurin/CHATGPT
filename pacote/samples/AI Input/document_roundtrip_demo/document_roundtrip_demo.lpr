program document_roundtrip_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, Forms, main;

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmRoundtripDemo, frmRoundtripDemo);
  Application.Run;
end.
