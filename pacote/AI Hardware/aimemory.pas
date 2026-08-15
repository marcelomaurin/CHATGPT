unit aimemory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  aihardwarelinux,
  {$ENDIF}
  LResources;

type
  TAIMemoryInfo = record
    MemoryType: string;
    TotalMB: QWord;
    AvailableMB: QWord;
    UsedMB: QWord;
    SlotCount: Integer;
    LoadPercent: Double;
    PhysicalTotalMB: QWord;
    PhysicalAvailableMB: QWord;
    PhysicalUsedMB: QWord;
  end;

  TAIMemory = class(TComponent)
  private
    FLastInfo: TAIMemoryInfo;
  public
    constructor Create(AOwner: TComponent); override;
    function RefreshInfo: TAIMemoryInfo;
    function GetMemoryType: string;
    function GetTotalMB: QWord;
    function GetAvailableMB: QWord;
    function GetUsedMB: QWord;
    function GetSlotCount: Integer;
    function GetLoadPercent: Double;
  public
    property LastInfo: TAIMemoryInfo read FLastInfo;
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
function TryReadMemInfo(out ATotalMB, AAvailableMB: QWord): Boolean;
var
  I, DelimiterPos, SpacePos: Integer;
  Key, ValueText: string;
  ValueKB, MemFreeKB, BuffersKB, CachedKB: QWord;
  Lines: TStringList;
begin
  Result := False;
  ATotalMB := 0;
  AAvailableMB := 0;
  MemFreeKB := 0;
  BuffersKB := 0;
  CachedKB := 0;
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
        ATotalMB := ValueKB div 1024
      else if SameText(Key, 'MemAvailable') then
        AAvailableMB := ValueKB div 1024
      else if SameText(Key, 'MemFree') then
        MemFreeKB := ValueKB
      else if SameText(Key, 'Buffers') then
        BuffersKB := ValueKB
      else if SameText(Key, 'Cached') then
        CachedKB := ValueKB;
    end;
    if (AAvailableMB = 0) and
      ((MemFreeKB > 0) or (BuffersKB > 0) or (CachedKB > 0)) then
      AAvailableMB := (MemFreeKB + BuffersKB + CachedKB) div 1024;
    if AAvailableMB > ATotalMB then
      AAvailableMB := ATotalMB;
    Result := ATotalMB > 0;
  finally
    Lines.Free;
  end;
end;

function LinuxMemorySlotCount: Integer;
var
  SearchRec: TSearchRec;
begin
  Result := 0;
  if FindFirst(AIHardwareSysPath('firmware/dmi/entries/17-*'), faAnyFile,
    SearchRec) <> 0 then
    Exit;
  try
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        Inc(Result);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;
{$ENDIF}

function PhysicalMemoryMB(out TotalMB, AvailableMB: QWord): Boolean;
{$IFDEF WINDOWS}
var
  MS: TMemoryStatusEx;
{$ENDIF}
begin
  TotalMB := 0;
  AvailableMB := 0;
  {$IF DEFINED(WINDOWS)}
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  Result := GlobalMemoryStatusEx(MS);
  if Result then
  begin
    TotalMB := MS.ullTotalPhys div 1024 div 1024;
    AvailableMB := MS.ullAvailPhys div 1024 div 1024;
  end;
  {$ELSEIF DEFINED(LINUX)}
  Result := TryReadMemInfo(TotalMB, AvailableMB);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function TAIMemory.GetMemoryType: string;
begin
  {$IFDEF LINUX}
  Result := 'Physical RAM (Linux)';
  {$ELSE}
  Result := 'Physical RAM';
  {$ENDIF}
end;

function TAIMemory.GetTotalMB: QWord;
begin
  Result := FLastInfo.TotalMB;
end;

function TAIMemory.GetAvailableMB: QWord;
begin
  Result := FLastInfo.AvailableMB;
end;

function TAIMemory.GetUsedMB: QWord;
begin
  Result := FLastInfo.UsedMB;
end;

function TAIMemory.GetSlotCount: Integer;
begin
  Result := FLastInfo.SlotCount;
end;

function TAIMemory.GetLoadPercent: Double;
begin
  Result := FLastInfo.LoadPercent;
end;

constructor TAIMemory.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FillChar(FLastInfo, SizeOf(FLastInfo), 0);
end;

function TAIMemory.RefreshInfo: TAIMemoryInfo;
var
  TotalMB, AvailMB: QWord;
begin
  FLastInfo.MemoryType := GetMemoryType;
  {$IFDEF LINUX}
  FLastInfo.SlotCount := LinuxMemorySlotCount;
  {$ELSE}
  FLastInfo.SlotCount := 0;
  {$ENDIF}
  FLastInfo.TotalMB := 0;
  FLastInfo.AvailableMB := 0;
  FLastInfo.UsedMB := 0;
  FLastInfo.LoadPercent := 0;
  FLastInfo.PhysicalTotalMB := 0;
  FLastInfo.PhysicalAvailableMB := 0;
  FLastInfo.PhysicalUsedMB := 0;
  if PhysicalMemoryMB(TotalMB, AvailMB) then
  begin
    FLastInfo.TotalMB := TotalMB;
    FLastInfo.AvailableMB := AvailMB;
    FLastInfo.UsedMB := TotalMB - AvailMB;
    if TotalMB > 0 then
      FLastInfo.LoadPercent := (FLastInfo.UsedMB * 100.0) / TotalMB;
    FLastInfo.PhysicalTotalMB := FLastInfo.TotalMB;
    FLastInfo.PhysicalAvailableMB := FLastInfo.AvailableMB;
    FLastInfo.PhysicalUsedMB := FLastInfo.UsedMB;
  end;
  Result := FLastInfo;
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIMemory]);
end;

initialization
  {$I aimemory_icon.lrs}

end.
