unit aihumanposedetector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, DynLibs, fpjson, jsonparser, FileUtil,
  aiplatform, airuntimepaths, aihumanpose_types, Math, LResources,
  IntfGraphics, GraphType;

type
  { MediaPipe Bridge DLL function prototypes }
  TInitMPPoseFunc = function(
    const AModelPath: PAnsiChar;
    AMaxPoses: Integer;
    AMinDetectConfidence: Single;
    AMinPresenceConfidence: Single;
    AMinTrackingConfidence: Single;
    AOutputMasks: Byte
  ): Integer; cdecl;

  TDetectMPPoseFrameFunc = function(
    APixels: Pointer;
    AWidth: Integer;
    AHeight: Integer;
    AFormat: Integer;
    var AOutScore: Single;
    AOutLandmarks: Pointer; // Expects pointer to 33 * 5 Singles (X, Y, Z, Vis, Pres)
    AOutMaskPixels: Pointer // Output buffer for segmentation mask if requested
  ): Integer; cdecl;

  TCloseMPPoseFunc = procedure; cdecl;

  { TAIHumanPoseDetector }

  TAIHumanPoseDetector = class(TAIBaseComponent)
  private
    FBridgeDLLPath: string;
    FRuntimePath: string;
    FModelFile: string;
    FActive: Boolean;
    FLoadMode: TMPLoadMode;
    FExecutionMode: TMPExecutionMode;
    FRequiredBridgeAbiVersion: Integer;
    FRequiredMediaPipeVersion: string;
    FRunningMode: TMPRunningMode;
    FNumPoses: Integer;
    FMinPoseDetectionConfidence: Single;
    FMinPosePresenceConfidence: Single;
    FMinTrackingConfidence: Single;
    FOutputSegmentationMasks: Boolean;
    FModelVariant: TMPModelVariant;
    FInputColorFormat: TMPInputColorFormat;
    FDetectAllLandmarks: Boolean;
    FEnabledBodyPartGroups: TAIHumanBodyPartGroups;
    FMinLandmarkVisibility: Single;
    FMinLandmarkPresence: Single;
    FIgnoreInvisibleLandmarks: Boolean;

    // Visualization
    FDrawSkeleton: Boolean;
    FDrawLandmarkPoints: Boolean;
    FDrawLandmarkNames: Boolean;

    // DLL details
    FLoadedBridgeDLLPath: string;
    FBridgeVersionText: string;
    FBridgeAbiVersion: Integer;
    FRequiredMethodsOK: Boolean;
    FDiagnosticLog: TStringList;
    FLibHandle: TLibHandle;

    // Detected results
    FLastResultData: TAIHumanPoseDetectionResult;

    // DLL functions pointers
    FInitMPPose: TInitMPPoseFunc;
    FDetectMPPoseFrame: TDetectMPPoseFrameFunc;
    FCloseMPPose: TCloseMPPoseFunc;

    procedure SetActive(const AValue: Boolean);
    function LoadBridgeDLL: Boolean;
    procedure UnloadBridgeDLL;
    function ResolveModelPath: string;
    procedure DoDiagnosticLog(const AMessage: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Initialize: Boolean;
    function DetectImageFile(const AFileName: string): Boolean;
    function DetectBitmap(ABitmap: TBitmap): Boolean;
    procedure ClearResult;
    function GetLandmark(APoseIndex: Integer; ALandmark: TAIHumanPoseLandmarkIndex; out AOutLandmark: TAIHumanPoseLandmark): Boolean;
    procedure DrawOnCanvas(ACanvas: TCanvas; AWidth, AHeight: Integer);
    procedure DrawOnCanvasRect(ACanvas: TCanvas; const ARect: TRect);

    property LoadedBridgeDLLPath: string read FLoadedBridgeDLLPath;
    property BridgeVersionText: string read FBridgeVersionText;
    property BridgeAbiVersion: Integer read FBridgeAbiVersion;
    property RequiredMethodsOK: Boolean read FRequiredMethodsOK;
    property DiagnosticLog: TStringList read FDiagnosticLog;
    property LastResultData: TAIHumanPoseDetectionResult read FLastResultData;
  published
    property BridgeDLLPath: string read FBridgeDLLPath write FBridgeDLLPath;
    property RuntimePath: string read FRuntimePath write FRuntimePath;
    property ModelFile: string read FModelFile write FModelFile;
    property Active: Boolean read FActive write SetActive default False;
    property LoadMode: TMPLoadMode read FLoadMode write FLoadMode default mplmAuto;
    property ExecutionMode: TMPExecutionMode read FExecutionMode write FExecutionMode default mpemDLL;
    property RequiredBridgeAbiVersion: Integer read FRequiredBridgeAbiVersion write FRequiredBridgeAbiVersion default 1;
    property RequiredMediaPipeVersion: string read FRequiredMediaPipeVersion write FRequiredMediaPipeVersion;
    property RunningMode: TMPRunningMode read FRunningMode write FRunningMode default hprImage;
    property NumPoses: Integer read FNumPoses write FNumPoses default 1;
    property MinPoseDetectionConfidence: Single read FMinPoseDetectionConfidence write FMinPoseDetectionConfidence;
    property MinPosePresenceConfidence: Single read FMinPosePresenceConfidence write FMinPosePresenceConfidence;
    property MinTrackingConfidence: Single read FMinTrackingConfidence write FMinTrackingConfidence;
    property OutputSegmentationMasks: Boolean read FOutputSegmentationMasks write FOutputSegmentationMasks default False;
    property ModelVariant: TMPModelVariant read FModelVariant write FModelVariant default hpmFull;
    property InputColorFormat: TMPInputColorFormat read FInputColorFormat write FInputColorFormat default hpcRGB;
    property DetectAllLandmarks: Boolean read FDetectAllLandmarks write FDetectAllLandmarks default True;
    property EnabledBodyPartGroups: TAIHumanBodyPartGroups read FEnabledBodyPartGroups write FEnabledBodyPartGroups;
    property MinLandmarkVisibility: Single read FMinLandmarkVisibility write FMinLandmarkVisibility;
    property MinLandmarkPresence: Single read FMinLandmarkPresence write FMinLandmarkPresence;
    property IgnoreInvisibleLandmarks: Boolean read FIgnoreInvisibleLandmarks write FIgnoreInvisibleLandmarks default True;

    // Visualization
    property DrawSkeleton: Boolean read FDrawSkeleton write FDrawSkeleton default True;
    property DrawLandmarkPoints: Boolean read FDrawLandmarkPoints write FDrawLandmarkPoints default True;
    property DrawLandmarkNames: Boolean read FDrawLandmarkNames write FDrawLandmarkNames default False;
  end;

procedure Register;

implementation

const
  LANDMARK_NAMES: array[0..32] of string = (
    'Nose', 'Left Eye Inner', 'Left Eye', 'Left Eye Outer',
    'Right Eye Inner', 'Right Eye', 'Right Eye Outer',
    'Left Ear', 'Right Ear', 'Mouth Left', 'Mouth Right',
    'Left Shoulder', 'Right Shoulder', 'Left Elbow', 'Right Elbow',
    'Left Wrist', 'Right Wrist', 'Left Pinky', 'Right Pinky',
    'Left Index', 'Right Index', 'Left Thumb', 'Right Thumb',
    'Left Hip', 'Right Hip', 'Left Knee', 'Right Knee',
    'Left Ankle', 'Right Ankle', 'Left Heel', 'Right Heel',
    'Left Foot Index', 'Right Foot Index'
  );

procedure Register;

begin
  RegisterComponents('AI Vision', [TAIHumanPoseDetector]);
end;

{ TAIHumanPoseDetector }

constructor TAIHumanPoseDetector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FPrompt := 'Component TAIHumanPoseDetector processes body pose estimation via native versioned MediaPipe C/C++ Bridge.';
  
  FBridgeDLLPath := '';
  FRuntimePath := '';
  FModelFile := '';
  FActive := False;
  FLoadMode := mplmAuto;
  FExecutionMode := mpemDLL;
  FRequiredBridgeAbiVersion := 1;
  FRequiredMediaPipeVersion := '0.10.35';
  FRunningMode := hprImage;
  FNumPoses := 1;
  FMinPoseDetectionConfidence := 0.5;
  FMinPosePresenceConfidence := 0.5;
  FMinTrackingConfidence := 0.5;
  FOutputSegmentationMasks := False;
  FModelVariant := hpmFull;
  FInputColorFormat := hpcRGB;
  FDetectAllLandmarks := True;
  FEnabledBodyPartGroups := [hpgFace, hpgShoulders, hpgLeftArm, hpgRightArm, hpgTorso, hpgLeftLeg, hpgRightLeg];
  FMinLandmarkVisibility := 0.5;
  FMinLandmarkPresence := 0.5;
  FIgnoreInvisibleLandmarks := True;

  FDrawSkeleton := True;
  FDrawLandmarkPoints := True;
  FDrawLandmarkNames := False;

  FLibHandle := NilHandle;
  FDiagnosticLog := TStringList.Create;
  
  FillChar(FLastResultData, SizeOf(FLastResultData), 0);
  ClearError;
end;

destructor TAIHumanPoseDetector.Destroy;
begin
  UnloadBridgeDLL;
  FDiagnosticLog.Free;
  inherited Destroy;
end;

procedure TAIHumanPoseDetector.DoDiagnosticLog(const AMessage: string);
begin
  FDiagnosticLog.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz: ', Now) + AMessage);
  Log(llDebug, AMessage);
end;

procedure TAIHumanPoseDetector.SetActive(const AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
  begin
    if Initialize then
      FActive := True;
  end
  else
  begin
    UnloadBridgeDLL;
    FActive := False;
  end;
end;

function TAIHumanPoseDetector.ResolveModelPath: string;
var
  LBase, LRuntimeRoot, LCandidate: string;
  I: Integer;
begin
  if FModelFile <> '' then
  begin
    if FileExists(FModelFile) then
      Exit(FModelFile);
  end;

  LBase := ExtractFilePath(ParamStr(0));
  LRuntimeRoot := '';
  for I := 0 to 5 do
  begin
    LCandidate := AICombinePath(LBase, 'runtime' + DirectorySeparator + 'mediapipe' + DirectorySeparator);
    if DirectoryExists(LCandidate) then
    begin
      LRuntimeRoot := LCandidate;
      Break;
    end;
    LBase := AICombinePath(LBase, '..' + DirectorySeparator);
  end;

  if LRuntimeRoot <> '' then
  begin
    // Structure: runtime/mediapipe/pose/mp_0_10_35/windows/x64/models/pose_landmarker_xxx.task
    LCandidate := LRuntimeRoot + 'pose' + DirectorySeparator + 'mp_' + StringReplace(FRequiredMediaPipeVersion, '.', '_', [rfReplaceAll]) +
                  DirectorySeparator;
    {$IFDEF MSWINDOWS}
    LCandidate := LCandidate + 'windows' + DirectorySeparator + 'x64' + DirectorySeparator;
    {$ELSE}
    LCandidate := LCandidate + 'linux' + DirectorySeparator + 'x64' + DirectorySeparator;
    {$ENDIF}

    case FModelVariant of
      hpmLite:   Result := LCandidate + 'models' + DirectorySeparator + 'pose_landmarker_lite.task';
      hpmHeavy:  Result := LCandidate + 'models' + DirectorySeparator + 'pose_landmarker_heavy.task';
      else       Result := LCandidate + 'models' + DirectorySeparator + 'pose_landmarker_full.task';
    end;
  end
  else
    Result := '';
end;

function TAIHumanPoseDetector.LoadBridgeDLL: Boolean;
var
  LDLLName, LPlatformFolder, LBase, LCandidateDir, LPath: string;
  I: Integer;
begin
  Result := False;
  UnloadBridgeDLL;

  // Resolve DLL name and folder structure dynamically based on OS and architecture
  {$IFDEF MSWINDOWS}
    {$IFDEF CPU64}
      LDLLName := 'ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll';
      LPlatformFolder := 'windows' + DirectorySeparator + 'x64' + DirectorySeparator;
    {$ELSE}
      LDLLName := 'ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win32.dll';
      LPlatformFolder := 'windows' + DirectorySeparator + 'x86' + DirectorySeparator;
    {$ENDIF}
  {$ELSE}
    {$IFDEF CPU64}
      LDLLName := 'libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so';
      LPlatformFolder := 'linux' + DirectorySeparator + 'x64' + DirectorySeparator;
    {$ELSE}
      LDLLName := 'libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux32.so';
      LPlatformFolder := 'linux' + DirectorySeparator + 'x86' + DirectorySeparator;
    {$ENDIF}
  {$ENDIF}

  if (FLoadMode = mplmManualPath) and (FBridgeDLLPath <> '') then
  begin
    if FileExists(FBridgeDLLPath) then
      LPath := FBridgeDLLPath
    else
      LPath := AICombinePath(FBridgeDLLPath, LDLLName);
  end
  else
  begin
    // Find bundled runtime path
    LBase := ExtractFilePath(ParamStr(0));
    LPath := '';
    for I := 0 to 5 do
    begin
      // Try posebridge folder structure: runtime/mediapipe/posebridge/
      LCandidateDir := AICombinePath(LBase, 'runtime' + DirectorySeparator + 'mediapipe' + DirectorySeparator + 'posebridge' + DirectorySeparator);
      if DirectoryExists(LCandidateDir) then
      begin
        LPath := AICombinePath(LCandidateDir, LDLLName);
        if FileExists(LPath) then Break;
      end;

      // Try simple OpenCV-like runtime structure first: runtime/mediapipe/windows/x64/
      LCandidateDir := AICombinePath(LBase, 'runtime' + DirectorySeparator + 'mediapipe' + DirectorySeparator + LPlatformFolder);
      if DirectoryExists(LCandidateDir) then
      begin
        LPath := AICombinePath(LCandidateDir, LDLLName);
        if FileExists(LPath) then Break;
      end;

      // Try nested versioned structure: runtime/mediapipe/pose/mp_0_10_35/windows/x64/
      LCandidateDir := AICombinePath(LBase, 'runtime' + DirectorySeparator + 'mediapipe' + DirectorySeparator +
                        'pose' + DirectorySeparator + 'mp_' + StringReplace(FRequiredMediaPipeVersion, '.', '_', [rfReplaceAll]) +
                        DirectorySeparator + LPlatformFolder);
      if DirectoryExists(LCandidateDir) then
      begin
        LPath := AICombinePath(LCandidateDir, LDLLName);
        if FileExists(LPath) then Break;
      end;

      LBase := AICombinePath(LBase, '..' + DirectorySeparator);
    end;

    if (LPath = '') or (not FileExists(LPath)) then
    begin
      // Try next to executable
      LPath := AICombinePath(ExtractFilePath(ParamStr(0)), LDLLName);
    end;
  end;

  DoDiagnosticLog('Resolving MediaPipe bridge path: ' + LPath);
  if not FileExists(LPath) then
  begin
    DoDiagnosticLog('MediaPipe Bridge DLL/SO not found: ' + LPath);
    FLoadedBridgeDLLPath := '';
    FRequiredMethodsOK := False;
    FBridgeVersionText := '';
    FBridgeAbiVersion := 0;
    Exit(False);
  end;

  try
    FLibHandle := SafeLoadLibrary(LPath);
    if FLibHandle <> NilHandle then
    begin
      FLoadedBridgeDLLPath := LPath;
      FInitMPPose := TInitMPPoseFunc(GetProcAddress(FLibHandle, 'InitMPPose'));
      FDetectMPPoseFrame := TDetectMPPoseFrameFunc(GetProcAddress(FLibHandle, 'DetectMPPoseFrame'));
      FCloseMPPose := TCloseMPPoseFunc(GetProcAddress(FLibHandle, 'CloseMPPose'));

      FRequiredMethodsOK := Assigned(FInitMPPose) and Assigned(FDetectMPPoseFrame) and Assigned(FCloseMPPose);
      if FRequiredMethodsOK then
      begin
        FBridgeVersionText := '1.0.0 (Native)';
        FBridgeAbiVersion := 1;
        DoDiagnosticLog('MediaPipe bridge DLL loaded successfully. All entry points verified.');
        Result := True;
      end;
    end;
  except
    on E: Exception do
      DoDiagnosticLog('Exception while loading bridge: ' + E.Message);
  end;
end;

procedure TAIHumanPoseDetector.UnloadBridgeDLL;
begin
  if FLibHandle <> NilHandle then
  begin
    if FRequiredMethodsOK and Assigned(FCloseMPPose) then
    begin
      try
        FCloseMPPose();
      except
        // ignore
      end;
    end;
    UnloadLibrary(FLibHandle);
    FLibHandle := NilHandle;
  end;
  FRequiredMethodsOK := False;
  FInitMPPose := nil;
  FDetectMPPoseFrame := nil;
  FCloseMPPose := nil;
end;

function TAIHumanPoseDetector.Initialize: Boolean;
var
  LModel: string;
begin
  ClearError;
  Result := False;
  DoDiagnosticLog('Initializing TAIHumanPoseDetector...');
  
  if not LoadBridgeDLL then
  begin
    SetError('Failed to load MediaPipe bridge DLL.');
    Exit;
  end;

  LModel := ResolveModelPath;
  DoDiagnosticLog('Model task file path: ' + LModel);

  if FRequiredMethodsOK then
  begin
    if LModel = '' then
    begin
      SetError('MediaPipe model task path cannot be resolved.');
      Exit;
    end;

    try
      // Return value: 0 is success
      if FInitMPPose(PAnsiChar(LModel), FNumPoses, FMinPoseDetectionConfidence,
                     FMinPosePresenceConfidence, FMinTrackingConfidence, Byte(FOutputSegmentationMasks)) = 0 then
      begin
        DoDiagnosticLog('Successfully initialized MediaPipe engine.');
        FLastSuccess := True;
        Result := True;
      end
      else
        SetError('InitMPPose returned failure initialization code.');
    except
      on E: Exception do
        SetError('Failed to initialize MediaPipe Native: ' + E.Message);
    end;
  end;
end;

function TAIHumanPoseDetector.DetectImageFile(const AFileName: string): Boolean;
var
  LPic: TPicture;
begin
  Result := False;
  ClearError;
  
  if AFileName = '' then
  begin
    SetError('File name is empty.');
    Exit;
  end;
  
  if not FileExists(AFileName) then
  begin
    SetError('Image file does not exist: ' + AFileName);
    Exit;
  end;

  LPic := TPicture.Create;
  try
    try
      LPic.LoadFromFile(AFileName);
      if Assigned(LPic.Bitmap) then
      begin
        Result := DetectBitmap(LPic.Bitmap);
      end
      else
        SetError('Loaded picture does not contain a valid bitmap.');
    except
      on E: Exception do
        SetError('Failed to process image file: ' + E.Message);
    end;
  finally
    LPic.Free;
  end;
end;

function TAIHumanPoseDetector.DetectBitmap(ABitmap: TBitmap): Boolean;
type
  TSingleArray = array[0..33*5-1] of Single;
var
  RawData: TSingleArray;
  Score: Single;
  I: Integer;
  Res: Integer;
  LIntfImg: TLazIntfImage;
  LFormat: Integer;
begin
  Result := False;
  ClearError;
  FillChar(FLastResultData, SizeOf(FLastResultData), 0);

  if not Assigned(ABitmap) or (ABitmap.Width <= 0) or (ABitmap.Height <= 0) then
  begin
    SetError('Invalid bitmap parameter.');
    Exit;
  end;

  if not FRequiredMethodsOK then
  begin
    SetError('MediaPipe bridge DLL is not loaded or missing entry points.');
    Exit;
  end;

  LIntfImg := TLazIntfImage.Create(0, 0);
  try
    try
      LIntfImg.LoadFromBitmap(ABitmap.Handle, ABitmap.MaskHandle);
      
      // Determine color format of raw pixels
      LFormat := 3; // Default to BGRA
      if LIntfImg.DataDescription.BitsPerPixel = 32 then
      begin
        if LIntfImg.DataDescription.RedShift < LIntfImg.DataDescription.BlueShift then
          LFormat := 2 // RGBA
        else
          LFormat := 3; // BGRA
      end
      else if LIntfImg.DataDescription.BitsPerPixel = 24 then
      begin
        if LIntfImg.DataDescription.RedShift < LIntfImg.DataDescription.BlueShift then
          LFormat := 0 // RGB
        else
          LFormat := 1; // BGR
      end;

      Score := 0;
      FillChar(RawData, SizeOf(RawData), 0);

      DoDiagnosticLog(Format('DetectBitmap: Invoking DLL DetectMPPoseFrame (%dx%d, Format=%d)...',
        [LIntfImg.Width, LIntfImg.Height, LFormat]));

      Res := FDetectMPPoseFrame(LIntfImg.GetDataLineStart(0), LIntfImg.Width, LIntfImg.Height, LFormat, Score, @RawData[0], nil);

      if Res = 0 then
      begin
        FLastResultData.HasPose := True;
        FLastResultData.Score := Score;
        for I := 0 to 32 do
        begin
          FLastResultData.Landmarks[I].Index := I;
          FLastResultData.Landmarks[I].X := RawData[I * 5 + 0];
          FLastResultData.Landmarks[I].Y := RawData[I * 5 + 1];
          FLastResultData.Landmarks[I].Z := RawData[I * 5 + 2];
          FLastResultData.Landmarks[I].Visibility := RawData[I * 5 + 3];
          FLastResultData.Landmarks[I].Presence := RawData[I * 5 + 4];
          FLastResultData.Landmarks[I].Name := LANDMARK_NAMES[I];
        end;
        FLastResult := 'Body pose estimation succeeded.';
        FLastSuccess := True;
        Result := True;
      end
      else
      begin
        SetError('DetectMPPoseFrame returned failure code: ' + IntToStr(Res));
      end;
    except
      on E: Exception do
        SetError('Error during frame detection: ' + E.Message);
    end;
  finally
    LIntfImg.Free;
  end;
end;

procedure TAIHumanPoseDetector.ClearResult;
begin
  FillChar(FLastResultData, SizeOf(FLastResultData), 0);
  FLastResultData.HasPose := False;
end;

function TAIHumanPoseDetector.GetLandmark(APoseIndex: Integer; ALandmark: TAIHumanPoseLandmarkIndex; out AOutLandmark: TAIHumanPoseLandmark): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  Idx := Integer(ALandmark);
  if (Idx >= 0) and (Idx <= 32) and FLastResultData.HasPose then
  begin
    AOutLandmark := FLastResultData.Landmarks[Idx];
    Result := True;
  end;
end;

procedure TAIHumanPoseDetector.DrawOnCanvas(ACanvas: TCanvas; AWidth, AHeight: Integer);
begin
  DrawOnCanvasRect(ACanvas, Rect(0, 0, AWidth, AHeight));
end;

procedure TAIHumanPoseDetector.DrawOnCanvasRect(ACanvas: TCanvas; const ARect: TRect);
  procedure DrawLine(Idx1, Idx2: Integer);
  var
    P1, P2: TPoint;
    LWidth, LHeight: Integer;
  begin
    LWidth := ARect.Right - ARect.Left;
    LHeight := ARect.Bottom - ARect.Top;
    P1.X := ARect.Left + Round(FLastResultData.Landmarks[Idx1].X * LWidth);
    P1.Y := ARect.Top + Round(FLastResultData.Landmarks[Idx1].Y * LHeight);
    P2.X := ARect.Left + Round(FLastResultData.Landmarks[Idx2].X * LWidth);
    P2.Y := ARect.Top + Round(FLastResultData.Landmarks[Idx2].Y * LHeight);
    ACanvas.Line(P1, P2);
  end;

  procedure DrawPoint(Idx: Integer);
  var
    P: TPoint;
    LWidth, LHeight: Integer;
  begin
    LWidth := ARect.Right - ARect.Left;
    LHeight := ARect.Bottom - ARect.Top;
    P.X := ARect.Left + Round(FLastResultData.Landmarks[Idx].X * LWidth);
    P.Y := ARect.Top + Round(FLastResultData.Landmarks[Idx].Y * LHeight);
    ACanvas.Ellipse(P.X - 4, P.Y - 4, P.X + 4, P.Y + 4);
    if FDrawLandmarkNames then
    begin
      ACanvas.TextOut(P.X + 6, P.Y - 6, IntToStr(Idx));
    end;
  end;

var
  I: Integer;
begin
  if not FLastResultData.HasPose then Exit;

  ACanvas.Pen.Color := clGreen;
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Color := clLime;

  if FDrawSkeleton then
  begin
    // Shoulders & Torso
    DrawLine(11, 12);
    DrawLine(11, 23);
    DrawLine(12, 24);
    DrawLine(23, 24);

    // Left Arm
    DrawLine(11, 13);
    DrawLine(13, 15);

    // Right Arm
    DrawLine(12, 14);
    DrawLine(14, 16);

    // Left Leg
    DrawLine(23, 25);
    DrawLine(25, 27);

    // Right Leg
    DrawLine(24, 26);
    DrawLine(26, 28);
  end;

  if FDrawLandmarkPoints then
  begin
    for I := 0 to 32 do
      DrawPoint(I);
  end;
end;

initialization
  {$I aihumanposedetector_icon.lrs}

end.
