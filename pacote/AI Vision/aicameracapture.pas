unit aicameracapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, ExtCtrls, LResources, Controls, Graphics
  {$IFDEF MSWINDOWS}
  , Windows, Messages
  {$ENDIF}
  ;

type
  TAICameraBackend = (
    cbAuto,
    cbWindowsVFW,
    cbNativeStub
  );

  TAIFrameEvent = procedure(Sender: TObject; const AFrameFile: string) of object;
  TAICameraErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TAICameraStateEvent = procedure(Sender: TObject; AActive: Boolean) of object;

  { TAICameraCapture }

  TAICameraCapture = class(TAIBaseComponent)
  private
    FCameraIndex: Integer;
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

    {$IFDEF MSWINDOWS}
    FCaptureWnd: HWND;
    {$ENDIF}

    FOnFrame: TAIFrameEvent;
    FOnError: TAICameraErrorEvent;
    FOnStateChange: TAICameraStateEvent;

    procedure OnTimerCapture(Sender: TObject);
    function GetActualTempFolder: string;
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

{$IFDEF MSWINDOWS}
const
  WM_CAP_START                  = WM_USER;
  WM_CAP_DRIVER_CONNECT         = WM_CAP_START + 10;
  WM_CAP_DRIVER_DISCONNECT      = WM_CAP_START + 11;
  WM_CAP_FILE_SAVEDIB           = WM_CAP_START + 25;
  WM_CAP_SET_PREVIEW            = WM_CAP_START + 50;
  WM_CAP_SET_PREVIEWRATE        = WM_CAP_START + 52;
  WM_CAP_GRAB_FRAME             = WM_CAP_START + 60;

function capCreateCaptureWindowA(
  lpszWindowName: PChar;
  dwStyle: DWORD;
  x, y, nWidth, nHeight: Integer;
  hwndParent: HWND;
  nID: Integer
): HWND; stdcall; external 'avicap32.dll';

function capGetDriverDescriptionA(
  wDriverIndex: Word;
  lpszName: PChar;
  cbName: Integer;
  lpszVer: PChar;
  cbVer: Integer
): BOOL; stdcall; external 'avicap32.dll';
{$ENDIF}

{ TAICameraCapture }

constructor TAICameraCapture.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Component TAICameraCapture captures frames from camera inputs natively using Windows VFW.';
  FCameraIndex := 0;
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

  {$IFDEF MSWINDOWS}
  FCaptureWnd := 0;
  {$ENDIF}

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
begin
  Result := False;
  ClearError;

  if FActive then
  begin
    Result := True;
    Exit;
  end;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  if (FBackend = cbAuto) or (FBackend = cbWindowsVFW) then
  begin
    if FPreviewEnabled and (FPreviewHandle = 0) then
    begin
      SetError('PreviewHandle is required when PreviewEnabled is True.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
      Exit;
    end;

    FCaptureWnd := capCreateCaptureWindowA(
      'TAICameraCaptureWnd',
      WS_CHILD or WS_VISIBLE,
      0, 0, FWidth, FHeight,
      FPreviewHandle,
      0
    );

    if FCaptureWnd = 0 then
    begin
      SetError('Could not create capture window.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
      Exit;
    end;

    if SendMessage(FCaptureWnd, WM_CAP_DRIVER_CONNECT, FCameraIndex, 0) = 0 then
    begin
      DestroyWindow(FCaptureWnd);
      FCaptureWnd := 0;
      SetError('Could not connect to camera driver.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
      Exit;
    end;

    if FPreviewEnabled then
    begin
      SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEWRATE, FCaptureInterval, 0);
      SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEW, 1, 0);
    end;

    FActive := True;
    FTimer.Interval := FCaptureInterval;
    FTimer.Enabled := True;

    if Assigned(FOnStateChange) then
      FOnStateChange(Self, True);

    Result := True;
  end
  else
  begin
    SetError('Backend not implemented.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
  end;
  {$ELSE}
  SetError('Platform not supported in this version.');
  if Assigned(FOnError) then
    FOnError(Self, FLastError);
  {$ENDIF}
end;

procedure TAICameraCapture.StopCapture;
begin
  if not FActive then Exit;

  FTimer.Enabled := False;

  {$IFDEF MSWINDOWS}
  if FCaptureWnd <> 0 then
  begin
    SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEW, 0, 0);
    SendMessage(FCaptureWnd, WM_CAP_DRIVER_DISCONNECT, 0, 0);
    DestroyWindow(FCaptureWnd);
    FCaptureWnd := 0;
  end;
  {$ENDIF}

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

  if not FActive then
  begin
    SetError('Camera is not active.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  if FCaptureWnd <> 0 then
  begin
    LTempFile := GetActualTempFolder + 'tai_frame_' + IntToStr(GetTickCount64) + '.bmp';
    
    if SendMessage(FCaptureWnd, WM_CAP_GRAB_FRAME, 0, 0) <> 0 then
    begin
      if SendMessage(FCaptureWnd, WM_CAP_FILE_SAVEDIB, 0, LPARAM(PtrUInt(PChar(LTempFile)))) <> 0 then
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
        end
        else
        begin
          SetError('Could not save frame file.');
          if Assigned(FOnError) then
            FOnError(Self, FLastError);
        end;
      end
      else
      begin
        SetError('Could not save frame file.');
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
      end;
    end
    else
    begin
      SetError('Could not capture frame.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
    end;
  end;
  {$ELSE}
  SetError('Platform not supported.');
  if Assigned(FOnError) then
    FOnError(Self, FLastError);
  {$ENDIF}
end;

function TAICameraCapture.CaptureToFile(const AFileName: string): Boolean;
begin
  Result := False;
  ClearError;

  if not FActive then
  begin
    SetError('Camera is not active.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  if FCaptureWnd <> 0 then
  begin
    if SendMessage(FCaptureWnd, WM_CAP_GRAB_FRAME, 0, 0) <> 0 then
    begin
      if SendMessage(FCaptureWnd, WM_CAP_FILE_SAVEDIB, 0, LPARAM(PtrUInt(PChar(AFileName)))) <> 0 then
      begin
        if FileExists(AFileName) then
        begin
          FLastFrameFile := AFileName;
          FLastResult := 'Frame saved to: ' + AFileName;
          FLastSuccess := True;
          Result := True;
        end
        else
        begin
          SetError('Could not save frame file.');
          if Assigned(FOnError) then
            FOnError(Self, FLastError);
        end;
      end
      else
      begin
        SetError('Could not save frame file.');
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
      end;
    end
    else
    begin
      SetError('Could not capture frame.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
    end;
  end;
  {$ELSE}
  SetError('Platform not supported.');
  if Assigned(FOnError) then
    FOnError(Self, FLastError);
  {$ENDIF}
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
  {$IFDEF MSWINDOWS}
  LTestWnd: HWND;
  LTempFile: string;
  {$ENDIF}
begin
  Result := False;
  ClearError;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  if (FBackend = cbAuto) or (FBackend = cbWindowsVFW) then
  begin
    LTestWnd := capCreateCaptureWindowA('TaisSelfTestWnd', 0, 0, 0, 160, 120, 0, 0);
    if LTestWnd <> 0 then
    begin
      if SendMessage(LTestWnd, WM_CAP_DRIVER_CONNECT, FCameraIndex, 0) <> 0 then
      begin
        LTempFile := GetActualTempFolder + 'tai_selftest_' + IntToStr(GetTickCount64) + '.bmp';
        if SendMessage(LTestWnd, WM_CAP_GRAB_FRAME, 0, 0) <> 0 then
        begin
          if SendMessage(LTestWnd, WM_CAP_FILE_SAVEDIB, 0, LPARAM(PtrUInt(PChar(LTempFile)))) <> 0 then
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
            SetError('SelfTest could not save frame to DIB.');
        end
        else
          SetError('SelfTest could not grab frame.');
          
        SendMessage(LTestWnd, WM_CAP_DRIVER_DISCONNECT, 0, 0);
      end
      else
        SetError('SelfTest could not connect to camera driver.');
      DestroyWindow(LTestWnd);
    end
    else
      SetError('SelfTest could not create capture window.');
  end
  else
    SetError('Backend not implemented.');
  {$ELSE}
  SetError('Platform not supported.');
  {$ENDIF}
end;

function TAICameraCapture.ListAvailableCameras: TStringList;
var
  LTempList: TStringList;
  {$IFDEF MSWINDOWS}
  I: Integer;
  LName: array[0..255] of Char;
  LVer: array[0..255] of Char;
  {$ENDIF}
begin
  LTempList := TStringList.Create;
  Result := LTempList;
  ClearError;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  for I := 0 to FMaxCameraScan do
  begin
    FillChar(LName, SizeOf(LName), 0);
    FillChar(LVer, SizeOf(LVer), 0);
    if capGetDriverDescriptionA(I, LName, SizeOf(LName), LVer, SizeOf(LVer)) then
    begin
      LTempList.Add(IntToStr(I) + ' - ' + string(LName));
    end;
  end;
  {$ELSE}
  SetError('Platform not supported.');
  {$ENDIF}
end;

initialization
  {$I aicameracapture_icon.lrs}

end.
