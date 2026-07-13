unit aiso;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, LResources;

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

function TAIOS.GetOSName: string;
begin
  Result := 'Windows';
end;

function TAIOS.GetOSVersion: string;
var
  Ex: OSVERSIONINFOW;
begin
  FillChar(Ex, SizeOf(Ex), 0);
  Ex.dwOSVersionInfoSize := SizeOf(Ex);
  if GetVersionExW(Ex) then
    Result := Format('%d.%d build %d', [Ex.dwMajorVersion, Ex.dwMinorVersion, Ex.dwBuildNumber])
  else
    Result := 'Unknown';
end;

function TAIOS.GetArchitecture: string;
begin
  {$IFDEF CPU64}
  Result := 'x64';
  {$ELSE}
  Result := 'x86';
  {$ENDIF}
end;

function TAIOS.GetBitness: string;
begin
  Result := GetArchitecture;
end;

function TAIOS.GetVirtualMemoryTotalMB: QWord;
var
  MS: TMemoryStatusEx;
begin
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  if GlobalMemoryStatusEx(MS) then
    Result := MS.ullTotalVirtual div 1024 div 1024
  else
    Result := 0;
end;

function TAIOS.GetVirtualMemoryUsedMB: QWord;
var
  MS: TMemoryStatusEx;
begin
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  if GlobalMemoryStatusEx(MS) then
    Result := (MS.ullTotalVirtual - MS.ullAvailVirtual) div 1024 div 1024
  else
    Result := 0;
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

end.
