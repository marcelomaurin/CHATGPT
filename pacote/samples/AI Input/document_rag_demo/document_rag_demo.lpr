program document_rag_demo;

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
  Application.CreateForm(TfrmDocRAGDemo, frmDocRAGDemo);
  Application.Run;
end.
