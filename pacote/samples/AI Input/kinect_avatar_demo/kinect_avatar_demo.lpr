program kinect_avatar_demo;
{$mode objfpc}{$H+}
uses Interfaces, Forms, demo_main;
var Main:TDemoForm;
begin
  Application.Initialize;
  Application.CreateForm(TDemoForm,Main);
  Application.Run;
end.
