unit aidisk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, LResources;

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

function TAIDisk.GetDiskCount: Integer;
var
  Mask: DWORD;
  I: Integer;
begin
  Result := 0;
  Mask := GetLogicalDrives;
  for I := 0 to 25 do
    if (Mask and (1 shl I)) <> 0 then
      Inc(Result);
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
var
  Mask: DWORD;
  I: Integer;
  Root: string;
  FreeToCaller, TotalBytes, FreeBytes: Int64;
  DriveType: UINT;
begin
  SetLength(FDisks, 0);
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
      FDisks[High(FDisks)].UsedMB := FDisks[High(FDisks)].TotalMB - FDisks[High(FDisks)].FreeMB;
    end;
  end;
  Result := Length(FDisks);
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIDisk]);
end;

end.
