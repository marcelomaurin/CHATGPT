unit aihumanposedetector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, fpjson, jsonparser, FileUtil,
  aiplatform, airuntimepaths, aihumanpose_types, Math, LResources,
  IntfGraphics, GraphType, FPImage
  {$IFDEF CPU64}
  , mp_pose_bridge
  {$ENDIF}
  ;

{ ============================================================
  Constantes do componente — fonte única de verdade (FASE5)
  Definidas fora de qualquer {$IFDEF} para que compilem em 32-bit.
  Em CPU64 os Assert no bloco initialization verificam coerência com a ABI.
  ============================================================ }
const
  HUMAN_POSE_OK                  = 0;
  HUMAN_POSE_ERR_ABI_MISMATCH    = 1;
  HUMAN_POSE_ERR_BAD_ARG         = 2;
  HUMAN_POSE_ERR_MODEL_LOAD      = 3;
  HUMAN_POSE_ERR_NOT_INITIALIZED = 4;
  HUMAN_POSE_ERR_INFERENCE       = 5;
  HUMAN_POSE_ERR_UNSUPPORTED     = 6;
  HUMAN_POSE_ERR_OUT_OF_MEMORY   = 7;
  HUMAN_POSE_ERR_BACKEND         = 8;

  HUMAN_POSE_ABI_VERSION         = 1;

  { Versão MediaPipe esperada — única constante; usada em ResolveModelPath
    e no campo FRequiredMediaPipeVersion do componente. }
  HUMAN_POSE_MP_VERSION          = '0.10.35';

type
  TAIHumanPoseDetectedEvent = procedure(Sender: TObject; const AResult: TAIHumanPoseResult) of object;
  TAIHumanPoseErrorEvent    = procedure(Sender: TObject; ACode: Integer; const AMsg: string) of object;

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

    { Diagnóstico e saída }
    FLastOutput: string;
    FLoadedBridgeDLLPath: string;
    FLoadedModelFile: string;
    FBridgeVersionText: string;
    FBridgeAbiVersion: Integer;
    FBridgeBackend: string;               { "SIM" | "REAL" | "UNKNOWN" }
    FRequiredMediaPipeVersionRead: string; { preenchido por mp_pose_get_info }
    FDiagnosticLog: TStringList;

    { Eventos }
    FOnPoseDetected: TAIHumanPoseDetectedEvent;
    FOnPoseError: TAIHumanPoseErrorEvent;

    { Handle interno da DLL }
    {$IFDEF CPU64}
    FDetectorHandle: mp_pose_handle;
    {$ELSE}
    FDetectorHandle: Pointer;
    {$ENDIF}
    FLastResultData: TAIHumanPoseResult;

    procedure SetActive(const AValue: Boolean);
    function  LoadBridgeDLL: Boolean;
    procedure UnloadBridgeDLL;
    function  ResolveModelPath: string;
    procedure DoDiagnosticLog(const AMessage: string);
    function  GetLazarusArchitecture: string;
    function  GetBridgeArchitecture: string;
    function  GetInitialized: Boolean;
    function  GetAvailable: Boolean;
    procedure ConvertLazIntfImageToRGB(LIntfImg: TLazIntfImage;
                out ARGBData: Pointer; out AStride: Integer);

    { FASE5-01: destrói apenas o handle, sem descarregar a DLL }
    procedure DestroyDetectorHandleOnly;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    { FASE5-01: ciclo de vida limpo }
    function  Initialize: Boolean;
    procedure FinalizeDetector;

    function DetectImageFile(const AFileName: string): Boolean;
    function DetectBitmap(ABitmap: TBitmap): Boolean;
    function DetectRGBBuffer(AData: Pointer; AWidth, AHeight, AStride: Integer): Boolean;

    function GetPoseCount: Integer;
    function GetLandmark(const APoseIndex: Integer;
                         const ALandmarkId: TAIHumanPoseLandmarkId;
                         out ALandmark: TAIHumanPoseLandmark): Boolean;
    function GetLandmarkByIndex(const APoseIndex: Integer;
                                const ALandmarkIndex: Integer;
                                out ALandmark: TAIHumanPoseLandmark): Boolean;

    procedure DrawResult(ACanvas: TCanvas; const ADestRect: TRect);
    procedure ClearResult;

    property Available: Boolean read GetAvailable;
    property LastError: string read FLastError;
    property LastOutput: string read FLastOutput;
    property LoadedBridgeDLLPath: string read FLoadedBridgeDLLPath;
    property LoadedModelFile: string read FLoadedModelFile;
    property BridgeVersionText: string read FBridgeVersionText;
    property BridgeAbiVersion: Integer read FBridgeAbiVersion;
    property BridgeBackend: string read FBridgeBackend;
    property Initialized: Boolean read GetInitialized;
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
    property OnPoseDetected: TAIHumanPoseDetectedEvent read FOnPoseDetected write FOnPoseDetected;
    property OnError: TAIHumanPoseErrorEvent read FOnPoseError write FOnPoseError;
  end;

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

  HUMAN_POSE_CONNECTIONS: array[0..34] of record A, B: Integer; end = (
    (A:11; B:12),(A:11; B:13),(A:13; B:15),(A:12; B:14),(A:14; B:16),
    (A:11; B:23),(A:12; B:24),(A:23; B:24),(A:23; B:25),(A:25; B:27),
    (A:27; B:29),(A:29; B:31),(A:24; B:26),(A:26; B:28),(A:28; B:30),
    (A:30; B:32),(A:15; B:17),(A:15; B:19),(A:15; B:21),(A:16; B:18),
    (A:16; B:20),(A:16; B:22),(A: 0; B: 1),(A: 1; B: 2),(A: 2; B: 3),
    (A: 0; B: 4),(A: 4; B: 5),(A: 5; B: 6),(A: 3; B: 7),(A: 6; B: 8),
    (A: 9; B:10),(A: 0; B: 9),(A: 0; B:10),(A: 7; B:11),(A: 8; B:12)
  );

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIHumanPoseDetector]);
end;

{ TAIHumanPoseDetector }

constructor TAIHumanPoseDetector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FPrompt   := 'Component TAIHumanPoseDetector processes body pose estimation '
             + 'via native versioned MediaPipe C/C++ Bridge.';

  FBridgeDLLPath              := '';
  FRuntimePath                := '';
  FModelFile                  := '';
  FActive                     := False;
  FLoadMode                   := mplmAuto;
  FExecutionMode              := mpemDLL;
  FRequiredBridgeAbiVersion   := HUMAN_POSE_ABI_VERSION;
  FRequiredMediaPipeVersion   := HUMAN_POSE_MP_VERSION;
  FRunningMode                := hprImage;
  FNumPoses                   := 1;
  FMinPoseDetectionConfidence := 0.5;
  FMinPosePresenceConfidence  := 0.5;
  FMinTrackingConfidence      := 0.5;
  FOutputSegmentationMasks    := False;
  FModelVariant               := hpmFull;
  FInputColorFormat           := hpcRGB;
  FDetectAllLandmarks         := True;
  FMinLandmarkVisibility      := 0.5;
  FMinLandmarkPresence        := 0.5;
  FIgnoreInvisibleLandmarks   := True;
  FDrawSkeleton               := True;
  FDrawLandmarkPoints         := True;
  FDrawLandmarkNames          := False;

  FBridgeBackend := 'UNKNOWN';
  FDetectorHandle := nil;
  FDiagnosticLog  := TStringList.Create;

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
  FDiagnosticLog.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ': ' + AMessage);
  Log(llDebug, AMessage);
end;

{ ============================================================
  FASE5-01 — Separar destruição do handle do descarregamento da DLL
  ============================================================ }

procedure TAIHumanPoseDetector.DestroyDetectorHandleOnly;
begin
  {$IFDEF CPU64}
  { Proteção real: teste de nil + Assigned.
    Sem try/except: exceção de função cdecl não vira exceção Pascal de forma confiável. }
  if (FDetectorHandle <> nil) and Assigned(mp_pose_destroy) then
  begin
    mp_pose_destroy(FDetectorHandle);
    FDetectorHandle := nil;   { destruição única }
  end;
  {$ELSE}
  FDetectorHandle := nil;
  {$ENDIF}
end;

procedure TAIHumanPoseDetector.FinalizeDetector;
begin
  DestroyDetectorHandleOnly;
  UnloadBridgeDLL;
end;

{ ============================================================
  Arquitetura e disponibilidade
  ============================================================ }

function TAIHumanPoseDetector.GetLazarusArchitecture: string;
begin
  {$IFDEF CPU64}
  Result := '64-bit';
  {$ELSE}
  Result := '32-bit';
  {$ENDIF}
end;

function TAIHumanPoseDetector.GetBridgeArchitecture: string;
{$IFDEF CPU64}
var
  LInfo: tmp_pose_info;
{$ENDIF}
begin
  Result := 'Unknown';
  {$IFDEF CPU64}
  if MpPoseBridgeAvailable then
  begin
    FillChar(LInfo, SizeOf(LInfo), 0);
    LInfo.struct_size := SizeOf(LInfo);
    if mp_pose_get_info(@LInfo) = HUMAN_POSE_OK then
      Result := string(LInfo.arch);
  end;
  {$ENDIF}
end;

{ FASE5-04 — Available usa a mesma lógica de carregamento }
function TAIHumanPoseDetector.GetInitialized: Boolean;
begin
  {$IFDEF CPU64}
  Result := (FDetectorHandle <> nil);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function TAIHumanPoseDetector.GetAvailable: Boolean;
{$IFDEF CPU64}
var
  LInfo: tmp_pose_info;
{$ENDIF}
begin
  Result := False;
  {$IFDEF CPU64}
  if not MpPoseBridgeAvailable then
    if not LoadBridgeDLL then Exit(False);

  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.struct_size := SizeOf(LInfo);
  Result :=
    (mp_pose_get_info(@LInfo) = HUMAN_POSE_OK) and
    (LInfo.abi_version = HUMAN_POSE_ABI_VERSION) and
    (string(LInfo.arch) = 'x86_64');
  {$ELSE}
  FLastError := 'Plataforma 32-bit não suportada (somente x86_64).';
  {$ENDIF}
end;

{ ============================================================
  FASE5-03 — LoadBridgeDLL com prioridade de busca
  1. BridgeDLLPath (mplmManualPath)
  2. RuntimePath (quando informado)
  3. Runtime relativo ao EXE: runtime/mediapipe/pose/<MP_VERSION>/<os>-x86_64/
  4. Pasta do executável
  5. Resolução do loader do SO
  ============================================================ }
function TAIHumanPoseDetector.LoadBridgeDLL: Boolean;
var
  LVersionedDLLName, LLegacyDLLName, LPlatformFolder, LBase, LCandidateDir,
  LPath: string;
  I: Integer;
begin
  Result := False;
  {$IFDEF CPU64}
  UnloadBridgeDLL;

  {$IFDEF MSWINDOWS}
  LVersionedDLLName := GetExpectedBridgeLibName;
  LLegacyDLLName := GetLegacyBridgeLibName;
  LPlatformFolder := 'windows-x86_64' + DirectorySeparator;
  {$ELSE}
  LVersionedDLLName := GetExpectedBridgeLibName;
  LLegacyDLLName := GetLegacyBridgeLibName;
  LPlatformFolder := 'linux-x86_64' + DirectorySeparator;
  {$ENDIF}

  { 1. BridgeDLLPath (mplmManualPath) }
  if (FLoadMode = mplmManualPath) and (FBridgeDLLPath <> '') then
  begin
    if FileExists(FBridgeDLLPath) then
      LPath := FBridgeDLLPath
    else
    begin
      LPath := AICombinePath(FBridgeDLLPath, LVersionedDLLName);
      if not FileExists(LPath) then
        LPath := AICombinePath(FBridgeDLLPath, LLegacyDLLName);
    end;
  end
  else
  begin
    LPath := '';

    { 2. RuntimePath (quando informado) }
    if FRuntimePath <> '' then
    begin
      LCandidateDir := AICombinePath(FRuntimePath, LPlatformFolder);
      if DirectoryExists(LCandidateDir) then
      begin
        LPath := AICombinePath(LCandidateDir, LVersionedDLLName);
        if not FileExists(LPath) then
          LPath := AICombinePath(LCandidateDir, LLegacyDLLName);
      end;
      if (LPath = '') or not FileExists(LPath) then
      begin
        LPath := AICombinePath(FRuntimePath, LVersionedDLLName);
        if not FileExists(LPath) then
          LPath := AICombinePath(FRuntimePath, LLegacyDLLName);
        if not FileExists(LPath) then LPath := '';
      end;
    end;

    { 3. Runtime relativo ao EXE }
    if (LPath = '') or not FileExists(LPath) then
    begin
      LBase := ExtractFilePath(ParamStr(0));
      for I := 0 to 5 do
      begin
        LCandidateDir := AICombinePath(LBase,
          'runtime' + DirectorySeparator + 'mediapipe' + DirectorySeparator +
          'pose' + DirectorySeparator + 'mp_' +
          StringReplace(HUMAN_POSE_MP_VERSION, '.', '_', [rfReplaceAll]) +
          DirectorySeparator + LPlatformFolder);
        if DirectoryExists(LCandidateDir) then
        begin
          LPath := AICombinePath(LCandidateDir, LVersionedDLLName);
          if not FileExists(LPath) then
            LPath := AICombinePath(LCandidateDir, LLegacyDLLName);
          if FileExists(LPath) then Break;
          LPath := '';
        end;
        LBase := AICombinePath(LBase, '..' + DirectorySeparator);
      end;
    end;

    { 4. Pasta do executável }
    if (LPath = '') or not FileExists(LPath) then
    begin
      LPath := AICombinePath(ExtractFilePath(ParamStr(0)), LVersionedDLLName);
      if not FileExists(LPath) then
        LPath := AICombinePath(ExtractFilePath(ParamStr(0)), LLegacyDLLName);
    end;
  end;

  DoDiagnosticLog('Resolving MediaPipe bridge: ' + LPath);

  if not FileExists(LPath) then
  begin
    FLastError := 'Bridge DLL não encontrada. '
                + 'Verifique BridgeDLLPath ou RuntimePath. '
                + 'Esperada: ' + LVersionedDLLName
                + ' (fallback legado: ' + LLegacyDLLName + ')'
                + ' | Último caminho testado: ' + LPath;
    DoDiagnosticLog(FLastError);
    Exit(False);
  end;

  if LoadMpPoseBridge(LPath) then
  begin
    FLoadedBridgeDLLPath := LPath;
    DoDiagnosticLog('Bridge carregada: ' + LPath);
    Result := True;
  end
  else
  begin
    FLastError := 'Falha ao carregar a bridge MediaPipe Pose: ' + LPath;
    if GetLastBridgeLoadError <> '' then
      FLastError := FLastError + ' | ' + GetLastBridgeLoadError;
    DoDiagnosticLog(FLastError);
  end;
  {$ELSE}
  FLastError := 'Plataforma 32-bit não suportada (somente x86_64).';
  {$ENDIF}
end;

procedure TAIHumanPoseDetector.UnloadBridgeDLL;
begin
  {$IFDEF CPU64}
  UnloadMpPoseBridge;
  {$ENDIF}
  FLoadedBridgeDLLPath := '';
  FLoadedModelFile := '';
  FBridgeVersionText := '';
  FBridgeAbiVersion := 0;
  FBridgeBackend := 'UNKNOWN';
  FRequiredMediaPipeVersionRead := '';
  FActive := False;
end;

{ ============================================================
  Resolução do caminho do modelo
  ============================================================ }
function TAIHumanPoseDetector.ResolveModelPath: string;
var
  LBase, LRuntimeRoot, LCandidate: string;
  I: Integer;

  function BuildModelPath(const ABaseDir: string): string;
  begin
    case FModelVariant of
      hpmLite:
        if SameText(FBridgeBackend, 'REAL') then
          Result := IncludeTrailingPathDelimiter(ABaseDir) + 'models' + DirectorySeparator + 'pose_landmarker_full.task'
        else
          Result := IncludeTrailingPathDelimiter(ABaseDir) + 'models' + DirectorySeparator + 'pose_landmarker_lite.task';
      hpmHeavy:
        if SameText(FBridgeBackend, 'REAL') then
          Result := IncludeTrailingPathDelimiter(ABaseDir) + 'models' + DirectorySeparator + 'pose_landmarker_full.task'
        else
          Result := IncludeTrailingPathDelimiter(ABaseDir) + 'models' + DirectorySeparator + 'pose_landmarker_heavy.task';
    else
      Result := IncludeTrailingPathDelimiter(ABaseDir) + 'models' + DirectorySeparator + 'pose_landmarker_full.task';
    end;
  end;

  function TryRuntimeBase(const ABaseDir: string): string;
  begin
    Result := '';
    if ABaseDir = '' then Exit;
    Result := BuildModelPath(ABaseDir);
    if not FileExists(Result) then
      Result := '';
  end;
begin
  Result := '';

  if FModelFile <> '' then
  begin
    if FileExists(FModelFile) then Exit(FModelFile);
  end;

  if FLoadedBridgeDLLPath <> '' then
  begin
    Result := TryRuntimeBase(ExtractFilePath(FLoadedBridgeDLLPath));
    if Result <> '' then Exit;
  end;

  if FRuntimePath <> '' then
  begin
    {$IFDEF MSWINDOWS}
    Result := TryRuntimeBase(AICombinePath(FRuntimePath, 'windows-x86_64' + DirectorySeparator));
    if Result <> '' then Exit;
    {$ELSE}
    Result := TryRuntimeBase(AICombinePath(FRuntimePath, 'linux-x86_64' + DirectorySeparator));
    if Result <> '' then Exit;
    {$ENDIF}

    Result := TryRuntimeBase(FRuntimePath);
    if Result <> '' then Exit;
  end;

  LBase        := ExtractFilePath(ParamStr(0));
  LRuntimeRoot := '';
  for I := 0 to 5 do
  begin
    LCandidate := AICombinePath(LBase,
      'runtime' + DirectorySeparator + 'mediapipe' + DirectorySeparator);
    if DirectoryExists(LCandidate) then
    begin
      LRuntimeRoot := LCandidate;
      Break;
    end;
    LBase := AICombinePath(LBase, '..' + DirectorySeparator);
  end;

  if LRuntimeRoot = '' then Exit;

  LCandidate := LRuntimeRoot + 'pose' + DirectorySeparator
              + 'mp_' + StringReplace(HUMAN_POSE_MP_VERSION, '.', '_', [rfReplaceAll])
              + DirectorySeparator;
  {$IFDEF MSWINDOWS}
  LCandidate := LCandidate + 'windows-x86_64' + DirectorySeparator;
  {$ELSE}
  LCandidate := LCandidate + 'linux-x86_64' + DirectorySeparator;
  {$ENDIF}

  Result := BuildModelPath(LCandidate);
end;

{ ============================================================
  Initialize
  FASE5-01: usa DestroyDetectorHandleOnly (não FinalizeDetector)
  FASE5-05: modelo exigido apenas para backend REAL
  FASE5-06: preenche metadados após mp_pose_get_info
  ============================================================ }
function TAIHumanPoseDetector.Initialize: Boolean;
{$IFDEF CPU64}
var
  LModel: string;
  LCfg: tmp_pose_config;
  LInfo: tmp_pose_info;
  Res: Integer;
{$ENDIF}
begin
  FLastError := '';
  Result := False;
  FActive := False;
  DoDiagnosticLog('Initializing TAIHumanPoseDetector...');

  {$IFNDEF CPU64}
  FLastError := 'Plataforma 32-bit não suportada (somente x86_64).';
  DoDiagnosticLog(FLastError);
  if Assigned(FOnPoseError) then
    FOnPoseError(Self, HUMAN_POSE_ERR_UNSUPPORTED, FLastError);
  {$ELSE}

  { Carregar DLL se ainda não estiver carregada }
  if not MpPoseBridgeAvailable then
    if not LoadBridgeDLL then
    begin
      if Assigned(FOnPoseError) then
        FOnPoseError(Self, HUMAN_POSE_ERR_NOT_INITIALIZED, FLastError);
      Exit;
    end;

  { Obter metadados da bridge }
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.struct_size := SizeOf(LInfo);
  Res := mp_pose_get_info(@LInfo);
  if Res <> HUMAN_POSE_OK then
  begin
    FLastError := 'Falha ao obter metadados da bridge.';
    DoDiagnosticLog(FLastError);
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, Res, FLastError);
    Exit;
  end;

  { Verificar ABI }
  if LInfo.abi_version <> HUMAN_POSE_ABI_VERSION then
  begin
    FLastError := Format('Incompatibilidade de ABI. Esperada: %d, Obtida: %d',
                         [HUMAN_POSE_ABI_VERSION, LInfo.abi_version]);
    DoDiagnosticLog(FLastError);
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, HUMAN_POSE_ERR_ABI_MISMATCH, FLastError);
    Exit;
  end;

  { FASE5-06: preencher metadados }
  FBridgeAbiVersion          := LInfo.abi_version;
  FBridgeVersionText         := string(LInfo.bridge_version);
  FRequiredMediaPipeVersionRead := string(LInfo.mediapipe_version);
  if LInfo.struct_size >= SizeOf(LInfo) then  { campo backend presente }
    FBridgeBackend := string(LInfo.backend)
  else
    FBridgeBackend := 'UNKNOWN';
  if FBridgeBackend = '' then FBridgeBackend := 'UNKNOWN';

  DoDiagnosticLog(Format('DLL carregada | ABI: %d | Bridge: %s | Backend: %s | MediaPipe: %s | Arch: %s',
    [LInfo.abi_version, string(LInfo.bridge_version),
     FBridgeBackend, string(LInfo.mediapipe_version), string(LInfo.arch)]));

  { FASE5-05: modelo obrigatório apenas para REAL }
  FillChar(LCfg, SizeOf(LCfg), 0);
  LCfg.struct_size := SizeOf(LCfg);

  if FBridgeBackend = 'REAL' then
  begin
    if FModelVariant <> hpmFull then
      DoDiagnosticLog('Backend REAL ativo: pose_landmarker_full.task será usado independentemente da variante selecionada.');
    LModel := ResolveModelPath;
    DoDiagnosticLog('Model task file: ' + LModel);
    if (LModel = '') or not FileExists(LModel) then
    begin
      FLastError := 'Modelo MediaPipe Pose Landmarker não encontrado '
                  + '(backend REAL exige pose_landmarker_full.task).';
      DoDiagnosticLog(FLastError);
      if Assigned(FOnPoseError) then
        FOnPoseError(Self, HUMAN_POSE_ERR_MODEL_LOAD, FLastError);
      Exit;
    end;
    FLoadedModelFile   := LModel;
    LCfg.model_path    := PAnsiChar(AnsiString(LModel));
  end
  else
  begin
    { SIM: modelo não necessário }
    FLoadedModelFile := '';
    LCfg.model_path  := nil;
    DoDiagnosticLog('Backend SIM — modelo não necessário.');
  end;

  LCfg.running_mode                   := Integer(FRunningMode);
  LCfg.num_poses                      := FNumPoses;
  LCfg.min_pose_detection_confidence  := FMinPoseDetectionConfidence;
  LCfg.min_pose_presence_confidence   := FMinPosePresenceConfidence;
  LCfg.min_tracking_confidence        := FMinTrackingConfidence;
  LCfg.output_segmentation_mask       := Integer(FOutputSegmentationMasks);
  LCfg.num_threads                    := 0; { automático }

  { FASE5-01: DestroyDetectorHandleOnly — DLL permanece carregada }
  DestroyDetectorHandleOnly;

  Res := mp_pose_create(@LCfg, @FDetectorHandle);
  if (Res = HUMAN_POSE_OK) and (FDetectorHandle <> nil) then
  begin
    DoDiagnosticLog('Handle do detector criado com sucesso.');
    Result := True;
    FActive := True;
  end
  else
  begin
    if Assigned(mp_pose_last_error) then
      FLastError := 'Falha ao criar detector: ' + string(mp_pose_last_error(nil))
    else
      FLastError := Format('Falha ao criar detector. Código: %d', [Res]);
    DoDiagnosticLog(FLastError);
    FDetectorHandle := nil;
    FActive := False;
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, Res, FLastError);
  end;
  {$ENDIF}
end;

procedure TAIHumanPoseDetector.SetActive(const AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
  begin
    if Initialize then FActive := True;
  end
  else
  begin
    FinalizeDetector;
    FActive := False;
  end;
end;

{ ============================================================
  Detecção
  ============================================================ }

function TAIHumanPoseDetector.DetectImageFile(const AFileName: string): Boolean;
var
  LBitmap: TBitmap;
begin
  Result := False;
  {$IFDEF CPU64}
  FLastError := '';
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
  {$ELSE}
  FLastError := 'Plataforma 32-bit não suportada (somente x86_64).';
  {$ENDIF}
end;

procedure TAIHumanPoseDetector.ConvertLazIntfImageToRGB(
  LIntfImg: TLazIntfImage; out ARGBData: Pointer; out AStride: Integer);
var
  X, Y: Integer;
  POut: PByte;
  Col: TFPColor;
begin
  AStride := LIntfImg.Width * 3;
  GetMem(ARGBData, AStride * LIntfImg.Height);
  POut := PByte(ARGBData);
  for Y := 0 to LIntfImg.Height - 1 do
    for X := 0 to LIntfImg.Width - 1 do
    begin
      Col    := LIntfImg.Colors[X, Y];
      POut[0] := Col.red   shr 8;
      POut[1] := Col.green shr 8;
      POut[2] := Col.blue  shr 8;
      Inc(POut, 3);
    end;
end;

function TAIHumanPoseDetector.DetectBitmap(ABitmap: TBitmap): Boolean;
var
  LIntfImg: TLazIntfImage;
  RGBData: Pointer;
  LStride: Integer;
begin
  Result := False;
  {$IFDEF CPU64}
  FLastError := '';
  ClearResult;

  if not Assigned(ABitmap) or (ABitmap.Width <= 0) or (ABitmap.Height <= 0) then
  begin
    FLastError := 'Imagem inválida ou dimensões zero.';
    Exit;
  end;

  if (FDetectorHandle = nil) or not MpPoseBridgeAvailable then
  begin
    FLastError := 'Detector não inicializado. Chame Initialize primeiro.';
    Exit;
  end;

  LIntfImg := TLazIntfImage.Create(0, 0);
  RGBData  := nil;
  try
    LIntfImg.LoadFromBitmap(ABitmap.Handle, ABitmap.MaskHandle);
    ConvertLazIntfImageToRGB(LIntfImg, RGBData, LStride);
    Result := DetectRGBBuffer(RGBData, LIntfImg.Width, LIntfImg.Height, LStride);
  finally
    if Assigned(RGBData) then FreeMem(RGBData);
    LIntfImg.Free;
  end;
  {$ELSE}
  FLastError := 'Plataforma 32-bit não suportada (somente x86_64).';
  {$ENDIF}
end;

{ ============================================================
  FASE5-08 — DetectRGBBuffer
  - Sem try/except ao redor do cdecl
  - Lê erro via mp_pose_last_error quando Res <> OK
  - Libera resultado com mp_pose_free_result (var Pmp_pose_result) → zera ponteiro
  ============================================================ }
function TAIHumanPoseDetector.DetectRGBBuffer(
  AData: Pointer; AWidth, AHeight, AStride: Integer): Boolean;
{$IFDEF CPU64}
var
  LImg: tmp_image_raw;
  LLastResultPtr: Pmp_pose_result;
  Res: Integer;
  I, J, LIdx: Integer;
{$ENDIF}
begin
  Result := False;
  {$IFDEF CPU64}
  FLastError := '';
  ClearResult;

  if not Assigned(AData) then
  begin
    FLastError := 'Buffer de dados inválido.';
    Exit;
  end;

  if (FDetectorHandle = nil) or not MpPoseBridgeAvailable then
  begin
    FLastError := 'Detector não inicializado. Chame Initialize primeiro.';
    Exit;
  end;

  FillChar(LImg, SizeOf(LImg), 0);
  LImg.struct_size   := SizeOf(LImg);
  LImg.data          := PByte(AData);
  LImg.width         := AWidth;
  LImg.height        := AHeight;
  LImg.channels      := 3;
  LImg.stride        := AStride;
  LImg.timestamp_ms  := 0;

  LLastResultPtr := nil;
  Res := mp_pose_detect(FDetectorHandle, @LImg, @LLastResultPtr);

  { FASE5-08: tratamento de erro correto }
  if Res <> HUMAN_POSE_OK then
  begin
    if Assigned(mp_pose_last_error) then
      FLastError := string(mp_pose_last_error(FDetectorHandle))
    else
      FLastError := Format('Erro na inferência. Código: %d', [Res]);
    if FLastError = '' then
      FLastError := Format('Erro na inferência. Código: %d', [Res]);
    DoDiagnosticLog('DetectRGBBuffer erro: ' + FLastError);
    if Assigned(FOnPoseError) then
      FOnPoseError(Self, Res, FLastError);
    Exit(False);
  end;

  if LLastResultPtr = nil then
  begin
    FLastError := 'Resultado nulo retornado pela bridge.';
    Exit(False);
  end;

  { Copiar landmarks }
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
        FLastResultData.Poses[I].Landmarks[J].X          := LLastResultPtr^.landmarks[LIdx].x;
        FLastResultData.Poses[I].Landmarks[J].Y          := LLastResultPtr^.landmarks[LIdx].y;
        FLastResultData.Poses[I].Landmarks[J].Z          := LLastResultPtr^.landmarks[LIdx].z;
        FLastResultData.Poses[I].Landmarks[J].Visibility := LLastResultPtr^.landmarks[LIdx].visibility;
        FLastResultData.Poses[I].Landmarks[J].Presence   := LLastResultPtr^.landmarks[LIdx].presence;
        FLastResultData.Poses[I].WorldLandmarks[J].X     := LLastResultPtr^.world_landmarks[LIdx].x;
        FLastResultData.Poses[I].WorldLandmarks[J].Y     := LLastResultPtr^.world_landmarks[LIdx].y;
        FLastResultData.Poses[I].WorldLandmarks[J].Z     := LLastResultPtr^.world_landmarks[LIdx].z;
        FLastResultData.Poses[I].WorldLandmarks[J].Visibility := 0.0;
        FLastResultData.Poses[I].WorldLandmarks[J].Presence   := 0.0;
      end;
    end;
  end;

  { FASE5-08: liberar resultado com ponteiro duplo — zera LLastResultPtr }
  mp_pose_free_result(LLastResultPtr);

  if FLastResultData.PoseCount > 0 then
  begin
    FLastOutput := Format('Detecção concluída. Poses: %d', [FLastResultData.PoseCount]);
    DoDiagnosticLog(FLastOutput);
    if Assigned(FOnPoseDetected) then
      FOnPoseDetected(Self, FLastResultData);
    Result := True;
  end
  else
    FLastError := 'Nenhuma pose humana detectada.';
  {$ELSE}
  FLastError := 'Plataforma 32-bit não suportada (somente x86_64).';
  {$ENDIF}
end;

{ ============================================================
  Acesso aos landmarks
  ============================================================ }

function TAIHumanPoseDetector.GetPoseCount: Integer;
begin
  Result := FLastResultData.PoseCount;
end;

function TAIHumanPoseDetector.GetLandmark(
  const APoseIndex: Integer;
  const ALandmarkId: TAIHumanPoseLandmarkId;
  out ALandmark: TAIHumanPoseLandmark): Boolean;
begin
  Result := GetLandmarkByIndex(APoseIndex, Integer(ALandmarkId), ALandmark);
end;

function TAIHumanPoseDetector.GetLandmarkByIndex(
  const APoseIndex: Integer;
  const ALandmarkIndex: Integer;
  out ALandmark: TAIHumanPoseLandmark): Boolean;
begin
  Result := False;
  if (APoseIndex < 0) or (APoseIndex >= FLastResultData.PoseCount) then
  begin
    FLastError := 'PoseIndex inválido.';
    Exit;
  end;
  if (ALandmarkIndex < 0) or (ALandmarkIndex >= AI_HUMAN_POSE_LANDMARK_COUNT) then
  begin
    FLastError := 'LandmarkIndex fora do intervalo.';
    Exit;
  end;
  ALandmark := FLastResultData.Poses[APoseIndex].Landmarks[ALandmarkIndex];
  Result := True;
end;

{ ============================================================
  Desenho do esqueleto
  ============================================================ }
procedure TAIHumanPoseDetector.DrawResult(ACanvas: TCanvas; const ADestRect: TRect);

  procedure DrawLine(Idx1, Idx2: Integer);
  var
    P1, P2: TPoint;
    LW, LH: Integer;
  begin
    LW := ADestRect.Right - ADestRect.Left;
    LH := ADestRect.Bottom - ADestRect.Top;
    P1.X := ADestRect.Left + Round(FLastResultData.Poses[0].Landmarks[Idx1].X * LW);
    P1.Y := ADestRect.Top  + Round(FLastResultData.Poses[0].Landmarks[Idx1].Y * LH);
    P2.X := ADestRect.Left + Round(FLastResultData.Poses[0].Landmarks[Idx2].X * LW);
    P2.Y := ADestRect.Top  + Round(FLastResultData.Poses[0].Landmarks[Idx2].Y * LH);
    ACanvas.Line(P1, P2);
  end;

  procedure DrawPoint(Idx: Integer);
  var
    P: TPoint;
    LW, LH: Integer;
  begin
    LW := ADestRect.Right - ADestRect.Left;
    LH := ADestRect.Bottom - ADestRect.Top;
    P.X := ADestRect.Left + Round(FLastResultData.Poses[0].Landmarks[Idx].X * LW);
    P.Y := ADestRect.Top  + Round(FLastResultData.Poses[0].Landmarks[Idx].Y * LH);
    ACanvas.Ellipse(P.X - 4, P.Y - 4, P.X + 4, P.Y + 4);
    if FDrawLandmarkNames then
      ACanvas.TextOut(P.X + 6, P.Y - 6, LANDMARK_NAMES[Idx]);
  end;

var
  I: Integer;
begin
  if FLastResultData.PoseCount <= 0 then Exit;

  ACanvas.Pen.Color   := clGreen;
  ACanvas.Pen.Width   := 2;
  ACanvas.Brush.Color := clLime;

  if FDrawSkeleton then
    for I := Low(HUMAN_POSE_CONNECTIONS) to High(HUMAN_POSE_CONNECTIONS) do
      DrawLine(HUMAN_POSE_CONNECTIONS[I].A, HUMAN_POSE_CONNECTIONS[I].B);

  if FDrawLandmarkPoints then
    for I := 0 to 32 do
      DrawPoint(I);
end;

procedure TAIHumanPoseDetector.ClearResult;
begin
  FillChar(FLastResultData, SizeOf(FLastResultData), 0);
  FLastResultData.PoseCount := 0;
end;

initialization
  {$I aihumanposedetector_icon.lrs}
  { FASE5 — Verificar coerência das constantes HUMAN_POSE_* com a ABI da binding }
  {$IFDEF CPU64}
  Assert(HUMAN_POSE_OK                  = MP_OK,                  'HUMAN_POSE_OK mismatch');
  Assert(HUMAN_POSE_ABI_VERSION         = MP_POSE_ABI_VERSION,    'HUMAN_POSE_ABI_VERSION mismatch');
  Assert(HUMAN_POSE_ERR_ABI_MISMATCH    = MP_ERR_ABI_MISMATCH,    'HUMAN_POSE_ERR_ABI_MISMATCH mismatch');
  Assert(HUMAN_POSE_ERR_BAD_ARG         = MP_ERR_BAD_ARG,         'HUMAN_POSE_ERR_BAD_ARG mismatch');
  Assert(HUMAN_POSE_ERR_MODEL_LOAD      = MP_ERR_MODEL_LOAD,      'HUMAN_POSE_ERR_MODEL_LOAD mismatch');
  Assert(HUMAN_POSE_ERR_NOT_INITIALIZED = MP_ERR_NOT_INITIALIZED, 'HUMAN_POSE_ERR_NOT_INITIALIZED mismatch');
  Assert(HUMAN_POSE_ERR_INFERENCE       = MP_ERR_INFERENCE,       'HUMAN_POSE_ERR_INFERENCE mismatch');
  Assert(HUMAN_POSE_ERR_UNSUPPORTED     = MP_ERR_UNSUPPORTED,     'HUMAN_POSE_ERR_UNSUPPORTED mismatch');
  Assert(HUMAN_POSE_ERR_OUT_OF_MEMORY   = MP_ERR_OUT_OF_MEMORY,   'HUMAN_POSE_ERR_OUT_OF_MEMORY mismatch');
  Assert(HUMAN_POSE_ERR_BACKEND         = MP_ERR_BACKEND,         'HUMAN_POSE_ERR_BACKEND mismatch');
  {$ENDIF}

end.
