{===============================================================================
  Kinect Skeleton Demo
  Demonstra rastreamento de esqueleto do Kinect v1 usando o SDK 1.8.

  Projeto: https://github.com/marcelomaurin/CHATGPT
  Licenca: conforme a licenca do repositorio principal.
===============================================================================}
program kinect_skeleton_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Forms, main;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.