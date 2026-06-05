program test_aicameracapture;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, aicameracapture, aibase;

type
  TTestRunner = class
  public
    procedure LogCallback(Sender: TObject; Level: TAILogLevel; const Message: string);
  end;

procedure TTestRunner.LogCallback(Sender: TObject; Level: TAILogLevel; const Message: string);
begin
  WriteLn('LOG: ', Message);
end;

var
  Runner: TTestRunner;
  Cam: TAICameraCapture;
  List: TStringList;
  I: Integer;
  EnvTest: string;
  HasCameraTest: Boolean;
  SelfTestOk: Boolean;

begin
  WriteLn('Starting test_aicameracapture...');
  
  Runner := TTestRunner.Create;
  Cam := TAICameraCapture.Create(nil);
  try
    Cam.OnLog := @Runner.LogCallback;

    // 1. Verify default property values
    WriteLn('Checking default properties...');
    if Cam.CameraIndex <> 0 then
      raise Exception.Create('Test failed: CameraIndex default value should be 0');
    if Cam.Width <> 640 then
      raise Exception.Create('Test failed: Width default value should be 640');
    if Cam.Height <> 480 then
      raise Exception.Create('Test failed: Height default value should be 480');
    if Cam.FPS <> 30 then
      raise Exception.Create('Test failed: FPS default value should be 30');
    if Cam.Backend <> cbAuto then
      raise Exception.Create('Test failed: Backend default value should be cbAuto');
    if Cam.PreviewHandle <> 0 then
      raise Exception.Create('Test failed: PreviewHandle default value should be 0');
    if not Cam.PreviewEnabled then
      raise Exception.Create('Test failed: PreviewEnabled default value should be True');
    if Cam.TempFolder <> '' then
      raise Exception.Create('Test failed: TempFolder default value should be empty');
    if not Cam.AutoDeleteTempFiles then
      raise Exception.Create('Test failed: AutoDeleteTempFiles default value should be True');
    if Cam.CaptureInterval <> 100 then
      raise Exception.Create('Test failed: CaptureInterval default value should be 100');
    if Cam.MaxCameraScan <> 5 then
      raise Exception.Create('Test failed: MaxCameraScan default value should be 5');
    if Cam.Active then
      raise Exception.Create('Test failed: Active should initially be False');
    if Cam.LastFrameFile <> '' then
      raise Exception.Create('Test failed: LastFrameFile should initially be empty');

    // 2. Verify behavior with cbNativeStub backend
    WriteLn('Testing cbNativeStub backend error validation...');
    Cam.Backend := cbNativeStub;
    if Cam.StartCapture then
      raise Exception.Create('Test failed: StartCapture should fail for cbNativeStub backend');
    if Cam.LastError = '' then
      raise Exception.Create('Test failed: LastError should not be empty on cbNativeStub StartCapture');
    if Cam.Active then
      raise Exception.Create('Test failed: Active should remain False on failed StartCapture');

    // Reset backend for subsequent checks
    Cam.Backend := cbAuto;

    // 3. Verify nil check on CaptureToImage
    WriteLn('Testing CaptureToImage(nil) validation...');
    if Cam.CaptureToImage(nil) then
      raise Exception.Create('Test failed: CaptureToImage(nil) should return False');
    if Pos('TImage parameter is nil', Cam.LastError) = 0 then
      raise Exception.Create('Test failed: LastError should indicate TImage is nil');

    // 4. Test physical camera functions if AI_CAMERA_TEST=1 is configured
    EnvTest := GetEnvironmentVariable('AI_CAMERA_TEST');
    HasCameraTest := (EnvTest = '1') or (UpperCase(EnvTest) = 'TRUE');

    if HasCameraTest then
    begin
      WriteLn('AI_CAMERA_TEST=1 found. Running physical camera tests...');
      
      // Run SelfTest
      WriteLn('Running SelfTest...');
      SelfTestOk := Cam.SelfTest;
      if not SelfTestOk then
      begin
        WriteLn('SelfTest failed: ' + Cam.LastError);
        raise Exception.Create('Test failed: SelfTest returned False: ' + Cam.LastError);
      end;
      WriteLn('SelfTest passed.');

      // Run ListAvailableCameras
      WriteLn('Listing available cameras...');
      List := Cam.ListAvailableCameras;
      try
        WriteLn('Found cameras:');
        for I := 0 to List.Count - 1 do
          WriteLn('  ', List[I]);
      finally
        List.Free;
      end;

      // Start capture headlessly
      WriteLn('Starting capture headlessly...');
      Cam.PreviewEnabled := False;
      if not Cam.StartCapture then
        raise Exception.Create('Test failed: StartCapture returned False: ' + Cam.LastError);
      
      if not Cam.Active then
        raise Exception.Create('Test failed: Active should be True after StartCapture');

      // Wait a short time to let capture run
      WriteLn('Waiting 1 second...');
      Sleep(1000);

      // Verify LastFrameFile is generated and exists
      WriteLn('Checking captured frame...');
      if Cam.LastFrameFile = '' then
        raise Exception.Create('Test failed: LastFrameFile should not be empty after capture runs');
      if not FileExists(Cam.LastFrameFile) then
        raise Exception.Create('Test failed: Captured frame file does not exist on disk: ' + Cam.LastFrameFile);
      
      WriteLn('Captured frame file exists: ', Cam.LastFrameFile);

      // Stop capture
      WriteLn('Stopping capture...');
      Cam.StopCapture;
      if Cam.Active then
        raise Exception.Create('Test failed: Active should be False after StopCapture');
        
      WriteLn('Physical camera test sequence passed.');
    end
    else
    begin
      WriteLn('AI_CAMERA_TEST is not set. Skipping physical camera testing.');
    end;

  finally
    Cam.Free;
    Runner.Free;
  end;

  WriteLn('test_aicameracapture COMPLETED SUCCESSFULLY.');
end.
