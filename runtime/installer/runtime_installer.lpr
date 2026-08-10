program CHATGPTRuntimeInstaller;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, uruntimeinstaller;

{$R *.res}

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.Title := 'CHATGPT-AI Runtime Installer';
  Application.CreateForm(TfrmRuntimeInstaller, frmRuntimeInstaller);
  Application.Run;
end.
