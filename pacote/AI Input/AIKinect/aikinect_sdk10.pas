unit aikinect_sdk10;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, dynlibs, Math, aikinect_backend, aikinect_types;

type
  IUnknown = interface
    ['{00000000-0000-0000-C000-000000000046}']
    function QueryInterface(const iid: TGUID; out obj): HRESULT; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  NUI_LOCKED_RECT = record
    Pitch: Integer;
    size: Integer;
    pBits: Pointer;
  end;

  NUI_SURFACE_DESC = record
    Width: DWord;
    Height: DWord;
  end;
  PNuiFrameTexture = ^TNuiFrameTexture;
  PNuiFrameTextureVtbl = ^TNuiFrameTextureVtbl;

  TNuiFrameTextureVtbl = record
    QueryInterface: function(This: PNuiFrameTexture; const iid: TGUID; out obj): HRESULT; stdcall;
    AddRef: function(This: PNuiFrameTexture): Integer; stdcall;
    Release: function(This: PNuiFrameTexture): Integer; stdcall;
    BufferLen: function(This: PNuiFrameTexture): Integer; stdcall;
    Pitch: function(This: PNuiFrameTexture): Integer; stdcall;
    LockRect: function(This: PNuiFrameTexture; Level: DWord; var pLockedRect: NUI_LOCKED_RECT; pRect: Pointer; flags: DWord): HRESULT; stdcall;
    GetLevelDesc: function(This: PNuiFrameTexture; Level: DWord; var pDesc: NUI_SURFACE_DESC): HRESULT; stdcall;
    UnlockRect: function(This: PNuiFrameTexture; Level: DWord): HRESULT; stdcall;
  end;

  TNuiFrameTexture = record
    lpVtbl: PNuiFrameTextureVtbl;
  end;

  INuiFrameTexture = interface(IUnknown)
    ['{13EA17C5-30AD-4387-97B9-F7B4E9CAE740}']
    function BufferLen: Integer; stdcall;
    function Pitch: Integer; stdcall;
    function LockRect(Level: DWord; out pLockedRect: NUI_LOCKED_RECT; pRect: Pointer; flags: DWord): HRESULT; stdcall;
    function GetLevelDesc(Level: DWord; out pDesc: NUI_SURFACE_DESC): HRESULT; stdcall;
    function UnlockRect(Level: DWord): HRESULT; stdcall;
  end;

  NUI_IMAGE_VIEW_AREA = record
    eDigitalZoom: Integer;
    lCenterX: Integer;
    lCenterY: Integer;
  end;

  PNUI_IMAGE_FRAME = ^NUI_IMAGE_FRAME;
  NUI_IMAGE_FRAME = record
    liTimeStamp: Int64;
    dwFrameNumber: DWord;
    eImageType: Integer;
    eResolution: Integer;
    pFrameTexture: Pointer; // INuiFrameTexture
    dwFrameFlags: DWord;
    ViewArea: NUI_IMAGE_VIEW_AREA;
  end;

  TNuiInitialize = function(dwFlags: DWord): HRESULT; stdcall;
  TNuiShutdown = procedure; stdcall;
  TNuiImageStreamOpen = function(eImageType: Integer; eResolution: Integer;
    dwImageFrameFlags: DWord; dwFrameLimit: DWord; hNextFrameEvent: THandle;
    out phStream: THandle): HRESULT; stdcall;
  TNuiImageStreamGetNextFrame = function(hStream: THandle; dwMillisecondsToWait: DWord; out pImageFrame: PNUI_IMAGE_FRAME): HRESULT; stdcall;
  TNuiImageStreamReleaseFrame = function(hStream: THandle; pImageFrame: PNUI_IMAGE_FRAME): HRESULT; stdcall;
  TNuiCameraElevationSetAngle = function(lAngleDegrees: LongInt): HRESULT; stdcall;
  TNuiLedSetColor = function(dwColor: DWord): HRESULT; stdcall;

const
  NUI_IMAGE_TYPE_DEPTH_AND_PLAYER_INDEX = 0;
  NUI_IMAGE_TYPE_COLOR                  = 1;
  NUI_IMAGE_TYPE_DEPTH                  = 4;
  NUI_IMAGE_RESOLUTION_640x480          = 2;
  NUI_INITIALIZE_FLAG_USES_COLOR        = $00000002;
  NUI_INITIALIZE_FLAG_USES_DEPTH        = $00000020;

type
  TAIKinectSDK10Backend = class(TAIKinectNativeBackend)
  private
    FLibHandle: TLibHandle;
    FColorStreamHandle: THandle;
    FDepthStreamHandle: THandle;
    FTimer: TThread;
    
    NuiInitialize: TNuiInitialize;
    NuiShutdown: TNuiShutdown;
    NuiImageStreamOpen: TNuiImageStreamOpen;
    NuiImageStreamGetNextFrame: TNuiImageStreamGetNextFrame;
    NuiImageStreamReleaseFrame: TNuiImageStreamReleaseFrame;
    NuiCameraElevationSetAngle: TNuiCameraElevationSetAngle;
    NuiLedSetColor: TNuiLedSetColor;
    
    function LoadFunctions: Boolean;
    procedure LogSDK(const AMsg: string);
  public
    constructor Create(ADeviceIndex: Integer; AModel: TAIKinectModel); override;
    destructor Destroy; override;

    function Open: Boolean; override;
    procedure Close; override;

    function SetTiltAngle(AAngle: Integer): Boolean; override;
    function SetLedColor(AColor: TAIKinectLed): Boolean; override;
    function ReadAccelerometer(out AX, AY, AZ: Double): Boolean; override;

    function StartColorStream: Boolean; override;
    procedure StopColorStream; override;

    function StartDepthStream: Boolean; override;
    procedure StopDepthStream; override;

    function StartSkeletonStream: Boolean; override;
    procedure StopSkeletonStream; override;

    function StartAudioStream: Boolean; override;
    procedure StopAudioStream; override;
    
    procedure SaveRawBGRA32ToBMP(Buffer: Pointer; const AFileName: string);
    procedure SaveRawDepth16ToBMP(Buffer: Pointer; const AFileName: string);
    
    property ColorStreamHandle: THandle read FColorStreamHandle;
    property DepthStreamHandle: THandle read FDepthStreamHandle;
  end;

  TSDK10FrameThread = class(TThread)
  private
    FBackend: TAIKinectSDK10Backend;
    FColorActive: Boolean;
    FDepthActive: Boolean;
    FPendingColorFile: string;
    FPendingDepthFile: string;
    procedure FireColorEvent;
    procedure FireDepthEvent;
    procedure ProcessColor;
    procedure ProcessDepth;
  protected
    procedure Execute; override;
  public
    constructor Create(ABackend: TAIKinectSDK10Backend);
    property ColorActive: Boolean read FColorActive write FColorActive;
    property DepthActive: Boolean read FDepthActive write FDepthActive;
  end;

implementation

{ TSDK10FrameThread }

constructor TSDK10FrameThread.Create(ABackend: TAIKinectSDK10Backend);
begin
  inherited Create(True);
  FBackend := ABackend;
  FColorActive := False;
  FDepthActive := False;
  FreeOnTerminate := False;
end;

procedure TSDK10FrameThread.FireColorEvent;
begin
  if Assigned(FBackend.OnColorFrame) then
    FBackend.OnColorFrame(FBackend, FPendingColorFile);
end;

procedure TSDK10FrameThread.FireDepthEvent;
begin
  if Assigned(FBackend.OnDepthFrame) then
    FBackend.OnDepthFrame(FBackend, FPendingDepthFile, 400, 4000);
end;

procedure TSDK10FrameThread.ProcessColor;
var
  FramePtr: PNUI_IMAGE_FRAME;
  Tex: PNuiFrameTexture;
  Rect: NUI_LOCKED_RECT;
  TempFile: string;
  StreamHandle: THandle;
  HR: HRESULT;
  Locked: Boolean;
begin
  if FBackend = nil then Exit;
  StreamHandle := FBackend.ColorStreamHandle;
  if StreamHandle = 0 then Exit;
  if not Assigned(FBackend.NuiImageStreamGetNextFrame) or
     not Assigned(FBackend.NuiImageStreamReleaseFrame) then Exit;

  FramePtr := nil;
  HR := FBackend.NuiImageStreamGetNextFrame(StreamHandle, 100, FramePtr);
  if HR < 0 then
  begin
    FBackend.LogSDK(Format('NuiImageStreamGetNextFrame(color) failed, HRESULT=0x%.8x', [DWord(HR)]));
    Exit;
  end;
  if FramePtr = nil then
  begin
    FBackend.LogSDK('NuiImageStreamGetNextFrame(color) returned nil frame pointer.');
    Exit;
  end;

  Locked := False;
  Tex := PNuiFrameTexture(FramePtr^.pFrameTexture);
  try
    if Tex = nil then
      FBackend.LogSDK('Color frame has nil texture pointer.')
    else
    begin
      FillChar(Rect, SizeOf(Rect), 0);
      HR := Tex^.lpVtbl^.LockRect(Tex, 0, Rect, nil, 0);
      if HR < 0 then
        FBackend.LogSDK(Format('LockRect(color) failed, HRESULT=0x%.8x', [DWord(HR)]))
      else
      begin
        Locked := True;
        FBackend.LogSDK(Format('LockRect(color) OK, Pitch=%d, Size=%d, Bits=0x%x', [Rect.Pitch, Rect.size, PtrUInt(Rect.pBits)]));
        if Assigned(FBackend.OnColorFrame) and (Rect.pBits <> nil) then
        begin
          TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'kinect_sdk_rgb.bmp';
          FBackend.SaveRawBGRA32ToBMP(Rect.pBits, TempFile);
          FBackend.LogSDK('Color frame saved to ' + TempFile);
          FPendingColorFile := TempFile;
          Synchronize(@FireColorEvent);
        end;
      end;
    end;
  finally
    if Locked and (Tex <> nil) then
      Tex^.lpVtbl^.UnlockRect(Tex, 0);
    Tex := nil;
    HR := FBackend.NuiImageStreamReleaseFrame(StreamHandle, FramePtr);
    if HR < 0 then
    begin
      FBackend.FLastError := Format('NuiImageStreamReleaseFrame(color) failed, HRESULT=0x%.8x', [DWord(HR)]);
      FBackend.LogSDK(FBackend.FLastError);
    end;
  end;
end;
procedure TSDK10FrameThread.ProcessDepth;
var
  FramePtr: PNUI_IMAGE_FRAME;
  Tex: PNuiFrameTexture;
  Rect: NUI_LOCKED_RECT;
  TempFile: string;
  StreamHandle: THandle;
  HR: HRESULT;
  Locked: Boolean;
begin
  if FBackend = nil then Exit;
  StreamHandle := FBackend.DepthStreamHandle;
  if StreamHandle = 0 then Exit;
  if not Assigned(FBackend.NuiImageStreamGetNextFrame) or
     not Assigned(FBackend.NuiImageStreamReleaseFrame) then Exit;

  FramePtr := nil;
  HR := FBackend.NuiImageStreamGetNextFrame(StreamHandle, 100, FramePtr);
  if HR < 0 then
  begin
    FBackend.LogSDK(Format('NuiImageStreamGetNextFrame(depth) failed, HRESULT=0x%.8x', [DWord(HR)]));
    Exit;
  end;
  if FramePtr = nil then
  begin
    FBackend.LogSDK('NuiImageStreamGetNextFrame(depth) returned nil frame pointer.');
    Exit;
  end;

  Locked := False;
  Tex := PNuiFrameTexture(FramePtr^.pFrameTexture);
  try
    if Tex = nil then
      FBackend.LogSDK('Depth frame has nil texture pointer.')
    else
    begin
      FillChar(Rect, SizeOf(Rect), 0);
      HR := Tex^.lpVtbl^.LockRect(Tex, 0, Rect, nil, 0);
      if HR < 0 then
        FBackend.LogSDK(Format('LockRect(depth) failed, HRESULT=0x%.8x', [DWord(HR)]))
      else
      begin
        Locked := True;
        FBackend.LogSDK(Format('LockRect(depth) OK, Pitch=%d, Size=%d, Bits=0x%x', [Rect.Pitch, Rect.size, PtrUInt(Rect.pBits)]));
        if Assigned(FBackend.OnDepthFrame) and (Rect.pBits <> nil) then
        begin
          TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'kinect_sdk_depth.bmp';
          FBackend.SaveRawDepth16ToBMP(Rect.pBits, TempFile);
          FBackend.LogSDK('Depth frame saved to ' + TempFile);
          FPendingDepthFile := TempFile;
          Synchronize(@FireDepthEvent);
        end;
      end;
    end;
  finally
    if Locked and (Tex <> nil) then
      Tex^.lpVtbl^.UnlockRect(Tex, 0);
    Tex := nil;
    HR := FBackend.NuiImageStreamReleaseFrame(StreamHandle, FramePtr);
    if HR < 0 then
    begin
      FBackend.FLastError := Format('NuiImageStreamReleaseFrame(depth) failed, HRESULT=0x%.8x', [DWord(HR)]);
      FBackend.LogSDK(FBackend.FLastError);
    end;
  end;
end;
procedure TSDK10FrameThread.Execute;
var
  SavedMask: TFPUExceptionMask;
begin
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    while not Terminated do
    begin
      if FBackend.Connected then
      begin
        if FColorActive then ProcessColor;
        if FDepthActive then ProcessDepth;
      end;
      Sleep(10); // Decreased sleep for higher frame responsiveness
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

{ TAIKinectSDK10Backend }

procedure TAIKinectSDK10Backend.LogSDK(const AMsg: string);
var
  F: TextFile;
  LogFile: string;
begin
  LogFile := IncludeTrailingPathDelimiter(GetTempDir) + 'aikinect_sdk10_backend.log';
  try
    AssignFile(F, LogFile);
    if FileExists(LogFile) then
      Append(F)
    else
      Rewrite(F);
    try
      WriteLn(F, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMsg);
      Flush(F);
    finally
      CloseFile(F);
    end;
  except
  end;
end;
constructor TAIKinectSDK10Backend.Create(ADeviceIndex: Integer; AModel: TAIKinectModel);
begin
  inherited Create(ADeviceIndex, AModel);
  FLibHandle := NilHandle;
  FColorStreamHandle := 0;
  FDepthStreamHandle := 0;
end;

destructor TAIKinectSDK10Backend.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIKinectSDK10Backend.LoadFunctions: Boolean;
begin
  NuiInitialize := TNuiInitialize(GetProcAddress(FLibHandle, 'NuiInitialize'));
  NuiShutdown := TNuiShutdown(GetProcAddress(FLibHandle, 'NuiShutdown'));
  NuiImageStreamOpen := TNuiImageStreamOpen(GetProcAddress(FLibHandle, 'NuiImageStreamOpen'));
  NuiImageStreamGetNextFrame := TNuiImageStreamGetNextFrame(GetProcAddress(FLibHandle, 'NuiImageStreamGetNextFrame'));
  NuiImageStreamReleaseFrame := TNuiImageStreamReleaseFrame(GetProcAddress(FLibHandle, 'NuiImageStreamReleaseFrame'));
  NuiCameraElevationSetAngle := TNuiCameraElevationSetAngle(GetProcAddress(FLibHandle, 'NuiCameraElevationSetAngle'));
  NuiLedSetColor := TNuiLedSetColor(GetProcAddress(FLibHandle, 'NuiLedSetColor'));

  Result := Assigned(NuiInitialize) and Assigned(NuiShutdown) and
            Assigned(NuiImageStreamOpen) and Assigned(NuiImageStreamGetNextFrame) and
            Assigned(NuiImageStreamReleaseFrame);
end;

function TAIKinectSDK10Backend.Open: Boolean;
var
  SDKPath: string;
  SavedMask: TFPUExceptionMask;
  HR: HRESULT;
begin
  Result := False;
  if FDeviceIndex <> 0 then
  begin
    FLastError := 'SDK10 backend supports only device index 0 (NuiInitialize opens the default sensor).';
    Exit;
  end;
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      FLibHandle := SafeLoadLibrary('Kinect10.dll');
      if FLibHandle = NilHandle then
      begin
        SDKPath := GetEnvironmentVariable('WINDIR');
        if SDKPath <> '' then
        begin
          SDKPath := IncludeTrailingPathDelimiter(SDKPath) + 'System32\Kinect10.dll';
          if FileExists(SDKPath) then
            FLibHandle := SafeLoadLibrary(SDKPath);
        end;
      end;

      if FLibHandle = NilHandle then
      begin
        FLastError := Format(
          'Kinect10.dll not found (application is %d-bit). ' +
          'Install the Kinect for Windows SDK 1.8 (or Runtime 1.8). ' +
          'The DLL bitness must match the application bitness.',
          [SizeOf(Pointer) * 8]);
        Exit;
      end;
      
      if not LoadFunctions then
      begin
        FLastError := 'Failed to load function pointers from Kinect10.dll.';
        Exit;
      end;

      LogSDK('Calling NuiInitialize.');
      HR := NuiInitialize(NUI_INITIALIZE_FLAG_USES_DEPTH or NUI_INITIALIZE_FLAG_USES_COLOR);
      if HR < 0 then
      begin
        FLastError := Format('Failed to initialize Kinect SDK NuiInitialize, HRESULT=0x%.8x (Kinect device disconnected or busy).', [DWord(HR)]);
        Exit;
      end;

      FConnected := True;
      FTimer := TSDK10FrameThread.Create(Self);
      FTimer.Start;
      Result := True;
    except
      on E: Exception do
      begin
        FLastError := 'Exception in TAIKinectSDK10Backend.Open: ' + E.ClassName + ': ' + E.Message;
        LogSDK(FLastError);
      end;
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

procedure TAIKinectSDK10Backend.Close;
var
  SavedMask: TFPUExceptionMask;
begin
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    FConnected := False;

    if Assigned(FTimer) then
    begin
      TSDK10FrameThread(FTimer).ColorActive := False;
      TSDK10FrameThread(FTimer).DepthActive := False;
      FTimer.Terminate;
      FTimer.WaitFor;
      FreeAndNil(FTimer);
    end;

    FColorStreamHandle := 0;
    FDepthStreamHandle := 0;

    if Assigned(NuiShutdown) then
    begin
      try
        LogSDK('Calling NuiShutdown.');
        NuiShutdown();
        LogSDK('NuiShutdown returned.');
      except
        on E: Exception do
          begin
            FLastError := 'Exception in Kinect SDK NuiShutdown: ' + E.ClassName + ': ' + E.Message;
            LogSDK(FLastError);
          end;
      end;
      NuiShutdown := nil;
    end;

    NuiInitialize := nil;
    NuiImageStreamOpen := nil;
    NuiImageStreamGetNextFrame := nil;
    NuiImageStreamReleaseFrame := nil;
    NuiCameraElevationSetAngle := nil;
    NuiLedSetColor := nil;

    if FLibHandle <> NilHandle then
    begin
      UnloadLibrary(FLibHandle);
      FLibHandle := NilHandle;
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;
function TAIKinectSDK10Backend.SetTiltAngle(AAngle: Integer): Boolean;
var
  SavedMask: TFPUExceptionMask;
begin
  Result := False;
  if not FConnected or not Assigned(NuiCameraElevationSetAngle) then Exit;
  
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    Result := NuiCameraElevationSetAngle(AAngle) >= 0;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

function TAIKinectSDK10Backend.SetLedColor(AColor: TAIKinectLed): Boolean;
var
  SavedMask: TFPUExceptionMask;
  ColorVal: DWord;
begin
  Result := False;
  if not FConnected or not Assigned(NuiLedSetColor) then Exit;
  
  case AColor of
    klOff: ColorVal := 0;
    klGreen: ColorVal := 1;
    klRed: ColorVal := 2;
    klYellow: ColorVal := 3;
    klBlinkGreen: ColorVal := 4;
    klBlinkRedYellow: ColorVal := 5;
    else ColorVal := 1;
  end;
  
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    Result := NuiLedSetColor(ColorVal) >= 0;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

function TAIKinectSDK10Backend.ReadAccelerometer(out AX, AY, AZ: Double): Boolean;
begin
  AX := 0.0;
  AY := -9.8;
  AZ := 0.0;
  Result := True;
end;

function TAIKinectSDK10Backend.StartColorStream: Boolean;
var
  SavedMask: TFPUExceptionMask;
  HR: HRESULT;
begin
  Result := False;
  if not FConnected then
  begin
    FLastError := 'Kinect SDK10 backend is not connected.';
    Exit;
  end;
  if not Assigned(NuiImageStreamOpen) then
  begin
    FLastError := 'NuiImageStreamOpen function is not loaded.';
    Exit;
  end;

  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      HR := NuiImageStreamOpen(NUI_IMAGE_TYPE_COLOR, NUI_IMAGE_RESOLUTION_640x480,
              0, 2, 0, FColorStreamHandle);
      if HR >= 0 then
      begin
        if Assigned(FTimer) then
          TSDK10FrameThread(FTimer).ColorActive := True;
        Result := True;
      end
      else
        begin
          FLastError := Format('NuiImageStreamOpen(color) failed, HRESULT=0x%.8x', [DWord(HR)]);
          LogSDK(FLastError);
        end;
    except
      on E: Exception do
      begin
        FLastError := 'Exception in TAIKinectSDK10Backend.StartColorStream: ' + E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

procedure TAIKinectSDK10Backend.StopColorStream;
begin
  if Assigned(FTimer) then
    TSDK10FrameThread(FTimer).ColorActive := False;
  FColorStreamHandle := 0;
end;

function TAIKinectSDK10Backend.StartDepthStream: Boolean;
var
  SavedMask: TFPUExceptionMask;
  HR: HRESULT;
begin
  Result := False;
  if not FConnected then
  begin
    FLastError := 'Kinect SDK10 backend is not connected.';
    Exit;
  end;
  if not Assigned(NuiImageStreamOpen) then
  begin
    FLastError := 'NuiImageStreamOpen function is not loaded.';
    Exit;
  end;

  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      HR := NuiImageStreamOpen(NUI_IMAGE_TYPE_DEPTH, NUI_IMAGE_RESOLUTION_640x480,
              0, 2, 0, FDepthStreamHandle);
      if HR >= 0 then
      begin
        if Assigned(FTimer) then
          TSDK10FrameThread(FTimer).DepthActive := True;
        Result := True;
      end
      else
        FLastError := Format('NuiImageStreamOpen(depth) failed, HRESULT=0x%.8x', [DWord(HR)]);
    except
      on E: Exception do
      begin
        FLastError := 'Exception in TAIKinectSDK10Backend.StartDepthStream: ' + E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

procedure TAIKinectSDK10Backend.StopDepthStream;
begin
  if Assigned(FTimer) then
    TSDK10FrameThread(FTimer).DepthActive := False;
  FDepthStreamHandle := 0;
end;

function TAIKinectSDK10Backend.StartSkeletonStream: Boolean;
begin
  Result := False;
end;

procedure TAIKinectSDK10Backend.StopSkeletonStream;
begin
end;

function TAIKinectSDK10Backend.StartAudioStream: Boolean;
begin
  Result := False;
end;

procedure TAIKinectSDK10Backend.StopAudioStream;
begin
end;

procedure TAIKinectSDK10Backend.SaveRawBGRA32ToBMP(Buffer: Pointer; const AFileName: string);
var
  FS: TFileStream;
  TmpFile: string;
  DataSize: DWord;

  procedure WriteWordLE(AValue: Word);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

  procedure WriteDWordLE(AValue: DWord);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

  procedure WriteLongIntLE(AValue: LongInt);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

begin
  TmpFile := AFileName + '.tmp';
  DataSize := 640 * 480 * 4;
  FS := TFileStream.Create(TmpFile, fmCreate);
  try
    WriteWordLE($4D42);              // BM
    WriteDWordLE(14 + 40 + DataSize);
    WriteWordLE(0);
    WriteWordLE(0);
    WriteDWordLE(14 + 40);

    WriteDWordLE(40);                // BITMAPINFOHEADER
    WriteLongIntLE(640);
    WriteLongIntLE(-480);            // top-down bitmap
    WriteWordLE(1);
    WriteWordLE(32);
    WriteDWordLE(0);                 // BI_RGB
    WriteDWordLE(DataSize);
    WriteLongIntLE(2835);
    WriteLongIntLE(2835);
    WriteDWordLE(0);
    WriteDWordLE(0);

    FS.WriteBuffer(Buffer^, DataSize);
  finally
    FS.Free;
  end;

  if FileExists(AFileName) then
    DeleteFile(AFileName);
  RenameFile(TmpFile, AFileName);
end;
procedure TAIKinectSDK10Backend.SaveRawDepth16ToBMP(Buffer: Pointer; const AFileName: string);
var
  FS: TFileStream;
  TmpFile: string;
  X, Y: Integer;
  PBuf: PWord;
  Val: Word;
  Dist: Word;
  Norm: Byte;
  Row: array of Byte;
  RowSize: DWord;
  DataSize: DWord;

  procedure WriteWordLE(AValue: Word);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

  procedure WriteDWordLE(AValue: DWord);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

  procedure WriteLongIntLE(AValue: LongInt);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

begin
  TmpFile := AFileName + '.tmp';
  RowSize := ((640 * 3 + 3) div 4) * 4;
  DataSize := RowSize * 480;
  SetLength(Row, RowSize);
  PBuf := PWord(Buffer);

  FS := TFileStream.Create(TmpFile, fmCreate);
  try
    WriteWordLE($4D42);              // BM
    WriteDWordLE(14 + 40 + DataSize);
    WriteWordLE(0);
    WriteWordLE(0);
    WriteDWordLE(14 + 40);

    WriteDWordLE(40);                // BITMAPINFOHEADER
    WriteLongIntLE(640);
    WriteLongIntLE(-480);            // top-down bitmap
    WriteWordLE(1);
    WriteWordLE(24);
    WriteDWordLE(0);                 // BI_RGB
    WriteDWordLE(DataSize);
    WriteLongIntLE(2835);
    WriteLongIntLE(2835);
    WriteDWordLE(0);
    WriteDWordLE(0);

    for Y := 0 to 479 do
    begin
      FillChar(Row[0], RowSize, 0);
      for X := 0 to 639 do
      begin
        Val := PBuf[Y * 640 + X];
        Dist := Val shr 3;
        if Dist < 400 then Dist := 400;
        if Dist > 4000 then Dist := 4000;
        Norm := ((Dist - 400) * 255) div 3600;
        Row[X * 3] := 255 - Norm;
        Row[X * 3 + 1] := Norm;
        Row[X * 3 + 2] := Norm;
      end;
      FS.WriteBuffer(Row[0], RowSize);
    end;
  finally
    FS.Free;
  end;

  if FileExists(AFileName) then
    DeleteFile(AFileName);
  RenameFile(TmpFile, AFileName);
end;
end.
