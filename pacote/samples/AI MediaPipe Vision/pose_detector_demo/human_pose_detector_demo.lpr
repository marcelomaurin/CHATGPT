program human_pose_detector_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Dialogs
  {$IFDEF CPU64}
  , main
  {$ENDIF}
  ;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  {$IFDEF CPU64}
  Application.CreateForm(TfrmPoseDemo, frmPoseDemo);
  Application.Run;
  {$ELSE}
  ShowMessage('Esta demonstração está disponível apenas em sistemas de 64-bit (x86_64).');
  {$ENDIF}
end.
