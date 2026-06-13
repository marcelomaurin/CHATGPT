unit aihumanposedetector;

{$mode objfpc}{$H+}

{$IFNDEF CPU64}
  {$ERROR TAIHumanPoseDetector is only supported on 64-bit systems.}
{$ENDIF}

interface

uses
  Classes, SysUtils, aibase, Graphics, fpjson, jsonparser, FileUtil,
  aiplatform, airuntimepaths, aihumanpose_types, Math, LResources,
  IntfGraphics, GraphType, mp_pose_bridge;

type
  TAIHumanPoseDetectedEvent = procedure(Sender: TObject; const AResult: TAIHumanPoseResult) of object;
  TAIHumanPoseErrorEvent = procedure(Sender: TObject; ACode: Integer; const AMsg: string) of object;

  { TAIHumanPoseDetector }

  TAIHumanPoseDetector = class(TAIBaseComponent)
  private
    FBridgeDLLPath: string;
    FRuntimePath: string;
    FModelFile: string;
    FActive: Boolean;
    FLoadMode: TAIHumanPoseLoadMode;
    FExecutionMode: TAIHumanPoseExecutionMode;
    FRequiredBridgeAbiVersion: Integer;
    FRequiredMediaPipeVersion: string;
    FRunningMode: TAIHumanPoseRunningMode;
    FNumPoses: Integer;
    FMinPoseDetectionConfidence: Single;
    FMinPosePresenceConfidence: Single;
    FMinTrackingConfidence: Single;
    FOutputSegmentationMasks: Boolean;
    FModelVariant: TAIHumanPoseModelVariant;
    FInputColorFormat: TAIHumanPoseColorFormat;
    FDetectAllLandmarks: Boolean;
    FMinLandmarkVisibility: Single;
    FMinLandmarkPresence: Single;
    FIgnoreInvisibleLandmarks: Boolean;

    FDrawSkeleton: Boolean;
    FDrawLandmarkPoints: Boolean;
    FDrawLandmarkNames: Boolean;

    // Diagnostics & Outputs
    FLastError: string;
    FLastOutput: string;
    FLoadedBridgeDLLPath: string;
    FLoadedModelFile: string;
    FBridgeVersionText: string;
    FBridgeAbiVersion: Integer;
    FDiagnosticLog: TStringList;

    // Events
    FOnPoseDetected: TAIHumanPoseDetectedEvent;
    FOnPoseError: TAIHumanPoseErrorEvent;

    // Internal DLL stuff
    FDetectorHandle: mp_pose_handle;
    FLastResultData: TAIHumanPoseResult;

    procedure SetActive(const AValue: Boolean);
    function LoadBridgeDLL: Boolean;
    procedure UnloadBridgeDLL;
    function ResolveModelPath: string;
    procedure DoDiagnosticLog(const AMessage: string);
    function GetLazarusArchitecture: string;
    function GetBridgeArchitecture: string;
    function GetAvailable: Boolean;
    procedure ConvertLazIntfImageToRGB(LIntfImg: TLazIntfImage; out ARGBData: Pointer; out AStride: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Initialize: Boolean;
    procedure FinalizeDetector;

    function DetectImageFile(const AFileName: string): Boolean;
    function DetectBitmap(ABitmap: TBitmap): Boolean;
    function DetectRGBBuffer(AData: Pointer; AWidth, AHeight, AStride: Integer): Boolean;

    function GetPoseCount: Integer;
    function GetLandmark(
      const APoseIndex: Integer;
      const ALandmarkId: TAIHumanPoseLandmarkId;
      out ALandmark: TAIHumanPoseLandmark
    ): Boolean;

    function GetLandmarkByIndex(
      const APoseIndex: Integer;
      const ALandmarkIndex: Integer;
      out ALandmark: TAIHumanPoseLandmark
    ): Boolean;

    procedure DrawResult(ACanvas: TCanvas; const ADestRect: TRect);
    procedure ClearResult;

    property Available: Boolean read GetAvailable;
    property LastError: string read FLastError;
    property LastOutput: string read FLastOutput;
    property LoadedBridgeDLLPath: string read FLoadedBridgeDLLPath;
    property LoadedModelFile: string read FLoadedModelFile;
    property BridgeVersionText: string read FBridgeVersionText;
    property BridgeAbiVersion: Integer read FBridgeAbiVersion;
    property LazarusArchitecture: string read GetLazarusArchitecture;
    property BridgeArchitecture: string read GetBridgeArchitecture;
    property DiagnosticLog: TStringList read FDiagnosticLog;
    property LastResultData: TAIHumanPoseResult read FLastResultData;
  published
    property BridgeDLLPath: string read FBridgeDLLPath write FBridgeDLLPath;
    property RuntimePath: string read FRuntimePath write FRuntimePath;
    property ModelFile: string read FModelFile write FModelFile;
    property Active: Boolean read FActive write SetActive default False;
    property LoadMode: TAIHumanPoseLoadMode read FLoadMode write FLoadMode default mplmAuto;
    property ExecutionMode: TAIHumanPoseExecutionMode read FExecutionMode write FExecutionMode default mpemDLL;
    property RequiredBridgeAbiVersion: Integer read FRequiredBridgeAbiVersion write FRequiredBridgeAbiVersion default 1;
    property RequiredMediaPipeVersion: string read FRequiredMediaPipeVersion write FRequiredMediaPipeVersion;
    property RunningMode: TAIHumanPoseRunningMode read FRunningMode write FRunningMode default hprImage;
    property NumPoses: Integer read FNumPoses write FNumPoses default 1;
    property MinPoseDetectionConfidence: Single read FMinPoseDetectionConfidence write FMinPoseDetectionConfidence;
    property MinPosePresenceConfidence: Single read FMinPosePresenceConfidence write FMinPosePresenceConfidence;
    property MinTrackingConfidence: Single read FMinTrackingConfidence write FMinTrackingConfidence;
    property OutputSegmentationMasks: Boolean read FOutputSegmentationMasks write FOutputSegmentationMasks default False;
    property ModelVariant: TAIHumanPoseModelVariant read FModelVariant write FModelVariant default hpmFull;
    property InputColorFormat: TAIHumanPoseColorFormat read FInputColorFormat write FInputColorFormat default hpcRGB;
    property DetectAllLandmarks: Boolean read FDetectAllLandmarks write FDetectAllLandmarks default True;
    property MinLandmarkVisibility: Single read FMinLandmarkVisibility write FMinLandmarkVisibility;
    property MinLandmarkPresence: Single read FMinLandmarkPresence write FMinLandmarkPresence;
    property IgnoreInvisibleLandmarks: Boolean read FIgnoreInvisibleLandmarks write FIgnoreInvisibleLandmarks default True;
    property DrawSkeleton: Boolean read FDrawSkeleton write FDrawSkeleton default True;
    property DrawLandmarkPoints: Boolean read FDrawLandmarkPoints write FDrawLandmarkPoints default True;
    property DrawLandmarkNames: Boolean read FDrawLandmarkNames write FDrawLandmarkNames default False;

    // Events
    property OnPoseDetected: TAIHumanPoseDetectedEvent read FOnPoseDetected write FOnPoseDetected;
    property OnError: TAIHumanPoseErrorEvent read FOnPoseError write FOnPoseError;
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

  HUMAN_POSE_CONNECTIONS: array[0..34] of record
    A: Integer;
    B: Integer;
  end = (
    (A: 11; B: 12), // shoulders
    (A: 11; B: 13),
    (A: 13; B: 15),
    (A: 12; B: 14),
    (A: 14; B: 16),
    (A: 11; B: 23),
    (A: 12; B: 24),
    (A: 23; B: 24),
    (A: 23; B: 25),
    (A: 25; B: 27),
    (A: 27; B: 29),
    (A: 29; B: 31),
    (A: 24; B: 26),
    (A: 26; B: 28),
    (A: 28; B: 30),
    (A: 30; B: 32),
    (A: 15; B: 17),
    (A: 15; B: 19),
    (A: 15; B: 21),
    (A: 16; B: 18),
    (A: 16; B: 20),
    (A: 16; B: 22),
    (A: 0; B: 1),
    (A: 1; B: 2),
    (A: 2; B: 3),
    (A: 0; B: 4),
    (A: 4; B: 5),
    (A: 5; B: 6),
    (A: 3; B: 7),
    (A: 6; B: 8),
    (A: 9; B: 10),
    (A: 0; B: 9),
    (A: 0; B: 10),
    (A: 7; B: 11),
    (A: 8; B: 12)
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
  FMinLandmarkVisibility := 0.5;
  FMinLandmarkPresence := 0.5;
  FIgnoreInvisibleLandmarks := True;

  FDrawSkeleton := True;
  FDrawLandmarkPoints := True;
  FDrawLandmarkNames := False;

  FDetectorHandle := nil;
  FDiagnosticLog := TStringList.Create;
  
  FillChar(FLastResultData, SizeOf(FLastResultData), 0);
  ClearResult;
end;

destructor TAIHumanPoseDetector.Destroy;
begin
  FinalizeDetector;
  FDiagnosticLog.Free;
  inherited Destroy;
end;

procedure TAIHumanPoseDetector.DoDiagnosticLog(const AMessage: string);
begin
  FDiagnosticLog.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz: ', Now) + AMessage);
  Log(llDebug, AMessage);
end;

function TAIHumanPoseDetector.GetLazarusArchitecture: string;
begin
  {$IFDEF CPU64}
  Result := '64-bit';
  {$ELSE}
  Result := '32-bit';
  {$ENDIF}
end;

function TAIHumanPoseDetector.GetBridgeArchitecture: string;
var
  LInfo: tmp_pose_info;
begin
  if MpPoseBridgeAvailable then
  begin
    FillChar(LInfo, SizeOf(LInfo), 0);
    LInfo.struct_size := SizeOf(LInfo);
    if mp_pose_get_info(@LInfo) = MP_OK then
      Result := string(LInfo.arch)
    else
      Result := 'Unknown';
  end
  else
    Result := 'Unknown';
end;

function TAIHumanPoseDetector.GetAvailable: Boolean;
var
  LInfo: tmp_pose_info;
begin
  Result := False;
  {$IFNDEF CPU64}
  Exit;
  {$ENDIF}

  if not MpPoseBridgeAvailable then
  begin
    // Attempt auto-load
    if not LoadMpPoseBridge(ExtractFilePath(ParamStr(0))) then
      Exit;
  end;

  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.struct_size := SizeOf(LInfo);
  if mp_pose_get_info(@LInfo) = MP_OK then
  begin
    Result := (LInfo.abi_version = MP_POSE_ABI_VERSION) and
              (string(LInfo.arch) = 'x86_64');
  end;
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
    FinalizeDetector;
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
    // Structure: runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/models/pose_landmarker_xxx.task
    LCandidate := LRuntimeRoot + 'pose' + DirectorySeparator + 'mp_' + StringReplace(FRequiredMediaPipeVersion, '.', '_', [rfReplaceAll]) +
                  DirectorySeparator;
    {$IFDEF MSWINDOWS}
      LCandidate := LCandidate + 'windows-x86_64' + DirectorySeparator;
    {$ELSE}
      LCandidate := LCandidate + 'linux-x86_64' + DirectorySeparator;
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

  // Resolve DLL name and folder structure dynamically based on OS (only 64-bit is supported)
  {$IFDEF MSWINDOWS}
    LDLLName := 'mp_pose_bridge.dll';
    LPlatformFolder := 'windows-x86_64' + DirectorySeparator;
  {$ELSE}
    LDLLName := 'libmp_pose_bridge.so';
    LPlatformFolder := 'linux-x86_64' + DirectorySeparator;
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
      // Try pose folder structure: runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/
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
    FLastError := 'MediaPipe Pose Bridge DLL não encontrada. Verifique BridgeDLLPath ou RuntimePath. DLL esperada: ' + LDLLName;
    DoDiagnosticLog(FLastError);
    Exit(False);
  end;

  if LoadMpPoseBridge(ExtractFilePath(LPath)) then
  begin
    FLoadedBridgeDLLPath := LPath;
    Result := True;
  end
  else
  begin
    FLastError := 'Erro ao carregar a biblioteca de ligação do MediaPipe Pose Bridge.';
    DoDiagnosticLog(FLastError);
  end;
end;

procedure TAIHumanPoseDetector.UnloadBridgeDLL;
begin
  UnloadMpPoseBridge;
  FLoadedBridgeDLLPath := '';
end;

function TAIHumanPoseDetector.Initialize: Boolean;
var
  LModel: string;
  LCfg: tmp_pose_config;
  LInfo: tmp_pose_info;
  Res: Integer;
begin
  FLastError := '';
  Result := False;
  DoDiagnosticLog('Initializing TAIHumanPoseDetector...');
  
  {$IFNDEF CPU64}
  FLastError := 'Plataforma 32-bit não suportada.';
  DoDiagnosticLog(FLastError);
  if Assigned(FOnPoseError) then
    FOnPoseError(Self, MP_ERR_UNSUPPORTED, FLastError);
  Exit;
  {$ENDIF}

  if not MpPoseBridgeAvailable then
  begin
    if not LoadBridgeDLL then
    begin
      if Assigned(FOnPoseError) then
        FOnPoseError(Self, MP_ERR_NOT_INITIALIZED, FLastError);
      Exit;
    end;
  end;

  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.struct_size := SizeOf(LInfo);
  Res := mp_pose_get_info(@LInfo);
  if Res <> MP_OK then
  begin
    FLastError := 'Falha ao obter metadados da bridge.';
    DoDiagnosticLog(FLastError);
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, Res, FLastError);
    Exit;
  end;

  if LInfo.abi_version <> MP_POSE_ABI_VERSION then
  begin
    FLastError := Format('Incompatibilidade de ABI. Esperada: %d, Obtida: %d', [MP_POSE_ABI_VERSION, LInfo.abi_version]);
    DoDiagnosticLog(FLastError);
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, MP_ERR_ABI_MISMATCH, FLastError);
    Exit;
  end;

  LModel := ResolveModelPath;
  DoDiagnosticLog('Model task file path: ' + LModel);
  if (LModel = '') or (not FileExists(LModel)) then
  begin
    FLastError := 'Modelo MediaPipe Pose Landmarker não encontrado.';
    DoDiagnosticLog(FLastError);
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, MP_ERR_MODEL_LOAD, FLastError);
    Exit;
  end;

  FLoadedModelFile := LModel;

  try
    FinalizeDetector;

    FillChar(LCfg, SizeOf(LCfg), 0);
    LCfg.struct_size := SizeOf(LCfg);
    LCfg.model_path := PAnsiChar(LModel);
    LCfg.running_mode := Integer(FRunningMode);
    LCfg.num_poses := FNumPoses;
    LCfg.min_pose_detection_confidence := FMinPoseDetectionConfidence;
    LCfg.min_pose_presence_confidence := FMinPosePresenceConfidence;
    LCfg.min_tracking_confidence := FMinTrackingConfidence;
    LCfg.output_segmentation_mask := Integer(FOutputSegmentationMasks);
    LCfg.num_threads := 0; // auto

    Res := mp_pose_create(@LCfg, @FDetectorHandle);
    if (Res = MP_OK) and (FDetectorHandle <> nil) then
    begin
      DoDiagnosticLog('Successfully created MediaPipe pose detector handle.');
      Result := True;
    end
    else
    begin
      FLastError := 'Failed to create detector instance: ' + string(mp_pose_last_error(FDetectorHandle));
      DoDiagnosticLog(FLastError);
      if Assigned(FOnPoseError) then
        FOnPoseError(Self, Res, FLastError);
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Failed to initialize MediaPipe Native: ' + E.Message;
      DoDiagnosticLog(FLastError);
      if Assigned(FOnPoseError) then
        FOnPoseError(Self, MP_ERR_BACKEND, FLastError);
    end;
  end;
end;

procedure TAIHumanPoseDetector.FinalizeDetector;
begin
  if FDetectorHandle <> nil then
  begin
    try
      mp_pose_destroy(FDetectorHandle);
    except
      // ignore
    end;
    FDetectorHandle := nil;
  end;
  UnloadBridgeDLL;
end;

function TAIHumanPoseDetector.DetectImageFile(const AFileName: string): Boolean;
var
  LBitmap: TBitmap;
begin
  Result := False;
  FLastError := '';
  if AFileName = '' then
  begin
    FLastError := 'Imagem não encontrada.';
    Exit;
  end;
  if not FileExists(AFileName) then
  begin
    FLastError := 'Imagem não encontrada: ' + AFileName;
    Exit;
  end;

  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromFile(AFileName);
    Result := DetectBitmap(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

procedure TAIHumanPoseDetector.ConvertLazIntfImageToRGB(LIntfImg: TLazIntfImage; out ARGBData: Pointer; out AStride: Integer);
var
  X, Y: Integer;
  POut: PByte;
  Col: TFPColor;
begin
  AStride := LIntfImg.Width * 3;
  GetMem(ARGBData, AStride * LIntfImg.Height);
  POut := PByte(ARGBData);
  for Y := 0 to LIntfImg.Height - 1 do
  begin
    for X := 0 to LIntfImg.Width - 1 do
    begin
      Col := LIntfImg.Colors[X, Y];
      POut[0] := Col.red shr 8;   // R
      POut[1] := Col.green shr 8; // G
      POut[2] := Col.blue shr 8;  // B
      Inc(POut, 3);
    end;
  end;
end;

function TAIHumanPoseDetector.DetectBitmap(ABitmap: TBitmap): Boolean;
var
  LIntfImg: TLazIntfImage;
  RGBData: Pointer;
  LStride: Integer;
begin
  Result := False;
  FLastError := '';
  ClearResult;

  if not Assigned(ABitmap) or (ABitmap.Width <= 0) or (ABitmap.Height <= 0) then
  begin
    FLastError := 'Imagem não encontrada ou inválida.';
    Exit;
  end;

  if (FDetectorHandle = nil) or (not MpPoseBridgeAvailable) then
  begin
    FLastError := 'Detector não inicializado.';
    Exit;
  end;

  LIntfImg := TLazIntfImage.Create(0, 0);
  RGBData := nil;
  try
    LIntfImg.LoadFromBitmap(ABitmap.Handle, ABitmap.MaskHandle);
    ConvertLazIntfImageToRGB(LIntfImg, RGBData, LStride);
    
    Result := DetectRGBBuffer(RGBData, LIntfImg.Width, LIntfImg.Height, LStride);
  finally
    if Assigned(RGBData) then
      FreeMem(RGBData);
    LIntfImg.Free;
  end;
end;

function TAIHumanPoseDetector.DetectRGBBuffer(AData: Pointer; AWidth, AHeight, AStride: Integer): Boolean;
var
  LImg: tmp_image_raw;
  LLastResultPtr: Pmp_pose_result;
  Res: Integer;
  I, J, LIdx: Integer;
begin
  Result := False;
  FLastError := '';
  ClearResult;

  if not Assigned(AData) then
  begin
    FLastError := 'Buffer de dados inválido.';
    Exit;
  end;

  if (FDetectorHandle = nil) or (not MpPoseBridgeAvailable) then
  begin
    FLastError := 'Detector não inicializado.';
    Exit;
  end;

  try
    FillChar(LImg, SizeOf(LImg), 0);
    LImg.struct_size := SizeOf(LImg);
    LImg.data := PByte(AData);
    LImg.width := AWidth;
    LImg.height := AHeight;
    LImg.channels := 3; // RGB packed
    LImg.stride := AStride;
    LImg.timestamp_ms := 0; // Monotonic frame timestamp

    LLastResultPtr := nil;
    Res := mp_pose_detect(FDetectorHandle, @LImg, @LLastResultPtr);
    if (Res = MP_OK) and (LLastResultPtr <> nil) then
    begin
      // Map C struct results to Lazarus record structure
      FLastResultData.PoseCount := LLastResultPtr^.pose_count;
      if FLastResultData.PoseCount > AI_HUMAN_POSE_MAX_POSES then
        FLastResultData.PoseCount := AI_HUMAN_POSE_MAX_POSES;

      for I := 0 to FLastResultData.PoseCount - 1 do
      begin
        FLastResultData.Poses[I].LandmarkCount := LLastResultPtr^.landmarks_per_pose;
        for J := 0 to LLastResultPtr^.landmarks_per_pose - 1 do
        begin
          if J < AI_HUMAN_POSE_LANDMARK_COUNT then
          begin
            LIdx := I * LLastResultPtr^.landmarks_per_pose + J;
            FLastResultData.Poses[I].Landmarks[J].X := LLastResultPtr^.landmarks[LIdx].x;
            FLastResultData.Poses[I].Landmarks[J].Y := LLastResultPtr^.landmarks[LIdx].y;
            FLastResultData.Poses[I].Landmarks[J].Z := LLastResultPtr^.landmarks[LIdx].z;
            FLastResultData.Poses[I].Landmarks[J].Visibility := LLastResultPtr^.landmarks[LIdx].visibility;
            FLastResultData.Poses[I].Landmarks[J].Presence := LLastResultPtr^.landmarks[LIdx].presence;

            FLastResultData.Poses[I].WorldLandmarks[J].X := LLastResultPtr^.world_landmarks[LIdx].x;
            FLastResultData.Poses[I].WorldLandmarks[J].Y := LLastResultPtr^.world_landmarks[LIdx].y;
            FLastResultData.Poses[I].WorldLandmarks[J].Z := LLastResultPtr^.world_landmarks[LIdx].z;
            FLastResultData.Poses[I].WorldLandmarks[J].Visibility := 0.0;
            FLastResultData.Poses[I].WorldLandmarks[J].Presence := 0.0;
          end;
        end;
      end;

      mp_pose_free_result(LLastResultPtr);

      if FLastResultData.PoseCount > 0 then
      begin
        FLastOutput := Format('DetectRGBBuffer succeeded. Poses found: %d', [FLastResultData.PoseCount]);
        if Assigned(FOnPoseDetected) then
          FOnPoseDetected(Self, FLastResultData);
        Result := True;
      end
      else
        FLastError := 'Nenhuma pose humana foi detectada.';
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Erro ao executar detecção de buffer: ' + E.Message;
      if Assigned(FOnPoseError) then
        FOnPoseError(Self, MP_ERR_INFERENCE, FLastError);
    end;
  end;
end;

function TAIHumanPoseDetector.GetPoseCount: Integer;
begin
  Result := FLastResultData.PoseCount;
end;

function TAIHumanPoseDetector.GetLandmark(
  const APoseIndex: Integer;
  const ALandmarkId: TAIHumanPoseLandmarkId;
  out ALandmark: TAIHumanPoseLandmark
): Boolean;
begin
  Result := GetLandmarkByIndex(APoseIndex, Integer(ALandmarkId), ALandmark);
end;

function TAIHumanPoseDetector.GetLandmarkByIndex(
  const APoseIndex: Integer;
  const ALandmarkIndex: Integer;
  out ALandmark: TAIHumanPoseLandmark
): Boolean;
begin
  Result := False;
  if (APoseIndex < 0) or (APoseIndex >= FLastResultData.PoseCount) then
  begin
    FLastError := 'PoseIndex inválido.';
    Exit;
  end;

  if (ALandmarkIndex < 0) or (ALandmarkIndex >= AI_HUMAN_POSE_LANDMARK_COUNT) then
  begin
    FLastError := 'Landmark fora do intervalo.';
    Exit;
  end;

  ALandmark := FLastResultData.Poses[APoseIndex].Landmarks[ALandmarkIndex];
  Result := True;
end;

procedure TAIHumanPoseDetector.DrawResult(ACanvas: TCanvas; const ADestRect: TRect);
  procedure DrawLine(Idx1, Idx2: Integer);
  var
    P1, P2: TPoint;
    LWidth, LHeight: Integer;
  begin
    LWidth := ADestRect.Right - ADestRect.Left;
    LHeight := ADestRect.Bottom - ADestRect.Top;
    P1.X := ADestRect.Left + Round(FLastResultData.Poses[0].Landmarks[Idx1].X * LWidth);
    P1.Y := ADestRect.Top + Round(FLastResultData.Poses[0].Landmarks[Idx1].Y * LHeight);
    P2.X := ADestRect.Left + Round(FLastResultData.Poses[0].Landmarks[Idx2].X * LWidth);
    P2.Y := ADestRect.Top + Round(FLastResultData.Poses[0].Landmarks[Idx2].Y * LHeight);
    ACanvas.Line(P1, P2);
  end;

  procedure DrawPoint(Idx: Integer);
  var
    P: TPoint;
    LWidth, LHeight: Integer;
  begin
    LWidth := ADestRect.Right - ADestRect.Left;
    LHeight := ADestRect.Bottom - ADestRect.Top;
    P.X := ADestRect.Left + Round(FLastResultData.Poses[0].Landmarks[Idx].X * LWidth);
    P.Y := ADestRect.Top + Round(FLastResultData.Poses[0].Landmarks[Idx].Y * LHeight);
    ACanvas.Ellipse(P.X - 4, P.Y - 4, P.X + 4, P.Y + 4);
    if FDrawLandmarkNames then
    begin
      ACanvas.TextOut(P.X + 6, P.Y - 6, LANDMARK_NAMES[Idx]);
    end;
  end;

var
  I: Integer;
begin
  if FLastResultData.PoseCount <= 0 then Exit;

  ACanvas.Pen.Color := clGreen;
  ACanvas.Pen.Width := 2;
  ACanvas.Brush.Color := clLime;

  if FDrawSkeleton then
  begin
    for I := Low(HUMAN_POSE_CONNECTIONS) to High(HUMAN_POSE_CONNECTIONS) do
    begin
      DrawLine(HUMAN_POSE_CONNECTIONS[I].A, HUMAN_POSE_CONNECTIONS[I].B);
    end;
  end;

  if FDrawLandmarkPoints then
  begin
    for I := 0 to 32 do
      DrawPoint(I);
  end;
end;

procedure TAIHumanPoseDetector.ClearResult;
begin
  FillChar(FLastResultData, SizeOf(FLastResultData), 0);
  FLastResultData.PoseCount := 0;
end;

initialization
  {$I aihumanposedetector_icon.lrs}

end.
