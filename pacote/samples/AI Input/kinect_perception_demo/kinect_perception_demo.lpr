{===============================================================================
  Kinect Perception Demo
  Demonstra a camada semantica TAIKinectPerception sobre o Kinect v1 (SDK 1.8).
  Exibe presenca, zona de interacao, distancia, posicao e classificacao de gestos,
  gerando eventos semanticos e payload JSON para o TAIConversationOrchestrator.

  MaurinSoft - Projeto CHATGPT
===============================================================================}
program kinect_perception_demo;

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
