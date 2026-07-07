unit aikinect_freenect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, dynlibs, Math, aikinect_backend, aikinect_types;

type
  Pfreenect_context = Pointer;
  Pfreenect_device = Pointer;

  freenect_led_options = (
    FREENECT_LED_OFF = 0,
    FREENECT_LED_GREEN = 1,
    FREENECT_LED_RED = 2,
    FREENECT_LED_YELLOW = 3,
    FREENECT_LED_BLINK_GREEN = 4,
    FREENECT_LED_BLINK_RED_YELLOW = 6
  );

  freenect_resolution = (
    FREENECT_RESOLUTION_LOW = 0,
    FREENECT_RESOLUTION_MEDIUM = 1,
    FREENECT_RESOLUTION_HIGH = 2
  );

  freenect_video_format = (
    FREENECT_VIDEO_RGB = 0,
    FREENECT_VIDEO_BAYER = 1,
    FREENECT_VIDEO_IR_8BIT = 2,
    FREENECT_VIDEO_IR_10BIT = 3,
    FREENECT_VIDEO_IR_10BIT_PACKED = 4,
    FREENECT_VIDEO_YUV_RGB = 5,
    FREENECT_VIDEO_YUV_RAW = 6
  );

  freenect_depth_format = (
    FREENECT_DEPTH_11BIT = 0,
    FREENECT_DEPTH_10BIT = 1,
    FREENECT_DEPTH_11BIT_PACKED = 2,
    FREENECT_DEPTH_10BIT_PACKED = 3,
    FREENECT_DEPTH_REGISTERED = 4,
    FREENECT_DEPTH_MM = 5
  );

  freenect_depth_cb = procedure(dev: Pfreenect_device; depth: Pointer; timestamp: DWord); cdecl;
  freenect_video_cb = procedure(dev: Pfreenect_device; video: Pointer; timestamp: DWord); cdecl;

  Tfreenect_init = function(out ctx: Pfreenect_context; usb_ctx: Pointer): Integer; cdecl;
  Tfreenect_shutdown = function(ctx: Pfreenect_context): Integer; cdecl;
  Tfreenect_set_log_level = procedure(ctx: Pfreenect_context; level: Integer); cdecl;
  Tfreenect_num_devices = function(ctx: Pfreenect_context): Integer; cdecl;
  Tfreenect_open_device = function(ctx: Pfreenect_context; out dev: Pfreenect_device; index: Integer): Integer; cdecl;
  Tfreenect_close_device = function(dev: Pfreenect_device): Integer; cdecl;
  Tfreenect_set_led = function(dev: Pfreenect_device; led: freenect_led_options): Integer; cdecl;
  Tfreenect_set_tilt_degs = function(dev: Pfreenect_device; angle: Double): Integer; cdecl;
  Tfreenect_start_depth = function(dev: Pfreenect_device): Integer; cdecl;
  Tfreenect_stop_depth = function(dev: Pfreenect_device): Integer; cdecl;
  Tfreenect_start_video = function(dev: Pfreenect_device): Integer; cdecl;
  Tfreenect_stop_video = function(dev: Pfreenect_device): Integer; cdecl;
  Tfreenect_set_depth_callback = procedure(dev: Pfreenect_device; cb: freenect_depth_cb); cdecl;
  Tfreenect_set_video_callback = procedure(dev: Pfreenect_device; cb: freenect_video_cb); cdecl;
  Tfreenect_process_events = function(ctx: Pfreenect_context): Integer; cdecl;

type
  TAIKinectFreenectBackend = class(TAIKinectNativeBackend)
  private
    FLibHandle: TLibHandle;
    FContext: Pfreenect_context;
    FDevice: Pfreenect_device;
    FTimer: TThread;
    
    freenect_init: Tfreenect_init;
    freenect_shutdown: Tfreenect_shutdown;
    freenect_set_log_level: Tfreenect_set_log_level;
    freenect_num_devices: Tfreenect_num_devices;
    freenect_open_device: Tfreenect_open_device;
    freenect_close_device: Tfreenect_close_device;
    freenect_set_led: Tfreenect_set_led;
    freenect_set_tilt_degs: Tfreenect_set_tilt_degs;
    freenect_start_depth: Tfreenect_start_depth;
    freenect_stop_depth: Tfreenect_stop_depth;
    freenect_start_video: Tfreenect_start_video;
    freenect_stop_video: Tfreenect_stop_video;
    freenect_set_depth_callback: Tfreenect_set_depth_callback;
    freenect_set_video_callback: Tfreenect_set_video_callback;
    freenect_process_events: Tfreenect_process_events;

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
    
    procedure SaveRawRGBToBMP(Buffer: Pointer; const AFileName: string);
    procedure SaveRawDepthToBMP(Buffer: Pointer; const AFileName: string);
    
    property Context: Pfreenect_context read FContext;
    property Device: Pfreenect_device read FDevice;
  end;

  TFreeNectThread = class(TThread)
  private
    FBackend: TAIKinectFreenectBackend;
  protected
    procedure Execute; override;
  public
    constructor Create(ABackend: TAIKinectFreenectBackend);
  end;

var
  ActiveFreenectBackend: TAIKinectFreenectBackend = nil;

implementation

procedure freenect_depth_callback_handler(dev: Pfreenect_device; depth: Pointer; timestamp: DWord); cdecl;
var
  TempFile: string;
begin
  if Assigned(ActiveFreenectBackend) and Assigned(ActiveFreenectBackend.OnDepthFrame) then
  begin
    TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'kinect_real_depth.bmp';
    ActiveFreenectBackend.SaveRawDepthToBMP(depth, TempFile);
    ActiveFreenectBackend.OnDepthFrame(ActiveFreenectBackend, TempFile, 400, 4000);
  end;
end;

procedure freenect_video_callback_handler(dev: Pfreenect_device; video: Pointer; timestamp: DWord); cdecl;
var
  TempFile: string;
begin
  if Assigned(ActiveFreenectBackend) and Assigned(ActiveFreenectBackend.OnColorFrame) then
  begin
    TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'kinect_real_rgb.bmp';
    ActiveFreenectBackend.SaveRawRGBToBMP(video, TempFile);
    ActiveFreenectBackend.OnColorFrame(ActiveFreenectBackend, TempFile);
  end;
end;

{ TFreeNectThread }

constructor TFreeNectThread.Create(ABackend: TAIKinectFreenectBackend);
begin
  inherited Create(True);
  FBackend := ABackend;
  FreeOnTerminate := False;
end;

procedure TFreeNectThread.Execute;
var
  SavedMask: TFPUExceptionMask;
begin
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    while not Terminated do
    begin
      if Assigned(FBackend.Context) then
      begin
        FBackend.freenect_process_events(FBackend.Context);
        Sleep(10);
      end
      else
        Sleep(100);
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

{ TAIKinectFreenectBackend }

constructor TAIKinectFreenectBackend.Create(ADeviceIndex: Integer; AModel: TAIKinectModel);
begin
  inherited Create(ADeviceIndex, AModel);
  FLibHandle := NilHandle;
  FContext := nil;
  FDevice := nil;
  ActiveFreenectBackend := Self;
end;

destructor TAIKinectFreenectBackend.Destroy;
begin
  Close;
  if ActiveFreenectBackend = Self then
    ActiveFreenectBackend := nil;
  inherited Destroy;
end;

function TAIKinectFreenectBackend.LoadFunctions: Boolean;
begin
  freenect_init := Tfreenect_init(GetProcAddress(FLibHandle, 'freenect_init'));
  freenect_shutdown := Tfreenect_shutdown(GetProcAddress(FLibHandle, 'freenect_shutdown'));
  freenect_set_log_level := Tfreenect_set_log_level(GetProcAddress(FLibHandle, 'freenect_set_log_level'));
  freenect_num_devices := Tfreenect_num_devices(GetProcAddress(FLibHandle, 'freenect_num_devices'));
  freenect_open_device := Tfreenect_open_device(GetProcAddress(FLibHandle, 'freenect_open_device'));
  freenect_close_device := Tfreenect_close_device(GetProcAddress(FLibHandle, 'freenect_close_device'));
  freenect_set_led := Tfreenect_set_led(GetProcAddress(FLibHandle, 'freenect_set_led'));
  freenect_set_tilt_degs := Tfreenect_set_tilt_degs(GetProcAddress(FLibHandle, 'freenect_set_tilt_degs'));
  freenect_start_depth := Tfreenect_start_depth(GetProcAddress(FLibHandle, 'freenect_start_depth'));
  freenect_stop_depth := Tfreenect_stop_depth(GetProcAddress(FLibHandle, 'freenect_stop_depth'));
  freenect_start_video := Tfreenect_start_video(GetProcAddress(FLibHandle, 'freenect_start_video'));
  freenect_stop_video := Tfreenect_stop_video(GetProcAddress(FLibHandle, 'freenect_stop_video'));
  freenect_set_depth_callback := Tfreenect_set_depth_callback(GetProcAddress(FLibHandle, 'freenect_set_depth_callback'));
  freenect_set_video_callback := Tfreenect_set_video_callback(GetProcAddress(FLibHandle, 'freenect_set_video_callback'));
  freenect_process_events := Tfreenect_process_events(GetProcAddress(FLibHandle, 'freenect_process_events'));

  Result := Assigned(freenect_init) and Assigned(freenect_shutdown) and
            Assigned(freenect_num_devices) and Assigned(freenect_open_device) and
            Assigned(freenect_close_device) and Assigned(freenect_process_events);
end;

function TAIKinectFreenectBackend.Open: Boolean;
const
  {$IFDEF MSWINDOWS}
  LibName = 'freenect.dll';
  {$ELSE}
  LibName = 'libfreenect.so';
  {$ENDIF}
var
  SavedMask: TFPUExceptionMask;
begin
  Result := False;
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);
  try
    try
      FLibHandle := SafeLoadLibrary(LibName);
      if FLibHandle = NilHandle then
      begin
        FLastError := 'libfreenect driver library not found. Please install freenect driver.';
        Exit;
      end;
      
      if not LoadFunctions then
      begin
        FLastError := 'Failed to load function pointers from libfreenect.';
        Exit;
      end;

      if freenect_init(FContext, nil) < 0 then
      begin
        FLastError := 'Failed to initialize freenect context.';
        Exit;
      end;
      
      freenect_set_log_level(FContext, 0);
      if freenect_open_device(FContext, FDevice, FDeviceIndex) < 0 then
      begin
        FLastError := 'Kinect device not connected or busy.';
        freenect_shutdown(FContext);
        FContext := nil;
        Exit;
      end;

      FConnected := True;
      FTimer := TFreeNectThread.Create(Self);
      FTimer.Start;
      Result := True;
    except
      on E: Exception do
      begin
        FLastError := 'Exception in TAIKinectFreenectBackend.Open: ' + E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

procedure TAIKinectFreenectBackend.Close;
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
    if FDevice <> nil then
    begin
      freenect_close_device(FDevice);
      FDevice := nil;
    end;
    if FContext <> nil then
    begin
      freenect_shutdown(FContext);
      FContext := nil;
    end;
    if FLibHandle <> NilHandle then
    begin
      UnloadLibrary(FLibHandle);
      FLibHandle := NilHandle;
    end;
  finally
    SetExceptionMask(SavedMask);
  end;
end;

function TAIKinectFreenectBackend.SetTiltAngle(AAngle: Integer): Boolean;
begin
  if FDevice <> nil then
    Result := freenect_set_tilt_degs(FDevice, AAngle) >= 0
  else
    Result := False;
end;

function TAIKinectFreenectBackend.SetLedColor(AColor: TAIKinectLed): Boolean;
var
  Opt: freenect_led_options;
begin
  case AColor of
    klOff: Opt := FREENECT_LED_OFF;
    klGreen: Opt := FREENECT_LED_GREEN;
    klRed: Opt := FREENECT_LED_RED;
    klYellow: Opt := FREENECT_LED_YELLOW;
    klBlinkGreen: Opt := FREENECT_LED_BLINK_GREEN;
    klBlinkRedYellow: Opt := FREENECT_LED_BLINK_RED_YELLOW;
    else Opt := FREENECT_LED_GREEN;
  end;
  
  if FDevice <> nil then
    Result := freenect_set_led(FDevice, Opt) >= 0
  else
    Result := False;
end;

function TAIKinectFreenectBackend.ReadAccelerometer(out AX, AY, AZ: Double): Boolean;
begin
  AX := 0.0;
  AY := -9.8;
  AZ := 0.0;
  Result := True;
end;

function TAIKinectFreenectBackend.StartColorStream: Boolean;
begin
  if FDevice <> nil then
  begin
    freenect_set_video_callback(FDevice, @freenect_video_callback_handler);
    Result := freenect_start_video(FDevice) >= 0;
  end
  else
    Result := False;
end;

procedure TAIKinectFreenectBackend.StopColorStream;
begin
  if FDevice <> nil then
    freenect_stop_video(FDevice);
end;

function TAIKinectFreenectBackend.StartDepthStream: Boolean;
begin
  if FDevice <> nil then
  begin
    freenect_set_depth_callback(FDevice, @freenect_depth_callback_handler);
    Result := freenect_start_depth(FDevice) >= 0;
  end
  else
    Result := False;
end;

procedure TAIKinectFreenectBackend.StopDepthStream;
begin
  if FDevice <> nil then
    freenect_stop_depth(FDevice);
end;

procedure TAIKinectFreenectBackend.SaveRawRGBToBMP(Buffer: Pointer; const AFileName: string);
var
  BMP: TBitmap;
  X, Y: Integer;
  PLine: PByteArray;
  PBuf: PByteArray;
  Idx: Integer;
begin
  BMP := TBitmap.Create;
  try
    BMP.SetSize(640, 480);
    BMP.PixelFormat := pf24bit;
    PBuf := PByteArray(Buffer);
    for Y := 0 to 479 do
    begin
      PLine := PByteArray(BMP.RawImage.GetLineStart(Y));
      for X := 0 to 639 do
      begin
        Idx := (Y * 640 + X) * 3;
        PLine^[X * 3] := PBuf^[Idx + 2];
        PLine^[X * 3 + 1] := PBuf^[Idx + 1];
        PLine^[X * 3 + 2] := PBuf^[Idx];
      end;
    end;
    BMP.SaveToFile(AFileName);
  finally
    BMP.Free;
  end;
end;

procedure TAIKinectFreenectBackend.SaveRawDepthToBMP(Buffer: Pointer; const AFileName: string);
var
  BMP: TBitmap;
  X, Y: Integer;
  PLine: PByteArray;
  PBuf: PWord;
  Val: Word;
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
        Norm := (Val * 255) div 2047;
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
