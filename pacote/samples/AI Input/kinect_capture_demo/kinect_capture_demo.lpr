{===============================================================================
  Kinect Capture Demo
  Demonstra captura do stream de video colorido de um sensor Kinect
  usando os componentes TAIKinectSensor e TAIKinectColorStream do
  pacote openai_input.

  Projeto: https://github.com/marcelomaurin/CHATGPT
  Licenca: conforme a licenca do repositorio principal.
===============================================================================}
program kinect_capture_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
