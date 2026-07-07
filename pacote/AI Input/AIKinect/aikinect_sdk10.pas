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

  INuiFrameTexture = interface(IUnknown)
    ['{13EA17C5-30AD-4387-97B9-F7B4E9CAE740}']
    function BufferLen: Integer; stdcall;
    function Pitch: Integer; stdcall;
    function LockRect(Level: DWord; out pLockedRect: NUI_LOCKED_RECT; pRect: Pointer; flags: DWord): HRESULT; stdcall;
    function UnlockRect(Level: DWord): HRESULT; stdcall;
  end;

  NUI_IMAGE_VIEW_AREA = record
    eDigitalZoom: Integer;
    lCenterX: Integer;
    lCenterY: Integer;
  end;

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
  TNuiImageStreamOpen = function(eImageType: Integer; eResolution: Integer; dwFrameLimit: DWord; hNextFrameEvent: THandle; out phStream: THandle): HRESULT; stdcall;
  TNuiImageStreamGetNextFrame = function(hStream: THandle; dwMillisecondsToWait: DWord; out pImageFrame: NUI_IMAGE_FRAME): HRESULT; stdcall;
  TNuiImageStreamReleaseFrame = function(hStream: THandle; var pImageFrame: NUI_IMAGE_FRAME): HRESULT; stdcall;
  TNuiCameraElevationSetAngle = function(lAngleDegrees: LongInt): HRESULT; stdcall;
  TNuiLedSetColor = function(dwColor: DWord): HRESULT; stdcall;

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

procedure TSDK10FrameThread.ProcessColor;
var
  Frame: NUI_IMAGE_FRAME;
  Tex: INuiFrameTexture;
  Rect: NUI_LOCKED_RECT;
  TempFile: string;
begin
  if FBackend.ColorStreamHandle = 0 then Exit;
  
  // Use 100ms timeout to wait for frame availability
  if FBackend.NuiImageStreamGetNextFrame(FBackend.ColorStreamHandle, 100, Frame) >= 0 then
  begin
    Pointer(Tex) := Frame.pFrameTexture; // Raw assignment bypasses automatic FPC COM _AddRef
    try
      if (Tex <> nil) and (Tex.LockRect(0, Rect, nil, 0) >= 0) then
      begin
        if Assigned(FBackend.OnColorFrame) then
        begin
          TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'kinect_sdk_rgb.bmp';
          FBackend.SaveRawBGRA32ToBMP(Rect.pBits, TempFile);
          FBackend.OnColorFrame(FBackend, TempFile);
        end;
        Tex.UnlockRect(0);
      end;
    finally
      Pointer(Tex) := nil; // Raw clear bypasses automatic FPC COM _Release
    end;
    FBackend.NuiImageStreamReleaseFrame(FBackend.ColorStreamHandle, Frame);
  end;
end;

procedure TSDK10FrameThread.ProcessDepth;
var
  Frame: NUI_IMAGE_FRAME;
  Tex: INuiFrameTexture;
  Rect: NUI_LOCKED_RECT;
  TempFile: string;
begin
  if FBackend.DepthStreamHandle = 0 then Exit;
  
  if FBackend.NuiImageStreamGetNextFrame(FBackend.DepthStreamHandle, 100, Frame) >= 0 then
  begin
    Pointer(Tex) := Frame.pFrameTexture;
    try
      if (Tex <> nil) and (Tex.LockRect(0, Rect, nil, 0) >= 0) then
      begin
        if Assigned(FBackend.OnDepthFrame) then
        begin
          TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'kinect_sdk_depth.bmp';
          FBackend.SaveRawDepth16ToBMP(Rect.pBits, TempFile);
          FBackend.OnDepthFrame(FBackend, TempFile, 400, 4000);
        end;
        Tex.UnlockRect(0);
      end;
    finally
      Pointer(Tex) := nil;
    end;
    FBackend.NuiImageStreamReleaseFrame(FBackend.DepthStreamHandle, Frame);
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
begin
  Result := False;
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      FLibHandle := SafeLoadLibrary('Kinect10.dll');
      if FLibHandle = NilHandle then
      begin
        SDKPath := GetEnvironmentVariable('KINECTSDK10_DIR');
        if SDKPath <> '' then
        begin
          SDKPath := IncludeTrailingPathDelimiter(SDKPath) + 'assemblies\Kinect10.dll';
          if FileExists(SDKPath) then
            FLibHandle := SafeLoadLibrary(SDKPath);
        end;
      end;

      if FLibHandle = NilHandle then
      begin
        FLastError := 'Kinect for Windows SDK 1.8 driver library (Kinect10.dll) not found. Please install the official Kinect SDK.';
        Exit;
      end;
      
      if not LoadFunctions then
      begin
        FLastError := 'Failed to load function pointers from Kinect10.dll.';
        Exit;
      end;

      // NUI_INITIALIZE_FLAG_USES_DEPTH = $00000020
      // NUI_INITIALIZE_FLAG_USES_COLOR = $00000002
      if NuiInitialize($00000020 or $00000002) < 0 then
      begin
        FLastError := 'Failed to initialize Kinect SDK NuiInitialize (Kinect device disconnected or busy).';
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
      FTimer.Terminate;
      FTimer.WaitFor;
      FreeAndNil(FTimer);
    end;
    
    if Assigned(NuiShutdown) then
      NuiShutdown();
      
    if FLibHandle <> NilHandle then
    begin
      UnloadLibrary(FLibHandle);
      FLibHandle := NilHandle;
    end;
    FColorStreamHandle := 0;
    FDepthStreamHandle := 0;
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
begin
  Result := False;
  if not FConnected or not Assigned(NuiImageStreamOpen) then Exit;
  
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      // Open Color Stream: Type=0 (Color), Res=1 (640x480), Limit=2, Event=0
      if NuiImageStreamOpen(0, 1, 2, 0, FColorStreamHandle) >= 0 then
      begin
        if Assigned(FTimer) then
          TSDK10FrameThread(FTimer).ColorActive := True;
        Result := True;
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
begin
  Result := False;
  if not FConnected or not Assigned(NuiImageStreamOpen) then Exit;
  
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      // Open Depth Stream: Type=1 (Depth), Res=1 (640x480), Limit=2, Event=0
      if NuiImageStreamOpen(1, 1, 2, 0, FDepthStreamHandle) >= 0 then
      begin
        if Assigned(FTimer) then
          TSDK10FrameThread(FTimer).DepthActive := True;
        Result := True;
      end;
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
  BMP: TBitmap;
  X, Y: Integer;
  PLine: PByteArray;
  PBuf: PDWord;
  Val: DWord;
begin
  BMP := TBitmap.Create;
  try
    BMP.SetSize(640, 480);
    BMP.PixelFormat := pf24bit;
    PBuf := PDWord(Buffer);
    for Y := 0 to 479 do
    begin
      PLine := PByteArray(BMP.RawImage.GetLineStart(Y));
      for X := 0 to 639 do
      begin
        Val := PBuf[Y * 640 + X];
        PLine^[X * 3] := Val and $FF;          // B
        PLine^[X * 3 + 1] := (Val >> 8) and $FF;  // G
        PLine^[X * 3 + 2] := (Val >> 16) and $FF; // R
      end;
    end;
    BMP.SaveToFile(AFileName);
  finally
    BMP.Free;
  end;
end;

procedure TAIKinectSDK10Backend.SaveRawDepth16ToBMP(Buffer: Pointer; const AFileName: string);
var
  BMP: TBitmap;
  X, Y: Integer;
  PLine: PByteArray;
  PBuf: PWord;
  Val: Word;
  Dist: Word;
  Norm: Byte;
begin
  BMP := TBitmap.Create;
  try
    BMP.SetSize(640, 480);
    BMP.PixelFormat := pf24bit;
    PBuf := PWord(Buffer);
    for Y := 0 to 479 do
    begin
      PLine := PByteArray(BMP.RawImage.GetLineStart(Y));
      for X := 0 to 639 do
      begin
        Val := PBuf[Y * 640 + X];
        // Lower 3 bits are player index, upper 13 bits are distance in mm
        Dist := Val shr 3;
        if Dist < 400 then Dist := 400;
        if Dist > 4000 then Dist := 4000;
        Norm := ((Dist - 400) * 255) div 3600;
        PLine^[X * 3] := 255 - Norm;
        PLine^[X * 3 + 1] := Norm;
        PLine^[X * 3 + 2] := Norm;
      end;
    end;
    BMP.SaveToFile(AFileName);
  finally
    BMP.Free;
  end;
end;

end.
