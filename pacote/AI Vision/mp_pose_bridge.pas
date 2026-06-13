unit mp_pose_bridge;

{$mode objfpc}{$H+}
{$PACKRECORDS C}

interface

uses
  ctypes, DynLibs, SysUtils;

const
  MP_POSE_ABI_VERSION = 1;
  MP_POSE_LANDMARK_COUNT = 33;

  { Error Codes }
  MP_OK                  = 0;
  MP_ERR_ABI_MISMATCH    = 1;
  MP_ERR_BAD_ARG         = 2;
  MP_ERR_MODEL_LOAD      = 3;
  MP_ERR_NOT_INITIALIZED = 4;
  MP_ERR_INFERENCE       = 5;
  MP_ERR_UNSUPPORTED     = 6;
  MP_ERR_OUT_OF_MEMORY   = 7;
  MP_ERR_BACKEND         = 8;

type
  mp_pose_handle = Pointer;

  Pmp_pose_info = ^tmp_pose_info;
  tmp_pose_info = record
    struct_size: cint32;
    abi_version: cint32;            { == MP_POSE_ABI_VERSION }
    bridge_version: array[0..31] of AnsiChar;
    mediapipe_version: array[0..31] of AnsiChar;
    platform: array[0..15] of AnsiChar;
    arch: array[0..15] of AnsiChar;
    model_name: array[0..127] of AnsiChar;
    backend: array[0..15] of AnsiChar;  { "SIM" | "REAL" — appended in v1 pre-release }
  end;

  Pmp_pose_config = ^tmp_pose_config;
  tmp_pose_config = record
    struct_size: cint32;
    model_path: PAnsiChar;
    running_mode: cint32;           { 0=IMAGE, 1=VIDEO }
    num_poses: cint32;              { >= 1 }
    min_pose_detection_confidence: cfloat;
    min_pose_presence_confidence: cfloat;
    min_tracking_confidence: cfloat;
    output_segmentation_mask: cint32; { 0 | 1 }
    num_threads: cint32;            { 0 = automatic }
  end;

  Pmp_image_raw = ^tmp_image_raw;
  tmp_image_raw = record
    struct_size: cint32;
    data: PByte;
    width: cint32;
    height: cint32;
    channels: cint32;
    stride: cint32;
    timestamp_ms: int64;
  end;

  Pmp_landmark = ^tmp_landmark;
  tmp_landmark = record
    x: cfloat;
    y: cfloat;
    z: cfloat;
    visibility: cfloat;
    presence: cfloat;
  end;

  Pmp_world_landmark = ^tmp_world_landmark;
  tmp_world_landmark = record
    x: cfloat;
    y: cfloat;
    z: cfloat;
  end;

  Pmp_pose_result = ^tmp_pose_result;
  Pmp_pose_result_ptr = ^Pmp_pose_result;
  tmp_pose_result = record
    struct_size: cint32;
    pose_count: cint32;
    landmarks_per_pose: cint32;
    landmarks: Pmp_landmark;
    world_landmarks: Pmp_world_landmark;
    mask_present: cint32;
    mask_width: cint32;
    mask_height: cint32;
    mask: PByte;
  end;

  { Function pointer types }
  TFunc_mp_pose_get_info = function(out_info: Pmp_pose_info): cint32; cdecl;
  TFunc_mp_pose_create = function(const cfg: Pmp_pose_config; out_handle: PPointer): cint32; cdecl;
  TFunc_mp_pose_destroy = procedure(h: mp_pose_handle); cdecl;
  TFunc_mp_pose_detect = function(h: mp_pose_handle; const img: Pmp_image_raw; out_result: Pmp_pose_result_ptr): cint32; cdecl;
  TFunc_mp_pose_free_result = procedure(var result: Pmp_pose_result); cdecl;
  TFunc_mp_pose_last_error = function(h: mp_pose_handle): PAnsiChar; cdecl;

var
  mp_pose_get_info: TFunc_mp_pose_get_info = nil;
  mp_pose_create: TFunc_mp_pose_create = nil;
  mp_pose_destroy: TFunc_mp_pose_destroy = nil;
  mp_pose_detect: TFunc_mp_pose_detect = nil;
  mp_pose_free_result: TFunc_mp_pose_free_result = nil;
  mp_pose_last_error: TFunc_mp_pose_last_error = nil;

function LoadMpPoseBridge(const ADir: string): Boolean;
procedure UnloadMpPoseBridge;
function MpPoseBridgeAvailable: Boolean;
function GetExpectedBridgeLibName: string;

implementation

var
  LibHandle: TLibHandle = NilHandle;

function GetExpectedBridgeLibName: string;
begin
  {$IFDEF MSWINDOWS}
    Result := 'mp_pose_bridge.dll';
  {$ELSE}
    Result := 'libmp_pose_bridge.so';
  {$ENDIF}
end;

{$IFDEF MSWINDOWS}
function SetDllDirectoryA(lpPathName: PAnsiChar): LongBool; stdcall; external 'kernel32.dll';
{$ENDIF}

function LoadMpPoseBridge(const ADir: string): Boolean;
var
  LPath: string;
begin
  Result := False;
  UnloadMpPoseBridge;

  if ADir <> '' then
    LPath := IncludeTrailingPathDelimiter(ADir) + GetExpectedBridgeLibName
  else
    LPath := GetExpectedBridgeLibName;

  if not FileExists(LPath) then
    Exit;

  {$IFDEF MSWINDOWS}
  if ADir <> '' then
    SetDllDirectoryA(PAnsiChar(AnsiString(ADir)));
  {$ENDIF}

  LibHandle := SafeLoadLibrary(LPath);
  
  {$IFDEF MSWINDOWS}
  if ADir <> '' then
    SetDllDirectoryA(nil);
  {$ENDIF}

  if LibHandle <> NilHandle then
  begin
    mp_pose_get_info := TFunc_mp_pose_get_info(GetProcAddress(LibHandle, 'mp_pose_get_info'));
    mp_pose_create := TFunc_mp_pose_create(GetProcAddress(LibHandle, 'mp_pose_create'));
    mp_pose_destroy := TFunc_mp_pose_destroy(GetProcAddress(LibHandle, 'mp_pose_destroy'));
    mp_pose_detect := TFunc_mp_pose_detect(GetProcAddress(LibHandle, 'mp_pose_detect'));
    mp_pose_free_result := TFunc_mp_pose_free_result(GetProcAddress(LibHandle, 'mp_pose_free_result'));
    mp_pose_last_error := TFunc_mp_pose_last_error(GetProcAddress(LibHandle, 'mp_pose_last_error'));

    if Assigned(mp_pose_get_info) and
       Assigned(mp_pose_create) and
       Assigned(mp_pose_destroy) and
       Assigned(mp_pose_detect) and
       Assigned(mp_pose_free_result) and
       Assigned(mp_pose_last_error) then
    begin
      Result := True;
    end
    else
    begin
      UnloadMpPoseBridge;
    end;
  end;
end;

procedure UnloadMpPoseBridge;
begin
  if LibHandle <> NilHandle then
  begin
    UnloadLibrary(LibHandle);
    LibHandle := NilHandle;
  end;
  mp_pose_get_info := nil;
  mp_pose_create := nil;
  mp_pose_destroy := nil;
  mp_pose_detect := nil;
  mp_pose_free_result := nil;
  mp_pose_last_error := nil;
end;

function MpPoseBridgeAvailable: Boolean;
begin
  Result := (LibHandle <> NilHandle) and 
            Assigned(mp_pose_get_info) and
            Assigned(mp_pose_create) and
            Assigned(mp_pose_destroy) and
            Assigned(mp_pose_detect) and
            Assigned(mp_pose_free_result) and
            Assigned(mp_pose_last_error);
end;

end.
