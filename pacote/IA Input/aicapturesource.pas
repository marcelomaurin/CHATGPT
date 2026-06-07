unit aicapturesource;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Controls, Forms,
  fphttpclient,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ELSE}
  LCLIntf, LCLType,
  {$ENDIF}
  Graphics,
  aibase, aicamera_backend
  {$IFDEF MSWINDOWS}
  , aicamera_vfw
  {$ENDIF}
  {$IFDEF LINUX}
  , aicamera_v4l2
  {$ENDIF}
  , LResources;

type
  { ---- Enums ---- }

  TAICaptureSourceKind = (
    cskCameraLocal,        // Webcam / USB camera via native OS backend
    cskCameraIPSnapshot,   // IP camera via HTTP/HTTPS JPEG snapshot
    cskCameraIPRTSP,       // IP camera via RTSP (not yet implemented)
    cskScreen,             // Desktop / screen capture
    cskFile,               // Load frame from image file
    cskNone                // No active source
  );

  { ---- Event types ---- }

  TAIFrameEvent         = procedure(Sender: TObject; const AFrameFile: string) of object;
  TAICaptureErrorEvent  = procedure(Sender: TObject; const AError: string) of object;
  TAICaptureStateEvent  = procedure(Sender: TObject; AActive: Boolean) of object;
  TOSMouseMoveEvent     = procedure(Sender: TObject; X, Y: Integer) of object;
  TOSKeyInterceptEvent  = procedure(Sender: TObject; KeyCode: Word; KeyChar: Char) of object;

  { ---- Internal abstract backend ---- }

  TAICaptureBackendBase = class
  public
    LastError: string;
    function Start: Boolean; virtual; abstract;
    procedure Stop; virtual; abstract;
    function CaptureFrame(out ABmp: TBitmap): Boolean; virtual; abstract;
  end;

  { ---- Backend: Local Camera ---- }

  TAILocalCameraBackend = class(TAICaptureBackendBase)
  private
    FNative: TAICameraNativeBackend;
    FCameraIndex: Integer;
    FDeviceName: string;
    FWidth, FHeight, FFPS: Integer;
    FPreviewHandle: THandle;
    FPreviewEnabled: Boolean;
    FMaxScan: Integer;
    FTempFolder: string;
  public
    constructor Create(ACameraIndex: Integer; const ADeviceName: string;
      AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle;
      APreviewEnabled: Boolean; AMaxScan: Integer; const ATempFolder: string);
    destructor Destroy; override;
    function Start: Boolean; override;
    procedure Stop; override;
    function CaptureFrame(out ABmp: TBitmap): Boolean; override;
    function CaptureToFile(const AFileName: string): Boolean;
    function ListCameras: TStringList;
  end;

  { ---- Backend: IP Snapshot ---- }

  TAIIPSnapshotBackend = class(TAICaptureBackendBase)
  private
    FIPAddress: string;
    FPort: Integer;
    FSnapshotURL: string;
    FUsername: string;
    FPassword: string;
    FUseHTTPS: Boolean;
    FTimeoutMs: Integer;
  public
    constructor Create(const AIPAddress: string; APort: Integer;
      const ASnapshotURL, AUsername, APassword: string;
      AUseHTTPS: Boolean; ATimeoutMs: Integer);
    function Start: Boolean; override;
    procedure Stop; override;
    function CaptureFrame(out ABmp: TBitmap): Boolean; override;
  end;

  { ---- Backend: RTSP (not implemented) ---- }

  TAIRTSPBackend = class(TAICaptureBackendBase)
  public
    function Start: Boolean; override;
    procedure Stop; override;
    function CaptureFrame(out ABmp: TBitmap): Boolean; override;
  end;

  { ---- Backend: Screen Capture ---- }

  TAIScreenCaptureBackend = class(TAICaptureBackendBase)
  private
    FCaptureRect: TRect;
    FCaptureFullScreen: Boolean;
  public
    constructor Create(const ACaptureRect: TRect; ACaptureFullScreen: Boolean);
    function Start: Boolean; override;
    procedure Stop; override;
    function CaptureFrame(out ABmp: TBitmap): Boolean; override;
  end;

  { ---- Backend: File Frame ---- }

  TAIFileCaptureBackend = class(TAICaptureBackendBase)
  private
    FInputFile: string;
  public
    constructor Create(const AInputFile: string);
    function Start: Boolean; override;
    procedure Stop; override;
    function CaptureFrame(out ABmp: TBitmap): Boolean; override;
  end;

  { ---- Main component ---- }

  TAICaptureSource = class(TAIBaseComponent)
  private
    // --- Core ---
    FSourceKind: TAICaptureSourceKind;
    FActive: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    FFPS: Integer;
    FCaptureInterval: Integer;
    FAutoStart: Boolean;
    FLastFrameFile: string;
    FTempFolder: string;
    FAutoDeleteTempFiles: Boolean;

    // --- Local Camera ---
    FCameraIndex: Integer;
    FDeviceName: string;
    FBackend: TAICameraBackend;
    FPreviewHandle: THandle;
    FPreviewEnabled: Boolean;
    FMaxCameraScan: Integer;

    // --- IP Camera ---
    FIPAddress: string;
    FPort: Integer;
    FSnapshotURL: string;
    FStreamURL: string;
    FUsername: string;
    FPassword: string;
    FUseHTTPS: Boolean;
    FTimeoutMs: Integer;

    // --- Screen ---
    FCaptureMonitorIndex: Integer;
    FCaptureFullScreen: Boolean;
    FCaptureRect: TRect;
    FTrackMouse: Boolean;
    FTrackKeyboard: Boolean;
    FPollingInterval: Integer;
    FLastMouseX, FLastMouseY: Integer;
    FLastKeyStates: array[0..255] of Boolean;

    // --- File ---
    FInputFile: string;

    // --- Internal ---
    FTimer: TTimer;
    FInTimerCall: Boolean;
    FActiveBackend: TAICaptureBackendBase;

    // --- Events ---
    FOnFrame: TAIFrameEvent;
    FOnError: TAICaptureErrorEvent;
    FOnStateChange: TAICaptureStateEvent;
    FOnMouseMove: TOSMouseMoveEvent;
    FOnKeyIntercepted: TOSKeyInterceptEvent;

    procedure OnTimerTick(Sender: TObject);
    procedure PollMouse;
    procedure PollKeyboard;
    function GetActualTempFolder: string;
    function BuildActiveBackend: TAICaptureBackendBase;
    function SaveBitmapToTemp(ABmp: TBitmap): string;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function StartCapture: Boolean;
    procedure StopCapture;
    function QueryFrame: Boolean;
    function CaptureToFile(const AFileName: string): Boolean;
    function CaptureToBitmap(out ABmp: TBitmap): Boolean;
    function CaptureToImage(AImage: TImage): Boolean;
    function SelfTest: Boolean;
    function ListAvailableSources: TStringList;
    function ListAvailableCameras: TStringList;

    property Active: Boolean read FActive;
    property LastFrameFile: string read FLastFrameFile;
    property CaptureRect: TRect read FCaptureRect write FCaptureRect; // TRect not publishable

  published
    // --- Core ---
    property SourceKind: TAICaptureSourceKind read FSourceKind write FSourceKind default cskCameraLocal;
    property Width: Integer read FWidth write FWidth default 640;
    property Height: Integer read FHeight write FHeight default 480;
    property FPS: Integer read FFPS write FFPS default 30;
    property CaptureInterval: Integer read FCaptureInterval write FCaptureInterval default 100;
    property AutoStart: Boolean read FAutoStart write FAutoStart default False;
    property TempFolder: string read FTempFolder write FTempFolder;
    property AutoDeleteTempFiles: Boolean read FAutoDeleteTempFiles write FAutoDeleteTempFiles default True;

    // --- Local Camera ---
    property CameraIndex: Integer read FCameraIndex write FCameraIndex default 0;
    property DeviceName: string read FDeviceName write FDeviceName;
    property Backend: TAICameraBackend read FBackend write FBackend default cbAuto;
    property PreviewHandle: THandle read FPreviewHandle write FPreviewHandle default 0;
    property PreviewEnabled: Boolean read FPreviewEnabled write FPreviewEnabled default True;
    property MaxCameraScan: Integer read FMaxCameraScan write FMaxCameraScan default 5;

    // --- IP Camera ---
    property IPAddress: string read FIPAddress write FIPAddress;
    property Port: Integer read FPort write FPort default 80;
    property SnapshotURL: string read FSnapshotURL write FSnapshotURL;
    property StreamURL: string read FStreamURL write FStreamURL;
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
    property UseHTTPS: Boolean read FUseHTTPS write FUseHTTPS default False;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 5000;

    // --- Screen ---
    property CaptureMonitorIndex: Integer read FCaptureMonitorIndex write FCaptureMonitorIndex default 0;
    property CaptureFullScreen: Boolean read FCaptureFullScreen write FCaptureFullScreen default True;
    // CaptureRect is in the public section (TRect is not publishable)
    property TrackMouse: Boolean read FTrackMouse write FTrackMouse default True;
    property TrackKeyboard: Boolean read FTrackKeyboard write FTrackKeyboard default False;
    property PollingInterval: Integer read FPollingInterval write FPollingInterval default 50;

    // --- File ---
    property InputFile: string read FInputFile write FInputFile;

    // --- Events ---
    property OnFrame: TAIFrameEvent read FOnFrame write FOnFrame;
    property OnError: TAICaptureErrorEvent read FOnError write FOnError;
    property OnStateChange: TAICaptureStateEvent read FOnStateChange write FOnStateChange;
    property OnMouseMove: TOSMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnKeyIntercepted: TOSKeyInterceptEvent read FOnKeyIntercepted write FOnKeyIntercepted;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAICaptureSource]);
end;

{ =========================================================== }
{ TAILocalCameraBackend                                       }
{ =========================================================== }

constructor TAILocalCameraBackend.Create(ACameraIndex: Integer;
  const ADeviceName: string; AWidth, AHeight, AFPS: Integer;
  APreviewHandle: THandle; APreviewEnabled: Boolean; AMaxScan: Integer;
  const ATempFolder: string);
begin
  inherited Create;
  FCameraIndex    := ACameraIndex;
  FDeviceName     := ADeviceName;
  FWidth          := AWidth;
  FHeight         := AHeight;
  FFPS            := AFPS;
  FPreviewHandle  := APreviewHandle;
  FPreviewEnabled := APreviewEnabled;
  FMaxScan        := AMaxScan;
  FTempFolder     := ATempFolder;
  FNative         := nil;
end;

destructor TAILocalCameraBackend.Destroy;
begin
  Stop;
  inherited Destroy;
end;

function TAILocalCameraBackend.Start: Boolean;
var
  LResolvedBackend: TAICameraBackend;
begin
  Result := False;
  LastError := '';

  {$IFDEF MSWINDOWS}
  LResolvedBackend := cbWindowsVFW;
  FNative := TAICameraVFWBackend.Create;
  {$ELSE}
    {$IFDEF LINUX}
    LResolvedBackend := cbLinuxV4L2;
    FNative := TAICameraV4L2Backend.Create;
    {$ELSE}
    LastError := 'Native camera backend not implemented on this platform.';
    Exit;
    {$ENDIF}
  {$ENDIF}

  if not Assigned(FNative) then
  begin
    LastError := 'Could not instantiate camera backend.';
    Exit;
  end;

  if not FNative.OpenCamera(FDeviceName, FCameraIndex, FWidth, FHeight, FFPS,
    FPreviewHandle, FPreviewEnabled) then
  begin
    LastError := FNative.LastError;
    FreeAndNil(FNative);
    Exit;
  end;

  Result := True;
end;

procedure TAILocalCameraBackend.Stop;
begin
  if Assigned(FNative) then
  begin
    FNative.CloseCamera;
    FreeAndNil(FNative);
  end;
end;

function TAILocalCameraBackend.CaptureFrame(out ABmp: TBitmap): Boolean;
var
  LTempFile: string;
begin
  Result := False;
  ABmp := nil;
  if not Assigned(FNative) then
  begin
    LastError := 'Camera backend not started.';
    Exit;
  end;

  LTempFile := FTempFolder + 'tai_capture_' + IntToStr(GetTickCount64) + '.bmp';
  if FNative.CaptureToFile(LTempFile) and FileExists(LTempFile) then
  begin
    ABmp := TBitmap.Create;
    try
      ABmp.LoadFromFile(LTempFile);
      Result := True;
    except
      on E: Exception do
      begin
        LastError := 'Failed to load captured frame: ' + E.Message;
        FreeAndNil(ABmp);
      end;
    end;
    SysUtils.DeleteFile(LTempFile);
  end
  else
    LastError := 'Backend CaptureToFile failed: ' + FNative.LastError;
end;

function TAILocalCameraBackend.CaptureToFile(const AFileName: string): Boolean;
begin
  Result := False;
  if not Assigned(FNative) then
  begin
    LastError := 'Camera backend not started.';
    Exit;
  end;
  Result := FNative.CaptureToFile(AFileName);
  if not Result then
    LastError := FNative.LastError;
end;

function TAILocalCameraBackend.ListCameras: TStringList;
begin
  if Assigned(FNative) then
    Result := FNative.ListCameras(FMaxScan)
  else
  begin
    Result := TStringList.Create;
    Result.Add('Camera backend not started.');
  end;
end;

{ =========================================================== }
{ TAIIPSnapshotBackend                                        }
{ =========================================================== }

constructor TAIIPSnapshotBackend.Create(const AIPAddress: string;
  APort: Integer; const ASnapshotURL, AUsername, APassword: string;
  AUseHTTPS: Boolean; ATimeoutMs: Integer);
begin
  inherited Create;
  FIPAddress   := AIPAddress;
  FPort        := APort;
  FSnapshotURL := ASnapshotURL;
  FUsername    := AUsername;
  FPassword    := APassword;
  FUseHTTPS    := AUseHTTPS;
  FTimeoutMs   := ATimeoutMs;
end;

function TAIIPSnapshotBackend.Start: Boolean;
begin
  // Validate required fields
  if FIPAddress = '' then
  begin
    LastError := 'IPAddress must not be empty.';
    Result := False;
    Exit;
  end;
  if FSnapshotURL = '' then
  begin
    LastError := 'SnapshotURL must not be empty.';
    Result := False;
    Exit;
  end;
  Result := True;
end;

procedure TAIIPSnapshotBackend.Stop;
begin
  // HTTP is stateless — nothing to close
end;

function TAIIPSnapshotBackend.CaptureFrame(out ABmp: TBitmap): Boolean;
var
  HTTP: TFPHttpClient;
  Stream: TMemoryStream;
  FullURL: string;
  Pic: TPicture;
begin
  Result := False;
  ABmp := nil;
  LastError := '';

  if FUseHTTPS then
    FullURL := 'https://'
  else
    FullURL := 'http://';
  FullURL := FullURL + FIPAddress + ':' + IntToStr(FPort) + FSnapshotURL;

  Stream := TMemoryStream.Create;
  HTTP := TFPHttpClient.Create(nil);
  try
    try
      HTTP.AllowRedirect := True;
      HTTP.ConnectTimeout := FTimeoutMs;
      HTTP.IOTimeout := FTimeoutMs;
      if (FUsername <> '') and (FPassword <> '') then
      begin
        HTTP.UserName := FUsername;
        HTTP.Password := FPassword;
      end;
      HTTP.Get(FullURL, Stream);

      if Stream.Size = 0 then
      begin
        LastError := 'HTTP response is empty from: ' + FullURL;
        Exit;
      end;

      Stream.Position := 0;

      // Real decoding: let TPicture detect format from stream content
      Pic := TPicture.Create;
      try
        try
          Pic.LoadFromStream(Stream);
          ABmp := TBitmap.Create;
          ABmp.Assign(Pic.Graphic);
          Result := True;
        except
          on E: Exception do
          begin
            LastError := 'Failed to decode image from ' + FullURL + ': ' + E.Message;
            FreeAndNil(ABmp);
          end;
        end;
      finally
        Pic.Free;
      end;

    except
      on E: Exception do
      begin
        LastError := 'HTTP snapshot failed for ' + FullURL + ': ' + E.Message;
      end;
    end;
  finally
    HTTP.Free;
    Stream.Free;
  end;
end;

{ =========================================================== }
{ TAIRTSPBackend                                              }
{ =========================================================== }

function TAIRTSPBackend.Start: Boolean;
begin
  Result := False;
  LastError := 'RTSP backend not implemented yet. ' +
    'Use cskCameraIPSnapshot mode or an external FFmpeg/OpenCV bridge.';
end;

procedure TAIRTSPBackend.Stop;
begin
  // nothing to stop
end;

function TAIRTSPBackend.CaptureFrame(out ABmp: TBitmap): Boolean;
begin
  Result := False;
  ABmp := nil;
  LastError := 'RTSP backend not implemented yet. ' +
    'Use cskCameraIPSnapshot mode or an external FFmpeg/OpenCV bridge.';
end;

{ =========================================================== }
{ TAIScreenCaptureBackend                                     }
{ =========================================================== }

constructor TAIScreenCaptureBackend.Create(const ACaptureRect: TRect;
  ACaptureFullScreen: Boolean);
begin
  inherited Create;
  FCaptureRect       := ACaptureRect;
  FCaptureFullScreen := ACaptureFullScreen;
end;

function TAIScreenCaptureBackend.Start: Boolean;
begin
  Result := True; // Screen is always available
end;

procedure TAIScreenCaptureBackend.Stop;
begin
  // nothing to stop
end;

function TAIScreenCaptureBackend.CaptureFrame(out ABmp: TBitmap): Boolean;
var
  ScreenDC: HDC;
  LCanvas: TCanvas;
  W, H: Integer;
  R: TRect;
begin
  Result := False;
  ABmp := nil;
  LastError := '';

  {$IFDEF MSWINDOWS}
  ScreenDC := GetDC(0);
  {$ELSE}
  ScreenDC := LCLIntf.GetDC(0);
  {$ENDIF}

  if ScreenDC = 0 then
  begin
    LastError := 'Failed to get screen device context.';
    Exit;
  end;

  try
    LCanvas := TCanvas.Create;
    try
      LCanvas.Handle := ScreenDC;
      if FCaptureFullScreen then
      begin
        W := Screen.Width;
        H := Screen.Height;
        R := Classes.Rect(0, 0, W, H);
      end
      else
      begin
        R := FCaptureRect;
        W := R.Right - R.Left;
        H := R.Bottom - R.Top;
      end;

      ABmp := TBitmap.Create;
      ABmp.Width  := W;
      ABmp.Height := H;
      ABmp.Canvas.CopyRect(Classes.Rect(0, 0, W, H), LCanvas, R);
      Result := True;
    finally
      LCanvas.Free;
    end;
  finally
    {$IFDEF MSWINDOWS}
    ReleaseDC(0, ScreenDC);
    {$ELSE}
    LCLIntf.ReleaseDC(0, ScreenDC);
    {$ENDIF}
  end;
end;

{ =========================================================== }
{ TAIFileCaptureBackend                                       }
{ =========================================================== }

constructor TAIFileCaptureBackend.Create(const AInputFile: string);
begin
  inherited Create;
  FInputFile := AInputFile;
end;

function TAIFileCaptureBackend.Start: Boolean;
begin
  if not FileExists(FInputFile) then
  begin
    LastError := 'File not found: ' + FInputFile;
    Result := False;
  end
  else
    Result := True;
end;

procedure TAIFileCaptureBackend.Stop;
begin
  // nothing to stop
end;

function TAIFileCaptureBackend.CaptureFrame(out ABmp: TBitmap): Boolean;
var
  Pic: TPicture;
begin
  Result := False;
  ABmp := nil;
  LastError := '';

  if not FileExists(FInputFile) then
  begin
    LastError := 'File not found: ' + FInputFile;
    Exit;
  end;

  Pic := TPicture.Create;
  try
    try
      Pic.LoadFromFile(FInputFile);
      ABmp := TBitmap.Create;
      ABmp.Assign(Pic.Graphic);
      Result := True;
    except
      on E: Exception do
      begin
        LastError := 'Failed to load image file: ' + E.Message;
        FreeAndNil(ABmp);
      end;
    end;
  finally
    Pic.Free;
  end;
end;

{ =========================================================== }
{ TAICaptureSource                                            }
{ =========================================================== }

constructor TAICaptureSource.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Component TAICaptureSource is the unified capture source for the AI Suite. ' +
    'It supports local camera (VFW/V4L2), IP camera snapshot (HTTP/HTTPS), ' +
    'screen capture, and file frame loading. SourceKind selects the active mode.';

  FSourceKind          := cskCameraLocal;
  FActive              := False;
  FWidth               := 640;
  FHeight              := 480;
  FFPS                 := 30;
  FCaptureInterval     := 100;
  FAutoStart           := False;
  FLastFrameFile       := '';
  FTempFolder          := '';
  FAutoDeleteTempFiles := True;

  FCameraIndex    := 0;
  FDeviceName     := '';
  FBackend        := cbAuto;
  FPreviewHandle  := 0;
  FPreviewEnabled := True;
  FMaxCameraScan  := 5;

  FIPAddress   := '192.168.1.50';
  FPort        := 80;
  FSnapshotURL := '/cgi-bin/snapshot.jpg';
  FStreamURL   := '';
  FUsername    := 'admin';
  FPassword    := 'admin';
  FUseHTTPS    := False;
  FTimeoutMs   := 5000;

  FCaptureMonitorIndex := 0;
  FCaptureFullScreen   := True;
  FCaptureRect         := Classes.Rect(0, 0, 0, 0);
  FTrackMouse          := True;
  FTrackKeyboard       := False; // OFF by default for security
  FPollingInterval     := 50;
  FLastMouseX          := -1;
  FLastMouseY          := -1;

  FInputFile := '';

  for I := 0 to 255 do
    FLastKeyStates[I] := False;

  FActiveBackend := nil;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FCaptureInterval;
  FTimer.OnTimer := @OnTimerTick;
  FInTimerCall := False;

  ClearError;
end;

destructor TAICaptureSource.Destroy;
begin
  StopCapture;
  if FAutoDeleteTempFiles and (FLastFrameFile <> '') and FileExists(FLastFrameFile) then
    try SysUtils.DeleteFile(FLastFrameFile); except end;
  inherited Destroy;
end;

function TAICaptureSource.GetActualTempFolder: string;
begin
  if FTempFolder <> '' then
    Result := IncludeTrailingPathDelimiter(FTempFolder)
  else
    Result := IncludeTrailingPathDelimiter(GetTempDir);
end;

function TAICaptureSource.BuildActiveBackend: TAICaptureBackendBase;
begin
  Result := nil;
  case FSourceKind of
    cskCameraLocal:
      Result := TAILocalCameraBackend.Create(
        FCameraIndex, FDeviceName, FWidth, FHeight, FFPS,
        FPreviewHandle, FPreviewEnabled, FMaxCameraScan,
        GetActualTempFolder);

    cskCameraIPSnapshot:
      Result := TAIIPSnapshotBackend.Create(
        FIPAddress, FPort, FSnapshotURL,
        FUsername, FPassword, FUseHTTPS, FTimeoutMs);

    cskCameraIPRTSP:
      Result := TAIRTSPBackend.Create;

    cskScreen:
      Result := TAIScreenCaptureBackend.Create(FCaptureRect, FCaptureFullScreen);

    cskFile:
      Result := TAIFileCaptureBackend.Create(FInputFile);

    cskNone:
    begin
      SetError('SourceKind is cskNone. No source configured.');
      if Assigned(FOnError) then FOnError(Self, FLastError);
    end;
  end;
end;

function TAICaptureSource.SaveBitmapToTemp(ABmp: TBitmap): string;
var
  LFile: string;
begin
  LFile := GetActualTempFolder + 'tai_cs_' + IntToStr(GetTickCount64) + '.bmp';
  try
    ABmp.SaveToFile(LFile);
    Result := LFile;
  except
    on E: Exception do
    begin
      SetError('Failed to save frame to temp: ' + E.Message);
      Result := '';
    end;
  end;
end;

procedure TAICaptureSource.OnTimerTick(Sender: TObject);
begin
  if FInTimerCall then Exit;
  FInTimerCall := True;
  try
    if FActive then
    begin
      QueryFrame;
      if FSourceKind = cskScreen then
      begin
        if FTrackMouse then PollMouse;
        if FTrackKeyboard then PollKeyboard;
      end;
    end;
  finally
    FInTimerCall := False;
  end;
end;

procedure TAICaptureSource.PollMouse;
var
  P: TPoint;
begin
  P := Mouse.CursorPos;
  if (P.X <> FLastMouseX) or (P.Y <> FLastMouseY) then
  begin
    FLastMouseX := P.X;
    FLastMouseY := P.Y;
    if Assigned(FOnMouseMove) then
      FOnMouseMove(Self, P.X, P.Y);
  end;
end;

procedure TAICaptureSource.PollKeyboard;
var
  Key: Integer;
  IsDown: Boolean;
  C: Char;
begin
  {$IFDEF MSWINDOWS}
  for Key := 8 to 255 do
  begin
    IsDown := (GetAsyncKeyState(Key) and $8000) <> 0;
    if IsDown and not FLastKeyStates[Key] then
    begin
      FLastKeyStates[Key] := True;
      if Key in [32..127] then C := Char(Key) else C := #0;
      if Assigned(FOnKeyIntercepted) then
        FOnKeyIntercepted(Self, Key, C);
    end
    else if not IsDown then
      FLastKeyStates[Key] := False;
  end;
  {$ELSE}
  for Key := 8 to 127 do
  begin
    IsDown := (LCLIntf.GetKeyState(Key) and $80) <> 0;
    if IsDown and not FLastKeyStates[Key] then
    begin
      FLastKeyStates[Key] := True;
      if Assigned(FOnKeyIntercepted) then
        FOnKeyIntercepted(Self, Key, Char(Key));
    end
    else if not IsDown then
      FLastKeyStates[Key] := False;
  end;
  {$ENDIF}
end;

function TAICaptureSource.StartCapture: Boolean;
begin
  Result := False;
  ClearError;

  if FActive then
  begin
    Result := True;
    Exit;
  end;

  FActiveBackend := BuildActiveBackend;
  if not Assigned(FActiveBackend) then
    Exit;

  if not FActiveBackend.Start then
  begin
    SetError(FActiveBackend.LastError);
    FreeAndNil(FActiveBackend);
    if Assigned(FOnError) then FOnError(Self, FLastError);
    Exit;
  end;

  FActive := True;

  if FFPS > 0 then
    FTimer.Interval := 1000 div FFPS
  else
    FTimer.Interval := FCaptureInterval;
  FTimer.Enabled := True;

  if Assigned(FOnStateChange) then FOnStateChange(Self, True);
  Result := True;
end;

procedure TAICaptureSource.StopCapture;
begin
  if not FActive then Exit;
  FTimer.Enabled := False;
  if Assigned(FActiveBackend) then
  begin
    FActiveBackend.Stop;
    FreeAndNil(FActiveBackend);
  end;
  FActive := False;
  if Assigned(FOnStateChange) then FOnStateChange(Self, False);
end;

function TAICaptureSource.QueryFrame: Boolean;
var
  ABmp: TBitmap;
  LFile: string;
begin
  Result := False;
  ClearError;

  if not FActive or not Assigned(FActiveBackend) then
  begin
    SetError('Capture source is not active. Call StartCapture first.');
    if Assigned(FOnError) then FOnError(Self, FLastError);
    Exit;
  end;

  ABmp := nil;
  if not FActiveBackend.CaptureFrame(ABmp) or not Assigned(ABmp) then
  begin
    SetError('CaptureFrame failed: ' + FActiveBackend.LastError);
    if Assigned(FOnError) then FOnError(Self, FLastError);
    FreeAndNil(ABmp);
    Exit;
  end;

  try
    LFile := SaveBitmapToTemp(ABmp);
    if LFile = '' then
    begin
      if Assigned(FOnError) then FOnError(Self, FLastError);
      Exit;
    end;

    // Delete previous temp file
    if FAutoDeleteTempFiles and (FLastFrameFile <> '') and
       (FLastFrameFile <> LFile) and FileExists(FLastFrameFile) then
      try SysUtils.DeleteFile(FLastFrameFile); except end;

    FLastFrameFile := LFile;
    FLastResult := 'Frame captured: ' + LFile;
    FLastSuccess := True;
    Result := True;

    if Assigned(FOnFrame) then FOnFrame(Self, FLastFrameFile);
  finally
    ABmp.Free;
  end;
end;

function TAICaptureSource.CaptureToFile(const AFileName: string): Boolean;
var
  ABmp: TBitmap;
begin
  Result := False;
  ClearError;

  if not FActive or not Assigned(FActiveBackend) then
  begin
    SetError('Capture source is not active.');
    if Assigned(FOnError) then FOnError(Self, FLastError);
    Exit;
  end;

  // LocalCamera has optimised CaptureToFile
  if (FSourceKind = cskCameraLocal) and
     (FActiveBackend is TAILocalCameraBackend) then
  begin
    Result := TAILocalCameraBackend(FActiveBackend).CaptureToFile(AFileName);
    if not Result then
    begin
      SetError(FActiveBackend.LastError);
      if Assigned(FOnError) then FOnError(Self, FLastError);
    end
    else
    begin
      FLastFrameFile := AFileName;
      FLastSuccess := True;
    end;
    Exit;
  end;

  // Generic path: capture to bitmap then save
  ABmp := nil;
  if FActiveBackend.CaptureFrame(ABmp) and Assigned(ABmp) then
  begin
    try
      ABmp.SaveToFile(AFileName);
      FLastFrameFile := AFileName;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to save frame to ' + AFileName + ': ' + E.Message);
        if Assigned(FOnError) then FOnError(Self, FLastError);
      end;
    end;
    ABmp.Free;
  end
  else
  begin
    SetError('CaptureFrame failed: ' + FActiveBackend.LastError);
    if Assigned(FOnError) then FOnError(Self, FLastError);
    FreeAndNil(ABmp);
  end;
end;

function TAICaptureSource.CaptureToBitmap(out ABmp: TBitmap): Boolean;
begin
  Result := False;
  ABmp := nil;
  ClearError;

  if not FActive or not Assigned(FActiveBackend) then
  begin
    SetError('Capture source is not active.');
    if Assigned(FOnError) then FOnError(Self, FLastError);
    Exit;
  end;

  Result := FActiveBackend.CaptureFrame(ABmp);
  if not Result then
  begin
    SetError(FActiveBackend.LastError);
    FreeAndNil(ABmp);
    if Assigned(FOnError) then FOnError(Self, FLastError);
  end;
end;

function TAICaptureSource.CaptureToImage(AImage: TImage): Boolean;
var
  ABmp: TBitmap;
begin
  Result := False;
  if not Assigned(AImage) then
  begin
    SetError('TImage parameter is nil.');
    if Assigned(FOnError) then FOnError(Self, FLastError);
    Exit;
  end;

  if CaptureToBitmap(ABmp) then
  begin
    try
      AImage.Picture.Assign(ABmp);
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to assign frame to TImage: ' + E.Message);
        if Assigned(FOnError) then FOnError(Self, FLastError);
      end;
    end;
    ABmp.Free;
  end;
end;

function TAICaptureSource.SelfTest: Boolean;
var
  LBmp: TBitmap;
  LBackend: TAICaptureBackendBase;
begin
  Result := False;
  ClearError;

  LBackend := BuildActiveBackend;
  if not Assigned(LBackend) then Exit;
  try
    if not LBackend.Start then
    begin
      SetError('SelfTest: Start failed — ' + LBackend.LastError);
      Exit;
    end;

    LBmp := nil;
    if LBackend.CaptureFrame(LBmp) and Assigned(LBmp) then
    begin
      FLastResult := 'SelfTest OK — frame ' + IntToStr(LBmp.Width) + 'x' +
        IntToStr(LBmp.Height) + ' captured successfully.';
      FLastSuccess := True;
      Result := True;
      LBmp.Free;
    end
    else
      SetError('SelfTest: CaptureFrame failed — ' + LBackend.LastError);

    LBackend.Stop;
  finally
    LBackend.Free;
  end;
end;

function TAICaptureSource.ListAvailableSources: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('cskCameraLocal    — Local camera (VFW/V4L2 native)');
  Result.Add('cskCameraIPSnapshot — IP camera HTTP/HTTPS snapshot');
  Result.Add('cskCameraIPRTSP   — IP camera RTSP (not yet implemented)');
  Result.Add('cskScreen         — Desktop screen capture');
  Result.Add('cskFile           — Static image file');
end;

function TAICaptureSource.ListAvailableCameras: TStringList;
var
  LBackend: TAILocalCameraBackend;
begin
  LBackend := TAILocalCameraBackend.Create(
    FCameraIndex, FDeviceName, FWidth, FHeight, FFPS,
    FPreviewHandle, FPreviewEnabled, FMaxCameraScan,
    GetActualTempFolder);
  try
    if LBackend.Start then
    begin
      Result := LBackend.ListCameras;
      LBackend.Stop;
    end
    else
    begin
      Result := TStringList.Create;
      Result.Add('Error: ' + LBackend.LastError);
    end;
  finally
    LBackend.Free;
  end;
end;

initialization
  {$I aicapturesource_icon.lrs}

end.
