unit aiwindowsvideopreview;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils;

type
  TAIVideoDevice = record
    ID: string;
    Name: string;
  end;
  TAIVideoDevices = array of TAIVideoDevice;

  { Continuous, renderer-backed video. Create, use and destroy on the UI thread.
    Device IDs are DirectShow monikers, never indexes into a VFW driver list. }
  TAIWindowsVideoPreview = class
  private
    FSession: TObject;
    FActive: Boolean;
    FLastError, FDeviceName: string;
    FVideoWidth, FVideoHeight: Integer;
    procedure EnsureSession;
  public
    destructor Destroy; override;
    function ListDevices: TAIVideoDevices;
    function Start(const ADeviceID: string; AParent: THandle;
      AWidth, AHeight: Integer): Boolean;
    procedure Stop;
    procedure Resize(AWidth, AHeight: Integer);
    property Active: Boolean read FActive;
    property LastError: string read FLastError;
    property DeviceName: string read FDeviceName;
    property VideoWidth: Integer read FVideoWidth;
    property VideoHeight: Integer read FVideoHeight;
  end;

implementation

{$IFDEF MSWINDOWS}
uses Windows, ActiveX, ComObj, Variants;

const
  CLSID_SystemDeviceEnum: TGUID = '{62BE5D10-60EB-11D0-BD3B-00A0C911CE86}';
  CLSID_VideoInputDeviceCategory: TGUID = '{860BB310-5D01-11D0-BD3B-00A0C911CE86}';
  CLSID_FilterGraph: TGUID = '{E436EBB3-524F-11CE-9F53-0020AF0BA770}';
  CLSID_CaptureGraphBuilder2: TGUID = '{BF87B6E1-8C27-11D0-B3F0-00AA003761C5}';
  IID_IBaseFilter: TGUID = '{56A86895-0AD4-11CE-B03A-0020AF0BA770}';
  IID_IVideoWindow: TGUID = '{56A868B4-0AD4-11CE-B03A-0020AF0BA770}';
  IID_IBasicVideo: TGUID = '{56A868B5-0AD4-11CE-B03A-0020AF0BA770}';
  PIN_CATEGORY_PREVIEW: TGUID = '{FB6C4282-0353-11D1-905F-0000C0CC16BA}';
  MEDIATYPE_Video: TGUID = '{73646976-0000-0010-8000-00AA00389B71}';

type
  ICreateDevEnum = interface(IUnknown)
    ['{29840822-5B84-11D0-BD3B-00A0C911CE86}']
    function CreateClassEnumerator(const Category: TGUID;
      out Enumerator: IEnumMoniker; Flags: DWORD): HRESULT; stdcall;
  end;
  IDevicePropertyBag = interface(IUnknown)
    ['{55272A00-42CB-11CE-8135-00AA004BB851}']
    function Read(Name: POleStr; var Value: OleVariant;
      ErrorLog: Pointer): HRESULT; stdcall;
    function Write(Name: POleStr; var Value: OleVariant): HRESULT; stdcall;
  end;

  { Only the leading vtable methods used here are declared. Signatures and order
    match Windows SDK strmif.h/control.h; unused tail methods are never called. }
  IPreviewGraph = interface(IUnknown)
    ['{56A868A9-0AD4-11CE-B03A-0020AF0BA770}']
    function AddFilter(const Filter: IUnknown; Name: PWideChar): HRESULT; stdcall;
  end;
  IPreviewBuilder = interface(IUnknown)
    ['{93E5A4E0-2D50-11D2-ABFA-00A0C9C6E38D}']
    function SetFiltergraph(const Graph: IPreviewGraph): HRESULT; stdcall;
    function GetFiltergraph(out Graph: IPreviewGraph): HRESULT; stdcall;
    function SetOutputFileName(const Kind: TGUID; Name: PWideChar;
      out Filter, Sink: IUnknown): HRESULT; stdcall;
    function FindInterface(Category, MediaType: PGUID; const Filter: IUnknown;
      const IID: TGUID; out Intf): HRESULT; stdcall;
    function RenderStream(Category, MediaType: PGUID;
      const Source, Intermediate, Renderer: IUnknown): HRESULT; stdcall;
  end;
  IPreviewControl = interface(IDispatch)
    ['{56A868B1-0AD4-11CE-B03A-0020AF0BA770}']
    function Run: HRESULT; stdcall;
    function Pause: HRESULT; stdcall;
    function Stop: HRESULT; stdcall;
    function GetState(Timeout: LongInt; out State: LongInt): HRESULT; stdcall;
  end;

  TPreviewSession = class
  private
    FUninitialize: Boolean;
  public
    Graph: IPreviewGraph;
    Builder: IPreviewBuilder;
    Source: IUnknown;
    Control: IPreviewControl;
    Video: OleVariant;
    constructor Create;
    destructor Destroy; override;
    function Enumerator: IEnumMoniker;
    procedure Close;
  end;

procedure CheckHR(HR: HRESULT; const Operation: string);
begin
  if Failed(HR) then
    raise Exception.Create(Operation + ' (Windows 0x' + IntToHex(LongWord(HR), 8) + ').');
end;

constructor TPreviewSession.Create;
var HR: HRESULT;
begin
  inherited Create;
  HR := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  FUninitialize := Succeeded(HR);
  if (not FUninitialize) and (LongWord(HR) <> $80010106) then
    CheckHR(HR, 'Could not initialize video');
end;

destructor TPreviewSession.Destroy;
begin
  Close;
  // Every COM reference, including dispatch variants, is released first.
  if FUninitialize then CoUninitialize;
  inherited Destroy;
end;

function TPreviewSession.Enumerator: IEnumMoniker;
var DevEnum: ICreateDevEnum; HR: HRESULT;
begin
  Result := nil;
  CheckHR(CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC_SERVER,
    ICreateDevEnum, DevEnum), 'Could not enumerate cameras');
  HR := DevEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, Result, 0);
  if HR <> S_FALSE then CheckHR(HR, 'Could not enumerate cameras');
end;

procedure TPreviewSession.Close;
begin
  if Assigned(Control) then Control.Stop;
  if not VarIsEmpty(Video) then
  begin
    try Video.Visible := False; except end;
    try Video.Owner := 0; except end;
  end;
  VarClear(Video);
  Control := nil;
  Source := nil;
  Builder := nil;
  Graph := nil;
end;

function MonikerID(const Moniker: IMoniker): string;
var Name: PWideChar;
begin
  Name := nil;
  CheckHR(Moniker.GetDisplayName(nil, nil, Name), 'Could not identify camera');
  try Result := UTF8Encode(WideString(Name)); finally CoTaskMemFree(Name); end;
end;

function MonikerName(const Moniker: IMoniker): string;
var Bag: IDevicePropertyBag; Value: OleVariant;
begin
  Result := 'Camera';
  if Succeeded(Moniker.BindToStorage(nil, nil, IDevicePropertyBag, Bag)) then
    if Succeeded(Bag.Read('FriendlyName', Value, nil)) then
      Result := UTF8Encode(WideString(Value));
end;
{$ENDIF}

procedure TAIWindowsVideoPreview.EnsureSession;
begin
  {$IFDEF MSWINDOWS}
  if not Assigned(FSession) then FSession := TPreviewSession.Create;
  {$ELSE}
  raise Exception.Create('Continuous Windows video preview requires Windows.');
  {$ENDIF}
end;

destructor TAIWindowsVideoPreview.Destroy;
begin
  Stop;
  FSession.Free;
  inherited Destroy;
end;

function TAIWindowsVideoPreview.ListDevices: TAIVideoDevices;
{$IFDEF MSWINDOWS}
var Enum: IEnumMoniker; Moniker: IMoniker; Fetched: ULONG; N: Integer;
{$ENDIF}
begin
  Result := nil;
  FLastError := '';
  try
    EnsureSession;
    {$IFDEF MSWINDOWS}
    Enum := TPreviewSession(FSession).Enumerator;
    if not Assigned(Enum) then Exit;
    while Enum.Next(1, Moniker, Fetched) = S_OK do
    begin
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N].ID := MonikerID(Moniker);
      Result[N].Name := MonikerName(Moniker);
      Moniker := nil;
    end;
    {$ENDIF}
  except
    on E: Exception do begin Result := nil; FLastError := E.Message; end;
  end;
end;

function TAIWindowsVideoPreview.Start(const ADeviceID: string; AParent: THandle;
  AWidth, AHeight: Integer): Boolean;
{$IFDEF MSWINDOWS}
var S: TPreviewSession; Enum: IEnumMoniker; Moniker: IMoniker;
  Fetched: ULONG; VideoDispatch: IDispatch; Basic: OleVariant;
{$ENDIF}
begin
  Result := False;
  Stop;
  FLastError := '';
  try
    if ADeviceID = '' then raise Exception.Create('Select a camera.');
    if AParent = 0 then raise Exception.Create('A video panel is required.');
    EnsureSession;
    {$IFDEF MSWINDOWS}
    if not IsWindow(AParent) then raise Exception.Create('Invalid video panel.');
    S := TPreviewSession(FSession);
    Enum := S.Enumerator;
    if Assigned(Enum) then
      while Enum.Next(1, Moniker, Fetched) = S_OK do
      begin
        if MonikerID(Moniker) = ADeviceID then
        begin
          FDeviceName := MonikerName(Moniker);
          CheckHR(Moniker.BindToObject(nil, nil, IID_IBaseFilter, S.Source),
            'Could not open ' + FDeviceName);
          Break;
        end;
        Moniker := nil;
      end;
    if not Assigned(S.Source) then
      raise Exception.Create('Selected camera is no longer available. Refresh the device list.');
    CheckHR(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER,
      IPreviewGraph, S.Graph), 'Could not create video graph');
    CheckHR(CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC_SERVER,
      IPreviewBuilder, S.Builder), 'Could not create video preview');
    CheckHR(S.Builder.SetFiltergraph(S.Graph), 'Could not configure video graph');
    CheckHR(S.Graph.AddFilter(S.Source, 'Camera'), 'Could not connect camera');
    CheckHR(S.Builder.RenderStream(@PIN_CATEGORY_PREVIEW, @MEDIATYPE_Video,
      S.Source, nil, nil), 'Could not start video stream; the camera may be in use');
    CheckHR(S.Graph.QueryInterface(IID_IVideoWindow, VideoDispatch), 'Video renderer unavailable');
    S.Video := VideoDispatch;
    S.Video.AutoShow := False;
    S.Video.Owner := PtrInt(AParent);
    S.Video.WindowStyle := LongInt(WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN);
    CheckHR(S.Graph.QueryInterface(IID_IBasicVideo, VideoDispatch), 'Video format unavailable');
    Basic := VideoDispatch;
    FVideoWidth := Basic.VideoWidth;
    FVideoHeight := Basic.VideoHeight;
    CheckHR(S.Graph.QueryInterface(IPreviewControl, S.Control), 'Video control unavailable');
    Resize(AWidth, AHeight);
    S.Video.Visible := True;
    CheckHR(S.Control.Run, 'Could not run video; check whether the camera is in use');
    FActive := True;
    Result := True;
    {$ENDIF}
  except
    on E: Exception do begin Stop; FLastError := E.Message; end;
  end;
end;

procedure TAIWindowsVideoPreview.Stop;
begin
  {$IFDEF MSWINDOWS}
  if Assigned(FSession) then TPreviewSession(FSession).Close;
  {$ENDIF}
  FActive := False;
  FDeviceName := '';
  FVideoWidth := 0;
  FVideoHeight := 0;
end;

procedure TAIWindowsVideoPreview.Resize(AWidth, AHeight: Integer);
{$IFDEF MSWINDOWS}
var W, H: Integer; S: TPreviewSession;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not Assigned(FSession) or (AWidth <= 0) or (AHeight <= 0) then Exit;
  S := TPreviewSession(FSession);
  if VarIsEmpty(S.Video) then Exit;
  W := AWidth; H := AHeight;
  if (FVideoWidth > 0) and (FVideoHeight > 0) then
  begin
    H := Round(Int64(W) * FVideoHeight / FVideoWidth);
    if H > AHeight then
    begin H := AHeight; W := Round(Int64(H) * FVideoWidth / FVideoHeight); end;
  end;
  S.Video.SetWindowPosition((AWidth - W) div 2, (AHeight - H) div 2, W, H);
  {$ENDIF}
end;

end.
