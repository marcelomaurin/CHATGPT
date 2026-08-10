program CHATGPTInstaller;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, uinstaller;

{$R *.res}

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.Title := 'CHATGPT Lazarus Suite Installer';
  Application.CreateForm(TfrmInstaller, frmInstaller);
  Application.Run;
end.
