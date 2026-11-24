program sip_server_demo;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Interfaces, Forms, sip_demo_main;
var Window: TSIPDemoForm;
begin
  Application.Initialize;
  Window := TSIPDemoForm.CreateDemo(Application, True);
  Window.Show; Application.Run;
end.
