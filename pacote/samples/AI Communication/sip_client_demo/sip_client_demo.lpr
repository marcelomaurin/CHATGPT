program sip_client_demo;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Interfaces, Forms, sip_demo_main;
var Window: TSIPDemoForm;
begin
  Application.Initialize;
  Window := TSIPDemoForm.CreateDemo(Application, False);
  Window.Show; Application.Run;
end.
