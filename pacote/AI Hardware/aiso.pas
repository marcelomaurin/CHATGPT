unit aiso;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  BaseUnix, Unix, UnixType, aihardwarelinux,
  {$ENDIF}
  LResources;

type
  TAIOSInfo = record
    OSName: string;
    OSVersion: string;
    Architecture: string;
    Bitness: string;
    VirtualMemoryUsedMB: QWord;
    VirtualMemoryTotalMB: QWord;
  end;

  TAIOS = class(TComponent)
  private
    FLastInfo: TAIOSInfo;
  public
    constructor Create(AOwner: TComponent); override;
    function RefreshInfo: TAIOSInfo;
    function GetOSName: string;
    function GetOSVersion: string;
    function GetArchitecture: string;
    function GetBitness: string;
    function GetVirtualMemoryUsedMB: QWord;
    function GetVirtualMemoryTotalMB: QWord;
  public
    property LastInfo: TAIOSInfo read FLastInfo;
  end;

procedure Register;

implementation

{$IFDEF WINDOWS}
type
  TMemoryStatusEx = packed record
    dwLength: DWORD;
    dwMemoryLoad: DWORD;
    ullTotalPhys: QWord;
    ullAvailPhys: QWord;
    ullTotalPageFile: QWord;
    ullAvailPageFile: QWord;
    ullTotalVirtual: QWord;
    ullAvailVirtual: QWord;
    ullAvailExtendedVirtual: QWord;
  end;

function GlobalMemoryStatusEx(var lpBuffer: TMemoryStatusEx): BOOL; stdcall;
  external 'kernel32.dll' name 'GlobalMemoryStatusEx';
{$ENDIF}

{$IFDEF LINUX}
function ReadDelimitedValue(const AFileName, AKey: string;
  ADelimiter: Char): string;
var
  I, DelimiterPos: Integer;
  Lines: TStringList;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFileName);
    except
      Exit;
    end;
    for I := 0 to Lines.Count - 1 do
    begin
      DelimiterPos := Pos(ADelimiter, Lines[I]);
      if (DelimiterPos > 0) and SameText(Trim(Copy(Lines[I], 1,
        DelimiterPos - 1)), AKey) then
      begin
        Result := AIUnquote(Trim(Copy(Lines[I], DelimiterPos + 1, MaxInt)));
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function LinuxUnameValue(AField: Integer): string;
var
  NameInfo: UtsName;
begin
  Result := '';
  FillChar(NameInfo, SizeOf(NameInfo), 0);
  if fpUname(NameInfo) <> 0 then
    Exit;
  case AField of
    0: Result := StrPas(@NameInfo.SysName[0]);
    1: Result := StrPas(@NameInfo.Release[0]);
    2: Result := StrPas(@NameInfo.Machine[0]);
  end;
end;

function ReadLinuxVirtualMemory(out ATotalMB, AUsedMB: QWord): Boolean;
var
  I, DelimiterPos, SpacePos: Integer;
  Key, ValueText: string;
  ValueKB, MemTotalKB, MemAvailableKB, MemFreeKB, BuffersKB, CachedKB,
    SwapTotalKB, SwapFreeKB: QWord;
  TotalKB, AvailableKB: QWord;
  Lines: TStringList;
begin
  Result := False;
  ATotalMB := 0;
  AUsedMB := 0;
  MemTotalKB := 0;
  MemAvailableKB := 0;
  MemFreeKB := 0;
  BuffersKB := 0;
  CachedKB := 0;
  SwapTotalKB := 0;
  SwapFreeKB := 0;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AIHardwareProcPath('meminfo'));
    except
      Exit;
    end;
    for I := 0 to Lines.Count - 1 do
    begin
      DelimiterPos := Pos(':', Lines[I]);
      if DelimiterPos = 0 then
        Continue;
      Key := Trim(Copy(Lines[I], 1, DelimiterPos - 1));
      ValueText := Trim(Copy(Lines[I], DelimiterPos + 1, MaxInt));
      SpacePos := Pos(' ', ValueText);
      if SpacePos > 0 then
        ValueText := Copy(ValueText, 1, SpacePos - 1);
      if not TryStrToQWord(ValueText, ValueKB) then
        Continue;
      if SameText(Key, 'MemTotal') then
        MemTotalKB := ValueKB
      else if SameText(Key, 'MemAvailable') then
        MemAvailableKB := ValueKB
      else if SameText(Key, 'MemFree') then
        MemFreeKB := ValueKB
      else if SameText(Key, 'Buffers') then
        BuffersKB := ValueKB
      else if SameText(Key, 'Cached') then
        CachedKB := ValueKB
      else if SameText(Key, 'SwapTotal') then
        SwapTotalKB := ValueKB
      else if SameText(Key, 'SwapFree') then
        SwapFreeKB := ValueKB;
    end;
    if (MemAvailableKB = 0) and
      ((MemFreeKB > 0) or (BuffersKB > 0) or (CachedKB > 0)) then
      MemAvailableKB := MemFreeKB + BuffersKB + CachedKB;
    TotalKB := MemTotalKB + SwapTotalKB;
    AvailableKB := MemAvailableKB + SwapFreeKB;
    if AvailableKB > TotalKB then
      AvailableKB := TotalKB;
    ATotalMB := TotalKB div 1024;
    AUsedMB := (TotalKB - AvailableKB) div 1024;
    Result := MemTotalKB > 0;
  finally
    Lines.Free;
  end;
end;
{$ENDIF}

function TAIOS.GetOSName: string;
begin
  {$IF DEFINED(WINDOWS)}
  Result := 'Windows';
  {$ELSEIF Defined(LINUX)}
  Result := ReadDelimitedValue(AIHardwareEtcPath('os-release'),
    'PRETTY_NAME', '=');
  if Result = '' then
    Result := ReadDelimitedValue(AIHardwareEtcPath('os-release'), 'NAME', '=');
  if Result = '' then
    Result := LinuxUnameValue(0);
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

function TAIOS.GetOSVersion: string;
{$IFDEF WINDOWS}
var
  Ex: OSVERSIONINFOW;
{$ENDIF}
{$IFDEF LINUX}
var
  DistributionVersion, KernelRelease: string;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  FillChar(Ex, SizeOf(Ex), 0);
  Ex.dwOSVersionInfoSize := SizeOf(Ex);
  if GetVersionExW(Ex) then
    Result := Format('%d.%d build %d', [Ex.dwMajorVersion, Ex.dwMinorVersion,
      Ex.dwBuildNumber])
  else
    Result := 'Unknown';
  {$ELSEIF DEFINED(LINUX)}
  DistributionVersion := ReadDelimitedValue(AIHardwareEtcPath('os-release'),
    'VERSION_ID', '=');
  if DistributionVersion = '' then
    DistributionVersion := ReadDelimitedValue(AIHardwareEtcPath('os-release'),
      'VERSION', '=');
  KernelRelease := LinuxUnameValue(1);
  Result := DistributionVersion;
  if KernelRelease <> '' then
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + '(kernel ' + KernelRelease + ')';
  end;
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

function TAIOS.GetArchitecture: string;
begin
  {$IFDEF LINUX}
  Result := LinuxUnameValue(2);
  if Result <> '' then
    Exit;
  {$ENDIF}
  {$IFDEF CPU64}
  Result := 'x64';
  {$ELSE}
  Result := 'x86';
  {$ENDIF}
end;

function TAIOS.GetBitness: string;
begin
  {$IFDEF LINUX}
  Result := IntToStr(SizeOf(Pointer) * 8) + '-bit';
  {$ELSE}
  Result := GetArchitecture;
  {$ENDIF}
end;

function TAIOS.GetVirtualMemoryTotalMB: QWord;
{$IFDEF WINDOWS}
var
  MS: TMemoryStatusEx;
{$ENDIF}
{$IFDEF LINUX}
var
  UsedMB: QWord;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  if GlobalMemoryStatusEx(MS) then
    Result := MS.ullTotalVirtual div 1024 div 1024
  else
    Result := 0;
  {$ELSEIF DEFINED(LINUX)}
  if not ReadLinuxVirtualMemory(Result, UsedMB) then
    Result := 0;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TAIOS.GetVirtualMemoryUsedMB: QWord;
{$IFDEF WINDOWS}
var
  MS: TMemoryStatusEx;
{$ENDIF}
{$IFDEF LINUX}
var
  TotalMB: QWord;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  if GlobalMemoryStatusEx(MS) then
    Result := (MS.ullTotalVirtual - MS.ullAvailVirtual) div 1024 div 1024
  else
    Result := 0;
  {$ELSEIF DEFINED(LINUX)}
  if not ReadLinuxVirtualMemory(TotalMB, Result) then
    Result := 0;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

constructor TAIOS.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FillChar(FLastInfo, SizeOf(FLastInfo), 0);
end;

function TAIOS.RefreshInfo: TAIOSInfo;
begin
  FLastInfo.OSName := GetOSName;
  FLastInfo.OSVersion := GetOSVersion;
  FLastInfo.Architecture := GetArchitecture;
  FLastInfo.Bitness := GetBitness;
  FLastInfo.VirtualMemoryTotalMB := GetVirtualMemoryTotalMB;
  FLastInfo.VirtualMemoryUsedMB := GetVirtualMemoryUsedMB;
  Result := FLastInfo;
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIOS]);
end;

initialization
  {$I aiso_icon.lrs}

end.
