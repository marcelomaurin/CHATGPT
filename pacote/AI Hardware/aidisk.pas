unit aidisk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  BaseUnix, UnixType, aihardwarelinux,
  {$ENDIF}
  LResources;

type
  TAIDiskInfo = record
    Drive: string;
    TotalBytes: UInt64;
    FreeBytes: UInt64;
    UsedBytes: UInt64;
    TotalMB: QWord;
    FreeMB: QWord;
    UsedMB: QWord;
  end;

  TAIDisk = class(TComponent)
  private
    FDisks: array of TAIDiskInfo;
    function GetDiskCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function RefreshInfo: Integer;
    function GetDiskInfo(Index: Integer): TAIDiskInfo;
    function GetDiskCountInfo: Integer;
    function GetDriveCount: Integer;
  public
    property DiskCount: Integer read GetDiskCountInfo;
  end;

procedure Register;

implementation

{$IFDEF LINUX}
function NextMountToken(const ALine: string; var APosition: Integer): string;
var
  StartPos: Integer;
begin
  while (APosition <= Length(ALine)) and (ALine[APosition] in [' ', #9]) do
    Inc(APosition);
  StartPos := APosition;
  while (APosition <= Length(ALine)) and not
    (ALine[APosition] in [' ', #9]) do
    Inc(APosition);
  Result := Copy(ALine, StartPos, APosition - StartPos);
end;

function IsPseudoFileSystem(const AFileSystem: string): Boolean;
const
  PseudoFileSystems: array[0..17] of string = (
    'proc', 'sysfs', 'devtmpfs', 'devpts', 'tmpfs', 'cgroup', 'cgroup2',
    'mqueue', 'securityfs', 'debugfs', 'tracefs', 'configfs', 'fusectl',
    'hugetlbfs', 'pstore', 'autofs', 'rpc_pipefs', 'binfmt_misc');
var
  I: Integer;
begin
  Result := False;
  for I := Low(PseudoFileSystems) to High(PseudoFileSystems) do
    if SameText(AFileSystem, PseudoFileSystems[I]) then
      Exit(True);
end;
{$ENDIF}

function TAIDisk.GetDiskCount: Integer;
{$IFDEF WINDOWS}
var
  Mask: DWORD;
  I: Integer;
{$ENDIF}
begin
  {$IF DEFINED(WINDOWS)}
  Result := 0;
  Mask := GetLogicalDrives;
  for I := 0 to 25 do
    if (Mask and (1 shl I)) <> 0 then
      Inc(Result);
  {$ELSEIF DEFINED(LINUX)}
  Result := RefreshInfo;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

constructor TAIDisk.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetLength(FDisks, 0);
end;

function TAIDisk.GetDiskInfo(Index: Integer): TAIDiskInfo;
begin
  Result := FDisks[Index];
end;

function TAIDisk.GetDiskCountInfo: Integer;
begin
  Result := Length(FDisks);
end;

function TAIDisk.GetDriveCount: Integer;
begin
  Result := GetDiskCount;
end;

function TAIDisk.RefreshInfo: Integer;
{$IFDEF WINDOWS}
var
  Mask: DWORD;
  I: Integer;
  Root: string;
  FreeToCaller, TotalBytes, FreeBytes: Int64;
  DriveType: UINT;
{$ENDIF}
{$IFDEF LINUX}
var
  I, Position: Integer;
  DeviceName, MountPoint, FileSystem: string;
  Lines, SeenMounts: TStringList;

  function AddMount(const AMountPoint: string): Boolean;
  var
    Info: TStatFS;
    BlockSize, TotalBytes, FreeBytes: QWord;
    ItemIndex: Integer;
  begin
    Result := False;
    if (AMountPoint = '') or (SeenMounts.IndexOf(AMountPoint) >= 0) then
      Exit;
    FillChar(Info, SizeOf(Info), 0);
    if fpStatFS(PChar(AMountPoint), @Info) <> 0 then
      Exit;
    if Info.frsize > 0 then
      BlockSize := QWord(Info.frsize)
    else if Info.bsize > 0 then
      BlockSize := QWord(Info.bsize)
    else
      Exit;
    TotalBytes := QWord(Info.blocks) * BlockSize;
    FreeBytes := QWord(Info.bavail) * BlockSize;
    if FreeBytes > TotalBytes then
      FreeBytes := TotalBytes;
    SeenMounts.Add(AMountPoint);
    SetLength(FDisks, Length(FDisks) + 1);
    ItemIndex := High(FDisks);
    FDisks[ItemIndex].Drive := AMountPoint;
    FDisks[ItemIndex].TotalBytes := TotalBytes;
    FDisks[ItemIndex].FreeBytes := FreeBytes;
    FDisks[ItemIndex].UsedBytes := TotalBytes - FreeBytes;
    FDisks[ItemIndex].TotalMB := TotalBytes div 1024 div 1024;
    FDisks[ItemIndex].FreeMB := FreeBytes div 1024 div 1024;
    FDisks[ItemIndex].UsedMB := FDisks[ItemIndex].TotalMB -
      FDisks[ItemIndex].FreeMB;
    Result := True;
  end;
{$ENDIF}
begin
  SetLength(FDisks, 0);
  {$IF DEFINED(WINDOWS)}
  Mask := GetLogicalDrives;
  for I := 0 to 25 do
  begin
    if (Mask and (1 shl I)) = 0 then
      Continue;
    Root := Chr(Ord('A') + I) + ':\';
    DriveType := GetDriveType(PChar(Root));
    if DriveType = DRIVE_NO_ROOT_DIR then
      Continue;
    if GetDiskFreeSpaceEx(PChar(Root), FreeToCaller, TotalBytes, @FreeBytes) then
    begin
      SetLength(FDisks, Length(FDisks) + 1);
      FDisks[High(FDisks)].Drive := Root;
      FDisks[High(FDisks)].TotalBytes := TotalBytes;
      FDisks[High(FDisks)].FreeBytes := FreeBytes;
      FDisks[High(FDisks)].UsedBytes := TotalBytes - FreeBytes;
      FDisks[High(FDisks)].TotalMB := QWord(TotalBytes) div 1024 div 1024;
      FDisks[High(FDisks)].FreeMB := QWord(FreeBytes) div 1024 div 1024;
      FDisks[High(FDisks)].UsedMB := FDisks[High(FDisks)].TotalMB -
        FDisks[High(FDisks)].FreeMB;
    end;
  end;
  {$ELSEIF DEFINED(LINUX)}
  Lines := TStringList.Create;
  SeenMounts := TStringList.Create;
  try
    SeenMounts.Sorted := True;
    SeenMounts.Duplicates := dupIgnore;
    try
      Lines.LoadFromFile(AIHardwareProcPath('self/mounts'));
    except
      Lines.Clear;
    end;
    for I := 0 to Lines.Count - 1 do
    begin
      Position := 1;
      DeviceName := NextMountToken(Lines[I], Position);
      MountPoint := AIDecodeMountPath(NextMountToken(Lines[I], Position));
      FileSystem := NextMountToken(Lines[I], Position);
      if (DeviceName = '') or (MountPoint = '') or (FileSystem = '') then
        Continue;
      if IsPseudoFileSystem(FileSystem) then
        Continue;
      AddMount(MountPoint);
    end;
    if Length(FDisks) = 0 then
      AddMount('/');
  finally
    SeenMounts.Free;
    Lines.Free;
  end;
  {$ENDIF}
  Result := Length(FDisks);
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIDisk]);
end;

initialization
  {$I aidisk_icon.lrs}

end.
