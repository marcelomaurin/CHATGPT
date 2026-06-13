program human_pose_detector_bridge_test;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Classes, SysUtils, Graphics, aihumanposedetector, aihumanpose_types;

var
  Detector: TAIHumanPoseDetector;
  Bmp: TBitmap;
  DLLPath: string;
begin
  WriteLn('Starting Human Pose Detector Bridge Test...');
  
  // Resolve DLL path (where we just copied it)
  DLLPath := ExpandFileName('../../../runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/mp_pose_bridge.dll');
  {$IFNDEF MSWINDOWS}
  DLLPath := ExpandFileName('../../../runtime/mediapipe/pose/mp_0_10_35/linux-x86_64/libmp_pose_bridge.so');
  {$ENDIF}
  
  WriteLn('Testing with DLL: ', DLLPath);
  if not FileExists(DLLPath) then
  begin
    WriteLn('ERROR: Bridge DLL not found at expected path: ', DLLPath);
    ExitCode := 1;
    Exit;
  end;

  Detector := TAIHumanPoseDetector.Create(nil);
  Bmp := TBitmap.Create;
  try
    Detector.LoadMode := mplmManualPath;
    Detector.BridgeDLLPath := DLLPath;
    
    WriteLn('Initializing detector...');
    if not Detector.Initialize then
    begin
      WriteLn('ERROR: Detector initialization failed. LastError: ', Detector.LastError);
      ExitCode := 1;
      Exit;
    end;
    
    WriteLn('DLL Loaded Successfully.');
    WriteLn('Backend: ' + Detector.BridgeBackend);
    WriteLn('Bridge Version: ' + Detector.BridgeVersionText);
    
    // Create a small 100x100 bitmap for testing
    Bmp.SetSize(100, 100);
    Bmp.Canvas.Brush.Color := clBlue;
    Bmp.Canvas.FillRect(0, 0, 100, 100);
    
    WriteLn('Running DetectBitmap...');
    if not Detector.DetectBitmap(Bmp) then
    begin
      WriteLn('ERROR: DetectBitmap failed. LastError: ' + Detector.LastError);
      ExitCode := 1;
      Exit;
    end;
    
    WriteLn('Pose Count detected: ' + IntToStr(Detector.GetPoseCount));
    if Detector.GetPoseCount <= 0 then
    begin
      WriteLn('ERROR: Pose count should be > 0 in SIM backend.');
      ExitCode := 1;
      Exit;
    end;
    
    WriteLn('Test passed successfully.');
    ExitCode := 0;
  finally
    Bmp.Free;
    Detector.Free;
  end;
end.
