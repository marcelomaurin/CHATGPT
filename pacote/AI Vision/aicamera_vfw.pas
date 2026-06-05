unit aicamera_vfw;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aicamera_backend
  {$IFDEF MSWINDOWS}
  , Windows, Messages
  {$ENDIF}
  ;

type
  {$IFDEF MSWINDOWS}
  { TAICameraVFWBackend }

  TAICameraVFWBackend = class(TAICameraNativeBackend)
  private
    FCaptureWnd: HWND;
    FParentWnd: HWND;
    FWidth: Integer;
    FHeight: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    function OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean; override;
    procedure CloseCamera; override;
    function CaptureToFile(const AFileName: string): Boolean; override;
    function ListCameras(AMaxScan: Integer): TStringList; override;
  end;
  {$ELSE}
  { TAICameraVFWBackend stub }

  TAICameraVFWBackend = class(TAICameraNativeBackend)
  public
    function OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean; override;
    procedure CloseCamera; override;
    function CaptureToFile(const AFileName: string): Boolean; override;
    function ListCameras(AMaxScan: Integer): TStringList; override;
  end;
  {$ENDIF}

implementation

{$IFNDEF MSWINDOWS}
{ Stub Implementation for Non-Windows Platforms }

function TAICameraVFWBackend.OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean;
begin
  LastError := 'VFW backend is only supported on Windows.';
  Result := False;
end;

procedure TAICameraVFWBackend.CloseCamera;
begin
end;

function TAICameraVFWBackend.CaptureToFile(const AFileName: string): Boolean;
begin
  LastError := 'VFW backend is only supported on Windows.';
  Result := False;
end;

function TAICameraVFWBackend.ListCameras(AMaxScan: Integer): TStringList;
begin
  Result := TStringList.Create;
end;

{$ELSE}
{ Full Windows VFW Implementation }

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

constructor TAICameraVFWBackend.Create;
begin
  inherited Create;
  FCaptureWnd := 0;
  FParentWnd := 0;
  FWidth := 640;
  FHeight := 480;
end;

destructor TAICameraVFWBackend.Destroy;
begin
  CloseCamera;
  inherited Destroy;
end;

function TAICameraVFWBackend.OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean;
var
  LCaptureInterval: Integer;
begin
  Result := False;
  LastError := '';
  
  if FCaptureWnd <> 0 then
  begin
    Result := True;
    Exit;
  end;

  if APreviewEnabled and (APreviewHandle = 0) then
  begin
    LastError := 'PreviewHandle is required when PreviewEnabled is True.';
    Exit;
  end;

  FParentWnd := APreviewHandle;
  FWidth := AWidth;
  FHeight := AHeight;

  FCaptureWnd := capCreateCaptureWindowA(
    'TAICameraVFWCaptureWnd',
    WS_CHILD or WS_VISIBLE,
    0, 0, FWidth, FHeight,
    FParentWnd,
    0
  );

  if FCaptureWnd = 0 then
  begin
    LastError := 'Could not create VFW capture window.';
    Exit;
  end;

  if SendMessage(FCaptureWnd, WM_CAP_DRIVER_CONNECT, AIndex, 0) = 0 then
  begin
    DestroyWindow(FCaptureWnd);
    FCaptureWnd := 0;
    LastError := 'Could not connect to camera driver at index ' + IntToStr(AIndex);
    Exit;
  end;

  if AFPS > 0 then
    LCaptureInterval := 1000 div AFPS
  else
    LCaptureInterval := 100;

  if APreviewEnabled then
  begin
    SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEWRATE, LCaptureInterval, 0);
    SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEW, 1, 0);
  end;

  Result := True;
end;

procedure TAICameraVFWBackend.CloseCamera;
begin
  if FCaptureWnd <> 0 then
  begin
    SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEW, 0, 0);
    SendMessage(FCaptureWnd, WM_CAP_DRIVER_DISCONNECT, 0, 0);
    DestroyWindow(FCaptureWnd);
    FCaptureWnd := 0;
  end;
  FParentWnd := 0;
end;

function TAICameraVFWBackend.CaptureToFile(const AFileName: string): Boolean;
begin
  Result := False;
  LastError := '';

  if FCaptureWnd = 0 then
  begin
    LastError := 'Camera is not open.';
    Exit;
  end;

  if SendMessage(FCaptureWnd, WM_CAP_GRAB_FRAME, 0, 0) <> 0 then
  begin
    // Convert AFileName (which might be Unicode) to Windows compatible LPARAM string pointer
    if SendMessage(FCaptureWnd, WM_CAP_FILE_SAVEDIB, 0, LPARAM(PtrUInt(PChar(AFileName)))) <> 0 then
    begin
      if FileExists(AFileName) then
      begin
        Result := True;
      end
      else
        LastError := 'VFW reported success but output file was not found.';
    end
    else
      LastError := 'Failed to save DIB image via VFW.';
  end
  else
    LastError := 'Failed to grab frame via VFW.';
end;

function TAICameraVFWBackend.ListCameras(AMaxScan: Integer): TStringList;
var
  I: Integer;
  LName: array[0..255] of Char;
  LVer: array[0..255] of Char;
begin
  Result := TStringList.Create;
  for I := 0 to AMaxScan - 1 do
  begin
    FillChar(LName, SizeOf(LName), 0);
    FillChar(LVer, SizeOf(LVer), 0);
    if capGetDriverDescriptionA(I, LName, SizeOf(LName), LVer, SizeOf(LVer)) then
    begin
      Result.Add(IntToStr(I) + ' - ' + string(LName));
    end;
  end;
end;

{$ENDIF}

end.
