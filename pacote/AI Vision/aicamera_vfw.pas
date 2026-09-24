unit aicamera_vfw;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aicamera_backend, Graphics
  {$IFDEF MSWINDOWS}
  , Windows, Messages, ActiveX, ComObj, Variants
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
    function CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean; override;
    function ListCameras(AMaxScan: Integer): TStringList; override;
  end;
  {$ELSE}
  { TAICameraVFWBackend stub }

  TAICameraVFWBackend = class(TAICameraNativeBackend)
  public
    function OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean; override;
    procedure CloseCamera; override;
    function CaptureToFile(const AFileName: string): Boolean; override;
    function CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean; override;
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

function TAICameraVFWBackend.CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean;
begin
  LastError := 'VFW backend is only supported on Windows.';
  ABmp := nil;
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
  WM_CAP_FILE_SAVEDIBW          = WM_CAP_START + 125;
  WM_CAP_SET_PREVIEW            = WM_CAP_START + 50;
  WM_CAP_SET_PREVIEWRATE        = WM_CAP_START + 52;
  WM_CAP_SET_SCALE              = WM_CAP_START + 53;
  WM_CAP_GRAB_FRAME             = WM_CAP_START + 60;

function capCreateCaptureWindowW(
  lpszWindowName: PWideChar;
  dwStyle: DWORD;
  x, y, nWidth, nHeight: Integer;
  hwndParent: HWND;
  nID: Integer
): HWND; stdcall; external 'avicap32.dll';

function capGetDriverDescriptionW(
  wDriverIndex: Word;
  lpszName: PWideChar;
  cbName: Integer;
  lpszVer: PWideChar;
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
  LStyle: DWORD;
begin
  Result := False;
  LastError := '';
  
  if FCaptureWnd <> 0 then
  begin
    Result := True;
    Exit;
  end;

  FParentWnd := APreviewHandle;
  FWidth := AWidth;
  FHeight := AHeight;

  if FParentWnd <> 0 then
    LStyle := WS_CHILD or WS_VISIBLE
  else
    LStyle := WS_POPUP;

  FCaptureWnd := capCreateCaptureWindowW(
    'TAICameraVFWCaptureWnd',
    LStyle,
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

  if APreviewEnabled and (FParentWnd <> 0) then
  begin
    SendMessage(FCaptureWnd, WM_CAP_SET_PREVIEWRATE, LCaptureInterval, 0);
    SendMessage(FCaptureWnd, WM_CAP_SET_SCALE, 1, 0);
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
var
  LWideFileName: WideString;
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
    LWideFileName := WideString(AFileName);
    if SendMessage(FCaptureWnd, WM_CAP_FILE_SAVEDIBW, 0, LPARAM(PWideChar(LWideFileName))) <> 0 then
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

function TAICameraVFWBackend.CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean;
var
  DC: HDC;
  LCanvas: TCanvas;
begin
  Result := False;
  ABmp := nil;
  LastError := '';

  if FCaptureWnd = 0 then
  begin
    LastError := 'Camera is not open.';
    Exit;
  end;

  if SendMessage(FCaptureWnd, WM_CAP_GRAB_FRAME, 0, 0) <> 0 then
  begin
    DC := GetDC(FCaptureWnd);
    if DC <> 0 then
    begin
      try
        ABmp := Graphics.TBitmap.Create;
        ABmp.Width := FWidth;
        ABmp.Height := FHeight;
        LCanvas := TCanvas.Create;
        try
          LCanvas.Handle := DC;
          ABmp.Canvas.CopyRect(Classes.Rect(0, 0, FWidth, FHeight), LCanvas, Classes.Rect(0, 0, FWidth, FHeight));
          Result := True;
        finally
          LCanvas.Free;
        end;
      finally
        ReleaseDC(FCaptureWnd, DC);
      end;
    end
    else
      LastError := 'Failed to get device context of VfW capture window.';
  end
  else
    LastError := 'Failed to grab frame via VFW.';
end;

const
  CLSID_SystemDeviceEnum: TGUID = '{62BE5D10-60EB-11d0-BD3B-00A0C911CE86}';
  CLSID_VideoInputDeviceCategory: TGUID = '{860BB310-5D01-11d0-BD3B-00A0C911CE86}';
  IID_ICreateDevEnum: TGUID = '{29840822-5B84-11D0-BD3B-00A0C911CE86}';

type
  ICreateDevEnum = interface(IUnknown)
    ['{29840822-5B84-11D0-BD3B-00A0C911CE86}']
    function CreateClassEnumerator(const clsidDeviceClass: TGUID;
      out ppEnumMoniker: IEnumMoniker; dwFlags: DWORD): HResult; stdcall;
  end;

  IPropertyBag = interface(IUnknown)
    ['{55272A00-42CB-11CE-8135-00AA004BB851}']
    function Read(pszPropName: POleStr; var pVar: OleVariant; pErrorLog: Pointer): HResult; stdcall;
    function Write(pszPropName: POleStr; var pVar: OleVariant): HResult; stdcall;
  end;

function TAICameraVFWBackend.ListCameras(AMaxScan: Integer): TStringList;
var
  I, Count: Integer;
  LName: array[0..255] of WideChar;
  LVer: array[0..255] of WideChar;
  HR: HResult;
  NeedUninit: Boolean;
  DevEnum: ICreateDevEnum;
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  Fetched: ULONG;
  PropBagObj: IUnknown;
  PropBag: IPropertyBag;
  VarName: OleVariant;
  CamName: string;
begin
  Result := TStringList.Create;

  // 1. Tenta enumeração nativa via DirectShow (Windows 7 e superior, 32 e 64 bits)
  NeedUninit := False;
  try
    HR := CoInitialize(nil);
    NeedUninit := Succeeded(HR);

    HR := CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC_SERVER,
      IID_ICreateDevEnum, DevEnum);
    if Succeeded(HR) and (DevEnum <> nil) then
    begin
      HR := DevEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, EnumMoniker, 0);
      if Succeeded(HR) and (EnumMoniker <> nil) then
      begin
        Count := 0;
        while (EnumMoniker.Next(1, Moniker, Fetched) = S_OK) and (Count < AMaxScan) do
        begin
          try
            HR := Moniker.BindToStorage(nil, nil, IPropertyBag, PropBagObj);
            if Succeeded(HR) and Supports(PropBagObj, IPropertyBag, PropBag) then
            begin
              VarClear(VarName);
              if Succeeded(PropBag.Read('FriendlyName', VarName, nil)) then
              begin
                CamName := Trim(String(VarName));
                if CamName <> '' then
                begin
                  Result.Add(IntToStr(Count) + ' - ' + CamName);
                  Inc(Count);
                end;
              end;
            end;
          finally
            Moniker := nil;
            PropBagObj := nil;
            PropBag := nil;
          end;
        end;
      end;
    end;
  except
    // Se falhar DirectShow, continua para fallback VFW
  end;

  if NeedUninit then
    try CoUninitialize; except end;

  // 2. Se DirectShow encontrou câmeras, retorna diretamente
  if Result.Count > 0 then Exit;

  // 3. Fallback legado VFW para Windows 95/98/XP/WDM mapper
  for I := 0 to AMaxScan - 1 do
  begin
    FillChar(LName, SizeOf(LName), 0);
    FillChar(LVer, SizeOf(LVer), 0);
    if capGetDriverDescriptionW(I, LName, 255, LVer, 255) then
    begin
      Result.Add(IntToStr(I) + ' - ' + string(LName));
    end;
  end;
end;

{$ENDIF}

end.
