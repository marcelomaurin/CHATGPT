program webrtc_datachannel_demo;
{$mode objfpc}{$H+}
uses Interfaces, Forms, main;
begin
  RequireDerivedFormResource:=True; Application.Initialize; Application.CreateForm(TMainForm, MainForm); Application.Run;
end.
