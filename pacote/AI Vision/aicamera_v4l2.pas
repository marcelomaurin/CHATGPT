unit aicamera_v4l2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aicamera_backend, Graphics;

type
  {$IFDEF LINUX}
  { TAICameraV4L2Backend }

  TAICameraV4L2Backend = class(TAICameraNativeBackend)
  private
    FDeviceFD: Integer;
    FWidth: Integer;
    FHeight: Integer;
    
    type
      TMapBuffer = record
        Start: Pointer;
        Length: NativeUInt;
      end;
    var
      FMapBuffers: array of TMapBuffer;
      
    function InitBuffers: Boolean;
    procedure FreeBuffers;
    procedure YUYVToRGB(const ASource: Pointer; ADest: Pointer; AWidth, AHeight: Integer);
    function SaveBGRToBMP(const AFileName: string; ABGRData: Pointer; AWidth, AHeight: Integer): Boolean;
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
  { TAICameraV4L2Backend stub }

  TAICameraV4L2Backend = class(TAICameraNativeBackend)
  public
    function OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean; override;
    procedure CloseCamera; override;
    function CaptureToFile(const AFileName: string): Boolean; override;
    function CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean; override;
    function ListCameras(AMaxScan: Integer): TStringList; override;
  end;
  {$ENDIF}

implementation

{$IFNDEF LINUX}
{ Stub Implementation for Non-Linux Platforms }

function TAICameraV4L2Backend.OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean;
begin
  LastError := 'V4L2 backend is only supported on Linux.';
  Result := False;
end;

procedure TAICameraV4L2Backend.CloseCamera;
begin
end;

function TAICameraV4L2Backend.CaptureToFile(const AFileName: string): Boolean;
begin
  LastError := 'V4L2 backend is only supported on Linux.';
  Result := False;
end;

function TAICameraV4L2Backend.CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean;
begin
  LastError := 'V4L2 backend is only supported on Linux.';
  ABmp := nil;
  Result := False;
end;

function TAICameraV4L2Backend.ListCameras(AMaxScan: Integer): TStringList;
begin
  Result := TStringList.Create;
end;

{$ELSE}
{ Full Linux V4L2 Implementation }

const
  O_RDWR = 2;
  PROT_READ = 1;
  PROT_WRITE = 2;
  MAP_SHARED = 1;

  // Linux ioctl constants derived for x86_64 / arm64 V4L2 headers
  VIDIOC_QUERYCAP   = $80685600;
  VIDIOC_S_FMT      = $C0D05605;
  VIDIOC_REQBUFS    = $C0145608;
  VIDIOC_QUERYBUF   = $C0585609;
  VIDIOC_QBUF       = $C058560F;
  VIDIOC_DQBUF      = $C0585611;
  VIDIOC_STREAMON   = $40045612;
  VIDIOC_STREAMOFF  = $40045613;

type
  // POSIX structures packed exactly like the Linux kernel structures
  v4l2_capability = packed record
    driver: array[0..15] of Char;
    card: array[0..31] of Char;
    bus_info: array[0..31] of Char;
    version: Cardinal;
    capabilities: Cardinal;
    device_caps: Cardinal;
    reserved: array[0..2] of Cardinal;
  end;

  v4l2_pix_format = packed record
    width: Cardinal;
    height: Cardinal;
    pixelformat: Cardinal;
    field: Cardinal;
    bytesperline: Cardinal;
    sizeimage: Cardinal;
    colorspace: Cardinal;
    priv: Cardinal;
    flags: Cardinal;
    ycbcr_enc: Cardinal;
    hsv_enc: Cardinal;
    quantization: Cardinal;
    xfer_func: Cardinal;
  end;

  v4l2_format = packed record
    fmt_type: Cardinal; // 1 = V4L2_BUF_TYPE_VIDEO_CAPTURE
    case Integer of
      0: (pix: v4l2_pix_format);
      1: (raw_data: array[0..199] of Byte);
  end;

  v4l2_requestbuffers = packed record
    count: Cardinal;
    fmt_type: Cardinal; // 1 = V4L2_BUF_TYPE_VIDEO_CAPTURE
    memory: Cardinal;   // 1 = V4L2_MEMORY_MMAP
    reserved: array[0..1] of Cardinal;
  end;

  v4l2_timecode = packed record
    type_: Cardinal;
    flags: Cardinal;
    frames: Byte;
    seconds: Byte;
    minutes: Byte;
    hours: Byte;
    userbits: array[0..3] of Byte;
  end;

  v4l2_buffer = packed record
    index: Cardinal;
    fmt_type: Cardinal;
    bytesused: Cardinal;
    flags: Cardinal;
    field: Cardinal;
    timestamp_sec: Int64;
    timestamp_usec: Int64;
    timecode: v4l2_timecode;
    sequence: Cardinal;
    memory: Cardinal;
    case Integer of
      0: (offset: Cardinal);
      1: (userptr: Pointer);
      2: (planes: Pointer);
      3: (fd: Integer);
    length: Cardinal;
    reserved2: Cardinal;
    request_fd: Integer;
  end;

  // BMP File Structure Headers
  TBitmapFileHeader = packed record
    bfType: Word;      // 'BM' ($4D42)
    bfSize: DWord;
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: DWord;
  end;

  TBitmapInfoHeader = packed record
    biSize: DWord;
    biWidth: LongInt;
    biHeight: LongInt;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: DWord;
    biSizeImage: DWord;
    biXPelsPerMeter: LongInt;
    biYPelsPerMeter: LongInt;
    biClrUsed: DWord;
    biClrImportant: DWord;
  end;

// C POSIX APIs imported directly from libc
function open(pathname: PChar; flags: Integer): Integer; cdecl; external 'libc' name 'open';
function close(fd: Integer): Integer; cdecl; external 'libc' name 'close';
function ioctl(fd: Integer; request: Cardinal; arg: Pointer): Integer; cdecl; external 'libc' name 'ioctl';
function mmap(addr: Pointer; length: NativeUInt; prot: Integer; flags: Integer; fd: Integer; offset: Int64): Pointer; cdecl; external 'libc' name 'mmap';
function munmap(addr: Pointer; length: NativeUInt): Integer; cdecl; external 'libc' name 'munmap';

constructor TAICameraV4L2Backend.Create;
begin
  inherited Create;
  FDeviceFD := -1;
  FWidth := 640;
  FHeight := 480;
end;

destructor TAICameraV4L2Backend.Destroy;
begin
  CloseCamera;
  inherited Destroy;
end;

function TAICameraV4L2Backend.OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean;
var
  LTargetDevice: string;
  cap: v4l2_capability;
  fmt: v4l2_format;
  LType: Cardinal;
begin
  Result := False;
  LastError := '';

  if FDeviceFD >= 0 then
  begin
    Result := True;
    Exit;
  end;

  if ADevice <> '' then
    LTargetDevice := ADevice
  else
    LTargetDevice := '/dev/video' + IntToStr(AIndex);

  FDeviceFD := open(PChar(LTargetDevice), O_RDWR);
  if FDeviceFD < 0 then
  begin
    LastError := 'Cannot open device: ' + LTargetDevice;
    Exit;
  end;

  // Verify capabilities
  if ioctl(FDeviceFD, VIDIOC_QUERYCAP, @cap) < 0 then
  begin
    LastError := 'Failed to query capabilities on device: ' + LTargetDevice;
    CloseCamera;
    Exit;
  end;

  // V4L2_CAP_VIDEO_CAPTURE = $00000001
  if (cap.device_caps and $00000001) = 0 then
  begin
    LastError := 'Device does not support Video Capture: ' + LTargetDevice;
    CloseCamera;
    Exit;
  end;

  // Set format: Try YUYV ($56595559 = 'YUYV') or fallback to MJPEG ($4745504A = 'MJPG')
  FillChar(fmt, SizeOf(fmt), 0);
  fmt.fmt_type := 1; // V4L2_BUF_TYPE_VIDEO_CAPTURE
  fmt.pix.width := AWidth;
  fmt.pix.height := AHeight;
  fmt.pix.pixelformat := $56595559; // YUYV
  fmt.pix.field := 1; // V4L2_FIELD_NONE

  if ioctl(FDeviceFD, VIDIOC_S_FMT, @fmt) < 0 then
  begin
    // Fallback to MJPEG
    fmt.pix.pixelformat := $4745504A; // MJPG
    if ioctl(FDeviceFD, VIDIOC_S_FMT, @fmt) < 0 then
    begin
      LastError := 'Failed to set format on device: ' + LTargetDevice;
      CloseCamera;
      Exit;
    end;
  end;

  FWidth := fmt.pix.width;
  FHeight := fmt.pix.height;

  // Initialize MMAP buffers
  if not InitBuffers then
  begin
    CloseCamera;
    Exit;
  end;

  // Stream ON
  LType := 1; // V4L2_BUF_TYPE_VIDEO_CAPTURE
  if ioctl(FDeviceFD, VIDIOC_STREAMON, @LType) < 0 then
  begin
    LastError := 'Failed to start streaming (STREAMON)';
    CloseCamera;
    Exit;
  end;

  Result := True;
end;

procedure TAICameraV4L2Backend.CloseCamera;
var
  LType: Cardinal;
begin
  if FDeviceFD >= 0 then
  begin
    LType := 1;
    ioctl(FDeviceFD, VIDIOC_STREAMOFF, @LType);
    FreeBuffers;
    close(FDeviceFD);
    FDeviceFD := -1;
  end;
end;

function TAICameraV4L2Backend.InitBuffers: Boolean;
var
  req: v4l2_requestbuffers;
  buf: v4l2_buffer;
  idx: Integer;
begin
  Result := False;

  FillChar(req, SizeOf(req), 0);
  req.count := 2; // double buffer
  req.fmt_type := 1; // V4L2_BUF_TYPE_VIDEO_CAPTURE
  req.memory := 1; // V4L2_MEMORY_MMAP

  if ioctl(FDeviceFD, VIDIOC_REQBUFS, @req) < 0 then
  begin
    LastError := 'Failed to request buffers (REQBUFS)';
    Exit;
  end;

  SetLength(FMapBuffers, req.count);
  for idx := 0 to req.count - 1 do
  begin
    FillChar(buf, SizeOf(buf), 0);
    buf.index := idx;
    buf.fmt_type := 1;
    buf.memory := 1;

    if ioctl(FDeviceFD, VIDIOC_QUERYBUF, @buf) < 0 then
    begin
      LastError := 'Failed to query buffer index ' + IntToStr(idx);
      Exit;
    end;

    FMapBuffers[idx].Length := buf.length;
    FMapBuffers[idx].Start := mmap(nil, buf.length, PROT_READ or PROT_WRITE, MAP_SHARED, FDeviceFD, buf.offset);
    if FMapBuffers[idx].Start = Pointer(-1) then
    begin
      LastError := 'Failed to map buffer index ' + IntToStr(idx);
      Exit;
    end;
  end;

  // Queue them to start
  for idx := 0 to req.count - 1 do
  begin
    FillChar(buf, SizeOf(buf), 0);
    buf.index := idx;
    buf.fmt_type := 1;
    buf.memory := 1;
    if ioctl(FDeviceFD, VIDIOC_QBUF, @buf) < 0 then
    begin
      LastError := 'Failed to initial queue buffer index ' + IntToStr(idx);
      Exit;
    end;
  end;

  Result := True;
end;

procedure TAICameraV4L2Backend.FreeBuffers;
var
  idx: Integer;
begin
  for idx := 0 to Length(FMapBuffers) - 1 do
  begin
    if Assigned(FMapBuffers[idx].Start) and (FMapBuffers[idx].Start <> Pointer(-1)) then
    begin
      munmap(FMapBuffers[idx].Start, FMapBuffers[idx].Length);
    end;
  end;
  SetLength(FMapBuffers, 0);
end;

function TAICameraV4L2Backend.CaptureToFile(const AFileName: string): Boolean;
var
  buf: v4l2_buffer;
  LTargetRGB: Pointer;
  LSaveSuccess: Boolean;
begin
  Result := False;
  LastError := '';

  if FDeviceFD < 0 then
  begin
    LastError := 'Camera is not open.';
    Exit;
  end;

  // Dequeue a ready buffer
  FillChar(buf, SizeOf(buf), 0);
  buf.fmt_type := 1;
  buf.memory := 1;

  if ioctl(FDeviceFD, VIDIOC_DQBUF, @buf) < 0 then
  begin
    LastError := 'Failed to dequeue frame buffer (DQBUF)';
    Exit;
  end;

  try
    // Decode based on format or direct save
    // For simplicity, we convert the buffer using YUYVToRGB
    GetMem(LTargetRGB, FWidth * FHeight * 3);
    try
      YUYVToRGB(FMapBuffers[buf.index].Start, LTargetRGB, FWidth, FHeight);
      LSaveSuccess := SaveBGRToBMP(AFileName, LTargetRGB, FWidth, FHeight);
      if LSaveSuccess then
        Result := True
      else
        LastError := 'Failed to save converted BMP file.';
    finally
      FreeMem(LTargetRGB);
    end;
  finally
    // Re-queue the buffer
    ioctl(FDeviceFD, VIDIOC_QBUF, @buf);
  end;
end;

function TAICameraV4L2Backend.CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean;
var
  buf: v4l2_buffer;
  LTargetRGB: Pointer;
  LRow: Integer;
  LRowSize: Integer;
  LSourcePtr: PByte;
begin
  Result := False;
  ABmp := nil;
  LastError := '';

  if FDeviceFD < 0 then
  begin
    LastError := 'Camera is not open.';
    Exit;
  end;

  FillChar(buf, SizeOf(buf), 0);
  buf.fmt_type := 1;
  buf.memory := 1;

  if ioctl(FDeviceFD, VIDIOC_DQBUF, @buf) < 0 then
  begin
    LastError := 'Failed to dequeue frame buffer (DQBUF)';
    Exit;
  end;

  try
    GetMem(LTargetRGB, FWidth * FHeight * 3);
    try
      YUYVToRGB(FMapBuffers[buf.index].Start, LTargetRGB, FWidth, FHeight);
      
      ABmp := TBitmap.Create;
      ABmp.Width := FWidth;
      ABmp.Height := FHeight;
      ABmp.PixelFormat := pf24bit;

      LRowSize := FWidth * 3;
      LSourcePtr := PByte(LTargetRGB);
      
      for LRow := 0 to FHeight - 1 do
      begin
        Move(LSourcePtr^, ABmp.RawImage.GetRowStart(LRow)^, LRowSize);
        Inc(LSourcePtr, LRowSize);
      end;
      
      Result := True;
    except
      on E: Exception do
      begin
        LastError := 'Failed to convert V4L2 frame to TBitmap: ' + E.Message;
        FreeAndNil(ABmp);
      end;
    end;
    FreeMem(LTargetRGB);
  finally
    ioctl(FDeviceFD, VIDIOC_QBUF, @buf);
  end;
end;

procedure TAICameraV4L2Backend.YUYVToRGB(const ASource: Pointer; ADest: Pointer; AWidth, AHeight: Integer);
var
  i: Integer;
  Src: PByte;
  Dst: PByte;
  y0, u, y1, v: Byte;
  r, g, b: Integer;
  c, d, e: Integer;
begin
  Src := PByte(ASource);
  Dst := PByte(ADest);
  for i := 0 to (AWidth * AHeight div 2) - 1 do
  begin
    y0 := Src^; Inc(Src);
    u  := Src^; Inc(Src);
    y1 := Src^; Inc(Src);
    v  := Src^; Inc(Src);

    // Pixel 1
    c := y0 - 16;
    d := u - 128;
    e := v - 128;
    
    r := (298 * c           + 409 * e + 128) div 256;
    g := (298 * c - 100 * d - 208 * e + 128) div 256;
    b := (298 * c + 516 * d           + 128) div 256;
    
    if r < 0 then r := 0 else if r > 255 then r := 255;
    if g < 0 then g := 0 else if g > 255 then g := 255;
    if b < 0 then b := 0 else if b > 255 then b := 255;
    
    Dst^ := b; Inc(Dst); // B
    Dst^ := g; Inc(Dst); // G
    Dst^ := r; Inc(Dst); // R

    // Pixel 2
    c := y1 - 16;
    r := (298 * c           + 409 * e + 128) div 256;
    g := (298 * c - 100 * d - 208 * e + 128) div 256;
    b := (298 * c + 516 * d           + 128) div 256;
    
    if r < 0 then r := 0 else if r > 255 then r := 255;
    if g < 0 then g := 0 else if g > 255 then g := 255;
    if b < 0 then b := 0 else if b > 255 then b := 255;
    
    Dst^ := b; Inc(Dst);
    Dst^ := g; Inc(Dst);
    Dst^ := r; Inc(Dst);
  end;
end;

function TAICameraV4L2Backend.SaveBGRToBMP(const AFileName: string; ABGRData: Pointer; AWidth, AHeight: Integer): Boolean;
var
  LStream: TFileStream;
  LFileHeader: TBitmapFileHeader;
  LInfoHeader: TBitmapInfoHeader;
  LPaddedWidth: Integer;
  LPaddingBytes: Integer;
  LRow: Integer;
  LPendingRow: PByte;
  LZero: DWord;
begin
  Result := False;
  LPaddedWidth := (AWidth * 3 + 3) and not 3;
  LPaddingBytes := LPaddedWidth - (AWidth * 3);
  LZero := 0;

  FillChar(LFileHeader, SizeOf(LFileHeader), 0);
  LFileHeader.bfType := $4D42; // 'BM'
  LFileHeader.bfSize := SizeOf(TBitmapFileHeader) + SizeOf(TBitmapInfoHeader) + LPaddedWidth * AHeight;
  LFileHeader.bfOffBits := SizeOf(TBitmapFileHeader) + SizeOf(TBitmapInfoHeader);

  FillChar(LInfoHeader, SizeOf(LInfoHeader), 0);
  LInfoHeader.biSize := SizeOf(TBitmapInfoHeader);
  LInfoHeader.biWidth := AWidth;
  LInfoHeader.biHeight := -AHeight; // top-down BMP
  LInfoHeader.biPlanes := 1;
  LInfoHeader.biBitCount := 24;
  LInfoHeader.biSizeImage := LPaddedWidth * AHeight;

  try
    LStream := TFileStream.Create(AFileName, fmCreate);
    try
      LStream.WriteBuffer(LFileHeader, SizeOf(LFileHeader));
      LStream.WriteBuffer(LInfoHeader, SizeOf(LInfoHeader));
      
      LPendingRow := PByte(ABGRData);
      for LRow := 0 to AHeight - 1 do
      begin
        LStream.WriteBuffer(LPendingRow^, AWidth * 3);
        if LPaddingBytes > 0 then
          LStream.Write(LZero, LPaddingBytes);
        Inc(LPendingRow, AWidth * 3);
      end;
      Result := True;
    finally
      LStream.Free;
    end;
  except
    // ignore stream exceptions
  end;
end;

function TAICameraV4L2Backend.ListCameras(AMaxScan: Integer): TStringList;
var
  idx: Integer;
  LDevice: string;
  LFD: Integer;
  cap: v4l2_capability;
  LName: string;
begin
  Result := TStringList.Create;
  for idx := 0 to AMaxScan - 1 do
  begin
    LDevice := '/dev/video' + IntToStr(idx);
    if FileExists(LDevice) then
    begin
      LFD := open(PChar(LDevice), O_RDWR);
      if LFD >= 0 then
      begin
        LName := 'Camera ' + IntToStr(idx);
        if ioctl(LFD, VIDIOC_QUERYCAP, @cap) >= 0 then
        begin
          LName := LName + ' - ' + StrPas(cap.card);
        end;
        close(LFD);
        Result.Add(IntToStr(idx) + ' - ' + LName);
      end;
    end;
  end;
end;

{$ENDIF}

end.
