unit aiplatform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIOSPlatform = (
    aosUnknown,
    aosWindows,
    aosLinux,
    aosDarwin
  );

  TAIArchitecture = (
    archUnknown,
    archX86,
    archX64,
    archARM,
    archARM64
  );

function AIGetOS: TAIOSPlatform;
function AIGetArchitecture: TAIArchitecture;
function AIIsWindows: Boolean;
function AIIsLinux: Boolean;
function AIIsARM: Boolean;
function AIIs64Bit: Boolean;
function AIOSName: string;
function AIArchitectureName: string;
function AIExecutableExt: string;
function AILibraryExt: string;
function AILibraryPrefix: string;
function AIPathSeparator: Char;
function AICombinePath(const ABase, ARelative: string): string;
function AINormalizePath(const APath: string): string;
function AIGetLibraryFileName(const ABaseName: string): string;
function AIIsRaspberryLike: Boolean;

implementation

function AIGetOS: TAIOSPlatform;
begin
  Result := aosUnknown;
  {$IFDEF MSWINDOWS}
  Result := aosWindows;
  {$ENDIF}
  {$IFDEF LINUX}
  Result := aosLinux;
  {$ENDIF}
  {$IFDEF DARWIN}
  Result := aosDarwin;
  {$ENDIF}
end;

function AIGetArchitecture: TAIArchitecture;
begin
  Result := archUnknown;
  {$IFDEF CPUX86}
  Result := archX86;
  {$ENDIF}
  {$IFDEF CPUX86_64}
  Result := archX64;
  {$ENDIF}
  {$IFDEF CPUARM}
  Result := archARM;
  {$ENDIF}
  {$IFDEF CPUAARCH64}
  Result := archARM64;
  {$ENDIF}
end;

function AIIsWindows: Boolean;
begin
  Result := AIGetOS = aosWindows;
end;

function AIIsLinux: Boolean;
begin
  Result := AIGetOS = aosLinux;
end;

function AIIsARM: Boolean;
begin
  Result := AIGetArchitecture in [archARM, archARM64];
end;

function AIIs64Bit: Boolean;
begin
  Result := AIGetArchitecture in [archX64, archARM64];
end;

function AIOSName: string;
begin
  case AIGetOS of
    aosWindows: Result := 'windows';
    aosLinux: Result := 'linux';
    aosDarwin: Result := 'darwin';
  else
    Result := 'unknown';
  end;
end;

function AIArchitectureName: string;
begin
  case AIGetArchitecture of
    archX86: Result := 'x86';
    archX64: Result := 'x64';
    archARM: Result := 'armhf';
    archARM64: Result := 'arm64';
  else
    Result := 'unknown';
  end;
end;

function AIExecutableExt: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '.exe';
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

function AILibraryExt: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '.dll';
  {$ELSE}
    {$IFDEF DARWIN}
    Result := '.dylib';
    {$ELSE}
    Result := '.so';
    {$ENDIF}
  {$ENDIF}
end;

function AILibraryPrefix: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '';
  {$ELSE}
  Result := 'lib';
  {$ENDIF}
end;

function AIPathSeparator: Char;
begin
  Result := DirectorySeparator;
end;

function AINormalizePath(const APath: string): string;
begin
  Result := ExpandFileName(APath);
end;

function AICombinePath(const ABase, ARelative: string): string;
begin
  if ABase = '' then
    Result := ExpandFileName(ARelative)
  else
    Result := ExpandFileName(IncludeTrailingPathDelimiter(ABase) + ARelative);
end;

function AIGetLibraryFileName(const ABaseName: string): string;
begin
  Result := ABaseName;
  if (AILibraryPrefix <> '') and (Copy(Result, 1, Length(AILibraryPrefix)) <> AILibraryPrefix) then
    Result := AILibraryPrefix + Result;
  if ExtractFileExt(Result) = '' then
    Result := Result + AILibraryExt;
end;

function AIIsRaspberryLike: Boolean;
var
  ModelFile: string;
  S: TStringList;
begin
  Result := False;
  if not AIIsLinux or not AIIsARM then
    Exit;

  ModelFile := '/proc/device-tree/model';
  if not FileExists(ModelFile) then
    ModelFile := '/sys/firmware/devicetree/base/model';

  if FileExists(ModelFile) then
  begin
    S := TStringList.Create;
    try
      try
        S.LoadFromFile(ModelFile);
        Result := Pos('Raspberry', S.Text) > 0;
      except
        Result := AIIsARM;
      end;
    finally
      S.Free;
    end;
  end
  else
    Result := AIIsARM;
end;

end.
