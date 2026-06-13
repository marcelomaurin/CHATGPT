program human_pose_detector_demo;

{$mode objfpc}{$H+}

{$IFNDEF CPU64}
  {$ERROR human_pose_detector_demo supports only 64-bit targets.}
{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmPoseDemo, frmPoseDemo);
  Application.Run;
end.
