unit aicameracapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, ExtCtrls, LResources, Controls, Graphics,
  aicamera_backend
  {$IFDEF MSWINDOWS}
  , aicamera_vfw
  {$ENDIF}
  {$IFDEF LINUX}
  , aicamera_v4l2
  {$ENDIF}
  ;

type
  TAIFrameEvent = procedure(Sender: TObject; const AFrameFile: string) of object;
  TAICameraErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TAICameraStateEvent = procedure(Sender: TObject; AActive: Boolean) of object;

  { TAICameraCapture }

  TAICameraCapture = class(TAIBaseComponent)
  private
    FCameraIndex: Integer;
    FDeviceName: string;
    FActive: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    FFPS: Integer;
    FBackend: TAICameraBackend;
    FPreviewHandle: THandle;
    FPreviewEnabled: Boolean;
    FLastFrameFile: string;
    FTempFolder: string;
    FAutoDeleteTempFiles: Boolean;
    FCaptureInterval: Integer;
    FMaxCameraScan: Integer;

    FTimer: TTimer;
    FInTimerCall: Boolean;
    FActiveBackend: TAICameraNativeBackend;

    FOnFrame: TAIFrameEvent;
    FOnError: TAICameraErrorEvent;
    FOnStateChange: TAICameraStateEvent;

    procedure OnTimerCapture(Sender: TObject);
    function GetActualTempFolder: string;
    function ResolveBackend: TAICameraBackend;
    function CreateBackendInstance(ABackend: TAICameraBackend): TAICameraNativeBackend;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function StartCapture: Boolean;
    procedure StopCapture;
    function QueryFrame: Boolean;
    function CaptureToFile(const AFileName: string): Boolean;
    function CaptureToImage(AImage: TImage): Boolean;
    function SelfTest: Boolean;
    function ListAvailableCameras: TStringList;

    property Active: Boolean read FActive;
    property LastFrameFile: string read FLastFrameFile;
  published
    property CameraIndex: Integer read FCameraIndex write FCameraIndex default 0;
    property DeviceName: string read FDeviceName write FDeviceName;
    property Width: Integer read FWidth write FWidth default 640;
    property Height: Integer read FHeight write FHeight default 480;
    property FPS: Integer read FFPS write FFPS default 30;
    property Backend: TAICameraBackend read FBackend write FBackend default cbAuto;
    property PreviewHandle: THandle read FPreviewHandle write FPreviewHandle default 0;
    property PreviewEnabled: Boolean read FPreviewEnabled write FPreviewEnabled default True;
    property TempFolder: string read FTempFolder write FTempFolder;
    property AutoDeleteTempFiles: Boolean read FAutoDeleteTempFiles write FAutoDeleteTempFiles default True;
    property CaptureInterval: Integer read FCaptureInterval write FCaptureInterval default 100;
    property MaxCameraScan: Integer read FMaxCameraScan write FMaxCameraScan default 5;

    // Events
    property OnFrame: TAIFrameEvent read FOnFrame write FOnFrame;
    property OnError: TAICameraErrorEvent read FOnError write FOnError;
    property OnStateChange: TAICameraStateEvent read FOnStateChange write FOnStateChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAICameraCapture]);
end;

{ TAICameraCapture }

constructor TAICameraCapture.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Component TAICameraCapture captures frames from camera inputs natively using OS-specific backends.';
  FCameraIndex := 0;
  FDeviceName := '';
  FActive := False;
  FWidth := 640;
  FHeight := 480;
  FFPS := 30;
  FBackend := cbAuto;
  FPreviewHandle := 0;
  FPreviewEnabled := True;
  FLastFrameFile := '';
  FTempFolder := '';
  FAutoDeleteTempFiles := True;
  FCaptureInterval := 100;
  FMaxCameraScan := 5;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := @OnTimerCapture;
  FInTimerCall := False;
  
  FActiveBackend := nil;

  ClearError;
end;

destructor TAICameraCapture.Destroy;
begin
  StopCapture;
  if FAutoDeleteTempFiles and (FLastFrameFile <> '') and FileExists(FLastFrameFile) then
  begin
    try
      SysUtils.DeleteFile(FLastFrameFile);
    except
      // ignore
    end;
  end;
  inherited Destroy;
end;

function TAICameraCapture.GetActualTempFolder: string;
begin
  if FTempFolder <> '' then
    Result := IncludeTrailingPathDelimiter(FTempFolder)
  else
    Result := IncludeTrailingPathDelimiter(GetTempDir);
end;

function TAICameraCapture.ResolveBackend: TAICameraBackend;
begin
  Result := FBackend;
  if Result = cbAuto then
  begin
    {$IFDEF MSWINDOWS}
    Result := cbWindowsVFW;
    {$ELSE}
      {$IFDEF LINUX}
      Result := cbLinuxV4L2;
      {$ELSE}
      Result := cbNativeStub;
      {$ENDIF}
    {$ENDIF}
  end;
end;

function TAICameraCapture.CreateBackendInstance(ABackend: TAICameraBackend): TAICameraNativeBackend;
begin
  Result := nil;
  case ABackend of
    cbWindowsVFW:
      begin
        {$IFDEF MSWINDOWS}
        Result := TAICameraVFWBackend.Create;
        {$ENDIF}
      end;
    cbLinuxV4L2:
      begin
        {$IFDEF LINUX}
        Result := TAICameraV4L2Backend.Create;
        {$ENDIF}
      end;
  end;
end;

procedure TAICameraCapture.OnTimerCapture(Sender: TObject);
begin
  if FInTimerCall then Exit;
  FInTimerCall := True;
  try
    if FActive then
      QueryFrame;
  finally
    FInTimerCall := False;
  end;
end;

function TAICameraCapture.StartCapture: Boolean;
var
  LResBackend: TAICameraBackend;
begin
  Result := False;
  ClearError;

  if FActive then
  begin
    Result := True;
    Exit;
  end;

  LResBackend := ResolveBackend;
  if LResBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet on this platform.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  FActiveBackend := CreateBackendInstance(LResBackend);
  if not Assigned(FActiveBackend) then
  begin
    SetError('Failed to instantiate camera backend.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  if not FActiveBackend.OpenCamera(FDeviceName, FCameraIndex, FWidth, FHeight, FFPS, FPreviewHandle, FPreviewEnabled) then
  begin
    SetError(FActiveBackend.LastError);
    FreeAndNil(FActiveBackend);
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  FActive := True;
  
  if FFPS > 0 then
    FCaptureInterval := 1000 div FFPS
  else
    FCaptureInterval := 100;
    
  FTimer.Interval := FCaptureInterval;
  FTimer.Enabled := True;

  if Assigned(FOnStateChange) then
    FOnStateChange(Self, True);

  Result := True;
end;

procedure TAICameraCapture.StopCapture;
begin
  if not FActive then Exit;

  FTimer.Enabled := False;

  if Assigned(FActiveBackend) then
  begin
    FActiveBackend.CloseCamera;
    FreeAndNil(FActiveBackend);
  end;

  FActive := False;

  if Assigned(FOnStateChange) then
    FOnStateChange(Self, False);
end;

function TAICameraCapture.QueryFrame: Boolean;
var
  LTempFile: string;
begin
  Result := False;
  ClearError;

  if not FActive or not Assigned(FActiveBackend) then
  begin
    SetError('Camera is not active.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  LTempFile := GetActualTempFolder + 'tai_frame_' + IntToStr(GetTickCount64) + '.bmp';
  
  if FActiveBackend.CaptureToFile(LTempFile) then
  begin
    if FileExists(LTempFile) then
    begin
      if FAutoDeleteTempFiles and (FLastFrameFile <> '') and (FLastFrameFile <> LTempFile) and FileExists(FLastFrameFile) then
      begin
        try
          SysUtils.DeleteFile(FLastFrameFile);
        except
          // ignore
        end;
      end;

      FLastFrameFile := LTempFile;
      FLastResult := 'Frame captured successfully: ' + LTempFile;
      FLastSuccess := True;
      Result := True;

      if Assigned(FOnFrame) then
        FOnFrame(Self, FLastFrameFile);
    end;
  end;

  if not Result then
  begin
    SetError('Failed to capture frame: ' + FActiveBackend.LastError);
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
  end;
end;

function TAICameraCapture.CaptureToFile(const AFileName: string): Boolean;
begin
  Result := False;
  ClearError;

  if not FActive or not Assigned(FActiveBackend) then
  begin
    SetError('Camera is not active.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  if FActiveBackend.CaptureToFile(AFileName) then
  begin
    FLastFrameFile := AFileName;
    FLastResult := 'Frame saved to: ' + AFileName;
    FLastSuccess := True;
    Result := True;
  end
  else
  begin
    SetError(FActiveBackend.LastError);
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
  end;
end;

function TAICameraCapture.CaptureToImage(AImage: TImage): Boolean;
begin
  Result := False;
  if not Assigned(AImage) then
  begin
    SetError('TImage parameter is nil.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  if QueryFrame then
  begin
    try
      AImage.Picture.LoadFromFile(FLastFrameFile);
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to load image into TImage: ' + E.Message);
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
      end;
    end;
  end;
end;

function TAICameraCapture.SelfTest: Boolean;
var
  LResBackend: TAICameraBackend;
  LTestBackend: TAICameraNativeBackend;
  LTempFile: string;
begin
  Result := False;
  ClearError;

  LResBackend := ResolveBackend;
  if LResBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    Exit;
  end;

  LTestBackend := CreateBackendInstance(LResBackend);
  if not Assigned(LTestBackend) then
  begin
    SetError('Could not instantiate camera backend.');
    Exit;
  end;

  try
    if LTestBackend.OpenCamera(FDeviceName, FCameraIndex, 160, 120, 15, 0, False) then
    begin
      LTempFile := GetActualTempFolder + 'tai_selftest_' + IntToStr(GetTickCount64) + '.bmp';
      if LTestBackend.CaptureToFile(LTempFile) then
      begin
        if FileExists(LTempFile) then
        begin
          Result := True;
          SysUtils.DeleteFile(LTempFile);
        end
        else
          SetError('SelfTest frame file was not created.');
      end
      else
        SetError('SelfTest could not capture frame: ' + LTestBackend.LastError);
      
      LTestBackend.CloseCamera;
    end
    else
      SetError('SelfTest could not open camera: ' + LTestBackend.LastError);
  finally
    LTestBackend.Free;
  end;
end;

function TAICameraCapture.ListAvailableCameras: TStringList;
var
  LResBackend: TAICameraBackend;
  LTestBackend: TAICameraNativeBackend;
begin
  ClearError;
  LResBackend := ResolveBackend;
  
  if LResBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    Result := TStringList.Create;
    Exit;
  end;

  LTestBackend := CreateBackendInstance(LResBackend);
  if not Assigned(LTestBackend) then
  begin
    SetError('Could not instantiate camera backend.');
    Result := TStringList.Create;
    Exit;
  end;

  try
    Result := LTestBackend.ListCameras(FMaxCameraScan);
  finally
    LTestBackend.Free;
  end;
end;

initialization
  {$I aicameracapture_icon.lrs}

end.
