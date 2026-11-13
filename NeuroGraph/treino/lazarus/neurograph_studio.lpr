program neurograph_studio;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, ustudio;

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.Title := 'NeuroGraph Studio';
  Application.CreateForm(TfrmStudio, frmStudio);
  Application.Run;
end.
