program human_pose_detector_bridge_test;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Classes, SysUtils, Graphics, Math,
  aihumanposedetector, aihumanpose_types;

const
  RELATIVE_RUNTIME_DLL = '../../../runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll';
  RELATIVE_BRIDGE_DLL  = '../../../bridge/runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll';
  RELATIVE_DEMO_DLL    = '../../samples/AI MediaPipe Vision/pose_detector_demo/ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll';
  RELATIVE_IMAGE_1     = '../../samples/AI MediaPipe Vision/pose_detector_demo/images/pose_1_full_body_standing_1781297037417.jpg';
  RELATIVE_IMAGE_2     = '../../samples/AI MediaPipe Vision/pose_detector_demo/images/pose_2_walking_side_view_1781297048074.jpg';

  SelectedLandmarkIds: array[0..8] of TAIHumanPoseLandmarkId = (
    hplNose,
    hplLeftShoulder,
    hplRightShoulder,
    hplLeftHip,
    hplRightHip,
    hplLeftKnee,
    hplRightKnee,
    hplLeftAnkle,
    hplRightAnkle
  );

  SelectedLandmarkNames: array[0..8] of string = (
    'Nose',
    'Left Shoulder',
    'Right Shoulder',
    'Left Hip',
    'Right Hip',
    'Left Knee',
    'Right Knee',
    'Left Ankle',
    'Right Ankle'
  );

type
  TSelectedLandmarks = array[0..8] of TAIHumanPoseLandmark;

var
  Detector: TAIHumanPoseDetector;
  Bmp: TBitmap;

function ResolveProjectFile(const ARelative: string): string;
begin
  Result := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + ARelative);
end;

function HasFullModelAlongsideDll(const ADllPath: string): Boolean;
var
  LModelPath: string;
begin
  Result := False;
  if ADllPath = '' then
    Exit;

  LModelPath := IncludeTrailingPathDelimiter(ExtractFilePath(ADllPath))
    + 'models' + DirectorySeparator + 'pose_landmarker_full.task';
  Result := FileExists(LModelPath);
end;

function ResolveBridgeDllPath: string;
var
  LCandidate: string;
begin
  Result := '';

  LCandidate := ResolveProjectFile(RELATIVE_RUNTIME_DLL);
  if FileExists(LCandidate) and HasFullModelAlongsideDll(LCandidate) then
    Exit(LCandidate);

  LCandidate := ResolveProjectFile(RELATIVE_BRIDGE_DLL);
  if FileExists(LCandidate) and HasFullModelAlongsideDll(LCandidate) then
    Exit(LCandidate);

  LCandidate := ResolveProjectFile(RELATIVE_DEMO_DLL);
  if FileExists(LCandidate) and HasFullModelAlongsideDll(LCandidate) then
    Exit(LCandidate);

  LCandidate := ResolveProjectFile(RELATIVE_RUNTIME_DLL);
  if FileExists(LCandidate) then
    Exit(LCandidate);

  LCandidate := ResolveProjectFile(RELATIVE_BRIDGE_DLL);
  if FileExists(LCandidate) then
    Exit(LCandidate);

  LCandidate := ResolveProjectFile(RELATIVE_DEMO_DLL);
  if FileExists(LCandidate) then
    Exit(LCandidate);
end;

function ResolveImagePath(const ARelative: string): string;
begin
  Result := ResolveProjectFile(ARelative);
end;

function LoadBitmapFromImage(const AFileName: string; ABmp: TBitmap): Boolean;
var
  LPicture: TPicture;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;

  LPicture := TPicture.Create;
  try
    LPicture.LoadFromFile(AFileName);
    ABmp.SetSize(LPicture.Width, LPicture.Height);
    ABmp.Canvas.Draw(0, 0, LPicture.Graphic);
    Result := True;
  finally
    LPicture.Free;
  end;
end;

function DetectBitmapWithTiming(const ADetector: TAIHumanPoseDetector; const ABitmap: TBitmap;
  out AElapsedMs: Double): Boolean;
var
  LStart, LEnd: TDateTime;
begin
  LStart := Now;
  Result := ADetector.DetectBitmap(ABitmap);
  LEnd := Now;
  AElapsedMs := (LEnd - LStart) * 24.0 * 60.0 * 60.0 * 1000.0;
end;

procedure CaptureSelectedLandmarks(const ADetector: TAIHumanPoseDetector;
  out AValues: TSelectedLandmarks);
var
  I: Integer;
begin
  for I := Low(SelectedLandmarkIds) to High(SelectedLandmarkIds) do
  begin
    if not ADetector.GetLandmark(0, SelectedLandmarkIds[I], AValues[I]) then
      raise Exception.Create('Failed to read selected landmark index ' + IntToStr(I) + '.');
  end;
end;

procedure PrintSelectedLandmarks(const AHeader: string; const AValues: TSelectedLandmarks);
var
  I: Integer;
begin
  WriteLn(AHeader);
  for I := Low(AValues) to High(AValues) do
  begin
    WriteLn(Format('  %s: x=%.6f y=%.6f z=%.6f',
      [SelectedLandmarkNames[I], AValues[I].X, AValues[I].Y, AValues[I].Z]));
  end;
end;

function SelectedLandmarksEqual(const A, B: TSelectedLandmarks): Boolean;
const
  Epsilon = 1e-6;
var
  I: Integer;
begin
  Result := True;
  for I := Low(A) to High(A) do
  begin
    if (Abs(A[I].X - B[I].X) > Epsilon) or
       (Abs(A[I].Y - B[I].Y) > Epsilon) or
       (Abs(A[I].Z - B[I].Z) > Epsilon) then
      Exit(False);
  end;
end;

procedure RunSimSmokeTest(const ADetector: TAIHumanPoseDetector; ABmp: TBitmap);
var
  LElapsedMs: Double;
begin
  ABmp.SetSize(100, 100);
  ABmp.Canvas.Brush.Color := clBlue;
  ABmp.Canvas.FillRect(0, 0, ABmp.Width, ABmp.Height);

  WriteLn('Running SIM smoke test...');
  if not DetectBitmapWithTiming(ADetector, ABmp, LElapsedMs) then
    raise Exception.Create('SIM DetectBitmap failed: ' + ADetector.LastError);

  WriteLn(Format('Tempo: %.2f ms', [LElapsedMs]));
  WriteLn(Format('Pose count: %d', [ADetector.GetPoseCount]));

  if ADetector.GetPoseCount <= 0 then
    raise Exception.Create('SIM backend did not return a pose.');

  if ADetector.LastResultData.Poses[0].LandmarkCount <> 33 then
    raise Exception.CreateFmt('SIM backend returned %d landmarks instead of 33.',
      [ADetector.LastResultData.Poses[0].LandmarkCount]);

  WriteLn('33 landmarks simulados detectados.');
  WriteLn('ATENCAO: backend SIM gera landmarks simulados. Ele nao reconhece a imagem real.');
end;

procedure RunRealComparison(const ADetector: TAIHumanPoseDetector; ABmp: TBitmap);
var
  LImage1Path, LImage2Path: string;
  LElapsedMs: Double;
  LFirstLandmarks, LSecondLandmarks: TSelectedLandmarks;
begin
  LImage1Path := ResolveImagePath(RELATIVE_IMAGE_1);
  LImage2Path := ResolveImagePath(RELATIVE_IMAGE_2);

  if not LoadBitmapFromImage(LImage1Path, ABmp) then
    raise Exception.Create('Image 1 not found or could not be loaded: ' + LImage1Path);

  WriteLn('Image 1: ' + LImage1Path);
  if not DetectBitmapWithTiming(ADetector, ABmp, LElapsedMs) then
    raise Exception.Create('mp_pose_detect REAL failed on image 1: ' + ADetector.LastError);
  WriteLn(Format('Tempo imagem 1: %.2f ms', [LElapsedMs]));
  if ADetector.GetPoseCount <= 0 then
    raise Exception.Create('REAL backend returned no pose for image 1.');
  if ADetector.LastResultData.Poses[0].LandmarkCount <> 33 then
    raise Exception.CreateFmt('REAL backend returned %d landmarks instead of 33 on image 1.',
      [ADetector.LastResultData.Poses[0].LandmarkCount]);
  CaptureSelectedLandmarks(ADetector, LFirstLandmarks);
  PrintSelectedLandmarks('Image 1 selected landmarks:', LFirstLandmarks);

  if not LoadBitmapFromImage(LImage2Path, ABmp) then
    raise Exception.Create('Image 2 not found or could not be loaded: ' + LImage2Path);

  WriteLn('Image 2: ' + LImage2Path);
  if not DetectBitmapWithTiming(ADetector, ABmp, LElapsedMs) then
    raise Exception.Create('mp_pose_detect REAL failed on image 2: ' + ADetector.LastError);
  WriteLn(Format('Tempo imagem 2: %.2f ms', [LElapsedMs]));
  if ADetector.GetPoseCount <= 0 then
    raise Exception.Create('REAL backend returned no pose for image 2.');
  if ADetector.LastResultData.Poses[0].LandmarkCount <> 33 then
    raise Exception.CreateFmt('REAL backend returned %d landmarks instead of 33 on image 2.',
      [ADetector.LastResultData.Poses[0].LandmarkCount]);
  CaptureSelectedLandmarks(ADetector, LSecondLandmarks);
  PrintSelectedLandmarks('Image 2 selected landmarks:', LSecondLandmarks);

  if SelectedLandmarksEqual(LFirstLandmarks, LSecondLandmarks) then
    raise Exception.Create('ERRO: landmarks identicos em imagens diferentes. Backend nao e REAL ou resultado e mock.');

  WriteLn('mp_pose_detect REAL: OK');
  WriteLn('Comparacao automatica: landmarks diferentes entre as imagens.');
end;

begin
  Detector := nil;
  Bmp := nil;
  try
    WriteLn('Starting Human Pose Detector Bridge Test...');

    try
      Detector := TAIHumanPoseDetector.Create(nil);
      Bmp := TBitmap.Create;

      DLLPath := ResolveBridgeDllPath;
      WriteLn('Testing with DLL: ' + DLLPath);
      if DLLPath = '' then
        raise Exception.Create('Bridge DLL not found in the expected runtime locations.');

      Detector.LoadMode := mplmManualPath;
      Detector.BridgeDLLPath := DLLPath;

      WriteLn('Initializing detector...');
      if not Detector.Initialize then
        raise Exception.Create('Detector initialization failed. LastError: ' + Detector.LastError);

      WriteLn('DLL Loaded Successfully.');
      WriteLn('Backend: ' + Detector.BridgeBackend);
      WriteLn('Bridge Version: ' + Detector.BridgeVersionText);
      WriteLn('MediaPipe Version: ' + Detector.RequiredMediaPipeVersion);
      WriteLn('Loaded model: ' + Detector.LoadedModelFile);

      if SameText(Detector.BridgeBackend, 'SIM') then
        RunSimSmokeTest(Detector, Bmp)
      else if SameText(Detector.BridgeBackend, 'REAL') then
      begin
        WriteLn('Backend REAL ativo.');
        if Detector.LoadedModelFile = '' then
          raise Exception.Create('Backend REAL did not load a model path.');
        WriteLn('mp_pose_create REAL: OK');
        RunRealComparison(Detector, Bmp);
      end
      else
        raise Exception.Create('Unknown backend reported by the bridge: ' + Detector.BridgeBackend);

      WriteLn('Test passed successfully.');
      ExitCode := 0;
    finally
      Bmp.Free;
      Detector.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
