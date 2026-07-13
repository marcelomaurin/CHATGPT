unit aimemory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, LResources;

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

function PhysicalMemoryMB(out TotalMB, AvailableMB: QWord): Boolean;
var
  MS: TMemoryStatusEx;
begin
  Result := False;
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  if GlobalMemoryStatusEx(MS) then
  begin
    TotalMB := MS.ullTotalPhys div 1024 div 1024;
    AvailableMB := MS.ullAvailPhys div 1024 div 1024;
    Result := True;
  end;
end;

function TAIMemory.GetMemoryType: string;
begin
  Result := 'Physical RAM';
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
  FLastInfo.SlotCount := 0;
  if PhysicalMemoryMB(TotalMB, AvailMB) then
  begin
    FLastInfo.TotalMB := TotalMB;
    FLastInfo.AvailableMB := AvailMB;
    FLastInfo.UsedMB := TotalMB - AvailMB;
    FLastInfo.LoadPercent := 0;
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

end.
