program hardware_linux_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, aihardwarelinux, aicpu, aimemory, aidisk, aiso, aigpu;

procedure Fail(const AMessage: string);
begin
  Writeln(StdErr, 'FAIL: ', AMessage);
  Halt(1);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    Fail(AMessage);
end;

procedure WriteFixture(const AFileName, AText: string);
var
  Lines: TStringList;
begin
  if not ForceDirectories(ExtractFileDir(AFileName)) then
    Fail('cannot create fixture directory for ' + AFileName);
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    Lines.SaveToFile(AFileName);
  finally
    Lines.Free;
  end;
end;

procedure DeleteTree(const ADirectory: string);
var
  SearchRec: TSearchRec;
  ItemPath: string;
begin
  if not DirectoryExists(ADirectory) then
    Exit;
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
      ItemPath := IncludeTrailingPathDelimiter(ADirectory) + SearchRec.Name;
      if (SearchRec.Attr and faDirectory) <> 0 then
        DeleteTree(ItemPath)
      else if not DeleteFile(ItemPath) then
        Fail('cannot delete fixture ' + ItemPath);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
  if not RemoveDir(ADirectory) then
    Fail('cannot remove fixture directory ' + ADirectory);
end;

{$IFDEF LINUX}
procedure RunLinuxFixtureTests;
var
  TempRoot, MountPath: string;
  CPU: TAICPU;
  Memory: TAIMemory;
  Disk: TAIDisk;
  OperatingSystem: TAIOS;
  GPU: TAIGPU;
  MemoryInfo: TAIMemoryInfo;
  OSInfo: TAIOSInfo;
  GPUInfo: TAIGPUInfo;
  DiskInfo: TAIDiskInfo;
begin
  TempRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'aihardware_linux_' + IntToStr(GetProcessID);
  DeleteTree(TempRoot);
  MountPath := IncludeTrailingPathDelimiter(TempRoot) + 'mount';
  ForceDirectories(MountPath);

  AIHardwareProcRoot := IncludeTrailingPathDelimiter(TempRoot) + 'proc';
  AIHardwareSysRoot := IncludeTrailingPathDelimiter(TempRoot) + 'sys';
  AIHardwareEtcRoot := IncludeTrailingPathDelimiter(TempRoot) + 'etc';

  WriteFixture(AIHardwareProcPath('cpuinfo'),
    'processor : 0' + LineEnding +
    'physical id : 0' + LineEnding +
    'core id : 0' + LineEnding +
    'model name : Fixture CPU' + LineEnding +
    'cpu MHz : 1800.000' + LineEnding + LineEnding +
    'processor : 1' + LineEnding +
    'physical id : 0' + LineEnding +
    'core id : 0' + LineEnding + LineEnding +
    'processor : 2' + LineEnding +
    'physical id : 0' + LineEnding +
    'core id : 1' + LineEnding + LineEnding +
    'processor : 3' + LineEnding +
    'physical id : 0' + LineEnding +
    'core id : 1' + LineEnding);
  WriteFixture(AIHardwareProcPath('stat'),
    'cpu  100 0 50 850 0 0 0 0' + LineEnding +
    'cpu0 25 0 12 213 0 0 0 0' + LineEnding +
    'cpu1 25 0 13 212 0 0 0 0' + LineEnding +
    'cpu2 25 0 12 213 0 0 0 0' + LineEnding +
    'cpu3 25 0 13 212 0 0 0 0' + LineEnding);
  WriteFixture(AIHardwareSysPath(
    'devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq'), '2400000');
  WriteFixture(AIHardwareSysPath(
    'devices/system/cpu/cpu0/cache/index0/coherency_line_size'), '64');

  WriteFixture(AIHardwareProcPath('meminfo'),
    'MemTotal:        8388608 kB' + LineEnding +
    'MemFree:         1048576 kB' + LineEnding +
    'Buffers:          524288 kB' + LineEnding +
    'Cached:          1572864 kB' + LineEnding +
    'SwapTotal:       2097152 kB' + LineEnding +
    'SwapFree:        1048576 kB' + LineEnding);
  ForceDirectories(AIHardwareSysPath('firmware/dmi/entries/17-0'));
  ForceDirectories(AIHardwareSysPath('firmware/dmi/entries/17-1'));

  WriteFixture(AIHardwareEtcPath('os-release'),
    'NAME="Fixture Linux"' + LineEnding +
    'PRETTY_NAME="Fixture Linux 42"' + LineEnding +
    'VERSION_ID="42"' + LineEnding);

  WriteFixture(AIHardwareSysPath('class/drm/card0/device/vendor'), '0x10de');
  WriteFixture(AIHardwareSysPath('class/drm/card0/device/device'), '0x1abc');
  WriteFixture(AIHardwareSysPath('class/drm/card0/device/product_name'),
    'Fixture GPU');
  WriteFixture(AIHardwareSysPath(
    'class/drm/card0/device/mem_info_vram_total'), '4294967296');
  WriteFixture(AIHardwareSysPath(
    'class/drm/card0/device/mem_info_vram_used'), '1073741824');
  WriteFixture(AIHardwareSysPath('class/drm/card0/device/gpu_busy_percent'),
    '37');

  WriteFixture(AIHardwareProcPath('self/mounts'),
    '/dev/fixture ' + MountPath + ' ext4 rw 0 0');

  CPU := TAICPU.Create(nil);
  Memory := TAIMemory.Create(nil);
  Disk := TAIDisk.Create(nil);
  OperatingSystem := TAIOS.Create(nil);
  GPU := TAIGPU.Create(nil);
  try
    Check(CPU.GetProcessorCount = 4, 'logical CPU count');
    Check(CPU.GetCoreCount = 2, 'physical CPU core count');
    Check(CPU.GetProcessorId = 'Fixture CPU', 'CPU model');
    Check(CPU.GetFrequencyMHz = 2400, 'CPU frequency');
    Check(CPU.GetCacheLineSize = 64, 'CPU cache line');

    MemoryInfo := Memory.RefreshInfo;
    Check(MemoryInfo.TotalMB = 8192, 'memory total');
    Check(MemoryInfo.AvailableMB = 3072, 'memory available');
    Check(MemoryInfo.UsedMB = 5120, 'memory used');
    Check(MemoryInfo.SlotCount = 2, 'memory DMI slots');

    OSInfo := OperatingSystem.RefreshInfo;
    Check(OSInfo.OSName = 'Fixture Linux 42', 'Linux distribution name');
    Check(Pos('42', OSInfo.OSVersion) = 1, 'Linux distribution version');
    Check(OSInfo.VirtualMemoryTotalMB = 10240, 'virtual memory total');
    Check(OSInfo.VirtualMemoryUsedMB = 6144, 'virtual memory used');
    Check(OSInfo.Architecture <> '', 'Linux architecture');

    GPUInfo := GPU.RefreshInfo;
    Check(GPUInfo.Available, 'DRM GPU should be available');
    Check(GPUInfo.Name = 'Fixture GPU [10de:1abc]', 'GPU identity');
    Check(GPUInfo.MemoryTotalMB = 4096, 'GPU memory total');
    Check(GPUInfo.MemoryUsedMB = 1024, 'GPU memory used');
    Check(GPUInfo.MemoryFreeMB = 3072, 'GPU memory free');
    Check(Abs(GPUInfo.UsagePercent - 37.0) < 0.01, 'GPU utilization');
    Check(Pos('CUDA core count', GPUInfo.LastError) > 0,
      'unsupported CUDA metric must be explicit');
    Check(GPU.Available, 'component GPU availability property');
    Check(GPU.LastError <> '', 'component GPU diagnostic property');

    AIHardwareSysRoot := IncludeTrailingPathDelimiter(TempRoot) + 'sys-missing';
    GPUInfo := GPU.RefreshInfo;
    Check(not GPUInfo.Available, 'missing DRM GPU reported availability');
    Check(GPUInfo.LastError <> '', 'missing DRM GPU omitted diagnostic');
    AIHardwareSysRoot := IncludeTrailingPathDelimiter(TempRoot) + 'sys';

    Check(Disk.RefreshInfo = 1, 'Linux mount count');
    DiskInfo := Disk.GetDiskInfo(0);
    Check(DiskInfo.Drive = MountPath, 'Linux mount path');
    Check(DiskInfo.TotalBytes > 0, 'Linux statfs total');
    Check(DiskInfo.FreeBytes <= DiskInfo.TotalBytes, 'Linux statfs free');
  finally
    GPU.Free;
    OperatingSystem.Free;
    Disk.Free;
    Memory.Free;
    CPU.Free;
    ResetAIHardwareLinuxRoots;
    DeleteTree(TempRoot);
  end;
end;
{$ENDIF}

procedure RunUnsupportedGPUContract;
var
  GPU: TAIGPU;
  Info: TAIGPUInfo;
begin
  {$IFNDEF LINUX}
  GPU := TAIGPU.Create(nil);
  try
    Info := GPU.RefreshInfo;
    Check(not Info.Available, 'unsupported GPU backend reported availability');
    Check(Info.LastError <> '', 'unsupported GPU backend omitted diagnostic');
  finally
    GPU.Free;
  end;
  {$ENDIF}
end;

begin
  {$IFDEF LINUX}
  RunLinuxFixtureTests;
  {$ELSE}
  RunUnsupportedGPUContract;
  {$ENDIF}
  Writeln('PASS: AI Hardware platform contracts');
end.
