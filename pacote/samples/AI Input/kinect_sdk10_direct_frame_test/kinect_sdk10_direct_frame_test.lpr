program kinect_sdk10_direct_frame_test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Dynlibs, Windows, Math;

const
  NUI_IMAGE_TYPE_COLOR = 1;
  NUI_IMAGE_RESOLUTION_640x480 = 2;
  NUI_INITIALIZE_FLAG_USES_COLOR = $00000002;
  WAIT_OBJECT_0 = 0;

  S_OK = 0;

type
  NUI_LOCKED_RECT = record
    Pitch: Integer;
    size: Integer;
    pBits: Pointer;
  end;

  NUI_SURFACE_DESC = record
    Width: DWord;
    Height: DWord;
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
    pFrameTexture: Pointer;
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

var
  LogFile: TextFile;
  OutputDir: string;

procedure Log(const AMsg: string);
begin
  WriteLn(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMsg);
  WriteLn(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMsg);
  Flush(LogFile);
end;

function HRText(HR: HRESULT): string;
begin
  Result := Format('0x%.8x', [DWord(HR)]);
end;

procedure SaveBGRA32BMP(Buffer: Pointer; const AFileName: string);
var
  FS: TFileStream;
  DataSize: DWord;

  procedure W16(AValue: Word);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

  procedure W32(AValue: DWord);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

  procedure I32(AValue: LongInt);
  begin
    FS.WriteBuffer(AValue, SizeOf(AValue));
  end;

begin
  DataSize := 640 * 480 * 4;
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    W16($4D42);
    W32(14 + 40 + DataSize);
    W16(0);
    W16(0);
    W32(14 + 40);
    W32(40);
    I32(640);
    I32(-480);
    W16(1);
    W16(32);
    W32(0);
    W32(DataSize);
    I32(2835);
    I32(2835);
    W32(0);
    W32(0);
    FS.WriteBuffer(Buffer^, DataSize);
  finally
    FS.Free;
  end;
end;

function Run: Integer;
var
  Lib: TLibHandle;
  NuiInitialize: TNuiInitialize;
  NuiShutdown: TNuiShutdown;
  NuiImageStreamOpen: TNuiImageStreamOpen;
  NuiImageStreamGetNextFrame: TNuiImageStreamGetNextFrame;
  NuiImageStreamReleaseFrame: TNuiImageStreamReleaseFrame;
  HR: HRESULT;
  StreamHandle: THandle;
  EventHandle: THandle;
  FramePtr: PNUI_IMAGE_FRAME;
  Texture: INuiFrameTexture;
  Rect: NUI_LOCKED_RECT;
  Desc: NUI_SURFACE_DESC;
  I: Integer;
  WaitRes: DWord;
  FrameFile: string;
  Initialized: Boolean;
  SavedMask: TFPUExceptionMask;
begin
  Result := 1;
  Lib := NilHandle;
  StreamHandle := 0;
  EventHandle := 0;
  FramePtr := nil;
  Initialized := False;
  SavedMask := GetExceptionMask;
  SetExceptionMask(SavedMask + [exZeroDivide, exInvalidOp, exOverflow, exUnderflow]);

  try
    Log('Iniciando teste direto Kinect10.dll.');
  Log('PointerSizeBits=' + IntToStr(SizeOf(Pointer) * 8));
  Log('SizeOf(NUI_IMAGE_FRAME)=' + IntToStr(SizeOf(NUI_IMAGE_FRAME)));

  Lib := SafeLoadLibrary('Kinect10.dll');
  if Lib = NilHandle then
  begin
    Log('Falha: Kinect10.dll nao carregou.');
    Exit(2);
  end;
  Log('Kinect10.dll carregada.');

  NuiInitialize := TNuiInitialize(GetProcAddress(Lib, 'NuiInitialize'));
  NuiShutdown := TNuiShutdown(GetProcAddress(Lib, 'NuiShutdown'));
  NuiImageStreamOpen := TNuiImageStreamOpen(GetProcAddress(Lib, 'NuiImageStreamOpen'));
  NuiImageStreamGetNextFrame := TNuiImageStreamGetNextFrame(GetProcAddress(Lib, 'NuiImageStreamGetNextFrame'));
  NuiImageStreamReleaseFrame := TNuiImageStreamReleaseFrame(GetProcAddress(Lib, 'NuiImageStreamReleaseFrame'));

  if not Assigned(NuiInitialize) or not Assigned(NuiShutdown) or
     not Assigned(NuiImageStreamOpen) or not Assigned(NuiImageStreamGetNextFrame) or
     not Assigned(NuiImageStreamReleaseFrame) then
  begin
    Log('Falha: uma ou mais funcoes Nui nao foram carregadas.');
    Exit(3);
  end;
  Log('Funcoes Nui carregadas.');

  try
    HR := NuiInitialize(NUI_INITIALIZE_FLAG_USES_COLOR);
    Log('NuiInitialize=' + HRText(HR));
  except
    on E: Exception do
    begin
      Log('EXCECAO em NuiInitialize: ' + E.ClassName + ': ' + E.Message);
      Exit(4);
    end;
  end;
  if HR < 0 then Exit(4);
  Initialized := True;

  EventHandle := CreateEvent(nil, True, False, nil);
  Log('CreateEvent=' + IntToStr(EventHandle));
  if EventHandle = 0 then Exit(5);

  HR := NuiImageStreamOpen(NUI_IMAGE_TYPE_COLOR, NUI_IMAGE_RESOLUTION_640x480,
    0, 2, EventHandle, StreamHandle);
  Log('NuiImageStreamOpen(color,640x480,event)=' + HRText(HR) + ', StreamHandle=' + IntToStr(StreamHandle));
  if HR < 0 then Exit(6);

  for I := 1 to 30 do
  begin
    Log('Aguardando evento/frame, tentativa ' + IntToStr(I));
    WaitRes := WaitForSingleObject(EventHandle, 1000);
    Log('WaitForSingleObject=' + IntToStr(WaitRes));
    ResetEvent(EventHandle);

    FramePtr := nil;
    HR := NuiImageStreamGetNextFrame(StreamHandle, 100, FramePtr);
    if FramePtr <> nil then
      Log('NuiImageStreamGetNextFrame=' + HRText(HR) + ', FramePtr=' + IntToHex(PtrUInt(FramePtr), SizeOf(Pointer) * 2) + ', FrameNumber=' + IntToStr(FramePtr^.dwFrameNumber) + ', TexturePtr=' + IntToHex(PtrUInt(FramePtr^.pFrameTexture), SizeOf(Pointer) * 2))
    else
      Log('NuiImageStreamGetNextFrame=' + HRText(HR) + ', FramePtr=nil');
    if (HR >= 0) and (FramePtr <> nil) then
    begin
      Pointer(Texture) := FramePtr^.pFrameTexture;
      try
        if Texture = nil then
        begin
          Log('Falha: Texture=nil');
          Continue;
        end;
        HR := Texture.GetLevelDesc(0, Desc);
        Log('Texture.GetLevelDesc=' + HRText(HR) + ', Width=' + IntToStr(Desc.Width) + ', Height=' + IntToStr(Desc.Height));
        HR := Texture.LockRect(0, Rect, nil, 0);
        Log('Texture.LockRect=' + HRText(HR) + ', Pitch=' + IntToStr(Rect.Pitch) + ', Size=' + IntToStr(Rect.size) + ', Bits=' + IntToHex(PtrUInt(Rect.pBits), SizeOf(Pointer) * 2));
        if (HR >= 0) and (Rect.pBits <> nil) then
        begin
          FrameFile := IncludeTrailingPathDelimiter(OutputDir) + 'direct_color_frame.bmp';
          SaveBGRA32BMP(Rect.pBits, FrameFile);
          Log('Frame salvo em: ' + FrameFile);
          Texture.UnlockRect(0);
          NuiImageStreamReleaseFrame(StreamHandle, FramePtr);
          Result := 0;
          Exit;
        end;
        if HR >= 0 then
          Texture.UnlockRect(0);
      finally
        Pointer(Texture) := nil;
      end;
      NuiImageStreamReleaseFrame(StreamHandle, FramePtr);
    end;
  end;
  Log('Falha: nenhuma captura concluida.');
  Result := 7;
finally
  if Initialized and Assigned(NuiShutdown) then
  begin
    Log('Chamando NuiShutdown.');
    NuiShutdown();
    Log('NuiShutdown retornou.');
  end;
  if EventHandle <> 0 then
    CloseHandle(EventHandle);
  if Lib <> NilHandle then
    UnloadLibrary(Lib);
  SetExceptionMask(SavedMask);
  end;
end;

begin
  OutputDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'capture_output';
  ForceDirectories(OutputDir);
  AssignFile(LogFile, IncludeTrailingPathDelimiter(OutputDir) + 'kinect_sdk10_direct_frame_test.log');
  Rewrite(LogFile);
  try
    Halt(Run);
  except
    on E: Exception do
    begin
      Log('EXCECAO FATAL: ' + E.ClassName + ': ' + E.Message);
      Halt(99);
    end;
  end;
  CloseFile(LogFile);
end.
