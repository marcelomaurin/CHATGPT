unit aigpu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF LINUX}
  aihardwarelinux,
  {$ENDIF}
  LResources;

type
  TAIGPUInfo = record
    Name: string;
    MemoryTotalMB: QWord;
    MemoryUsedMB: QWord;
    MemoryFreeMB: QWord;
    CUDACoreCount: Integer;
    UsagePercent: Double;
    Available: Boolean;
    LastError: string;
  end;

  TAIGPU = class(TComponent)
  private
    FLastInfo: TAIGPUInfo;
    FAvailable: Boolean;
    FLastError: string;
    FQueried: Boolean;
    procedure EnsureRefreshed;
    function GetAvailable: Boolean;
    function GetLastError: string;
  public
    constructor Create(AOwner: TComponent); override;
    function RefreshInfo: TAIGPUInfo;
    function GetGPUName: string;
    function GetMemoryTotalMB: QWord;
    function GetMemoryUsedMB: QWord;
    function GetMemoryFreeMB: QWord;
    function GetCUDACoreCount: Integer;
    function GetUsagePercent: Double;
  public
    property LastInfo: TAIGPUInfo read FLastInfo;
    property Available: Boolean read GetAvailable;
    property LastError: string read GetLastError;
  end;

procedure Register;

implementation

procedure ClearGPUInfo(var AInfo: TAIGPUInfo);
begin
  AInfo.Name := '';
  AInfo.MemoryTotalMB := 0;
  AInfo.MemoryUsedMB := 0;
  AInfo.MemoryFreeMB := 0;
  AInfo.CUDACoreCount := 0;
  AInfo.UsagePercent := 0;
  AInfo.Available := False;
  AInfo.LastError := '';
end;

{$IFDEF LINUX}
function IsDRMCardName(const AName: string): Boolean;
var
  I: Integer;
begin
  Result := (Length(AName) > 4) and SameText(Copy(AName, 1, 4), 'card');
  if not Result then
    Exit;
  for I := 5 to Length(AName) do
    if not (AName[I] in ['0'..'9']) then
      Exit(False);
end;

function FindLinuxDRMCard(out ACardPath: string): Boolean;
var
  SearchRec: TSearchRec;
  DRMRoot: string;
begin
  Result := False;
  ACardPath := '';
  DRMRoot := AIHardwareSysPath('class/drm');
  if FindFirst(IncludeTrailingPathDelimiter(DRMRoot) + 'card*', faAnyFile,
    SearchRec) <> 0 then
    Exit;
  try
    repeat
      if IsDRMCardName(SearchRec.Name) then
      begin
        ACardPath := IncludeTrailingPathDelimiter(DRMRoot) + SearchRec.Name;
        if DirectoryExists(ACardPath) then
          Exit(True);
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

function NormalizeHexId(const AValue: string): string;
begin
  Result := LowerCase(Trim(AValue));
  if Copy(Result, 1, 2) = '0x' then
    Delete(Result, 1, 2);
end;

function GPUVendorName(const AVendorId: string): string;
begin
  if SameText(AVendorId, '10de') then
    Result := 'NVIDIA'
  else if SameText(AVendorId, '1002') then
    Result := 'AMD'
  else if SameText(AVendorId, '8086') then
    Result := 'Intel'
  else if SameText(AVendorId, '1a03') then
    Result := 'ASPEED'
  else
    Result := 'PCI';
end;

function QueryLinuxGPU(out AInfo: TAIGPUInfo): Boolean;
var
  CardPath, DevicePath, VendorText, DeviceText, ProductName: string;
  VendorId, DeviceId: string;
  TotalBytes, UsedBytes, BusyPercent: QWord;
  Messages: string;
begin
  ClearGPUInfo(AInfo);
  Messages := '';
  Result := FindLinuxDRMCard(CardPath);
  if not Result then
  begin
    AInfo.Name := 'Unavailable';
    AInfo.LastError := 'No DRM GPU found under /sys/class/drm';
    Exit;
  end;

  DevicePath := IncludeTrailingPathDelimiter(CardPath) + 'device';
  AIReadFirstLine(IncludeTrailingPathDelimiter(DevicePath) + 'vendor',
    VendorText);
  AIReadFirstLine(IncludeTrailingPathDelimiter(DevicePath) + 'device',
    DeviceText);
  VendorId := NormalizeHexId(VendorText);
  DeviceId := NormalizeHexId(DeviceText);

  if not AIReadFirstLine(IncludeTrailingPathDelimiter(DevicePath) +
    'product_name', ProductName) then
    if not AIReadFirstLine(IncludeTrailingPathDelimiter(DevicePath) +
      'product', ProductName) then
      AIReadFirstLine(IncludeTrailingPathDelimiter(DevicePath) + 'label',
        ProductName);

  if ProductName <> '' then
    AInfo.Name := ProductName
  else
    AInfo.Name := GPUVendorName(VendorId) + ' GPU';
  if (VendorId <> '') or (DeviceId <> '') then
    AInfo.Name := AInfo.Name + ' [' + VendorId + ':' + DeviceId + ']';

  if AITryReadQWord(IncludeTrailingPathDelimiter(DevicePath) +
    'mem_info_vram_total', TotalBytes) then
    AInfo.MemoryTotalMB := TotalBytes div 1024 div 1024
  else
    AIAppendMessage(Messages, 'VRAM total is not exposed by this DRM driver');

  if AITryReadQWord(IncludeTrailingPathDelimiter(DevicePath) +
    'mem_info_vram_used', UsedBytes) then
    AInfo.MemoryUsedMB := UsedBytes div 1024 div 1024
  else
    AIAppendMessage(Messages, 'VRAM usage is not exposed by this DRM driver');

  if AInfo.MemoryUsedMB > AInfo.MemoryTotalMB then
    AInfo.MemoryUsedMB := AInfo.MemoryTotalMB;
  AInfo.MemoryFreeMB := AInfo.MemoryTotalMB - AInfo.MemoryUsedMB;

  if AITryReadQWord(IncludeTrailingPathDelimiter(DevicePath) +
    'gpu_busy_percent', BusyPercent) then
  begin
    if BusyPercent > 100 then
      BusyPercent := 100;
    AInfo.UsagePercent := BusyPercent;
  end
  else
    AIAppendMessage(Messages, 'GPU utilization is not exposed by this DRM driver');

  if SameText(VendorId, '10de') then
    AIAppendMessage(Messages, 'CUDA core count is unavailable through DRM sysfs');

  AInfo.Available := True;
  AInfo.LastError := Messages;
end;
{$ENDIF}

constructor TAIGPU.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ClearGPUInfo(FLastInfo);
  FAvailable := False;
  FLastError := '';
  FQueried := False;
end;

procedure TAIGPU.EnsureRefreshed;
begin
  if not FQueried then
    RefreshInfo;
end;

function TAIGPU.GetAvailable: Boolean;
begin
  EnsureRefreshed;
  Result := FAvailable;
end;

function TAIGPU.GetLastError: string;
begin
  EnsureRefreshed;
  Result := FLastError;
end;

function TAIGPU.GetGPUName: string;
begin
  EnsureRefreshed;
  Result := FLastInfo.Name;
end;

function TAIGPU.GetMemoryTotalMB: QWord;
begin
  EnsureRefreshed;
  Result := FLastInfo.MemoryTotalMB;
end;

function TAIGPU.GetMemoryUsedMB: QWord;
begin
  EnsureRefreshed;
  Result := FLastInfo.MemoryUsedMB;
end;

function TAIGPU.GetMemoryFreeMB: QWord;
begin
  EnsureRefreshed;
  Result := FLastInfo.MemoryFreeMB;
end;

function TAIGPU.GetCUDACoreCount: Integer;
begin
  EnsureRefreshed;
  Result := FLastInfo.CUDACoreCount;
end;

function TAIGPU.GetUsagePercent: Double;
begin
  EnsureRefreshed;
  Result := FLastInfo.UsagePercent;
end;

function TAIGPU.RefreshInfo: TAIGPUInfo;
begin
  ClearGPUInfo(FLastInfo);
  {$IFDEF LINUX}
  QueryLinuxGPU(FLastInfo);
  {$ELSE}
  FLastInfo.Name := 'Unavailable';
  FLastInfo.LastError := 'GPU telemetry is not implemented for this platform';
  {$ENDIF}
  FAvailable := FLastInfo.Available;
  FLastError := FLastInfo.LastError;
  FQueried := True;
  Result := FLastInfo;
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIGPU]);
end;

initialization
  {$I aigpu_icon.lrs}

end.
