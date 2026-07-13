unit aicpu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, LCLType, LResources;

type
  TAICPUInfo = record
    ProcessorCount: Integer;
    LogicalCount: Integer;
    Cores: Integer;
    CacheLineSize: Integer;
    ProcessorId: string;
    FrequencyMHz: Cardinal;
    UsageTotalPercent: Double;
    CoreUsagePercent: array of Double;
  end;

  TAICPU = class(TComponent)
  private
    FLastInfo: TAICPUInfo;
    function QueryUsageTotal: Double;
    function QueryCoreUsage(Index: Integer): Double;
  public
    constructor Create(AOwner: TComponent); override;
    function RefreshInfo: TAICPUInfo;
    function GetProcessorCount: Integer;
    function GetLogicalProcessorCount: Integer;
    function GetCoreCount: Integer;
    function GetCacheLineSize: Integer;
    function GetProcessorId: string;
    function GetFrequencyMHz: Cardinal;
    function GetUsageTotalPercent: Double;
    function GetCoreUsagePercent(Index: Integer): Double;
  public
    property LastInfo: TAICPUInfo read FLastInfo;
  end;

procedure Register;

implementation

type
  TSystemProcessorPerformanceInformation = packed record
    IdleTime: Int64;
    KernelTime: Int64;
    UserTime: Int64;
    DpcTime: Int64;
    InterruptTime: Int64;
    InterruptCount: Cardinal;
  end;

  PSystemProcessorPerformanceInformation = ^TSystemProcessorPerformanceInformation;

const
  SystemProcessorPerformanceInformation = 8;

function GetSystemTimes(lpIdleTime, lpKernelTime, lpUserTime: PFILETIME): BOOL; stdcall;
  external 'kernel32.dll' name 'GetSystemTimes';

function NtQuerySystemInformation(SystemInformationClass: Cardinal; SystemInformation: Pointer;
  SystemInformationLength: Cardinal; ReturnLength: PCardinal): LongInt; stdcall;
  external 'ntdll.dll';

function GetPerformanceInfoByIndex(Index: Integer; out Info: TSystemProcessorPerformanceInformation): Boolean;
var
  Len: Cardinal;
  Arr: array[0..255] of TSystemProcessorPerformanceInformation;
begin
  FillChar(Arr, SizeOf(Arr), 0);
  Len := 0;
  Result := NtQuerySystemInformation(SystemProcessorPerformanceInformation, @Arr[0], SizeOf(Arr), @Len) = 0;
  if Result and (Index >= 0) and (Index < Integer(Len div SizeOf(TSystemProcessorPerformanceInformation))) then
    Info := Arr[Index]
  else
    Result := False;
end;

function GetProcessorFrequencyMHz: Cardinal;
var
  H: HKEY;
  S: array[0..255] of Char;
  Sz, Typ: DWORD;
begin
  Result := 0;
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_READ, H) = ERROR_SUCCESS then
  try
    Sz := SizeOf(S);
    Typ := REG_SZ;
    if RegQueryValueEx(H, '~MHz', nil, @Typ, @S[0], @Sz) = ERROR_SUCCESS then
      Result := StrToIntDef(Trim(S), 0);
  finally
    RegCloseKey(H);
  end;
end;

function GetProcessorIdString: string;
var
  H: HKEY;
  S: array[0..255] of Char;
  Sz, Typ: DWORD;
begin
  Result := '';
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_READ, H) = ERROR_SUCCESS then
  try
    Sz := SizeOf(S);
    Typ := REG_SZ;
    if RegQueryValueEx(H, 'ProcessorNameString', nil, @Typ, @S[0], @Sz) = ERROR_SUCCESS then
      Result := Trim(S);
  finally
    RegCloseKey(H);
  end;
end;

constructor TAICPU.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FillChar(FLastInfo, SizeOf(FLastInfo), 0);
end;

function TAICPU.GetProcessorCount: Integer;
var
  SI: TSystemInfo;
begin
  FillChar(SI, SizeOf(SI), 0);
  GetSystemInfo(SI);
  Result := SI.dwNumberOfProcessors;
  if Result <= 0 then
    Result := 1;
end;

function TAICPU.GetLogicalProcessorCount: Integer;
begin
  Result := GetProcessorCount;
end;

function TAICPU.GetCoreCount: Integer;
begin
  Result := GetProcessorCount;
end;

function TAICPU.GetCacheLineSize: Integer;
begin
  Result := 64;
end;

function TAICPU.GetProcessorId: string;
begin
  Result := GetProcessorIdString;
end;

function TAICPU.GetFrequencyMHz: Cardinal;
begin
  Result := GetProcessorFrequencyMHz;
end;

function TAICPU.QueryUsageTotal: Double;
var
  Idle1, Kernel1, User1: FILETIME;
  Idle2, Kernel2, User2: FILETIME;
  IdleTime1, KernelTime1, UserTime1: UInt64;
  IdleTime2, KernelTime2, UserTime2: UInt64;
begin
  Result := 0;
  if not GetSystemTimes(@Idle1, @Kernel1, @User1) then Exit;
  Sleep(120);
  if not GetSystemTimes(@Idle2, @Kernel2, @User2) then Exit;
  IdleTime1 := (UInt64(Idle1.dwHighDateTime) shl 32) or Idle1.dwLowDateTime;
  KernelTime1 := (UInt64(Kernel1.dwHighDateTime) shl 32) or Kernel1.dwLowDateTime;
  UserTime1 := (UInt64(User1.dwHighDateTime) shl 32) or User1.dwLowDateTime;
  IdleTime2 := (UInt64(Idle2.dwHighDateTime) shl 32) or Idle2.dwLowDateTime;
  KernelTime2 := (UInt64(Kernel2.dwHighDateTime) shl 32) or Kernel2.dwLowDateTime;
  UserTime2 := (UInt64(User2.dwHighDateTime) shl 32) or User2.dwLowDateTime;
  if (KernelTime2 - KernelTime1) + (UserTime2 - UserTime1) > 0 then
    Result := 100.0 * (1.0 - ((IdleTime2 - IdleTime1) / ((KernelTime2 - KernelTime1) + (UserTime2 - UserTime1))));
end;

function TAICPU.QueryCoreUsage(Index: Integer): Double;
var
  P1, P2: TSystemProcessorPerformanceInformation;
  Idle1, Kernel1, User1: UInt64;
  Idle2, Kernel2, User2: UInt64;
begin
  Result := 0;
  if not GetPerformanceInfoByIndex(Index, P1) then Exit;
  Sleep(80);
  if not GetPerformanceInfoByIndex(Index, P2) then Exit;
  Idle1 := UInt64(P1.IdleTime);
  Kernel1 := UInt64(P1.KernelTime);
  User1 := UInt64(P1.UserTime);
  Idle2 := UInt64(P2.IdleTime);
  Kernel2 := UInt64(P2.KernelTime);
  User2 := UInt64(P2.UserTime);
  if (Kernel2 - Kernel1) + (User2 - User1) > 0 then
    Result := 100.0 * (1.0 - ((Idle2 - Idle1) / ((Kernel2 - Kernel1) + (User2 - User1))));
end;

function TAICPU.GetUsageTotalPercent: Double;
begin
  Result := QueryUsageTotal;
end;

function TAICPU.GetCoreUsagePercent(Index: Integer): Double;
begin
  Result := QueryCoreUsage(Index);
end;

function TAICPU.RefreshInfo: TAICPUInfo;
var
  I, Cnt: Integer;
begin
  FLastInfo.ProcessorCount := GetProcessorCount;
  FLastInfo.LogicalCount := GetLogicalProcessorCount;
  FLastInfo.Cores := GetCoreCount;
  FLastInfo.CacheLineSize := GetCacheLineSize;
  FLastInfo.ProcessorId := GetProcessorId;
  FLastInfo.FrequencyMHz := GetFrequencyMHz;
  FLastInfo.UsageTotalPercent := GetUsageTotalPercent;
  Cnt := FLastInfo.LogicalCount;
  SetLength(FLastInfo.CoreUsagePercent, Cnt);
  for I := 0 to Cnt - 1 do
    FLastInfo.CoreUsagePercent[I] := GetCoreUsagePercent(I);
  Result := FLastInfo;
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAICPU]);
end;

initialization
  {$I aihardware_icons.lrs}

end.
