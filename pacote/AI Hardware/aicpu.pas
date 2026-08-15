unit aicpu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IF DEFINED(WINDOWS)}
  Windows, LCLType,
  {$ENDIF}
  {$IF DEFINED(LINUX)}
  aihardwarelinux,
  {$ENDIF}
  LResources;

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

{$IFDEF WINDOWS}
type
  TSystemProcessorPerformanceInformation = packed record
    IdleTime: Int64;
    KernelTime: Int64;
    UserTime: Int64;
    DpcTime: Int64;
    InterruptTime: Int64;
    InterruptCount: Cardinal;
  end;

const
  SystemProcessorPerformanceInformation = 8;

function GetSystemTimes(lpIdleTime, lpKernelTime, lpUserTime: PFILETIME): BOOL; stdcall;
  external 'kernel32.dll' name 'GetSystemTimes';

function NtQuerySystemInformation(SystemInformationClass: Cardinal;
  SystemInformation: Pointer; SystemInformationLength: Cardinal;
  ReturnLength: PCardinal): LongInt; stdcall; external 'ntdll.dll';

function GetPerformanceInfoByIndex(Index: Integer;
  out Info: TSystemProcessorPerformanceInformation): Boolean;
var
  Len: Cardinal;
  Arr: array[0..255] of TSystemProcessorPerformanceInformation;
begin
  FillChar(Arr, SizeOf(Arr), 0);
  Len := 0;
  Result := NtQuerySystemInformation(SystemProcessorPerformanceInformation,
    @Arr[0], SizeOf(Arr), @Len) = 0;
  if Result and (Index >= 0) and
    (Index < Integer(Len div SizeOf(TSystemProcessorPerformanceInformation))) then
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
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE,
    'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_READ, H) =
    ERROR_SUCCESS then
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
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE,
    'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_READ, H) =
    ERROR_SUCCESS then
  try
    Sz := SizeOf(S);
    Typ := REG_SZ;
    if RegQueryValueEx(H, 'ProcessorNameString', nil, @Typ, @S[0], @Sz) =
      ERROR_SUCCESS then
      Result := Trim(S);
  finally
    RegCloseKey(H);
  end;
end;
{$ENDIF}

{$IFDEF LINUX}
function LoadLinuxLines(const AFileName: string; ALines: TStrings): Boolean;
begin
  Result := False;
  try
    ALines.LoadFromFile(AFileName);
    Result := True;
  except
    ALines.Clear;
  end;
end;

function CPUInfoValue(const AKey: string): string;
var
  I, DelimiterPos: Integer;
  Lines: TStringList;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    if not LoadLinuxLines(AIHardwareProcPath('cpuinfo'), Lines) then
      Exit;
    for I := 0 to Lines.Count - 1 do
    begin
      DelimiterPos := Pos(':', Lines[I]);
      if (DelimiterPos > 0) and SameText(Trim(Copy(Lines[I], 1,
        DelimiterPos - 1)), AKey) then
      begin
        Result := Trim(Copy(Lines[I], DelimiterPos + 1, MaxInt));
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function LinuxLogicalProcessorCount: Integer;
var
  I, DelimiterPos: Integer;
  Lines: TStringList;
begin
  Result := 0;
  Lines := TStringList.Create;
  try
    if not LoadLinuxLines(AIHardwareProcPath('cpuinfo'), Lines) then
      Exit;
    for I := 0 to Lines.Count - 1 do
    begin
      DelimiterPos := Pos(':', Lines[I]);
      if (DelimiterPos > 0) and SameText(Trim(Copy(Lines[I], 1,
        DelimiterPos - 1)), 'processor') then
        Inc(Result);
    end;
  finally
    Lines.Free;
  end;
end;

function LinuxPhysicalCoreCount: Integer;
var
  I, DelimiterPos: Integer;
  Key, Value, PhysicalId, CoreId: string;
  Lines, Cores: TStringList;

  procedure AddCurrentCore;
  begin
    if CoreId = '' then
      Exit;
    if PhysicalId = '' then
      PhysicalId := '0';
    Cores.Add(PhysicalId + ':' + CoreId);
    PhysicalId := '';
    CoreId := '';
  end;

begin
  Result := 0;
  Lines := TStringList.Create;
  Cores := TStringList.Create;
  try
    Cores.Sorted := True;
    Cores.Duplicates := dupIgnore;
    if not LoadLinuxLines(AIHardwareProcPath('cpuinfo'), Lines) then
      Exit;
    PhysicalId := '';
    CoreId := '';
    for I := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[I]) = '' then
      begin
        AddCurrentCore;
        Continue;
      end;
      DelimiterPos := Pos(':', Lines[I]);
      if DelimiterPos = 0 then
        Continue;
      Key := Trim(Copy(Lines[I], 1, DelimiterPos - 1));
      Value := Trim(Copy(Lines[I], DelimiterPos + 1, MaxInt));
      if SameText(Key, 'physical id') then
        PhysicalId := Value
      else if SameText(Key, 'core id') then
        CoreId := Value;
    end;
    AddCurrentCore;
    Result := Cores.Count;
  finally
    Cores.Free;
    Lines.Free;
  end;
end;

function NextStatValue(const AText: string; var APosition: Integer;
  out AValue: QWord): Boolean;
var
  StartPos: Integer;
  Token: string;
begin
  while (APosition <= Length(AText)) and (AText[APosition] in [' ', #9]) do
    Inc(APosition);
  StartPos := APosition;
  while (APosition <= Length(AText)) and not
    (AText[APosition] in [' ', #9]) do
    Inc(APosition);
  Token := Copy(AText, StartPos, APosition - StartPos);
  Result := (Token <> '') and TryStrToQWord(Token, AValue);
end;

function ReadLinuxCPUStat(AIndex: Integer; out AIdle, ATotal: QWord): Boolean;
var
  I, J, Position: Integer;
  LabelName, Line: string;
  Lines: TStringList;
  Value: QWord;
begin
  Result := False;
  AIdle := 0;
  ATotal := 0;
  if AIndex < 0 then
    LabelName := 'cpu'
  else
    LabelName := 'cpu' + IntToStr(AIndex);

  Lines := TStringList.Create;
  try
    if not LoadLinuxLines(AIHardwareProcPath('stat'), Lines) then
      Exit;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if (Copy(Line, 1, Length(LabelName)) <> LabelName) or
        ((Length(Line) > Length(LabelName)) and
         not (Line[Length(LabelName) + 1] in [' ', #9])) then
        Continue;
      Position := Length(LabelName) + 1;
      for J := 0 to 7 do
      begin
        if not NextStatValue(Line, Position, Value) then
          Exit;
        Inc(ATotal, Value);
        if J in [3, 4] then
          Inc(AIdle, Value);
      end;
      Result := True;
      Exit;
    end;
  finally
    Lines.Free;
  end;
end;

function UsageFromLinuxStat(AIndex, ADelayMs: Integer): Double;
var
  Idle1, Total1, Idle2, Total2, DeltaIdle, DeltaTotal: QWord;
begin
  Result := 0;
  if not ReadLinuxCPUStat(AIndex, Idle1, Total1) then
    Exit;
  Sleep(ADelayMs);
  if not ReadLinuxCPUStat(AIndex, Idle2, Total2) then
    Exit;
  if (Total2 <= Total1) or (Idle2 < Idle1) then
    Exit;
  DeltaTotal := Total2 - Total1;
  DeltaIdle := Idle2 - Idle1;
  if DeltaTotal > 0 then
    Result := 100.0 * (1.0 - (DeltaIdle / DeltaTotal));
end;
{$ENDIF}

constructor TAICPU.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FillChar(FLastInfo, SizeOf(FLastInfo), 0);
end;

function TAICPU.GetProcessorCount: Integer;
{$IFDEF WINDOWS}
var
  SI: TSystemInfo;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  FillChar(SI, SizeOf(SI), 0);
  GetSystemInfo(SI);
  Result := SI.dwNumberOfProcessors;
  if Result <= 0 then
    Result := 1;
  {$ELSEIF Defined(LINUX)}
  Result := LinuxLogicalProcessorCount;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TAICPU.GetLogicalProcessorCount: Integer;
begin
  Result := GetProcessorCount;
end;

function TAICPU.GetCoreCount: Integer;
begin
  {$IFDEF LINUX}
  Result := LinuxPhysicalCoreCount;
  if Result = 0 then
    Result := LinuxLogicalProcessorCount;
  {$ELSE}
  Result := GetProcessorCount;
  {$ENDIF}
end;

function TAICPU.GetCacheLineSize: Integer;
{$IFDEF LINUX}
var
  I: Integer;
  Value: QWord;
{$ENDIF}
begin
  {$IF DEFINED(LINUX)}
  Result := 0;
  for I := 0 to 9 do
    if AITryReadQWord(AIHardwareSysPath(Format(
      'devices/system/cpu/cpu0/cache/index%d/coherency_line_size', [I])),
      Value) then
    begin
      if Value <= High(Integer) then
        Result := Integer(Value);
      Exit;
    end;
  {$ELSEIF Defined(WINDOWS)}
  Result := 64;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TAICPU.GetProcessorId: string;
begin
  {$IF DEFINED(WINDOWS)}
  Result := GetProcessorIdString;
  {$ELSEIF Defined(LINUX)}
  Result := CPUInfoValue('model name');
  if Result = '' then
    Result := CPUInfoValue('Hardware');
  if Result = '' then
    Result := CPUInfoValue('cpu model');
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

function TAICPU.GetFrequencyMHz: Cardinal;
{$IFDEF LINUX}
var
  KHz: QWord;
  MHz: Double;
  Value: string;
  Settings: TFormatSettings;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  Result := GetProcessorFrequencyMHz;
  {$ELSEIF Defined(LINUX)}
  Result := 0;
  if AITryReadQWord(AIHardwareSysPath(
    'devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq'), KHz) then
  begin
    if (KHz div 1000) <= High(Cardinal) then
      Result := Cardinal(KHz div 1000);
    Exit;
  end;
  Value := CPUInfoValue('cpu MHz');
  Settings := DefaultFormatSettings;
  Settings.DecimalSeparator := '.';
  if TryStrToFloat(Value, MHz, Settings) and (MHz > 0) then
    Result := Round(MHz);
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TAICPU.QueryUsageTotal: Double;
{$IFDEF WINDOWS}
var
  Idle1, Kernel1, User1: FILETIME;
  Idle2, Kernel2, User2: FILETIME;
  IdleTime1, KernelTime1, UserTime1: UInt64;
  IdleTime2, KernelTime2, UserTime2: UInt64;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  Result := 0;
  if not GetSystemTimes(@Idle1, @Kernel1, @User1) then
    Exit;
  Sleep(120);
  if not GetSystemTimes(@Idle2, @Kernel2, @User2) then
    Exit;
  IdleTime1 := (UInt64(Idle1.dwHighDateTime) shl 32) or Idle1.dwLowDateTime;
  KernelTime1 := (UInt64(Kernel1.dwHighDateTime) shl 32) or Kernel1.dwLowDateTime;
  UserTime1 := (UInt64(User1.dwHighDateTime) shl 32) or User1.dwLowDateTime;
  IdleTime2 := (UInt64(Idle2.dwHighDateTime) shl 32) or Idle2.dwLowDateTime;
  KernelTime2 := (UInt64(Kernel2.dwHighDateTime) shl 32) or Kernel2.dwLowDateTime;
  UserTime2 := (UInt64(User2.dwHighDateTime) shl 32) or User2.dwLowDateTime;
  if (KernelTime2 - KernelTime1) + (UserTime2 - UserTime1) > 0 then
    Result := 100.0 * (1.0 - ((IdleTime2 - IdleTime1) /
      ((KernelTime2 - KernelTime1) + (UserTime2 - UserTime1))));
  {$ELSEIF Defined(LINUX)}
  Result := UsageFromLinuxStat(-1, 120);
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TAICPU.QueryCoreUsage(Index: Integer): Double;
{$IFDEF WINDOWS}
var
  P1, P2: TSystemProcessorPerformanceInformation;
  Idle1, Kernel1, User1: UInt64;
  Idle2, Kernel2, User2: UInt64;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  Result := 0;
  if not GetPerformanceInfoByIndex(Index, P1) then
    Exit;
  Sleep(80);
  if not GetPerformanceInfoByIndex(Index, P2) then
    Exit;
  Idle1 := UInt64(P1.IdleTime);
  Kernel1 := UInt64(P1.KernelTime);
  User1 := UInt64(P1.UserTime);
  Idle2 := UInt64(P2.IdleTime);
  Kernel2 := UInt64(P2.KernelTime);
  User2 := UInt64(P2.UserTime);
  if (Kernel2 - Kernel1) + (User2 - User1) > 0 then
    Result := 100.0 * (1.0 - ((Idle2 - Idle1) /
      ((Kernel2 - Kernel1) + (User2 - User1))));
  {$ELSEIF Defined(LINUX)}
  Result := UsageFromLinuxStat(Index, 80);
  {$ELSE}
  Result := 0;
  {$ENDIF}
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
  {$I aicpu_icon.lrs}

end.
