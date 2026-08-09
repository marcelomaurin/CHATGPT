program trace_viewer_demo;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, main;

begin
  RequireDerivedFormResource := False;
  Application.Initialize;
  Application.CreateForm(TTraceViewerForm, TraceViewerForm);
  Application.Run;
end.
